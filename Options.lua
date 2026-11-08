local addonName, ns = ...
local L = ns.L

-- Settings under Options → AddOns → EmoteForever, built with Blizzard's Settings API.
-- Main page: how to open the wheel, its look, minimap button, reset. Sub page: the wheel editor (Editor.lua).
local Options = { settings = {}, categories = {} }
ns.Options = Options

StaticPopupDialogs["EMOTEFOREVER_RESET_SETTINGS"] = {
    text = L.optResetConfirm,
    button1 = YES,
    button2 = NO,
    OnAccept = function() Options:ResetToDefaults() end,
    showAlert = true,
    hideOnEscape = true,
    whileDead = true,
    timeout = 0,
}

-- Add every element through Settings.RegisterInitializer: it inserts into the page layout in secure
-- execution. Settings.CreateCheckbox & co. (and layout:AddInitializer) insert from our code instead,
-- which taints the layout. Blizzard's settings search reads every layout, so a search would then run
-- tainted and get blocked on protected calls of other entries (e.g. the Discord button).
local function Add(category, initializer)
    Settings.RegisterInitializer(category, initializer)
    return initializer
end

local function Header(category, text)
    Add(category, CreateSettingsListSectionHeaderInitializer(text))
end

-- No search tags: AddSearchTags would run in our code and taint the tags the search reads.
local function Button(category, name, buttonText, onClick, tooltip)
    Add(category, CreateSettingsButtonInitializer(name, buttonText, onClick, tooltip, false))
end

local function Register(category, key, name, onChange)
    local default = ns.defaults[key]
    local setting = Settings.RegisterAddOnSetting(category, "EmoteForever_" .. key, key, EmoteForeverDB,
        type(default), name, default)
    setting:SetValueChangedCallback(function()
        if onChange then onChange() end
        ns.ApplySettings()
    end)
    Options.settings[key] = setting
    return setting
end

local function Checkbox(category, key, name, tooltip)
    return Add(category, Settings.CreateCheckboxInitializer(Register(category, key, name), nil, tooltip))
end

local function Slider(category, key, name, tooltip, min, max, step, formatter, onChange)
    local options = Settings.CreateSliderOptions(min, max, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatter)
    return Add(category, Settings.CreateSliderInitializer(Register(category, key, name, onChange), options, tooltip))
end

-- The key is set on Blizzard's key binding page (section "AddOns"). Deliberately no embedded
-- key binding row: CreateKeybindingEntryInitializer replaces MatchesSearchTags with a function
-- created in our code, and the settings search calls it on every search (tainted).
-- The search still finds the binding through Blizzard's own key binding entries.
local function OpenKeyBindings()
    if InCombatLockdown() then
        ns.Print(L.notInCombat)
        return
    end
    Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID, ADDONS)
end

local function RegisterMainPage(category)
    Header(category, L.optSectionOpen)
    if Settings.KEYBINDINGS_CATEGORY_ID then
        Button(category, L.optKey, L.optKeyButton, OpenKeyBindings, L.optKeyTip)
    end
    Button(category, L.optHowTo, L.optHowToButton, function() ns.Wheel:Open(true) end, L.optHowToTip)
    Checkbox(category, "wheelFixed", L.optFixed, L.optFixedTip)
    -- Moving the wheel implies the fixed position, so the button also turns it on.
    Button(category, L.optPosition, L.optPositionButton, function()
        Options:SetValue("wheelFixed", true)
        ns.Wheel:StartMoving()
    end, L.optPositionTip)

    Header(category, L.optSectionWheel)
    Button(category, L.optEditor, L.optEditorButton, function() Options:OpenEditor() end, L.optEditorTip)
    Slider(category, "wheelSize", L.optSize, L.optSizeTip, ns.MIN_SLOTS, ns.MAX_SLOTS, 1, nil, ns.ResizeWheel)
    Slider(category, "wheelScale", L.optScale, nil, 70, 150, 5, function(value)
        return string.format("%d %%", value)
    end)

    Header(category, L.optSectionMore)
    Checkbox(category, "showMinimapButton", L.optMinimap, L.optMinimapTip)
    -- Our own button instead of Blizzard's "Defaults", which resets either the whole game (including
    -- key bindings) or only the page that is currently open.
    Button(category, L.optReset, L.optResetButton,
        function() StaticPopup_Show("EMOTEFOREVER_RESET_SETTINGS") end, L.optResetTip)

    -- End of the main page: name, author and version.
    Header(category, L.aboutLine:format(ns.BrandLine(), ns.VERSION))
end

-- Hide Blizzard's "Defaults" button (top right) on our pages (see above) and show it again on
-- other pages. We only touch it when necessary.
local function HideDefaultsButtonOnOurPages()
    local button = SettingsPanel:GetSettingsList().Header.DefaultsButton
    local hiddenByUs = false

    local function IsOurs(category)
        return category and Options.categories[category] or false
    end

    hooksecurefunc(SettingsPanel, "DisplayCategory", function(_, category)
        if IsOurs(category) then
            button:Hide()
            hiddenByUs = true
        elseif hiddenByUs then
            button:Show()
            hiddenByUs = false
        end
    end)
    -- Blizzard shows it again e.g. after the search box is cleared.
    button:HookScript("OnShow", function()
        if IsOurs(SettingsPanel:GetCurrentCategory()) then
            button:Hide()
            hiddenByUs = true
        end
    end)
end

function Options:Register()
    local category = Settings.RegisterVerticalLayoutCategory(addonName)
    RegisterMainPage(category)

    local editorCategory = Settings.RegisterCanvasLayoutSubcategory(category, ns.Editor:Create(), L.editorTitle)

    Settings.RegisterAddOnCategory(category)
    self.category, self.editorCategory = category, editorCategory
    self.categories[category], self.categories[editorCategory] = true, true
    HideDefaultsButtonOnOurPages()
end

local function OpenCategory(category)
    if InCombatLockdown() then
        ns.Print(L.notInCombat)
        return
    end
    Settings.OpenToCategory(category:GetID())
end

function Options:Open()
    OpenCategory(self.category)
end

function Options:OpenEditor()
    OpenCategory(self.editorCategory)
end

-- Change a setting from outside so the settings panel stays in sync.
function Options:SetValue(key, value)
    local setting = self.settings[key]
    if setting then
        setting:SetValue(value)
    else
        EmoteForeverDB[key] = value
        ns.ApplySettings()
    end
end

-- Reset through the registered settings so an open settings panel stays in sync.
-- The minimap button keeps its position.
function Options:ResetToDefaults()
    EmoteForeverDB.wheel = ns.GetDefault("wheel")
    for key in pairs(ns.defaults) do
        if key ~= "wheel" and key ~= "minimap" then self:SetValue(key, ns.GetDefault(key)) end
    end
    ns.ApplySettings()
    ns.Print(L.settingsReset)
end
