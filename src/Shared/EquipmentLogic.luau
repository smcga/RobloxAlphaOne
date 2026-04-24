export type RewardKind = 'hat' | 'vehicleMount'
export type RewardRarity = 'green' | 'blue' | 'purple' | 'orange' | 'gold'

export type RewardDescriptor = {
    id: string,
    kind: RewardKind,
    displayName: string,
    rarity: RewardRarity,
    assetId: number?,
    sourceUrl: string?,
}

export type EquipmentStatePayload = {
    unlockedHats: { string },
    unlockedVehicleMounts: { string },
    equippedHatId: string?,
    equippedVehicleMountId: string?,
    availableHats: { RewardDescriptor },
    availableVehicleMounts: { RewardDescriptor },
}

local EquipmentLogic = {}

local function cloneStringArray(values: { string }): { string }
    local cloned = {}
    for index, value in ipairs(values) do
        cloned[index] = value
    end
    return cloned
end

local function isRewardIdUnlocked(unlockedIds: { string }, rewardId: string): boolean
    for _, unlockedId in ipairs(unlockedIds) do
        if unlockedId == rewardId then
            return true
        end
    end

    return false
end

local function rewardDescriptorFromItem(categoryId: string, item): RewardDescriptor?
    local kind: RewardKind? = nil
    if categoryId == 'hat' then
        kind = 'hat'
    elseif categoryId == 'vehicleMount' then
        kind = 'vehicleMount'
    end

    if not kind then
        return nil
    end

    return {
        id = item.id,
        kind = kind,
        displayName = item.displayName,
        rarity = item.rarity,
        assetId = item.assetId,
        sourceUrl = item.sourceUrl,
    }
end

function EquipmentLogic.buildRewardLookup(categoryConfigs: { any }): { [string]: RewardDescriptor }
    local lookup: { [string]: RewardDescriptor } = {}

    for _, category in ipairs(categoryConfigs) do
        for _, item in ipairs(category.items) do
            local descriptor = rewardDescriptorFromItem(category.id, item)
            if descriptor then
                lookup[item.id] = descriptor
            end
        end
    end

    return lookup
end

function EquipmentLogic.buildAvailableRewards(
    unlockedIds: { string },
    kind: RewardKind,
    rewardLookup: { [string]: RewardDescriptor }
): { RewardDescriptor }
    local availableRewards = {}

    for _, unlockedId in ipairs(unlockedIds) do
        local descriptor = rewardLookup[unlockedId]
        if descriptor and descriptor.kind == kind then
            availableRewards[#availableRewards + 1] = descriptor
        end
    end

    return availableRewards
end

function EquipmentLogic.resolveEquipReward(
    rewardId: any,
    expectedKind: RewardKind,
    unlockedIds: { string },
    rewardLookup: { [string]: RewardDescriptor }
): (boolean, string, RewardDescriptor?)
    if typeof(rewardId) ~= 'string' or rewardId == '' then
        return false, 'Invalid reward id.', nil
    end

    if not isRewardIdUnlocked(unlockedIds, rewardId) then
        return false, 'You have not unlocked that reward.', nil
    end

    local reward = rewardLookup[rewardId]
    if not reward then
        return false, 'That reward no longer exists in the reward catalog.', nil
    end

    if reward.kind ~= expectedKind then
        return false, 'That reward type does not match this equipment slot.', nil
    end

    return true, 'ok', reward
end

function EquipmentLogic.normalizeEquippedId(
    equippedId: any,
    kind: RewardKind,
    unlockedIds: { string },
    rewardLookup: { [string]: RewardDescriptor }
): string?
    if typeof(equippedId) ~= 'string' or equippedId == '' then
        return nil
    end

    if not isRewardIdUnlocked(unlockedIds, equippedId) then
        return nil
    end

    local reward = rewardLookup[equippedId]
    if not reward then
        return nil
    end

    if reward.kind ~= kind then
        return nil
    end

    return equippedId
end

function EquipmentLogic.buildEquipmentStatePayload(
    profileData,
    rewardLookup: { [string]: RewardDescriptor }
): EquipmentStatePayload
    local unlockedHats = cloneStringArray(profileData.unlockedHats)
    local unlockedVehicleMounts = cloneStringArray(profileData.unlockedVehicleMounts)
    local equippedHatId = EquipmentLogic.normalizeEquippedId(
        profileData.equippedHatId,
        'hat',
        unlockedHats,
        rewardLookup
    )
    local equippedVehicleMountId = EquipmentLogic.normalizeEquippedId(
        profileData.equippedVehicleMountId,
        'vehicleMount',
        unlockedVehicleMounts,
        rewardLookup
    )

    return {
        unlockedHats = unlockedHats,
        unlockedVehicleMounts = unlockedVehicleMounts,
        equippedHatId = equippedHatId,
        equippedVehicleMountId = equippedVehicleMountId,
        availableHats = EquipmentLogic.buildAvailableRewards(unlockedHats, 'hat', rewardLookup),
        availableVehicleMounts = EquipmentLogic.buildAvailableRewards(
            unlockedVehicleMounts,
            'vehicleMount',
            rewardLookup
        ),
    }
end

return EquipmentLogic
