local ScoreLogic = require('../src/Shared/ScoreLogic')

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

runCase('starting from 0 score', function()
    local state = ScoreLogic.newState()
    expectEqual(state.score, 0, 'new state score should start at zero')
end)

runCase('one second inside zone adds 1', function()
    local state = ScoreLogic.newState(0)
    local nextState = ScoreLogic.tick(state, 1, true, 1, 1)
    expectEqual(nextState.score, 1, 'score should increment by one')
end)

runCase('multiple seconds inside zone accumulate correctly', function()
    local state = ScoreLogic.newState(0)
    local nextState = ScoreLogic.tick(state, 3.2, true, 1, 1)
    expectEqual(nextState.score, 3, 'score should increment once per full second')
end)

runCase('no score change when outside zone', function()
    local state = ScoreLogic.newState(5)
    local nextState = ScoreLogic.tick(state, 2.5, false, 1, 1)
    expectEqual(nextState.score, 5, 'score should not change outside zone')
end)

runCase('repeated enter and leave does not overcount', function()
    local state = ScoreLogic.newState(0)
    state = ScoreLogic.tick(state, 0.8, true, 1, 1)
    state = ScoreLogic.tick(state, 0.6, false, 1, 1)
    state = ScoreLogic.tick(state, 1, true, 1, 1)
    expectEqual(state.score, 1, 'accumulator should reset when player leaves zone')
end)
