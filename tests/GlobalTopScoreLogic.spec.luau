local GlobalTopScoreLogic = require('../src/Shared/GlobalTopScoreLogic')

local function expectEqual(actual, expected, message)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function expectTruthy(actual: any, message: string)
    if not actual then
        error(message)
    end
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

runCase('normalize invalid record into safe defaults', function()
    local normalized = GlobalTopScoreLogic.normalizeRecord(nil)
    expectEqual(normalized.playerName, 'No champion yet', 'expected fallback name')
    expectEqual(normalized.highestScore, 0, 'expected fallback score')
end)

runCase('higher candidate score replaces current record', function()
    local current = GlobalTopScoreLogic.createCandidateRecord(1, 'Alice', 500, 10)
    local candidate = GlobalTopScoreLogic.createCandidateRecord(2, 'Bob', 900, 11)
    expectTruthy(
        GlobalTopScoreLogic.shouldReplaceRecord(current, candidate),
        'higher score should replace current record'
    )
end)

runCase('lower candidate score does not replace current record', function()
    local current = GlobalTopScoreLogic.createCandidateRecord(1, 'Alice', 500, 10)
    local candidate = GlobalTopScoreLogic.createCandidateRecord(2, 'Bob', 400, 11)
    expectEqual(
        GlobalTopScoreLogic.shouldReplaceRecord(current, candidate),
        false,
        'lower score should not replace current record'
    )
end)

runCase('screen text shows fallback message when no score exists', function()
    local text =
        GlobalTopScoreLogic.toScreenText(GlobalTopScoreLogic.createCandidateRecord(0, '', 0, 0))
    expectTruthy(string.find(text, 'No champion yet', 1, true) ~= nil, 'missing fallback message')
end)

runCase('screen text includes player and score when record exists', function()
    local text = GlobalTopScoreLogic.toScreenText(
        GlobalTopScoreLogic.createCandidateRecord(55, 'TopPlayer', 12500, 100)
    )
    expectTruthy(string.find(text, 'TopPlayer', 1, true) ~= nil, 'missing player name')
    expectTruthy(string.find(text, '12.5 K', 1, true) ~= nil, 'missing compact score')
end)
