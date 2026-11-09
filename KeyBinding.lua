local addonName, ns = ...
local L = ns.L

-- The "Key" row on our settings page: click it, then press a key or mouse button.
-- Not Blizzard's own key binding row (CreateKeybindingEntryInitializer): that one replaces
-- MatchesSearchTags with a function from our code, which taints the settings search. This row is
-- our own template, created like Blizzard's button rows (Settings.CreateElementInitializer).
-- The binding is the game's own, so Blizzard's key bindings page shows the same key.

local KeyBinding = {}
ns.KeyBinding = KeyBinding

function KeyBinding.Text()
    local key1, key2 = GetBindingKey(ns.BINDING)
    if not key1 then return nil end
    local text = GetBindingText(key1)
    if key2 then text = text .. ", " .. GetBindingText(key2) end
    return text
end

local function ClearOwnKeys()
    local key1, key2 = GetBindingKey(ns.BINDING)
    if key1 then SetBinding(key1) end
    if key2 then SetBinding(key2) end
end

-- Like Blizzard's key bindings page: the new key wins, the action that had it is named in chat.
local function Bind(key)
    local previous = GetBindingAction(key)
    ClearOwnKeys()
    SetBinding(key, ns.BINDING)
    SaveBindings(GetCurrentBindingSet())
    if previous ~= "" and previous ~= ns.BINDING then
        ns.Print(L.keyReplaced:format(GetBindingText(key), GetBindingName(previous)))
    end
end

local function Unbind()
    ClearOwnKeys()
    SaveBindings(GetCurrentBindingSet())
end

-- Row mixin, used by EmoteForeverKeyBindingRowTemplate (KeyBinding.xml).
EmoteForeverKeyBindingRowMixin = CreateFromMixins(SettingsListElementMixin)
local Row = EmoteForeverKeyBindingRowMixin

local function ShowButtonTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.optKey)
    GameTooltip:AddLine(L.keyClickHint, 1, 1, 1, true)
    GameTooltip:AddLine(L.keyRightClickHint, 1, 1, 1, true)
    GameTooltip:Show()
end

function Row:OnLoad()
    SettingsListElementMixin.OnLoad(self)
    local button = self.Button
    button:SetScript("OnClick", function(_, mouseButton) self:OnButtonClick(mouseButton) end)
    button:SetScript("OnKeyDown", function(_, key) self:OnKeyDown(key) end)
    button:SetScript("OnKeyUp", function(_, key) self:OnKeyUp(key) end)
    button:SetScript("OnEnter", ShowButtonTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- An OnKeyDown script switches the keyboard on, which would swallow every key (no movement)
    -- while the settings are open. Only on while waiting for a key.
    button:EnableKeyboard(false)
end

function Row:Init(initializer)
    SettingsListElementMixin.Init(self, initializer)
    self.Button:SetPoint("LEFT", self, "CENTER", -40, 0)
    self:StopCapture()
end

function Row:Release()
    self:StopCapture()
    SettingsListElementMixin.Release(self)
end

function Row:OnShow()
    self:RegisterEvent("UPDATE_BINDINGS")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:Refresh()
end

function Row:OnHide()
    self:StopCapture()
    self:UnregisterAllEvents()
end

function Row:OnEvent(event)
    if event == "PLAYER_REGEN_DISABLED" then
        self:StopCapture()
    else
        self:Refresh()
    end
end

function Row:Refresh()
    local button = self.Button
    if self.capturing then
        button:SetText(L.keyPress)
        button:GetFontString():SetTextColor(NORMAL_FONT_COLOR:GetRGB())
        return
    end
    local text = KeyBinding.Text()
    button:SetText(text or NOT_BOUND)
    local color = text and HIGHLIGHT_FONT_COLOR or GRAY_FONT_COLOR
    button:GetFontString():SetTextColor(color:GetRGB())
end

function Row:StartCapture()
    self.capturing = true
    self.pendingKey, self.pendingChord = nil, nil
    self.Button:SetSelected(true)
    self.Button:SetPropagateKeyboardInput(false) -- out of combat only; we never start in combat
    self.Button:EnableKeyboard(true)
    self:Refresh()
end

function Row:StopCapture()
    self.capturing = false
    self.pendingKey, self.pendingChord = nil, nil
    self.Button:EnableKeyboard(false)
    self.Button:SetSelected(false)
    self:Refresh()
end

-- Mouse buttons are recorded by clicking the waiting button with them, as on Blizzard's page.
-- Left or right click while waiting cancels; right click otherwise removes the key.
function Row:OnButtonClick(mouseButton)
    if InCombatLockdown() then
        ns.Print(L.keyNotInCombat)
        return
    end
    if not self.capturing then
        if mouseButton == "RightButton" then Unbind() else self:StartCapture() end
        return
    end
    local key = GetConvertedKeyOrButton(mouseButton)
    if not IsKeyPressIgnoredForBinding(key) then Bind(CreateKeyChordStringUsingMetaKeyState(key)) end
    self:StopCapture()
end

function Row:OnKeyDown(key)
    if not self.capturing then return end
    if key == "ESCAPE" then
        self:StopCapture()
    elseif not IsKeyPressIgnoredForBinding(key) then
        self.pendingKey, self.pendingChord = key, CreateKeyChordStringUsingMetaKeyState(key)
    end
end

-- Bound when the key is let go: bound while still held, the release would reach the wheel.
function Row:OnKeyUp(key)
    if not self.capturing or key ~= self.pendingKey then return end
    if InCombatLockdown() then
        ns.Print(L.keyNotInCombat)
    else
        Bind(self.pendingChord)
    end
    self:StopCapture()
end

function KeyBinding.CreateInitializer()
    return Settings.CreateElementInitializer("EmoteForeverKeyBindingRowTemplate",
        { name = L.optKey, tooltip = L.optKeyTip })
end
