local RankProgressionLogic = require('../src/Shared/RankProgressionLogic')

local rankConfigs = {
    { name = 'Age 00 Newborn Spark', requiredScore = 0 },
    { name = 'Age 01 Newborn Spark', requiredScore = 1000 },
    { name = 'Age 02 Curious Toddler', requiredScore = 2000 },
}

local function expectEqual(actual: any, expected: any, message: string)
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

    expectEqual(
        rankProgress.currentRankName,
        'Age 01 Newborn Spark',
        'current rank should be Age 01 Newborn Spark'
    )
    expectEqual(
        rankProgress.nextRankName,
        'Age 02 Curious Toddler',
        'next rank should be Age 02 Curious Toddler'
    )
    expectEqual(rankProgress.scoreIntoCurrentRank, 500, 'score into rank should be 500')
    expectEqual(rankProgress.scoreNeededForNextRank, 500, '500 score should remain to next rank')
    expectEqual(rankProgress.progressAlpha, 0.5, 'progress bar alpha should be 0.5')
end)

runCase('getRankProgress clamps negative scores to rank one progress', function()
    local rankProgress = RankProgressionLogic.getRankProgress(-100, rankConfigs)

    expectEqual(
        rankProgress.currentRankName,
        'Age 00 Newborn Spark',
        'negative scores should clamp to the first age rank'
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

    expectEqual(
        rankProgress.currentRankName,
        'Age 02 Curious Toddler',
        'highest rank should stay active'
    )
    expectEqual(rankProgress.nextRankName, nil, 'no next rank should exist at cap')
    expectEqual(rankProgress.progressAlpha, 1, 'max rank progress alpha should be full')
end)
