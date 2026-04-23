local LuckyChestLogic = require('../src/Shared/LuckyChestLogic')

local function expectEqual(actual, expected, message)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function expectTruthy(actual: any, message: string)
    if not actual then
        error(message)
    end
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

local function randomSequence(sequence)
    local index = 0
    return function()
        index += 1
        return sequence[index] or 0
    end
end

runCase('chest cannot be opened before cooldown finishes', function()
    local result = LuckyChestLogic.applyChestSpin({
        nextLuckyChestOpenAt = 100,
        scoreBoostExpiresAt = 0,
        unlockedHats = {},
        unlockedPets = {},
        unlockedVehicleMounts = {},
    }, 0, 0, 99, 300, 60, randomSequence({ 0 }))

    expectEqual(result, nil, 'spin should be blocked while chest is on cooldown')
end)

runCase('score category awards score and updates cooldown', function()
    local result = LuckyChestLogic.applyChestSpin({
        nextLuckyChestOpenAt = 0,
        scoreBoostExpiresAt = 0,
        unlockedHats = {},
        unlockedPets = {},
        unlockedVehicleMounts = {},
    }, 100, 1, 1000, 300, 60, randomSequence({ 0, 0 }))

    expectTruthy(result, 'spin should produce a result when chest is ready')
    expectEqual(result.score, 2600, 'score prize should be applied to player score')
    expectEqual(result.profileData.nextLuckyChestOpenAt, 1300, 'cooldown should be set')
end)

runCase('pet category unlocks pet inventory entry', function()
    local result = LuckyChestLogic.applyChestSpin({
        nextLuckyChestOpenAt = 0,
        scoreBoostExpiresAt = 0,
        unlockedHats = {},
        unlockedPets = {},
        unlockedVehicleMounts = {},
    }, 0, 0, 100, 300, 60, randomSequence({ 0.85, 0 }))

    expectTruthy(result, 'spin should produce a result')
    expectEqual(result.spinResult.category, 'pet', 'expected to land in pet category')
    expectEqual(result.profileData.unlockedPets[1], 'pet_sprout_cube', 'pet id should be unlocked')
end)

runCase('score boost category updates boost expiration', function()
    local result = LuckyChestLogic.applyChestSpin({
        nextLuckyChestOpenAt = 0,
        scoreBoostExpiresAt = 0,
        unlockedHats = {},
        unlockedPets = {},
        unlockedVehicleMounts = {},
    }, 0, 0, 100, 300, 60, randomSequence({ 0.9, 0 }))

    expectTruthy(result, 'spin should produce a result')
    expectEqual(
        result.spinResult.category,
        'scoreBoost',
        'expected to land in score boost category'
    )
    expectEqual(result.profileData.scoreBoostExpiresAt, 160, 'boost expiration should be set')
    expectEqual(
        LuckyChestLogic.getActiveScoreBoostMultiplier(result.profileData, 120, 10),
        10,
        'boost should be active before expiration'
    )
    expectEqual(
        LuckyChestLogic.getActiveScoreBoostMultiplier(result.profileData, 160, 10),
        1,
        'boost should expire at target timestamp'
    )
end)

runCase('custom admin hat rewards are included in chest spins', function()
    local result = LuckyChestLogic.applyChestSpin(
        {
            nextLuckyChestOpenAt = 0,
            scoreBoostExpiresAt = 0,
            unlockedHats = {},
            unlockedPets = {},
            unlockedVehicleMounts = {},
        },
        0,
        0,
        100,
        300,
        60,
        randomSequence({ 0.7, 0.99 }),
        {
            {
                id = 'admin_hat_999',
                displayName = 'Admin Top Hat',
                rarity = 'gold',
                assetId = 999,
                sourceUrl = 'https://www.roblox.com/catalog/999/Admin-Top-Hat',
                rewardKind = 'hat',
            },
        }
    )

    expectTruthy(result, 'spin should produce a result')
    expectEqual(result.spinResult.category, 'hat', 'expected hat category')
    expectEqual(result.spinResult.item.id, 'admin_hat_999', 'expected custom reward id')
    expectEqual(result.profileData.unlockedHats[1], 'admin_hat_999', 'expected unlocked custom hat')
end)
