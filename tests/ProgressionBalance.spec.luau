local ProgressionBalance = require('../src/Shared/ProgressionBalance')

local function expectTrue(condition: boolean, message: string)
    if not condition then
        error(message)
    end
end

local function approxRelative(actual: number, expected: number, tolerance: number): boolean
    if expected == 0 then
        return math.abs(actual) <= tolerance
    end

    return math.abs(actual - expected) / math.abs(expected) <= tolerance
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

local rankNames = table.create(ProgressionBalance.TOTAL_RANKS)
for rankIndex = 1, ProgressionBalance.TOTAL_RANKS do
    rankNames[rankIndex] = string.format('Rank %d', rankIndex)
end
local rankConfigs, ageConfigs = ProgressionBalance.build(rankNames)

runCase('generated progression has required counts and aligned age gates', function()
    expectTrue(#rankConfigs == 96, 'should generate exactly 96 ranks')
    expectTrue(#ageConfigs == 12, 'should generate exactly 12 ages')
    expectTrue(rankConfigs[1].requiredScore == 0, 'rank 1 should start at zero')

    for rankIndex = 2, #rankConfigs do
        expectTrue(
            rankConfigs[rankIndex].requiredScore > rankConfigs[rankIndex - 1].requiredScore,
            string.format('rank requirement %d should strictly increase', rankIndex)
        )
    end

    expectTrue(
        ageConfigs[1].requiredScore == rankConfigs[1].requiredScore,
        'age 1 gate should match rank 1 requirement'
    )
    expectTrue(
        ageConfigs[2].requiredScore == rankConfigs[9].requiredScore,
        'age 2 gate should match rank 9 requirement'
    )
    expectTrue(
        ageConfigs[12].requiredScore == rankConfigs[89].requiredScore,
        'age 12 gate should match rank 89 requirement'
    )
end)

runCase('final rank target remains compact-formatted and near max target', function()
    local finalRequirement = rankConfigs[#rankConfigs].requiredScore
    expectTrue(finalRequirement > 1e65, 'final requirement should be above 1e65')
    expectTrue(finalRequirement < 1e66, 'final requirement should remain below 1e66')
    expectTrue(
        approxRelative(finalRequirement, ProgressionBalance.MAX_COMPACT_SCORE_TARGET, 1e-3),
        'final requirement should be within 0.1% of target'
    )
end)

runCase('every transition matches target seconds for its age gain', function()
    for transitionRank = 1, 95 do
        local deltaRequirement = rankConfigs[transitionRank + 1].requiredScore
            - rankConfigs[transitionRank].requiredScore
        local ageIndex = ProgressionBalance.getAgeIndexForRankTransition(transitionRank)
        local gainPerSecond = ageConfigs[ageIndex].scoreIncrement
        local actualSeconds = deltaRequirement / gainPerSecond
        local expectedSeconds = ProgressionBalance.getTargetSecondsForRankTransition(transitionRank)

        expectTrue(
            approxRelative(actualSeconds, expectedSeconds, 1e-9),
            string.format('transition %d timing should match expected curve', transitionRank)
        )
    end
end)

runCase('catch-up multiplier keeps early rebirths linear but damps late scaling', function()
    local earlyMultiplier = ProgressionBalance.getCatchUpMultiplier(0, 0, 2, 30)
    local lateMultiplier = ProgressionBalance.getCatchUpMultiplier(0, 0, 150, 30)

    expectTrue(earlyMultiplier == 15, 'early rebirths should keep existing linear speed')
    expectTrue(lateMultiplier == 30, 'late rebirth scaling should be capped')
end)
