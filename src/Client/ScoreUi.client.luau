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
local RebirthLogic = require(Shared:WaitForChild('RebirthLogic'))
local RankUiLayoutLogic = require(Shared:WaitForChild('RankUiLayoutLogic'))
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

local ageStatusPanel = Instance.new('Frame')
ageStatusPanel.Name = 'AgeStatusPanel'
ageStatusPanel.Size = UDim2.fromOffset(460, 100)
ageStatusPanel.AnchorPoint = Vector2.new(0.5, 0)
ageStatusPanel.Position = UDim2.new(0.5, 0, 0, 16)
ageStatusPanel.BackgroundTransparency = 0.12
ageStatusPanel.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
ageStatusPanel.Parent = screenGui

local ageStatusCorner = corner:Clone()
ageStatusCorner.Parent = ageStatusPanel

local ageStatusStroke = Instance.new('UIStroke')
ageStatusStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ageStatusStroke.Color = Color3.fromRGB(86, 106, 148)
ageStatusStroke.Thickness = 1
ageStatusStroke.Transparency = 0.25
ageStatusStroke.Parent = ageStatusPanel

local ageStatusPadding = Instance.new('UIPadding')
ageStatusPadding.PaddingTop = UDim.new(0, 10)
ageStatusPadding.PaddingBottom = UDim.new(0, 10)
ageStatusPadding.PaddingLeft = UDim.new(0, 14)
ageStatusPadding.PaddingRight = UDim.new(0, 14)
ageStatusPadding.Parent = ageStatusPanel

local ageStatusLayout = Instance.new('UIListLayout')
ageStatusLayout.FillDirection = Enum.FillDirection.Vertical
ageStatusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
ageStatusLayout.VerticalAlignment = Enum.VerticalAlignment.Top
ageStatusLayout.Padding = UDim.new(0, 8)
ageStatusLayout.Parent = ageStatusPanel

local currentAgeLabel = Instance.new('TextLabel')
currentAgeLabel.Name = 'CurrentAgeLabel'
currentAgeLabel.Size = UDim2.new(1, 0, 0, 34)
currentAgeLabel.BackgroundTransparency = 1
currentAgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
currentAgeLabel.TextXAlignment = Enum.TextXAlignment.Left
currentAgeLabel.Font = Enum.Font.GothamBold
currentAgeLabel.TextSize = 22
currentAgeLabel.Text = 'Current Age: Age of Beads'
currentAgeLabel.Parent = ageStatusPanel

local nextUnlockLabel = currentAgeLabel:Clone()
nextUnlockLabel.Name = 'NextUnlockLabel'
nextUnlockLabel.Size = UDim2.new(1, 0, 0, 30)
nextUnlockLabel.TextColor3 = Color3.fromRGB(204, 222, 255)
nextUnlockLabel.Font = Enum.Font.Gotham
nextUnlockLabel.TextSize = 17
nextUnlockLabel.Text = 'Next Age: Age of Brass at 600 (600 to go)'
nextUnlockLabel.Parent = ageStatusPanel

local rankPanelLayout = RankUiLayoutLogic.getRankPanelLayout()

local rankPanel = Instance.new('Frame')
rankPanel.Name = 'RankPanel'
rankPanel.Size = UDim2.fromOffset(rankPanelLayout.width, rankPanelLayout.height)
rankPanel.AnchorPoint = Vector2.new(0.5, 1)
rankPanel.Position = UDim2.new(0.5, 0, 1, -rankPanelLayout.bottomPadding)
rankPanel.BackgroundTransparency = 0.22
rankPanel.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
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
luckyChestPanel.Size = UDim2.fromOffset(320, 154)
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

local rewardsButton = luckyChestButton:Clone()
rewardsButton.Name = 'RewardsButton'
rewardsButton.Position = UDim2.fromOffset(16, 16 + 108)
rewardsButton.Size = UDim2.fromOffset(160, 36)
rewardsButton.BackgroundColor3 = Color3.fromRGB(70, 82, 128)
rewardsButton.Text = 'Rewards'
rewardsButton.Parent = luckyChestPanel

local rewardsOverlay = Instance.new('TextButton')
rewardsOverlay.Name = 'RewardsOverlay'
rewardsOverlay.Size = UDim2.fromScale(1, 1)
rewardsOverlay.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
rewardsOverlay.BackgroundTransparency = 0.35
rewardsOverlay.AutoButtonColor = false
rewardsOverlay.Text = ''
rewardsOverlay.Visible = false
rewardsOverlay.ZIndex = 10
rewardsOverlay.Parent = screenGui

local rewardsModal = Instance.new('Frame')
rewardsModal.Name = 'RewardsModal'
rewardsModal.Size = UDim2.fromOffset(540, 430)
rewardsModal.AnchorPoint = Vector2.new(0.5, 0.5)
rewardsModal.Position = UDim2.fromScale(0.5, 0.5)
rewardsModal.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
rewardsModal.BackgroundTransparency = 0.08
rewardsModal.ZIndex = 11
rewardsModal.Parent = rewardsOverlay
corner:Clone().Parent = rewardsModal

local rewardsTitle = Instance.new('TextLabel')
rewardsTitle.Size = UDim2.fromOffset(508, 30)
rewardsTitle.Position = UDim2.fromOffset(16, 10)
rewardsTitle.BackgroundTransparency = 1
rewardsTitle.Text = 'Rewards Inventory'
rewardsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
rewardsTitle.TextXAlignment = Enum.TextXAlignment.Left
rewardsTitle.Font = Enum.Font.GothamBold
rewardsTitle.TextSize = 22
rewardsTitle.ZIndex = 12
rewardsTitle.Parent = rewardsModal

local closeRewardsButton = Instance.new('TextButton')
closeRewardsButton.Size = UDim2.fromOffset(110, 30)
closeRewardsButton.Position = UDim2.fromOffset(414, 10)
closeRewardsButton.BackgroundColor3 = Color3.fromRGB(90, 56, 56)
closeRewardsButton.Text = 'Close'
closeRewardsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeRewardsButton.Font = Enum.Font.GothamBold
closeRewardsButton.TextSize = 14
closeRewardsButton.ZIndex = 12
closeRewardsButton.Parent = rewardsModal
corner:Clone().Parent = closeRewardsButton

local hatsLabel = rewardsTitle:Clone()
hatsLabel.Size = UDim2.fromOffset(248, 24)
hatsLabel.Position = UDim2.fromOffset(16, 48)
hatsLabel.Text = 'Hats'
hatsLabel.TextSize = 18
hatsLabel.Parent = rewardsModal

local mountsLabel = hatsLabel:Clone()
mountsLabel.Position = UDim2.fromOffset(276, 48)
mountsLabel.Text = 'Vehicle Mounts'
mountsLabel.Parent = rewardsModal

local hatsListFrame = Instance.new('ScrollingFrame')
hatsListFrame.Size = UDim2.fromOffset(248, 286)
hatsListFrame.Position = UDim2.fromOffset(16, 76)
hatsListFrame.BackgroundColor3 = Color3.fromRGB(32, 38, 48)
hatsListFrame.BackgroundTransparency = 0.1
hatsListFrame.ScrollBarThickness = 8
hatsListFrame.CanvasSize = UDim2.fromOffset(0, 0)
hatsListFrame.ZIndex = 12
hatsListFrame.Parent = rewardsModal
corner:Clone().Parent = hatsListFrame

local mountsListFrame = hatsListFrame:Clone()
mountsListFrame.Position = UDim2.fromOffset(276, 76)
mountsListFrame.Parent = rewardsModal

local rewardsStatusLabel = Instance.new('TextLabel')
rewardsStatusLabel.Size = UDim2.fromOffset(508, 40)
rewardsStatusLabel.Position = UDim2.fromOffset(16, 374)
rewardsStatusLabel.BackgroundTransparency = 1
rewardsStatusLabel.Text = ''
rewardsStatusLabel.TextWrapped = true
rewardsStatusLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
rewardsStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
rewardsStatusLabel.Font = Enum.Font.Gotham
rewardsStatusLabel.TextSize = 14
rewardsStatusLabel.ZIndex = 12
rewardsStatusLabel.Parent = rewardsModal

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
local availableHats = {}
local availableVehicleMounts = {}
local equippedHatId: string? = nil
local equippedVehicleMountId: string? = nil

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

local REBIRTH_CONFIG: RebirthLogic.RebirthConfig = {
    baseRequirementScore = Constants.REBIRTH_BASE_REQUIREMENT_SCORE,
    requirementGrowthPerRebirth = Constants.REBIRTH_REQUIREMENT_GROWTH_PER_REBIRTH,
    scoreToBonusPower = Constants.REBIRTH_SCORE_TO_BONUS_POWER,
    scoreToBonusScale = Constants.REBIRTH_SCORE_TO_BONUS_SCALE,
    maxBonusRebirthsFromScore = Constants.REBIRTH_MAX_BONUS_FROM_SCORE,
    hourlyFinalZoneBonus = {
        chancePerHour = Constants.REBIRTH_HOURLY_FINAL_ZONE_BONUS_CHANCE,
        activeWindowSeconds = Constants.REBIRTH_HOURLY_FINAL_ZONE_BONUS_WINDOW_SECONDS,
        bonusRebirths = Constants.REBIRTH_HOURLY_FINAL_ZONE_BONUS_REBIRTHS,
    },
}

local function updateRebirthZoneLabel(score: number, rebirths: number)
    local rebirthZone = workspace:FindFirstChild(Constants.REBIRTH_ZONE_NAME)
    if not rebirthZone or not rebirthZone:IsA('BasePart') then
        return
    end

    local billboard = rebirthZone:FindFirstChild('ZoneBillboard')
    if not billboard or not billboard:IsA('BillboardGui') then
        return
    end

    local label = billboard:FindFirstChild('ZoneLabel')
    if not label or not label:IsA('TextLabel') then
        return
    end

    local requiredScore = RebirthLogic.getRequiredScore(rebirths, REBIRTH_CONFIG)
    local previewGrant =
        RebirthLogic.getPreviewGrant(score, rebirths, false, os.time(), REBIRTH_CONFIG)
    label.Text = string.format(
        'Rebirth\n<font size="18">Cost: %s score • Next grant: +%s rebirths</font>',
        NumberFormat.formatCompact(requiredScore),
        NumberFormat.formatCompact(previewGrant)
    )
end

local function setScoreAndRebirths(score: number, rebirths: number)
    scoreLabel.Text = string.format('Score: %s', NumberFormat.formatCompact(score))
    rebirthsLabel.Text = string.format('Rebirths: %s', NumberFormat.formatCompact(rebirths))
    currentAgeLabel.Text = ZoneUnlockUiLogic.buildCurrentAgeText(score, Constants.AGE_ZONE_CONFIGS)
    local nextUnlockText = ZoneUnlockUiLogic.buildNextUnlockText(
        score,
        Constants.AGE_ZONE_CONFIGS,
        NumberFormat.formatCompact
    )
    nextUnlockLabel.Text = string.format('Next Age: %s', nextUnlockText:gsub('^Next:%s*', ''))
    updateAgeZoneLabelVisibility(score)
    updateRebirthZoneLabel(score, rebirths)

    local rankProgress = RankProgressionLogic.getRankProgress(score, Constants.RANK_CONFIGS)
    rankNameLabel.Text = rankProgress.currentRankName
    rankProgressFill.Size = UDim2.fromScale(rankProgress.progressAlpha, 1)
    local currentRankMultiplier = RankProgressionLogic.getScoreMultiplierForRankIndex(
        rankProgress.currentRankIndex,
        Constants.RANK_SCORE_MULTIPLIER_STEP
    )

    if rankProgress.nextRankName and rankProgress.nextRankRequiredScore then
        local nextRankMultiplier = RankProgressionLogic.getScoreMultiplierForRankIndex(
            rankProgress.nextRankIndex or rankProgress.currentRankIndex,
            Constants.RANK_SCORE_MULTIPLIER_STEP
        )
        local progressValue = rankProgress.scoreIntoCurrentRank
        local neededValue = rankProgress.nextRankRequiredScore
            - rankProgress.currentRankRequiredScore
        rankProgressTextLabel.Text = string.format(
            '%s / %s to %s • Rank bonus x%.2f → x%.2f',
            NumberFormat.formatCompact(progressValue),
            NumberFormat.formatCompact(neededValue),
            rankProgress.nextRankName,
            currentRankMultiplier,
            nextRankMultiplier
        )
    else
        rankProgressTextLabel.Text =
            string.format('Max rank reached • Rank bonus x%.2f', currentRankMultiplier)
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
local adminGainRankRequestEvent = Remotes.waitForAdminGainRankRequestEvent()
local adminSkipLuckyChestTimerRequestEvent = Remotes.waitForAdminSkipLuckyChestTimerRequestEvent()
local adminStateUpdatedEvent = Remotes.waitForAdminStateUpdatedEvent()
local luckyChestStatusUpdatedEvent = Remotes.waitForLuckyChestStatusUpdatedEvent()
local luckyChestOpenRequestEvent = Remotes.waitForLuckyChestOpenRequestEvent()
local luckyChestOpenedEvent = Remotes.waitForLuckyChestOpenedEvent()
local adminAddRewardRequestEvent = Remotes.waitForAdminAddRewardRequestEvent()
local adminAddRewardResultEvent = Remotes.waitForAdminAddRewardResultEvent()
local adminRewardCatalogUpdatedEvent = Remotes.waitForAdminRewardCatalogUpdatedEvent()
local equipmentStateUpdatedEvent = Remotes.waitForEquipmentStateUpdatedEvent()
local equipHatRequestEvent = Remotes.waitForEquipHatRequestEvent()
local unequipHatRequestEvent = Remotes.waitForUnequipHatRequestEvent()
local equipVehicleMountRequestEvent = Remotes.waitForEquipVehicleMountRequestEvent()
local unequipVehicleMountRequestEvent = Remotes.waitForUnequipVehicleMountRequestEvent()
local equipmentActionResultEvent = Remotes.waitForEquipmentActionResultEvent()

local adminPanel = Instance.new('Frame')
adminPanel.Name = 'AdminPanel'
adminPanel.Size = UDim2.fromOffset(220, 340)
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

local gainRankButton = Instance.new('TextButton')
gainRankButton.Name = 'GainRankButton'
gainRankButton.Size = UDim2.fromOffset(188, 36)
gainRankButton.Position = UDim2.fromOffset(16, 36 + ((#Constants.ADMIN_SCORE_MULTIPLIERS + 2) * 44))
gainRankButton.BackgroundColor3 = Color3.fromRGB(60, 86, 130)
gainRankButton.TextColor3 = Color3.fromRGB(255, 255, 255)
gainRankButton.Font = Enum.Font.GothamBold
gainRankButton.TextSize = 16
gainRankButton.Text = 'Gain +1 Rank'
gainRankButton.Parent = adminPanel

local gainRankButtonCorner = corner:Clone()
gainRankButtonCorner.Parent = gainRankButton

local skipLuckyChestTimerButton = Instance.new('TextButton')
skipLuckyChestTimerButton.Name = 'SkipLuckyChestTimerButton'
skipLuckyChestTimerButton.Size = UDim2.fromOffset(188, 36)
skipLuckyChestTimerButton.Position =
    UDim2.fromOffset(16, 36 + ((#Constants.ADMIN_SCORE_MULTIPLIERS + 1) * 44))
skipLuckyChestTimerButton.BackgroundColor3 = Color3.fromRGB(53, 103, 62)
skipLuckyChestTimerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
skipLuckyChestTimerButton.Font = Enum.Font.GothamBold
skipLuckyChestTimerButton.TextSize = 16
skipLuckyChestTimerButton.Text = 'Skip Lucky Chest Timer'
skipLuckyChestTimerButton.Parent = adminPanel

local skipLuckyChestTimerButtonCorner = corner:Clone()
skipLuckyChestTimerButtonCorner.Parent = skipLuckyChestTimerButton

local resetConfirmationLabel = Instance.new('TextLabel')
resetConfirmationLabel.Name = 'ResetConfirmationLabel'
resetConfirmationLabel.Size = UDim2.fromOffset(188, 30)
resetConfirmationLabel.Position = UDim2.fromOffset(16, 212)
resetConfirmationLabel.BackgroundTransparency = 1
resetConfirmationLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
resetConfirmationLabel.TextXAlignment = Enum.TextXAlignment.Center
resetConfirmationLabel.TextYAlignment = Enum.TextYAlignment.Center
resetConfirmationLabel.Font = Enum.Font.Gotham
resetConfirmationLabel.TextSize = 14
resetConfirmationLabel.TextWrapped = true
resetConfirmationLabel.Text = ''
resetConfirmationLabel.Parent = adminPanel

local addRewardButton = Instance.new('TextButton')
addRewardButton.Name = 'AddRewardButton'
addRewardButton.Size = UDim2.fromOffset(188, 36)
addRewardButton.Position = UDim2.fromOffset(16, 256)
addRewardButton.BackgroundColor3 = Color3.fromRGB(66, 84, 130)
addRewardButton.TextColor3 = Color3.fromRGB(255, 255, 255)
addRewardButton.Font = Enum.Font.GothamBold
addRewardButton.TextSize = 16
addRewardButton.Text = 'Add Reward'
addRewardButton.Parent = adminPanel

local addRewardButtonCorner = corner:Clone()
addRewardButtonCorner.Parent = addRewardButton

resetConfirmationLabel.Position = UDim2.fromOffset(16, 296)

local addRewardOverlay = Instance.new('TextButton')
addRewardOverlay.Name = 'AddRewardOverlay'
addRewardOverlay.Size = UDim2.fromScale(1, 1)
addRewardOverlay.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
addRewardOverlay.BackgroundTransparency = 0.35
addRewardOverlay.AutoButtonColor = false
addRewardOverlay.Text = ''
addRewardOverlay.Visible = false
addRewardOverlay.ZIndex = 15
addRewardOverlay.Parent = screenGui

local addRewardModal = Instance.new('Frame')
addRewardModal.Name = 'AddRewardModal'
addRewardModal.Size = UDim2.fromOffset(420, 300)
addRewardModal.AnchorPoint = Vector2.new(0.5, 0.5)
addRewardModal.Position = UDim2.fromScale(0.5, 0.5)
addRewardModal.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
addRewardModal.BackgroundTransparency = 0.1
addRewardModal.ZIndex = 16
addRewardModal.Parent = addRewardOverlay

local addRewardModalCorner = corner:Clone()
addRewardModalCorner.Parent = addRewardModal

local addRewardTitle = Instance.new('TextLabel')
addRewardTitle.Size = UDim2.fromOffset(388, 30)
addRewardTitle.Position = UDim2.fromOffset(16, 12)
addRewardTitle.BackgroundTransparency = 1
addRewardTitle.Font = Enum.Font.GothamBold
addRewardTitle.TextSize = 20
addRewardTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
addRewardTitle.TextXAlignment = Enum.TextXAlignment.Left
addRewardTitle.Text = 'Add Lucky Chest Reward'
addRewardTitle.ZIndex = 17
addRewardTitle.Parent = addRewardModal

local selectedRewardKind = 'hat'
local selectedRewardRarity = 'green'
local addRewardPending = false

local kindHatButton = Instance.new('TextButton')
kindHatButton.Size = UDim2.fromOffset(188, 32)
kindHatButton.Position = UDim2.fromOffset(16, 54)
kindHatButton.BackgroundColor3 = Color3.fromRGB(53, 103, 62)
kindHatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
kindHatButton.Font = Enum.Font.GothamBold
kindHatButton.TextSize = 14
kindHatButton.Text = 'Hat'
kindHatButton.ZIndex = 17
kindHatButton.Parent = addRewardModal
corner:Clone().Parent = kindHatButton

local kindMountButton = kindHatButton:Clone()
kindMountButton.Position = UDim2.fromOffset(216, 54)
kindMountButton.Text = 'Vehicle Mount'
kindMountButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
kindMountButton.Parent = addRewardModal

local assetInput = Instance.new('TextBox')
assetInput.Size = UDim2.fromOffset(388, 34)
assetInput.Position = UDim2.fromOffset(16, 96)
assetInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
assetInput.TextColor3 = Color3.fromRGB(255, 255, 255)
assetInput.PlaceholderColor3 = Color3.fromRGB(170, 170, 170)
assetInput.PlaceholderText = 'Asset link or ID'
assetInput.ClearTextOnFocus = false
assetInput.Font = Enum.Font.Gotham
assetInput.TextSize = 14
assetInput.TextXAlignment = Enum.TextXAlignment.Left
assetInput.ZIndex = 17
assetInput.Parent = addRewardModal
corner:Clone().Parent = assetInput

local displayNameInput = assetInput:Clone()
displayNameInput.Position = UDim2.fromOffset(16, 140)
displayNameInput.PlaceholderText = 'Display name'
displayNameInput.Parent = addRewardModal

local rarityButton = kindHatButton:Clone()
rarityButton.Size = UDim2.fromOffset(388, 34)
rarityButton.Position = UDim2.fromOffset(16, 184)
rarityButton.Text = 'Rarity: Green'
rarityButton.BackgroundColor3 = RARITY_COLORS.green
rarityButton.Parent = addRewardModal

local addRewardStatusLabel = Instance.new('TextLabel')
addRewardStatusLabel.Size = UDim2.fromOffset(388, 34)
addRewardStatusLabel.Position = UDim2.fromOffset(16, 224)
addRewardStatusLabel.BackgroundTransparency = 1
addRewardStatusLabel.Text = ''
addRewardStatusLabel.TextWrapped = true
addRewardStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
addRewardStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
addRewardStatusLabel.Font = Enum.Font.Gotham
addRewardStatusLabel.TextSize = 14
addRewardStatusLabel.ZIndex = 17
addRewardStatusLabel.Parent = addRewardModal

local cancelAddRewardButton = kindHatButton:Clone()
cancelAddRewardButton.Size = UDim2.fromOffset(188, 34)
cancelAddRewardButton.Position = UDim2.fromOffset(16, 260)
cancelAddRewardButton.BackgroundColor3 = Color3.fromRGB(90, 56, 56)
cancelAddRewardButton.Text = 'Cancel'
cancelAddRewardButton.Parent = addRewardModal

local submitAddRewardButton = kindHatButton:Clone()
submitAddRewardButton.Size = UDim2.fromOffset(188, 34)
submitAddRewardButton.Position = UDim2.fromOffset(216, 260)
submitAddRewardButton.BackgroundColor3 = Color3.fromRGB(53, 103, 62)
submitAddRewardButton.Text = 'Submit'
submitAddRewardButton.Parent = addRewardModal

local resetConfirmationPending = false
local resetConfirmationToken = 0
local RESET_CONFIRMATION_TIMEOUT_SECONDS = 4

local function clearResetConfirmationPrompt()
    resetConfirmationPending = false
    resetProgressButton.Text = 'Reset Score + Rebirths'
    resetConfirmationLabel.Text = ''
end

local RARITY_ORDER = { 'green', 'blue', 'purple', 'orange', 'gold' }
local rarityIndex = 1

local function refreshRewardKindButtons()
    kindHatButton.BackgroundColor3 = selectedRewardKind == 'hat' and Color3.fromRGB(53, 103, 62)
        or Color3.fromRGB(45, 45, 45)
    kindMountButton.BackgroundColor3 = selectedRewardKind == 'vehicleMount'
            and Color3.fromRGB(53, 103, 62)
        or Color3.fromRGB(45, 45, 45)
end

local function refreshRewardRarityButton()
    local rarityKey = selectedRewardRarity
    local label = string.upper(string.sub(rarityKey, 1, 1)) .. string.sub(rarityKey, 2)
    rarityButton.Text = string.format('Rarity: %s', label)
    rarityButton.BackgroundColor3 = RARITY_COLORS[rarityKey] or Color3.fromRGB(45, 45, 45)
end

local function setAddRewardPending(pending: boolean)
    addRewardPending = pending
    submitAddRewardButton.Active = not pending
    submitAddRewardButton.AutoButtonColor = not pending
    submitAddRewardButton.Text = pending and 'Submitting...' or 'Submit'
end

local function clearAddRewardStatus()
    addRewardStatusLabel.Text = ''
end

local function clearList(frame: ScrollingFrame)
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA('GuiObject') and child.Name == 'RewardItem' then
            child:Destroy()
        end
    end
end

local function renderRewardsList(
    frame: ScrollingFrame,
    rewards,
    equippedId: string?,
    onEquip: (string) -> (),
    onUnequip: () -> ()
)
    clearList(frame)

    if #rewards == 0 then
        local emptyLabel = Instance.new('TextLabel')
        emptyLabel.Name = 'RewardItem'
        emptyLabel.Size = UDim2.fromOffset(frame.AbsoluteSize.X - 16, 36)
        emptyLabel.Position = UDim2.fromOffset(8, 8)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = 'No rewards unlocked yet.'
        emptyLabel.TextColor3 = Color3.fromRGB(185, 185, 185)
        emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.TextSize = 14
        emptyLabel.ZIndex = 13
        emptyLabel.Parent = frame
        frame.CanvasSize = UDim2.fromOffset(0, 56)
        return
    end

    local y = 8
    for _, reward in ipairs(rewards) do
        local row = Instance.new('Frame')
        row.Name = 'RewardItem'
        row.Size = UDim2.fromOffset(frame.AbsoluteSize.X - 16, 62)
        row.Position = UDim2.fromOffset(8, y)
        row.BackgroundColor3 = Color3.fromRGB(42, 46, 58)
        row.ZIndex = 13
        row.Parent = frame
        corner:Clone().Parent = row

        local nameLabel = Instance.new('TextLabel')
        nameLabel.Size = UDim2.fromOffset(150, 22)
        nameLabel.Position = UDim2.fromOffset(10, 8)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = reward.displayName
        nameLabel.TextColor3 = RARITY_COLORS[reward.rarity] or Color3.fromRGB(255, 255, 255)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.ZIndex = 14
        nameLabel.Parent = row

        local rarityLabel = nameLabel:Clone()
        rarityLabel.Position = UDim2.fromOffset(10, 30)
        rarityLabel.Size = UDim2.fromOffset(120, 20)
        rarityLabel.Font = Enum.Font.Gotham
        rarityLabel.TextSize = 12
        rarityLabel.Text = string.format('Rarity: %s', reward.rarity)
        rarityLabel.Parent = row

        local actionButton = Instance.new('TextButton')
        actionButton.Size = UDim2.fromOffset(90, 28)
        actionButton.Position = UDim2.fromOffset(row.Size.X.Offset - 102, 17)
        actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        actionButton.Font = Enum.Font.GothamBold
        actionButton.TextSize = 12
        actionButton.ZIndex = 14
        actionButton.Parent = row
        corner:Clone().Parent = actionButton

        local isEquipped = equippedId == reward.id
        actionButton.Text = isEquipped and 'Unequip' or 'Equip'
        actionButton.BackgroundColor3 = isEquipped and Color3.fromRGB(120, 74, 54)
            or Color3.fromRGB(53, 103, 62)
        actionButton.Activated:Connect(function()
            if isEquipped then
                onUnequip()
            else
                onEquip(reward.id)
            end
        end)

        y += 70
    end

    frame.CanvasSize = UDim2.fromOffset(0, y)
end

local function refreshRewardsUi()
    renderRewardsList(hatsListFrame, availableHats, equippedHatId, function(rewardId: string)
        equipHatRequestEvent:FireServer(rewardId)
    end, function()
        unequipHatRequestEvent:FireServer()
    end)

    renderRewardsList(
        mountsListFrame,
        availableVehicleMounts,
        equippedVehicleMountId,
        function(rewardId: string)
            equipVehicleMountRequestEvent:FireServer(rewardId)
        end,
        function()
            unequipVehicleMountRequestEvent:FireServer()
        end
    )
end

local function closeAddRewardModal()
    addRewardOverlay.Visible = false
    clearAddRewardStatus()
    setAddRewardPending(false)
end

local function openAddRewardModal()
    addRewardOverlay.Visible = true
    clearAddRewardStatus()
    setAddRewardPending(false)
end

refreshRewardKindButtons()
refreshRewardRarityButton()

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

gainRankButton.Activated:Connect(function()
    adminGainRankRequestEvent:FireServer()
end)

skipLuckyChestTimerButton.Activated:Connect(function()
    adminSkipLuckyChestTimerRequestEvent:FireServer()
end)

addRewardButton.Activated:Connect(function()
    openAddRewardModal()
end)

kindHatButton.Activated:Connect(function()
    selectedRewardKind = 'hat'
    refreshRewardKindButtons()
end)

kindMountButton.Activated:Connect(function()
    selectedRewardKind = 'vehicleMount'
    refreshRewardKindButtons()
end)

rarityButton.Activated:Connect(function()
    rarityIndex = (rarityIndex % #RARITY_ORDER) + 1
    selectedRewardRarity = RARITY_ORDER[rarityIndex]
    refreshRewardRarityButton()
end)

cancelAddRewardButton.Activated:Connect(function()
    closeAddRewardModal()
end)

addRewardOverlay.Activated:Connect(function()
    -- Modal blocker: swallow background clicks without closing.
end)

rewardsButton.Activated:Connect(function()
    rewardsOverlay.Visible = true
    refreshRewardsUi()
end)

closeRewardsButton.Activated:Connect(function()
    rewardsOverlay.Visible = false
end)

rewardsOverlay.Activated:Connect(function()
    -- Modal blocker: swallow background clicks without closing.
end)

submitAddRewardButton.Activated:Connect(function()
    if addRewardPending then
        return
    end

    local displayName = displayNameInput.Text
    local assetText = assetInput.Text
    if displayName:match('^%s*$') then
        addRewardStatusLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
        addRewardStatusLabel.Text = 'Display name is required.'
        return
    end
    if assetText:match('^%s*$') then
        addRewardStatusLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
        addRewardStatusLabel.Text = 'Asset link or ID is required.'
        return
    end

    setAddRewardPending(true)
    addRewardStatusLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
    addRewardStatusLabel.Text = 'Submitting reward...'
    adminAddRewardRequestEvent:FireServer({
        kind = selectedRewardKind,
        displayName = displayName,
        rarity = selectedRewardRarity,
        assetText = assetText,
    })
end)

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
        closeAddRewardModal()
    end
end)

adminAddRewardResultEvent.OnClientEvent:Connect(function(success: boolean, message: string)
    setAddRewardPending(false)
    addRewardStatusLabel.Text = message or ''
    addRewardStatusLabel.TextColor3 = success and Color3.fromRGB(180, 255, 187)
        or Color3.fromRGB(255, 180, 180)

    if success then
        assetInput.Text = ''
        displayNameInput.Text = ''
    end
end)

adminRewardCatalogUpdatedEvent.OnClientEvent:Connect(function()
    -- Catalog is server-authoritative; cache can be added here if client-side previews are needed.
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

equipmentStateUpdatedEvent.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= 'table' then
        return
    end

    availableHats = payload.availableHats or {}
    availableVehicleMounts = payload.availableVehicleMounts or {}
    equippedHatId = payload.equippedHatId
    equippedVehicleMountId = payload.equippedVehicleMountId
    refreshRewardsUi()
end)

equipmentActionResultEvent.OnClientEvent:Connect(function(success: boolean, message: string)
    rewardsStatusLabel.Text = message or ''
    rewardsStatusLabel.TextColor3 = success and Color3.fromRGB(180, 255, 187)
        or Color3.fromRGB(255, 180, 180)
end)

task.spawn(function()
    while true do
        updateLuckyChestUi()
        task.wait(1)
    end
end)
