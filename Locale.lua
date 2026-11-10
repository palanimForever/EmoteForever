local addonName, ns = ...

-- English is the base. Other client languages only override the texts that differ;
-- if a translation is missing, the English text is used.
local L = {
    byAuthor = "by %s", -- branding: deliberately English in every language
    aboutLine = "%s · version %s",

    -- Key binding and wheel
    bindingWheel = "Emote wheel (hold)",
    bindingSet = "Hold the middle mouse button to open the emote wheel. Change the key with /emf.",
    bindingMissing = "Your middle mouse button is already in use. Choose a key for the emote wheel with /emf.",
    wheelNoTarget = "no target",
    wheelMoveTitle = "Drag the wheel",
    wheelMoveHint = "Right-click or click elsewhere when done",

    -- Minimap button
    tooltipKey = "Key",
    tooltipNoKey = "not set",
    actionOptions = "Settings",
    actionOpenWheel = "Open the wheel",
    actionDragMinimap = "Drag around the minimap",
    hintMinimapLeft = "Left-click: settings",
    hintMinimapRight = "Right-click: open the wheel",
    hintMinimapDrag = "Drag: move around the minimap",

    -- Chat
    helpWheel = "Hold your key (middle mouse button by default), move towards an emote, release.",
    helpOptions = "settings",
    helpEdit = "arrange the wheel",
    notInCombat = "Settings can't be opened during combat.",
    settingsReset = "All settings reset to defaults.",
    testResult = "%s: %s",
    testError = "error: %s",
    unknownEmote = "Unknown emote: %s",
    probeDone = "%d emotes checked, %d unknown. Details after /reload in EmoteForeverDB.probe.",

    -- Settings: main page
    optSectionOpen = "Opening the wheel",
    optKey = "Key",
    optKeyTip = "The key you hold to open the wheel. Any key or mouse button works, also with Shift, Ctrl or Alt. It is the same key as \"Emote wheel (hold)\" in the game's key bindings (AddOns section).",
    keyPress = "Press a key …",
    keyClickHint = "Click, then press a key. For a mouse button, click this field with it.",
    keyRightClickHint = "Right-click: remove the key. Esc: cancel.",
    keyReplaced = "%s was bound to \"%s\". It now opens the emote wheel.",
    keyNotInCombat = "The key can't be changed during combat.",
    optHowTo = "Hold, aim, release",
    optHowToButton = "Try it",
    optHowToTip = "Hold your key, move the mouse towards an emote and release. Right-click while holding cancels. A short tap keeps the wheel open, then choose with a click.",
    optClickMode = "Choose with a click",
    optClickModeTip = "Pressing the key opens the wheel and keeps it open. Click an emote to perform it. Right-click, a click elsewhere or pressing the key again closes it.",
    optFixed = "Fixed position",
    optFixedTip = "The wheel always opens at the same spot instead of at the mouse. You still choose by moving the mouse towards an emote.",
    optPosition = "Wheel position",
    optPositionButton = "Move",
    optPositionTip = "Shows the wheel so you can drag it where you like. Also turns on the fixed position.",
    optSectionWheel = "Wheel",
    optEditor = "Emotes on the wheel",
    optEditorButton = "Arrange",
    optEditorTip = "Choose which emote sits on which slot.",
    optSize = "Number of slots",
    optSizeTip = "New slots get popular emotes; you can change them in the editor.",
    optScale = "Size",
    optSectionMore = "More",
    optMinimap = "Minimap button",
    optMinimapTip = "Left-click: settings. Right-click: open the wheel.",
    optReset = "Default settings",
    optResetButton = "Reset",
    optResetTip = "Resets all settings and the wheel. Your key binding stays.",
    optResetConfirm = "Reset all EmoteForever settings and the wheel to defaults?",

    -- Settings: editor
    editorTitle = "Arrange the wheel",
    editorHint = "Click a slot in the wheel, then an emote in the list. Shift-click an emote to try it out.",
    editorOthers = "More emotes (mostly text)",
    editorSlot = "Slot %d",
    editorSlotClick = "Click: select, then choose an emote on the right",
    editorRowClick = "Click: put on slot %d",
    editorRowShiftClick = "Shift-click: try it out",
    editorReset = "Default wheel",

    -- Preview window (/emf preview) and editor sections
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
    aboutLine = "%s · Version %s",

    bindingWheel = "Emote-Rad (halten)",
    bindingSet = "Halte die mittlere Maustaste, um das Emote-Rad zu öffnen. Taste ändern mit /emf.",
    bindingMissing = "Deine mittlere Maustaste ist schon belegt. Wähle eine Taste für das Emote-Rad mit /emf.",
    wheelNoTarget = "kein Ziel",
    wheelMoveTitle = "Rad verschieben",
    wheelMoveHint = "Rechtsklick oder Klick daneben zum Beenden",

    tooltipKey = "Taste",
    tooltipNoKey = "nicht belegt",
    actionOptions = "Einstellungen",
    actionOpenWheel = "Rad öffnen",
    actionDragMinimap = "Um die Minimap ziehen",
    hintMinimapLeft = "Linksklick: Einstellungen",
    hintMinimapRight = "Rechtsklick: Rad öffnen",
    hintMinimapDrag = "Ziehen: um die Minimap verschieben",

    helpWheel = "Taste halten (Standard: mittlere Maustaste), Richtung Emote bewegen, loslassen.",
    helpOptions = "Einstellungen",
    helpEdit = "Rad belegen",
    notInCombat = "Die Einstellungen lassen sich im Kampf nicht öffnen.",
    settingsReset = "Alle Einstellungen auf Standard zurückgesetzt.",
    testError = "Fehler: %s",
    unknownEmote = "Unbekanntes Emote: %s",
    probeDone = "%d Emotes geprüft, %d unbekannt. Details nach /reload in EmoteForeverDB.probe.",

    optSectionOpen = "Rad öffnen",
    optKey = "Taste",
    optKeyTip = "Die Taste, die du hältst, um das Rad zu öffnen. Jede Taste und Maustaste geht, auch mit Shift, Strg oder Alt. Es ist dieselbe Taste wie „Emote-Rad (halten)“ in der Tastenbelegung des Spiels (Abschnitt AddOns).",
    keyPress = "Taste drücken …",
    keyClickHint = "Klicken, dann eine Taste drücken. Für eine Maustaste dieses Feld mit ihr anklicken.",
    keyRightClickHint = "Rechtsklick: Taste entfernen. Esc: abbrechen.",
    keyReplaced = "%s war mit „%s“ belegt. Jetzt öffnet sie das Emote-Rad.",
    keyNotInCombat = "Die Taste lässt sich im Kampf nicht ändern.",
    optHowTo = "Halten, zielen, loslassen",
    optHowToButton = "Ausprobieren",
    optHowToTip = "Taste halten, Maus Richtung Emote bewegen und loslassen. Rechtsklick während des Haltens bricht ab. Kurz antippen lässt das Rad offen, dann per Klick wählen.",
    optClickMode = "Per Klick wählen",
    optClickModeTip = "Ein Tastendruck öffnet das Rad und lässt es offen. Ein Klick auf ein Emote führt es aus. Rechtsklick, Klick daneben oder erneuter Tastendruck schließt es.",
    optFixed = "Feste Position",
    optFixedTip = "Das Rad öffnet immer an derselben Stelle statt an der Maus. Gewählt wird weiterhin per Mausbewegung Richtung Emote.",
    optPosition = "Position des Rads",
    optPositionButton = "Verschieben",
    optPositionTip = "Zeigt das Rad, damit du es an die gewünschte Stelle ziehen kannst. Schaltet auch die feste Position ein.",
    optSectionWheel = "Rad",
    optEditor = "Emotes im Rad",
    optEditorButton = "Belegen",
    optEditorTip = "Lege fest, welches Emote auf welchem Feld liegt.",
    optSize = "Anzahl der Felder",
    optSizeTip = "Neue Felder bekommen beliebte Emotes, die du im Editor ändern kannst.",
    optScale = "Größe",
    optSectionMore = "Weiteres",
    optMinimap = "Minimap-Button",
    optMinimapTip = "Linksklick: Einstellungen. Rechtsklick: Rad öffnen.",
    optReset = "Standardeinstellungen",
    optResetButton = "Zurücksetzen",
    optResetTip = "Setzt alle Einstellungen und das Rad zurück. Deine Tastenbelegung bleibt.",
    optResetConfirm = "Alle Einstellungen von EmoteForever und das Rad auf Standard zurücksetzen?",

    editorTitle = "Rad belegen",
    editorHint = "Klicke ein Feld im Rad an, dann ein Emote in der Liste. Shift-Klick auf ein Emote spielt es zum Ausprobieren ab.",
    editorOthers = "Weitere Emotes (meist nur Text)",
    editorSlot = "Feld %d",
    editorSlotClick = "Klick: auswählen, dann rechts ein Emote wählen",
    editorRowClick = "Klick: auf Feld %d legen",
    editorRowShiftClick = "Shift-Klick: ausprobieren",
    editorReset = "Standardrad",

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
