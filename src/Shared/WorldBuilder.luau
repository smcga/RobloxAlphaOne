local InsertService = game:GetService('InsertService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SoundService = game:GetService('SoundService')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local Constants = require(Shared:WaitForChild('Constants'))
local WorldDecorLogic = require(Shared:WaitForChild('WorldDecorLogic'))

local WorldBuilder = {}

local DECOR_MATERIALS: { [string]: Enum.Material } = {
    Slate = Enum.Material.Slate,
    Grass = Enum.Material.Grass,
    Wood = Enum.Material.Wood,
}

local ASSET_TEMPLATE_CACHE: { [number]: Instance } = {}

local function toVector3(vector: WorldDecorLogic.Vector3Spec): Vector3
    return Vector3.new(vector.x, vector.y, vector.z)
end

local function toColor3(color: WorldDecorLogic.Color3Spec): Color3
    return Color3.fromRGB(color.r, color.g, color.b)
end

local function toCFrame(
    position: WorldDecorLogic.Vector3Spec,
    rotation: WorldDecorLogic.Vector3Spec?
): CFrame
    local worldPosition = toVector3(position)
    if rotation == nil then
        return CFrame.new(worldPosition)
    end

    return CFrame.new(worldPosition)
        * CFrame.Angles(math.rad(rotation.x), math.rad(rotation.y), math.rad(rotation.z))
end

local function applyDecorShape(part: Part, shapeName: WorldDecorLogic.DecorShape)
    if shapeName == 'Cylinder' then
        part.Shape = Enum.PartType.Cylinder
    elseif shapeName == 'Ball' then
        part.Shape = Enum.PartType.Ball
    else
        part.Shape = Enum.PartType.Block
    end
end

local function ensureGeneratedWorldRoot(workspaceRoot: Instance): Folder
    local existing = workspaceRoot:FindFirstChild('GeneratedWorld')
    if existing and existing:IsA('Folder') then
        return existing
    end

    if existing then
        existing:Destroy()
    end

    local folder = Instance.new('Folder')
    folder.Name = 'GeneratedWorld'
    folder.Parent = workspaceRoot
    return folder
end

local function applyGeneratedAttributes(instance: Instance, specId: string, specKind: string)
    instance:SetAttribute('Generated', true)
    instance:SetAttribute('WorldId', specId)
    instance:SetAttribute('WorldKind', specKind)
end

local function getFirstPlaceableChild(container: Instance): Instance?
    for _, child in container:GetChildren() do
        if child:IsA('Model') then
            return child
        end
    end

    for _, descendant in container:GetDescendants() do
        if descendant:IsA('Model') then
            return descendant
        end
    end

    for _, child in container:GetChildren() do
        if child:IsA('BasePart') then
            return child
        end
    end

    for _, descendant in container:GetDescendants() do
        if descendant:IsA('BasePart') then
            return descendant
        end
    end

    return nil
end

local function getMeshPartTemplate(assetId: number): MeshPart?
    local ok, meshPart = pcall(function()
        return InsertService:CreateMeshPartAsync(
            string.format('rbxassetid://%d', assetId),
            Enum.CollisionFidelity.Default,
            Enum.RenderFidelity.Automatic
        )
    end)

    if not ok or meshPart == nil then
        return nil
    end

    meshPart.Anchored = true
    meshPart.CanCollide = true
    return meshPart
end

local function getAssetTemplate(assetId: number): Instance?
    local cached = ASSET_TEMPLATE_CACHE[assetId]
    if cached then
        return cached
    end

    local ok, loaded = pcall(function()
        return InsertService:LoadAsset(assetId)
    end)

    if not ok or loaded == nil then
        local meshTemplate = getMeshPartTemplate(assetId)
        if meshTemplate then
            ASSET_TEMPLATE_CACHE[assetId] = meshTemplate
            return meshTemplate
        end

        warn(string.format('World decor asset %d failed to load', assetId))
        return nil
    end

    local template = getFirstPlaceableChild(loaded)
    if not template then
        loaded:Destroy()
        local meshTemplate = getMeshPartTemplate(assetId)
        if meshTemplate then
            ASSET_TEMPLATE_CACHE[assetId] = meshTemplate
            return meshTemplate
        end

        warn(string.format('World decor asset %d had no placeable model', assetId))
        return nil
    end

    local detachedTemplate = template:Clone()
    loaded:Destroy()
    ASSET_TEMPLATE_CACHE[assetId] = detachedTemplate
    return detachedTemplate
end

local function anchorModel(model: Model)
    for _, descendant in model:GetDescendants() do
        if descendant:IsA('BasePart') then
            descendant.Anchored = true
            descendant.CanCollide = true
        end
    end
end

local function ensureBaseplate(workspaceRoot: Instance): Part
    local existing = workspaceRoot:FindFirstChild('Baseplate')
    if existing and existing:IsA('Part') then
        return existing
    end

    local baseplate = Instance.new('Part')
    baseplate.Name = 'Baseplate'
    baseplate.Anchored = true
    baseplate.Size = Constants.BASEPLATE_SIZE
    baseplate.Position = Vector3.new(0, -0.5, 0)
    baseplate.Material = Enum.Material.Concrete
    baseplate.Color = Color3.fromRGB(99, 95, 98)
    baseplate.Parent = workspaceRoot

    return baseplate
end

local function ensurePartDecor(parent: Instance, spec: WorldDecorLogic.PartDecorSpec)
    local existing = parent:FindFirstChild(spec.name)
    local part: Part

    if existing and existing:IsA('Part') then
        part = existing
    else
        if existing then
            existing:Destroy()
        end

        part = Instance.new('Part')
        part.Name = spec.name
        part.Parent = parent
    end

    part.Anchored = true
    part.Size = toVector3(spec.size)
    part.CFrame = toCFrame(spec.position, spec.rotation)
    part.Color = toColor3(spec.color)
    part.Material = DECOR_MATERIALS[spec.material] or Enum.Material.SmoothPlastic
    part.Transparency = spec.transparency or 0
    part.CanCollide = true
    applyDecorShape(part, spec.shape)
    applyGeneratedAttributes(part, spec.id, spec.kind)
end

local function getFallbackPartName(specName: string): string
    return string.format('%s_Fallback', specName)
end

local function clearAssetFallbackPart(parent: Instance, specName: string)
    local fallback = parent:FindFirstChild(getFallbackPartName(specName))
    if fallback then
        fallback:Destroy()
    end
end

local function ensureAssetFallbackPart(parent: Instance, spec: WorldDecorLogic.AssetDecorSpec)
    local fallbackName = getFallbackPartName(spec.name)
    local existing = parent:FindFirstChild(fallbackName)
    local fallbackPart: Part

    if existing and existing:IsA('Part') then
        fallbackPart = existing
    else
        if existing then
            existing:Destroy()
        end

        fallbackPart = Instance.new('Part')
        fallbackPart.Name = fallbackName
        fallbackPart.Parent = parent
    end

    local isGrassFallback = string.find(spec.name, 'Grass', 1, true) ~= nil
    if isGrassFallback then
        fallbackPart.Shape = Enum.PartType.Block
        fallbackPart.Size = Vector3.new(10, 0.8, 10)
        fallbackPart.Material = Enum.Material.Grass
        fallbackPart.Color = Color3.fromRGB(97, 145, 86)
        fallbackPart.CFrame = toCFrame(
            { x = spec.position.x, y = spec.position.y + 0.4, z = spec.position.z },
            spec.rotation
        )
    else
        fallbackPart.Shape = Enum.PartType.Ball
        fallbackPart.Size = Vector3.new(5.5, 4.5, 5.5)
        fallbackPart.Material = Enum.Material.Slate
        fallbackPart.Color = Color3.fromRGB(118, 113, 108)
        fallbackPart.CFrame = toCFrame(
            { x = spec.position.x, y = spec.position.y + 2.25, z = spec.position.z },
            spec.rotation
        )
    end

    fallbackPart.Anchored = true
    fallbackPart.CanCollide = true
end

local function ensureAssetDecor(parent: Instance, spec: WorldDecorLogic.AssetDecorSpec)
    local existing = parent:FindFirstChild(spec.name)
    local target = existing

    if not target or (not target:IsA('Model') and not target:IsA('BasePart')) then
        if target then
            target:Destroy()
        end

        local template = getAssetTemplate(spec.assetId)
        if not template then
            ensureAssetFallbackPart(parent, spec)
            return
        end

        target = template:Clone()
        target.Name = spec.name
        target.Parent = parent
    end

    local targetCFrame = toCFrame(spec.position, spec.rotation)
    applyGeneratedAttributes(target, spec.id, spec.kind)
    target:SetAttribute('WorldAssetId', spec.assetId)

    if target:IsA('Model') then
        if spec.scale then
            target:ScaleTo(spec.scale)
            target:SetAttribute('WorldScale', spec.scale)
        else
            target:SetAttribute('WorldScale', nil)
        end

        anchorModel(target)
        target:PivotTo(targetCFrame)
        clearAssetFallbackPart(parent, spec.name)
        return
    end

    target.Anchored = true
    target.CanCollide = true
    target.CFrame = targetCFrame
    if spec.scale then
        target:SetAttribute('WorldScale', spec.scale)
    else
        target:SetAttribute('WorldScale', nil)
    end
    clearAssetFallbackPart(parent, spec.name)
end

local function ensureWorldDecor(workspaceRoot: Instance)
    local generatedWorld = ensureGeneratedWorldRoot(workspaceRoot)

    local decorFolder = generatedWorld:FindFirstChild('WorldDecor')
    if not decorFolder or not decorFolder:IsA('Folder') then
        if decorFolder then
            decorFolder:Destroy()
        end

        decorFolder = Instance.new('Folder')
        decorFolder.Name = 'WorldDecor'
        decorFolder.Parent = generatedWorld
    end

    for _, spec in WorldDecorLogic.getDecorSpecs() do
        if spec.kind == 'Asset' then
            ensureAssetDecor(decorFolder, spec)
        else
            ensurePartDecor(decorFolder, spec)
        end
    end
end

local function ensureZone(
    workspaceRoot: Instance,
    zoneName: string,
    zoneCenter: Vector3,
    zoneRadius: number,
    zoneHeight: number,
    zoneColor: Color3,
    outlineColor: Color3
): BasePart
    local existing = workspaceRoot:FindFirstChild(zoneName)
    local zone: BasePart
    if existing and existing:IsA('BasePart') then
        zone = existing
    else
        if existing then
            existing:Destroy()
        end

        zone = Instance.new('Part')
        zone.Name = zoneName
        zone.Parent = workspaceRoot
    end

    zone.Shape = Enum.PartType.Cylinder
    zone.Anchored = true
    zone.CanCollide = false
    zone.CanTouch = false
    zone.CanQuery = true
    zone.Size = Vector3.new(zoneHeight, zoneRadius * 2, zoneRadius * 2)
    zone.CFrame = CFrame.new(zoneCenter) * CFrame.Angles(0, 0, math.rad(90))
    zone.Material = Enum.Material.Neon
    zone.Transparency = 0.35
    zone.Color = zoneColor
    zone.Parent = workspaceRoot

    local highlight: Highlight
    local existingHighlight = zone:FindFirstChild('ZoneHighlight')
    if existingHighlight and existingHighlight:IsA('Highlight') then
        highlight = existingHighlight
    else
        highlight = Instance.new('Highlight')
        highlight.Name = 'ZoneHighlight'
        highlight.Parent = zone
    end
    highlight.FillTransparency = 0.75
    highlight.OutlineColor = outlineColor
    highlight.OutlineTransparency = 0
    highlight.Adornee = zone

    return zone
end

local function ensureZoneLabel(zone: BasePart, text: string, isVisible: boolean)
    local existing = zone:FindFirstChild('ZoneBillboard')
    local billboardGui: BillboardGui
    if existing and existing:IsA('BillboardGui') then
        billboardGui = existing
    else
        if existing then
            existing:Destroy()
        end

        billboardGui = Instance.new('BillboardGui')
        billboardGui.Name = 'ZoneBillboard'
        billboardGui.Parent = zone
    end

    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.fromOffset(220, 64)
    billboardGui.StudsOffset = Vector3.new(0, 6, 0)
    billboardGui.Enabled = isVisible

    local existingLabel = billboardGui:FindFirstChild('ZoneLabel')
    local label: TextLabel
    if existingLabel and existingLabel:IsA('TextLabel') then
        label = existingLabel
    else
        if existingLabel then
            existingLabel:Destroy()
        end

        label = Instance.new('TextLabel')
        label.Name = 'ZoneLabel'
        label.Parent = billboardGui
    end

    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.TextStrokeTransparency = 0.2
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = text
end

local function ensureAgeOfBeadsSpawn(workspaceRoot: Instance)
    local beadsConfig = Constants.AGE_ZONE_CONFIGS[1]
    if not beadsConfig then
        return
    end

    local spawnPosition = beadsConfig.center + Constants.SPAWN_LOCATION_OFFSET
    local existing = workspaceRoot:FindFirstChild(Constants.SPAWN_LOCATION_NAME)
    local spawnLocation: SpawnLocation

    if existing and existing:IsA('SpawnLocation') then
        spawnLocation = existing
    else
        if existing then
            existing:Destroy()
        end

        spawnLocation = Instance.new('SpawnLocation')
        spawnLocation.Name = Constants.SPAWN_LOCATION_NAME
        spawnLocation.Parent = workspaceRoot
    end

    spawnLocation.Size = Constants.SPAWN_LOCATION_SIZE
    spawnLocation.Position = spawnPosition
    spawnLocation.Anchored = true
    spawnLocation.Neutral = true
    spawnLocation.CanCollide = true
    spawnLocation.Transparency = 1
end

local function ensureBackgroundMusic()
    local existing = SoundService:FindFirstChild(Constants.BACKGROUND_MUSIC_NAME)
    local sound: Sound

    if existing and existing:IsA('Sound') then
        sound = existing
    else
        if existing then
            existing:Destroy()
        end

        sound = Instance.new('Sound')
        sound.Name = Constants.BACKGROUND_MUSIC_NAME
        sound.Parent = SoundService
    end

    sound.SoundId = Constants.BACKGROUND_MUSIC_SOUND_ID
    sound.Volume = Constants.BACKGROUND_MUSIC_VOLUME
    sound.Looped = true

    if not sound.IsPlaying then
        sound:Play()
    end
end

function WorldBuilder.build(workspaceRoot: Instance)
    ensureBaseplate(workspaceRoot)
    ensureWorldDecor(workspaceRoot)
    ensureAgeOfBeadsSpawn(workspaceRoot)
    ensureBackgroundMusic()

    local obsoleteZoneNames = {
        'ScoreZone',
        'HighScoreZone',
        "1700'sZone",
    }

    for _, obsoleteName in ipairs(obsoleteZoneNames) do
        local obsoleteZone = workspaceRoot:FindFirstChild(obsoleteName)
        if obsoleteZone and obsoleteZone:IsA('BasePart') then
            obsoleteZone:Destroy()
        end
    end

    for _, zoneConfig in ipairs(Constants.AGE_ZONE_CONFIGS) do
        local zone = ensureZone(
            workspaceRoot,
            zoneConfig.zoneName,
            zoneConfig.center,
            zoneConfig.radius,
            zoneConfig.height,
            zoneConfig.color,
            zoneConfig.outlineColor
        )
        zone:SetAttribute('RequiredScore', zoneConfig.requiredScore)
        zone:SetAttribute('DisplayName', zoneConfig.displayName)
        ensureZoneLabel(zone, zoneConfig.displayName, zoneConfig.requiredScore <= 0)
    end

    local rebirthZone = ensureZone(
        workspaceRoot,
        Constants.REBIRTH_ZONE_NAME,
        Constants.REBIRTH_ZONE_CENTER,
        Constants.REBIRTH_ZONE_RADIUS,
        Constants.REBIRTH_ZONE_HEIGHT,
        Color3.fromRGB(255, 0, 255),
        Color3.fromRGB(255, 214, 255)
    )

    ensureZoneLabel(rebirthZone, 'Rebirth', true)
end

return WorldBuilder
