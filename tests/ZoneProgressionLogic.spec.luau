local ZoneProgressionLogic = require('../src/Shared/ZoneProgressionLogic')

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

local function tick(state, overrides)
    local defaultInput = {
        deltaSeconds = 1,
        isInsideAgeZones = {
            false,
            false,
            false,
        },
        ageZoneConfigs = {
            {
                requiredScore = 0,
                scoreIncrement = 1,
            },
            {
                requiredScore = 100,
                scoreIncrement = 50,
            },
            {
                requiredScore = 1000,
                scoreIncrement = 500,
            },
        },
        isInsideRebirthZone = false,
        scoreIntervalSeconds = 1,
        rebirthScoreDivisor = 1000,
    }

    for key, value in pairs(overrides) do
        defaultInput[key] = value
    end

    return ZoneProgressionLogic.tick(state, defaultInput)
end

runCase('standing in first age zone increments by one', function()
    local result = tick(ZoneProgressionLogic.newState(0), {
        isInsideAgeZones = {
            true,
            false,
            false,
        },
    })

    expectEqual(result.state.score, 1, 'first age zone should increment score by one')
    expectEqual(result.state.rebirths, 0, 'rebirths should start at zero')
end)

runCase('rebirth count multiplies score gain per tick', function()
    local result = tick(ZoneProgressionLogic.newState(0, 2), {
        isInsideAgeZones = {
            true,
            false,
            false,
        },
    })

    expectEqual(result.state.score, 2, 'two rebirths should double zone score gain')
end)

runCase('bonus score multiplier from lucky chest stacks with rebirth multiplier', function()
    local result = tick(ZoneProgressionLogic.newState(0, 2), {
        isInsideAgeZones = {
            true,
            false,
            false,
        },
        bonusScoreMultiplier = 10,
    })

    expectEqual(result.state.score, 20, '2 rebirths and 10x boost should multiply zone gain')
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

runCase('locked age zone increments when requirement is met', function()
    local result = tick(ZoneProgressionLogic.newState(100), {
        isInsideAgeZones = {
            false,
            true,
            false,
        },
    })

    expectEqual(result.state.score, 150, 'second age zone should increment by fifty')
end)

runCase('locked age zone does not increment when requirement is unmet', function()
    local result = tick(ZoneProgressionLogic.newState(99), {
        isInsideAgeZones = {
            false,
            true,
            false,
        },
    })

    expectEqual(result.state.score, 99, 'second age zone should stay locked below requirement')
end)

runCase('reaching requirement in one age unlocks next age in the same tick', function()
    local result = tick(ZoneProgressionLogic.newState(99), {
        isInsideAgeZones = {
            true,
            true,
            false,
        },
    })

    expectEqual(
        result.state.score,
        150,
        'first age gain should unlock second age gain in the same tick'
    )
end)

runCase('multiple unlocked ages stack in a single tick', function()
    local result = tick(ZoneProgressionLogic.newState(1000), {
        isInsideAgeZones = {
            true,
            true,
            true,
        },
    })

    expectEqual(result.state.score, 1551, 'all unlocked age increments should stack')
end)

runCase('rebirth resets accumulated partial time across all ages', function()
    local first = tick(ZoneProgressionLogic.newState(1999, 0), {
        deltaSeconds = 0.5,
        isInsideAgeZones = {
            true,
            false,
            false,
        },
    })
    local rebirthed = tick(first.state, {
        isInsideRebirthZone = true,
    })
    local afterRebirth = tick(rebirthed.state, {
        deltaSeconds = 0.5,
        isInsideAgeZones = {
            true,
            false,
            false,
        },
    })

    expectEqual(rebirthed.state.score, 0, 'rebirth should reset score to zero')
    expectEqual(afterRebirth.state.score, 0, 'partial age timers should reset on rebirth')
end)
