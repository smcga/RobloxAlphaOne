local worldLayoutModule

if script and script.Parent then
    worldLayoutModule = require(script.Parent:WaitForChild('WorldLayout'))
else
    worldLayoutModule = require('./WorldLayout')
end

export type DecorShape = worldLayoutModule.DecorShape
export type Vector3Spec = worldLayoutModule.Vector3Spec
export type Color3Spec = worldLayoutModule.Color3Spec
export type PartDecorSpec = worldLayoutModule.PartDecorSpec
export type AssetDecorSpec = worldLayoutModule.AssetDecorSpec
export type DecorSpec = worldLayoutModule.DecorSpec

local WorldDecorLogic = {}

function WorldDecorLogic.getDecorSpecs(): { DecorSpec }
    return worldLayoutModule.getDecorSpecs()
end

return WorldDecorLogic
