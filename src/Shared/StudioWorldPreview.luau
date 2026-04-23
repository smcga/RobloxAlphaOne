local Workspace = game:GetService('Workspace')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local WorldBuilder = require(Shared:WaitForChild('WorldBuilder'))
local WorldLayoutExportLogic = require(Shared:WaitForChild('WorldLayoutExportLogic'))

local StudioWorldPreview = {}

type Vector3Spec = {
    x: number,
    y: number,
    z: number,
}

type DecorSpec = {
    id: string,
    kind: string,
    name: string,
    position: Vector3Spec,
    rotation: Vector3Spec,
    assetId: number?,
    scale: number?,
    shape: string?,
    size: Vector3Spec?,
    color: {
        r: number,
        g: number,
        b: number,
    }?,
    material: string?,
    transparency: number?,
}

local function roundNumber(value: number): number
    return math.round(value * 1000) / 1000
end

local function vector3ToSpec(vector: Vector3): Vector3Spec
    return {
        x = roundNumber(vector.X),
        y = roundNumber(vector.Y),
        z = roundNumber(vector.Z),
    }
end

local function getSourceAssetId(instance: Instance): number
    local ok, sourceAssetId = pcall(function()
        return instance.SourceAssetId
    end)

    if not ok or type(sourceAssetId) ~= 'number' then
        return 0
    end

    return sourceAssetId
end

local function toDecorShape(part: BasePart): string
    if part:IsA('Part') then
        return tostring(part.Shape):gsub('Enum.PartType.', '')
    end

    return 'Block'
end

local function getDecorContainers(): { Instance }
    local containers = {}

    local generatedWorld = Workspace:FindFirstChild('GeneratedWorld')
    if generatedWorld and generatedWorld:IsA('Folder') then
        local generatedDecor = generatedWorld:FindFirstChild('WorldDecor')
        if generatedDecor and generatedDecor:IsA('Folder') then
            table.insert(containers, generatedDecor)
        end
    end

    local manualWorld = Workspace:FindFirstChild('ManualWorld')
    if manualWorld and manualWorld:IsA('Folder') then
        table.insert(containers, manualWorld)
    end

    local legacyWorldDecor = Workspace:FindFirstChild('WorldDecor')
    if legacyWorldDecor and legacyWorldDecor:IsA('Folder') then
        table.insert(containers, legacyWorldDecor)
    end

    return containers
end

local function nextStableId(baseName: string, usedIds: { [string]: boolean }): string
    if not usedIds[baseName] then
        usedIds[baseName] = true
        return baseName
    end

    local suffix = 2
    while usedIds[string.format('%s_%d', baseName, suffix)] do
        suffix += 1
    end

    local id = string.format('%s_%d', baseName, suffix)
    usedIds[id] = true
    return id
end

local function collectDecorFromWorkspace(): { DecorSpec }
    local containers = getDecorContainers()
    if #containers == 0 then
        error(
            'No decor folders found. Run preview.buildInWorkspace() and/or create Workspace.ManualWorld with decor instances.'
        )
    end

    local specs = {}
    local usedIds: { [string]: boolean } = {}

    for _, container in containers do
        for _, child in container:GetChildren() do
            if child:IsA('Model') or child:IsA('BasePart') then
                local pivot = child:GetPivot()
                local x, y, z = pivot:ToEulerAnglesXYZ()
                local sourceAssetId = getSourceAssetId(child)
                local worldId = child:GetAttribute('WorldId')
                local specId = nextStableId(worldId or child.Name, usedIds)

                local baseSpec: DecorSpec = {
                    id = specId,
                    name = child.Name,
                    position = vector3ToSpec(pivot.Position),
                    rotation = {
                        x = roundNumber(math.deg(x)),
                        y = roundNumber(math.deg(y)),
                        z = roundNumber(math.deg(z)),
                    },
                    kind = 'Part',
                }

                local explicitKind = child:GetAttribute('WorldKind')
                if explicitKind == 'Asset' or sourceAssetId > 0 or child:IsA('Model') then
                    baseSpec.kind = 'Asset'
                    baseSpec.assetId = child:GetAttribute('WorldAssetId') or sourceAssetId
                    baseSpec.scale = child:GetAttribute('WorldScale') or 1

                    if not baseSpec.assetId or baseSpec.assetId <= 0 then
                        warn(
                            string.format(
                                'Skipping %s because it has no asset id (set WorldAssetId attribute or insert from Creator Store).',
                                child:GetFullName()
                            )
                        )
                        continue
                    end
                elseif child:IsA('BasePart') then
                    local color = child.Color
                    baseSpec.shape = toDecorShape(child)
                    baseSpec.size = vector3ToSpec(child.Size)
                    baseSpec.color = {
                        r = math.round(color.R * 255),
                        g = math.round(color.G * 255),
                        b = math.round(color.B * 255),
                    }
                    baseSpec.material = tostring(child.Material):gsub('Enum.Material.', '')
                    if child.Transparency > 0 then
                        baseSpec.transparency = roundNumber(child.Transparency)
                    end
                end

                table.insert(specs, baseSpec)
            end
        end
    end

    return specs
end

function StudioWorldPreview.buildInWorkspace()
    WorldBuilder.build(Workspace)
end

function StudioWorldPreview.exportLayoutModuleSourceFromWorkspace(): string
    local specs = collectDecorFromWorkspace()
    return WorldLayoutExportLogic.serializeWorldLayoutModule(specs)
end

function StudioWorldPreview.syncLayoutModuleFromWorkspace(): string
    local worldLayout = Shared:FindFirstChild('WorldLayout')
    if not worldLayout or not worldLayout:IsA('ModuleScript') then
        error('ReplicatedStorage.Shared.WorldLayout ModuleScript is missing.')
    end

    local moduleSource = StudioWorldPreview.exportLayoutModuleSourceFromWorkspace()
    worldLayout.Source = moduleSource
    print(
        string.format(
            'Synced %d bytes into ReplicatedStorage.Shared.WorldLayout.Source',
            #moduleSource
        )
    )

    return moduleSource
end

return StudioWorldPreview
