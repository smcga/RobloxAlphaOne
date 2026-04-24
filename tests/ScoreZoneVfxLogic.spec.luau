local ScoreZoneVfxLogic = require('../src/Shared/ScoreZoneVfxLogic')

local function expectEqual(actual: number | boolean, expected: number | boolean, message: string)
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

local zoneConfigs = {
    { requiredScore = 0 },
    { requiredScore = 100 },
    { requiredScore = 500 },
}

runCase('inside unlocked zone is considered active scoring zone', function()
    local isInsideScoringZone = ScoreZoneVfxLogic.isInsideScoringZone(0, {
        true,
        false,
        false,
    }, zoneConfigs)

    expectEqual(isInsideScoringZone, true, 'first zone should be active at score 0')
end)

runCase('inside locked zone is not considered an active scoring zone', function()
    local isInsideScoringZone = ScoreZoneVfxLogic.isInsideScoringZone(80, {
        false,
        true,
        false,
    }, zoneConfigs)

    expectEqual(isInsideScoringZone, false, 'locked zone should not be active')
end)

runCase('score burst emits nothing outside scoring zones', function()
    local burstCount = ScoreZoneVfxLogic.getScoreBurstCount(100, 150, false, 12)
    expectEqual(burstCount, 0, 'score bursts should be disabled outside active zones')
end)

runCase('score burst count follows whole-number score gain while inside scoring zones', function()
    local burstCount = ScoreZoneVfxLogic.getScoreBurstCount(100, 104.8, true, 12)
    expectEqual(burstCount, 4, 'score bursts should floor fractional score gain')
end)

runCase('score burst count is capped for very large gains', function()
    local burstCount = ScoreZoneVfxLogic.getScoreBurstCount(0, 200, true, 12)
    expectEqual(burstCount, 12, 'score bursts should cap to avoid excessive particles')
end)
