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

local rankConfigs = {
    { name = 'r1', requiredScore = 0 },
    { name = 'r2', requiredScore = 100 },
    { name = 'r3', requiredScore = 1000 },
}

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
        rankConfigs = rankConfigs,
        rebirthCatchUpPerRebirth = 7,
        maxCatchUpMultiplier = 30,
        postRecordRebirthMultiplier = 1,
    }

    for key, value in pairs(overrides) do
        defaultInput[key] = value
    end

    return ZoneProgressionLogic.tick(state, defaultInput)
end

runCase('standing in first age zone increments by one without rebirth catch-up', function()
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

runCase('catch-up multiplier applies when current score is below highest achieved score', function()
    local result = tick(ZoneProgressionLogic.newState(0, 2, 500, 2, 2), {
        isInsideAgeZones = {
            true,
            false,
            false,
        },
    })

    expectEqual(result.state.score, 15, '2 rebirths should apply 15x catch-up multiplier')
end)

runCase('bonus score multiplier stacks with catch-up multiplier', function()
    local result = tick(ZoneProgressionLogic.newState(0, 2, 500, 2, 2), {
        isInsideAgeZones = {
            true,
            false,
            false,
        },
        bonusScoreMultiplier = 10,
    })

    expectEqual(result.state.score, 150, '10x boost should stack with catch-up multiplier')
end)

runCase('entering rebirth zone resets score and increments rebirths by exactly one', function()
    local result = tick(ZoneProgressionLogic.newState(2100, 3, 2100, 3, 1), {
        isInsideRebirthZone = true,
    })

    expectEqual(result.state.score, 0, 'rebirth should reset score to zero')
    expectEqual(result.state.rebirths, 4, 'rebirth should increment by one')
    expectEqual(
        result.state.highestScoreAchieved,
        2100,
        'rebirth should preserve highest score achieved'
    )
end)

runCase('staying in rebirth zone does not repeatedly grant rebirths', function()
    local state = ZoneProgressionLogic.newState(2100, 3, 2100, 3, 1)
    local first = tick(state, {
        isInsideRebirthZone = true,
    })
    local second = tick(first.state, {
        isInsideRebirthZone = true,
    })

    expectEqual(second.state.rebirths, 4, 'rebirth grants should only happen on zone entry')
end)

runCase('catch-up multiplier caps at max catch-up multiplier', function()
    local result = tick(ZoneProgressionLogic.newState(0, 10, 100, 1, 1), {
        isInsideAgeZones = {
            true,
            false,
            false,
        },
    })

    expectEqual(result.state.score, 30, 'catch-up should cap at 30x multiplier')
end)

runCase('catch-up multiplier becomes one at or above highest score achieved', function()
    local result = tick(ZoneProgressionLogic.newState(100, 4, 100, 2, 2), {
        isInsideAgeZones = {
            true,
            false,
            false,
        },
    })

    expectEqual(result.state.score, 101, 'no catch-up multiplier should apply at record score')
end)

runCase('highest rank and age are preserved and updated on score growth', function()
    local result = tick(ZoneProgressionLogic.newState(100, 0, 100, 1, 1), {
        isInsideAgeZones = {
            false,
            true,
            false,
        },
    })

    expectEqual(
        result.state.highestRankAchieved,
        2,
        'score growth in unlocked zone should update highest rank'
    )
    expectEqual(
        result.state.highestAgeAchieved,
        2,
        'score growth in unlocked zone should update highest age'
    )
end)

runCase('rebirth resets accumulated partial time across all ages', function()
    local first = tick(ZoneProgressionLogic.newState(1999, 0, 1999, 3, 3), {
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
