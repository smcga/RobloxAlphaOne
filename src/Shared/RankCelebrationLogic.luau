export type RankUpEvent = {
    rankIndex: number,
    rankName: string,
    rankDescription: string,
    timesReached: number,
    globalPlayersReached: number,
    popupDurationSeconds: number,
}

local RankCelebrationLogic = {}

RankCelebrationLogic.FIRST_TIME_POPUP_DURATION_SECONDS = 6.5
RankCelebrationLogic.REPEAT_POPUP_DURATION_SECONDS = 3

local function sanitizeWholeNumber(value: any): number
    if type(value) ~= 'number' then
        return 0
    end

    if value ~= value then
        return 0
    end

    if value == math.huge or value == -math.huge then
        return 0
    end

    return math.max(0, math.floor(value))
end

function RankCelebrationLogic.sanitizeRankReachCounts(raw: any, totalRanks: number): { number }
    local sanitized = table.create(totalRanks, 0)

    if type(raw) ~= 'table' then
        return sanitized
    end

    for rankIndex = 1, totalRanks do
        sanitized[rankIndex] = sanitizeWholeNumber(raw[rankIndex])
    end

    return sanitized
end

function RankCelebrationLogic.sanitizeRankIndexArray(raw: any, totalRanks: number): { number }
    if type(raw) ~= 'table' then
        return {}
    end

    local result = {}
    local seen: { [number]: boolean } = {}

    for _, value in ipairs(raw) do
        local rankIndex = sanitizeWholeNumber(value)
        if rankIndex >= 1 and rankIndex <= totalRanks and not seen[rankIndex] then
            seen[rankIndex] = true
            result[#result + 1] = rankIndex
        end
    end

    return result
end

function RankCelebrationLogic.getNewRankIndices(
    previousRankIndex: number,
    nextRankIndex: number
): { number }
    local previous = math.max(0, math.floor(previousRankIndex))
    local nextRank = math.max(0, math.floor(nextRankIndex))

    if nextRank <= previous then
        return {}
    end

    local rankIndices = table.create(nextRank - previous)
    for rankIndex = previous + 1, nextRank do
        rankIndices[#rankIndices + 1] = rankIndex
    end

    return rankIndices
end

function RankCelebrationLogic.getPopupDurationSeconds(firstTimeReached: boolean): number
    if firstTimeReached then
        return RankCelebrationLogic.FIRST_TIME_POPUP_DURATION_SECONDS
    end

    return RankCelebrationLogic.REPEAT_POPUP_DURATION_SECONDS
end

function RankCelebrationLogic.buildRankUpEvent(
    rankIndex: number,
    rankName: string,
    rankDescription: string,
    timesReached: number,
    globalPlayersReached: number,
    firstTimeReached: boolean
): RankUpEvent
    return {
        rankIndex = rankIndex,
        rankName = rankName,
        rankDescription = rankDescription,
        timesReached = math.max(1, sanitizeWholeNumber(timesReached)),
        globalPlayersReached = sanitizeWholeNumber(globalPlayersReached),
        popupDurationSeconds = RankCelebrationLogic.getPopupDurationSeconds(firstTimeReached),
    }
end

return RankCelebrationLogic
