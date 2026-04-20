local WorldDecorLogic = require('../src/Shared/WorldDecorLogic')

local FLOOR_Y = -0.5

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

local function getVerticalHalfExtent(spec: WorldDecorLogic.DecorSpec): number
    if spec.shape == 'Cylinder' then
        local rotation = spec.rotation
        if rotation and math.abs(rotation.z) % 180 == 90 then
            return spec.size.x / 2
        end
    end

    return spec.size.y / 2
end

runCase('decor specs include stable scene pieces', function()
    local specs = WorldDecorLogic.getDecorSpecs()
    expectEqual(#specs, 11, 'scene should include the expected number of decor parts')

    local foundMainPath = false
    local foundTreeLeaves = false

    for _, spec in specs do
        if spec.name == 'MainPath' then
            foundMainPath = true
        end

        if spec.name == 'NorthTreeLeaves' then
            foundTreeLeaves = true
        end
    end

    expectTruthy(foundMainPath, 'main path decor should exist')
    expectTruthy(foundTreeLeaves, 'tree leaves decor should exist')
end)

runCase('critical cylinder props are rotated into their intended orientation', function()
    local specs = WorldDecorLogic.getDecorSpecs()
    local expectedRotations = {
        CenterPad = 90,
        NorthTree = 90,
        SouthTree = 90,
    }

    for decorName, expectedZRotation in expectedRotations do
        local foundSpec = nil

        for _, spec in specs do
            if spec.name == decorName then
                foundSpec = spec
                break
            end
        end

        expectTruthy(foundSpec, string.format('missing decor spec for %s', decorName))
        expectTruthy(foundSpec.rotation, string.format('%s should define rotation', decorName))
        expectEqual(
            foundSpec.rotation.z,
            expectedZRotation,
            string.format('%s should have expected z-axis rotation', decorName)
        )
    end
end)

runCase('decor specs stay near the base playable area', function()
    local specs = WorldDecorLogic.getDecorSpecs()

    for _, spec in specs do
        local horizontalDistance = math.max(math.abs(spec.position.x), math.abs(spec.position.z))
        if horizontalDistance > 64 then
            error(string.format('decor %s is outside the baseplate bounds', spec.name))
        end
    end
end)

runCase('decor does not clip deeply below the floor', function()
    local specs = WorldDecorLogic.getDecorSpecs()

    for _, spec in specs do
        local bottomY = spec.position.y - getVerticalHalfExtent(spec)
        if bottomY < FLOOR_Y then
            error(string.format('decor %s clips below floor (bottomY=%0.2f)', spec.name, bottomY))
        end
    end
end)
