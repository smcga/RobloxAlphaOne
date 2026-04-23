local ProfileDataLogic = require('../src/Shared/ProfileDataLogic')

local function expectEqual(actual: number, expected: number, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function expectStringEqual(actual: string, expected: string, message: string)
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
    expectEqual(result.nextLuckyChestOpenAt, 0, 'missing data should default chest cooldown')
    expectEqual(result.scoreBoostExpiresAt, 0, 'missing data should default boost expiration')
    expectEqual(#result.unlockedHats, 0, 'missing data should default hats to empty')
end)

runCase('normalize clamps invalid values to zero', function()
    local result = ProfileDataLogic.normalize({
        score = -12,
        rebirths = 0 / 0,
        nextLuckyChestOpenAt = -1,
        scoreBoostExpiresAt = math.huge,
    })

    expectEqual(result.score, 0, 'negative score should be clamped to zero')
    expectEqual(result.rebirths, 0, 'non-finite rebirths should be clamped to zero')
    expectEqual(result.nextLuckyChestOpenAt, 0, 'invalid chest timestamp should clamp to zero')
    expectEqual(result.scoreBoostExpiresAt, 0, 'invalid boost timestamp should clamp to zero')
end)

runCase('normalize floors decimal values from persisted data', function()
    local result = ProfileDataLogic.normalize({
        score = 15.9,
        rebirths = 3.2,
        nextLuckyChestOpenAt = 111.8,
        scoreBoostExpiresAt = 74.6,
        unlockedHats = { 'hat_one', 'hat_one', 42, 'hat_two' },
    })

    expectEqual(result.score, 15, 'score should be stored as a whole number')
    expectEqual(result.rebirths, 3, 'rebirths should be stored as a whole number')
    expectEqual(result.nextLuckyChestOpenAt, 111, 'timestamps should be whole numbers')
    expectEqual(result.scoreBoostExpiresAt, 74, 'timestamps should be whole numbers')
    expectEqual(#result.unlockedHats, 2, 'duplicate/invalid inventory entries should be stripped')
    expectStringEqual(result.unlockedHats[2], 'hat_two', 'keeps valid entries in order')
end)

runCase('toStoredValue serializes sanitized values', function()
    local result = ProfileDataLogic.toStoredValue({
        score = 42.7,
        rebirths = -5,
        nextLuckyChestOpenAt = 17.9,
        scoreBoostExpiresAt = 23,
        unlockedHats = { 'hat_alpha', 'hat_alpha', 'hat_beta' },
        unlockedPets = { 'pet_one' },
        unlockedVehicleMounts = {},
    })

    expectEqual(result.score, 42, 'stored score should be sanitized')
    expectEqual(result.rebirths, 0, 'stored rebirths should be sanitized')
    expectEqual(result.nextLuckyChestOpenAt, 17, 'stored chest timestamp should be sanitized')
    expectEqual(result.scoreBoostExpiresAt, 23, 'stored boost timestamp should be sanitized')
    expectEqual(#result.unlockedHats, 2, 'stored hats should be deduplicated')
end)
