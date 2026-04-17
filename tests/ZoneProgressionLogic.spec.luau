local ZoneProgressionLogic = require('../src/Shared/ZoneProgressionLogic')

local function expectEqual(actual: number, expected: number, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function expectBoolean(actual: boolean, expected: boolean, message: string)
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

local function tick(state, overrides)
    local defaultInput = {
        deltaSeconds = 1,
        isInsideBlueZone = false,
        isInsideRedZone = false,
        scoreIntervalSeconds = 1,
        blueIncrement = 1,
        redIncrement = 50,
        redRequiredScore = 100,
    }

    for key, value in pairs(overrides) do
        defaultInput[key] = value
    end

    return ZoneProgressionLogic.tick(state, defaultInput)
end

runCase('standing in blue zone increments by one', function()
    local result = tick(ZoneProgressionLogic.newState(0), {
        isInsideBlueZone = true,
    })

    expectEqual(result.state.score, 1, 'blue zone should increment score by one')
    expectBoolean(
        result.shouldPunishForRedZone,
        false,
        'blue zone should not trigger red punishment'
    )
end)

runCase('red zone increments by fifty when requirement is met', function()
    local result = tick(ZoneProgressionLogic.newState(100), {
        isInsideRedZone = true,
    })

    expectEqual(result.state.score, 150, 'red zone should increment score by fifty')
    expectBoolean(result.shouldPunishForRedZone, false, 'eligible red zone entry should not punish')
end)

runCase('red zone punishes when score is below requirement', function()
    local result = tick(ZoneProgressionLogic.newState(99), {
        isInsideRedZone = true,
    })

    expectEqual(result.state.score, 99, 'red zone should not add score before requirement')
    expectBoolean(result.shouldPunishForRedZone, true, 'ineligible red zone entry should punish')
end)

runCase('reaching requirement in blue zone unlocks red zone immediately', function()
    local result = tick(ZoneProgressionLogic.newState(99), {
        isInsideBlueZone = true,
        isInsideRedZone = true,
    })

    expectEqual(result.state.score, 150, 'blue gain should unlock red gain in the same tick')
    expectBoolean(
        result.shouldPunishForRedZone,
        false,
        'player should not be punished once requirement is met in the same tick'
    )
end)
