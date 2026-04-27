export type AgeZoneUnlockConfig = {
    displayName: string,
    requiredScore: number,
}

local ZoneUnlockUiLogic = {}

function ZoneUnlockUiLogic.isZoneUnlocked(score: number, requiredScore: number): boolean
    return score >= requiredScore
end

function ZoneUnlockUiLogic.getNextUnlock(
    score: number,
    ageZoneConfigs: { AgeZoneUnlockConfig }
): AgeZoneUnlockConfig?
    for _, zoneConfig in ipairs(ageZoneConfigs) do
        if not ZoneUnlockUiLogic.isZoneUnlocked(score, zoneConfig.requiredScore) then
            return zoneConfig
        end
    end

    return nil
end

function ZoneUnlockUiLogic.getCurrentAge(
    score: number,
    ageZoneConfigs: { AgeZoneUnlockConfig }
): AgeZoneUnlockConfig?
    local currentAge: AgeZoneUnlockConfig? = nil

    for _, zoneConfig in ipairs(ageZoneConfigs) do
        if ZoneUnlockUiLogic.isZoneUnlocked(score, zoneConfig.requiredScore) then
            currentAge = zoneConfig
        else
            break
        end
    end

    return currentAge
end

function ZoneUnlockUiLogic.buildCurrentAgeText(
    score: number,
    ageZoneConfigs: { AgeZoneUnlockConfig }
): string
    local currentAge = ZoneUnlockUiLogic.getCurrentAge(score, ageZoneConfigs)
    if currentAge then
        return string.format('Current Age: %s', currentAge.displayName)
    end

    return 'Current Age: Unknown'
end

function ZoneUnlockUiLogic.buildNextUnlockText(
    score: number,
    ageZoneConfigs: { AgeZoneUnlockConfig },
    formatCompact: (number) -> string
): string
    local nextUnlock = ZoneUnlockUiLogic.getNextUnlock(score, ageZoneConfigs)

    if not nextUnlock then
        return 'All ages unlocked'
    end

    local remainingScore = nextUnlock.requiredScore - score

    return string.format(
        'Next: %s at %s (%s to go)',
        nextUnlock.displayName,
        formatCompact(nextUnlock.requiredScore),
        formatCompact(remainingScore)
    )
end

return ZoneUnlockUiLogic
