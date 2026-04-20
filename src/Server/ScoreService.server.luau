local DataStoreService = game:GetService('DataStoreService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local Constants = require(Shared:WaitForChild('Constants'))
local AdminLogic = require(Shared:WaitForChild('AdminLogic'))
local ProfileDataLogic = require(Shared:WaitForChild('ProfileDataLogic'))
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

local function getHumanoid(player: Player): Humanoid?
    local character = player.Character
    if not character then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass('Humanoid')
    if humanoid then
        return humanoid
    end

    return nil
end

local function pushScore(player: Player, score: number, rebirths: number)
    scoreUpdatedEvent:FireClient(player, score, rebirths)
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
    pushIsAdmin(player, isPlayerAdmin(player))

    player.CharacterAdded:Connect(function()
        local currentState = playerStates[player]
        if currentState then
            pushScore(
                player,
                currentState.progressionState.score,
                currentState.progressionState.rebirths
            )
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
    markDirty(state)
    savePlayerState(player, false)
end)

local function punishForRedZone(player: Player, rootPart: BasePart)
    local direction = rootPart.Position - Constants.RED_ZONE_CENTER
    local flatDirection = Vector3.new(direction.X, 0, direction.Z)

    if flatDirection.Magnitude < 0.001 then
        flatDirection = Vector3.new(1, 0, 0)
    else
        flatDirection = flatDirection.Unit
    end

    rootPart.AssemblyLinearVelocity = (flatDirection * Constants.RED_ZONE_LAUNCH_SPEED)
        + Vector3.new(0, Constants.RED_ZONE_LAUNCH_UPWARD_SPEED, 0)

    local humanoid = getHumanoid(player)
    if humanoid and humanoid.Health > 0 then
        task.delay(0.15, function()
            if humanoid.Parent and humanoid.Health > 0 then
                humanoid.Health = 0
            end
        end)
    end
end

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
        local isInsideBlueZone = false
        local isInsideRedZone = false
        local isInsideRebirthZone = false

        if rootPart then
            isInsideBlueZone = ZoneLogic.isPositionInsideCircle(
                rootPart.Position,
                Constants.BLUE_ZONE_CENTER,
                Constants.BLUE_ZONE_RADIUS
            )
            isInsideRedZone = ZoneLogic.isPositionInsideCircle(
                rootPart.Position,
                Constants.RED_ZONE_CENTER,
                Constants.RED_ZONE_RADIUS
            )
            isInsideRebirthZone = ZoneLogic.isPositionInsideCircle(
                rootPart.Position,
                Constants.REBIRTH_ZONE_CENTER,
                Constants.REBIRTH_ZONE_RADIUS
            )
        end

        local tickResult = ZoneProgressionLogic.tick(state.progressionState, {
            deltaSeconds = deltaSeconds,
            isInsideBlueZone = isInsideBlueZone,
            isInsideRedZone = isInsideRedZone,
            scoreIntervalSeconds = Constants.SCORE_INTERVAL_SECONDS,
            blueIncrement = Constants.BLUE_SCORE_INCREMENT,
            redIncrement = Constants.RED_SCORE_INCREMENT,
            redRequiredScore = Constants.RED_ZONE_REQUIRED_SCORE,
            isInsideRebirthZone = isInsideRebirthZone,
            rebirthScoreDivisor = Constants.REBIRTH_SCORE_DIVISOR,
        })

        if tickResult.shouldPunishForRedZone and rootPart then
            punishForRedZone(player, rootPart)
        end

        if
            tickResult.state.score ~= state.progressionState.score
            or tickResult.state.rebirths ~= state.progressionState.rebirths
        then
            pushScore(player, tickResult.state.score, tickResult.state.rebirths)
            markDirty(state)
            savePlayerState(player, false)
        end

        state.progressionState = tickResult.state
    end
end)
