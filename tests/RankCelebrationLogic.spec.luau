local RankCelebrationLogic = require('../src/Shared/RankCelebrationLogic')

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

runCase('sanitizeRankReachCounts normalizes invalid values and pads to total ranks', function()
    local counts =
        RankCelebrationLogic.sanitizeRankReachCounts({ [1] = 4.9, [2] = -2, [3] = 0 / 0 }, 4)

    expectEqual(#counts, 4, 'should include all rank entries')
    expectEqual(counts[1], 4, 'valid values should floor to whole numbers')
    expectEqual(counts[2], 0, 'negative values should clamp to zero')
    expectEqual(counts[3], 0, 'nan values should clamp to zero')
    expectEqual(counts[4], 0, 'missing values should default to zero')
end)

runCase('sanitizeRankIndexArray deduplicates and drops out-of-range entries', function()
    local ranks = RankCelebrationLogic.sanitizeRankIndexArray({ 1, 1, 2.8, -1, 99 }, 3)

    expectEqual(#ranks, 2, 'should keep only unique in-range ranks')
    expectEqual(ranks[1], 1, 'first rank should be retained')
    expectEqual(ranks[2], 2, 'decimal rank should be floored and retained')
end)

runCase('getNewRankIndices returns each newly crossed rank', function()
    local newRanks = RankCelebrationLogic.getNewRankIndices(3, 6)

    expectEqual(#newRanks, 3, 'should include each crossed rank')
    expectEqual(newRanks[1], 4, 'first crossed rank should be previous + 1')
    expectEqual(newRanks[3], 6, 'last crossed rank should match next rank')
end)

runCase('getNewRankIndices returns no ranks when rank does not increase', function()
    local sameRank = RankCelebrationLogic.getNewRankIndices(6, 6)
    local lowerRank = RankCelebrationLogic.getNewRankIndices(6, 4)

    expectEqual(#sameRank, 0, 'same rank should not emit rank-up events')
    expectEqual(#lowerRank, 0, 'lower rank should not emit rank-up events')
end)

runCase('buildRankUpEvent applies first-time popup duration', function()
    local event =
        RankCelebrationLogic.buildRankUpEvent(5, 'Market Reckoner', 'Quick sums.', 1, 25, true)

    expectEqual(
        event.popupDurationSeconds,
        RankCelebrationLogic.FIRST_TIME_POPUP_DURATION_SECONDS,
        'first-time rank should use long popup duration'
    )
    expectEqual(event.timesReached, 1, 'times reached should remain one')
end)

runCase('buildRankUpEvent applies repeat popup duration and sanitizes counts', function()
    local event =
        RankCelebrationLogic.buildRankUpEvent(5, 'Market Reckoner', 'Quick sums.', -3, 5.8, false)

    expectEqual(
        event.popupDurationSeconds,
        RankCelebrationLogic.REPEAT_POPUP_DURATION_SECONDS,
        'repeat rank should use short popup duration'
    )
    expectEqual(event.timesReached, 1, 'times reached should clamp to at least one')
    expectEqual(event.globalPlayersReached, 5, 'global count should floor whole number')
end)
