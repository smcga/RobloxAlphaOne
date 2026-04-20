local ScorePopupLogic = require('../src/Shared/ScorePopupLogic')
local NumberFormat = require('../src/Shared/NumberFormat')

local function expectEqual(actual: any, expected: any, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function expectNear(actual: number, expected: number, epsilon: number, message: string)
    if math.abs(actual - expected) > epsilon then
        error(string.format('%s (expected %.4f, got %.4f)', message, expected, actual))
    end
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

runCase('returns nil when score has no previous value', function()
    expectEqual(
        ScorePopupLogic.getPositiveIncrease(nil, 10),
        nil,
        'first update should not create popup'
    )
end)

runCase('returns nil when score does not increase', function()
    expectEqual(
        ScorePopupLogic.getPositiveIncrease(10, 10),
        nil,
        'equal values should not create popup'
    )
    expectEqual(ScorePopupLogic.getPositiveIncrease(10, 4), nil, 'decrease should not create popup')
end)

runCase('returns positive increase amount', function()
    expectEqual(ScorePopupLogic.getPositiveIncrease(25, 125), 100, 'should return the gain amount')
end)

runCase('formats popup text with compact lowercase style', function()
    expectEqual(
        ScorePopupLogic.formatIncreaseText(1600, NumberFormat.formatCompact),
        '+1.6k',
        'should produce compact plus-prefixed increase text'
    )
end)

runCase('computes random popup position within padded bounds', function()
    local x, y = ScorePopupLogic.getRandomPopupPosition(1920, 1080, 160, 60, 0.5, 0.25)
    expectNear(x, 880, 1e-6, 'x should be midpoint of padded horizontal range')
    expectNear(y, 265, 1e-6, 'y should reflect randomY selection in padded vertical range')
end)
