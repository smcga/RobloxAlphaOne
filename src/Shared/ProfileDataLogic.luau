export type ProfileData = {
    score: number,
    rebirths: number,
    nextLuckyChestOpenAt: number,
    scoreBoostExpiresAt: number,
    unlockedHats: { string },
    unlockedPets: { string },
    unlockedVehicleMounts: { string },
    equippedHatId: string?,
    equippedVehicleMountId: string?,
}

local ProfileDataLogic = {}

local function sanitizeWholeNumber(value: any): number
    if type(value) ~= 'number' then
        return 0
    end

    if value ~= value then
        return 0
    end

    if value == math.huge or value == -math.huge then
        return 0
    end

    return math.max(math.floor(value), 0)
end

local function sanitizeStringArray(value: any): { string }
    if type(value) ~= 'table' then
        return {}
    end

    local sanitized = {}
    local seen: { [string]: boolean } = {}

    for _, item in ipairs(value) do
        if type(item) == 'string' and not seen[item] then
            seen[item] = true
            sanitized[#sanitized + 1] = item
        end
    end

    return sanitized
end

local function sanitizeOptionalOwnedId(value: any, ownedIds: { string }): string?
    if type(value) ~= 'string' or value == '' then
        return nil
    end

    for _, ownedId in ipairs(ownedIds) do
        if ownedId == value then
            return value
        end
    end

    return nil
end

function ProfileDataLogic.normalize(rawData: any): ProfileData
    if type(rawData) ~= 'table' then
        return {
            score = 0,
            rebirths = 0,
            nextLuckyChestOpenAt = 0,
            scoreBoostExpiresAt = 0,
            unlockedHats = {},
            unlockedPets = {},
            unlockedVehicleMounts = {},
            equippedHatId = nil,
            equippedVehicleMountId = nil,
        }
    end

    local unlockedHats = sanitizeStringArray(rawData.unlockedHats)
    local unlockedVehicleMounts = sanitizeStringArray(rawData.unlockedVehicleMounts)

    return {
        score = sanitizeWholeNumber(rawData.score),
        rebirths = sanitizeWholeNumber(rawData.rebirths),
        nextLuckyChestOpenAt = sanitizeWholeNumber(rawData.nextLuckyChestOpenAt),
        scoreBoostExpiresAt = sanitizeWholeNumber(rawData.scoreBoostExpiresAt),
        unlockedHats = unlockedHats,
        unlockedPets = sanitizeStringArray(rawData.unlockedPets),
        unlockedVehicleMounts = unlockedVehicleMounts,
        equippedHatId = sanitizeOptionalOwnedId(rawData.equippedHatId, unlockedHats),
        equippedVehicleMountId = sanitizeOptionalOwnedId(
            rawData.equippedVehicleMountId,
            unlockedVehicleMounts
        ),
    }
end

function ProfileDataLogic.toStoredValue(profileData: ProfileData): { [string]: any }
    local unlockedHats = sanitizeStringArray(profileData.unlockedHats)
    local unlockedVehicleMounts = sanitizeStringArray(profileData.unlockedVehicleMounts)

    return {
        score = sanitizeWholeNumber(profileData.score),
        rebirths = sanitizeWholeNumber(profileData.rebirths),
        nextLuckyChestOpenAt = sanitizeWholeNumber(profileData.nextLuckyChestOpenAt),
        scoreBoostExpiresAt = sanitizeWholeNumber(profileData.scoreBoostExpiresAt),
        unlockedHats = unlockedHats,
        unlockedPets = sanitizeStringArray(profileData.unlockedPets),
        unlockedVehicleMounts = unlockedVehicleMounts,
        equippedHatId = sanitizeOptionalOwnedId(profileData.equippedHatId, unlockedHats),
        equippedVehicleMountId = sanitizeOptionalOwnedId(
            profileData.equippedVehicleMountId,
            unlockedVehicleMounts
        ),
    }
end

return ProfileDataLogic
