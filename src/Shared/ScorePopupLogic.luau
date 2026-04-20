local ScorePopupLogic = {}

local DEFAULT_EDGE_PADDING = 20

function ScorePopupLogic.getPositiveIncrease(previousScore: number?, nextScore: number): number?
    if previousScore == nil then
        return nil
    end

    local increase = nextScore - previousScore
    if increase <= 0 then
        return nil
    end

    return increase
end

function ScorePopupLogic.formatIncreaseText(
    increase: number,
    formatCompact: (number) -> string
): string
    local compactText = formatCompact(increase)
    local tightText = compactText:gsub('%s+', ''):lower()

    return string.format('+%s', tightText)
end

function ScorePopupLogic.getRandomPopupPosition(
    screenWidth: number,
    screenHeight: number,
    popupWidth: number,
    popupHeight: number,
    randomX: number,
    randomY: number,
    edgePadding: number?
): (number, number)
    local padding = edgePadding or DEFAULT_EDGE_PADDING
    local minX = padding
    local maxX = math.max(minX, screenWidth - popupWidth - padding)
    local minY = padding
    local maxY = math.max(minY, screenHeight - popupHeight - padding)

    local x = minX + ((maxX - minX) * randomX)
    local y = minY + ((maxY - minY) * randomY)

    return x, y
end

return ScorePopupLogic
