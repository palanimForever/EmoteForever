local addonName, ns = ...
local L = ns.L

-- Entry point: saved variables, branding, chat output and slash commands.
-- Load order (see .toc): Locale → Core → Emotes → Wheel → Preview. Bindings.xml loads automatically.

local TEST_DELAY = 1 -- seconds; /emf testdelay performs without a key press in the call stack
local BINDING = "EMOTEFOREVER_WHEEL"
local DEFAULT_KEY = "BUTTON3" -- middle mouse button

ns.defaults = {
    -- Emote tokens of the wheel, clockwise from the top.
    wheel = { "WAVE", "THANK", "DANCE", "KISS", "LAUGH", "CHEER", "BOW", "HELLO" },
    wheelStyle = "symbols", -- "symbols" | "names"
}

-- Name in Blizzard's key binding menu (Options → Keybindings → AddOns).
BINDING_NAME_EMOTEFOREVER_WHEEL = L.bindingWheel

-- Branding: author and brand color in one place so all Palanim addons look the same.
ns.AUTHOR = "Palanim"
ns.BRAND_COLOR = CreateColorFromHexString("ff9966ff")
-- The packager replaces @project-version@ with the git tag on release; locally the placeholder remains.
local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or ""
ns.VERSION = version:find("^@") and "dev" or version

-- "EmoteForever by Palanim", addon name in the brand color.
function ns.BrandLine()
    return ns.BRAND_COLOR:WrapTextInColorCode(addonName) .. " " .. L.byAuthor:format(ns.AUTHOR)
end

function ns.Print(message)
    print(ns.BRAND_COLOR:WrapTextInColorCode(addonName) .. " " .. message)
end

-- Default value of a setting; tables are copied so the defaults are never modified.
function ns.GetDefault(key)
    local value = ns.defaults[key]
    return type(value) == "table" and CopyTable(value) or value
end

-- Performs an emote at the current target (the game picks the target when no name is given).
-- PerformEmote returns false even when the emote plays (Forever beta, 2026-10), so the return value
-- is only logged, not shown. Every attempt goes to EmoteForeverDB.probe.tests (readable after /reload).
function ns.PerformEmote(token, source)
    local ok, result = pcall(C_ChatInfo.PerformEmote, token)
    table.insert(EmoteForeverDB.probe.tests, {
        time = date("%H:%M:%S"),
        token = token,
        source = source,
        ok = ok,
        result = tostring(result),
        inCombat = InCombatLockdown(),
        chatLockdown = tostring(C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()),
    })
    if not ok then
        ns.Print(L.testResult:format(ns.Emotes.GetLabel(token), L.testError:format(tostring(result))))
    end
end

local frame = CreateFrame("Frame")
local handlers = {}

function handlers.ADDON_LOADED(name)
    if name ~= addonName then return end
    frame:UnregisterEvent("ADDON_LOADED")

    EmoteForeverDB = EmoteForeverDB or {}
    for key in pairs(ns.defaults) do
        if EmoteForeverDB[key] == nil then EmoteForeverDB[key] = ns.GetDefault(key) end
    end
    EmoteForeverDB.probe = EmoteForeverDB.probe or {}
    EmoteForeverDB.probe.tests = EmoteForeverDB.probe.tests or {}
end

-- On first login, put the wheel on the middle mouse button if neither is bound yet.
-- Only offered once, so a player who removes the binding keeps it removed.
function handlers.PLAYER_LOGIN()
    if EmoteForeverDB.bindingOffered or InCombatLockdown() then return end
    EmoteForeverDB.bindingOffered = true
    if GetBindingKey(BINDING) then return end
    if GetBindingAction(DEFAULT_KEY) == "" then
        SetBinding(DEFAULT_KEY, BINDING)
        SaveBindings(GetCurrentBindingSet())
        ns.Print(L.bindingSet)
    else
        ns.Print(L.bindingMissing)
    end
end

frame:SetScript("OnEvent", function(_, event, ...) handlers[event](...) end)
for event in pairs(handlers) do frame:RegisterEvent(event) end

local function RunTest(arg, delayed)
    local token = ns.Emotes.FindToken(arg)
    if not token then
        ns.Print(L.unknownEmote:format(arg))
        return
    end
    if delayed then
        C_Timer.After(TEST_DELAY, function() ns.PerformEmote(token, "timer") end)
    else
        ns.PerformEmote(token, "slash")
    end
end

SLASH_EMOTEFOREVER1 = "/emf"
SLASH_EMOTEFOREVER2 = "/emoteforever"
SlashCmdList.EMOTEFOREVER = function(msg)
    local command, arg = strtrim(msg):match("^(%S*)%s*(.-)$")
    command = command:lower()
    if command == "preview" then
        ns.Preview:Toggle()
    elseif command == "style" then
        EmoteForeverDB.wheelStyle = EmoteForeverDB.wheelStyle == "symbols" and "names" or "symbols"
        ns.Wheel:ApplySettings()
        ns.Print(EmoteForeverDB.wheelStyle == "symbols" and L.styleSymbols or L.styleNames)
    elseif command == "test" and arg ~= "" then
        RunTest(arg, false)
    elseif command == "testdelay" and arg ~= "" then
        RunTest(arg, true)
    elseif command == "probe" then
        ns.Emotes.Probe()
    else
        ns.Print(L.helpWheel)
        ns.Print("/emf style  –  " .. L.helpStyle)
        ns.Print("/emf preview  –  " .. L.helpPreview)
        ns.Print("/emf test <emote>  –  " .. L.helpTest)
        ns.Print("/emf testdelay <emote>  –  " .. L.helpTestDelayed)
        ns.Print("/emf probe  –  " .. L.helpProbe)
    end
end
