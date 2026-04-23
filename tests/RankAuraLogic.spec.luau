local RankAuraLogic = require('../src/Shared/RankAuraLogic')

local function expectEqual(actual: any, expected: any, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function expectTrue(value: boolean, message: string)
    if not value then
        error(message)
    end
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

runCase('getAuraForRank clamps rank index and max ranks', function()
    local aura = RankAuraLogic.getAuraForRank(-10, 0)
    expectEqual(aura.rankIndex, 1, 'rank index should clamp to 1')
    expectEqual(aura.intensityAlpha, 1, 'single rank should resolve full intensity')
end)

runCase('getAuraForRank scales intensity as rank increases', function()
    local earlyAura = RankAuraLogic.getAuraForRank(5, 100)
    local lateAura = RankAuraLogic.getAuraForRank(90, 100)

    expectTrue(
        lateAura.scaleMultiplier > earlyAura.scaleMultiplier,
        'higher rank should increase player size multiplier'
    )
    expectTrue(
        lateAura.coreEmissionRate > earlyAura.coreEmissionRate,
        'higher rank should emit more core particles'
    )
    expectTrue(
        lateAura.sparkleEmissionRate > earlyAura.sparkleEmissionRate,
        'higher rank should emit more sparkle particles'
    )
    expectTrue(lateAura.glowRange > earlyAura.glowRange, 'higher rank should glow farther')
end)

runCase('getAuraForRank produces deterministic unique hues per rank', function()
    local auraOne = RankAuraLogic.getAuraForRank(1, 100)
    local auraTwo = RankAuraLogic.getAuraForRank(2, 100)
    local auraOneRepeat = RankAuraLogic.getAuraForRank(1, 100)

    expectTrue(
        auraOne.primaryHue ~= auraTwo.primaryHue,
        'adjacent ranks should not reuse the same primary hue'
    )
    expectEqual(
        auraOne.primaryHue,
        auraOneRepeat.primaryHue,
        'same rank should always produce the same primary hue'
    )
end)
