local addonName, ns = ...
local L = ns.L

-- The emote wheel: opens at the mouse cursor while the key binding is held.
-- Hold mode: move the mouse towards an emote and release the key.
-- Click mode: a short tap keeps the wheel open; click to perform, click outside to close.
-- The selection follows the direction from the wheel center, so slots never need the mouse;
-- in hold mode the wheel ignores the mouse completely, so the key release reaches the binding.
--
-- The look (disc, slots, portrait, pointer) is a reusable view: Wheel.CreateView builds it for the
-- wheel in the world and for the preview in the editor.

local Wheel = {}
ns.Wheel = Wheel

local RADIUS = { symbols = 92, names = 104 } -- distance of the slot centers from the wheel center
local DEAD_ZONE = 24 -- pixels around the center without a selection
local TAP_TIME = 0.25 -- seconds; a shorter press opens the click mode
local REOPEN_BLOCK = 0.1 -- seconds; a click outside closes the wheel and must not reopen it via the binding
local FADE_TIME = 0.08

-- Colors: bronze like the ring of Forever's unit frames instead of Blizzard's yellow gold.
local BRONZE = CreateColor(0.82, 0.58, 0.30)
local BRONZE_BRIGHT = CreateColor(1, 0.84, 0.60) -- selected slot, emote name
local BRONZE_GLOW = CreateColor(0.9, 0.55, 0.25) -- additive glow behind the selected symbol
ns.BRONZE, ns.BRONZE_BRIGHT = BRONZE, BRONZE_BRIGHT

-- Slot: dark round background with the symbol, framed by the same bronze ring as the center.
local SLOT_SIZE = 46
local SLOT_RING_SIZE = SLOT_SIZE / 0.7 -- the ring texture's outer edge is at 70 % of its canvas
local SLOT_BACKGROUND_SIZE = 38 -- fills the ring's inner opening
local SLOT_SYMBOL_SIZE = 30
local SELECTED_SCALE = 1.15

local PLATE_HEIGHT = 26
local PLATE_PADDING = 14
local PLATE_BORDER_COLOR = { 0.55, 0.38, 0.18 }

local DISC_SIZE = 300
local DISC_ALPHA = 0.6
-- Text below the wheel at fixed positions (from the wheel center), so nothing moves when the name changes.
local NAME_OFFSET = 140 -- top of the emote name
local TARGET_OFFSET = 184 -- middle of the target line

-- Center: the player's portrait (you perform the emote) in a bronze ring like Forever's unit frames.
-- When an emote is selected, the ring with the square corner of the player frame fades in and turns to it.
local CENTER_SIZE = 120 -- ring canvas; the ring itself is smaller to leave room for the corner
local PORTRAIT_SIZE = 70 -- fills the ring's inner opening (see ring.py in the design folder)

-- Pointer motion: a critically damped spring, so the corner glides over and stops without overshooting.
local SPRING_FREQUENCY = 20 -- rad/s; higher = faster
local SPRING_DAMPING = 1 -- 1 = fastest without overshoot; below 1 would swing past the goal
local MAX_STEP = 0.05 -- seconds; longer frames are split up so the spring stays stable
local POINTER_FADE_SPEED = 8 -- alpha per second when the corner appears or disappears

-- Target below the emote name: small portrait in the same bronze ring, name next to it.
local TARGET_RING_SIZE = 48
local TARGET_PORTRAIT_SIZE = 28

local TEXTURE_BACKGROUND = "Interface\\Minimap\\UI-Minimap-Background"
local TEXTURE_HIGHLIGHT = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local TEXTURE_RING = "Interface\\AddOns\\" .. addonName .. "\\Media\\ring"
local TEXTURE_RING_POINTER = "Interface\\AddOns\\" .. addonName .. "\\Media\\ring-pointer" -- corner up
local TEXTURE_DISC = "Interface\\AddOns\\" .. addonName .. "\\Media\\disc" -- soft round backdrop, white
ns.TEXTURE_RING = TEXTURE_RING

local PLATE_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

-- Angle of slot i in radians, slot 1 at the top, clockwise.
local function SlotAngle(i, count)
    return math.pi / 2 - (i - 1) * 2 * math.pi / count
end

-- Slot index for a direction (dx, dy from the center), or nil inside the dead zone.
function Wheel.SlotAt(dx, dy, count)
    if dx * dx + dy * dy < DEAD_ZONE * DEAD_ZONE then return nil end
    local step = 2 * math.pi / count
    -- Clockwise angle from the top, shifted by half a slot so each slot owns the sector around it.
    local angle = (math.pi / 2 - math.atan2(dy, dx) + step / 2) % (2 * math.pi)
    return math.floor(angle / step) + 1
end

local function CreateSlot(parent)
    local slot = CreateFrame("Frame", nil, parent)
    slot:SetSize(SLOT_SIZE, SLOT_SIZE)

    -- Symbol style
    local symbol = CreateFrame("Frame", nil, slot)
    symbol:SetSize(SLOT_SIZE, SLOT_SIZE)
    symbol:SetPoint("CENTER")
    slot.symbolFrame = symbol

    local background = symbol:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(TEXTURE_BACKGROUND)
    background:SetSize(SLOT_BACKGROUND_SIZE, SLOT_BACKGROUND_SIZE)
    background:SetPoint("CENTER")

    slot.icon = symbol:CreateTexture(nil, "ARTWORK")
    slot.icon:SetSize(SLOT_SYMBOL_SIZE, SLOT_SYMBOL_SIZE)
    slot.icon:SetPoint("CENTER")

    local ring = symbol:CreateTexture(nil, "OVERLAY")
    ring:SetTexture(TEXTURE_RING)
    ring:SetSize(SLOT_RING_SIZE, SLOT_RING_SIZE)
    ring:SetPoint("CENTER")

    slot.glow = symbol:CreateTexture(nil, "OVERLAY", nil, 1)
    slot.glow:SetTexture(TEXTURE_HIGHLIGHT)
    slot.glow:SetBlendMode("ADD")
    slot.glow:SetVertexColor(BRONZE_GLOW:GetRGB())
    slot.glow:SetAllPoints()

    slot.label = symbol:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    slot.label:SetPoint("TOP", symbol, "BOTTOM", 0, -1)

    -- Name style
    local plate = CreateFrame("Frame", nil, slot, "BackdropTemplate")
    plate:SetHeight(PLATE_HEIGHT)
    plate:SetPoint("CENTER")
    plate:SetBackdrop(PLATE_BACKDROP)
    plate.text = plate:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    plate.text:SetPoint("CENTER")
    slot.plate = plate

    return slot
end

local function ApplySlotStyle(slot, isSelected)
    if EmoteForeverDB.wheelStyle == "symbols" then
        slot.symbolFrame:SetScale(isSelected and SELECTED_SCALE or 1)
        slot.glow:SetShown(isSelected)
        local color = isSelected and BRONZE_BRIGHT or BRONZE
        slot.icon:SetVertexColor(color:GetRGB())
        slot.label:SetTextColor(color:GetRGB())
    else
        slot.plate:SetBackdropColor(0, 0, 0, isSelected and 0.95 or 0.75)
        if isSelected then
            slot.plate:SetBackdropBorderColor(BRONZE:GetRGB())
            slot.plate.text:SetTextColor(BRONZE_BRIGHT:GetRGB())
        else
            slot.plate:SetBackdropBorderColor(unpack(PLATE_BORDER_COLOR))
            slot.plate.text:SetTextColor(BRONZE:GetRGB())
        end
    end
end

-- View: methods mixed into the frame returned by Wheel.CreateView.
local View = {}

-- Builds the slots for the current wheel and style.
function View:Layout()
    local style = EmoteForeverDB.wheelStyle
    local tokens = EmoteForeverDB.wheel
    local radius = RADIUS[style]
    for i, token in ipairs(tokens) do
        local slot = self.slots[i] or CreateSlot(self)
        self.slots[i] = slot
        slot.index, slot.token = i, token
        local label = ns.Emotes.GetLabel(token)
        slot.icon:SetTexture(ns.Emotes.GetIcon(token))
        slot.label:SetText(label)
        slot.plate.text:SetText(label)
        slot.plate:SetWidth(slot.plate.text:GetStringWidth() + 2 * PLATE_PADDING)
        slot.symbolFrame:SetShown(style == "symbols")
        slot.plate:SetShown(style == "names")
        local angle = SlotAngle(i, #tokens)
        slot:ClearAllPoints()
        slot:SetPoint("CENTER", radius * math.cos(angle), radius * math.sin(angle))
        slot:Show()
        ApplySlotStyle(slot, i == self.selected)
    end
    for i = #tokens + 1, #self.slots do self.slots[i]:Hide() end
    if self.selected and self.selected > #tokens then self:SetSelected(nil) end
    if self.selected then self.pointer.goal = SlotAngle(self.selected, #tokens) end
end

function View:SetSelected(index)
    if index == self.selected then return end
    local previous = self.slots[self.selected]
    if previous then ApplySlotStyle(previous, false) end
    self.selected = index
    local pointer = self.pointer
    if index then
        ApplySlotStyle(self.slots[index], true)
        if self.name then self.name:SetText(ns.Emotes.GetLabel(self.slots[index].token)) end
        pointer.goal = SlotAngle(index, #EmoteForeverDB.wheel)
        if pointer.alpha == 0 then -- appearing: start at the goal instead of swinging in from the old angle
            pointer.angle, pointer.velocity = pointer.goal, 0
        end
        pointer.alphaGoal = 1
    else
        if self.name then self.name:SetText("") end
        pointer.alphaGoal = 0
    end
end

-- Hides the pointer at once (e.g. when the wheel opens).
function View:ResetPointer()
    self.pointer.alpha = 0
    self:Animate(0)
end

-- Moves the pointer ring towards its goal (spring) and fades its corner in or out.
function View:Animate(elapsed)
    local pointer = self.pointer
    local omega = SPRING_FREQUENCY
    while elapsed > 0 do
        local dt = math.min(elapsed, MAX_STEP)
        elapsed = elapsed - dt
        -- Shortest way around: the difference wrapped into -pi .. pi.
        local diff = (pointer.angle - pointer.goal + math.pi) % (2 * math.pi) - math.pi
        local acceleration = -omega * omega * diff - 2 * SPRING_DAMPING * omega * pointer.velocity
        pointer.velocity = pointer.velocity + acceleration * dt
        pointer.angle = pointer.angle + pointer.velocity * dt

        local step = POINTER_FADE_SPEED * dt
        pointer.alpha = math.max(math.min(pointer.alpha + step, pointer.alphaGoal), pointer.alpha - step)
    end
    self.pointerRing:SetRotation(pointer.angle - math.pi / 2) -- the corner points up in the texture
    self.pointerRing:SetAlpha(pointer.alpha)
    self.roundRing:SetAlpha(1 - pointer.alpha)
end

function View:UpdatePlayerPortrait()
    SetPortraitTexture(self.portrait, "player")
end

-- Shows the current target under the emote name: small portrait and name
-- (or a hint that the emote goes to no one).
-- The name can be a secret value for NPCs: no comparisons or string operations, straight to the widget.
function View:UpdateTarget()
    local name = UnitName("target")
    local hasTarget = issecretvalue(name) or name ~= nil
    if hasTarget then
        self.target:SetText(name)
        self.target:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
        SetPortraitTexture(self.targetPortrait, "target") -- round by default (Blizzard mask)
    else
        self.target:SetText(L.wheelNoTarget)
        self.target:SetTextColor(GRAY_FONT_COLOR:GetRGB())
    end
    self.targetPortrait:SetShown(hasTarget)
    self.targetRing:SetShown(hasTarget)
end

-- withTexts: emote name and target below the wheel (the wheel in the world; the editor has its own).
function Wheel.CreateView(parent, withTexts)
    local view = CreateFrame("Frame", nil, parent)
    Mixin(view, View)
    view:SetSize(DISC_SIZE, DISC_SIZE)
    view.slots = {}
    view.pointer = { angle = 0, velocity = 0, goal = 0, alpha = 0, alphaGoal = 0 }

    local disc = view:CreateTexture(nil, "BACKGROUND")
    disc:SetTexture(TEXTURE_DISC)
    disc:SetAllPoints()
    disc:SetVertexColor(0, 0, 0, DISC_ALPHA)

    view.portrait = view:CreateTexture(nil, "ARTWORK")
    view.portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
    view.portrait:SetPoint("CENTER")
    -- Round ring and pointer ring crossfade (the round arc would show inside the corner otherwise).
    view.roundRing = view:CreateTexture(nil, "OVERLAY", nil, 1)
    view.roundRing:SetSize(CENTER_SIZE, CENTER_SIZE)
    view.roundRing:SetPoint("CENTER")
    view.roundRing:SetTexture(TEXTURE_RING)
    view.pointerRing = view:CreateTexture(nil, "OVERLAY", nil, 2)
    view.pointerRing:SetSize(CENTER_SIZE, CENTER_SIZE)
    view.pointerRing:SetPoint("CENTER")
    view.pointerRing:SetTexture(TEXTURE_RING_POINTER)
    view.pointerRing:SetAlpha(0)

    if withTexts then
        view.name = view:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        view.name:SetTextColor(BRONZE_BRIGHT:GetRGB())
        view.name:SetPoint("TOP", view, "CENTER", 0, -NAME_OFFSET)
        view.target = view:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        view.target:SetPoint("CENTER", view, "CENTER", 0, -TARGET_OFFSET)
        -- Portrait left of the (centered) name; anchored instead of measured, the name may be a secret value.
        view.targetPortrait = view:CreateTexture(nil, "ARTWORK")
        view.targetPortrait:SetSize(TARGET_PORTRAIT_SIZE, TARGET_PORTRAIT_SIZE)
        view.targetPortrait:SetPoint("RIGHT", view.target, "LEFT", -6, 0)
        view.targetRing = view:CreateTexture(nil, "OVERLAY")
        view.targetRing:SetTexture(TEXTURE_RING)
        view.targetRing:SetSize(TARGET_RING_SIZE, TARGET_RING_SIZE)
        view.targetRing:SetPoint("CENTER", view.targetPortrait)
    end

    view:Layout()
    return view
end

-- The wheel in the world ----------------------------------------------------------------------------

local mode -- nil (closed) | "hold" | "click"
local openedAt, closedAt = 0, 0

-- Selection from the mouse direction relative to the wheel center.
local function UpdateSelection(view)
    local scale = view:GetEffectiveScale()
    local x, y = GetCursorPosition()
    local centerX, centerY = view:GetCenter()
    view:SetSelected(Wheel.SlotAt(x / scale - centerX, y / scale - centerY, #EmoteForeverDB.wheel))
end

function Wheel:Init()
    local view = Wheel.CreateView(UIParent, true)
    view:SetFrameStrata("DIALOG")
    view:SetClampedToScreen(true)
    view:Hide()

    local fadeIn = view:CreateAnimationGroup()
    local alpha = fadeIn:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0)
    alpha:SetToAlpha(1)
    alpha:SetDuration(FADE_TIME)
    view.fadeIn = fadeIn

    -- Click mode: a click on the wheel performs the selection; GLOBAL_MOUSE_DOWN closes on clicks elsewhere.
    view:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then Wheel.Perform() end
        Wheel:Close()
    end)
    view:SetScript("OnEvent", function(_, event, button) -- button = unit for UNIT_PORTRAIT_UPDATE
        if event == "GLOBAL_MOUSE_DOWN" and mode == "click" and not view:IsMouseOver() then
            Wheel:Close()
        elseif event == "GLOBAL_MOUSE_UP" and mode == "hold" and button == "MiddleButton" then
            -- Safety net: the binding's key-up can be lost (e.g. while the game window loses focus).
            Wheel:Release()
        elseif event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_PORTRAIT_UPDATE" and button == "target") then
            view:UpdateTarget()
        elseif event == "UNIT_PORTRAIT_UPDATE" then
            view:UpdatePlayerPortrait()
        end
    end)
    view:SetScript("OnUpdate", function(_, elapsed) -- only runs while the wheel is shown
        UpdateSelection(view)
        view:Animate(elapsed)
    end)

    self.frame = view
    self:ApplySettings()
end

function Wheel:ApplySettings()
    if not self.frame then return end
    self.frame:SetScale(EmoteForeverDB.wheelScale / 100)
    self.frame:Layout()
end

function Wheel:Open(asClickMode)
    if not self.frame then self:Init() end
    if mode then self:Close() end
    local view = self.frame
    local scale = view:GetEffectiveScale()
    local x, y = GetCursorPosition()
    view:ClearAllPoints()
    view:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)

    mode = asClickMode and "click" or "hold"
    openedAt = GetTime()
    view:SetSelected(nil)
    view:ResetPointer()
    view:UpdatePlayerPortrait()
    view:UpdateTarget()
    view:EnableMouse(mode == "click")
    view:RegisterEvent("GLOBAL_MOUSE_DOWN")
    view:RegisterEvent("GLOBAL_MOUSE_UP")
    view:RegisterEvent("PLAYER_TARGET_CHANGED")
    view:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player", "target")
    view:Show()
    view.fadeIn:Play()
end

function Wheel:Close()
    if not self.frame then return end
    mode = nil
    closedAt = GetTime()
    self.frame:UnregisterAllEvents()
    self.frame:EnableMouse(false)
    self.frame:Hide()
end

function Wheel.Perform()
    local view = Wheel.frame
    local slot = view and view.slots[view.selected]
    if slot then ns.PerformEmote(slot.token, "wheel") end
end

-- Key released in hold mode: perform, or switch to click mode after a short tap.
function Wheel:Release()
    if mode ~= "hold" then return end
    if self.frame.selected then
        Wheel.Perform()
        self:Close()
    elseif GetTime() - openedAt < TAP_TIME then
        mode = "click"
        self.frame:EnableMouse(true)
    else
        self:Close()
    end
end

function Wheel:OnKey(keystate)
    if keystate == "down" then
        if mode then
            self:Close() -- pressing again closes the click mode
        elseif GetTime() - closedAt > REOPEN_BLOCK then
            self:Open(false)
        end
    else
        self:Release()
    end
end

-- Called by Bindings.xml (binding code runs in the global environment).
function EmoteForever_OnWheelKey(keystate)
    Wheel:OnKey(keystate)
end
