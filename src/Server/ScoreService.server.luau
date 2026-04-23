local DataStoreService = game:GetService('DataStoreService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Debris = game:GetService('Debris')
local SoundService = game:GetService('SoundService')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local AdminLogic = require(Shared:WaitForChild('AdminLogic'))
local Constants = require(Shared:WaitForChild('Constants'))
local LuckyChestLogic = require(Shared:WaitForChild('LuckyChestLogic'))
local ProfileDataLogic = require(Shared:WaitForChild('ProfileDataLogic'))
local RankAuraLogic = require(Shared:WaitForChild('RankAuraLogic'))
local RankProgressionLogic = require(Shared:WaitForChild('RankProgressionLogic'))
local Remotes = require(Shared:WaitForChild('Remotes'))
local ZoneLogic = require(Shared:WaitForChild('ZoneLogic'))
local LockedZonePenaltyLogic = require(Shared:WaitForChild('LockedZonePenaltyLogic'))
local ZoneProgressionLogic = require(Shared:WaitForChild('ZoneProgressionLogic'))

type ZoneProgressionState = ZoneProgressionLogic.ZoneProgressionState
type ProfileData = ProfileDataLogic.ProfileData

type PlayerScoreState = {
    progressionState: ZoneProgressionState,
    profileData: ProfileData,
    dirtyVersion: number,
    lastSavedVersion: number,
    lastSaveClock: number,
    currentAuraRankIndex: number?,
    auraPulseClock: number,
    lastLockedZonePenaltyClock: number?,
}

local scoreUpdatedEvent = Remotes.getOrCreateScoreUpdatedEvent()
local adminScoreMultiplyRequestEvent = Remotes.getOrCreateAdminScoreMultiplyRequestEvent()
local adminResetProgressRequestEvent = Remotes.getOrCreateAdminResetProgressRequestEvent()
local adminStateUpdatedEvent = Remotes.getOrCreateAdminStateUpdatedEvent()
local luckyChestStatusUpdatedEvent = Remotes.getOrCreateLuckyChestStatusUpdatedEvent()
local luckyChestOpenRequestEvent = Remotes.getOrCreateLuckyChestOpenRequestEvent()
local luckyChestOpenedEvent = Remotes.getOrCreateLuckyChestOpenedEvent()

local playerStates: { [Player]: PlayerScoreState } = {}
local scoreStore = DataStoreService:GetDataStore(Constants.SCORE_DATASTORE_NAME)

local function getOrCreateLockedZoneDeathSound(): Sound
    local existing = SoundService:FindFirstChild(Constants.LOCKED_ZONE_DEATH_SOUND_NAME)
    local sound: Sound

    if existing and existing:IsA('Sound') then
        sound = existing
    else
        sound = Instance.new('Sound')
        sound.Name = Constants.LOCKED_ZONE_DEATH_SOUND_NAME
        sound.Parent = SoundService
    end

    sound.SoundId = Constants.LOCKED_ZONE_DEATH_SOUND_ID
    sound.Volume = Constants.LOCKED_ZONE_DEATH_SOUND_VOLUME
    sound.RollOffMode = Enum.RollOffMode.InverseTapered

    return sound
end

local function emitNopeParticles(originPosition: Vector3)
    local container = Instance.new('Folder')
    container.Name = 'LockedZoneNopeParticles'
    container.Parent = workspace

    Debris:AddItem(container, Constants.LOCKED_ZONE_NOPE_PARTICLE_LIFETIME_SECONDS)

    for _ = 1, Constants.LOCKED_ZONE_NOPE_PARTICLE_COUNT do
        local particle = Instance.new('Part')
        particle.Name = 'NopeParticle'
        particle.Size = Vector3.new(0.45, 0.45, 0.45)
        particle.CFrame = CFrame.new(originPosition + Vector3.new(0, 2.5, 0))
        particle.Transparency = 1
        particle.CanCollide = false
        particle.CanTouch = false
        particle.CanQuery = false
        particle.Massless = true
        particle.Parent = container

        local billboard = Instance.new('BillboardGui')
        billboard.Size = UDim2.fromOffset(140, 60)
        billboard.AlwaysOnTop = true
        billboard.StudsOffsetWorldSpace = Vector3.new(0, 0.8, 0)
        billboard.Parent = particle

        local label = Instance.new('TextLabel')
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = 'Nope!'
        label.TextScaled = true
        label.Font = Enum.Font.GothamBlack
        label.TextColor3 = Color3.fromRGB(255, 95, 207)
        label.TextStrokeTransparency = 0.2
        label.Rotation = math.random(-20, 20)
        label.Parent = billboard

        local direction = Vector3.new(
            math.random(-100, 100) / 100,
            math.random(20, 100) / 100,
            math.random(-100, 100) / 100
        )
        if direction.Magnitude <= 0 then
            direction = Vector3.new(0, 1, 0)
        end

        local speed = math.random(
            Constants.LOCKED_ZONE_NOPE_PARTICLE_MIN_SPEED,
            Constants.LOCKED_ZONE_NOPE_PARTICLE_MAX_SPEED
        )
        particle.AssemblyLinearVelocity = direction.Unit * speed
    end
end

local function penalizeLockedZoneEntry(
    player: Player,
    state: PlayerScoreState,
    rootPart: BasePart,
    lockedZoneConfig: {
        requiredScore: number,
        scoreIncrement: number,
        center: Vector3,
    }
)
    local now = os.clock()
    local lastPenaltyClock = state.lastLockedZonePenaltyClock
    if
        lastPenaltyClock
        and now - lastPenaltyClock < Constants.LOCKED_ZONE_PENALTY_COOLDOWN_SECONDS
    then
        return
    end
    state.lastLockedZonePenaltyClock = now

    local horizontalDirection = LockedZonePenaltyLogic.getKnockbackHorizontalDirection(
        rootPart.Position,
        lockedZoneConfig.center
    )
    rootPart.AssemblyLinearVelocity = Vector3.new(
        horizontalDirection.X * Constants.LOCKED_ZONE_KNOCKBACK_HORIZONTAL_SPEED,
        Constants.LOCKED_ZONE_KNOCKBACK_UPWARD_SPEED,
        horizontalDirection.Z * Constants.LOCKED_ZONE_KNOCKBACK_HORIZONTAL_SPEED
    )

    emitNopeParticles(rootPart.Position)
    getOrCreateLockedZoneDeathSound():Play()

    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass('Humanoid')
        if humanoid then
            task.delay(Constants.LOCKED_ZONE_KILL_DELAY_SECONDS, function()
                if humanoid.Parent and humanoid.Health > 0 then
                    humanoid.Health = 0
                end
            end)
        end
    end
end

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

local function pushLuckyChestStatus(player: Player, profileData: ProfileData)
    luckyChestStatusUpdatedEvent:FireClient(
        player,
        profileData.nextLuckyChestOpenAt,
        profileData.scoreBoostExpiresAt,
        profileData.unlockedHats,
        profileData.unlockedPets,
        profileData.unlockedVehicleMounts
    )
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

local function getBodyScaleValue(character: Model, valueName: string): NumberValue?
    local value = character:FindFirstChild(valueName)
    if value and value:IsA('NumberValue') then
        return value
    end

    return nil
end

local function applyAuraScale(character: Model, scaleMultiplier: number)
    local scaleValueNames = {
        'BodyHeightScale',
        'BodyWidthScale',
        'BodyDepthScale',
        'HeadScale',
    }

    for _, valueName in ipairs(scaleValueNames) do
        local scaleValue = getBodyScaleValue(character, valueName)
        if scaleValue then
            scaleValue.Value = scaleMultiplier
        end
    end
end

local function ensureAuraAttachment(rootPart: BasePart): Attachment
    local auraAttachment = rootPart:FindFirstChild('RankAuraAttachment')
    if auraAttachment and auraAttachment:IsA('Attachment') then
        return auraAttachment
    end

    auraAttachment = Instance.new('Attachment')
    auraAttachment.Name = 'RankAuraAttachment'
    auraAttachment.Position = Vector3.new(0, 1.2, 0)
    auraAttachment.Parent = rootPart

    return auraAttachment
end

local function ensureAuraEffectsContainer(character: Model): Folder
    local container = character:FindFirstChild('RankAuraEffects')
    if container and container:IsA('Folder') then
        return container
    end

    container = Instance.new('Folder')
    container.Name = 'RankAuraEffects'
    container.Parent = character
    return container
end

local function ensureAuraHighlight(character: Model, container: Folder): Highlight
    local highlight = container:FindFirstChild('AuraHighlight')
    if highlight and highlight:IsA('Highlight') then
        return highlight
    end

    highlight = Instance.new('Highlight')
    highlight.Name = 'AuraHighlight'
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = container
    highlight.Adornee = character
    return highlight
end

local function ensureAuraLight(attachment: Attachment): PointLight
    local light = attachment:FindFirstChild('AuraPointLight')
    if light and light:IsA('PointLight') then
        return light
    end

    light = Instance.new('PointLight')
    light.Name = 'AuraPointLight'
    light.Parent = attachment
    return light
end

local function ensureAuraEmitter(attachment: Attachment, name: string): ParticleEmitter
    local emitter = attachment:FindFirstChild(name)
    if emitter and emitter:IsA('ParticleEmitter') then
        return emitter
    end

    emitter = Instance.new('ParticleEmitter')
    emitter.Name = name
    emitter.Parent = attachment
    emitter.LockedToPart = false
    emitter.SpreadAngle = Vector2.new(360, 360)
    emitter.Speed = NumberRange.new(0.8, 1.8)
    emitter.Acceleration = Vector3.new(0, 3, 0)
    emitter.RotSpeed = NumberRange.new(-80, 80)
    emitter.Lifetime = NumberRange.new(0.8, 1.8)
    emitter.Drag = 0.5

    return emitter
end

local function updateRankAura(player: Player, state: PlayerScoreState)
    local character = player.Character
    if not character then
        return
    end

    local rootPart = character:FindFirstChild('HumanoidRootPart')
    if not rootPart or not rootPart:IsA('BasePart') then
        return
    end

    local rankProgress =
        RankProgressionLogic.getRankProgress(state.progressionState.score, Constants.RANK_CONFIGS)
    local auraConfig =
        RankAuraLogic.getAuraForRank(rankProgress.currentRankIndex, #Constants.RANK_CONFIGS)
    local primaryColor =
        Color3.fromHSV(auraConfig.primaryHue, auraConfig.colorSaturation, auraConfig.colorValue)
    local secondaryColor =
        Color3.fromHSV(auraConfig.secondaryHue, auraConfig.colorSaturation, auraConfig.colorValue)
    local accentColor =
        Color3.fromHSV(auraConfig.accentHue, auraConfig.colorSaturation, auraConfig.colorValue)
    local auraAttachment = ensureAuraAttachment(rootPart)
    local auraContainer = ensureAuraEffectsContainer(character)
    local auraHighlight = ensureAuraHighlight(character, auraContainer)
    local auraLight = ensureAuraLight(auraAttachment)
    local coreEmitter = ensureAuraEmitter(auraAttachment, 'CoreAuraEmitter')
    local sparkleEmitter = ensureAuraEmitter(auraAttachment, 'SparkleAuraEmitter')

    auraAttachment.Position = Vector3.new(0, 1 + auraConfig.intensityAlpha, 0)
    auraAttachment.Orientation = Vector3.new(0, state.auraPulseClock * auraConfig.orbitSpeed, 0)

    applyAuraScale(character, auraConfig.scaleMultiplier)

    auraHighlight.FillColor = primaryColor
    auraHighlight.OutlineColor = secondaryColor
    auraHighlight.FillTransparency = auraConfig.highlightFillTransparency
    auraHighlight.OutlineTransparency = auraConfig.highlightOutlineTransparency

    local pulse = 0.5
        + (0.5 * math.sin(state.auraPulseClock * (2.6 + auraConfig.intensityAlpha * 3.5)))

    auraLight.Color = accentColor:Lerp(primaryColor, pulse)
    auraLight.Brightness = auraConfig.glowBrightness * (0.75 + (pulse * 0.6))
    auraLight.Range = auraConfig.glowRange * (0.75 + (pulse * 0.3))

    coreEmitter.Color = ColorSequence.new(primaryColor, secondaryColor)
    coreEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, auraConfig.coreSizeBase * 0.5),
        NumberSequenceKeypoint.new(0.5, auraConfig.coreSizeBase),
        NumberSequenceKeypoint.new(1, auraConfig.coreSizeBase * 0.25),
    })
    coreEmitter.Rate = auraConfig.coreEmissionRate
    coreEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.65, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })

    sparkleEmitter.Color = ColorSequence.new(secondaryColor, accentColor)
    sparkleEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, auraConfig.sparkleSizeBase * 0.3),
        NumberSequenceKeypoint.new(0.6, auraConfig.sparkleSizeBase),
        NumberSequenceKeypoint.new(1, 0),
    })
    sparkleEmitter.Rate = auraConfig.sparkleEmissionRate
    sparkleEmitter.Speed =
        NumberRange.new(3 + (auraConfig.intensityAlpha * 6), 5 + (auraConfig.intensityAlpha * 9))
    sparkleEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.5, 0.45),
        NumberSequenceKeypoint.new(1, 1),
    })

    if state.currentAuraRankIndex ~= auraConfig.rankIndex then
        coreEmitter:Emit(auraConfig.burstCount)
        sparkleEmitter:Emit(math.floor(auraConfig.burstCount * 1.5))
        state.currentAuraRankIndex = auraConfig.rankIndex
    end
end

local function pushIsAdmin(player: Player, isAdmin: boolean)
    adminStateUpdatedEvent:FireClient(player, isAdmin)
end

local function isPlayerAdmin(player: Player): boolean
    return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end

local function createPlayerState(profileData: ProfileData): PlayerScoreState
    return {
        progressionState = ZoneProgressionLogic.newState(profileData.score, profileData.rebirths),
        profileData = profileData,
        dirtyVersion = 0,
        lastSavedVersion = 0,
        lastSaveClock = os.clock(),
        currentAuraRankIndex = nil,
        auraPulseClock = 0,
        lastLockedZonePenaltyClock = nil,
    }
end

local function loadPlayerState(player: Player): PlayerScoreState
    local playerData = ProfileDataLogic.normalize(nil)

    local success, result = pcall(function()
        return scoreStore:GetAsync(getPlayerDataStoreKey(player))
    end)

    if success then
        playerData = ProfileDataLogic.normalize(result)
    else
        warn(string.format('Failed to load score data for %s: %s', player.Name, tostring(result)))
    end

    return createPlayerState(playerData)
end

local function syncProfileWithProgression(state: PlayerScoreState)
    state.profileData.score = state.progressionState.score
    state.profileData.rebirths = state.progressionState.rebirths
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

    syncProfileWithProgression(state)

    local captureVersion = state.dirtyVersion
    local profileToSave = state.profileData

    state.lastSaveClock = now

    task.spawn(function()
        local success, err = pcall(function()
            scoreStore:SetAsync(
                getPlayerDataStoreKey(player),
                ProfileDataLogic.toStoredValue(profileToSave)
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
    pushLuckyChestStatus(player, state.profileData)
    updateRankTitle(player, state.progressionState.score)
    pushIsAdmin(player, isPlayerAdmin(player))

    player.CharacterAdded:Connect(function()
        local currentState = playerStates[player]
        if currentState then
            pushScore(
                player,
                currentState.progressionState.score,
                currentState.progressionState.rebirths
            )
            pushLuckyChestStatus(player, currentState.profileData)
            updateRankTitle(player, currentState.progressionState.score)
            currentState.currentAuraRankIndex = nil
            updateRankAura(player, currentState)
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
    updateRankTitle(player, progressionState.score)
    updateRankAura(player, state)
    markDirty(state)
    savePlayerState(player, false)
end)

adminResetProgressRequestEvent.OnServerEvent:Connect(function(player: Player)
    if not isPlayerAdmin(player) then
        return
    end

    local state = playerStates[player]
    if not state then
        return
    end

    local progressionState = state.progressionState
    progressionState.score, progressionState.rebirths = AdminLogic.resetScoreAndRebirths()

    pushScore(player, progressionState.score, progressionState.rebirths)
    updateRankTitle(player, progressionState.score)
    updateRankAura(player, state)
luckyChestOpenRequestEvent.OnServerEvent:Connect(function(player: Player)
    local state = playerStates[player]
    if not state then
        return
    end

    local now = os.time()
    local spinResult = LuckyChestLogic.applyChestSpin(
        state.profileData,
        state.progressionState.score,
        state.progressionState.rebirths,
        now,
        Constants.LUCKY_CHEST_COOLDOWN_SECONDS,
        Constants.LUCKY_CHEST_SCORE_BOOST_DURATION_SECONDS,
        function()
            return Random.new():NextNumber()
        end
    )

    if not spinResult then
        pushLuckyChestStatus(player, state.profileData)
        return
    end

    state.profileData = spinResult.profileData
    state.progressionState.score = spinResult.score
    state.progressionState.rebirths = spinResult.rebirths

    pushScore(player, state.progressionState.score, state.progressionState.rebirths)
    updateRankTitle(player, state.progressionState.score)
    pushLuckyChestStatus(player, state.profileData)

    luckyChestOpenedEvent:FireClient(
        player,
        spinResult.spinResult,
        state.profileData.nextLuckyChestOpenAt,
        state.profileData.scoreBoostExpiresAt
    )

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
        state.auraPulseClock += deltaSeconds
        local rootPart = getHumanoidRootPart(player)
        local isInsideAgeZones = {}
        local isInsideRebirthZone = false
        local lockedZoneIndex: number? = nil

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
            lockedZoneIndex = LockedZonePenaltyLogic.getFirstLockedZoneIndex(
                state.progressionState.score,
                isInsideAgeZones,
                Constants.AGE_ZONE_CONFIGS
            )
            if lockedZoneIndex then
                penalizeLockedZoneEntry(
                    player,
                    state,
                    rootPart,
                    Constants.AGE_ZONE_CONFIGS[lockedZoneIndex]
                )
            end
        end

        local ageZoneProgressionConfigs = {}
        for index, zoneConfig in ipairs(Constants.AGE_ZONE_CONFIGS) do
            ageZoneProgressionConfigs[index] = {
                requiredScore = zoneConfig.requiredScore,
                scoreIncrement = zoneConfig.scoreIncrement,
            }
        end

        local boostedMultiplier = LuckyChestLogic.getActiveScoreBoostMultiplier(
            state.profileData,
            os.time(),
            Constants.LUCKY_CHEST_SCORE_BOOST_MULTIPLIER
        )

        local tickResult = ZoneProgressionLogic.tick(state.progressionState, {
            deltaSeconds = deltaSeconds,
            isInsideAgeZones = isInsideAgeZones,
            ageZoneConfigs = ageZoneProgressionConfigs,
            scoreIntervalSeconds = Constants.SCORE_INTERVAL_SECONDS,
            isInsideRebirthZone = isInsideRebirthZone,
            rebirthScoreDivisor = Constants.REBIRTH_SCORE_DIVISOR,
            bonusScoreMultiplier = boostedMultiplier,
        })

        if
            tickResult.state.score ~= state.progressionState.score
            or tickResult.state.rebirths ~= state.progressionState.rebirths
        then
            pushScore(player, tickResult.state.score, tickResult.state.rebirths)
            updateRankTitle(player, tickResult.state.score)
            markDirty(state)
            savePlayerState(player, false)
        end

        state.progressionState = tickResult.state
        updateRankAura(player, state)
    end
end)
