local ZoneSkyLogic = require('../src/Shared/ZoneSkyLogic')

local function expectEqual(actual: any, expected: any, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function makeColor(r: number, g: number, b: number)
    local color = {
        R = r,
        G = g,
        B = b,
    }

    function color:Lerp(targetColor, alpha: number)
        return makeColor(
            self.R + ((targetColor.R - self.R) * alpha),
            self.G + ((targetColor.G - self.G) * alpha),
            self.B + ((targetColor.B - self.B) * alpha)
        )
    end

    return color
end

local function expectColorClose(actual, expected, tolerance: number, message: string)
    local rDelta = math.abs(actual.R - expected.R)
    local gDelta = math.abs(actual.G - expected.G)
    local bDelta = math.abs(actual.B - expected.B)
    local maxDelta = math.max(rDelta, gDelta, bDelta)

    if maxDelta > tolerance then
        error(
            string.format(
                '%s (expected [%0.4f, %0.4f, %0.4f], got [%0.4f, %0.4f, %0.4f])',
                message,
                expected.R,
                expected.G,
                expected.B,
                actual.R,
                actual.G,
                actual.B
            )
        )
    end
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

local zoneConfigs = {
    {
        center = { X = 0, Y = 0, Z = 0 },
        radius = 12,
        color = makeColor(120 / 255, 200 / 255, 1),
    },
    {
        center = { X = 40, Y = 0, Z = 0 },
        radius = 8,
        color = makeColor(1, 140 / 255, 140 / 255),
    },
}

runCase('returns zone index for matching position', function()
    local zoneIndex = ZoneSkyLogic.getCurrentZoneIndex({ X = 4, Y = 10, Z = 3 }, zoneConfigs)
    expectEqual(zoneIndex, 1, 'position inside first zone should return first index')
end)

runCase('returns nil when position is not inside any zone', function()
    local zoneIndex = ZoneSkyLogic.getCurrentZoneIndex({ X = 200, Y = 0, Z = 0 }, zoneConfigs)
    expectEqual(zoneIndex, nil, 'position outside zones should return nil')
end)

runCase('returns neutral tint when zone index is nil', function()
    local neutralColor = makeColor(1, 1, 1)
    local tint = ZoneSkyLogic.getSkyTintColor(nil, zoneConfigs, neutralColor, 0.42)
    expectColorClose(tint, neutralColor, 1e-6, 'nil zone should keep neutral tint')
end)

runCase('lerps sky tint toward active zone color', function()
    local neutralColor = makeColor(1, 1, 1)
    local tint = ZoneSkyLogic.getSkyTintColor(2, zoneConfigs, neutralColor, 0.5)
    local expected = neutralColor:Lerp(zoneConfigs[2].color, 0.5)
    expectColorClose(tint, expected, 1e-6, 'zone tint should blend with configured strength')
end)

runCase('clamps tint strength to supported range', function()
    local neutralColor = makeColor(1, 1, 1)
    local tint = ZoneSkyLogic.getSkyTintColor(1, zoneConfigs, neutralColor, 2)
    expectColorClose(tint, zoneConfigs[1].color, 1e-6, 'strength above one should clamp to one')
end)
