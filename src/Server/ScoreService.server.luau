local DataStoreService = game:GetService('DataStoreService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local Constants = require(Shared:WaitForChild('Constants'))
local AdminLogic = require(Shared:WaitForChild('AdminLogic'))
local AuraLogic = require(Shared:WaitForChild('AuraLogic'))
local ProfileDataLogic = require(Shared:WaitForChild('ProfileDataLogic'))
local RankProgressionLogic = require(Shared:WaitForChild('RankProgressionLogic'))
local Remotes = require(Shared:WaitForChild('Remotes'))
local ZoneLogic = require(Shared:WaitForChild('ZoneLogic'))
local ZoneProgressionLogic = require(Shared:WaitForChild('ZoneProgressionLogic'))

type ZoneProgressionState = ZoneProgressionLogic.ZoneProgressionState

type PlayerScoreState = {
    progressionState: ZoneProgressionState,
    currentRankIndex: number,
    dirtyVersion: number,
    lastSavedVersion: number,
    lastSaveClock: number,
}

local scoreUpdatedEvent = Remotes.getOrCreateScoreUpdatedEvent()
local adminScoreMultiplyRequestEvent = Remotes.getOrCreateAdminScoreMultiplyRequestEvent()
local adminStateUpdatedEvent = Remotes.getOrCreateAdminStateUpdatedEvent()
local playerStates: { [Player]: PlayerScoreState } = {}
local scoreStore = DataStoreService:GetDataStore(Constants.SCORE_DATASTORE_NAME)

local function getPlayerDataStoreKey(player: Player): string
    return string.format('player_%s', tostring(player.UserId))
end

local function getHumanoidRootPart(player: Player): BasePart?
    local character = player.Character
    if not character then
        return nil
    end

    local rootPart = character:FindFirstChild('HumanoidRootPart')
    if rootPart and rootPart:IsA('BasePart') then
        return rootPart
    end

    return nil
end

local function pushScore(player: Player, score: number, rebirths: number)
    scoreUpdatedEvent:FireClient(player, score, rebirths)
end

local function getRankNameForScore(score: number): string
    local rankProgress = RankProgressionLogic.getRankProgress(score, Constants.RANK_CONFIGS)
    return rankProgress.currentRankName
end

local function ensureRankTitleLabel(player: Player): TextLabel?
    local character = player.Character
    if not character then
        return nil
    end

    local head = character:FindFirstChild('Head')
    if not head or not head:IsA('BasePart') then
        return nil
    end

    local billboard = head:FindFirstChild('RankTitleBillboard')
    if not billboard then
        billboard = Instance.new('BillboardGui')
        billboard.Name = 'RankTitleBillboard'
        billboard.Size = UDim2.fromOffset(200, 36)
        billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head
    end

    local rankLabel = billboard:FindFirstChild('RankLabel')
    if not rankLabel then
        rankLabel = Instance.new('TextLabel')
        rankLabel.Name = 'RankLabel'
        rankLabel.Size = UDim2.fromScale(1, 1)
        rankLabel.BackgroundTransparency = 1
        rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        rankLabel.TextStrokeTransparency = 0.2
        rankLabel.Font = Enum.Font.GothamBold
        rankLabel.TextScaled = true
        rankLabel.Parent = billboard
    end

    return rankLabel :: TextLabel
end

local function updateRankTitle(player: Player, score: number)
    local rankLabel = ensureRankTitleLabel(player)
    if not rankLabel then
        return
    end

    rankLabel.Text = getRankNameForScore(score)
end

local function ensureRankAuraNodes(
    player: Player
): (Attachment?, ParticleEmitter?, ParticleEmitter?, PointLight?)
    local character = player.Character
    if not character then
        return nil, nil, nil, nil
    end

    local rootPart = character:FindFirstChild('HumanoidRootPart')
    if not rootPart or not rootPart:IsA('BasePart') then
        return nil, nil, nil, nil
    end

    local auraAttachment = rootPart:FindFirstChild('RankAuraAttachment')
    if not auraAttachment then
        auraAttachment = Instance.new('Attachment')
        auraAttachment.Name = 'RankAuraAttachment'
        auraAttachment.Position = Vector3.new(0, -1.5, 0)
        auraAttachment.Parent = rootPart
    end

    local primaryEmitter = auraAttachment:FindFirstChild('PrimaryAuraEmitter')
    if not primaryEmitter then
        primaryEmitter = Instance.new('ParticleEmitter')
        primaryEmitter.Name = 'PrimaryAuraEmitter'
        primaryEmitter.Shape = Enum.ParticleEmitterShape.Sphere
        primaryEmitter.EmissionDirection = Enum.NormalId.Top
        primaryEmitter.Rotation = NumberRange.new(0, 360)
        primaryEmitter.RotSpeed = NumberRange.new(-40, 40)
        primaryEmitter.Parent = auraAttachment
    end

    local secondaryEmitter = auraAttachment:FindFirstChild('SecondaryAuraEmitter')
    if not secondaryEmitter then
        secondaryEmitter = Instance.new('ParticleEmitter')
        secondaryEmitter.Name = 'SecondaryAuraEmitter'
        secondaryEmitter.Shape = Enum.ParticleEmitterShape.Sphere
        secondaryEmitter.EmissionDirection = Enum.NormalId.Top
        secondaryEmitter.Rotation = NumberRange.new(0, 360)
        secondaryEmitter.RotSpeed = NumberRange.new(-120, 120)
        secondaryEmitter.Parent = auraAttachment
    end

    local auraLight = auraAttachment:FindFirstChild('AuraLight')
    if not auraLight then
        auraLight = Instance.new('PointLight')
        auraLight.Name = 'AuraLight'
        auraLight.Parent = auraAttachment
    end

    return auraAttachment :: Attachment,
        primaryEmitter :: ParticleEmitter,
        secondaryEmitter :: ParticleEmitter,
        auraLight :: PointLight
end

local function updateRankAura(player: Player, rankIndex: number, didRankIncrease: boolean)
    local _, primaryEmitter, secondaryEmitter, auraLight = ensureRankAuraNodes(player)
    if not primaryEmitter or not secondaryEmitter or not auraLight then
        return
    end

    local auraConfig = AuraLogic.getAuraConfig(rankIndex, #Constants.RANK_CONFIGS)
    local primaryColor =
        Color3.fromHSV(auraConfig.primaryHue, auraConfig.primarySaturation, auraConfig.primaryValue)
    local secondaryColor = Color3.fromHSV(
        auraConfig.secondaryHue,
        auraConfig.secondarySaturation,
        auraConfig.secondaryValue
    )

    primaryEmitter.Color = ColorSequence.new(primaryColor, secondaryColor)
    primaryEmitter.Rate = auraConfig.rate
    primaryEmitter.Lifetime = NumberRange.new(auraConfig.lifetimeMin, auraConfig.lifetimeMax)
    primaryEmitter.Speed = NumberRange.new(auraConfig.speedMin, auraConfig.speedMax)
    primaryEmitter.SpreadAngle = Vector2.new(auraConfig.spread, auraConfig.spread)
    primaryEmitter.LightEmission = auraConfig.lightEmission
    primaryEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, auraConfig.sizeStart),
        NumberSequenceKeypoint.new(0.7, auraConfig.sizeStart * 0.6),
        NumberSequenceKeypoint.new(1, auraConfig.sizeEnd),
    })
    primaryEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.08),
        NumberSequenceKeypoint.new(0.75, 0.45),
        NumberSequenceKeypoint.new(1, 1),
    })

    secondaryEmitter.Enabled = auraConfig.hasSecondaryBurst
    secondaryEmitter.Color = ColorSequence.new(secondaryColor, primaryColor)
    secondaryEmitter.Rate = auraConfig.secondaryRate
    secondaryEmitter.Lifetime =
        NumberRange.new(auraConfig.lifetimeMin * 0.6, auraConfig.lifetimeMax * 0.8)
    secondaryEmitter.Speed = NumberRange.new(auraConfig.speedMin * 2.2, auraConfig.speedMax * 2.8)
    secondaryEmitter.SpreadAngle = Vector2.new(auraConfig.spread * 1.2, auraConfig.spread * 1.2)
    secondaryEmitter.LightEmission = math.min(auraConfig.lightEmission + 0.05, 1)
    secondaryEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, auraConfig.sizeStart * 0.35),
        NumberSequenceKeypoint.new(1, auraConfig.sizeEnd * 0.2),
    })
    secondaryEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })

    auraLight.Color = primaryColor:Lerp(secondaryColor, 0.35)
    auraLight.Brightness = auraConfig.lightBrightness
    auraLight.Range = auraConfig.lightRange

    if didRankIncrease then
        local burstAmount = math.max(10, math.floor(16 + (rankIndex * 0.4)))
        primaryEmitter:Emit(burstAmount)

        if auraConfig.hasSecondaryBurst then
            secondaryEmitter:Emit(math.floor(burstAmount * 0.85))
        end
    end
end

local function updateRankPresentation(player: Player, score: number, previousRankIndex: number?)
    local rankIndex = RankProgressionLogic.getCurrentRankIndex(score, Constants.RANK_CONFIGS)
    updateRankTitle(player, score)
    updateRankAura(player, rankIndex, previousRankIndex ~= nil and rankIndex > previousRankIndex)
    return rankIndex
end

local function pushIsAdmin(player: Player, isAdmin: boolean)
    adminStateUpdatedEvent:FireClient(player, isAdmin)
end

local function isPlayerAdmin(player: Player): boolean
    return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end

local function createPlayerState(score: number, rebirths: number): PlayerScoreState
    local initialRankIndex = RankProgressionLogic.getCurrentRankIndex(score, Constants.RANK_CONFIGS)

    return {
        progressionState = ZoneProgressionLogic.newState(score, rebirths),
        currentRankIndex = initialRankIndex,
        dirtyVersion = 0,
        lastSavedVersion = 0,
        lastSaveClock = os.clock(),
    }
end

local function loadPlayerState(player: Player): PlayerScoreState
    local playerData = {
        score = 0,
        rebirths = 0,
    }

    local success, result = pcall(function()
        return scoreStore:GetAsync(getPlayerDataStoreKey(player))
    end)

    if success then
        playerData = ProfileDataLogic.normalize(result)
    else
        warn(string.format('Failed to load score data for %s: %s', player.Name, tostring(result)))
    end

    return createPlayerState(playerData.score, playerData.rebirths)
end

local function savePlayerState(player: Player, force: boolean)
    local state = playerStates[player]
    if not state then
        return
    end

    if state.dirtyVersion <= state.lastSavedVersion then
        return
    end

    local now = os.clock()
    if not force and now - state.lastSaveClock < Constants.SCORE_AUTOSAVE_INTERVAL_SECONDS then
        return
    end

    local captureVersion = state.dirtyVersion
    local scoreToSave = state.progressionState.score
    local rebirthsToSave = state.progressionState.rebirths

    state.lastSaveClock = now

    task.spawn(function()
        local success, err = pcall(function()
            scoreStore:SetAsync(
                getPlayerDataStoreKey(player),
                ProfileDataLogic.toStoredValue({
                    score = scoreToSave,
                    rebirths = rebirthsToSave,
                })
            )
        end)

        if not success then
            warn(string.format('Failed to save score data for %s: %s', player.Name, tostring(err)))
            return
        end

        local latestState = playerStates[player]
        if latestState and latestState.lastSavedVersion < captureVersion then
            latestState.lastSavedVersion = captureVersion
        end
    end)
end

local function markDirty(state: PlayerScoreState)
    state.dirtyVersion += 1
end

local function initializePlayerState(player: Player)
    local state = loadPlayerState(player)
    playerStates[player] = state

    pushScore(player, state.progressionState.score, state.progressionState.rebirths)
    state.currentRankIndex = updateRankPresentation(player, state.progressionState.score, nil)
    pushIsAdmin(player, isPlayerAdmin(player))

    player.CharacterAdded:Connect(function()
        local currentState = playerStates[player]
        if currentState then
            pushScore(
                player,
                currentState.progressionState.score,
                currentState.progressionState.rebirths
            )
            currentState.currentRankIndex =
                updateRankPresentation(player, currentState.progressionState.score, nil)
        end
    end)
end

adminScoreMultiplyRequestEvent.OnServerEvent:Connect(function(player: Player, multiplier: number)
    if typeof(multiplier) ~= 'number' then
        return
    end

    if not isPlayerAdmin(player) then
        return
    end

    if not AdminLogic.isAllowedScoreMultiplier(Constants.ADMIN_SCORE_MULTIPLIERS, multiplier) then
        return
    end

    local state = playerStates[player]
    if not state then
        return
    end

    local progressionState = state.progressionState
    progressionState.score = AdminLogic.applyScoreMultiplier(progressionState.score, multiplier)

    pushScore(player, progressionState.score, progressionState.rebirths)
    state.currentRankIndex =
        updateRankPresentation(player, progressionState.score, state.currentRankIndex)
    markDirty(state)
    savePlayerState(player, false)
end)

Players.PlayerAdded:Connect(function(player)
    initializePlayerState(player)
end)

for _, player in Players:GetPlayers() do
    initializePlayerState(player)
end

Players.PlayerRemoving:Connect(function(player)
    savePlayerState(player, true)
    playerStates[player] = nil
end)

game:BindToClose(function()
    for player in pairs(playerStates) do
        savePlayerState(player, true)
    end

    task.wait(2)
end)

RunService.Heartbeat:Connect(function(deltaSeconds: number)
    for player, state in pairs(playerStates) do
        local rootPart = getHumanoidRootPart(player)
        local isInsideAgeZones = {}
        local isInsideRebirthZone = false

        if rootPart then
            for index, zoneConfig in ipairs(Constants.AGE_ZONE_CONFIGS) do
                isInsideAgeZones[index] = ZoneLogic.isPositionInsideCircle(
                    rootPart.Position,
                    zoneConfig.center,
                    zoneConfig.radius
                )
            end
            isInsideRebirthZone = ZoneLogic.isPositionInsideCircle(
                rootPart.Position,
                Constants.REBIRTH_ZONE_CENTER,
                Constants.REBIRTH_ZONE_RADIUS
            )
        end

        local ageZoneProgressionConfigs = {}
        for index, zoneConfig in ipairs(Constants.AGE_ZONE_CONFIGS) do
            ageZoneProgressionConfigs[index] = {
                requiredScore = zoneConfig.requiredScore,
                scoreIncrement = zoneConfig.scoreIncrement,
            }
        end

        local tickResult = ZoneProgressionLogic.tick(state.progressionState, {
            deltaSeconds = deltaSeconds,
            isInsideAgeZones = isInsideAgeZones,
            ageZoneConfigs = ageZoneProgressionConfigs,
            scoreIntervalSeconds = Constants.SCORE_INTERVAL_SECONDS,
            isInsideRebirthZone = isInsideRebirthZone,
            rebirthScoreDivisor = Constants.REBIRTH_SCORE_DIVISOR,
        })

        if
            tickResult.state.score ~= state.progressionState.score
            or tickResult.state.rebirths ~= state.progressionState.rebirths
        then
            pushScore(player, tickResult.state.score, tickResult.state.rebirths)
            state.currentRankIndex =
                updateRankPresentation(player, tickResult.state.score, state.currentRankIndex)
            markDirty(state)
            savePlayerState(player, false)
        end

        state.progressionState = tickResult.state
    end
end)
