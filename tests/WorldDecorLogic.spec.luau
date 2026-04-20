local WorldDecorLogic = require('../src/Shared/WorldDecorLogic')

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

runCase('decor specs stay near the base playable area', function()
    local specs = WorldDecorLogic.getDecorSpecs()

    for _, spec in specs do
        local horizontalDistance = math.max(math.abs(spec.position.x), math.abs(spec.position.z))
        if horizontalDistance > 64 then
            error(string.format('decor %s is outside the baseplate bounds', spec.name))
        end
    end
end)
