export type DecorShape = 'Block' | 'Cylinder' | 'Ball'

export type Vector3Spec = {
    x: number,
    y: number,
    z: number,
}

export type Color3Spec = {
    r: number,
    g: number,
    b: number,
}

export type DecorSpec = {
    name: string,
    shape: DecorShape,
    size: Vector3Spec,
    position: Vector3Spec,
    rotation: Vector3Spec?,
    color: Color3Spec,
    material: string,
    transparency: number?,
}

local WorldDecorLogic = {}

local DECOR_SPECS: { DecorSpec } = {
    {
        name = 'CenterPad',
        shape = 'Cylinder',
        size = { x = 2, y = 52, z = 52 },
        position = { x = 0, y = 0.5, z = 0 },
        rotation = { x = 0, y = 0, z = 90 },
        color = { r = 110, g = 128, b = 102 },
        material = 'Slate',
    },
    {
        name = 'NorthHill',
        shape = 'Ball',
        size = { x = 26, y = 14, z = 26 },
        position = { x = 0, y = 6.5, z = -42 },
        color = { r = 92, g = 120, b = 77 },
        material = 'Grass',
    },
    {
        name = 'SouthHill',
        shape = 'Ball',
        size = { x = 32, y = 16, z = 32 },
        position = { x = 0, y = 7.5, z = 42 },
        color = { r = 80, g = 110, b = 65 },
        material = 'Grass',
    },
    {
        name = 'EastHill',
        shape = 'Ball',
        size = { x = 24, y = 10, z = 24 },
        position = { x = 45, y = 4.5, z = 20 },
        color = { r = 98, g = 126, b = 84 },
        material = 'Grass',
    },
    {
        name = 'WestHill',
        shape = 'Ball',
        size = { x = 28, y = 11, z = 28 },
        position = { x = -45, y = 5, z = -20 },
        color = { r = 98, g = 126, b = 84 },
        material = 'Grass',
    },
    {
        name = 'MainPath',
        shape = 'Block',
        size = { x = 88, y = 1, z = 10 },
        position = { x = 18, y = 0.1, z = 0 },
        color = { r = 106, g = 97, b = 88 },
        material = 'Slate',
    },
    {
        name = 'RebirthPath',
        shape = 'Block',
        size = { x = 50, y = 1, z = 10 },
        position = { x = -35, y = 0.1, z = 0 },
        color = { r = 106, g = 97, b = 88 },
        material = 'Slate',
    },
    {
        name = 'NorthTree',
        shape = 'Cylinder',
        size = { x = 8, y = 3, z = 3 },
        position = { x = 18, y = 4, z = -28 },
        rotation = { x = 0, y = 0, z = 90 },
        color = { r = 84, g = 55, b = 33 },
        material = 'Wood',
    },
    {
        name = 'NorthTreeLeaves',
        shape = 'Ball',
        size = { x = 10, y = 10, z = 10 },
        position = { x = 18, y = 10, z = -28 },
        color = { r = 69, g = 125, b = 64 },
        material = 'Grass',
    },
    {
        name = 'SouthTree',
        shape = 'Cylinder',
        size = { x = 8, y = 3, z = 3 },
        position = { x = -22, y = 4, z = 26 },
        rotation = { x = 0, y = 0, z = 90 },
        color = { r = 84, g = 55, b = 33 },
        material = 'Wood',
    },
    {
        name = 'SouthTreeLeaves',
        shape = 'Ball',
        size = { x = 10, y = 10, z = 10 },
        position = { x = -22, y = 10, z = 26 },
        color = { r = 69, g = 125, b = 64 },
        material = 'Grass',
    },
    {
        name = 'PineNorthTrunk',
        shape = 'Cylinder',
        size = { x = 9, y = 2.5, z = 2.5 },
        position = { x = 34, y = 4.5, z = -38 },
        rotation = { x = 0, y = 0, z = 90 },
        color = { r = 88, g = 58, b = 34 },
        material = 'Wood',
    },
    {
        name = 'PineNorthCanopy',
        shape = 'Ball',
        size = { x = 12, y = 13, z = 12 },
        position = { x = 34, y = 11, z = -38 },
        color = { r = 58, g = 116, b = 67 },
        material = 'Grass',
    },
    {
        name = 'PineSouthTrunk',
        shape = 'Cylinder',
        size = { x = 9, y = 2.5, z = 2.5 },
        position = { x = -35, y = 4.5, z = 34 },
        rotation = { x = 0, y = 0, z = 90 },
        color = { r = 88, g = 58, b = 34 },
        material = 'Wood',
    },
    {
        name = 'PineSouthCanopy',
        shape = 'Ball',
        size = { x = 11, y = 12, z = 11 },
        position = { x = -35, y = 10.5, z = 34 },
        color = { r = 56, g = 109, b = 62 },
        material = 'Grass',
    },
    {
        name = 'EastBushPatch',
        shape = 'Ball',
        size = { x = 7, y = 4, z = 7 },
        position = { x = 39, y = 1.6, z = 7 },
        color = { r = 63, g = 119, b = 58 },
        material = 'Grass',
    },
    {
        name = 'WestBushPatch',
        shape = 'Ball',
        size = { x = 8, y = 4, z = 8 },
        position = { x = -39, y = 1.6, z = -8 },
        color = { r = 61, g = 117, b = 56 },
        material = 'Grass',
    },
    {
        name = 'NorthRockCluster',
        shape = 'Block',
        size = { x = 6, y = 3.2, z = 4.5 },
        position = { x = 7, y = 1.1, z = -20 },
        rotation = { x = 0, y = 18, z = 0 },
        color = { r = 117, g = 113, b = 108 },
        material = 'Slate',
    },
    {
        name = 'SouthRockCluster',
        shape = 'Block',
        size = { x = 5.5, y = 3, z = 4 },
        position = { x = -11, y = 1, z = 18 },
        rotation = { x = 0, y = -26, z = 0 },
        color = { r = 113, g = 108, b = 103 },
        material = 'Slate',
    },
    {
        name = 'NorthFlowerPatch',
        shape = 'Cylinder',
        size = { x = 0.4, y = 6, z = 6 },
        position = { x = 29, y = -0.25, z = -15 },
        rotation = { x = 0, y = 0, z = 90 },
        color = { r = 198, g = 120, b = 165 },
        material = 'Grass',
        transparency = 0.2,
    },
    {
        name = 'SouthFlowerPatch',
        shape = 'Cylinder',
        size = { x = 0.4, y = 5.5, z = 5.5 },
        position = { x = -28, y = -0.25, z = 13 },
        rotation = { x = 0, y = 0, z = 90 },
        color = { r = 203, g = 166, b = 98 },
        material = 'Grass',
        transparency = 0.2,
    },
}

function WorldDecorLogic.getDecorSpecs(): { DecorSpec }
    return DECOR_SPECS
end

return WorldDecorLogic
