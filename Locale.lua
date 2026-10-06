local addonName, ns = ...

-- English is the base. Other client languages only override the texts that differ;
-- if a translation is missing, the English text is used.
local L = {
    byAuthor = "by %s", -- branding: deliberately English in every language

    -- Key binding and wheel
    bindingWheel = "Emote wheel (hold)",
    bindingSet = "Hold the middle mouse button to open the emote wheel. Change it under Options → Keybindings → AddOns.",
    bindingMissing = "Your middle mouse button is already in use. Choose a key for the emote wheel under Options → Keybindings → AddOns.",
    wheelNoTarget = "no target",
    styleSymbols = "Wheel style: symbols with names.",
    styleNames = "Wheel style: names only.",

    -- Chat
    helpWheel = "Hold the middle mouse button (or your key binding), move towards an emote, release.",
    helpStyle = "switch the wheel between symbols and names",
    helpPreview = "show all emotes with their symbols (click to perform)",
    helpTest = "perform an emote, e.g. /emf test wave",
    helpTestDelayed = "same, but one second later (no key press)",
    helpProbe = "check which emotes the game knows, results in EmoteForeverDB.probe after /reload",
    testResult = "%s: %s",
    testError = "error: %s",
    unknownEmote = "Unknown emote: %s",
    probeDone = "%d emotes checked, %d unknown. Details after /reload in EmoteForeverDB.probe.",

    -- Preview window
    previewTitle = "EmoteForever – emotes and symbols",
    previewAnimations = "With animation",
    previewSpeech = "With voice",
    previewClickHint = "Click: perform the emote",
    previewDefaultWheel = "Part of the default wheel",

    -- Names of the catalog emotes. Emotes not listed here use the game's slash command as their name.
    emotes = {
        WAVE = "Wave", BOW = "Bow", DANCE = "Dance", APPLAUD = "Applaud", BEG = "Beg", CHICKEN = "Chicken",
        CRY = "Cry", EAT = "Eat", FLEX = "Flex", KISS = "Kiss", LAUGH = "Laugh", POINT = "Point", ROAR = "Roar",
        RUDE = "Rude", SALUTE = "Salute", SHY = "Shy", TALK = "Talk", STAND = "Stand", SIT = "Sit", SLEEP = "Sleep",
        KNEEL = "Kneel", LEAN = "Lean", HUG = "Hug", CLAP = "Clap",
        HELPME = "Help me!", INCOMING = "Incoming!", CHARGE = "Charge!", FLEE = "Flee!",
        ATTACKMYTARGET = "Attack my target", OOM = "Out of mana", FOLLOW = "Follow me", WAIT = "Wait",
        HEALME = "Heal me!", CHEER = "Cheer", OPENFIRE = "Open fire!", RASP = "Raspberry", HELLO = "Hello",
        BYE = "Bye", NOD = "Nod", NO = "No", THANK = "Thank", WELCOME = "Welcome", CONGRATULATE = "Congratulate",
        FLIRT = "Flirt", JOKE = "Joke", TRAIN = "Train",
        FORTHEALLIANCE = "For the Alliance!", FORTHEHORDE = "For the Horde!",
    },
}

local translations = {}

translations.deDE = {
    bindingWheel = "Emote-Rad (halten)",
    bindingSet = "Halte die mittlere Maustaste, um das Emote-Rad zu öffnen. Ändern unter Optionen → Tastaturbelegung → AddOns.",
    bindingMissing = "Deine mittlere Maustaste ist schon belegt. Wähle eine Taste für das Emote-Rad unter Optionen → Tastaturbelegung → AddOns.",
    wheelNoTarget = "kein Ziel",
    styleSymbols = "Rad-Stil: Symbole mit Namen.",
    styleNames = "Rad-Stil: nur Namen.",

    helpWheel = "Mittlere Maustaste (oder deine Taste) halten, Richtung Emote bewegen, loslassen.",
    helpStyle = "Rad zwischen Symbolen und Namen umschalten",
    helpPreview = "alle Emotes mit Symbolen anzeigen (Klick führt aus)",
    helpTest = "Emote ausführen, z. B. /emf test wave",
    helpTestDelayed = "dasselbe, aber eine Sekunde später (ohne Tastendruck)",
    helpProbe = "prüfen, welche Emotes das Spiel kennt, Ergebnis nach /reload in EmoteForeverDB.probe",
    testError = "Fehler: %s",
    unknownEmote = "Unbekanntes Emote: %s",
    probeDone = "%d Emotes geprüft, %d unbekannt. Details nach /reload in EmoteForeverDB.probe.",

    previewTitle = "EmoteForever – Emotes und Symbole",
    previewAnimations = "Mit Animation",
    previewSpeech = "Mit Stimme",
    previewClickHint = "Klick: Emote ausführen",
    previewDefaultWheel = "Teil des Standardrads",

    emotes = {
        WAVE = "Winken", BOW = "Verbeugen", DANCE = "Tanzen", APPLAUD = "Applaudieren", BEG = "Betteln",
        CHICKEN = "Huhn", CRY = "Weinen", EAT = "Essen", FLEX = "Muskeln zeigen", KISS = "Kuss", LAUGH = "Lachen",
        POINT = "Zeigen", ROAR = "Brüllen", RUDE = "Unhöflich", SALUTE = "Salutieren", SHY = "Schüchtern",
        TALK = "Reden", STAND = "Aufstehen", SIT = "Sitzen", SLEEP = "Schlafen", KNEEL = "Knien", LEAN = "Anlehnen",
        HUG = "Umarmen", CLAP = "Klatschen",
        HELPME = "Hilfe!", INCOMING = "Achtung!", CHARGE = "Angriff!", FLEE = "Rückzug!",
        ATTACKMYTARGET = "Ziel angreifen", OOM = "Kein Mana", FOLLOW = "Folgt mir", WAIT = "Warten",
        HEALME = "Heilt mich!", CHEER = "Jubeln", OPENFIRE = "Feuer frei!", RASP = "Zunge zeigen", HELLO = "Hallo",
        BYE = "Tschüss", NOD = "Nicken", NO = "Nein", THANK = "Danke", WELCOME = "Willkommen",
        CONGRATULATE = "Gratulieren", FLIRT = "Flirten", JOKE = "Witz", TRAIN = "Zug",
        FORTHEALLIANCE = "Für die Allianz!", FORTHEHORDE = "Für die Horde!",
    },
}

for key, text in pairs(translations[GetLocale()] or {}) do
    L[key] = text
end

ns.L = L
