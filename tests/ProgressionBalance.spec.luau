local ProgressionBalance = require('../src/Shared/ProgressionBalance')

local function expectTrue(condition: boolean, message: string)
    if not condition then
        error(message)
    end
end

local function expectEqual(actual: number, expected: number, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
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
    expectEqual(#rankConfigs, 96, 'should generate exactly 96 ranks')
    expectEqual(#ageConfigs, 12, 'should generate exactly 12 ages')
    expectEqual(rankConfigs[1].requiredScore, 0, 'rank 1 should start at zero')

    for rankIndex = 2, #rankConfigs do
        expectTrue(
            rankConfigs[rankIndex].requiredScore > rankConfigs[rankIndex - 1].requiredScore,
            string.format('rank requirement %d should strictly increase', rankIndex)
        )
    end

    expectEqual(
        ageConfigs[1].requiredScore,
        rankConfigs[1].requiredScore,
        'age 1 gate should match rank 1 requirement'
    )
    expectEqual(
        ageConfigs[2].requiredScore,
        rankConfigs[9].requiredScore,
        'age 2 gate should match rank 9 requirement'
    )
    expectEqual(
        ageConfigs[12].requiredScore,
        rankConfigs[89].requiredScore,
        'age 12 gate should match rank 89 requirement'
    )
end)

runCase('age requirements follow configured base and growth constants', function()
    expectEqual(ProgressionBalance.getAgeRequirement(1), 0, 'age 1 requirement should be zero')
    expectEqual(ProgressionBalance.getAgeRequirement(2), 1000, 'age 2 requirement should be 1,000')
    expectEqual(ProgressionBalance.getAgeRequirement(3), 8000, 'age 3 requirement should be 8,000')
    expectEqual(
        ProgressionBalance.getAgeRequirement(6),
        4_096_000,
        'age 6 requirement should match curve'
    )
end)

runCase('age multipliers follow configured exponential base', function()
    expectEqual(ProgressionBalance.getAgeMultiplier(1), 1, 'age 1 should be 1x')
    expectEqual(ProgressionBalance.getAgeMultiplier(2), 3, 'age 2 should be 3x')
    expectEqual(ProgressionBalance.getAgeMultiplier(4), 27, 'age 4 should be 27x')
end)

runCase('rank multipliers scale meaningfully within each age and reset per age', function()
    expectEqual(ProgressionBalance.getRankMultiplier(1), 1, 'rank 1 should be 1x')
    expectTrue(
        ProgressionBalance.getRankMultiplier(8) > 2.6,
        'rank 8 should be stronger than 2.6x inside age 1'
    )
    expectEqual(ProgressionBalance.getRankMultiplier(9), 1, 'rank 9 should reset at new age')
end)

runCase('rank requirements interpolate between age requirements', function()
    expectEqual(rankConfigs[1].requiredScore, 0, 'rank 1 requirement should be zero')
    expectEqual(rankConfigs[9].requiredScore, 1_000, 'rank 9 should match age 2 gate')
    expectEqual(rankConfigs[17].requiredScore, 8_000, 'rank 17 should match age 3 gate')

    local ageTwoStart = rankConfigs[9].requiredScore
    local ageTwoEnd = ProgressionBalance.getAgeRequirement(3)
    expectTrue(
        rankConfigs[16].requiredScore < ageTwoEnd,
        'last rank before next age gate should stay below next age requirement'
    )
    expectTrue(
        rankConfigs[16].requiredScore > ageTwoStart,
        'last rank of age should progress beyond age start requirement'
    )
end)

runCase('final age ranks continue progressing using extrapolated next-age requirement', function()
    local ageTwelveRequirement = ProgressionBalance.getAgeRequirement(12)
    local finalRankRequirement = rankConfigs[96].requiredScore

    expectEqual(rankConfigs[89].requiredScore, ageTwelveRequirement, 'rank 89 should match age 12')
    expectTrue(
        finalRankRequirement > ageTwelveRequirement,
        'final rank should exceed age 12 base requirement'
    )
end)

runCase('rebirth multiplier uses diminishing returns and stays monotonic', function()
    local zero = ProgressionBalance.getRebirthScoreMultiplier(0)
    local four = ProgressionBalance.getRebirthScoreMultiplier(4)
    local oneHundred = ProgressionBalance.getRebirthScoreMultiplier(100)

    expectEqual(zero, 1, 'zero rebirths should keep 1x multiplier')
    expectTrue(four > zero, 'rebirth multiplier should increase with rebirths')
    expectTrue(oneHundred > four, 'multiplier should remain monotonic at high rebirths')
    expectTrue(oneHundred < 5, 'diminishing scaling should avoid runaway at 100 rebirths')
end)

runCase('rebirth multiplier respects configured cap', function()
    local capped = ProgressionBalance.getRebirthScoreMultiplier(50_000, nil, nil, 12)
    expectEqual(capped, 12, 'multiplier should clamp to configured cap')
end)

runCase('debug printer emits generated age and rank tables without throwing', function()
    ProgressionBalance.debugPrintGeneratedProgression(rankConfigs, ageConfigs)
    expectTrue(true, 'debug print should complete')
end)
