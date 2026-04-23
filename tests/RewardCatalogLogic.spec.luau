local RewardCatalogLogic = require('../src/Shared/RewardCatalogLogic')

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

runCase('parse raw numeric asset id', function()
    expectEqual(RewardCatalogLogic.parseAssetId('754810830'), 754810830, 'expected raw id parsing')
end)

runCase('parse create.roblox.com asset url', function()
    expectEqual(
        RewardCatalogLogic.parseAssetId(
            'https://create.roblox.com/store/asset/754810830/Classic-Banded-Top-Hat'
        ),
        754810830,
        'expected create.roblox.com parsing'
    )
end)

runCase('parse roblox library url', function()
    expectEqual(
        RewardCatalogLogic.parseAssetId(
            'https://www.roblox.com/library/754810830/Classic-Banded-Top-Hat'
        ),
        754810830,
        'expected library url parsing'
    )
end)

runCase('parse roblox catalog url', function()
    expectEqual(
        RewardCatalogLogic.parseAssetId('https://www.roblox.com/catalog/754810830/Some-Asset'),
        754810830,
        'expected catalog url parsing'
    )
end)

runCase('reject invalid asset text', function()
    expectEqual(RewardCatalogLogic.parseAssetId('not-an-asset'), nil, 'invalid text should fail')
end)

runCase('normalize kind and rarity', function()
    expectEqual(RewardCatalogLogic.normalizeKind('Vehicle Mount'), 'vehicleMount', 'normalize kind')
    expectEqual(RewardCatalogLogic.normalizeRarity('Purple'), 'purple', 'normalize rarity')
end)

runCase('reject overlong display name', function()
    local longName = string.rep('a', RewardCatalogLogic.getMaxDisplayNameLength() + 1)
    expectEqual(
        RewardCatalogLogic.normalizeDisplayName(longName),
        nil,
        'overlong name should be rejected'
    )
end)

runCase('merge duplicate reward by kind + asset', function()
    local ok, _, normalized = RewardCatalogLogic.normalizeSubmission({
        kind = 'hat',
        displayName = 'My Hat',
        rarity = 'green',
        assetText = '123456',
    })
    expectTruthy(ok and normalized, 'submission should normalize')

    local upsertOk1, _, firstRewards = RewardCatalogLogic.upsertReward({}, normalized, 100, 1, 100)
    expectTruthy(upsertOk1 and firstRewards, 'initial upsert should pass')
    expectEqual(#firstRewards, 1, 'catalog should contain one reward after initial insert')

    local ok2, _, normalized2 = RewardCatalogLogic.normalizeSubmission({
        kind = 'hat',
        displayName = 'My Better Hat',
        rarity = 'gold',
        assetText = '123456',
    })
    expectTruthy(ok2 and normalized2, 'second submission should normalize')

    local upsertOk2, _, mergedRewards =
        RewardCatalogLogic.upsertReward(firstRewards, normalized2, 120, 2, 100)
    expectTruthy(upsertOk2 and mergedRewards, 'duplicate upsert should merge')
    expectEqual(#mergedRewards, 1, 'duplicate should update existing item instead of adding one')
    expectEqual(mergedRewards[1].displayName, 'My Better Hat', 'display name should update')
    expectEqual(mergedRewards[1].rarity, 'gold', 'rarity should update')
end)
