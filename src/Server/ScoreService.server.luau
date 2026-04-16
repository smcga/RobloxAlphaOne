local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local Constants = require(Shared:WaitForChild('Constants'))
local Remotes = require(Shared:WaitForChild('Remotes'))
local ScoreLogic = require(Shared:WaitForChild('ScoreLogic'))
local ZoneLogic = require(Shared:WaitForChild('ZoneLogic'))

type TickState = typeof(ScoreLogic.newState())

type PlayerScoreState = {
    tickState: TickState,
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

local function pushScore(player: Player, score: number)
    scoreUpdatedEvent:FireClient(player, score)
end

local function resetPlayerState(player: Player)
    playerStates[player] = {
        tickState = ScoreLogic.newState(0),
    }

    pushScore(player, 0)
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
        local isInside = false

        if rootPart then
            isInside = ZoneLogic.isPositionInsideCircle(
                rootPart.Position,
                Constants.ZONE_CENTER,
                Constants.ZONE_RADIUS
            )
        end

        local nextState = ScoreLogic.tick(
            state.tickState,
            deltaSeconds,
            isInside,
            Constants.SCORE_INTERVAL_SECONDS,
            Constants.SCORE_INCREMENT
        )

        if nextState.score ~= state.tickState.score then
            pushScore(player, nextState.score)
        end

        state.tickState = nextState
    end
end)
