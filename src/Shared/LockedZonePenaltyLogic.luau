export type LockedZoneConfig = {
    requiredScore: number,
    center: { X: number, Z: number },
}

local LockedZonePenaltyLogic = {}

function LockedZonePenaltyLogic.getFirstLockedZoneIndex(
    score: number,
    isInsideAgeZones: { [number]: boolean },
    ageZoneConfigs: { LockedZoneConfig }
): number?
    for index, zoneConfig in ipairs(ageZoneConfigs) do
        local isInsideZone = isInsideAgeZones[index] == true
        local isZoneLocked = score < zoneConfig.requiredScore

        if isInsideZone and isZoneLocked then
            return index
        end
    end

    return nil
end

function LockedZonePenaltyLogic.getKnockbackHorizontalDirection(
    playerPosition: { X: number, Z: number },
    zoneCenter: { X: number, Z: number }
): { X: number, Z: number }
    local xOffset = playerPosition.X - zoneCenter.X
    local zOffset = playerPosition.Z - zoneCenter.Z
    local distance = math.sqrt((xOffset * xOffset) + (zOffset * zOffset))

    if distance <= 0 then
        return {
            X = 0,
            Z = -1,
        }
    end

    return {
        X = xOffset / distance,
        Z = zOffset / distance,
    }
end

return LockedZonePenaltyLogic
