local ZoneLogic = {}

function ZoneLogic.isPositionInsideCircle(
    position: Vector3,
    zoneCenter: Vector3,
    zoneRadius: number
): boolean
    local xOffset = position.X - zoneCenter.X
    local zOffset = position.Z - zoneCenter.Z
    local horizontalDistanceSquared = (xOffset * xOffset) + (zOffset * zOffset)
    return horizontalDistanceSquared <= (zoneRadius * zoneRadius)
end

function ZoneLogic.isPositionInsideOrientedCircle(
    position: Vector3,
    zoneCFrame: CFrame,
    zoneSize: Vector3
): boolean
    local localPosition = zoneCFrame:PointToObjectSpace(position)
    local sizeX = math.abs(zoneSize.X)
    local sizeY = math.abs(zoneSize.Y)
    local sizeZ = math.abs(zoneSize.Z)

    local axis = 'X'
    if sizeY <= sizeX and sizeY <= sizeZ then
        axis = 'Y'
    elseif sizeZ <= sizeX and sizeZ <= sizeY then
        axis = 'Z'
    end

    local radialA = 0
    local radialB = 0
    local radius = 0

    if axis == 'X' then
        radialA = localPosition.Y
        radialB = localPosition.Z
        radius = math.max(sizeY, sizeZ) * 0.5
    elseif axis == 'Y' then
        radialA = localPosition.X
        radialB = localPosition.Z
        radius = math.max(sizeX, sizeZ) * 0.5
    else
        radialA = localPosition.X
        radialB = localPosition.Y
        radius = math.max(sizeX, sizeY) * 0.5
    end

    local radialDistanceSquared = (radialA * radialA) + (radialB * radialB)
    return radialDistanceSquared <= (radius * radius)
end

return ZoneLogic
