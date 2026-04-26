export type HourlyFinalZoneBonusConfig = {
    chancePerHour: number,
    activeWindowSeconds: number,
    bonusRebirths: number,
}

export type RebirthConfig = {
    baseRequirementScore: number,
    requirementGrowthPerRebirth: number,
    scoreToBonusPower: number,
    scoreToBonusScale: number,
    maxBonusRebirthsFromScore: number,
    hourlyFinalZoneBonus: HourlyFinalZoneBonusConfig,
}

local RebirthLogic = {}
local LINEAR_GRANT_STEPS = 5
local DIMINISHING_GRANT_POWER = 0.6

local function clamp(value: number, minValue: number, maxValue: number): number
    return math.max(minValue, math.min(maxValue, value))
end

function RebirthLogic.getRequiredScore(rebirths: number, config: RebirthConfig): number
    local sanitizedRebirths = math.max(math.floor(rebirths), 0)
    local rawRequirement = config.baseRequirementScore
        + (sanitizedRebirths * config.requirementGrowthPerRebirth)
    return math.max(1, math.floor(rawRequirement))
end

function RebirthLogic.isHourlyFinalZoneBonusActive(
    unixTimeSeconds: number,
    config: HourlyFinalZoneBonusConfig
): boolean
    local chance = clamp(config.chancePerHour, 0, 1)
    if chance <= 0 then
        return false
    end

    local windowSeconds = math.max(math.floor(config.activeWindowSeconds), 0)
    if windowSeconds <= 0 then
        return false
    end

    local hourIndex = math.floor(unixTimeSeconds / 3600)
    local seed = (hourIndex * 1103515245 + 12345) % 2 ^ 31
    local roll = (seed % 10_000) / 10_000
    if roll > chance then
        return false
    end

    local secondOfHour = unixTimeSeconds % 3600
    return secondOfHour < windowSeconds
end

function RebirthLogic.getPreviewGrant(
    score: number,
    rebirths: number,
    isInsideFinalAgeZone: boolean,
    unixTimeSeconds: number,
    config: RebirthConfig
): number
    local requirement = RebirthLogic.getRequiredScore(rebirths, config)
    local clampedScore = math.max(score, 0)
    if clampedScore < requirement then
        return 0
    end

    local steps = clampedScore / requirement
    local grant = math.floor(steps)
    if steps > LINEAR_GRANT_STEPS then
        grant = LINEAR_GRANT_STEPS
            + math.floor((steps - LINEAR_GRANT_STEPS) ^ DIMINISHING_GRANT_POWER)
    end
    if
        isInsideFinalAgeZone
        and RebirthLogic.isHourlyFinalZoneBonusActive(unixTimeSeconds, config.hourlyFinalZoneBonus)
    then
        grant += math.max(0, math.floor(config.hourlyFinalZoneBonus.bonusRebirths))
    end

    return grant
end

return RebirthLogic
