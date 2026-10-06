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

local function Header(category, text)
    local layout = SettingsPanel:GetLayout(category)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
end

local function Button(category, name, buttonText, onClick, tooltip)
    local layout = SettingsPanel:GetLayout(category)
    layout:AddInitializer(CreateSettingsButtonInitializer(name, buttonText, onClick, tooltip, true))
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
    return Settings.CreateCheckbox(category, Register(category, key, name), tooltip)
end

local function Slider(category, key, name, tooltip, min, max, step, formatter, onChange)
    local options = Settings.CreateSliderOptions(min, max, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatter)
    return Settings.CreateSlider(category, Register(category, key, name, onChange), options, tooltip)
end

-- Blizzard's own key binding row (as in Options → Keybindings): click it, then press a key or mouse button.
local function KeyBinding(category)
    local bindingIndex = C_KeyBindings and C_KeyBindings.GetBindingIndex(ns.BINDING)
    if not bindingIndex then return end
    local initializer = CreateKeybindingEntryInitializer(bindingIndex, true)
    initializer:AddSearchTags(L.bindingWheel)
    SettingsPanel:GetLayout(category):AddInitializer(initializer)
end

local function RegisterMainPage(category)
    Header(category, L.optSectionOpen)
    KeyBinding(category)
    Button(category, L.optHowTo, L.optHowToButton, function() ns.Wheel:Open(true) end, L.optHowToTip)

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
