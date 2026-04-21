export type RankConfig = {
    name: string,
    requiredScore: number,
}

export type RankProgress = {
    currentRankIndex: number,
    currentRankName: string,
    currentRankRequiredScore: number,
    nextRankIndex: number?,
    nextRankName: string?,
    nextRankRequiredScore: number?,
    scoreIntoCurrentRank: number,
    scoreNeededForNextRank: number,
    progressAlpha: number,
}

local RankProgressionLogic = {}

local function sanitizeScore(score: number): number
    if score < 0 then
        return 0
    end

    return math.floor(score)
end

function RankProgressionLogic.getCurrentRankIndex(
    score: number,
    rankConfigs: { RankConfig }
): number
    if #rankConfigs == 0 then
        return 0
    end

    local sanitizedScore = sanitizeScore(score)
    local currentRankIndex = 1

    for index, rankConfig in ipairs(rankConfigs) do
        if sanitizedScore >= rankConfig.requiredScore then
            currentRankIndex = index
        else
            break
        end
    end

    return currentRankIndex
end

function RankProgressionLogic.getRankProgress(
    score: number,
    rankConfigs: { RankConfig }
): RankProgress
    if #rankConfigs == 0 then
        error('RankProgressionLogic requires at least one rank config')
    end

    local currentRankIndex = RankProgressionLogic.getCurrentRankIndex(score, rankConfigs)
    local currentRank = rankConfigs[currentRankIndex]
    local nextRank = rankConfigs[currentRankIndex + 1]
    local sanitizedScore = sanitizeScore(score)

    if nextRank then
        local span = math.max(nextRank.requiredScore - currentRank.requiredScore, 1)
        local scoreIntoCurrentRank = math.max(sanitizedScore - currentRank.requiredScore, 0)
        local clampedScoreIntoCurrentRank = math.min(scoreIntoCurrentRank, span)

        return {
            currentRankIndex = currentRankIndex,
            currentRankName = currentRank.name,
            currentRankRequiredScore = currentRank.requiredScore,
            nextRankIndex = currentRankIndex + 1,
            nextRankName = nextRank.name,
            nextRankRequiredScore = nextRank.requiredScore,
            scoreIntoCurrentRank = clampedScoreIntoCurrentRank,
            scoreNeededForNextRank = math.max(nextRank.requiredScore - sanitizedScore, 0),
            progressAlpha = clampedScoreIntoCurrentRank / span,
        }
    end

    return {
        currentRankIndex = currentRankIndex,
        currentRankName = currentRank.name,
        currentRankRequiredScore = currentRank.requiredScore,
        nextRankIndex = nil,
        nextRankName = nil,
        nextRankRequiredScore = nil,
        scoreIntoCurrentRank = 0,
        scoreNeededForNextRank = 0,
        progressAlpha = 1,
    }
end

return RankProgressionLogic
