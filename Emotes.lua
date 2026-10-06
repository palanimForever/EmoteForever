local addonName, ns = ...
local L = ns.L

-- Emote catalog: which emotes can be put on the wheel and which icon each one shows.
-- The game has no icons for emotes, so EmoteForever ships its own single-color symbols (Media/Emotes,
-- white on transparency, tinted in-game). Symbols from game-icons.net (CC BY 3.0), credits in the README.
-- Tokens and localized slash commands come from Blizzard (EMOTE<i>_TOKEN / EMOTE<i>_CMD1).

local Emotes = {}
ns.Emotes = Emotes

local ICON_PATH = "Interface\\AddOns\\" .. addonName .. "\\Media\\Emotes\\"
local FALLBACK_ICON = {
    anim = "drama-masks",
    speech = "chat-bubble",
}

-- Same lists as Blizzard's chat menu (EmoteList / TextEmoteSpeechList), extended by a few popular emotes.
-- kind: "anim" = character animation, "speech" = animation with a voice line.
Emotes.list = {
    -- With animation
    { token = "WAVE", kind = "anim", icon = "palm" },
    { token = "BOW", kind = "anim", icon = "prayer" },
    { token = "DANCE", kind = "anim", icon = "acrobatic" },
    { token = "APPLAUD", kind = "anim", icon = "laurel-crown" },
    { token = "BEG", kind = "anim", icon = "two-coins" },
    { token = "CHICKEN", kind = "anim", icon = "chicken" },
    { token = "CRY", kind = "anim", icon = "tear-tracks" },
    { token = "EAT", kind = "anim", icon = "chicken-leg" },
    { token = "FLEX", kind = "anim", icon = "biceps" },
    { token = "KISS", kind = "anim", icon = "lips" },
    { token = "LAUGH", kind = "anim", icon = "jester-hat" },
    { token = "POINT", kind = "anim", icon = "pointing" },
    { token = "ROAR", kind = "anim", icon = "shouting" },
    { token = "RUDE", kind = "anim", icon = "fist" },
    { token = "SALUTE", kind = "anim", icon = "knight-banner" },
    { token = "SHY", kind = "anim", icon = "hood" },
    { token = "TALK", kind = "anim", icon = "talk" },
    { token = "STAND", kind = "anim", icon = "person" },
    { token = "SIT", kind = "anim", icon = "meditation" },
    { token = "SLEEP", kind = "anim", icon = "night-sleep" },
    { token = "KNEEL", kind = "anim", icon = "kneeling" },
    { token = "LEAN", kind = "anim", icon = "brick-wall" },
    { token = "HUG", kind = "anim", icon = "lovers" },
    { token = "CLAP", kind = "anim", icon = "high-five" },

    -- With voice
    { token = "HELPME", kind = "speech", icon = "help" },
    { token = "INCOMING", kind = "speech", icon = "ringing-bell" },
    { token = "CHARGE", kind = "speech", icon = "hunting-horn" },
    { token = "FLEE", kind = "speech", icon = "run" },
    { token = "ATTACKMYTARGET", kind = "speech", icon = "crosshair" },
    { token = "OOM", kind = "speech", icon = "round-potion" },
    { token = "FOLLOW", kind = "speech", icon = "footprint" },
    { token = "WAIT", kind = "speech", icon = "hourglass" },
    { token = "HEALME", kind = "speech", icon = "health-potion" },
    { token = "CHEER", kind = "speech", icon = "party-popper" },
    { token = "OPENFIRE", kind = "speech", icon = "cannon" },
    { token = "RASP", kind = "speech", icon = "tongue" },
    { token = "HELLO", kind = "speech", icon = "open-palm" },
    { token = "BYE", kind = "speech", icon = "exit-door" },
    { token = "NOD", kind = "speech", icon = "thumb-up" },
    { token = "NO", kind = "speech", icon = "thumb-down" },
    { token = "THANK", kind = "speech", icon = "shaking-hands" },
    { token = "WELCOME", kind = "speech", icon = "beer-stein" },
    { token = "CONGRATULATE", kind = "speech", icon = "present" },
    { token = "FLIRT", kind = "speech", icon = "rose" },
    { token = "JOKE", kind = "speech", icon = "card-joker" },
    { token = "TRAIN", kind = "speech", icon = "steam-locomotive" },
    { token = "FORTHEALLIANCE", kind = "speech", icon = "lion", faction = "Alliance" },
    { token = "FORTHEHORDE", kind = "speech", icon = "wolf-head", faction = "Horde" },
}

local byToken = {}
for _, emote in ipairs(Emotes.list) do byToken[emote.token] = emote end

-- Blizzard's emote index (EMOTE<i>_TOKEN), built on first use.
local blizzardIndex
local function GetBlizzardIndex()
    if blizzardIndex then return blizzardIndex end
    blizzardIndex = {}
    for i = 1, MAXEMOTEINDEX or 0 do
        local token = _G["EMOTE" .. i .. "_TOKEN"]
        if token then blizzardIndex[token] = i end
    end
    return blizzardIndex
end

function Emotes.Get(token)
    return byToken[token]
end

-- Does the game know this emote? (Retail-only emotes may be missing in Forever.)
function Emotes.Exists(token)
    return GetBlizzardIndex()[token] ~= nil
end

-- Localized name, taken from the slash command ("/winken" → "Winken").
function Emotes.GetLabel(token)
    local index = GetBlizzardIndex()[token]
    local command = index and _G["EMOTE" .. index .. "_CMD1"]
    if not command then return token end
    command = command:gsub("^/", "")
    return command:sub(1, 1):upper() .. command:sub(2)
end

function Emotes.GetIcon(token)
    local emote = byToken[token]
    local icon = emote and emote.icon or FALLBACK_ICON[emote and emote.kind or "anim"]
    return ICON_PATH .. icon
end

function Emotes.IsAvailable(emote)
    return not emote.faction or emote.faction == UnitFactionGroup("player")
end

-- Finds the token for user input: the token itself ("wave") or a localized slash command ("/winken").
function Emotes.FindToken(input)
    input = input:upper():gsub("^/", "")
    if GetBlizzardIndex()[input] then return input end
    local wanted = "/" .. input:lower()
    for token, i in pairs(GetBlizzardIndex()) do
        for n = 1, 9 do
            local command = _G["EMOTE" .. i .. "_CMD" .. n]
            if not command then break end
            if command:lower() == wanted then return token end
        end
    end
end

-- Developer check: which emotes of our list does the game know?
-- Stored in EmoteForeverDB.probe (readable after /reload).
function Emotes.Probe()
    local probe = EmoteForeverDB.probe
    probe.time = date("%Y-%m-%d %H:%M:%S")
    probe.maxEmoteIndex = MAXEMOTEINDEX
    probe.unknownTokens, probe.labels = {}, {}
    probe.missingIcons = nil

    for _, emote in ipairs(Emotes.list) do
        if not Emotes.Exists(emote.token) then table.insert(probe.unknownTokens, emote.token) end
        probe.labels[emote.token] = Emotes.GetLabel(emote.token)
    end

    -- All emotes the game knows, as a base for the full selection list later.
    probe.allTokens = {}
    for token, i in pairs(GetBlizzardIndex()) do
        probe.allTokens[token] = _G["EMOTE" .. i .. "_CMD1"] or false
    end

    ns.Print(L.probeDone:format(#Emotes.list, #probe.unknownTokens))
end
