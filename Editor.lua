local addonName, ns = ...
local L = ns.L

-- Wheel editor: a sub page in the settings (canvas layout).
-- Left: live preview of the wheel; click a slot to select it, the pointer turns towards it.
-- Right: searchable list of all emotes; a click puts the emote on the selected slot (swapping if it is
-- already on the wheel), Shift-click performs it to try it out.

local Editor = {}
ns.Editor = Editor

local PADDING = 16
local TITLE_TOP = 16
local CONTENT_TOP = 92 -- below title and hint
local VIEW_SCALE = 0.95
local LIST_LEFT = 330
local LIST_WIDTH = 270
local LIST_BOTTOM = 56
local SEARCH_HEIGHT = 20
local ROW_HEIGHT = 24
local HEADER_HEIGHT = 26
local ROW_ICON_SIZE = 18
local BUTTON_WIDTH, BUTTON_HEIGHT = 190, 24

local selectedSlot = 1
local rows = {} -- list rows and section headers in display order
local query = ""

-- Position of an emote on the wheel, or nil.
local function WheelIndex(token)
    for i, existing in ipairs(EmoteForeverDB.wheel) do
        if existing == token then return i end
    end
end

local function RowTooltip(row)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(ns.Emotes.GetLabel(row.token))
    GameTooltip:AddLine(L.editorRowClick:format(selectedSlot), HIGHLIGHT_FONT_COLOR:GetRGB())
    GameTooltip:AddLine(L.editorRowShiftClick, GRAY_FONT_COLOR:GetRGB())
    GameTooltip:Show()
end

local function CreateRow(content, token)
    local row = CreateFrame("Button", nil, content)
    row:SetHeight(ROW_HEIGHT)
    row.token = token
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row:GetHighlightTexture():SetVertexColor(ns.BRONZE:GetRGB())

    row.selectedBg = row:CreateTexture(nil, "BACKGROUND")
    row.selectedBg:SetAllPoints()
    row.selectedBg:SetColorTexture(ns.BRONZE.r, ns.BRONZE.g, ns.BRONZE.b, 0.25)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ROW_ICON_SIZE, ROW_ICON_SIZE)
    row.icon:SetPoint("LEFT", 6, 0)
    row.icon:SetTexture(ns.Emotes.GetIcon(token))
    row.icon:SetVertexColor(ns.BRONZE:GetRGB())

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.text:SetText(ns.Emotes.GetLabel(token))
    row.searchText = (ns.Emotes.GetLabel(token) .. " " .. token):lower()

    row.slotText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.slotText:SetPoint("RIGHT", -8, 0)
    row.slotText:SetTextColor(ns.BRONZE:GetRGB())

    row:SetScript("OnClick", function(self)
        if IsShiftKeyDown() then
            ns.PerformEmote(self.token, "editor")
        else
            ns.SetWheelEmote(selectedSlot, self.token)
        end
    end)
    row:SetScript("OnEnter", RowTooltip)
    row:SetScript("OnLeave", GameTooltip_Hide)
    return row
end

local function CreateHeader(content, text)
    local header = CreateFrame("Frame", nil, content)
    header:SetHeight(HEADER_HEIGHT)
    header.isHeader = true
    header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header.text:SetPoint("BOTTOMLEFT", 4, 4)
    header.text:SetText(text)
    header.text:SetTextColor(ns.BRONZE_BRIGHT:GetRGB())
    local line = header:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", 0, 0)
    line:SetColorTexture(ns.BRONZE.r, ns.BRONZE.g, ns.BRONZE.b, 0.4)
    return header
end

local function BuildList(content)
    local function AddSection(title, tokens)
        table.insert(rows, CreateHeader(content, title))
        for _, token in ipairs(tokens) do table.insert(rows, CreateRow(content, token)) end
    end
    local anim, speech = {}, {}
    for _, emote in ipairs(ns.Emotes.list) do
        if ns.Emotes.IsAvailable(emote) then
            table.insert(emote.kind == "speech" and speech or anim, emote.token)
        end
    end
    AddSection(L.previewAnimations, anim)
    AddSection(L.previewSpeech, speech)
    AddSection(L.editorOthers, ns.Emotes.Others())
end

-- Places the rows that match the search; a section header only shows if one of its rows does.
local function LayoutList(content)
    local y = 0
    local pendingHeader
    for _, row in ipairs(rows) do
        row:Hide()
        if row.isHeader then
            pendingHeader = row
        elseif query == "" or row.searchText:find(query, 1, true) then
            if pendingHeader then
                pendingHeader:SetPoint("TOPLEFT", 0, -y)
                pendingHeader:SetPoint("RIGHT")
                pendingHeader:Show()
                y = y + HEADER_HEIGHT
                pendingHeader = nil
            end
            row:SetPoint("TOPLEFT", 0, -y)
            row:SetPoint("RIGHT")
            row:Show()
            y = y + ROW_HEIGHT
        end
    end
    content:SetHeight(math.max(y, 1))
end

-- Slot numbers on the right, the selected slot's emote highlighted.
local function UpdateRowMarks()
    local current = EmoteForeverDB.wheel[selectedSlot]
    for _, row in ipairs(rows) do
        if not row.isHeader then
            local index = WheelIndex(row.token)
            row.slotText:SetText(index and L.editorSlot:format(index) or "")
            row.selectedBg:SetShown(row.token == current)
        end
    end
end

local function SlotTooltip(slot)
    GameTooltip:SetOwner(slot, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.editorSlot:format(slot.index) .. ": " .. ns.Emotes.GetLabel(slot.token))
    GameTooltip:AddLine(L.editorSlotClick, HIGHLIGHT_FONT_COLOR:GetRGB())
    GameTooltip:Show()
end

-- Slots of the preview are clickable (unlike in the world, where the wheel ignores the mouse).
local function HookSlots(view)
    for _, slot in ipairs(view.slots) do
        if not slot.editorHooked then
            slot.editorHooked = true
            slot:EnableMouse(true)
            slot:SetScript("OnMouseDown", function(self)
                selectedSlot = self.index
                view:SetSelected(self.index)
                UpdateRowMarks()
            end)
            slot:SetScript("OnEnter", SlotTooltip)
            slot:SetScript("OnLeave", GameTooltip_Hide)
        end
    end
end

function Editor:Create()
    local frame = CreateFrame("Frame")
    frame:Hide()
    self.frame = frame

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    title:SetPoint("TOPLEFT", PADDING, -TITLE_TOP)
    title:SetText(L.editorTitle)

    local hint = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    hint:SetPoint("RIGHT", -PADDING, 0)
    hint:SetJustifyH("LEFT")
    hint:SetTextColor(GRAY_FONT_COLOR:GetRGB())
    hint:SetText(L.editorHint)

    frame:SetScript("OnShow", function() Editor:Build() Editor:Refresh() end)
    return frame
end

-- Builds the content on first show, so nothing is created for players who never open the editor.
function Editor:Build()
    if self.view then return end
    local frame = self.frame

    local view = ns.Wheel.CreateView(frame, false)
    view:SetScale(VIEW_SCALE)
    view:SetPoint("TOPLEFT", PADDING / VIEW_SCALE, -CONTENT_TOP / VIEW_SCALE)
    self.view = view
    frame:SetScript("OnUpdate", function(_, elapsed) view:Animate(elapsed) end)

    local reset = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    reset:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    reset:SetPoint("TOP", view, "BOTTOM", 0, -12)
    reset:SetText(L.editorReset)
    reset:SetScript("OnClick", function()
        EmoteForeverDB.wheel = ns.GetDefault("wheel")
        ns.Options:SetValue("wheelSize", #EmoteForeverDB.wheel)
        ns.ApplySettings()
    end)

    local search = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    search:SetSize(LIST_WIDTH - 6, SEARCH_HEIGHT)
    search:SetPoint("TOPLEFT", LIST_LEFT + 6, -CONTENT_TOP)
    search:HookScript("OnTextChanged", function(box)
        query = strtrim(box:GetText()):lower()
        LayoutList(self.content)
    end)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "ScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", LIST_LEFT, -(CONTENT_TOP + SEARCH_HEIGHT + 8))
    scroll:SetPoint("BOTTOMLEFT", LIST_LEFT, LIST_BOTTOM)
    scroll:SetWidth(LIST_WIDTH)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(LIST_WIDTH)
    scroll:SetScrollChild(content)
    self.content = content

    BuildList(content)
    LayoutList(content)
end

function Editor:Refresh()
    local view = self.view
    if not view or not self.frame:IsShown() then return end
    selectedSlot = math.min(selectedSlot, #EmoteForeverDB.wheel)
    view:Layout()
    HookSlots(view)
    view:SetSelected(selectedSlot)
    view:UpdatePlayerPortrait()
    UpdateRowMarks()
end
