local ZoneLogic = require('../src/Shared/ZoneLogic')

local function expectEqual(actual: boolean, expected: boolean, message: string)
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

runCase('position inside radius returns true', function()
    local isInside = ZoneLogic.isPositionInsideCircle(
        { X = 5, Y = 2, Z = 5 },
        { X = 0, Y = 0, Z = 0 },
        10
    )
    expectEqual(isInside, true, 'position should be inside circle')
end)

runCase('position outside radius returns false', function()
    local isInside = ZoneLogic.isPositionInsideCircle(
        { X = 11, Y = 2, Z = 0 },
        { X = 0, Y = 0, Z = 0 },
        10
    )
    expectEqual(isInside, false, 'position should be outside circle')
end)

runCase('height differences do not affect inclusion', function()
    local isInside = ZoneLogic.isPositionInsideCircle(
        { X = 0, Y = 100, Z = 0 },
        { X = 0, Y = 0, Z = 0 },
        1
    )
    expectEqual(isInside, true, 'only horizontal distance should matter for circle checks')
end)
