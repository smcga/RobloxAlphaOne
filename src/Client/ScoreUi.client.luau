local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local player = Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local Remotes = require(Shared:WaitForChild('Remotes'))
local NumberFormat = require(Shared:WaitForChild('NumberFormat'))

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
scoreUpdatedEvent.OnClientEvent:Connect(function(score: number, rebirths: number)
    setScoreAndRebirths(score, rebirths)
end)
