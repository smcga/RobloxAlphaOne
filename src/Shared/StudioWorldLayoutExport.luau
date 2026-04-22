local Workspace = game:GetService('Workspace')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local WorldLayoutSerializationLogic = require(Shared:WaitForChild('WorldLayoutSerializationLogic'))

local StudioWorldLayoutExport = {}

local function roundToThree(value: number): number
    return math.round(value * 1000) / 1000
end

local function toVectorSpec(value: Vector3): WorldLayoutSerializationLogic.Vector3Spec
    return {
        x = roundToThree(value.X),
        y = roundToThree(value.Y),
        z = roundToThree(value.Z),
    }
end

local function toColorSpec(color: Color3): WorldLayoutSerializationLogic.Color3Spec
    return {
        r = math.round(color.R * 255),
        g = math.round(color.G * 255),
        b = math.round(color.B * 255),
    }
end

local function mapShape(shape: Enum.PartType): string
    if shape == Enum.PartType.Cylinder then
        return 'Cylinder'
    elseif shape == Enum.PartType.Ball then
        return 'Ball'
    end

    return 'Block'
end

local function findDecorFolder(workspaceRoot: Instance): Instance?
    local generatedWorld = workspaceRoot:FindFirstChild('GeneratedWorld')
    if generatedWorld and generatedWorld:IsA('Folder') then
        local decorFolder = generatedWorld:FindFirstChild('WorldDecor')
        if decorFolder and decorFolder:IsA('Folder') then
            return decorFolder
        end
    end

    local legacyDecor = workspaceRoot:FindFirstChild('WorldDecor')
    if legacyDecor and legacyDecor:IsA('Folder') then
        return legacyDecor
    end

    return nil
end

local function getScaleValue(instance: Instance): number?
    local scale = instance:GetAttribute('DecorScale')
    if typeof(scale) == 'number' then
        return scale
    end

    return nil
end

local function readDecorSpec(instance: Instance): WorldLayoutSerializationLogic.ExportDecorSpec?
    local isGenerated = instance:GetAttribute('Generated')
    local worldId = instance:GetAttribute('WorldId')
    local decorKind = instance:GetAttribute('DecorKind')

    if isGenerated ~= true or typeof(worldId) ~= 'string' or typeof(decorKind) ~= 'string' then
        return nil
    end

    local pivot = instance:GetPivot()
    local rotationX, rotationY, rotationZ = pivot.Rotation:ToOrientation()
    local rotation = {
        x = roundToThree(math.deg(rotationX)),
        y = roundToThree(math.deg(rotationY)),
        z = roundToThree(math.deg(rotationZ)),
    }

    local baseSpec = {
        worldId = worldId,
        kind = decorKind :: 'Part' | 'Asset',
        name = instance.Name,
        position = toVectorSpec(pivot.Position),
        rotation = rotation,
    }

    if decorKind == 'Part' then
        if not instance:IsA('Part') then
            return nil
        end

        return {
            worldId = baseSpec.worldId,
            kind = 'Part',
            name = baseSpec.name,
            shape = mapShape(instance.Shape),
            size = toVectorSpec(instance.Size),
            position = baseSpec.position,
            rotation = baseSpec.rotation,
            color = toColorSpec(instance.Color),
            material = instance.Material.Name,
            transparency = roundToThree(instance.Transparency),
        }
    end

    local assetId = instance:GetAttribute('AssetId')
    if typeof(assetId) ~= 'number' then
        return nil
    end

    return {
        worldId = baseSpec.worldId,
        kind = 'Asset',
        name = baseSpec.name,
        assetId = assetId,
        position = baseSpec.position,
        rotation = baseSpec.rotation,
        scale = getScaleValue(instance),
    }
end

function StudioWorldLayoutExport.exportLayoutFromWorkspace(workspaceRoot: Instance?): string
    local root = workspaceRoot or Workspace
    local decorFolder = findDecorFolder(root)
    if not decorFolder then
        error('WorldDecor folder was not found under Workspace.GeneratedWorld or Workspace')
    end

    local specs = {}
    for _, child in decorFolder:GetChildren() do
        local spec = readDecorSpec(child)
        if spec then
            table.insert(specs, spec)
        end
    end

    return WorldLayoutSerializationLogic.serializeDecorSpecs(specs)
end

return StudioWorldLayoutExport
