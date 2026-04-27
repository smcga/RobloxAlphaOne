export type AgeZoneRuntimeConfig = {
    zoneName: string,
    requiredScore: number,
    scoreIncrement: number,
    center: { X: number, Y: number, Z: number },
    radius: number,
}

export type RuntimeZoneSnapshot = {
    position: { X: number, Y: number, Z: number },
    size: { Y: number, Z: number },
}

local AgeZoneRuntimeLogic = {}

local function resolveRadius(fallbackRadius: number, runtimeSnapshot: RuntimeZoneSnapshot?): number
    if runtimeSnapshot == nil then
        return fallbackRadius
    end

    local runtimeDiameter = math.max(runtimeSnapshot.size.Y, runtimeSnapshot.size.Z)
    if runtimeDiameter <= 0 then
        return fallbackRadius
    end

    return runtimeDiameter * 0.5
end

function AgeZoneRuntimeLogic.buildRuntimeConfigs(
    ageZoneConfigs: { AgeZoneRuntimeConfig },
    runtimeSnapshotsByZoneName: { [string]: RuntimeZoneSnapshot }?
): { AgeZoneRuntimeConfig }
    local runtimeConfigs = table.create(#ageZoneConfigs)

    for index, zoneConfig in ipairs(ageZoneConfigs) do
        local runtimeSnapshot = if runtimeSnapshotsByZoneName
            then runtimeSnapshotsByZoneName[zoneConfig.zoneName]
            else nil
        runtimeConfigs[index] = {
            zoneName = zoneConfig.zoneName,
            requiredScore = zoneConfig.requiredScore,
            scoreIncrement = zoneConfig.scoreIncrement,
            center = if runtimeSnapshot then runtimeSnapshot.position else zoneConfig.center,
            radius = resolveRadius(zoneConfig.radius, runtimeSnapshot),
        }
    end

    return runtimeConfigs
end

return AgeZoneRuntimeLogic
