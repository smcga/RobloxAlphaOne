local ProfileDataLogic = require('../src/Shared/ProfileDataLogic')

local function expectEqual(actual: number, expected: number, message: string)
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

runCase('normalize returns zeroed state when persisted data is missing', function()
    local result = ProfileDataLogic.normalize(nil)

    expectEqual(result.score, 0, 'missing data should default score to zero')
    expectEqual(result.rebirths, 0, 'missing data should default rebirths to zero')
end)

runCase('normalize clamps invalid values to zero', function()
    local result = ProfileDataLogic.normalize({
        score = -12,
        rebirths = 0 / 0,
    })

    expectEqual(result.score, 0, 'negative score should be clamped to zero')
    expectEqual(result.rebirths, 0, 'non-finite rebirths should be clamped to zero')
end)

runCase('normalize floors decimal values from persisted data', function()
    local result = ProfileDataLogic.normalize({
        score = 15.9,
        rebirths = 3.2,
    })

    expectEqual(result.score, 15, 'score should be stored as a whole number')
    expectEqual(result.rebirths, 3, 'rebirths should be stored as a whole number')
end)

runCase('toStoredValue serializes sanitized values', function()
    local result = ProfileDataLogic.toStoredValue({
        score = 42.7,
        rebirths = -5,
    })

    expectEqual(result.score, 42, 'stored score should be sanitized')
    expectEqual(result.rebirths, 0, 'stored rebirths should be sanitized')
end)
