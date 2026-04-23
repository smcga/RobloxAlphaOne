local DataStoreService = game:GetService('DataStoreService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local AdminLogic = require(Shared:WaitForChild('AdminLogic'))
local Constants = require(Shared:WaitForChild('Constants'))
local LuckyChestLogic = require(Shared:WaitForChild('LuckyChestLogic'))
local ProfileDataLogic = require(Shared:WaitForChild('ProfileDataLogic'))
local RankProgressionLogic = require(Shared:WaitForChild('RankProgressionLogic'))
local Remotes = require(Shared:WaitForChild('Remotes'))
local ZoneLogic = require(Shared:WaitForChild('ZoneLogic'))
local ZoneProgressionLogic = require(Shared:WaitForChild('ZoneProgressionLogic'))

type ZoneProgressionState = ZoneProgressionLogic.ZoneProgressionState
type ProfileData = ProfileDataLogic.ProfileData

type PlayerScoreState = {
    progressionState: ZoneProgressionState,
    profileData: ProfileData,
    dirtyVersion: number,
    lastSavedVersion: number,
    lastSaveClock: number,
}

local scoreUpdatedEvent = Remotes.getOrCreateScoreUpdatedEvent()
local adminScoreMultiplyRequestEvent = Remotes.getOrCreateAdminScoreMultiplyRequestEvent()
local adminStateUpdatedEvent = Remotes.getOrCreateAdminStateUpdatedEvent()
local luckyChestStatusUpdatedEvent = Remotes.getOrCreateLuckyChestStatusUpdatedEvent()
local luckyChestOpenRequestEvent = Remotes.getOrCreateLuckyChestOpenRequestEvent()
local luckyChestOpenedEvent = Remotes.getOrCreateLuckyChestOpenedEvent()

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
    markDirty(state)
    savePlayerState(player, false)
end)

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
    end
end)
