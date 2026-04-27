local AgeZoneRuntimeLogic = require('../src/Shared/AgeZoneRuntimeLogic')

local function expectEqual(actual: any, expected: any, message: string)
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

local function expectCenterEqual(
    actual: { X: number, Y: number, Z: number },
    expected: { X: number, Y: number, Z: number },
    message: string
)
    if actual.X ~= expected.X or actual.Y ~= expected.Y or actual.Z ~= expected.Z then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

runCase('returns fallback center and radius when runtime snapshot is missing', function()
    local configs = AgeZoneRuntimeLogic.buildRuntimeConfigs({
        {
            zoneName = 'AgeOfBeadsZone',
            requiredScore = 0,
            scoreIncrement = 1,
            center = { X = 10, Y = 1, Z = 20 },
            radius = 16,
        },
    })

    expectCenterEqual(configs[1].center, { X = 10, Y = 1, Z = 20 }, 'should keep fallback center')
    expectEqual(configs[1].radius, 16, 'should keep fallback radius')
end)

runCase('uses runtime snapshot center and radius when available', function()
    local configs = AgeZoneRuntimeLogic.buildRuntimeConfigs({
        {
            zoneName = 'AgeOfBeadsZone',
            requiredScore = 0,
            scoreIncrement = 1,
            center = { X = 10, Y = 1, Z = 20 },
            radius = 16,
        },
    }, {
        AgeOfBeadsZone = {
            position = { X = 100, Y = 3, Z = -50 },
            size = { Y = 40, Z = 32 },
        },
    })

    expectCenterEqual(
        configs[1].center,
        { X = 100, Y = 3, Z = -50 },
        'should use runtime zone center'
    )
    expectEqual(configs[1].radius, 20, 'radius should be derived from runtime diameter')
end)

runCase('falls back to configured radius when runtime diameter is invalid', function()
    local configs = AgeZoneRuntimeLogic.buildRuntimeConfigs({
        {
            zoneName = 'AgeOfBeadsZone',
            requiredScore = 0,
            scoreIncrement = 1,
            center = { X = 10, Y = 1, Z = 20 },
            radius = 16,
        },
    }, {
        AgeOfBeadsZone = {
            position = { X = 100, Y = 3, Z = -50 },
            size = { Y = 0, Z = 0 },
        },
    })

    expectEqual(configs[1].radius, 16, 'zero runtime diameter should keep fallback radius')
end)
