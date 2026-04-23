local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')

local player = Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')
local camera = workspace.CurrentCamera

local Shared = ReplicatedStorage:WaitForChild('Shared')
local Constants = require(Shared:WaitForChild('Constants'))
local NumberFormat = require(Shared:WaitForChild('NumberFormat'))
local RankProgressionLogic = require(Shared:WaitForChild('RankProgressionLogic'))
local Remotes = require(Shared:WaitForChild('Remotes'))
local ScorePopupLogic = require(Shared:WaitForChild('ScorePopupLogic'))
local ZoneUnlockUiLogic = require(Shared:WaitForChild('ZoneUnlockUiLogic'))

local RARITY_COLORS = {
    green = Color3.fromRGB(126, 211, 122),
    blue = Color3.fromRGB(87, 174, 255),
    purple = Color3.fromRGB(188, 126, 255),
    orange = Color3.fromRGB(255, 166, 87),
    gold = Color3.fromRGB(255, 222, 89),
}

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

local nextUnlockLabel = scoreLabel:Clone()
nextUnlockLabel.Name = 'NextUnlockLabel'
nextUnlockLabel.Size = UDim2.fromOffset(460, 48)
nextUnlockLabel.Position = UDim2.fromOffset(16, 128)
nextUnlockLabel.TextSize = 18
nextUnlockLabel.Text = 'Next: Age of Brass at 600 (600 to go)'
nextUnlockLabel.Parent = screenGui

local rankPanel = Instance.new('Frame')
rankPanel.Name = 'RankPanel'
rankPanel.Size = UDim2.fromOffset(460, 88)
rankPanel.Position = UDim2.fromOffset(16, 184)
rankPanel.BackgroundTransparency = 0.3
rankPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
rankPanel.Parent = screenGui

local rankPanelCorner = corner:Clone()
rankPanelCorner.Parent = rankPanel

local rankNameLabel = Instance.new('TextLabel')
rankNameLabel.Name = 'RankNameLabel'
rankNameLabel.Size = UDim2.fromOffset(428, 24)
rankNameLabel.Position = UDim2.fromOffset(16, 10)
rankNameLabel.BackgroundTransparency = 1
rankNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
rankNameLabel.TextXAlignment = Enum.TextXAlignment.Left
rankNameLabel.Font = Enum.Font.GothamBold
rankNameLabel.TextSize = 18
rankNameLabel.Text = 'Pebble Counter'
rankNameLabel.Parent = rankPanel

local rankProgressTrack = Instance.new('Frame')
rankProgressTrack.Name = 'ProgressTrack'
rankProgressTrack.Size = UDim2.fromOffset(428, 20)
rankProgressTrack.Position = UDim2.fromOffset(16, 38)
rankProgressTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
rankProgressTrack.Parent = rankPanel

local rankProgressTrackCorner = corner:Clone()
rankProgressTrackCorner.Parent = rankProgressTrack

local rankProgressFill = Instance.new('Frame')
rankProgressFill.Name = 'ProgressFill'
rankProgressFill.Size = UDim2.fromScale(0, 1)
rankProgressFill.BackgroundColor3 = Color3.fromRGB(64, 205, 136)
rankProgressFill.Parent = rankProgressTrack

local rankProgressFillCorner = corner:Clone()
rankProgressFillCorner.Parent = rankProgressFill

local rankProgressTextLabel = Instance.new('TextLabel')
rankProgressTextLabel.Name = 'ProgressTextLabel'
rankProgressTextLabel.Size = UDim2.fromOffset(428, 18)
rankProgressTextLabel.Position = UDim2.fromOffset(16, 62)
rankProgressTextLabel.BackgroundTransparency = 1
rankProgressTextLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
rankProgressTextLabel.TextXAlignment = Enum.TextXAlignment.Left
rankProgressTextLabel.Font = Enum.Font.Gotham
rankProgressTextLabel.TextSize = 14
rankProgressTextLabel.Text = '0 / 1,000 to Bead Keeper'
rankProgressTextLabel.Parent = rankPanel

local luckyChestPanel = Instance.new('Frame')
luckyChestPanel.Name = 'LuckyChestPanel'
luckyChestPanel.Size = UDim2.fromOffset(320, 108)
luckyChestPanel.Position = UDim2.new(1, -336, 0, 16)
luckyChestPanel.BackgroundTransparency = 0.22
luckyChestPanel.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
luckyChestPanel.Parent = screenGui

local luckyPanelCorner = corner:Clone()
luckyPanelCorner.Parent = luckyChestPanel

local luckyChestTitle = Instance.new('TextLabel')
luckyChestTitle.Name = 'LuckyChestTitle'
luckyChestTitle.Size = UDim2.fromOffset(288, 28)
luckyChestTitle.Position = UDim2.fromOffset(16, 8)
luckyChestTitle.BackgroundTransparency = 1
luckyChestTitle.Text = 'Lucky Chest'
luckyChestTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
luckyChestTitle.Font = Enum.Font.GothamBold
luckyChestTitle.TextXAlignment = Enum.TextXAlignment.Left
luckyChestTitle.TextSize = 20
luckyChestTitle.Parent = luckyChestPanel

local luckyChestCooldownLabel = Instance.new('TextLabel')
luckyChestCooldownLabel.Name = 'LuckyChestCooldownLabel'
luckyChestCooldownLabel.Size = UDim2.fromOffset(288, 20)
luckyChestCooldownLabel.Position = UDim2.fromOffset(16, 34)
luckyChestCooldownLabel.BackgroundTransparency = 1
luckyChestCooldownLabel.Text = 'Next chest: ready now!'
luckyChestCooldownLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
luckyChestCooldownLabel.Font = Enum.Font.Gotham
luckyChestCooldownLabel.TextXAlignment = Enum.TextXAlignment.Left
luckyChestCooldownLabel.TextSize = 14
luckyChestCooldownLabel.Parent = luckyChestPanel

local luckyChestButton = Instance.new('TextButton')
luckyChestButton.Name = 'LuckyChestButton'
luckyChestButton.Size = UDim2.fromOffset(288, 40)
luckyChestButton.Position = UDim2.fromOffset(16, 60)
luckyChestButton.BackgroundColor3 = Color3.fromRGB(53, 103, 62)
luckyChestButton.Text = 'Open Lucky Chest'
luckyChestButton.TextColor3 = Color3.fromRGB(255, 255, 255)
luckyChestButton.Font = Enum.Font.GothamBold
luckyChestButton.TextSize = 16
luckyChestButton.Parent = luckyChestPanel

local luckyButtonCorner = corner:Clone()
luckyButtonCorner.Parent = luckyChestButton

local chestSpinOverlay = Instance.new('Frame')
chestSpinOverlay.Name = 'ChestSpinOverlay'
chestSpinOverlay.Size = UDim2.fromScale(1, 1)
chestSpinOverlay.BackgroundColor3 = Color3.fromRGB(5, 8, 12)
chestSpinOverlay.BackgroundTransparency = 1
chestSpinOverlay.Visible = false
chestSpinOverlay.Parent = screenGui

local chestCenterPanel = Instance.new('Frame')
chestCenterPanel.Name = 'ChestCenterPanel'
chestCenterPanel.Size = UDim2.fromOffset(580, 260)
chestCenterPanel.AnchorPoint = Vector2.new(0.5, 0.5)
chestCenterPanel.Position = UDim2.fromScale(0.5, 0.5)
chestCenterPanel.BackgroundTransparency = 0.18
chestCenterPanel.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
chestCenterPanel.Parent = chestSpinOverlay

local chestCenterCorner = corner:Clone()
chestCenterCorner.Parent = chestCenterPanel

local chestCategoryLabel = Instance.new('TextLabel')
chestCategoryLabel.Name = 'ChestCategoryLabel'
chestCategoryLabel.Size = UDim2.fromOffset(548, 44)
chestCategoryLabel.Position = UDim2.fromOffset(16, 16)
chestCategoryLabel.BackgroundTransparency = 1
chestCategoryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
chestCategoryLabel.Font = Enum.Font.GothamBold
chestCategoryLabel.TextSize = 32
chestCategoryLabel.Text = 'Spinning category...'
chestCategoryLabel.Parent = chestCenterPanel

local chestItemLabel = chestCategoryLabel:Clone()
chestItemLabel.Name = 'ChestItemLabel'
chestItemLabel.Position = UDim2.fromOffset(16, 72)
chestItemLabel.Text = 'Spinning reward...'
chestItemLabel.Parent = chestCenterPanel

local chestRewardLabel = chestCategoryLabel:Clone()
chestRewardLabel.Name = 'ChestRewardLabel'
chestRewardLabel.Position = UDim2.fromOffset(16, 150)
chestRewardLabel.TextSize = 28
chestRewardLabel.Text = ''
chestRewardLabel.Parent = chestCenterPanel

local nextLuckyChestOpenAt = 0
local isChestSpinPlaying = false
local previousScore: number? = nil

local function updateAgeZoneLabelVisibility(score: number)
    for _, zoneConfig in ipairs(Constants.AGE_ZONE_CONFIGS) do
        local zone = workspace:FindFirstChild(zoneConfig.zoneName)
        if zone and zone:IsA('BasePart') then
            local billboard = zone:FindFirstChild('ZoneBillboard')
            if billboard and billboard:IsA('BillboardGui') then
                billboard.Enabled =
                    ZoneUnlockUiLogic.isZoneUnlocked(score, zoneConfig.requiredScore)
            end
        end
    end
end

local function setScoreAndRebirths(score: number, rebirths: number)
    scoreLabel.Text = string.format('Score: %s', NumberFormat.formatCompact(score))
    rebirthsLabel.Text = string.format('Rebirths: %s', NumberFormat.formatCompact(rebirths))
    nextUnlockLabel.Text = ZoneUnlockUiLogic.buildNextUnlockText(
        score,
        Constants.AGE_ZONE_CONFIGS,
        NumberFormat.formatCompact
    )
    updateAgeZoneLabelVisibility(score)

    local rankProgress = RankProgressionLogic.getRankProgress(score, Constants.RANK_CONFIGS)
    rankNameLabel.Text = rankProgress.currentRankName
    rankProgressFill.Size = UDim2.fromScale(rankProgress.progressAlpha, 1)

    if rankProgress.nextRankName and rankProgress.nextRankRequiredScore then
        local progressValue = rankProgress.scoreIntoCurrentRank
        local neededValue = rankProgress.nextRankRequiredScore
            - rankProgress.currentRankRequiredScore
        rankProgressTextLabel.Text = string.format(
            '%s / %s to %s',
            NumberFormat.formatCompact(progressValue),
            NumberFormat.formatCompact(neededValue),
            rankProgress.nextRankName
        )
    else
        rankProgressTextLabel.Text = 'Max rank reached'
    end
end

local POPUP_WIDTH = 160
local POPUP_HEIGHT = 60

local function showScoreIncreasePopup(increase: number)
    local popup = Instance.new('TextLabel')
    popup.Name = 'ScoreIncreasePopup'
    popup.Size = UDim2.fromOffset(POPUP_WIDTH, POPUP_HEIGHT)
    popup.AnchorPoint = Vector2.new(0, 0)
    popup.BackgroundTransparency = 1
    popup.TextColor3 = Color3.fromRGB(120, 255, 120)
    popup.TextStrokeTransparency = 0.25
    popup.TextScaled = true
    popup.Font = Enum.Font.GothamBlack
    popup.Text = ScorePopupLogic.formatIncreaseText(increase, NumberFormat.formatCompact)

    local viewportSize = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local randomX = math.random()
    local randomY = math.random()
    local x, y = ScorePopupLogic.getRandomPopupPosition(
        viewportSize.X,
        viewportSize.Y,
        POPUP_WIDTH,
        POPUP_HEIGHT,
        randomX,
        randomY
    )

    popup.Position = UDim2.fromOffset(x, y)
    popup.Parent = screenGui

    local floatTween = TweenService:Create(
        popup,
        TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Position = UDim2.fromOffset(x, y - 42),
            TextTransparency = 1,
            TextStrokeTransparency = 1,
        }
    )

    floatTween.Completed:Connect(function()
        popup:Destroy()
    end)

    floatTween:Play()
end

local function formatCountdown(seconds: number): string
    local wholeSeconds = math.max(math.floor(seconds), 0)
    local minutes = math.floor(wholeSeconds / 60)
    local remainingSeconds = wholeSeconds % 60
    return string.format('%02d:%02d', minutes, remainingSeconds)
end

local function updateLuckyChestUi()
    local now = os.time()
    local remaining = nextLuckyChestOpenAt - now
    local ready = remaining <= 0

    luckyChestCooldownLabel.Text = ready and 'Next chest: ready now!'
        or string.format('Next chest in: %s', formatCountdown(remaining))
    luckyChestButton.Active = ready and not isChestSpinPlaying
    luckyChestButton.AutoButtonColor = ready and not isChestSpinPlaying
    luckyChestButton.BackgroundColor3 = ready and Color3.fromRGB(53, 103, 62)
        or Color3.fromRGB(63, 63, 63)
end

local function animateSpinLabel(label: TextLabel, options, finalName: string, finalRarity: string)
    for _ = 1, 12 do
        local option = options[math.random(1, #options)]
        label.Text = option.displayName
        label.TextColor3 = RARITY_COLORS[option.rarity] or Color3.fromRGB(255, 255, 255)
        task.wait(0.06)
    end

    label.Text = finalName
    label.TextColor3 = RARITY_COLORS[finalRarity] or Color3.fromRGB(255, 255, 255)
end

local function playChestSpinVisual(spinResult)
    isChestSpinPlaying = true
    updateLuckyChestUi()

    chestSpinOverlay.Visible = true
    chestSpinOverlay.BackgroundTransparency = 1
    chestRewardLabel.Text = ''

    TweenService:Create(
        chestSpinOverlay,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0.35 }
    ):Play()

    chestCategoryLabel.Text = 'Spinning category...'
    chestCategoryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    chestItemLabel.Text = 'Spinning reward...'
    chestItemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

    animateSpinLabel(
        chestCategoryLabel,
        spinResult.categorySpinOptions,
        spinResult.categoryDisplayName,
        spinResult.categoryRarity
    )

    task.wait(0.2)

    animateSpinLabel(
        chestItemLabel,
        spinResult.itemSpinOptions,
        spinResult.item.displayName,
        spinResult.item.rarity
    )

    if spinResult.scoreBoostMultiplier > 1 then
        chestRewardLabel.Text = string.format(
            'Reward: %sx score for %ss!',
            tostring(spinResult.scoreBoostMultiplier),
            tostring(spinResult.scoreBoostDurationSeconds)
        )
    elseif spinResult.scoreGranted > 0 then
        chestRewardLabel.Text =
            string.format('Reward: +%s Score', NumberFormat.formatCompact(spinResult.scoreGranted))
    elseif spinResult.rebirthsGranted > 0 then
        chestRewardLabel.Text = string.format(
            'Reward: +%s Rebirths',
            NumberFormat.formatCompact(spinResult.rebirthsGranted)
        )
    else
        chestRewardLabel.Text = string.format('Reward: %s unlocked!', spinResult.item.displayName)
    end

    chestRewardLabel.TextColor3 = RARITY_COLORS[spinResult.item.rarity]
        or Color3.fromRGB(255, 255, 255)

    task.wait(2)

    local fade = TweenService:Create(
        chestSpinOverlay,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }
    )
    fade:Play()
    fade.Completed:Wait()

    chestSpinOverlay.Visible = false
    isChestSpinPlaying = false
    updateLuckyChestUi()
end

local scoreUpdatedEvent = Remotes.waitForScoreUpdatedEvent()
local adminScoreMultiplyRequestEvent = Remotes.waitForAdminScoreMultiplyRequestEvent()
local adminResetProgressRequestEvent = Remotes.waitForAdminResetProgressRequestEvent()
local adminStateUpdatedEvent = Remotes.waitForAdminStateUpdatedEvent()
local luckyChestStatusUpdatedEvent = Remotes.waitForLuckyChestStatusUpdatedEvent()
local luckyChestOpenRequestEvent = Remotes.waitForLuckyChestOpenRequestEvent()
local luckyChestOpenedEvent = Remotes.waitForLuckyChestOpenedEvent()

local adminPanel = Instance.new('Frame')
adminPanel.Name = 'AdminPanel'
adminPanel.Size = UDim2.fromOffset(220, 214)
adminPanel.Position = UDim2.fromOffset(16, 280)
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

local resetProgressButton = Instance.new('TextButton')
resetProgressButton.Name = 'ResetProgressButton'
resetProgressButton.Size = UDim2.fromOffset(188, 36)
resetProgressButton.Position = UDim2.fromOffset(16, 36 + (#Constants.ADMIN_SCORE_MULTIPLIERS * 44))
resetProgressButton.BackgroundColor3 = Color3.fromRGB(135, 48, 48)
resetProgressButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetProgressButton.Font = Enum.Font.GothamBold
resetProgressButton.TextSize = 16
resetProgressButton.Text = 'Reset Score + Rebirths'
resetProgressButton.Parent = adminPanel

local resetProgressButtonCorner = corner:Clone()
resetProgressButtonCorner.Parent = resetProgressButton

local resetConfirmationLabel = Instance.new('TextLabel')
resetConfirmationLabel.Name = 'ResetConfirmationLabel'
resetConfirmationLabel.Size = UDim2.fromOffset(188, 30)
resetConfirmationLabel.Position = UDim2.fromOffset(16, 176)
resetConfirmationLabel.BackgroundTransparency = 1
resetConfirmationLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
resetConfirmationLabel.TextXAlignment = Enum.TextXAlignment.Center
resetConfirmationLabel.TextYAlignment = Enum.TextYAlignment.Center
resetConfirmationLabel.Font = Enum.Font.Gotham
resetConfirmationLabel.TextSize = 14
resetConfirmationLabel.TextWrapped = true
resetConfirmationLabel.Text = ''
resetConfirmationLabel.Parent = adminPanel

local resetConfirmationPending = false
local resetConfirmationToken = 0
local RESET_CONFIRMATION_TIMEOUT_SECONDS = 4

local function clearResetConfirmationPrompt()
    resetConfirmationPending = false
    resetProgressButton.Text = 'Reset Score + Rebirths'
    resetConfirmationLabel.Text = ''
end

resetProgressButton.Activated:Connect(function()
    if not resetConfirmationPending then
        resetConfirmationPending = true
        resetConfirmationToken += 1
        local currentToken = resetConfirmationToken

        resetProgressButton.Text = 'Click Again to Confirm'
        resetConfirmationLabel.Text = 'Are you sure? This permanently resets your progress.'

        task.delay(RESET_CONFIRMATION_TIMEOUT_SECONDS, function()
            if resetConfirmationPending and currentToken == resetConfirmationToken then
                clearResetConfirmationPrompt()
            end
        end)

        return
    end

    adminResetProgressRequestEvent:FireServer()
    clearResetConfirmationPrompt()
end)

local previousScore: number? = nil
luckyChestButton.Activated:Connect(function()
    if isChestSpinPlaying then
        return
    end

    luckyChestOpenRequestEvent:FireServer()
end)

scoreUpdatedEvent.OnClientEvent:Connect(function(score: number, rebirths: number)
    local increase = ScorePopupLogic.getPositiveIncrease(previousScore, score)
    if increase then
        showScoreIncreasePopup(increase)
    end

    previousScore = score
    setScoreAndRebirths(score, rebirths)
end)

adminStateUpdatedEvent.OnClientEvent:Connect(function(isAdmin: boolean)
    adminPanel.Visible = isAdmin
    if not isAdmin then
        clearResetConfirmationPrompt()
    end
end)

luckyChestStatusUpdatedEvent.OnClientEvent:Connect(function(serverNextLuckyChestOpenAt: number)
    nextLuckyChestOpenAt = serverNextLuckyChestOpenAt
    updateLuckyChestUi()
end)

luckyChestOpenedEvent.OnClientEvent:Connect(function(spinResult, serverNextLuckyChestOpenAt: number)
    nextLuckyChestOpenAt = serverNextLuckyChestOpenAt
    task.spawn(function()
        playChestSpinVisual(spinResult)
    end)
end)

task.spawn(function()
    while true do
        updateLuckyChestUi()
        task.wait(1)
    end
end)
