export type AgeZoneConfig = {
    requiredScore: number,
}

local ScoreZoneVfxLogic = {}

function ScoreZoneVfxLogic.isInsideScoringZone(
    currentScore: number,
    isInsideAgeZones: { [number]: boolean },
    ageZoneConfigs: { AgeZoneConfig }
): boolean
    for index, zoneConfig in ipairs(ageZoneConfigs) do
        if isInsideAgeZones[index] and currentScore >= zoneConfig.requiredScore then
            return true
        end
    end

    return false
end

function ScoreZoneVfxLogic.getScoreBurstCount(
    previousScore: number,
    nextScore: number,
    isInsideScoringZone: boolean,
    maxBurstCount: number
): number
    if not isInsideScoringZone then
        return 0
    end

    local gained = math.max(0, math.floor(nextScore - previousScore))
    if gained <= 0 then
        return 0
    end

    return math.min(gained, math.max(1, maxBurstCount))
end

return ScoreZoneVfxLogic
