local addonName, ns = ...
local L = ns.L

-- Minimap button via LibDBIcon: round, can be dragged around the minimap, position stored in
-- EmoteForeverDB.minimap. Also adds an entry to Blizzard's addon menu at the minimap (addon compartment).

local ICON = "Interface\\AddOns\\" .. addonName .. "\\Media\\icon"
local ICON_SIZE = 28 -- almost fills the 31 px button
-- LibDBIcon crops 5% from every edge (zoom effect). With these coordinates the icon's bronze ring
-- stays fully visible: -a + 0.05 * (1 + 2a) = 0  →  a = 0.05 / 0.9.
local ICON_COORDS = { -0.0556, 1.0556, -0.0556, 1.0556 }

local MinimapButton = {}
ns.MinimapButton = MinimapButton

-- Current key of the wheel binding for the tooltip, e.g. "Middle Mouse".
local function BindingText()
    local key = GetBindingKey(ns.BINDING)
    return key and GetBindingText(key) or L.tooltipNoKey
end

local function ShowTooltip(tooltip)
    tooltip:AddLine(ns.BrandLine())
    tooltip:AddDoubleLine(L.tooltipKey, BindingText(), 1, 1, 1, 1, 1, 1)
    tooltip:AddLine(" ")
    tooltip:AddLine(ns.ClickHint("LeftButton", L.actionOptions, L.hintMinimapLeft), GRAY_FONT_COLOR:GetRGB())
    tooltip:AddLine(ns.ClickHint("RightButton", L.actionOpenWheel, L.hintMinimapRight), GRAY_FONT_COLOR:GetRGB())
    tooltip:AddLine(ns.ClickHint("LeftButton", L.actionDragMinimap, L.hintMinimapDrag), GRAY_FONT_COLOR:GetRGB())
end

local function OnClick(_, button)
    if button == "RightButton" then
        ns.Wheel:Open(true) -- click mode: choose with a click
    else
        ns.Options:Open()
    end
end

-- Must run before PLAYER_LOGIN (LibDBIcon positions its buttons on login), so in ADDON_LOADED.
function MinimapButton:Init()
    local LDB = LibStub("LibDataBroker-1.1", true)
    local DBIcon = LibStub("LibDBIcon-1.0", true)
    if not (LDB and DBIcon) then return end
    self.DBIcon = DBIcon

    local launcher = LDB:NewDataObject(addonName, {
        type = "launcher",
        icon = ICON,
        iconCoords = ICON_COORDS,
        label = addonName,
        OnClick = OnClick,
        OnTooltipShow = ShowTooltip,
    })
    EmoteForeverDB.minimap.hide = not EmoteForeverDB.showMinimapButton
    DBIcon:Register(addonName, launcher, EmoteForeverDB.minimap)

    -- Our icon has its own bronze ring. LibDBIcon's golden ring would sit around it twice and is
    -- slightly offset in Forever (which reports itself as Mainline), so remove it.
    DBIcon:RemoveButtonBorder(addonName)
    DBIcon:RemoveButtonBackground(addonName)
    DBIcon:SetButtonIcon(addonName, nil, ICON_SIZE, "CENTER", 0, 0)

    DBIcon:AddButtonToCompartment(addonName)
end

function MinimapButton:ApplySettings()
    if not self.DBIcon then return end
    EmoteForeverDB.minimap.hide = not EmoteForeverDB.showMinimapButton
    -- Refresh also picks up a new db table (e.g. after "Restore defaults").
    self.DBIcon:Refresh(addonName, EmoteForeverDB.minimap)
end
