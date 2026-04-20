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
        color = { r = 110, g = 128, b = 102 },
        material = 'Slate',
    },
    {
        name = 'NorthHill',
        shape = 'Ball',
        size = { x = 26, y = 14, z = 26 },
        position = { x = 0, y = 2, z = -42 },
        color = { r = 92, g = 120, b = 77 },
        material = 'Grass',
    },
    {
        name = 'SouthHill',
        shape = 'Ball',
        size = { x = 32, y = 16, z = 32 },
        position = { x = 0, y = 1, z = 42 },
        color = { r = 80, g = 110, b = 65 },
        material = 'Grass',
    },
    {
        name = 'EastHill',
        shape = 'Ball',
        size = { x = 24, y = 10, z = 24 },
        position = { x = 45, y = 1, z = 20 },
        color = { r = 98, g = 126, b = 84 },
        material = 'Grass',
    },
    {
        name = 'WestHill',
        shape = 'Ball',
        size = { x = 28, y = 11, z = 28 },
        position = { x = -45, y = 1, z = -20 },
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
}

function WorldDecorLogic.getDecorSpecs(): { DecorSpec }
    return DECOR_SPECS
end

return WorldDecorLogic
