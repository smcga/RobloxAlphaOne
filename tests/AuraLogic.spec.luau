local AuraLogic = require('../src/Shared/AuraLogic')

local function expectEqual(actual: any, expected: any, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function expectGreater(actual: number, expectedFloor: number, message: string)
    if actual <= expectedFloor then
        error(
            string.format(
                '%s (expected > %s, got %s)',
                message,
                tostring(expectedFloor),
                tostring(actual)
            )
        )
    end
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

runCase('getAuraConfig clamps rank index and unlocks richer values over ranks', function()
    local lowRankConfig = AuraLogic.getAuraConfig(1, 100)
    local highRankConfig = AuraLogic.getAuraConfig(100, 100)

    expectGreater(highRankConfig.rate, lowRankConfig.rate, 'higher rank should emit more particles')
    expectGreater(
        highRankConfig.lightBrightness,
        lowRankConfig.lightBrightness,
        'higher rank should be brighter'
    )
    expectGreater(
        highRankConfig.lightRange,
        lowRankConfig.lightRange,
        'higher rank should glow wider'
    )
    expectEqual(
        lowRankConfig.hasSecondaryBurst,
        false,
        'low rank should not have secondary burst effects'
    )
    expectEqual(
        highRankConfig.hasSecondaryBurst,
        true,
        'high rank should unlock secondary burst effects'
    )
end)

runCase('getAuraConfig treats out-of-range rank indexes as valid clamped ranks', function()
    local clampedFloor = AuraLogic.getAuraConfig(-12, 100)
    local firstRank = AuraLogic.getAuraConfig(1, 100)
    local clampedCeiling = AuraLogic.getAuraConfig(999, 100)
    local lastRank = AuraLogic.getAuraConfig(100, 100)

    expectEqual(clampedFloor.rate, firstRank.rate, 'negative rank should clamp to first rank rate')
    expectEqual(
        clampedCeiling.lightRange,
        lastRank.lightRange,
        'too-high rank should clamp to last rank range'
    )
end)
