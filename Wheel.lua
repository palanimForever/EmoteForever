local addonName, ns = ...
local L = ns.L

-- The emote wheel: opens at the mouse cursor while the key binding is held.
-- Hold mode: move the mouse towards an emote and release the key.
-- Click mode: a short tap keeps the wheel open; click to perform, click outside to close.
-- The selection follows the direction from the wheel center, so slots never need the mouse;
-- in hold mode the wheel ignores the mouse completely, so the key release reaches the binding.

local Wheel = {}
ns.Wheel = Wheel

local RADIUS = { symbols = 92, names = 104 } -- distance of the slot centers from the wheel center
local DEAD_ZONE = 24 -- pixels around the center without a selection
local TAP_TIME = 0.25 -- seconds; a shorter press opens the click mode
local REOPEN_BLOCK = 0.1 -- seconds; a click outside closes the wheel and must not reopen it via the binding
local FADE_TIME = 0.08

-- Slot in the style of the minimap buttons (LibDBIcon geometry for a 31 px button, scaled up).
local SLOT_SCALE = 1.5
local SLOT_SIZE = 31 * SLOT_SCALE
local SLOT_BORDER_SIZE = 50 * SLOT_SCALE
local SLOT_BACKGROUND_SIZE = 24 * SLOT_SCALE
local SLOT_SYMBOL_SIZE = 20 * SLOT_SCALE
local SELECTED_SCALE = 1.15

local PLATE_HEIGHT = 26
local PLATE_PADDING = 14
local PLATE_BORDER_COLOR = { 0.6, 0.5, 0.3 }

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

local TEXTURE_BORDER = "Interface\\Minimap\\MiniMap-TrackingBorder"
local TEXTURE_BACKGROUND = "Interface\\Minimap\\UI-Minimap-Background"
local TEXTURE_HIGHLIGHT = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local TEXTURE_RING = "Interface\\AddOns\\" .. addonName .. "\\Media\\ring"
local TEXTURE_RING_POINTER = "Interface\\AddOns\\" .. addonName .. "\\Media\\ring-pointer" -- corner up
local TEXTURE_DISC = "Interface\\AddOns\\" .. addonName .. "\\Media\\disc" -- soft round backdrop, white

local PLATE_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local slots = {}
local selected -- index of the selected slot or nil
local mode -- nil (closed) | "hold" | "click"
local openedAt, closedAt = 0, 0
local pointer = { angle = 0, velocity = 0, goal = 0, alpha = 0, alphaGoal = 0 }

-- Angle of slot i in radians, slot 1 at the top, clockwise.
local function SlotAngle(i, count)
    return math.pi / 2 - (i - 1) * 2 * math.pi / count
end

local function CreateSlot(parent)
    local slot = CreateFrame("Frame", nil, parent)

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

    local border = symbol:CreateTexture(nil, "OVERLAY")
    border:SetTexture(TEXTURE_BORDER)
    border:SetSize(SLOT_BORDER_SIZE, SLOT_BORDER_SIZE)
    border:SetPoint("TOPLEFT")

    slot.glow = symbol:CreateTexture(nil, "OVERLAY", nil, 1)
    slot.glow:SetTexture(TEXTURE_HIGHLIGHT)
    slot.glow:SetBlendMode("ADD")
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
    local style = EmoteForeverDB.wheelStyle
    if style == "symbols" then
        slot.symbolFrame:SetScale(isSelected and SELECTED_SCALE or 1)
        slot.glow:SetShown(isSelected)
        local color = isSelected and HIGHLIGHT_FONT_COLOR or NORMAL_FONT_COLOR
        slot.icon:SetVertexColor(color:GetRGB())
        slot.label:SetTextColor(color:GetRGB())
    else
        slot.plate:SetBackdropColor(0, 0, 0, isSelected and 0.95 or 0.75)
        if isSelected then
            slot.plate:SetBackdropBorderColor(NORMAL_FONT_COLOR:GetRGB())
            slot.plate.text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
        else
            slot.plate:SetBackdropBorderColor(unpack(PLATE_BORDER_COLOR))
            slot.plate.text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
        end
    end
end

local function SetSelected(index)
    if index == selected then return end
    if selected and slots[selected] then ApplySlotStyle(slots[selected], false) end
    selected = index
    local frame = Wheel.frame
    if index then
        ApplySlotStyle(slots[index], true)
        frame.name:SetText(ns.Emotes.GetLabel(slots[index].token))
        pointer.goal = SlotAngle(index, #EmoteForeverDB.wheel)
        if pointer.alpha == 0 then -- appearing: start at the goal instead of swinging in from the old angle
            pointer.angle, pointer.velocity = pointer.goal, 0
        end
        pointer.alphaGoal = 1
    else
        frame.name:SetText("")
        pointer.alphaGoal = 0
    end
end

-- Moves the pointer ring towards its goal (spring) and fades its corner in or out.
local function AnimatePointer(elapsed)
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
    local frame = Wheel.frame
    frame.pointerRing:SetRotation(pointer.angle - math.pi / 2) -- the corner points up in the texture
    frame.pointerRing:SetAlpha(pointer.alpha)
    frame.roundRing:SetAlpha(1 - pointer.alpha)
end

-- Selection from the mouse direction relative to the wheel center.
local function UpdateSelection()
    local frame = Wheel.frame
    local scale = frame:GetEffectiveScale()
    local x, y = GetCursorPosition()
    local centerX, centerY = frame:GetCenter()
    local dx, dy = x / scale - centerX, y / scale - centerY
    if dx * dx + dy * dy < DEAD_ZONE * DEAD_ZONE then
        SetSelected(nil)
        return
    end
    local count = #EmoteForeverDB.wheel
    local step = 2 * math.pi / count
    -- Clockwise angle from the top, shifted by half a slot so each slot owns the sector around it.
    local angle = (math.pi / 2 - math.atan2(dy, dx) + step / 2) % (2 * math.pi)
    SetSelected(math.floor(angle / step) + 1)
end

-- Shows the current target under the emote name: small portrait and name
-- (or a hint that the emote goes to no one).
-- The name can be a secret value for NPCs: no comparisons or string operations, straight to the widget.
local function UpdateTarget()
    local frame = Wheel.frame
    local name = UnitName("target")
    local hasTarget = issecretvalue(name) or name ~= nil
    if hasTarget then
        frame.target:SetText(name)
        frame.target:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
        SetPortraitTexture(frame.targetPortrait, "target") -- round by default (Blizzard mask)
    else
        frame.target:SetText(L.wheelNoTarget)
        frame.target:SetTextColor(GRAY_FONT_COLOR:GetRGB())
    end
    frame.targetPortrait:SetShown(hasTarget)
    frame.targetRing:SetShown(hasTarget)
end

local function UpdatePlayerPortrait()
    SetPortraitTexture(Wheel.frame.portrait, "player")
end

function Wheel:Init()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(DISC_SIZE, DISC_SIZE)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:Hide()

    local disc = frame:CreateTexture(nil, "BACKGROUND")
    disc:SetTexture(TEXTURE_DISC)
    disc:SetAllPoints()
    disc:SetVertexColor(0, 0, 0, DISC_ALPHA)


    frame.name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.name:SetPoint("TOP", frame, "CENTER", 0, -NAME_OFFSET)
    frame.target = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.target:SetPoint("CENTER", frame, "CENTER", 0, -TARGET_OFFSET)
    -- Portrait left of the (centered) name; anchored instead of measured, the name may be a secret value.
    frame.targetPortrait = frame:CreateTexture(nil, "ARTWORK")
    frame.targetPortrait:SetSize(TARGET_PORTRAIT_SIZE, TARGET_PORTRAIT_SIZE)
    frame.targetPortrait:SetPoint("RIGHT", frame.target, "LEFT", -6, 0)
    frame.targetRing = frame:CreateTexture(nil, "OVERLAY")
    frame.targetRing:SetTexture(TEXTURE_RING)
    frame.targetRing:SetSize(TARGET_RING_SIZE, TARGET_RING_SIZE)
    frame.targetRing:SetPoint("CENTER", frame.targetPortrait)

    frame.portrait = frame:CreateTexture(nil, "ARTWORK")
    frame.portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
    frame.portrait:SetPoint("CENTER")
    -- Round ring and pointer ring crossfade (the round arc would show inside the corner otherwise).
    frame.roundRing = frame:CreateTexture(nil, "OVERLAY", nil, 1)
    frame.roundRing:SetSize(CENTER_SIZE, CENTER_SIZE)
    frame.roundRing:SetPoint("CENTER")
    frame.roundRing:SetTexture(TEXTURE_RING)
    frame.pointerRing = frame:CreateTexture(nil, "OVERLAY", nil, 2)
    frame.pointerRing:SetSize(CENTER_SIZE, CENTER_SIZE)
    frame.pointerRing:SetPoint("CENTER")
    frame.pointerRing:SetTexture(TEXTURE_RING_POINTER)
    frame.pointerRing:SetAlpha(0)

    local fadeIn = frame:CreateAnimationGroup()
    local alpha = fadeIn:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0)
    alpha:SetToAlpha(1)
    alpha:SetDuration(FADE_TIME)
    frame.fadeIn = fadeIn

    -- Click mode: a click on the wheel performs the selection; GLOBAL_MOUSE_DOWN closes on clicks elsewhere.
    frame:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and selected then Wheel.Perform() end
        Wheel:Close()
    end)
    frame:SetScript("OnEvent", function(_, event, button) -- button = unit for UNIT_PORTRAIT_UPDATE
        if event == "GLOBAL_MOUSE_DOWN" and mode == "click" and not frame:IsMouseOver() then
            Wheel:Close()
        elseif event == "GLOBAL_MOUSE_UP" and mode == "hold" and button == "MiddleButton" then
            -- Safety net: the binding's key-up can be lost (e.g. while the game window loses focus).
            Wheel:Release()
        elseif event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_PORTRAIT_UPDATE" and button == "target") then
            UpdateTarget()
        elseif event == "UNIT_PORTRAIT_UPDATE" then
            UpdatePlayerPortrait()
        end
    end)
    frame:SetScript("OnUpdate", function(_, elapsed) -- only runs while the wheel is shown
        UpdateSelection()
        AnimatePointer(elapsed)
    end)

    self.frame = frame
    self:ApplySettings()
end

-- Builds the slots for the current wheel and style.
function Wheel:ApplySettings()
    if not self.frame then return end
    local style = EmoteForeverDB.wheelStyle
    local tokens = EmoteForeverDB.wheel
    local radius = RADIUS[style]
    for i, token in ipairs(tokens) do
        local slot = slots[i] or CreateSlot(self.frame)
        slots[i] = slot
        slot.token = token
        local label = ns.Emotes.GetLabel(token)
        slot.icon:SetTexture(ns.Emotes.GetIcon(token))
        slot.label:SetText(label)
        slot.plate.text:SetText(label)
        slot.plate:SetWidth(slot.plate.text:GetStringWidth() + 2 * PLATE_PADDING)
        slot.symbolFrame:SetShown(style == "symbols")
        slot.plate:SetShown(style == "names")
        local angle = SlotAngle(i, #tokens)
        slot:SetSize(SLOT_SIZE, SLOT_SIZE)
        slot:ClearAllPoints()
        slot:SetPoint("CENTER", radius * math.cos(angle), radius * math.sin(angle))
        slot:Show()
        ApplySlotStyle(slot, false)
    end
    for i = #tokens + 1, #slots do slots[i]:Hide() end
end

function Wheel:Open(asClickMode)
    if not self.frame then self:Init() end
    local frame = self.frame
    local scale = frame:GetEffectiveScale()
    local x, y = GetCursorPosition()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)

    mode = asClickMode and "click" or "hold"
    openedAt = GetTime()
    selected = nil
    for i = 1, #EmoteForeverDB.wheel do ApplySlotStyle(slots[i], false) end
    SetSelected(nil)
    pointer.alpha = 0
    AnimatePointer(0)
    UpdatePlayerPortrait()
    UpdateTarget()
    frame:EnableMouse(mode == "click")
    frame:RegisterEvent("GLOBAL_MOUSE_DOWN")
    frame:RegisterEvent("GLOBAL_MOUSE_UP")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player", "target")
    frame:Show()
    frame.fadeIn:Play()
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
    if selected then ns.PerformEmote(slots[selected].token, "wheel") end
end

-- Key released in hold mode: perform, or switch to click mode after a short tap.
function Wheel:Release()
    if mode ~= "hold" then return end
    if selected then
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
