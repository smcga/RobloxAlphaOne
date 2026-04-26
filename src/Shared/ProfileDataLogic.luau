local ProgressionBalance = require('./ProgressionBalance')
local RankCelebrationLogic = require('./RankCelebrationLogic')

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
    equippedHatId: string?,
    equippedVehicleMountId: string?,
    rankReachCounts: { number },
    globallyCountedRankIndices: { number },
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
            highestScoreAchieved = 0,
            highestRankAchieved = 1,
            highestAgeAchieved = 1,
            nextLuckyChestOpenAt = 0,
            scoreBoostExpiresAt = 0,
            unlockedHats = {},
            unlockedPets = {},
            unlockedVehicleMounts = {},
            equippedHatId = nil,
            equippedVehicleMountId = nil,
            rankReachCounts = RankCelebrationLogic.sanitizeRankReachCounts(
                nil,
                ProgressionBalance.TOTAL_RANKS
            ),
            globallyCountedRankIndices = {},
        }
    end

    local unlockedHats = sanitizeStringArray(rawData.unlockedHats)
    local unlockedVehicleMounts = sanitizeStringArray(rawData.unlockedVehicleMounts)
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
        unlockedHats = unlockedHats,
        unlockedPets = sanitizeStringArray(rawData.unlockedPets),
        unlockedVehicleMounts = unlockedVehicleMounts,
        equippedHatId = sanitizeOptionalOwnedId(rawData.equippedHatId, unlockedHats),
        equippedVehicleMountId = sanitizeOptionalOwnedId(
            rawData.equippedVehicleMountId,
            unlockedVehicleMounts
        ),
        rankReachCounts = RankCelebrationLogic.sanitizeRankReachCounts(
            rawData.rankReachCounts,
            ProgressionBalance.TOTAL_RANKS
        ),
        globallyCountedRankIndices = RankCelebrationLogic.sanitizeRankIndexArray(
            rawData.globallyCountedRankIndices,
            ProgressionBalance.TOTAL_RANKS
        ),
    }
end

function ProfileDataLogic.toStoredValue(profileData: ProfileData): { [string]: any }
    local unlockedHats = sanitizeStringArray(profileData.unlockedHats)
    local unlockedVehicleMounts = sanitizeStringArray(profileData.unlockedVehicleMounts)
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
        unlockedHats = unlockedHats,
        unlockedPets = sanitizeStringArray(profileData.unlockedPets),
        unlockedVehicleMounts = unlockedVehicleMounts,
        equippedHatId = sanitizeOptionalOwnedId(profileData.equippedHatId, unlockedHats),
        equippedVehicleMountId = sanitizeOptionalOwnedId(
            profileData.equippedVehicleMountId,
            unlockedVehicleMounts
        ),
        rankReachCounts = RankCelebrationLogic.sanitizeRankReachCounts(
            profileData.rankReachCounts,
            ProgressionBalance.TOTAL_RANKS
        ),
        globallyCountedRankIndices = RankCelebrationLogic.sanitizeRankIndexArray(
            profileData.globallyCountedRankIndices,
            ProgressionBalance.TOTAL_RANKS
        ),
    }
end

return ProfileDataLogic
