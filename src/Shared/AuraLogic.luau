export type AuraConfig = {
    primaryHue: number,
    secondaryHue: number,
    primarySaturation: number,
    secondarySaturation: number,
    primaryValue: number,
    secondaryValue: number,
    rate: number,
    lifetimeMin: number,
    lifetimeMax: number,
    speedMin: number,
    speedMax: number,
    sizeStart: number,
    sizeEnd: number,
    spread: number,
    lightEmission: number,
    lightBrightness: number,
    lightRange: number,
    hasSecondaryBurst: boolean,
    secondaryRate: number,
}

local AuraLogic = {}

local function clamp(value: number, minValue: number, maxValue: number): number
    return math.max(minValue, math.min(value, maxValue))
end

local function lerp(minValue: number, maxValue: number, alpha: number): number
    return minValue + ((maxValue - minValue) * alpha)
end

function AuraLogic.getAuraConfig(rankIndex: number, maxRankCount: number): AuraConfig
    local maxRanks = math.max(math.floor(maxRankCount), 1)
    local clampedRankIndex = clamp(math.floor(rankIndex), 1, maxRanks)
    local alpha = if maxRanks == 1 then 1 else (clampedRankIndex - 1) / (maxRanks - 1)
    local hue = (clampedRankIndex - 1) / maxRanks

    return {
        primaryHue = hue,
        secondaryHue = (hue + 0.12) % 1,
        primarySaturation = 0.78,
        secondarySaturation = 0.62,
        primaryValue = 1,
        secondaryValue = 1,
        rate = lerp(12, 88, alpha),
        lifetimeMin = lerp(0.5, 1.2, alpha),
        lifetimeMax = lerp(1.1, 2.2, alpha),
        speedMin = lerp(1, 4, alpha),
        speedMax = lerp(3, 12, alpha),
        sizeStart = lerp(0.45, 1.2, alpha),
        sizeEnd = lerp(0.08, 0.28, alpha),
        spread = lerp(10, 42, alpha),
        lightEmission = lerp(0.3, 0.95, alpha),
        lightBrightness = lerp(0.8, 3.8, alpha),
        lightRange = lerp(6, 16, alpha),
        hasSecondaryBurst = alpha >= 0.25,
        secondaryRate = lerp(0, 26, alpha),
    }
end

return AuraLogic
