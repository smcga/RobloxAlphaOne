local RewardCatalogLogic = {}

export type RewardKind = 'hat' | 'vehicleMount'
export type RewardRarity = 'green' | 'blue' | 'purple' | 'orange' | 'gold'

export type AdminReward = {
    id: string,
    kind: RewardKind,
    displayName: string,
    rarity: RewardRarity,
    assetId: number,
    sourceUrl: string?,
    createdAt: number,
    createdByUserId: number,
}

export type NormalizedRewardSubmission = {
    kind: RewardKind,
    displayName: string,
    rarity: RewardRarity,
    assetId: number,
    sourceUrl: string?,
}

local ALLOWED_RARITIES: { [string]: RewardRarity } = {
    green = 'green',
    blue = 'blue',
    purple = 'purple',
    orange = 'orange',
    gold = 'gold',
}

local MAX_DISPLAY_NAME_LENGTH = 60

local function trim(value: string): string
    return value:match('^%s*(.-)%s*$') or ''
end

function RewardCatalogLogic.getMaxDisplayNameLength(): number
    return MAX_DISPLAY_NAME_LENGTH
end

function RewardCatalogLogic.normalizeKind(rawKind: any): RewardKind?
    if typeof(rawKind) ~= 'string' then
        return nil
    end

    local normalized = string.lower(trim(rawKind))
    if normalized == 'hat' then
        return 'hat'
    end
    if normalized == 'vehiclemount' or normalized == 'vehicle_mount' then
        return 'vehicleMount'
    end
    if normalized == 'vehiclemounts' or normalized == 'vehicle_mounts' then
        return 'vehicleMount'
    end
    if normalized == 'vehicle mount' then
        return 'vehicleMount'
    end

    return nil
end

function RewardCatalogLogic.normalizeRarity(rawRarity: any): RewardRarity?
    if typeof(rawRarity) ~= 'string' then
        return nil
    end

    local normalized = string.lower(trim(rawRarity))
    return ALLOWED_RARITIES[normalized]
end

function RewardCatalogLogic.parseAssetId(rawAssetText: any): number?
    if typeof(rawAssetText) ~= 'string' then
        return nil
    end

    local input = trim(rawAssetText)
    if input == '' then
        return nil
    end

    local rawDigits = input:match('^(%d+)$')
    if rawDigits then
        local parsedRaw = tonumber(rawDigits)
        if parsedRaw and parsedRaw > 0 then
            return math.floor(parsedRaw)
        end
    end

    local createStoreId = input:match('^https?://create%.roblox%.com/store/asset/(%d+)')
    if createStoreId then
        return tonumber(createStoreId)
    end

    local libraryId = input:match('^https?://www%.roblox%.com/library/(%d+)')
    if libraryId then
        return tonumber(libraryId)
    end

    local catalogId = input:match('^https?://www%.roblox%.com/catalog/(%d+)')
    if catalogId then
        return tonumber(catalogId)
    end

    return nil
end

function RewardCatalogLogic.normalizeDisplayName(rawDisplayName: any): string?
    if typeof(rawDisplayName) ~= 'string' then
        return nil
    end

    local normalized = trim(rawDisplayName)
    if normalized == '' then
        return nil
    end

    if string.len(normalized) > MAX_DISPLAY_NAME_LENGTH then
        return nil
    end

    return normalized
end

function RewardCatalogLogic.buildRewardId(kind: RewardKind, assetId: number): string
    local kindToken = kind == 'vehicleMount' and 'vehicle_mount' or 'hat'
    return string.format('admin_%s_%s', kindToken, tostring(assetId))
end

function RewardCatalogLogic.normalizeSubmission(
    payload: any
): (boolean, string, NormalizedRewardSubmission?)
    if typeof(payload) ~= 'table' then
        return false, 'Invalid payload.', nil
    end

    local kind = RewardCatalogLogic.normalizeKind(payload.kind)
    if not kind then
        return false, 'Reward type must be Hat or Vehicle Mount.', nil
    end

    local displayName = RewardCatalogLogic.normalizeDisplayName(payload.displayName)
    if not displayName then
        return false, 'Display name is required and must be short.', nil
    end

    local rarity = RewardCatalogLogic.normalizeRarity(payload.rarity)
    if not rarity then
        return false, 'Rarity must be one of green/blue/purple/orange/gold.', nil
    end

    local assetId = RewardCatalogLogic.parseAssetId(payload.assetText)
    if not assetId then
        return false, 'Asset link or ID is invalid.', nil
    end

    local sourceUrl: string? = nil
    if typeof(payload.assetText) == 'string' then
        local trimmed = trim(payload.assetText)
        if trimmed ~= '' and string.match(trimmed, '^https?://') then
            sourceUrl = trimmed
        end
    end

    return true,
        'ok',
        {
            kind = kind,
            displayName = displayName,
            rarity = rarity,
            assetId = assetId,
            sourceUrl = sourceUrl,
        }
end

function RewardCatalogLogic.upsertReward(
    existingRewards: { AdminReward },
    normalizedSubmission: NormalizedRewardSubmission,
    nowUnixSeconds: number,
    createdByUserId: number,
    maxRewards: number
): (boolean, string, { AdminReward }?, AdminReward?)
    local nextRewards = table.clone(existingRewards)
    local rewardId =
        RewardCatalogLogic.buildRewardId(normalizedSubmission.kind, normalizedSubmission.assetId)
    local updatedReward: AdminReward? = nil
    local existingIndex: number? = nil

    for index, reward in ipairs(nextRewards) do
        if reward.id == rewardId then
            existingIndex = index
            break
        end
    end

    if existingIndex then
        local existingReward = nextRewards[existingIndex]
        updatedReward = {
            id = rewardId,
            kind = normalizedSubmission.kind,
            displayName = normalizedSubmission.displayName,
            rarity = normalizedSubmission.rarity,
            assetId = normalizedSubmission.assetId,
            sourceUrl = normalizedSubmission.sourceUrl,
            createdAt = existingReward.createdAt,
            createdByUserId = existingReward.createdByUserId,
        }
        nextRewards[existingIndex] = updatedReward
    else
        if #nextRewards >= maxRewards then
            return false,
                string.format('Catalog is full (max %s rewards).', tostring(maxRewards)),
                nil,
                nil
        end

        updatedReward = {
            id = rewardId,
            kind = normalizedSubmission.kind,
            displayName = normalizedSubmission.displayName,
            rarity = normalizedSubmission.rarity,
            assetId = normalizedSubmission.assetId,
            sourceUrl = normalizedSubmission.sourceUrl,
            createdAt = nowUnixSeconds,
            createdByUserId = createdByUserId,
        }
        table.insert(nextRewards, updatedReward)
    end

    return true, 'ok', nextRewards, updatedReward
end

function RewardCatalogLogic.toLuckyChestRewardItem(reward: AdminReward)
    return {
        id = reward.id,
        displayName = reward.displayName,
        rarity = reward.rarity,
        assetId = reward.assetId,
        sourceUrl = reward.sourceUrl,
        rewardKind = reward.kind,
    }
end

return RewardCatalogLogic
