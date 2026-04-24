local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Remotes = {}

Remotes.FOLDER_NAME = 'Remotes'
Remotes.SCORE_UPDATED_EVENT = 'ScoreUpdated'
Remotes.ADMIN_SCORE_MULTIPLY_REQUEST_EVENT = 'AdminScoreMultiplyRequest'
Remotes.ADMIN_RESET_PROGRESS_REQUEST_EVENT = 'AdminResetProgressRequest'
Remotes.ADMIN_SKIP_LUCKY_CHEST_TIMER_REQUEST_EVENT = 'AdminSkipLuckyChestTimerRequest'
Remotes.ADMIN_ADD_REWARD_REQUEST_EVENT = 'AdminAddRewardRequest'
Remotes.ADMIN_ADD_REWARD_RESULT_EVENT = 'AdminAddRewardResult'
Remotes.ADMIN_REWARD_CATALOG_UPDATED_EVENT = 'AdminRewardCatalogUpdated'
Remotes.ADMIN_STATE_UPDATED_EVENT = 'AdminStateUpdated'
Remotes.LUCKY_CHEST_STATUS_UPDATED_EVENT = 'LuckyChestStatusUpdated'
Remotes.LUCKY_CHEST_OPEN_REQUEST_EVENT = 'LuckyChestOpenRequest'
Remotes.LUCKY_CHEST_OPENED_EVENT = 'LuckyChestOpened'

Remotes.EQUIPMENT_STATE_UPDATED_EVENT = 'EquipmentStateUpdated'
Remotes.EQUIP_HAT_REQUEST_EVENT = 'EquipHatRequest'
Remotes.UNEQUIP_HAT_REQUEST_EVENT = 'UnequipHatRequest'
Remotes.EQUIP_VEHICLE_MOUNT_REQUEST_EVENT = 'EquipVehicleMountRequest'
Remotes.UNEQUIP_VEHICLE_MOUNT_REQUEST_EVENT = 'UnequipVehicleMountRequest'
Remotes.EQUIPMENT_ACTION_RESULT_EVENT = 'EquipmentActionResult'

local function getOrCreateFolder(): Folder
    local folder = ReplicatedStorage:FindFirstChild(Remotes.FOLDER_NAME)
    if not folder then
        folder = Instance.new('Folder')
        folder.Name = Remotes.FOLDER_NAME
        folder.Parent = ReplicatedStorage
    end

    return folder :: Folder
end

local function getOrCreateRemoteEvent(eventName: string): RemoteEvent
    local folder = getOrCreateFolder()
    local event = folder:FindFirstChild(eventName)
    if not event then
        event = Instance.new('RemoteEvent')
        event.Name = eventName
        event.Parent = folder
    end

    return event :: RemoteEvent
end

local function waitForRemoteEvent(eventName: string): RemoteEvent
    local folder = ReplicatedStorage:WaitForChild(Remotes.FOLDER_NAME)
    local event = folder:WaitForChild(eventName)
    return event :: RemoteEvent
end

function Remotes.getOrCreateScoreUpdatedEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.SCORE_UPDATED_EVENT)
end

function Remotes.waitForScoreUpdatedEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.SCORE_UPDATED_EVENT)
end

function Remotes.getOrCreateAdminScoreMultiplyRequestEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.ADMIN_SCORE_MULTIPLY_REQUEST_EVENT)
end

function Remotes.waitForAdminScoreMultiplyRequestEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.ADMIN_SCORE_MULTIPLY_REQUEST_EVENT)
end

function Remotes.getOrCreateAdminResetProgressRequestEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.ADMIN_RESET_PROGRESS_REQUEST_EVENT)
end

function Remotes.waitForAdminResetProgressRequestEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.ADMIN_RESET_PROGRESS_REQUEST_EVENT)
end

function Remotes.getOrCreateAdminSkipLuckyChestTimerRequestEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.ADMIN_SKIP_LUCKY_CHEST_TIMER_REQUEST_EVENT)
end

function Remotes.waitForAdminSkipLuckyChestTimerRequestEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.ADMIN_SKIP_LUCKY_CHEST_TIMER_REQUEST_EVENT)
end

function Remotes.getOrCreateAdminAddRewardRequestEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.ADMIN_ADD_REWARD_REQUEST_EVENT)
end

function Remotes.waitForAdminAddRewardRequestEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.ADMIN_ADD_REWARD_REQUEST_EVENT)
end

function Remotes.getOrCreateAdminAddRewardResultEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.ADMIN_ADD_REWARD_RESULT_EVENT)
end

function Remotes.waitForAdminAddRewardResultEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.ADMIN_ADD_REWARD_RESULT_EVENT)
end

function Remotes.getOrCreateAdminRewardCatalogUpdatedEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.ADMIN_REWARD_CATALOG_UPDATED_EVENT)
end

function Remotes.waitForAdminRewardCatalogUpdatedEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.ADMIN_REWARD_CATALOG_UPDATED_EVENT)
end

function Remotes.getOrCreateAdminStateUpdatedEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.ADMIN_STATE_UPDATED_EVENT)
end

function Remotes.waitForAdminStateUpdatedEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.ADMIN_STATE_UPDATED_EVENT)
end

function Remotes.getOrCreateLuckyChestStatusUpdatedEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.LUCKY_CHEST_STATUS_UPDATED_EVENT)
end

function Remotes.waitForLuckyChestStatusUpdatedEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.LUCKY_CHEST_STATUS_UPDATED_EVENT)
end

function Remotes.getOrCreateLuckyChestOpenRequestEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.LUCKY_CHEST_OPEN_REQUEST_EVENT)
end

function Remotes.waitForLuckyChestOpenRequestEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.LUCKY_CHEST_OPEN_REQUEST_EVENT)
end

function Remotes.getOrCreateLuckyChestOpenedEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.LUCKY_CHEST_OPENED_EVENT)
end

function Remotes.waitForLuckyChestOpenedEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.LUCKY_CHEST_OPENED_EVENT)
end

function Remotes.getOrCreateEquipmentStateUpdatedEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.EQUIPMENT_STATE_UPDATED_EVENT)
end

function Remotes.waitForEquipmentStateUpdatedEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.EQUIPMENT_STATE_UPDATED_EVENT)
end

function Remotes.getOrCreateEquipHatRequestEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.EQUIP_HAT_REQUEST_EVENT)
end

function Remotes.waitForEquipHatRequestEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.EQUIP_HAT_REQUEST_EVENT)
end

function Remotes.getOrCreateUnequipHatRequestEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.UNEQUIP_HAT_REQUEST_EVENT)
end

function Remotes.waitForUnequipHatRequestEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.UNEQUIP_HAT_REQUEST_EVENT)
end

function Remotes.getOrCreateEquipVehicleMountRequestEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.EQUIP_VEHICLE_MOUNT_REQUEST_EVENT)
end

function Remotes.waitForEquipVehicleMountRequestEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.EQUIP_VEHICLE_MOUNT_REQUEST_EVENT)
end

function Remotes.getOrCreateUnequipVehicleMountRequestEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.UNEQUIP_VEHICLE_MOUNT_REQUEST_EVENT)
end

function Remotes.waitForUnequipVehicleMountRequestEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.UNEQUIP_VEHICLE_MOUNT_REQUEST_EVENT)
end

function Remotes.getOrCreateEquipmentActionResultEvent(): RemoteEvent
    return getOrCreateRemoteEvent(Remotes.EQUIPMENT_ACTION_RESULT_EVENT)
end

function Remotes.waitForEquipmentActionResultEvent(): RemoteEvent
    return waitForRemoteEvent(Remotes.EQUIPMENT_ACTION_RESULT_EVENT)
end

return Remotes
