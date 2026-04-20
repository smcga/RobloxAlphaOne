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
        isInsideEighteenHundredsZone = false,
        isInsideRebirthZone = false,
        scoreIntervalSeconds = 1,
        blueIncrement = 1,
        redIncrement = 50,
        redRequiredScore = 100,
        eighteenHundredsIncrement = 500,
        eighteenHundredsRequiredScore = 50000000,
        rebirthScoreDivisor = 1000,
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
    expectEqual(result.state.rebirths, 0, 'rebirths should start at zero')
    expectBoolean(
        result.shouldPunishForRedZone,
        false,
        'blue zone should not trigger red punishment'
    )
end)

runCase('rebirth count multiplies score gain per tick', function()
    local result = tick(ZoneProgressionLogic.newState(0, 2), {
        isInsideBlueZone = true,
    })

    expectEqual(result.state.score, 2, 'two rebirths should double blue score gain')
end)

runCase('entering rebirth zone resets score and awards rebirths', function()
    local result = tick(ZoneProgressionLogic.newState(2100, 3), {
        isInsideRebirthZone = true,
    })

    expectEqual(result.state.score, 0, 'rebirth should reset score to zero')
    expectEqual(result.state.rebirths, 5, 'rebirth should award floor(score / 1000)')
end)

runCase('staying in rebirth zone does not repeatedly grant rebirths', function()
    local state = ZoneProgressionLogic.newState(2100, 3)
    local first = tick(state, {
        isInsideRebirthZone = true,
    })
    local second = tick(first.state, {
        isInsideRebirthZone = true,
    })

    expectEqual(second.state.rebirths, 5, 'rebirth grants should only happen on zone entry')
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

runCase("1700's zone increments by 500 when requirement is met", function()
    local result = tick(ZoneProgressionLogic.newState(50000000), {
        isInsideEighteenHundredsZone = true,
    })

    expectEqual(result.state.score, 50000500, "1700's zone should increment score by five hundred")
end)

runCase("1700's zone does not increment before requirement is met", function()
    local result = tick(ZoneProgressionLogic.newState(49999999), {
        isInsideEighteenHundredsZone = true,
    })

    expectEqual(result.state.score, 49999999, "1700's zone should stay locked below requirement")
end)
