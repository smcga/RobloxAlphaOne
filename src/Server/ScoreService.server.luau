local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local Constants = require(Shared:WaitForChild('Constants'))
local Remotes = require(Shared:WaitForChild('Remotes'))
local ZoneLogic = require(Shared:WaitForChild('ZoneLogic'))
local ZoneProgressionLogic = require(Shared:WaitForChild('ZoneProgressionLogic'))

type ZoneProgressionState = ZoneProgressionLogic.ZoneProgressionState

type PlayerScoreState = {
    progressionState: ZoneProgressionState,
}

local scoreUpdatedEvent = Remotes.getOrCreateScoreUpdatedEvent()
local playerStates: { [Player]: PlayerScoreState } = {}

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

local function pushScore(player: Player, score: number)
    scoreUpdatedEvent:FireClient(player, score)
end

local function resetPlayerState(player: Player)
    playerStates[player] = {
        progressionState = ZoneProgressionLogic.newState(0),
    }

    pushScore(player, 0)
end

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
    resetPlayerState(player)

    player.CharacterAdded:Connect(function()
        resetPlayerState(player)
    end)
end)

for _, player in Players:GetPlayers() do
    resetPlayerState(player)

    player.CharacterAdded:Connect(function()
        resetPlayerState(player)
    end)
end

Players.PlayerRemoving:Connect(function(player)
    playerStates[player] = nil
end)

RunService.Heartbeat:Connect(function(deltaSeconds: number)
    for player, state in pairs(playerStates) do
        local rootPart = getHumanoidRootPart(player)
        local isInsideBlueZone = false
        local isInsideRedZone = false

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
        end

        local tickResult = ZoneProgressionLogic.tick(state.progressionState, {
            deltaSeconds = deltaSeconds,
            isInsideBlueZone = isInsideBlueZone,
            isInsideRedZone = isInsideRedZone,
            scoreIntervalSeconds = Constants.SCORE_INTERVAL_SECONDS,
            blueIncrement = Constants.BLUE_SCORE_INCREMENT,
            redIncrement = Constants.RED_SCORE_INCREMENT,
            redRequiredScore = Constants.RED_ZONE_REQUIRED_SCORE,
        })

        if tickResult.shouldPunishForRedZone and rootPart then
            punishForRedZone(player, rootPart)
        end

        if tickResult.state.score ~= state.progressionState.score then
            pushScore(player, tickResult.state.score)
        end

        state.progressionState = tickResult.state
    end
end)
