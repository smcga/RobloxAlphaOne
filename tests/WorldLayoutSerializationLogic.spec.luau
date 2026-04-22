local WorldLayoutSerializationLogic = require('../src/Shared/WorldLayoutSerializationLogic')

local function expectEqual<T>(actual: T, expected: T, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function expectTruthy(value: unknown, message: string)
    if not value then
        error(message)
    end
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

runCase('serializeDecorSpecs sorts output by worldId', function()
    local serialized = WorldLayoutSerializationLogic.serializeDecorSpecs({
        {
            worldId = 'B',
            kind = 'Part',
            name = 'Beta',
            shape = 'Block',
            size = { x = 1, y = 1, z = 1 },
            position = { x = 2, y = 3, z = 4 },
            color = { r = 1, g = 2, b = 3 },
            material = 'Slate',
        },
        {
            worldId = 'A',
            kind = 'Asset',
            name = 'Alpha',
            assetId = 123,
            position = { x = 0, y = 0, z = 0 },
            scale = 1,
        },
    })

    local alphaStart = string.find(serialized, "worldId = 'A'", 1, true)
    local betaStart = string.find(serialized, "worldId = 'B'", 1, true)
    expectTruthy(alphaStart and betaStart, 'serialized output should include both world ids')
    expectTruthy(alphaStart < betaStart, 'serialized output should be sorted by worldId')
end)

runCase('serializeDecorSpecs keeps deterministic numeric formatting', function()
    local serialized = WorldLayoutSerializationLogic.serializeDecorSpecs({
        {
            worldId = 'PrecisePart',
            kind = 'Part',
            name = 'PrecisePart',
            shape = 'Cylinder',
            size = { x = 1, y = 2.5000, z = 3.1250 },
            position = { x = 1.5, y = -2, z = 0 },
            rotation = { x = 0, y = 45.2500, z = 90 },
            color = { r = 10, g = 20, b = 30 },
            material = 'Grass',
            transparency = 0,
        },
    })

    expectTruthy(
        string.find(serialized, '{ x = 1, y = 2.5, z = 3.125 }', 1, true) ~= nil,
        'size vector should trim trailing zeroes'
    )
    expectTruthy(
        string.find(serialized, 'rotation = { x = 0, y = 45.25, z = 90 },', 1, true) ~= nil,
        'rotation should keep deterministic decimal precision'
    )
    expectTruthy(
        string.find(serialized, 'local WorldLayout = {}', 1, true) == 1,
        'module should start with header'
    )
end)
