local ProgressionBalance = require('../src/Shared/ProgressionBalance')
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
    expectEqual(result.highestScoreAchieved, 0, 'missing data should default highest score')
    expectEqual(result.highestRankAchieved, 1, 'missing data should default highest rank')
    expectEqual(result.highestAgeAchieved, 1, 'missing data should default highest age')
    expectEqual(result.nextLuckyChestOpenAt, 0, 'missing data should default chest cooldown')
    expectEqual(result.scoreBoostExpiresAt, 0, 'missing data should default boost expiration')
    expectEqual(#result.unlockedHats, 0, 'missing data should default hats to empty')
    expectEqual(result.equippedHatId, nil, 'missing data should default equipped hat to nil')
end)

runCase('normalize backfills highest fields for old saved data', function()
    local result = ProfileDataLogic.normalize({
        score = 500,
        rebirths = 2,
    })

    expectEqual(
        result.highestScoreAchieved,
        500,
        'old data should backfill highest score from score'
    )
    local placeholderRankNames = table.create(ProgressionBalance.TOTAL_RANKS)
    for rankIndex = 1, ProgressionBalance.TOTAL_RANKS do
        placeholderRankNames[rankIndex] = string.format('Rank %d', rankIndex)
    end
    local rankConfigs, ageConfigs = ProgressionBalance.build(placeholderRankNames)

    expectEqual(
        result.highestRankAchieved,
        ProgressionBalance.getRankIndexForScore(500, rankConfigs),
        'old data should derive highest rank from score'
    )
    expectEqual(
        result.highestAgeAchieved,
        ProgressionBalance.getHighestUnlockedAgeIndex(500, ageConfigs),
        'old data should derive highest age from score'
    )
end)

runCase('normalize clamps invalid values to zero', function()
    local result = ProfileDataLogic.normalize({
        score = -12,
        rebirths = 0 / 0,
        highestScoreAchieved = math.huge,
        highestRankAchieved = -9,
        highestAgeAchieved = 0 / 0,
        nextLuckyChestOpenAt = -1,
        scoreBoostExpiresAt = math.huge,
    })

    expectEqual(result.score, 0, 'negative score should be clamped to zero')
    expectEqual(result.rebirths, 0, 'non-finite rebirths should be clamped to zero')
    expectEqual(result.highestScoreAchieved, 0, 'non-finite highest score should be clamped')
    expectEqual(
        result.highestRankAchieved,
        1,
        'invalid highest rank should fall back to derived rank'
    )
    expectEqual(result.highestAgeAchieved, 1, 'invalid highest age should fall back to derived age')
    expectEqual(result.nextLuckyChestOpenAt, 0, 'invalid chest timestamp should clamp to zero')
    expectEqual(result.scoreBoostExpiresAt, 0, 'invalid boost timestamp should clamp to zero')
end)

runCase('normalize floors decimal values from persisted data', function()
    local result = ProfileDataLogic.normalize({
        score = 15.9,
        rebirths = 3.2,
        highestScoreAchieved = 20.9,
        highestRankAchieved = 4.8,
        highestAgeAchieved = 2.7,
        nextLuckyChestOpenAt = 111.8,
        scoreBoostExpiresAt = 74.6,
        unlockedHats = { 'hat_one', 'hat_one', 42, 'hat_two' },
        unlockedVehicleMounts = { 'mount_one' },
        equippedHatId = 'hat_two',
        equippedVehicleMountId = 'mount_one',
    })

    expectEqual(result.score, 15, 'score should be stored as a whole number')
    expectEqual(result.rebirths, 3, 'rebirths should be stored as a whole number')
    expectEqual(result.highestScoreAchieved, 20, 'highest score should be stored as a whole number')
    expectEqual(result.nextLuckyChestOpenAt, 111, 'timestamps should be whole numbers')
    expectEqual(result.scoreBoostExpiresAt, 74, 'timestamps should be whole numbers')
    expectEqual(#result.unlockedHats, 2, 'duplicate/invalid inventory entries should be stripped')
    expectStringEqual(result.unlockedHats[2], 'hat_two', 'keeps valid entries in order')
    expectStringEqual(result.equippedHatId or '', 'hat_two', 'equipped hat should be preserved')
    expectStringEqual(
        result.equippedVehicleMountId or '',
        'mount_one',
        'equipped mount should be preserved'
    )
end)

runCase('toStoredValue serializes sanitized highest achieved values', function()
    local result = ProfileDataLogic.toStoredValue({
        score = 42.7,
        rebirths = -5,
        highestScoreAchieved = 40,
        highestRankAchieved = 1,
        highestAgeAchieved = 1,
        nextLuckyChestOpenAt = 17.9,
        scoreBoostExpiresAt = 23,
        unlockedHats = { 'hat_alpha', 'hat_alpha', 'hat_beta' },
        unlockedPets = { 'pet_one' },
        unlockedVehicleMounts = { 'mount_alpha' },
        equippedHatId = 'hat_beta',
        equippedVehicleMountId = 'mount_alpha',
    })

    expectEqual(result.score, 42, 'stored score should be sanitized')
    expectEqual(result.rebirths, 0, 'stored rebirths should be sanitized')
    expectEqual(result.highestScoreAchieved, 42, 'stored highest score should never trail score')
    local placeholderRankNames = table.create(ProgressionBalance.TOTAL_RANKS)
    for rankIndex = 1, ProgressionBalance.TOTAL_RANKS do
        placeholderRankNames[rankIndex] = string.format('Rank %d', rankIndex)
    end
    local rankConfigs, ageConfigs = ProgressionBalance.build(placeholderRankNames)

    expectEqual(
        result.highestRankAchieved,
        ProgressionBalance.getRankIndexForScore(42, rankConfigs),
        'stored highest rank should be derived from score when needed'
    )
    expectEqual(
        result.highestAgeAchieved,
        ProgressionBalance.getHighestUnlockedAgeIndex(42, ageConfigs),
        'stored highest age should be derived from score when needed'
    )
    expectEqual(result.nextLuckyChestOpenAt, 17, 'stored chest timestamp should be sanitized')
    expectEqual(result.scoreBoostExpiresAt, 23, 'stored boost timestamp should be sanitized')
    expectEqual(#result.unlockedHats, 2, 'stored hats should be deduplicated')
    expectStringEqual(result.equippedHatId or '', 'hat_beta', 'stored equipped hat should persist')
    expectStringEqual(
        result.equippedVehicleMountId or '',
        'mount_alpha',
        'stored equipped mount should persist'
    )
end)
