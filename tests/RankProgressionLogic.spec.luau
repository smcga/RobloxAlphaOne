local RankProgressionLogic = require('../src/Shared/RankProgressionLogic')

local rankConfigs = {
    { name = 'Pebble Counter', requiredScore = 0 },
    { name = 'Bead Keeper', requiredScore = 1000 },
    { name = 'String Tallyer', requiredScore = 2000 },
}

local function expectEqual(actual: any, expected: any, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function expectApprox(actual: number, expected: number, tolerance: number, message: string)
    if math.abs(actual - expected) > tolerance then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

runCase('getCurrentRankIndex resolves first rank at score zero', function()
    local rankIndex = RankProgressionLogic.getCurrentRankIndex(0, rankConfigs)
    expectEqual(rankIndex, 1, 'score zero should map to the first rank')
end)

runCase('getCurrentRankIndex resolves highest unlocked rank', function()
    local rankIndex = RankProgressionLogic.getCurrentRankIndex(1800, rankConfigs)
    expectEqual(rankIndex, 2, 'score should resolve to the highest unlocked rank')
end)

runCase('getRankProgress reports progress toward the next rank', function()
    local rankProgress = RankProgressionLogic.getRankProgress(1500, rankConfigs)

    expectEqual(rankProgress.currentRankName, 'Bead Keeper', 'current rank should be Bead Keeper')
    expectEqual(rankProgress.nextRankName, 'String Tallyer', 'next rank should be String Tallyer')
    expectEqual(rankProgress.scoreIntoCurrentRank, 500, 'score into rank should be 500')
    expectEqual(rankProgress.scoreNeededForNextRank, 500, '500 score should remain to next rank')
    expectEqual(rankProgress.progressAlpha, 0.5, 'progress bar alpha should be 0.5')
end)

runCase('getRankProgress clamps negative scores to first rank progress', function()
    local rankProgress = RankProgressionLogic.getRankProgress(-100, rankConfigs)

    expectEqual(
        rankProgress.currentRankName,
        'Pebble Counter',
        'negative scores should clamp to first rank'
    )
    expectEqual(
        rankProgress.scoreIntoCurrentRank,
        0,
        'negative scores should clamp progress to zero'
    )
    expectEqual(
        rankProgress.scoreNeededForNextRank,
        1000,
        'full score should be needed for next rank'
    )
end)

runCase('getRankProgress returns maxed state when highest rank is reached', function()
    local rankProgress = RankProgressionLogic.getRankProgress(5000, rankConfigs)

    expectEqual(rankProgress.currentRankName, 'String Tallyer', 'highest rank should stay active')
    expectEqual(rankProgress.nextRankName, nil, 'no next rank should exist at cap')
    expectEqual(rankProgress.progressAlpha, 1, 'max rank progress alpha should be full')
end)

runCase('rank multiplier starts at 1x for first rank', function()
    local multiplier = RankProgressionLogic.getScoreMultiplierForRankIndex(1, 1.15, 8)
    expectEqual(multiplier, 1, 'first rank multiplier should be 1x')
end)

runCase('rank multiplier grows exponentially within age', function()
    local multiplier = RankProgressionLogic.getScoreMultiplierForRankIndex(8, 1.15, 8)
    expectApprox(multiplier, 2.6600198805, 1e-9, 'rank 8 should be about 2.66x')
end)

runCase('rank multiplier resets after each age boundary', function()
    local multiplier = RankProgressionLogic.getScoreMultiplierForRankIndex(9, 1.15, 8)
    expectEqual(multiplier, 1, 'first rank of next age should reset to 1x')
end)

runCase('score-based multiplier resolves from unlocked rank', function()
    local multiplier = RankProgressionLogic.getScoreMultiplierForScore(1800, rankConfigs, 1.15, 8)
    expectApprox(multiplier, 1.15, 1e-9, 'second rank should apply one 1.15x step')
end)
