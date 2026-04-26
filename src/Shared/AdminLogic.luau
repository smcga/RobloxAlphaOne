local AdminLogic = {}

type RankConfig = {
    requiredScore: number,
}

function AdminLogic.isAllowedScoreMultiplier(
    allowedMultipliers: { number },
    multiplier: number
): boolean
    for _, allowedMultiplier in ipairs(allowedMultipliers) do
        if allowedMultiplier == multiplier then
            return true
        end
    end

    return false
end

function AdminLogic.applyScoreMultiplier(score: number, multiplier: number): number
    return math.floor(score * multiplier)
end

function AdminLogic.resetScoreAndRebirths(): (number, number)
    return 0, 0
end

function AdminLogic.getNextRankScore(score: number, rankConfigs: { RankConfig }): number
    if #rankConfigs == 0 then
        return score
    end

    local sanitizedScore = math.max(score, 0)
    local currentRankIndex = 1
    for rankIndex, rankConfig in ipairs(rankConfigs) do
        if sanitizedScore >= rankConfig.requiredScore then
            currentRankIndex = rankIndex
        else
            break
        end
    end

    local nextRank = rankConfigs[currentRankIndex + 1]
    if not nextRank then
        return sanitizedScore
    end

    return nextRank.requiredScore
end

function AdminLogic.skipLuckyChestTimer(currentNextLuckyChestOpenAt: number): number
    if currentNextLuckyChestOpenAt <= 0 then
        return currentNextLuckyChestOpenAt
    end

    return 0
end

return AdminLogic
