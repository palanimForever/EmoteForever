local addonName, ns = ...

-- English is the base. Other client languages only override the texts that differ;
-- if a translation is missing, the English text is used.
local L = {
    byAuthor = "by %s", -- branding: deliberately English in every language

    -- Chat
    helpPreview = "show all emotes with their icons (click to perform)",
    helpTest = "perform an emote, e.g. /emf test wave",
    helpTestDelayed = "same, but one second later (no key press)",
    helpProbe = "check which emotes the game knows, results in EmoteForeverDB.probe after /reload",
    testResult = "%s: %s",
    testError = "error: %s",
    unknownEmote = "Unknown emote: %s",
    probeDone = "%d emotes checked, %d unknown. Details after /reload in EmoteForeverDB.probe.",

    -- Preview window
    previewTitle = "EmoteForever – emotes and icons",
    previewAnimations = "With animation",
    previewSpeech = "With voice",
    previewClickHint = "Click: perform the emote",
    previewDefaultWheel = "Part of the default wheel",
}

local translations = {}

translations.deDE = {
    helpPreview = "alle Emotes mit Icons anzeigen (Klick führt aus)",
    helpTest = "Emote ausführen, z. B. /emf test wave",
    helpTestDelayed = "dasselbe, aber eine Sekunde später (ohne Tastendruck)",
    helpProbe = "prüfen, welche Emotes das Spiel kennt, Ergebnis nach /reload in EmoteForeverDB.probe",
    testError = "Fehler: %s",
    unknownEmote = "Unbekanntes Emote: %s",
    probeDone = "%d Emotes geprüft, %d unbekannt. Details nach /reload in EmoteForeverDB.probe.",

    previewTitle = "EmoteForever – Emotes und Icons",
    previewAnimations = "Mit Animation",
    previewSpeech = "Mit Stimme",
    previewClickHint = "Klick: Emote ausführen",
    previewDefaultWheel = "Teil des Standardrads",
}

for key, text in pairs(translations[GetLocale()] or {}) do
    L[key] = text
end

ns.L = L
