local addonName, ns = ...
local L = ns.L

-- Emote catalog: which emotes can be put on the wheel and which icon each one shows.
-- The game has no icons for emotes, so every entry borrows a fitting game icon.
-- Tokens and localized slash commands come from Blizzard (EMOTE<i>_TOKEN / EMOTE<i>_CMD1).

local Emotes = {}
ns.Emotes = Emotes

local ICON_PATH = "Interface\\Icons\\"
local FALLBACK_ICON = {
    anim = "INV_Gauntlets_04",
    speech = "INV_Misc_Note_01",
}

-- Same lists as Blizzard's chat menu (EmoteList / TextEmoteSpeechList), extended by a few popular emotes.
-- kind: "anim" = character animation, "speech" = animation with a voice line.
Emotes.list = {
    -- With animation
    { token = "WAVE", kind = "anim", icon = "Spell_Holy_SealOfProtection" },
    { token = "BOW", kind = "anim", icon = "Spell_Holy_Restoration" },
    { token = "DANCE", kind = "anim", icon = "INV_Misc_Drum_01" },
    { token = "APPLAUD", kind = "anim", icon = "Spell_Holy_PowerInfusion" },
    { token = "BEG", kind = "anim", icon = "INV_Misc_Coin_01" },
    { token = "CHICKEN", kind = "anim", icon = "Spell_Magic_PolymorphChicken" },
    { token = "CRY", kind = "anim", icon = "Spell_Frost_FrostShock" },
    { token = "EAT", kind = "anim", icon = "INV_Misc_Food_01" },
    { token = "FLEX", kind = "anim", icon = "Spell_Nature_Strength" },
    { token = "KISS", kind = "anim", icon = "Spell_Shadow_SoothingKiss" },
    { token = "LAUGH", kind = "anim", icon = "Spell_Shadow_Charm" },
    { token = "POINT", kind = "anim", icon = "Ability_TownWatch" },
    { token = "ROAR", kind = "anim", icon = "Ability_Druid_DemoralizingRoar" },
    { token = "RUDE", kind = "anim", icon = "Spell_Shadow_UnholyFrenzy" },
    { token = "SALUTE", kind = "anim", icon = "Ability_Warrior_BattleShout" },
    { token = "SHY", kind = "anim", icon = "Ability_Stealth" },
    { token = "TALK", kind = "anim", icon = "INV_Letter_01" },
    { token = "STAND", kind = "anim", icon = "Ability_Warrior_DefensiveStance" },
    { token = "SIT", kind = "anim", icon = "Spell_Nature_Slow" },
    { token = "SLEEP", kind = "anim", icon = "Spell_Nature_Sleep" },
    { token = "KNEEL", kind = "anim", icon = "Spell_Holy_PrayerOfHealing" },
    { token = "LEAN", kind = "anim", icon = "Spell_Nature_Invisibilty" },
    { token = "HUG", kind = "anim", icon = "INV_Misc_Pelt_Bear_01" },
    { token = "CLAP", kind = "anim", icon = "Spell_Holy_Heal" },

    -- With voice
    { token = "HELPME", kind = "speech", icon = "Spell_Holy_SealOfSacrifice" },
    { token = "INCOMING", kind = "speech", icon = "Ability_Hunter_EagleEye" },
    { token = "CHARGE", kind = "speech", icon = "Ability_Warrior_Charge" },
    { token = "FLEE", kind = "speech", icon = "Ability_Rogue_Sprint" },
    { token = "ATTACKMYTARGET", kind = "speech", icon = "Ability_Hunter_SniperShot" },
    { token = "OOM", kind = "speech", icon = "Spell_Shadow_ManaBurn" },
    { token = "FOLLOW", kind = "speech", icon = "Ability_Tracking" },
    { token = "WAIT", kind = "speech", icon = "INV_Misc_PocketWatch_01" },
    { token = "HEALME", kind = "speech", icon = "Spell_Holy_FlashHeal" },
    { token = "CHEER", kind = "speech", icon = "INV_Misc_MissileSmall_Red" },
    { token = "OPENFIRE", kind = "speech", icon = "Spell_Fire_FireBolt02" },
    { token = "RASP", kind = "speech", icon = "Spell_Shadow_CurseOfTounges" },
    { token = "HELLO", kind = "speech", icon = "INV_Gauntlets_05" },
    { token = "BYE", kind = "speech", icon = "INV_Misc_Rune_01" },
    { token = "NOD", kind = "speech", icon = "Spell_Holy_SealOfWisdom" },
    { token = "NO", kind = "speech", icon = "Ability_Warrior_ShieldBash" },
    { token = "THANK", kind = "speech", icon = "Spell_Holy_SealOfSalvation" },
    { token = "WELCOME", kind = "speech", icon = "INV_Drink_05" },
    { token = "CONGRATULATE", kind = "speech", icon = "INV_Holiday_Christmas_Present_01" },
    { token = "FLIRT", kind = "speech", icon = "INV_ValentinesCandy" },
    { token = "JOKE", kind = "speech", icon = "INV_Misc_Toy_05" },
    { token = "TRAIN", kind = "speech", icon = "INV_Misc_Gear_01" },
    { token = "FORTHEALLIANCE", kind = "speech", icon = "INV_BannerPVP_02", faction = "Alliance" },
    { token = "FORTHEHORDE", kind = "speech", icon = "INV_BannerPVP_01", faction = "Horde" },
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

-- Developer check: which emotes of our list does the game know, and which icon files exist?
-- Stored in EmoteForeverDB.probe (readable after /reload).
function Emotes.Probe()
    local probe = EmoteForeverDB.probe
    probe.time = date("%Y-%m-%d %H:%M:%S")
    probe.maxEmoteIndex = MAXEMOTEINDEX
    probe.unknownTokens, probe.missingIcons, probe.labels = {}, {}, {}

    local function CheckIcon(icon)
        local fileID = GetFileIDFromPath(ICON_PATH .. icon)
        if not fileID or fileID == 0 then table.insert(probe.missingIcons, icon) end
    end
    for _, emote in ipairs(Emotes.list) do
        if not Emotes.Exists(emote.token) then table.insert(probe.unknownTokens, emote.token) end
        probe.labels[emote.token] = Emotes.GetLabel(emote.token)
        CheckIcon(emote.icon)
    end
    for _, icon in pairs(FALLBACK_ICON) do CheckIcon(icon) end

    -- All emotes the game knows, as a base for the full selection list later.
    probe.allTokens = {}
    for token, i in pairs(GetBlizzardIndex()) do
        probe.allTokens[token] = _G["EMOTE" .. i .. "_CMD1"] or false
    end

    ns.Print(L.probeDone:format(#Emotes.list, #probe.unknownTokens, #probe.missingIcons))
end
