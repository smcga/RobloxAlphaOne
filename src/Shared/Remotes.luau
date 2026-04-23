local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Remotes = {}

Remotes.FOLDER_NAME = 'Remotes'
Remotes.SCORE_UPDATED_EVENT = 'ScoreUpdated'
Remotes.ADMIN_SCORE_MULTIPLY_REQUEST_EVENT = 'AdminScoreMultiplyRequest'
Remotes.ADMIN_RESET_PROGRESS_REQUEST_EVENT = 'AdminResetProgressRequest'
Remotes.ADMIN_STATE_UPDATED_EVENT = 'AdminStateUpdated'

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

function Remotes.getOrCreateAdminScoreMultiplyRequestEvent(): RemoteEvent
    local folder = ReplicatedStorage:FindFirstChild(Remotes.FOLDER_NAME)
    if not folder then
        folder = Instance.new('Folder')
        folder.Name = Remotes.FOLDER_NAME
        folder.Parent = ReplicatedStorage
    end

    local event = folder:FindFirstChild(Remotes.ADMIN_SCORE_MULTIPLY_REQUEST_EVENT)
    if not event then
        event = Instance.new('RemoteEvent')
        event.Name = Remotes.ADMIN_SCORE_MULTIPLY_REQUEST_EVENT
        event.Parent = folder
    end

    return event :: RemoteEvent
end

function Remotes.waitForAdminScoreMultiplyRequestEvent(): RemoteEvent
    local folder = ReplicatedStorage:WaitForChild(Remotes.FOLDER_NAME)
    local event = folder:WaitForChild(Remotes.ADMIN_SCORE_MULTIPLY_REQUEST_EVENT)
    return event :: RemoteEvent
end

function Remotes.getOrCreateAdminResetProgressRequestEvent(): RemoteEvent
    local folder = ReplicatedStorage:FindFirstChild(Remotes.FOLDER_NAME)
    if not folder then
        folder = Instance.new('Folder')
        folder.Name = Remotes.FOLDER_NAME
        folder.Parent = ReplicatedStorage
    end

    local event = folder:FindFirstChild(Remotes.ADMIN_RESET_PROGRESS_REQUEST_EVENT)
    if not event then
        event = Instance.new('RemoteEvent')
        event.Name = Remotes.ADMIN_RESET_PROGRESS_REQUEST_EVENT
        event.Parent = folder
    end

    return event :: RemoteEvent
end

function Remotes.waitForAdminResetProgressRequestEvent(): RemoteEvent
    local folder = ReplicatedStorage:WaitForChild(Remotes.FOLDER_NAME)
    local event = folder:WaitForChild(Remotes.ADMIN_RESET_PROGRESS_REQUEST_EVENT)
    return event :: RemoteEvent
end

function Remotes.getOrCreateAdminStateUpdatedEvent(): RemoteEvent
    local folder = ReplicatedStorage:FindFirstChild(Remotes.FOLDER_NAME)
    if not folder then
        folder = Instance.new('Folder')
        folder.Name = Remotes.FOLDER_NAME
        folder.Parent = ReplicatedStorage
    end

    local event = folder:FindFirstChild(Remotes.ADMIN_STATE_UPDATED_EVENT)
    if not event then
        event = Instance.new('RemoteEvent')
        event.Name = Remotes.ADMIN_STATE_UPDATED_EVENT
        event.Parent = folder
    end

    return event :: RemoteEvent
end

function Remotes.waitForAdminStateUpdatedEvent(): RemoteEvent
    local folder = ReplicatedStorage:WaitForChild(Remotes.FOLDER_NAME)
    local event = folder:WaitForChild(Remotes.ADMIN_STATE_UPDATED_EVENT)
    return event :: RemoteEvent
end

return Remotes
