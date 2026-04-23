export type ProfileData = {
    score: number,
    rebirths: number,
    nextLuckyChestOpenAt: number,
    scoreBoostExpiresAt: number,
    unlockedHats: { string },
    unlockedPets: { string },
    unlockedVehicleMounts: { string },
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
        }
    end

    return {
        score = sanitizeWholeNumber(rawData.score),
        rebirths = sanitizeWholeNumber(rawData.rebirths),
        nextLuckyChestOpenAt = sanitizeWholeNumber(rawData.nextLuckyChestOpenAt),
        scoreBoostExpiresAt = sanitizeWholeNumber(rawData.scoreBoostExpiresAt),
        unlockedHats = sanitizeStringArray(rawData.unlockedHats),
        unlockedPets = sanitizeStringArray(rawData.unlockedPets),
        unlockedVehicleMounts = sanitizeStringArray(rawData.unlockedVehicleMounts),
    }
end

function ProfileDataLogic.toStoredValue(profileData: ProfileData): { [string]: any }
    return {
        score = sanitizeWholeNumber(profileData.score),
        rebirths = sanitizeWholeNumber(profileData.rebirths),
        nextLuckyChestOpenAt = sanitizeWholeNumber(profileData.nextLuckyChestOpenAt),
        scoreBoostExpiresAt = sanitizeWholeNumber(profileData.scoreBoostExpiresAt),
        unlockedHats = sanitizeStringArray(profileData.unlockedHats),
        unlockedPets = sanitizeStringArray(profileData.unlockedPets),
        unlockedVehicleMounts = sanitizeStringArray(profileData.unlockedVehicleMounts),
    }
end

return ProfileDataLogic
