local addonName, ns = ...
local L = ns.L

-- Developer preview: all emotes of the catalog as a symbol grid, to review the symbol choice.
-- Gold label = part of the default wheel, red label = emote unknown to the game.
-- Clicking an icon performs the emote (tests C_ChatInfo.PerformEmote from a mouse click).

local Preview = {}
ns.Preview = Preview

local COLUMNS = 8
local ICON_SIZE = 40
local CELL_WIDTH = 72
local CELL_HEIGHT = 62
local PADDING = 16
local HEADER_HEIGHT = 22
local TITLE_HEIGHT = 30
local SLOT_INSET = 4 -- symbol padding inside the dark slot

local function IsOnDefaultWheel(token)
    for _, wheelToken in ipairs(ns.defaults.wheel) do
        if wheelToken == token then return true end
    end
    return false
end

local function OnEnter(button)
    local token = button.token
    button.icon:SetVertexColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(ns.Emotes.GetLabel(token))
    GameTooltip:AddLine(token, GRAY_FONT_COLOR:GetRGB())
    GameTooltip:AddLine(ns.Emotes.Get(token).icon, GRAY_FONT_COLOR:GetRGB())
    if IsOnDefaultWheel(token) then
        GameTooltip:AddLine(L.previewDefaultWheel, NORMAL_FONT_COLOR:GetRGB())
    end
    GameTooltip:AddLine(L.previewClickHint, HIGHLIGHT_FONT_COLOR:GetRGB())
    GameTooltip:AddLine(ns.BrandLine(), GRAY_FONT_COLOR:GetRGB())
    GameTooltip:Show()
end

local function CreateIconButton(parent, emote)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(ICON_SIZE, ICON_SIZE)
    button.token = emote.token

    local slot = button:CreateTexture(nil, "BACKGROUND")
    slot:SetAllPoints()
    slot:SetColorTexture(0, 0, 0, 0.5)

    -- White symbol, tinted gold like Blizzard's headings; white while hovered.
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", SLOT_INSET, -SLOT_INSET)
    icon:SetPoint("BOTTOMRIGHT", -SLOT_INSET, SLOT_INSET)
    icon:SetTexture(ns.Emotes.GetIcon(emote.token))
    icon:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
    button.icon = icon

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOP", button, "BOTTOM", 0, -3)
    label:SetWidth(CELL_WIDTH - 4)
    label:SetWordWrap(false)
    label:SetText(ns.Emotes.GetLabel(emote.token))
    if not ns.Emotes.Exists(emote.token) then
        label:SetTextColor(1, 0.2, 0.2)
    elseif IsOnDefaultWheel(emote.token) then
        label:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
    end

    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", function(self)
        self.icon:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
        GameTooltip_Hide()
    end)
    button:SetScript("OnClick", function() ns.PerformEmote(emote.token, "click") end)
    return button
end

-- Places a section header and the icons of one kind below y; returns the new y.
local function AddSection(frame, title, kind, y)
    local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", PADDING, -y)
    header:SetText(title)
    y = y + HEADER_HEIGHT

    local index = 0
    for _, emote in ipairs(ns.Emotes.list) do
        if emote.kind == kind and ns.Emotes.IsAvailable(emote) then
            local column, row = index % COLUMNS, math.floor(index / COLUMNS)
            local button = CreateIconButton(frame, emote)
            button:SetPoint("TOPLEFT", PADDING + column * CELL_WIDTH + (CELL_WIDTH - ICON_SIZE) / 2,
                -(y + row * CELL_HEIGHT))
            index = index + 1
        end
    end
    return y + math.ceil(index / COLUMNS) * CELL_HEIGHT
end

function Preview:Init()
    local frame = CreateFrame("Frame", "EmoteForeverPreview", UIParent, "BasicFrameTemplateWithInset")
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    table.insert(UISpecialFrames, "EmoteForeverPreview") -- closes with Escape

    frame.TitleText:SetText(L.previewTitle)

    local y = TITLE_HEIGHT
    y = AddSection(frame, L.previewAnimations, "anim", y)
    y = AddSection(frame, L.previewSpeech, "speech", y + PADDING / 2)
    frame:SetSize(COLUMNS * CELL_WIDTH + 2 * PADDING, y + PADDING)

    self.frame = frame
end

function Preview:Toggle()
    if not self.frame then self:Init() return end
    self.frame:SetShown(not self.frame:IsShown())
end
