local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local player = Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local Remotes = require(Shared:WaitForChild('Remotes'))
local NumberFormat = require(Shared:WaitForChild('NumberFormat'))
local Constants = require(Shared:WaitForChild('Constants'))

local screenGui = Instance.new('ScreenGui')
screenGui.Name = 'ScoreGui'
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local scoreLabel = Instance.new('TextLabel')
scoreLabel.Name = 'ScoreLabel'
scoreLabel.Size = UDim2.fromOffset(220, 48)
scoreLabel.Position = UDim2.fromOffset(16, 16)
scoreLabel.BackgroundTransparency = 0.3
scoreLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
scoreLabel.TextXAlignment = Enum.TextXAlignment.Left
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.TextSize = 26
scoreLabel.Text = 'Score: 0'
scoreLabel.Parent = screenGui

local corner = Instance.new('UICorner')
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = scoreLabel

local rebirthsLabel = scoreLabel:Clone()
rebirthsLabel.Name = 'RebirthsLabel'
rebirthsLabel.Position = UDim2.fromOffset(16, 72)
rebirthsLabel.Text = 'Rebirths: 0'
rebirthsLabel.Parent = screenGui

local function setScoreAndRebirths(score: number, rebirths: number)
    scoreLabel.Text = string.format('Score: %s', NumberFormat.formatCompact(score))
    rebirthsLabel.Text = string.format('Rebirths: %s', NumberFormat.formatCompact(rebirths))
end

local scoreUpdatedEvent = Remotes.waitForScoreUpdatedEvent()
local adminScoreMultiplyRequestEvent = Remotes.waitForAdminScoreMultiplyRequestEvent()
local adminStateUpdatedEvent = Remotes.waitForAdminStateUpdatedEvent()

local adminPanel = Instance.new('Frame')
adminPanel.Name = 'AdminPanel'
adminPanel.Size = UDim2.fromOffset(220, 128)
adminPanel.Position = UDim2.fromOffset(16, 128)
adminPanel.BackgroundTransparency = 0.3
adminPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
adminPanel.Visible = false
adminPanel.Parent = screenGui

local adminPanelCorner = corner:Clone()
adminPanelCorner.Parent = adminPanel

local adminLabel = Instance.new('TextLabel')
adminLabel.Name = 'AdminLabel'
adminLabel.Size = UDim2.fromOffset(220, 32)
adminLabel.Position = UDim2.fromOffset(0, 0)
adminLabel.BackgroundTransparency = 1
adminLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
adminLabel.TextXAlignment = Enum.TextXAlignment.Center
adminLabel.Font = Enum.Font.GothamBold
adminLabel.TextSize = 18
adminLabel.Text = 'Admin Panel'
adminLabel.Parent = adminPanel

local function createMultiplierButton(multiplier: number, index: number): TextButton
    local button = Instance.new('TextButton')
    button.Name = string.format('MultiplyButton%s', tostring(multiplier))
    button.Size = UDim2.fromOffset(188, 36)
    button.Position = UDim2.fromOffset(16, 36 + ((index - 1) * 44))
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 16
    button.Text = string.format('Increase Score %sx', tostring(multiplier))
    button.Parent = adminPanel

    local buttonCorner = corner:Clone()
    buttonCorner.Parent = button

    button.Activated:Connect(function()
        adminScoreMultiplyRequestEvent:FireServer(multiplier)
    end)

    return button
end

for index, multiplier in ipairs(Constants.ADMIN_SCORE_MULTIPLIERS) do
    createMultiplierButton(multiplier, index)
end

scoreUpdatedEvent.OnClientEvent:Connect(function(score: number, rebirths: number)
    setScoreAndRebirths(score, rebirths)
end)

adminStateUpdatedEvent.OnClientEvent:Connect(function(isAdmin: boolean)
    adminPanel.Visible = isAdmin
end)
