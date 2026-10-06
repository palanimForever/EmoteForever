local addonName, ns = ...
local L = ns.L

-- Entry point: saved variables, branding, chat output and slash commands.
-- Load order (see .toc): embeds.xml (libs) → Locale → Core → Emotes → Wheel → Preview → MinimapButton
-- → Editor → Options. Bindings.xml loads automatically.

local TEST_DELAY = 1 -- seconds; /emf testdelay performs without a key press in the call stack
local MAX_LOGGED_TESTS = 20 -- EmoteForeverDB.probe.tests keeps only the latest attempts
local DEFAULT_KEY = "BUTTON3" -- middle mouse button
ns.BINDING = "EMOTEFOREVER_WHEEL"

ns.MIN_SLOTS, ns.MAX_SLOTS = 4, 12

ns.defaults = {
    -- Emote tokens of the wheel, clockwise from the top.
    wheel = { "WAVE", "THANK", "DANCE", "KISS", "LAUGH", "CHEER", "BOW", "HELLO" },
    wheelSize = 8, -- number of slots; kept in sync with #wheel
    wheelScale = 100, -- percent
    showMinimapButton = true,
    minimap = {}, -- minimap button position, managed by LibDBIcon
}

-- Name in Blizzard's key binding menu (Options → Keybindings → AddOns) and on our settings page.
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

-- Mouse icons from Blizzard's new player tutorial for usage hints in tooltips.
local MOUSE_ATLAS = {
    LeftButton = "newplayertutorial-icon-mouse-leftbutton",
    RightButton = "newplayertutorial-icon-mouse-rightbutton",
}
local HINT_ICON_HEIGHT = 16

-- Usage hint like "[mouse]  Settings". If the mouse icon is missing in the client, the plain text
-- (fallback) is returned.
function ns.ClickHint(button, action, fallback)
    local atlas = MOUSE_ATLAS[button]
    local info = atlas and C_Texture.GetAtlasInfo(atlas)
    if not info then return fallback end
    local width = math.floor(HINT_ICON_HEIGHT * info.width / info.height + 0.5)
    return CreateAtlasMarkup(atlas, width, HINT_ICON_HEIGHT) .. "  " .. action
end

-- Default value of a setting; tables are copied so the defaults are never modified.
function ns.GetDefault(key)
    local value = ns.defaults[key]
    return type(value) == "table" and CopyTable(value) or value
end

function ns.ApplySettings()
    ns.Wheel:ApplySettings()
    ns.MinimapButton:ApplySettings()
    ns.Editor:Refresh()
end

-- Grows or shrinks the wheel to wheelSize slots. New slots get catalog emotes that aren't on it yet.
function ns.ResizeWheel()
    local wheel, size = EmoteForeverDB.wheel, EmoteForeverDB.wheelSize
    for i = #wheel, size + 1, -1 do wheel[i] = nil end
    local used = {}
    for _, token in ipairs(wheel) do used[token] = true end
    for _, emote in ipairs(ns.Emotes.list) do
        if #wheel >= size then break end
        if not used[emote.token] and ns.Emotes.IsAvailable(emote) then
            table.insert(wheel, emote.token)
            used[emote.token] = true
        end
    end
end

-- Puts an emote on a slot. If it already sits on another slot, the two slots swap.
function ns.SetWheelEmote(index, token)
    local wheel = EmoteForeverDB.wheel
    for i, existing in ipairs(wheel) do
        if existing == token and i ~= index then wheel[i] = wheel[index] end
    end
    wheel[index] = token
    ns.ApplySettings()
end

-- Performs an emote at the current target (the game picks the target when no name is given).
-- PerformEmote returns false even when the emote plays (Forever beta, 2026-10), so the return value
-- is only logged, not shown. The latest attempts go to EmoteForeverDB.probe.tests (readable after /reload).
function ns.PerformEmote(token, source)
    local ok, result = pcall(C_ChatInfo.PerformEmote, token)
    local tests = EmoteForeverDB.probe.tests
    table.insert(tests, {
        time = date("%H:%M:%S"),
        token = token,
        source = source,
        ok = ok,
        result = tostring(result),
        inCombat = InCombatLockdown(),
        chatLockdown = tostring(C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()),
    })
    while #tests > MAX_LOGGED_TESTS do table.remove(tests, 1) end
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
    EmoteForeverDB.wheelSize = #EmoteForeverDB.wheel
    EmoteForeverDB.wheelStyle = nil -- removed option (names-only style)

    ns.Options:Register()
    ns.MinimapButton:Init()
end

-- On first login, put the wheel on the middle mouse button if neither is bound yet.
-- Only offered once, so a player who removes the binding keeps it removed.
function handlers.PLAYER_LOGIN()
    if EmoteForeverDB.bindingOffered or InCombatLockdown() then return end
    EmoteForeverDB.bindingOffered = true
    if GetBindingKey(ns.BINDING) then return end
    if GetBindingAction(DEFAULT_KEY) == "" then
        SetBinding(DEFAULT_KEY, ns.BINDING)
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
    if command == "" then
        ns.Options:Open()
    elseif command == "edit" then
        ns.Options:OpenEditor()
    elseif command == "preview" then
        ns.Preview:Toggle()
    elseif command == "test" and arg ~= "" then
        RunTest(arg, false)
    elseif command == "testdelay" and arg ~= "" then
        RunTest(arg, true)
    elseif command == "probe" then
        ns.Emotes.Probe()
    else
        ns.Print(L.helpWheel)
        ns.Print("/emf  –  " .. L.helpOptions)
        ns.Print("/emf edit  –  " .. L.helpEdit)
    end
end
