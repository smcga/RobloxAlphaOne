local GlobalLeaderboardLogic = require('../src/Shared/GlobalLeaderboardLogic')

local function expectEqual<T>(actual: T, expected: T, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function expectTruthy(value: unknown, message: string)
    if not value then
        error(message)
    end
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

runCase('normalizeEntries sorts descending and truncates by max entries', function()
    local normalized = GlobalLeaderboardLogic.normalizeEntries({
        { userId = 22, playerName = 'Two', bestScore = 1000 },
        { userId = 11, playerName = 'One', bestScore = 5000 },
        { userId = 33, playerName = 'Three', bestScore = 2500 },
    }, 2)

    expectEqual(#normalized, 2, 'should keep only max entries')
    expectEqual(normalized[1].playerName, 'One', 'highest score should come first')
    expectEqual(normalized[2].playerName, 'Three', 'second-highest score should come second')
end)

runCase('normalizeEntries sanitizes invalid values', function()
    local normalized = GlobalLeaderboardLogic.normalizeEntries({
        { userId = -12, playerName = '', bestScore = -50 },
        { userId = 4.9, playerName = 'Valid', bestScore = math.huge },
    }, 10)

    expectEqual(normalized[1].userId, 0, 'negative user ids should clamp to zero')
    expectEqual(normalized[1].playerName, 'Unknown', 'blank names should sanitize to Unknown')
    expectEqual(normalized[1].bestScore, 0, 'negative scores should sanitize to zero')
    expectEqual(normalized[2].userId, 4, 'user id should be floored')
    expectEqual(normalized[2].bestScore, 0, 'infinite scores should sanitize to zero')
end)

runCase('buildSignText renders empty and populated states', function()
    local emptyText = GlobalLeaderboardLogic.buildSignText({}, function(score)
        return tostring(score)
    end)
    expectTruthy(
        string.find(emptyText, 'No scores yet', 1, true) ~= nil,
        'empty sign text should show no-scores copy'
    )

    local fullText = GlobalLeaderboardLogic.buildSignText({
        { userId = 10, playerName = 'Alice', bestScore = 12345 },
        { userId = 11, playerName = 'Bob', bestScore = 9999 },
    }, function(score)
        return string.format('%s pts', tostring(score))
    end)

    expectTruthy(
        string.find(fullText, '1) Alice - 12345 pts', 1, true) ~= nil,
        'first line should include rank/name/score'
    )
    expectTruthy(
        string.find(fullText, '2) Bob - 9999 pts', 1, true) ~= nil,
        'second line should include rank/name/score'
    )
end)
