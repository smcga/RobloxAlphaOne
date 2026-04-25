export type RankConfig = {
    name: string,
    requiredScore: number,
}

export type AgeBalanceConfig = {
    ageIndex: number,
    requiredScore: number,
    scorePerSecond: number,
    scoreIncrement: number,
}

local ProgressionBalance = {}

ProgressionBalance.TOTAL_RANKS = 96
ProgressionBalance.TOTAL_AGES = 12
ProgressionBalance.RANKS_PER_AGE = 8
ProgressionBalance.MAX_COMPACT_SCORE_TARGET = 9.99e65
ProgressionBalance.BASE_AGE_SCORE_PER_SECOND = 1
ProgressionBalance.REBIRTH_CATCH_UP_PER_REBIRTH = 7
ProgressionBalance.MAX_CATCH_UP_MULTIPLIER = 30
ProgressionBalance.POST_RECORD_REBIRTH_MULTIPLIER = 1

local AGE_GAIN_RATIO = 449623.4583190185
ProgressionBalance.AGE_GAIN_RATIO = AGE_GAIN_RATIO

function ProgressionBalance.getTargetSecondsForRankTransition(transitionRank: number): number
    return 30 + 10 * (transitionRank - 1)
end

function ProgressionBalance.getAgeIndexForRankTransition(transitionRank: number): number
    return math.min(
        ProgressionBalance.TOTAL_AGES,
        math.floor((transitionRank - 1) / ProgressionBalance.RANKS_PER_AGE) + 1
    )
end

function ProgressionBalance.getAgeIndexForRank(rankIndex: number): number
    return math.min(
        ProgressionBalance.TOTAL_AGES,
        math.floor((rankIndex - 1) / ProgressionBalance.RANKS_PER_AGE) + 1
    )
end

local function getAgeScorePerSecond(ageIndex: number): number
    return ProgressionBalance.BASE_AGE_SCORE_PER_SECOND * (AGE_GAIN_RATIO ^ (ageIndex - 1))
end

local function computeRankRequirements(): { number }
    local requirements = table.create(ProgressionBalance.TOTAL_RANKS)
    requirements[1] = 0

    for transitionRank = 1, ProgressionBalance.TOTAL_RANKS - 1 do
        local ageIndex = ProgressionBalance.getAgeIndexForRankTransition(transitionRank)
        local transitionSeconds =
            ProgressionBalance.getTargetSecondsForRankTransition(transitionRank)
        requirements[transitionRank + 1] = requirements[transitionRank]
            + getAgeScorePerSecond(ageIndex) * transitionSeconds
    end

    return requirements
end

local function buildRankConfigs(rankNames: { string }): { RankConfig }
    local requirements = computeRankRequirements()
    local configs = table.create(#rankNames)

    for rankIndex, rankName in ipairs(rankNames) do
        configs[rankIndex] = {
            name = rankName,
            requiredScore = requirements[rankIndex],
        }
    end

    return configs
end

local function buildAgeBalanceConfigs(rankConfigs: { RankConfig }): { AgeBalanceConfig }
    local ageConfigs = table.create(ProgressionBalance.TOTAL_AGES)

    for ageIndex = 1, ProgressionBalance.TOTAL_AGES do
        local rankIndex = ((ageIndex - 1) * ProgressionBalance.RANKS_PER_AGE) + 1
        ageConfigs[ageIndex] = {
            ageIndex = ageIndex,
            requiredScore = rankConfigs[rankIndex].requiredScore,
            scorePerSecond = getAgeScorePerSecond(ageIndex),
            scoreIncrement = getAgeScorePerSecond(ageIndex),
        }
    end

    return ageConfigs
end

function ProgressionBalance.getRankIndexForScore(score: number, rankConfigs: { RankConfig }): number
    if #rankConfigs == 0 then
        return 0
    end

    local scoreValue = if score > 0 then score else 0
    local currentIndex = 1

    for rankIndex, rankConfig in ipairs(rankConfigs) do
        if scoreValue >= rankConfig.requiredScore then
            currentIndex = rankIndex
        else
            break
        end
    end

    return currentIndex
end

function ProgressionBalance.getHighestUnlockedAgeIndex(
    score: number,
    ageConfigs: { AgeBalanceConfig }
): number
    if #ageConfigs == 0 then
        return 0
    end

    local scoreValue = if score > 0 then score else 0
    local ageIndex = 1

    for index, ageConfig in ipairs(ageConfigs) do
        if scoreValue >= ageConfig.requiredScore then
            ageIndex = index
        else
            break
        end
    end

    return ageIndex
end

function ProgressionBalance.getCatchUpMultiplier(
    _currentScore: number,
    _highestScoreAchieved: number,
    rebirths: number
): number
    local catchUpMultiplier = 1
        + math.max(rebirths, 0) * ProgressionBalance.REBIRTH_CATCH_UP_PER_REBIRTH
    return math.min(ProgressionBalance.MAX_CATCH_UP_MULTIPLIER, catchUpMultiplier)
end

function ProgressionBalance.build(rankNames: { string }): ({ RankConfig }, { AgeBalanceConfig })
    local rankConfigs = buildRankConfigs(rankNames)
    local ageConfigs = buildAgeBalanceConfigs(rankConfigs)
    return rankConfigs, ageConfigs
end

return ProgressionBalance
