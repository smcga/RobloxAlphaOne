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

export type PartDecorSpec = {
    kind: 'Part',
    name: string,
    shape: DecorShape,
    size: Vector3Spec,
    position: Vector3Spec,
    rotation: Vector3Spec?,
    color: Color3Spec,
    material: string,
    transparency: number?,
}

export type AssetDecorSpec = {
    kind: 'Asset',
    name: string,
    assetId: number,
    position: Vector3Spec,
    rotation: Vector3Spec?,
    scale: number?,
}

export type DecorSpec = PartDecorSpec | AssetDecorSpec

local WorldDecorLogic = {}

local REALISTIC_TREES_ASSET_ID = 3256343670

local DECOR_SPECS: { DecorSpec } = {
    {
        kind = 'Part',
        name = 'CenterPad',
        shape = 'Cylinder',
        size = { x = 2, y = 52, z = 52 },
        position = { x = 0, y = 0.5, z = 0 },
        rotation = { x = 0, y = 0, z = 90 },
        color = { r = 110, g = 128, b = 102 },
        material = 'Slate',
    },
    {
        kind = 'Part',
        name = 'NorthHill',
        shape = 'Ball',
        size = { x = 26, y = 14, z = 26 },
        position = { x = 0, y = 6.5, z = -42 },
        color = { r = 92, g = 120, b = 77 },
        material = 'Grass',
    },
    {
        kind = 'Part',
        name = 'SouthHill',
        shape = 'Ball',
        size = { x = 32, y = 16, z = 32 },
        position = { x = 0, y = 7.5, z = 42 },
        color = { r = 80, g = 110, b = 65 },
        material = 'Grass',
    },
    {
        kind = 'Part',
        name = 'EastHill',
        shape = 'Ball',
        size = { x = 24, y = 10, z = 24 },
        position = { x = 45, y = 4.5, z = 20 },
        color = { r = 98, g = 126, b = 84 },
        material = 'Grass',
    },
    {
        kind = 'Part',
        name = 'WestHill',
        shape = 'Ball',
        size = { x = 28, y = 11, z = 28 },
        position = { x = -45, y = 5, z = -20 },
        color = { r = 98, g = 126, b = 84 },
        material = 'Grass',
    },
    {
        kind = 'Part',
        name = 'MainPath',
        shape = 'Block',
        size = { x = 88, y = 1, z = 10 },
        position = { x = 18, y = 0.1, z = 0 },
        color = { r = 106, g = 97, b = 88 },
        material = 'Slate',
    },
    {
        kind = 'Part',
        name = 'RebirthPath',
        shape = 'Block',
        size = { x = 50, y = 1, z = 10 },
        position = { x = -35, y = 0.1, z = 0 },
        color = { r = 106, g = 97, b = 88 },
        material = 'Slate',
    },
    {
        kind = 'Part',
        name = 'NorthRockCluster',
        shape = 'Block',
        size = { x = 6, y = 3.2, z = 4.5 },
        position = { x = 7, y = 1.1, z = -20 },
        rotation = { x = 0, y = 18, z = 0 },
        color = { r = 117, g = 113, b = 108 },
        material = 'Slate',
    },
    {
        kind = 'Part',
        name = 'SouthRockCluster',
        shape = 'Block',
        size = { x = 5.5, y = 3, z = 4 },
        position = { x = -11, y = 1, z = 18 },
        rotation = { x = 0, y = -26, z = 0 },
        color = { r = 113, g = 108, b = 103 },
        material = 'Slate',
    },
    {
        kind = 'Asset',
        name = 'RealisticTreeNorth',
        assetId = REALISTIC_TREES_ASSET_ID,
        position = { x = 24, y = 0, z = -28 },
        scale = 0.4,
    },
    {
        kind = 'Asset',
        name = 'RealisticTreeNorthEast',
        assetId = REALISTIC_TREES_ASSET_ID,
        position = { x = 40, y = 0, z = -22 },
        rotation = { x = 0, y = 110, z = 0 },
        scale = 0.35,
    },
    {
        kind = 'Asset',
        name = 'RealisticTreeSouth',
        assetId = REALISTIC_TREES_ASSET_ID,
        position = { x = -26, y = 0, z = 28 },
        rotation = { x = 0, y = 180, z = 0 },
        scale = 0.4,
    },
    {
        kind = 'Asset',
        name = 'RealisticTreeWest',
        assetId = REALISTIC_TREES_ASSET_ID,
        position = { x = -40, y = 0, z = -10 },
        rotation = { x = 0, y = -75, z = 0 },
        scale = 0.32,
    },
}

function WorldDecorLogic.getDecorSpecs(): { DecorSpec }
    return DECOR_SPECS
end

return WorldDecorLogic
