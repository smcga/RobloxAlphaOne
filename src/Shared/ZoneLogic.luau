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

return ZoneLogic
