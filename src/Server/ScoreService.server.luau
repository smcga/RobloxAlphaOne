local DataStoreService = game:GetService('DataStoreService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local Constants = require(Shared:WaitForChild('Constants'))
local AdminLogic = require(Shared:WaitForChild('AdminLogic'))
local GlobalLeaderboardLogic = require(Shared:WaitForChild('GlobalLeaderboardLogic'))
local NumberFormat = require(Shared:WaitForChild('NumberFormat'))
local ProfileDataLogic = require(Shared:WaitForChild('ProfileDataLogic'))
local RankProgressionLogic = require(Shared:WaitForChild('RankProgressionLogic'))
local Remotes = require(Shared:WaitForChild('Remotes'))
local ZoneLogic = require(Shared:WaitForChild('ZoneLogic'))
local ZoneProgressionLogic = require(Shared:WaitForChild('ZoneProgressionLogic'))

type ZoneProgressionState = ZoneProgressionLogic.ZoneProgressionState

type PlayerScoreState = {
    progressionState: ZoneProgressionState,
    dirtyVersion: number,
    lastSavedVersion: number,
    lastSaveClock: number,
}

local scoreUpdatedEvent = Remotes.getOrCreateScoreUpdatedEvent()
local adminScoreMultiplyRequestEvent = Remotes.getOrCreateAdminScoreMultiplyRequestEvent()
local adminStateUpdatedEvent = Remotes.getOrCreateAdminStateUpdatedEvent()
local playerStates: { [Player]: PlayerScoreState } = {}
local scoreStore = DataStoreService:GetDataStore(Constants.SCORE_DATASTORE_NAME)
local globalLeaderboardStore =
    DataStoreService:GetOrderedDataStore(Constants.GLOBAL_LEADERBOARD_DATASTORE_NAME)
local globalLeaderboardTextLabel: TextLabel? = nil
local cachedNamesByUserId: { [number]: string } = {}
local lastLeaderboardRefreshClock = 0

local function getPlayerDataStoreKey(player: Player): string
    return string.format('player_%s', tostring(player.UserId))
end

local function getLeaderboardDataStoreKey(userId: number): string
    return string.format('player_%s', tostring(userId))
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

local function ensureLeaderboardTextLabel(): TextLabel?
    if globalLeaderboardTextLabel and globalLeaderboardTextLabel.Parent ~= nil then
        return globalLeaderboardTextLabel
    end

    local signBoard = workspace:FindFirstChild('GlobalLeaderboardSignBoard')
    if not signBoard or not signBoard:IsA('BasePart') then
        return nil
    end

    local surfaceGui = signBoard:FindFirstChild('LeaderboardSurfaceGui')
    if not surfaceGui or not surfaceGui:IsA('SurfaceGui') then
        if surfaceGui then
            surfaceGui:Destroy()
        end

        surfaceGui = Instance.new('SurfaceGui')
        surfaceGui.Name = 'LeaderboardSurfaceGui'
        surfaceGui.Face = Enum.NormalId.Right
        surfaceGui.AlwaysOnTop = true
        surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        surfaceGui.PixelsPerStud = 30
        surfaceGui.Parent = signBoard
    end

    local titleLabel = surfaceGui:FindFirstChild('LeaderboardLabel')
    if not titleLabel or not titleLabel:IsA('TextLabel') then
        if titleLabel then
            titleLabel:Destroy()
        end

        titleLabel = Instance.new('TextLabel')
        titleLabel.Name = 'LeaderboardLabel'
        titleLabel.Size = UDim2.fromScale(1, 1)
        titleLabel.BackgroundTransparency = 0.2
        titleLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        titleLabel.TextColor3 = Color3.fromRGB(255, 240, 189)
        titleLabel.TextStrokeTransparency = 0.35
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextYAlignment = Enum.TextYAlignment.Top
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextScaled = false
        titleLabel.TextSize = 22
        titleLabel.RichText = false
        titleLabel.TextWrapped = false
        titleLabel.Text = 'Loading leaderboard...'
        titleLabel.Parent = surfaceGui
    end

    globalLeaderboardTextLabel = titleLabel :: TextLabel
    return globalLeaderboardTextLabel
end

local function resolvePlayerName(userId: number): string
    local cachedName = cachedNamesByUserId[userId]
    if cachedName then
        return cachedName
    end

    local onlinePlayer = Players:GetPlayerByUserId(userId)
    if onlinePlayer then
        cachedNamesByUserId[userId] = onlinePlayer.DisplayName
        return onlinePlayer.DisplayName
    end

    local success, result = pcall(function()
        return Players:GetNameFromUserIdAsync(userId)
    end)

    if success and type(result) == 'string' then
        cachedNamesByUserId[userId] = result
        return result
    end

    return string.format('User %s', tostring(userId))
end

local function refreshGlobalLeaderboardSign()
    local signTextLabel = ensureLeaderboardTextLabel()
    if not signTextLabel then
        return
    end

    local success, pagesOrErr = pcall(function()
        return globalLeaderboardStore:GetSortedAsync(
            false,
            Constants.GLOBAL_LEADERBOARD_MAX_ENTRIES
        )
    end)

    if not success then
        warn(string.format('Failed to fetch global leaderboard page: %s', tostring(pagesOrErr)))
        signTextLabel.Text = 'GLOBAL ALL-TIME TOP SCORES\n\nFailed to load leaderboard'
        return
    end

    local page = pagesOrErr:GetCurrentPage()
    local entries = {}

    for _, item in ipairs(page) do
        local userId = tonumber(item.key)
        if userId ~= nil then
            table.insert(entries, {
                userId = userId,
                playerName = resolvePlayerName(userId),
                bestScore = item.value,
            })
        end
    end

    local normalizedEntries =
        GlobalLeaderboardLogic.normalizeEntries(entries, Constants.GLOBAL_LEADERBOARD_MAX_ENTRIES)

    signTextLabel.Text = GlobalLeaderboardLogic.buildSignText(normalizedEntries, function(score)
        return NumberFormat.formatCompact(score)
    end)
    lastLeaderboardRefreshClock = os.clock()
end

local function saveBestScoreForLeaderboard(userId: number, scoreValue: number)
    local success, err = pcall(function()
        globalLeaderboardStore:UpdateAsync(
            getLeaderboardDataStoreKey(userId),
            function(previousValue)
                local previousNumber = tonumber(previousValue)
                if previousNumber == nil then
                    return math.max(math.floor(scoreValue), 0)
                end

                return math.max(math.floor(scoreValue), math.floor(previousNumber))
            end
        )
    end)

    if not success then
        warn(
            string.format(
                'Failed to save global leaderboard score for user %s: %s',
                tostring(userId),
                tostring(err)
            )
        )
        return
    end

    refreshGlobalLeaderboardSign()
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

local function createPlayerState(score: number, rebirths: number): PlayerScoreState
    return {
        progressionState = ZoneProgressionLogic.newState(score, rebirths),
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

        saveBestScoreForLeaderboard(player.UserId, scoreToSave)

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

Players.PlayerAdded:Connect(function(player)
    cachedNamesByUserId[player.UserId] = player.DisplayName
    initializePlayerState(player)
end)

for _, player in Players:GetPlayers() do
    cachedNamesByUserId[player.UserId] = player.DisplayName
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
    if
        os.clock() - lastLeaderboardRefreshClock
        >= Constants.GLOBAL_LEADERBOARD_REFRESH_INTERVAL_SECONDS
    then
        refreshGlobalLeaderboardSign()
    end

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
            updateRankTitle(player, tickResult.state.score)
            markDirty(state)
            savePlayerState(player, false)
        end

        state.progressionState = tickResult.state
    end
end)

refreshGlobalLeaderboardSign()
