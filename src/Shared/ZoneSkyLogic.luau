export type SkyZoneConfig = {
    center: Vector3,
    radius: number,
    color: Color3,
}

local ZoneSkyLogic = {}

local function clamp01(value: number): number
    if value < 0 then
        return 0
    end

    if value > 1 then
        return 1
    end

    return value
end

local function isPositionInsideCircle(
    position: Vector3,
    zoneCenter: Vector3,
    zoneRadius: number
): boolean
    local xOffset = position.X - zoneCenter.X
    local zOffset = position.Z - zoneCenter.Z
    local horizontalDistanceSquared = (xOffset * xOffset) + (zOffset * zOffset)
    return horizontalDistanceSquared <= (zoneRadius * zoneRadius)
end

function ZoneSkyLogic.getCurrentZoneIndex(position: Vector3, zones: { SkyZoneConfig }): number?
    for index, zone in ipairs(zones) do
        if isPositionInsideCircle(position, zone.center, zone.radius) then
            return index
        end
    end

    return nil
end

function ZoneSkyLogic.getSkyTintColor(
    zoneIndex: number?,
    zones: { SkyZoneConfig },
    neutralColor: Color3,
    tintStrength: number
): Color3
    local strength = clamp01(tintStrength)

    if zoneIndex == nil then
        return neutralColor
    end

    local zone = zones[zoneIndex]
    if zone == nil then
        return neutralColor
    end

    return neutralColor:Lerp(zone.color, strength)
end

return ZoneSkyLogic
