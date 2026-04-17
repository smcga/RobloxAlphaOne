local Workspace = game:GetService('Workspace')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local Constants = require(Shared:WaitForChild('Constants'))

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

ensureZoneLabel(scoreZone, 'Score')
ensureZoneLabel(highScoreZone, 'High Score')
ensureZoneLabel(rebirthZone, 'Rebirth')
