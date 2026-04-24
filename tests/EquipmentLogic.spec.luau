local LuckyChestLogic = require('../src/Shared/LuckyChestLogic')
local EquipmentLogic = require('../src/Shared/EquipmentLogic')

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

local customRewards = {
    {
        id = 'admin_hat_123',
        displayName = 'Admin Hat',
        rarity = 'orange',
        assetId = 123,
        rewardKind = 'hat',
    },
}

runCase('buildRewardLookup includes static + admin rewards', function()
    local lookup =
        EquipmentLogic.buildRewardLookup(LuckyChestLogic.getEffectiveCategoryConfigs(customRewards))
    expectTruthy(lookup.hat_copper_crown ~= nil, 'expected static hat in lookup')
    expectTruthy(lookup.mount_gear_skimmer ~= nil, 'expected static mount in lookup')
    expectEqual(lookup.admin_hat_123.kind, 'hat', 'expected admin hat kind')
end)

runCase('resolveEquipReward rejects unowned IDs', function()
    local lookup =
        EquipmentLogic.buildRewardLookup(LuckyChestLogic.getEffectiveCategoryConfigs(customRewards))
    local ok, message = EquipmentLogic.resolveEquipReward('admin_hat_123', 'hat', {}, lookup)

    expectEqual(ok, false, 'expected unowned reward to be rejected')
    expectEqual(message, 'You have not unlocked that reward.', 'expected ownership rejection')
end)

runCase('normalizeEquippedId clears stale equipped ids', function()
    local lookup =
        EquipmentLogic.buildRewardLookup(LuckyChestLogic.getEffectiveCategoryConfigs(customRewards))
    local normalized =
        EquipmentLogic.normalizeEquippedId('admin_hat_123', 'hat', { 'hat_copper_crown' }, lookup)

    expectEqual(normalized, nil, 'stale equipped id should be cleared')
end)

runCase('buildEquipmentStatePayload includes only unlocked entries', function()
    local lookup =
        EquipmentLogic.buildRewardLookup(LuckyChestLogic.getEffectiveCategoryConfigs(customRewards))
    local payload = EquipmentLogic.buildEquipmentStatePayload({
        unlockedHats = { 'hat_copper_crown', 'admin_hat_123' },
        unlockedVehicleMounts = { 'mount_gear_skimmer' },
        equippedHatId = 'admin_hat_123',
        equippedVehicleMountId = 'mount_gear_skimmer',
    }, lookup)

    expectEqual(#payload.availableHats, 2, 'expected two hat entries')
    expectEqual(#payload.availableVehicleMounts, 1, 'expected one mount entry')
    expectEqual(payload.equippedHatId, 'admin_hat_123', 'hat equip should persist')
    expectEqual(payload.equippedVehicleMountId, 'mount_gear_skimmer', 'mount equip should persist')
end)
