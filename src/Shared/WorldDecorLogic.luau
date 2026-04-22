local WorldLayout = require('./WorldLayout')

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

export type BaseDecorSpec = {
    worldId: string,
    name: string,
    kind: 'Part' | 'Asset',
    position: Vector3Spec,
    rotation: Vector3Spec?,
}

export type PartDecorSpec = BaseDecorSpec & {
    kind: 'Part',
    shape: DecorShape,
    size: Vector3Spec,
    color: Color3Spec,
    material: string,
    transparency: number?,
}

export type AssetDecorSpec = BaseDecorSpec & {
    kind: 'Asset',
    assetId: number,
    scale: number?,
}

export type DecorSpec = PartDecorSpec | AssetDecorSpec

local WorldDecorLogic = {}

function WorldDecorLogic.getDecorSpecs(): { DecorSpec }
    return WorldLayout.decor
end

return WorldDecorLogic
