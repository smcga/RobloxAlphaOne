local ProgressionBalance = require('./ProgressionBalance')

export type ProfileData = {
    score: number,
    rebirths: number,
    highestScoreAchieved: number,
    highestRankAchieved: number,
    highestAgeAchieved: number,
    nextLuckyChestOpenAt: number,
    scoreBoostExpiresAt: number,
    unlockedHats: { string },
    unlockedPets: { string },
    unlockedVehicleMounts: { string },
}

local ProfileDataLogic = {}

local PLACEHOLDER_RANK_NAMES = table.create(ProgressionBalance.TOTAL_RANKS)
for rankIndex = 1, ProgressionBalance.TOTAL_RANKS do
    PLACEHOLDER_RANK_NAMES[rankIndex] = string.format('Rank %d', rankIndex)
end

local RANK_CONFIGS, AGE_CONFIGS = ProgressionBalance.build(PLACEHOLDER_RANK_NAMES)

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
            highestScoreAchieved = 0,
            highestRankAchieved = 1,
            highestAgeAchieved = 1,
            nextLuckyChestOpenAt = 0,
            scoreBoostExpiresAt = 0,
            unlockedHats = {},
            unlockedPets = {},
            unlockedVehicleMounts = {},
        }
    end

    local score = sanitizeWholeNumber(rawData.score)
    local derivedHighestRank = ProgressionBalance.getRankIndexForScore(score, RANK_CONFIGS)
    local derivedHighestAge = ProgressionBalance.getHighestUnlockedAgeIndex(score, AGE_CONFIGS)

    return {
        score = score,
        rebirths = sanitizeWholeNumber(rawData.rebirths),
        highestScoreAchieved = math.max(sanitizeWholeNumber(rawData.highestScoreAchieved), score),
        highestRankAchieved = math.max(
            sanitizeWholeNumber(rawData.highestRankAchieved),
            derivedHighestRank
        ),
        highestAgeAchieved = math.max(
            sanitizeWholeNumber(rawData.highestAgeAchieved),
            derivedHighestAge
        ),
        nextLuckyChestOpenAt = sanitizeWholeNumber(rawData.nextLuckyChestOpenAt),
        scoreBoostExpiresAt = sanitizeWholeNumber(rawData.scoreBoostExpiresAt),
        unlockedHats = sanitizeStringArray(rawData.unlockedHats),
        unlockedPets = sanitizeStringArray(rawData.unlockedPets),
        unlockedVehicleMounts = sanitizeStringArray(rawData.unlockedVehicleMounts),
    }
end

function ProfileDataLogic.toStoredValue(profileData: ProfileData): { [string]: any }
    local score = sanitizeWholeNumber(profileData.score)
    local derivedHighestRank = ProgressionBalance.getRankIndexForScore(score, RANK_CONFIGS)
    local derivedHighestAge = ProgressionBalance.getHighestUnlockedAgeIndex(score, AGE_CONFIGS)

    return {
        score = score,
        rebirths = sanitizeWholeNumber(profileData.rebirths),
        highestScoreAchieved = math.max(
            sanitizeWholeNumber(profileData.highestScoreAchieved),
            score
        ),
        highestRankAchieved = math.max(
            sanitizeWholeNumber(profileData.highestRankAchieved),
            derivedHighestRank
        ),
        highestAgeAchieved = math.max(
            sanitizeWholeNumber(profileData.highestAgeAchieved),
            derivedHighestAge
        ),
        nextLuckyChestOpenAt = sanitizeWholeNumber(profileData.nextLuckyChestOpenAt),
        scoreBoostExpiresAt = sanitizeWholeNumber(profileData.scoreBoostExpiresAt),
        unlockedHats = sanitizeStringArray(profileData.unlockedHats),
        unlockedPets = sanitizeStringArray(profileData.unlockedPets),
        unlockedVehicleMounts = sanitizeStringArray(profileData.unlockedVehicleMounts),
    }
end

return ProfileDataLogic
