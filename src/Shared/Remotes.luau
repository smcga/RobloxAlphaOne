local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Remotes = {}

Remotes.FOLDER_NAME = 'Remotes'
Remotes.SCORE_UPDATED_EVENT = 'ScoreUpdated'

function Remotes.getOrCreateScoreUpdatedEvent(): RemoteEvent
    local folder = ReplicatedStorage:FindFirstChild(Remotes.FOLDER_NAME)
    if not folder then
        folder = Instance.new('Folder')
        folder.Name = Remotes.FOLDER_NAME
        folder.Parent = ReplicatedStorage
    end

    local event = folder:FindFirstChild(Remotes.SCORE_UPDATED_EVENT)
    if not event then
        event = Instance.new('RemoteEvent')
        event.Name = Remotes.SCORE_UPDATED_EVENT
        event.Parent = folder
    end

    return event :: RemoteEvent
end

function Remotes.waitForScoreUpdatedEvent(): RemoteEvent
    local folder = ReplicatedStorage:WaitForChild(Remotes.FOLDER_NAME)
    local event = folder:WaitForChild(Remotes.SCORE_UPDATED_EVENT)
    return event :: RemoteEvent
end

return Remotes
