local Workspace = game:GetService('Workspace')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

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

local function applyDecorShape(part: Part, shapeName: WorldDecorLogic.DecorShape)
    if shapeName == 'Cylinder' then
        part.Shape = Enum.PartType.Cylinder
    elseif shapeName == 'Ball' then
        part.Shape = Enum.PartType.Ball
    else
        part.Shape = Enum.PartType.Block
    end
end

local function ensureDecorPart(parent: Instance, spec: WorldDecorLogic.DecorSpec)
    local existing = parent:FindFirstChild(spec.name)
    local part: Part

    if existing and existing:IsA('Part') then
        part = existing
    else
        part = Instance.new('Part')
        part.Name = spec.name
        part.Parent = parent
    end

    part.Anchored = true
    part.Size = toVector3(spec.size)
    part.Position = toVector3(spec.position)
    part.Color = toColor3(spec.color)
    part.Material = DECOR_MATERIALS[spec.material] or Enum.Material.SmoothPlastic
    part.Transparency = spec.transparency or 0
    part.CanCollide = true
    applyDecorShape(part, spec.shape)
end

local function ensureWorldDecor()
    local decorFolder = Workspace:FindFirstChild('WorldDecor')
    if not decorFolder or not decorFolder:IsA('Folder') then
        decorFolder = Instance.new('Folder')
        decorFolder.Name = 'WorldDecor'
        decorFolder.Parent = Workspace
    end

    for _, spec in WorldDecorLogic.getDecorSpecs() do
        ensureDecorPart(decorFolder, spec)
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
    if existing and existing:IsA('BasePart') then
        return existing
    end

    local zone = Instance.new('Part')
    zone.Name = zoneName
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

    local highlight = Instance.new('Highlight')
    highlight.Name = 'ZoneHighlight'
    highlight.FillTransparency = 0.75
    highlight.OutlineColor = outlineColor
    highlight.OutlineTransparency = 0
    highlight.Adornee = zone
    highlight.Parent = zone

    return zone
end

local function ensureZoneLabel(zone: BasePart, text: string)
    local existing = zone:FindFirstChild('ZoneBillboard')
    if existing and existing:IsA('BillboardGui') then
        return
    end

    local billboardGui = Instance.new('BillboardGui')
    billboardGui.Name = 'ZoneBillboard'
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.fromOffset(220, 64)
    billboardGui.StudsOffset = Vector3.new(0, 6, 0)
    billboardGui.Parent = zone

    local label = Instance.new('TextLabel')
    label.Name = 'ZoneLabel'
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.TextStrokeTransparency = 0.2
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.Parent = billboardGui
end

ensureBaseplate()
ensureWorldDecor()
local scoreZone = ensureZone(
    Constants.BLUE_ZONE_NAME,
    Constants.BLUE_ZONE_CENTER,
    Constants.BLUE_ZONE_RADIUS,
    Constants.BLUE_ZONE_HEIGHT,
    Color3.fromRGB(0, 170, 255),
    Color3.fromRGB(167, 230, 255)
)
local highScoreZone = ensureZone(
    Constants.RED_ZONE_NAME,
    Constants.RED_ZONE_CENTER,
    Constants.RED_ZONE_RADIUS,
    Constants.RED_ZONE_HEIGHT,
    Color3.fromRGB(255, 60, 60),
    Color3.fromRGB(255, 170, 170)
)
local rebirthZone = ensureZone(
    Constants.REBIRTH_ZONE_NAME,
    Constants.REBIRTH_ZONE_CENTER,
    Constants.REBIRTH_ZONE_RADIUS,
    Constants.REBIRTH_ZONE_HEIGHT,
    Color3.fromRGB(255, 0, 255),
    Color3.fromRGB(255, 214, 255)
)
local eighteenHundredsZone = ensureZone(
    Constants.EIGHTEEN_HUNDREDS_ZONE_NAME,
    Constants.EIGHTEEN_HUNDREDS_ZONE_CENTER,
    Constants.EIGHTEEN_HUNDREDS_ZONE_RADIUS,
    Constants.EIGHTEEN_HUNDREDS_ZONE_HEIGHT,
    Color3.fromRGB(255, 170, 0),
    Color3.fromRGB(255, 234, 181)
)

ensureZoneLabel(scoreZone, 'Score')
ensureZoneLabel(highScoreZone, 'High Score')
ensureZoneLabel(rebirthZone, 'Rebirth')
ensureZoneLabel(eighteenHundredsZone, "1700's")
