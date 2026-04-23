export type AuraConfig = {
    rankIndex: number,
    intensityAlpha: number,
    scaleMultiplier: number,
    primaryHue: number,
    secondaryHue: number,
    accentHue: number,
    colorSaturation: number,
    colorValue: number,
    glowBrightness: number,
    glowRange: number,
    highlightFillTransparency: number,
    highlightOutlineTransparency: number,
    coreEmissionRate: number,
    sparkleEmissionRate: number,
    coreSizeBase: number,
    sparkleSizeBase: number,
    orbitRadius: number,
    orbitSpeed: number,
    burstCount: number,
}

local RankAuraLogic = {}

local GOLDEN_RATIO_CONJUGATE = 0.61803398875

local function clampRank(rankIndex: number, maxRanks: number): number
    return math.clamp(math.floor(rankIndex), 1, math.max(maxRanks, 1))
end

local function rankAlpha(rankIndex: number, maxRanks: number): number
    if maxRanks <= 1 then
        return 1
    end

    return (rankIndex - 1) / (maxRanks - 1)
end

function RankAuraLogic.getAuraForRank(rankIndex: number, maxRanks: number): AuraConfig
    local normalizedRank = clampRank(rankIndex, maxRanks)
    local intensityAlpha = rankAlpha(normalizedRank, maxRanks)

    local primaryHue = (normalizedRank * GOLDEN_RATIO_CONJUGATE) % 1
    local secondaryHue = (primaryHue + 0.17) % 1
    local accentHue = (primaryHue + 0.33) % 1

    local saturationBoost = 0.65 + (0.35 * intensityAlpha)
    local valueBoost = 0.9 + (0.1 * intensityAlpha)

    return {
        rankIndex = normalizedRank,
        intensityAlpha = intensityAlpha,
        scaleMultiplier = 1 + (intensityAlpha * 0.5),
        primaryHue = primaryHue,
        secondaryHue = secondaryHue,
        accentHue = accentHue,
        colorSaturation = saturationBoost,
        colorValue = valueBoost,
        glowBrightness = 2 + (intensityAlpha * 9),
        glowRange = 8 + (intensityAlpha * 24),
        highlightFillTransparency = 0.85 - (intensityAlpha * 0.45),
        highlightOutlineTransparency = 0.2 - (intensityAlpha * 0.15),
        coreEmissionRate = 6 + math.floor(intensityAlpha * 70),
        sparkleEmissionRate = 3 + math.floor(intensityAlpha * 120),
        coreSizeBase = 1 + (intensityAlpha * 2.5),
        sparkleSizeBase = 0.2 + (intensityAlpha * 0.8),
        orbitRadius = 1.2 + (intensityAlpha * 3.5),
        orbitSpeed = 30 + (intensityAlpha * 180),
        burstCount = 8 + math.floor(intensityAlpha * 120),
    }
end

return RankAuraLogic
