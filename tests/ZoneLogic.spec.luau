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

runCase('position exactly on radius boundary returns true', function()
    local isInside = ZoneLogic.isPositionInsideCircle(
        { X = 10, Y = 0, Z = 0 },
        { X = 0, Y = 0, Z = 0 },
        10
    )
    expectEqual(isInside, true, 'boundary position should count as inside circle')
end)

runCase('oriented circle check stays valid for rotated zone parts', function()
    local zoneCFrame = {
        PointToObjectSpace = function(_, _)
            return { X = 0, Y = 8, Z = 9 }
        end,
    }
    local zoneSize = { X = 4, Y = 32, Z = 32 }
    local isInside =
        ZoneLogic.isPositionInsideOrientedCircle({ X = 12, Y = 20, Z = -10 }, zoneCFrame, zoneSize)

    expectEqual(isInside, true, 'rotated cylinder zone should still detect inside positions')
end)

runCase('oriented circle check rejects points outside radial range', function()
    local zoneCFrame = {
        PointToObjectSpace = function(_, _)
            return { X = 0, Y = 40, Z = 0 }
        end,
    }
    local zoneSize = { X = 4, Y = 32, Z = 32 }
    local isInside =
        ZoneLogic.isPositionInsideOrientedCircle({ X = 100, Y = 1, Z = 0 }, zoneCFrame, zoneSize)

    expectEqual(isInside, false, 'far radial points should remain outside zone')
end)
