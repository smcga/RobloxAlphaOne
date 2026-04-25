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

runCase('standing in first age zone increments by one without rebirth boost', function()
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

runCase('rebirth multiplier applies immediately after rebirth regardless of prior best', function()
    local result = tick(ZoneProgressionLogic.newState(0, 2, 500, 2, 2), {
        isInsideAgeZones = {
            true,
            false,
            false,
        },
    })

    expectEqual(result.state.score, 15, '2 rebirths should apply 15x rebirth multiplier')
end)

runCase('bonus score multiplier stacks with rebirth multiplier', function()
    local result = tick(ZoneProgressionLogic.newState(0, 2, 500, 2, 2), {
        isInsideAgeZones = {
            true,
            false,
            false,
        },
        bonusScoreMultiplier = 10,
    })

    expectEqual(result.state.score, 150, '10x boost should stack with rebirth multiplier')
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

runCase('rebirth multiplier caps at max catch-up multiplier', function()
    local result = tick(ZoneProgressionLogic.newState(0, 10, 100, 1, 1), {
        isInsideAgeZones = {
            true,
            false,
            false,
        },
    })

    expectEqual(result.state.score, 30, 'rebirth multiplier should cap at 30x')
end)

runCase('rebirth multiplier still applies at or above highest score achieved', function()
    local result = tick(ZoneProgressionLogic.newState(100, 4, 100, 2, 2), {
        isInsideAgeZones = {
            true,
            false,
            false,
        },
    })

    expectEqual(result.state.score, 129, 'rebirth multiplier should apply even at record score')
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

runCase('rebirth zone does not grant rebirth when score is below rebirth requirement', function()
    local result = tick(ZoneProgressionLogic.newState(1000, 0, 1000, 2, 1), {
        isInsideRebirthZone = true,
        rebirthConfig = {
            baseRequirementScore = 1200,
            requirementGrowthPerRebirth = 350,
            scoreToBonusPower = 0.72,
            scoreToBonusScale = 2.6,
            maxBonusRebirthsFromScore = 20,
            hourlyFinalZoneBonus = {
                chancePerHour = 0.35,
                activeWindowSeconds = 180,
                bonusRebirths = 2,
            },
        },
        nowUnixTime = 0,
        isInsideFinalAgeZone = false,
    })

    expectEqual(result.state.score, 1000, 'failed rebirth should keep score unchanged')
    expectEqual(result.state.rebirths, 0, 'failed rebirth should not grant rebirths')
end)

runCase(
    'rebirth does not restore pre-rebirth score or reduce granted rebirths on next zone tick',
    function()
        local preRebirthScore = 155000000
        local rebirthed =
            tick(ZoneProgressionLogic.newState(preRebirthScore, 12, preRebirthScore, 3, 3), {
                isInsideRebirthZone = true,
                rebirthConfig = {
                    baseRequirementScore = 1000,
                    requirementGrowthPerRebirth = 0,
                    scoreToBonusPower = 0.72,
                    scoreToBonusScale = 2.6,
                    maxBonusRebirthsFromScore = 20,
                    hourlyFinalZoneBonus = {
                        chancePerHour = 0,
                        activeWindowSeconds = 180,
                        bonusRebirths = 2,
                    },
                },
                nowUnixTime = 0,
                isInsideFinalAgeZone = false,
            })

        local afterFirstZoneTick = tick(rebirthed.state, {
            isInsideAgeZones = {
                true,
                false,
                false,
            },
            isInsideRebirthZone = false,
        })

        expectEqual(rebirthed.state.score, 0, 'rebirth should reset score to zero immediately')
        expectEqual(
            rebirthed.state.rebirths,
            155012,
            'rebirth should include one rebirth per 1000 score'
        )
        expectEqual(
            afterFirstZoneTick.state.rebirths,
            rebirthed.state.rebirths,
            'next zone tick should not roll rebirth count back'
        )
        expectEqual(
            afterFirstZoneTick.state.score,
            30,
            'next zone tick should restart from zero and use rebirth multiplier, not restore prior score'
        )
    end
)

runCase('rank multiplier contributes to score gain', function()
    local result = tick(ZoneProgressionLogic.newState(0, 0, 500, 2, 2), {
        isInsideAgeZones = {
            true,
            false,
            false,
        },
        rankScoreMultiplier = 1.2,
    })

    expectEqual(result.state.score, 1.2, 'rank multiplier should scale zone score increment')
end)
