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
ProgressionBalance.POST_RECORD_REBIRTH_MULTIPLIER = 1
ProgressionBalance.REBIRTH_MULTIPLIER_SCALE = 0.35
ProgressionBalance.REBIRTH_MULTIPLIER_POWER = 0.5
ProgressionBalance.MAX_REBIRTH_SCORE_MULTIPLIER = 12

-- Progression guardrail:
-- Keep age power growth sane and tunable. Avoid returning to giant per-age multipliers
-- (for example hundreds of thousands x per age), which collapses readability and pacing.
ProgressionBalance.AGE_REQUIREMENT_BASE = 1_000
ProgressionBalance.AGE_REQUIREMENT_GROWTH = 8
ProgressionBalance.AGE_MULTIPLIER_BASE = 3
ProgressionBalance.RANK_MULTIPLIER_BASE = 1.15
ProgressionBalance.RANK_REQUIREMENT_CURVE = 1.35
ProgressionBalance.FINAL_RANK_AGE_PROGRESS = 0.9

function ProgressionBalance.getAgeIndexForRank(rankIndex: number): number
    return math.min(
        ProgressionBalance.TOTAL_AGES,
        math.floor((rankIndex - 1) / ProgressionBalance.RANKS_PER_AGE) + 1
    )
end

function ProgressionBalance.getAgeRequirement(ageIndex: number): number
    if ageIndex <= 1 then
        return 0
    end

    return ProgressionBalance.AGE_REQUIREMENT_BASE
        * (ProgressionBalance.AGE_REQUIREMENT_GROWTH ^ (ageIndex - 2))
end

function ProgressionBalance.getAgeMultiplier(ageIndex: number): number
    local sanitizedAgeIndex = math.max(1, math.floor(ageIndex))
    return ProgressionBalance.AGE_MULTIPLIER_BASE ^ (sanitizedAgeIndex - 1)
end

function ProgressionBalance.getRankMultiplier(rankIndex: number): number
    local sanitizedRankIndex = math.max(1, math.floor(rankIndex))
    local rankWithinAge = (sanitizedRankIndex - 1) % ProgressionBalance.RANKS_PER_AGE
    return ProgressionBalance.RANK_MULTIPLIER_BASE ^ rankWithinAge
end

function ProgressionBalance.getRankRequirement(rankIndex: number): number
    local sanitizedRankIndex = math.max(1, math.floor(rankIndex))
    if sanitizedRankIndex <= 1 then
        return 0
    end

    local ageIndex = math.floor((sanitizedRankIndex - 1) / ProgressionBalance.RANKS_PER_AGE) + 1
    local rankWithinAge = (sanitizedRankIndex - 1) % ProgressionBalance.RANKS_PER_AGE

    local currentAgeRequirement = ProgressionBalance.getAgeRequirement(ageIndex)
    local nextAgeRequirement = ProgressionBalance.getAgeRequirement(ageIndex + 1)

    if ageIndex >= ProgressionBalance.TOTAL_AGES then
        nextAgeRequirement = currentAgeRequirement * ProgressionBalance.AGE_REQUIREMENT_GROWTH
    end

    local rawProgress = rankWithinAge / ProgressionBalance.RANKS_PER_AGE
    local scaledProgress = ProgressionBalance.FINAL_RANK_AGE_PROGRESS
        * (rawProgress ^ ProgressionBalance.RANK_REQUIREMENT_CURVE)

    return currentAgeRequirement + (nextAgeRequirement - currentAgeRequirement) * scaledProgress
end

local function getAgeScorePerSecond(ageIndex: number): number
    return ProgressionBalance.BASE_AGE_SCORE_PER_SECOND
        * ProgressionBalance.getAgeMultiplier(ageIndex)
end

local function computeRankRequirements(): { number }
    local requirements = table.create(ProgressionBalance.TOTAL_RANKS)

    for rankIndex = 1, ProgressionBalance.TOTAL_RANKS do
        local generatedRequirement = ProgressionBalance.getRankRequirement(rankIndex)
        if rankIndex == 1 then
            requirements[rankIndex] = 0
        else
            local previousRequirement = requirements[rankIndex - 1]
            local roundedRequirement = math.floor(generatedRequirement)
            requirements[rankIndex] = math.max(previousRequirement + 1, roundedRequirement)
        end
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

function ProgressionBalance.getRebirthScoreMultiplier(
    rebirths: number,
    scale: number?,
    power: number?,
    maxMultiplier: number?
): number
    local rebirthCount = math.max(math.floor(rebirths), 0)
    local effectiveScale = math.max(scale or ProgressionBalance.REBIRTH_MULTIPLIER_SCALE, 0)
    local effectivePower = math.max(power or ProgressionBalance.REBIRTH_MULTIPLIER_POWER, 0)
    local multiplier = 1 + effectiveScale * (rebirthCount ^ effectivePower)

    if maxMultiplier ~= nil then
        multiplier = math.min(multiplier, math.max(maxMultiplier, 1))
    else
        multiplier = math.min(multiplier, ProgressionBalance.MAX_REBIRTH_SCORE_MULTIPLIER)
    end

    return multiplier
end

function ProgressionBalance.debugPrintGeneratedProgression(
    rankConfigs: { RankConfig },
    ageConfigs: { AgeBalanceConfig }
)
    print('=== Progression Debug: Ages ===')
    for _, ageConfig in ipairs(ageConfigs) do
        local ageMultiplier = ProgressionBalance.getAgeMultiplier(ageConfig.ageIndex)
        print(
            string.format(
                'Age %02d | requirement=%d | multiplier=%.4f | scoreIncrement=%.4f',
                ageConfig.ageIndex,
                ageConfig.requiredScore,
                ageMultiplier,
                ageConfig.scoreIncrement
            )
        )
    end

    print('=== Progression Debug: Ranks ===')
    for rankIndex, rankConfig in ipairs(rankConfigs) do
        local ageIndex = ProgressionBalance.getAgeIndexForRank(rankIndex)
        local rankWithinAge = (rankIndex - 1) % ProgressionBalance.RANKS_PER_AGE
        local rankMultiplier = ProgressionBalance.getRankMultiplier(rankIndex)
        print(
            string.format(
                'Rank %02d | age=%02d | withinAge=%d | requirement=%d | multiplier=%.4f | name=%s',
                rankIndex,
                ageIndex,
                rankWithinAge,
                rankConfig.requiredScore,
                rankMultiplier,
                rankConfig.name
            )
        )
    end
end

function ProgressionBalance.build(rankNames: { string }): ({ RankConfig }, { AgeBalanceConfig })
    local rankConfigs = buildRankConfigs(rankNames)
    local ageConfigs = buildAgeBalanceConfigs(rankConfigs)
    return rankConfigs, ageConfigs
end

return ProgressionBalance
