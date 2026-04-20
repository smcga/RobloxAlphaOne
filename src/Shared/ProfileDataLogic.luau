export type ProfileData = {
    score: number,
    rebirths: number,
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

function ProfileDataLogic.normalize(rawData: any): ProfileData
    if type(rawData) ~= 'table' then
        return {
            score = 0,
            rebirths = 0,
        }
    end

    return {
        score = sanitizeWholeNumber(rawData.score),
        rebirths = sanitizeWholeNumber(rawData.rebirths),
    }
end

function ProfileDataLogic.toStoredValue(profileData: ProfileData): { [string]: number }
    return {
        score = sanitizeWholeNumber(profileData.score),
        rebirths = sanitizeWholeNumber(profileData.rebirths),
    }
end

return ProfileDataLogic
