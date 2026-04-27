export type RankPanelLayout = {
    width: number,
    height: number,
    bottomPadding: number,
}

local RankUiLayoutLogic = {}

local DEFAULT_RANK_PANEL_LAYOUT: RankPanelLayout = {
    width = 460,
    height = 88,
    bottomPadding = 24,
}

function RankUiLayoutLogic.getRankPanelLayout(): RankPanelLayout
    return table.clone(DEFAULT_RANK_PANEL_LAYOUT)
end

return RankUiLayoutLogic
