local Workspace = game:GetService('Workspace')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local InsertService = game:GetService('InsertService')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local Constants = require(Shared:WaitForChild('Constants'))
local WorldDecorLogic = require(Shared:WaitForChild('WorldDecorLogic'))

local function ensureBaseplate(): Part
    local existing = Workspace:FindFirstChild('Baseplate')
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
    baseplate.Parent = Workspace

    return baseplate
end

local DECOR_MATERIALS: { [string]: Enum.Material } = {
    Slate = Enum.Material.Slate,
    Grass = Enum.Material.Grass,
    Wood = Enum.Material.Wood,
}

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

local ASSET_TEMPLATE_CACHE: { [number]: Instance } = {}

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

    if target:IsA('Model') then
        if spec.scale then
            target:ScaleTo(spec.scale)
        end

        anchorModel(target)
        target:PivotTo(targetCFrame)
        clearAssetFallbackPart(parent, spec.name)
        return
    end

    target.Anchored = true
    target.CanCollide = true
    target.CFrame = targetCFrame
    clearAssetFallbackPart(parent, spec.name)
end

local function ensureWorldDecor()
    local decorFolder = Workspace:FindFirstChild('WorldDecor')
    if not decorFolder or not decorFolder:IsA('Folder') then
        decorFolder = Instance.new('Folder')
        decorFolder.Name = 'WorldDecor'
        decorFolder.Parent = Workspace
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
    zoneName: string,
    zoneCenter: Vector3,
    zoneRadius: number,
    zoneHeight: number,
    zoneColor: Color3,
    outlineColor: Color3
): BasePart
    local existing = Workspace:FindFirstChild(zoneName)
    local zone: BasePart
    if existing and existing:IsA('BasePart') then
        zone = existing
    else
        if existing then
            existing:Destroy()
        end

        zone = Instance.new('Part')
        zone.Name = zoneName
        zone.Parent = Workspace
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
    zone.Parent = Workspace

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

local function ensureZoneLabel(zone: BasePart, text: string)
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

ensureBaseplate()
ensureWorldDecor()
local obsoleteZoneNames = {
    'ScoreZone',
    'HighScoreZone',
    "1700'sZone",
}

for _, obsoleteName in ipairs(obsoleteZoneNames) do
    local obsoleteZone = Workspace:FindFirstChild(obsoleteName)
    if obsoleteZone and obsoleteZone:IsA('BasePart') then
        obsoleteZone:Destroy()
    end
end

for _, zoneConfig in ipairs(Constants.AGE_ZONE_CONFIGS) do
    local zone = ensureZone(
        zoneConfig.zoneName,
        zoneConfig.center,
        zoneConfig.radius,
        zoneConfig.height,
        zoneConfig.color,
        zoneConfig.outlineColor
    )
    ensureZoneLabel(zone, zoneConfig.displayName)
end

local rebirthZone = ensureZone(
    Constants.REBIRTH_ZONE_NAME,
    Constants.REBIRTH_ZONE_CENTER,
    Constants.REBIRTH_ZONE_RADIUS,
    Constants.REBIRTH_ZONE_HEIGHT,
    Color3.fromRGB(255, 0, 255),
    Color3.fromRGB(255, 214, 255)
)

ensureZoneLabel(rebirthZone, 'Rebirth')
