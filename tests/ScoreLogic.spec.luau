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

runCase('sub-second ticks while inside zone carry over across updates', function()
    local state = ScoreLogic.newState(0)
    state = ScoreLogic.tick(state, 0.4, true, 1, 1)
    state = ScoreLogic.tick(state, 0.7, true, 1, 1)
    expectEqual(state.score, 1, 'fractional elapsed time should accumulate between ticks')
end)

runCase('accumulator remainder is preserved after full interval scoring', function()
    local state = ScoreLogic.newState(10)
    state = ScoreLogic.tick(state, 2.25, true, 1, 2)
    expectEqual(state.score, 14, 'two full intervals should apply increment twice')
    expectEqual(state.accumulatorSeconds, 0.25, 'remainder should be retained for next tick')
end)

runCase('zone and rank multipliers can be pre-multiplied into increment', function()
    local state = ScoreLogic.newState(100)
    local zoneMultiplier = 4
    local rankMultiplier = 1.5
    local perSecondBase = 2
    local increment = perSecondBase * zoneMultiplier * rankMultiplier

    state = ScoreLogic.tick(state, 2, true, 1, increment)
    expectEqual(state.score, 124, 'score should apply pre-multiplied increment every interval')
end)

runCase('combo ticks ramp score while staying in a zone', function()
    local state = ScoreLogic.newComboState(0)
    state = ScoreLogic.tickWithCombo(state, 3, true, 1, 100, 0.05, 2)
    expectEqual(state.score, 315, 'combo should apply 1x, 1.05x, then 1.10x increments')
    expectEqual(state.comboTicks, 3, 'combo tick count should advance per scoring interval')
end)

runCase('combo resets when leaving the zone', function()
    local state = ScoreLogic.newComboState(0)
    state = ScoreLogic.tickWithCombo(state, 2, true, 1, 100, 0.05, 2)
    state = ScoreLogic.tickWithCombo(state, 0.2, false, 1, 100, 0.05, 2)
    state = ScoreLogic.tickWithCombo(state, 1, true, 1, 100, 0.05, 2)

    expectEqual(state.score, 305, 'new zone streak should restart at the base increment')
    expectEqual(state.comboTicks, 1, 'combo should restart after leaving')
end)

runCase('combo multiplier caps at configured maximum', function()
    local state = ScoreLogic.newComboState(0)
    state = ScoreLogic.tickWithCombo(state, 4, true, 1, 100, 0.5, 2)
    expectEqual(state.score, 650, 'combo should cap after reaching maximum multiplier')
end)
