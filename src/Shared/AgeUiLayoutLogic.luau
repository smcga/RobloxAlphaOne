export type AgeStatusPanelLayout = {
    width: number,
    height: number,
    topPadding: number,
}

local AgeUiLayoutLogic = {}

local DEFAULT_AGE_STATUS_PANEL_LAYOUT: AgeStatusPanelLayout = {
    width = 460,
    height = 100,
    topPadding = 6,
}

function AgeUiLayoutLogic.getAgeStatusPanelLayout(): AgeStatusPanelLayout
    return table.clone(DEFAULT_AGE_STATUS_PANEL_LAYOUT)
end

return AgeUiLayoutLogic
