local DataStoreService = game:GetService('DataStoreService')
local InsertService = game:GetService('InsertService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local Debris = game:GetService('Debris')
local SoundService = game:GetService('SoundService')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local AdminLogic = require(Shared:WaitForChild('AdminLogic'))
local Constants = require(Shared:WaitForChild('Constants'))
local EquipmentLogic = require(Shared:WaitForChild('EquipmentLogic'))
local LuckyChestLogic = require(Shared:WaitForChild('LuckyChestLogic'))
local GlobalTopScoreLogic = require(Shared:WaitForChild('GlobalTopScoreLogic'))
local ProfileDataLogic = require(Shared:WaitForChild('ProfileDataLogic'))
local RankAuraLogic = require(Shared:WaitForChild('RankAuraLogic'))
local RankCelebrationLogic = require(Shared:WaitForChild('RankCelebrationLogic'))
local RankProgressionLogic = require(Shared:WaitForChild('RankProgressionLogic'))
local RebirthLogic = require(Shared:WaitForChild('RebirthLogic'))
local Remotes = require(Shared:WaitForChild('Remotes'))
local RewardCatalogLogic = require(Shared:WaitForChild('RewardCatalogLogic'))
local ZoneLogic = require(Shared:WaitForChild('ZoneLogic'))
local LockedZonePenaltyLogic = require(Shared:WaitForChild('LockedZonePenaltyLogic'))
local ZoneProgressionLogic = require(Shared:WaitForChild('ZoneProgressionLogic'))
local ProgressionBalance = require(Shared:WaitForChild('ProgressionBalance'))

type ZoneProgressionState = ZoneProgressionLogic.ZoneProgressionState
type ProfileData = ProfileDataLogic.ProfileData
type AdminReward = RewardCatalogLogic.AdminReward
type TopScoreRecord = GlobalTopScoreLogic.TopScoreRecord
type RankUpEvent = RankCelebrationLogic.RankUpEvent

type PlayerScoreState = {
    progressionState: ZoneProgressionState,
    profileData: ProfileData,
    dirtyVersion: number,
    lastSavedVersion: number,
    lastSaveClock: number,
    currentAuraRankIndex: number?,
    auraPulseClock: number,
    lastLockedZonePenaltyClock: number?,
    equippedMountInstance: Model?,
    storedWalkSpeed: number?,
    lastHasActiveScoringZone: boolean,
}

local scoreUpdatedEvent = Remotes.getOrCreateScoreUpdatedEvent()
local adminScoreMultiplyRequestEvent = Remotes.getOrCreateAdminScoreMultiplyRequestEvent()
local adminResetProgressRequestEvent = Remotes.getOrCreateAdminResetProgressRequestEvent()
local adminSkipLuckyChestTimerRequestEvent =
    Remotes.getOrCreateAdminSkipLuckyChestTimerRequestEvent()
local adminAddRewardRequestEvent = Remotes.getOrCreateAdminAddRewardRequestEvent()
local adminAddRewardResultEvent = Remotes.getOrCreateAdminAddRewardResultEvent()
local adminRewardCatalogUpdatedEvent = Remotes.getOrCreateAdminRewardCatalogUpdatedEvent()
local adminStateUpdatedEvent = Remotes.getOrCreateAdminStateUpdatedEvent()
local luckyChestStatusUpdatedEvent = Remotes.getOrCreateLuckyChestStatusUpdatedEvent()
local luckyChestOpenRequestEvent = Remotes.getOrCreateLuckyChestOpenRequestEvent()
local luckyChestOpenedEvent = Remotes.getOrCreateLuckyChestOpenedEvent()
local equipmentStateUpdatedEvent = Remotes.getOrCreateEquipmentStateUpdatedEvent()
local equipHatRequestEvent = Remotes.getOrCreateEquipHatRequestEvent()
local unequipHatRequestEvent = Remotes.getOrCreateUnequipHatRequestEvent()
local equipVehicleMountRequestEvent = Remotes.getOrCreateEquipVehicleMountRequestEvent()
local unequipVehicleMountRequestEvent = Remotes.getOrCreateUnequipVehicleMountRequestEvent()
local equipmentActionResultEvent = Remotes.getOrCreateEquipmentActionResultEvent()

local playerStates: { [Player]: PlayerScoreState } = {}
local scoreStore = DataStoreService:GetDataStore(Constants.SCORE_DATASTORE_NAME)
local globalTopScoreStore = DataStoreService:GetDataStore(Constants.GLOBAL_TOP_SCORE_DATASTORE_NAME)
local customRewardCatalogStore =
    DataStoreService:GetDataStore(Constants.CUSTOM_REWARD_CATALOG_DATASTORE_NAME)
local globalRankReachStore =
    DataStoreService:GetDataStore(Constants.GLOBAL_RANK_REACH_DATASTORE_NAME)
local customRewards: { AdminReward } = {}
local globalTopScoreRecord: TopScoreRecord = GlobalTopScoreLogic.normalizeRecord(nil)
local globalRankReachCounts: { [number]: number } = {}
local playerMountsFolder = workspace:FindFirstChild('PlayerMounts')
if not playerMountsFolder then
    playerMountsFolder = Instance.new('Folder')
    playerMountsFolder.Name = 'PlayerMounts'
    playerMountsFolder.Parent = workspace
end
local equipmentAssetCacheFolder = ServerStorage:FindFirstChild('LuckyChestAssetCache')
if not equipmentAssetCacheFolder then
    equipmentAssetCacheFolder = Instance.new('Folder')
    equipmentAssetCacheFolder.Name = 'LuckyChestAssetCache'
    equipmentAssetCacheFolder.Parent = ServerStorage
end
local assetTemplateCache: { [number]: Instance } = {}
local assetCacheOrder: { number } = {}
local assetFailureById: { [number]: number } = {}
local globalTopScoreUpdateInFlightByUserId: { [number]: boolean } = {}
local queuedTopScoreByUserId: { [number]: number } = {}
local forcedAssetOverrides: EquipmentLogic.ForcedAssetOverrides = {
    hatAssetId = Constants.FORCED_HAT_ASSET_ID,
    vehicleMountAssetId = Constants.FORCED_MOUNT_ASSET_ID,
}

local function getCustomLuckyChestRewards()
    local luckyChestRewards = {}
    for index, reward in ipairs(customRewards) do
        luckyChestRewards[index] = RewardCatalogLogic.toLuckyChestRewardItem(reward)
    end
    return luckyChestRewards
end

local function getRewardLookup()
    local categoryConfigs =
        LuckyChestLogic.getEffectiveCategoryConfigs(getCustomLuckyChestRewards())
    return EquipmentLogic.buildRewardLookup(categoryConfigs)
end

local function cloneArray(values: { string }): { string }
    return table.clone(values)
end

local function pushEquipmentState(player: Player, state: PlayerScoreState)
    local payload = EquipmentLogic.buildEquipmentStatePayload(state.profileData, getRewardLookup())
    if payload.equippedHatId ~= state.profileData.equippedHatId then
        state.profileData.equippedHatId = payload.equippedHatId
    end
    if payload.equippedVehicleMountId ~= state.profileData.equippedVehicleMountId then
        state.profileData.equippedVehicleMountId = payload.equippedVehicleMountId
    end

    equipmentStateUpdatedEvent:FireClient(player, {
        unlockedHats = cloneArray(payload.unlockedHats),
        unlockedVehicleMounts = cloneArray(payload.unlockedVehicleMounts),
        equippedHatId = payload.equippedHatId,
        equippedVehicleMountId = payload.equippedVehicleMountId,
        availableHats = payload.availableHats,
        availableVehicleMounts = payload.availableVehicleMounts,
    })
end

local function sendEquipmentResult(player: Player, success: boolean, message: string)
    equipmentActionResultEvent:FireClient(player, success, message)
end

local function stripScripts(root: Instance)
    for _, descendant in ipairs(root:GetDescendants()) do
        if
            descendant:IsA('Script')
            or descendant:IsA('LocalScript')
            or descendant:IsA('ModuleScript')
        then
            descendant:Destroy()
        end
    end
end

local function getFirstBasePart(root: Instance): BasePart?
    if root:IsA('BasePart') then
        return root
    end

    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA('BasePart') then
            return descendant
        end
    end

    return nil
end

local function rememberAssetTemplate(assetId: number, template: Instance)
    assetTemplateCache[assetId] = template
    table.insert(assetCacheOrder, assetId)
    if #assetCacheOrder > Constants.EQUIPMENT_ASSET_CACHE_SIZE then
        local oldestAssetId = table.remove(assetCacheOrder, 1)
        if oldestAssetId and oldestAssetId ~= assetId then
            local oldTemplate = assetTemplateCache[oldestAssetId]
            if oldTemplate then
                oldTemplate:Destroy()
                assetTemplateCache[oldestAssetId] = nil
            end
        end
    end
end

local function getSanitizedAssetTemplate(assetId: number): (boolean, string, Instance?)
    local cached = assetTemplateCache[assetId]
    if cached then
        return true, 'ok', cached
    end

    local now = os.time()
    local failedAt = assetFailureById[assetId]
    if failedAt and now - failedAt < Constants.EQUIPMENT_ASSET_FAILURE_RETRY_SECONDS then
        return false, 'Asset is temporarily unavailable. Try again soon.', nil
    end

    local success, loaded = pcall(function()
        return InsertService:LoadAsset(assetId)
    end)

    if not success or not loaded then
        assetFailureById[assetId] = now
        return false, 'Failed to load asset. Try another reward.', nil
    end

    stripScripts(loaded)
    if #loaded:GetDescendants() > 500 then
        loaded:Destroy()
        assetFailureById[assetId] = now
        return false, 'Reward asset is too large to equip safely.', nil
    end

    local hasPart = getFirstBasePart(loaded) ~= nil
    if not hasPart then
        loaded:Destroy()
        assetFailureById[assetId] = now
        return false, 'Reward asset has no usable parts.', nil
    end

    loaded.Name = string.format('Asset_%s', tostring(assetId))
    loaded.Parent = equipmentAssetCacheFolder
    rememberAssetTemplate(assetId, loaded)
    assetFailureById[assetId] = nil
    return true, 'ok', loaded
end

local function pushCustomRewardCatalogToPlayer(player: Player)
    adminRewardCatalogUpdatedEvent:FireClient(player, getCustomLuckyChestRewards())
end

local function broadcastCustomRewardCatalog()
    local rewards = getCustomLuckyChestRewards()
    for _, player in ipairs(Players:GetPlayers()) do
        adminRewardCatalogUpdatedEvent:FireClient(player, rewards)
    end
end

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

local function removeEquippedHatVisual(player: Player)
    local character = player.Character
    if not character then
        return
    end

    for _, child in ipairs(character:GetChildren()) do
        if string.match(child.Name, '^LuckyChestEquippedHat') then
            child:Destroy()
        end
    end
end

local function removeEquippedMountVisual(state: PlayerScoreState)
    local existing = state.equippedMountInstance
    if existing then
        existing:Destroy()
        state.equippedMountInstance = nil
    end
end

local function restoreWalkSpeed(player: Player, state: PlayerScoreState)
    local humanoid = getHumanoid(player)
    if humanoid and state.storedWalkSpeed then
        humanoid.WalkSpeed = state.storedWalkSpeed
    end
    state.storedWalkSpeed = nil
end

local function configurePartForMount(part: BasePart)
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
end

local function createMountModel(assetTemplate: Instance): (boolean, string, Model?)
    local sourceModel = assetTemplate:FindFirstChildWhichIsA('Model')
    local sourcePart = sourceModel and nil or getFirstBasePart(assetTemplate)

    local model: Model
    if sourceModel then
        model = sourceModel:Clone()
    elseif sourcePart then
        model = Instance.new('Model')
        sourcePart:Clone().Parent = model
    else
        return false, 'Failed to load asset. Try another reward.', nil
    end

    local primaryPart = model.PrimaryPart or getFirstBasePart(model)
    if not primaryPart then
        model:Destroy()
        return false, 'Reward asset has no usable parts.', nil
    end
    model.PrimaryPart = primaryPart

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA('BasePart') then
            configurePartForMount(descendant)
        end
    end

    return true, 'ok', model
end

local function equipHatVisual(
    player: Player,
    reward: EquipmentLogic.RewardDescriptor
): (boolean, string)
    local assetId = EquipmentLogic.resolveAssetIdForEquip(reward, forcedAssetOverrides)
    if not assetId then
        return false, 'That reward has no asset configured yet.'
    end

    local character = player.Character
    local humanoid = getHumanoid(player)
    if not character or not humanoid then
        return false, 'Character is not ready yet.'
    end

    local head = character:FindFirstChild('Head')
    if not head or not head:IsA('BasePart') then
        return false, 'Character is missing a head part.'
    end

    local ok, message, template = getSanitizedAssetTemplate(assetId)
    if not ok or not template then
        return false, message
    end

    removeEquippedHatVisual(player)

    local accessory = template:FindFirstChildWhichIsA('Accessory', true)
    if accessory then
        local accessoryClone = accessory:Clone()
        accessoryClone.Name = 'LuckyChestEquippedHatAccessory'
        local handle = accessoryClone:FindFirstChild('Handle')
        if handle and handle:IsA('BasePart') then
            humanoid:AddAccessory(accessoryClone)
            return true, string.format('Equipped %s.', reward.displayName)
        end
        accessoryClone:Destroy()
    end

    local sourceModel = template:FindFirstChildWhichIsA('Model')
    local sourcePart = sourceModel and nil or getFirstBasePart(template)
    local visual: Instance? = nil
    if sourceModel then
        visual = sourceModel:Clone()
    elseif sourcePart then
        visual = sourcePart:Clone()
    end
    if not visual then
        return false, 'Failed to load asset. Try another reward.'
    end

    local rootPart = getFirstBasePart(visual)
    if not rootPart then
        visual:Destroy()
        return false, 'Reward asset has no usable parts.'
    end

    if visual:IsA('Model') then
        for _, descendant in ipairs(visual:GetDescendants()) do
            if descendant:IsA('BasePart') then
                descendant.Anchored = false
                descendant.CanCollide = false
                descendant.CanTouch = false
                descendant.CanQuery = false
                descendant.Massless = true
            end
        end
        local model = visual :: Model
        model.Name = 'LuckyChestEquippedHatModel'
        if not model.PrimaryPart then
            model.PrimaryPart = rootPart
        end
        model:PivotTo(head.CFrame * CFrame.new(0, 0.65, 0))
        model.Parent = character
    else
        local part = visual :: BasePart
        part.Name = 'LuckyChestEquippedHatPart'
        part.Anchored = false
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Massless = true
        part.CFrame = head.CFrame * CFrame.new(0, 0.65, 0)
        part.Parent = character
    end

    local weld = Instance.new('WeldConstraint')
    weld.Part0 = head
    weld.Part1 = rootPart
    weld.Parent = rootPart
    -- TODO: tune per-asset offsets for hats that need custom placement.

    return true, string.format('Equipped %s.', reward.displayName)
end

local function equipMountVisual(
    player: Player,
    state: PlayerScoreState,
    reward: EquipmentLogic.RewardDescriptor
): (boolean, string)
    local assetId = EquipmentLogic.resolveAssetIdForEquip(reward, forcedAssetOverrides)
    if not assetId then
        return false, 'That reward has no asset configured yet.'
    end

    local character = player.Character
    local rootPart = getHumanoidRootPart(player)
    local humanoid = getHumanoid(player)
    if not character or not rootPart or not humanoid then
        return false, 'Character is not ready yet.'
    end

    local ok, message, template = getSanitizedAssetTemplate(assetId)
    if not ok or not template then
        return false, message
    end

    local modelOk, modelMessage, model = createMountModel(template)
    if not modelOk or not model then
        return false, modelMessage
    end

    removeEquippedMountVisual(state)
    restoreWalkSpeed(player, state)

    model.Name = 'LuckyChestEquippedMount'
    model.Parent = playerMountsFolder
    model:PivotTo(rootPart.CFrame * CFrame.new(0, -2.4, 0.5))

    local primaryPart = model.PrimaryPart
    if not primaryPart then
        model:Destroy()
        return false, 'Reward asset has no usable parts.'
    end

    local weld = Instance.new('WeldConstraint')
    weld.Part0 = rootPart
    weld.Part1 = primaryPart
    weld.Parent = primaryPart

    state.equippedMountInstance = model
    state.storedWalkSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = math.floor(state.storedWalkSpeed * Constants.MOUNT_WALK_SPEED_MULTIPLIER)

    -- TODO: tune mount offsets per-asset for best riding visuals.
    return true, 'Vehicle mount equipped.'
end

local function pushScore(
    player: Player,
    score: number,
    rebirths: number,
    hasActiveScoringZone: boolean?,
    rankUpEvents: { RankUpEvent }?
)
    scoreUpdatedEvent:FireClient(
        player,
        score,
        rebirths,
        hasActiveScoringZone == true,
        rankUpEvents
    )
end

local function getGlobalRankReachDataStoreKey(rankIndex: number): string
    return string.format('%s%s', Constants.GLOBAL_RANK_REACH_KEY_PREFIX, tostring(rankIndex))
end

local function containsRankIndex(rankIndices: { number }, rankIndex: number): boolean
    for _, value in ipairs(rankIndices) do
        if value == rankIndex then
            return true
        end
    end

    return false
end

local function incrementGlobalRankReachCount(rankIndex: number): number
    local dataStoreKey = getGlobalRankReachDataStoreKey(rankIndex)
    local success, result = pcall(function()
        return globalRankReachStore:UpdateAsync(dataStoreKey, function(oldValue)
            local previous = if type(oldValue) == 'number' then oldValue else 0
            return math.max(0, math.floor(previous)) + 1
        end)
    end)

    if not success then
        warn(
            string.format(
                'Failed to increment global rank reach count for rank %d: %s',
                rankIndex,
                tostring(result)
            )
        )
        local fallbackCount = globalRankReachCounts[rankIndex] or 0
        return math.max(1, fallbackCount)
    end

    local count = if type(result) == 'number' then math.max(0, math.floor(result)) else 0
    globalRankReachCounts[rankIndex] = count
    return count
end

local function getKnownGlobalRankReachCount(rankIndex: number): number
    return globalRankReachCounts[rankIndex] or 0
end

local function buildRankUpEvents(
    state: PlayerScoreState,
    previousRankIndex: number,
    nextRankIndex: number
): { RankUpEvent }
    local events = {}
    local newRankIndices = RankCelebrationLogic.getNewRankIndices(previousRankIndex, nextRankIndex)
    local totalRanks = #Constants.RANK_CONFIGS

    for _, rankIndex in ipairs(newRankIndices) do
        if rankIndex >= 1 and rankIndex <= totalRanks then
            local rankConfig = Constants.RANK_CONFIGS[rankIndex]
            local previousTimesReached = state.profileData.rankReachCounts[rankIndex] or 0
            local newTimesReached = previousTimesReached + 1
            state.profileData.rankReachCounts[rankIndex] = newTimesReached

            local hasContributedToGlobalCount =
                containsRankIndex(state.profileData.globallyCountedRankIndices, rankIndex)
            local globalPlayersReached = getKnownGlobalRankReachCount(rankIndex)

            if not hasContributedToGlobalCount then
                globalPlayersReached = incrementGlobalRankReachCount(rankIndex)
                table.insert(state.profileData.globallyCountedRankIndices, rankIndex)
            end

            events[#events + 1] = RankCelebrationLogic.buildRankUpEvent(
                rankIndex,
                rankConfig.name,
                rankConfig.description or '',
                newTimesReached,
                globalPlayersReached,
                previousTimesReached == 0
            )
        end
    end

    return events
end

local REBIRTH_CONFIG: RebirthLogic.RebirthConfig = {
    baseRequirementScore = Constants.REBIRTH_BASE_REQUIREMENT_SCORE,
    requirementGrowthPerRebirth = Constants.REBIRTH_REQUIREMENT_GROWTH_PER_REBIRTH,
    scoreToBonusPower = Constants.REBIRTH_SCORE_TO_BONUS_POWER,
    scoreToBonusScale = Constants.REBIRTH_SCORE_TO_BONUS_SCALE,
    maxBonusRebirthsFromScore = Constants.REBIRTH_MAX_BONUS_FROM_SCORE,
    hourlyFinalZoneBonus = {
        chancePerHour = Constants.REBIRTH_HOURLY_FINAL_ZONE_BONUS_CHANCE,
        activeWindowSeconds = Constants.REBIRTH_HOURLY_FINAL_ZONE_BONUS_WINDOW_SECONDS,
        bonusRebirths = Constants.REBIRTH_HOURLY_FINAL_ZONE_BONUS_REBIRTHS,
    },
}

local function getGlobalTopScoreLabel(): TextLabel?
    local screenPart = workspace:FindFirstChild(Constants.GLOBAL_TOP_SCORE_SCREEN_NAME)
    if not screenPart or not screenPart:IsA('BasePart') then
        return nil
    end

    local surfaceGui = screenPart:FindFirstChild('TopScoreSurfaceGui')
    if not surfaceGui or not surfaceGui:IsA('SurfaceGui') then
        return nil
    end

    local label = surfaceGui:FindFirstChild('TopScoreLabel')
    if label and label:IsA('TextLabel') then
        return label
    end

    return nil
end

local function refreshGlobalTopScoreScreen()
    local label = getGlobalTopScoreLabel()
    if not label then
        return
    end

    label.Text = GlobalTopScoreLogic.toScreenText(globalTopScoreRecord)
end

local function bindGlobalTopScoreScreen()
    refreshGlobalTopScoreScreen()

    workspace.DescendantAdded:Connect(function(descendant)
        if descendant.Name == 'TopScoreLabel' and descendant:IsA('TextLabel') then
            refreshGlobalTopScoreScreen()
        end
    end)
end

local function loadGlobalTopScoreRecord()
    local success, result = pcall(function()
        return globalTopScoreStore:GetAsync(Constants.GLOBAL_TOP_SCORE_DATASTORE_KEY)
    end)

    if not success then
        warn(string.format('Failed to load global top score: %s', tostring(result)))
        globalTopScoreRecord = GlobalTopScoreLogic.normalizeRecord(nil)
        refreshGlobalTopScoreScreen()
        return
    end

    globalTopScoreRecord = GlobalTopScoreLogic.normalizeRecord(result)
    refreshGlobalTopScoreScreen()
end

local function tryUpdateGlobalTopScore(player: Player, score: number)
    local candidateRecord =
        GlobalTopScoreLogic.createCandidateRecord(player.UserId, player.Name, score, os.time())

    if not GlobalTopScoreLogic.shouldReplaceRecord(globalTopScoreRecord, candidateRecord) then
        return
    end

    local success, result = pcall(function()
        return globalTopScoreStore:UpdateAsync(
            Constants.GLOBAL_TOP_SCORE_DATASTORE_KEY,
            function(old)
                local normalizedCurrent = GlobalTopScoreLogic.normalizeRecord(old)
                if GlobalTopScoreLogic.shouldReplaceRecord(normalizedCurrent, candidateRecord) then
                    return candidateRecord
                end

                return normalizedCurrent
            end
        )
    end)

    if not success then
        warn(string.format('Failed to update global top score: %s', tostring(result)))
        return
    end

    globalTopScoreRecord = GlobalTopScoreLogic.normalizeRecord(result)
    refreshGlobalTopScoreScreen()
end

local function requestGlobalTopScoreUpdate(player: Player, score: number)
    local userId = player.UserId
    local queuedScore = queuedTopScoreByUserId[userId]
    if queuedScore == nil or score > queuedScore then
        queuedTopScoreByUserId[userId] = score
    end

    if globalTopScoreUpdateInFlightByUserId[userId] then
        return
    end

    globalTopScoreUpdateInFlightByUserId[userId] = true

    task.spawn(function()
        while true do
            local nextScore = queuedTopScoreByUserId[userId]
            if nextScore == nil then
                break
            end

            queuedTopScoreByUserId[userId] = nil
            tryUpdateGlobalTopScore(player, nextScore)
        end

        globalTopScoreUpdateInFlightByUserId[userId] = nil
    end)
end

local function refreshProgressionHighWatermarks(progressionState: ZoneProgressionState)
    progressionState.highestScoreAchieved =
        math.max(progressionState.highestScoreAchieved, progressionState.score)
    progressionState.highestRankAchieved = math.max(
        progressionState.highestRankAchieved,
        RankProgressionLogic.getCurrentRankIndex(progressionState.score, Constants.RANK_CONFIGS)
    )
    progressionState.highestAgeAchieved = math.max(
        progressionState.highestAgeAchieved,
        ProgressionBalance.getHighestUnlockedAgeIndex(
            progressionState.score,
            Constants.AGE_ZONE_CONFIGS
        )
    )
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

local function loadCustomRewardCatalog()
    local success, result = pcall(function()
        return customRewardCatalogStore:GetAsync(Constants.CUSTOM_REWARD_CATALOG_DATASTORE_KEY)
    end)

    if not success then
        warn(string.format('Failed to load custom reward catalog: %s', tostring(result)))
        customRewards = {}
        return
    end

    if typeof(result) ~= 'table' or typeof(result.rewards) ~= 'table' then
        customRewards = {}
        return
    end

    local loadedRewards: { AdminReward } = {}
    local seenIds: { [string]: boolean } = {}
    for _, rawReward in ipairs(result.rewards) do
        if #loadedRewards >= Constants.CUSTOM_REWARD_CATALOG_MAX_REWARDS then
            break
        end
        if typeof(rawReward) == 'table' then
            local normalizedKind = RewardCatalogLogic.normalizeKind(rawReward.kind)
            local normalizedRarity = RewardCatalogLogic.normalizeRarity(rawReward.rarity)
            local displayName = RewardCatalogLogic.normalizeDisplayName(rawReward.displayName)
            local assetId = rawReward.assetId
            if
                normalizedKind
                and normalizedRarity
                and displayName
                and typeof(assetId) == 'number'
                and assetId > 0
            then
                local rewardId =
                    RewardCatalogLogic.buildRewardId(normalizedKind, math.floor(assetId))
                if seenIds[rewardId] then
                    continue
                end
                seenIds[rewardId] = true
                table.insert(loadedRewards, {
                    id = rewardId,
                    kind = normalizedKind,
                    displayName = displayName,
                    rarity = normalizedRarity,
                    assetId = math.floor(assetId),
                    sourceUrl = typeof(rawReward.sourceUrl) == 'string' and rawReward.sourceUrl
                        or nil,
                    createdAt = typeof(rawReward.createdAt) == 'number' and rawReward.createdAt
                        or os.time(),
                    createdByUserId = typeof(rawReward.createdByUserId) == 'number'
                            and rawReward.createdByUserId
                        or 0,
                })
            end
        end
    end

    customRewards = loadedRewards
end

local function saveCustomRewardCatalog(rewardsToSave: { AdminReward }): boolean
    local success, err = pcall(function()
        customRewardCatalogStore:SetAsync(Constants.CUSTOM_REWARD_CATALOG_DATASTORE_KEY, {
            rewards = rewardsToSave,
            updatedAt = os.time(),
        })
    end)

    if not success then
        warn(string.format('Failed to save custom reward catalog: %s', tostring(err)))
        return false
    end

    return true
end

local function createPlayerState(profileData: ProfileData): PlayerScoreState
    return {
        progressionState = ZoneProgressionLogic.newState(
            profileData.score,
            profileData.rebirths,
            profileData.highestScoreAchieved,
            profileData.highestRankAchieved,
            profileData.highestAgeAchieved
        ),
        profileData = profileData,
        dirtyVersion = 0,
        lastSavedVersion = 0,
        lastSaveClock = os.clock(),
        currentAuraRankIndex = nil,
        auraPulseClock = 0,
        lastLockedZonePenaltyClock = nil,
        equippedMountInstance = nil,
        storedWalkSpeed = nil,
        lastHasActiveScoringZone = false,
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
    state.profileData.highestScoreAchieved = state.progressionState.highestScoreAchieved
    state.profileData.highestRankAchieved = state.progressionState.highestRankAchieved
    state.profileData.highestAgeAchieved = state.progressionState.highestAgeAchieved
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

local function reapplyPersistedEquipment(player: Player, state: PlayerScoreState)
    if state.profileData.equippedHatId then
        local rewardLookup = getRewardLookup()
        local reward = rewardLookup[state.profileData.equippedHatId]
        if reward and reward.kind == 'hat' then
            local ok = equipHatVisual(player, reward)
            if not ok then
                removeEquippedHatVisual(player)
            end
        else
            state.profileData.equippedHatId = nil
            markDirty(state)
        end
    else
        removeEquippedHatVisual(player)
    end

    if state.profileData.equippedVehicleMountId then
        local rewardLookup = getRewardLookup()
        local reward = rewardLookup[state.profileData.equippedVehicleMountId]
        if reward and reward.kind == 'vehicleMount' then
            local ok = equipMountVisual(player, state, reward)
            if not ok then
                removeEquippedMountVisual(state)
                restoreWalkSpeed(player, state)
            end
        else
            state.profileData.equippedVehicleMountId = nil
            markDirty(state)
        end
    else
        removeEquippedMountVisual(state)
        restoreWalkSpeed(player, state)
    end
end

local function initializePlayerState(player: Player)
    local state = loadPlayerState(player)
    playerStates[player] = state
    requestGlobalTopScoreUpdate(player, state.progressionState.highestScoreAchieved)

    pushScore(player, state.progressionState.score, state.progressionState.rebirths, false)
    pushLuckyChestStatus(player, state.profileData)
    pushEquipmentState(player, state)
    updateRankTitle(player, state.progressionState.score)
    pushIsAdmin(player, isPlayerAdmin(player))
    pushCustomRewardCatalogToPlayer(player)

    player.CharacterAdded:Connect(function()
        local currentState = playerStates[player]
        if currentState then
            pushScore(
                player,
                currentState.progressionState.score,
                currentState.progressionState.rebirths,
                false
            )
            pushLuckyChestStatus(player, currentState.profileData)
            pushEquipmentState(player, currentState)
            updateRankTitle(player, currentState.progressionState.score)
            currentState.currentAuraRankIndex = nil
            updateRankAura(player, currentState)
            reapplyPersistedEquipment(player, currentState)
        end
    end)

    if player.Character then
        reapplyPersistedEquipment(player, state)
    end
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
    local previousRankIndex =
        RankProgressionLogic.getCurrentRankIndex(progressionState.score, Constants.RANK_CONFIGS)
    progressionState.score = AdminLogic.applyScoreMultiplier(progressionState.score, multiplier)
    refreshProgressionHighWatermarks(progressionState)
    local nextRankIndex =
        RankProgressionLogic.getCurrentRankIndex(progressionState.score, Constants.RANK_CONFIGS)
    local rankUpEvents = buildRankUpEvents(state, previousRankIndex, nextRankIndex)

    pushScore(player, progressionState.score, progressionState.rebirths, false, rankUpEvents)
    updateRankTitle(player, progressionState.score)
    requestGlobalTopScoreUpdate(player, progressionState.highestScoreAchieved)
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
    local previousRankIndex =
        RankProgressionLogic.getCurrentRankIndex(progressionState.score, Constants.RANK_CONFIGS)
    progressionState.score, progressionState.rebirths = AdminLogic.resetScoreAndRebirths()
    refreshProgressionHighWatermarks(progressionState)
    local nextRankIndex =
        RankProgressionLogic.getCurrentRankIndex(progressionState.score, Constants.RANK_CONFIGS)
    local rankUpEvents = buildRankUpEvents(state, previousRankIndex, nextRankIndex)

    pushScore(player, progressionState.score, progressionState.rebirths, false, rankUpEvents)
    updateRankTitle(player, progressionState.score)
    requestGlobalTopScoreUpdate(player, progressionState.highestScoreAchieved)
    updateRankAura(player, state)
    markDirty(state)
    savePlayerState(player, false)
end)

adminSkipLuckyChestTimerRequestEvent.OnServerEvent:Connect(function(player: Player)
    if not isPlayerAdmin(player) then
        return
    end

    local state = playerStates[player]
    if not state then
        return
    end

    state.profileData.nextLuckyChestOpenAt =
        AdminLogic.skipLuckyChestTimer(state.profileData.nextLuckyChestOpenAt)
    pushLuckyChestStatus(player, state.profileData)
    markDirty(state)
    savePlayerState(player, false)
end)

adminAddRewardRequestEvent.OnServerEvent:Connect(function(player: Player, payload)
    if not isPlayerAdmin(player) then
        adminAddRewardResultEvent:FireClient(player, false, 'Only admins can add rewards.', nil)
        return
    end

    local ok, message, normalizedSubmission = RewardCatalogLogic.normalizeSubmission(payload)
    if not ok or not normalizedSubmission then
        adminAddRewardResultEvent:FireClient(player, false, message, nil)
        return
    end

    local upsertOk, upsertMessage, nextRewards, reward = RewardCatalogLogic.upsertReward(
        customRewards,
        normalizedSubmission,
        os.time(),
        player.UserId,
        Constants.CUSTOM_REWARD_CATALOG_MAX_REWARDS
    )

    if not upsertOk or not nextRewards or not reward then
        adminAddRewardResultEvent:FireClient(player, false, upsertMessage, nil)
        return
    end

    if not saveCustomRewardCatalog(nextRewards) then
        adminAddRewardResultEvent:FireClient(player, false, 'Could not save reward catalog.', nil)
        return
    end

    customRewards = nextRewards
    adminAddRewardResultEvent:FireClient(player, true, 'Reward saved successfully.', reward)
    broadcastCustomRewardCatalog()
    for _, onlinePlayer in ipairs(Players:GetPlayers()) do
        local onlineState = playerStates[onlinePlayer]
        if onlineState then
            pushEquipmentState(onlinePlayer, onlineState)
        end
    end
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
        end,
        getCustomLuckyChestRewards()
    )

    if not spinResult then
        pushLuckyChestStatus(player, state.profileData)
        return
    end

    state.profileData = spinResult.profileData
    local previousRankIndex = RankProgressionLogic.getCurrentRankIndex(
        state.progressionState.score,
        Constants.RANK_CONFIGS
    )
    state.progressionState.score = spinResult.score
    state.progressionState.rebirths = spinResult.rebirths
    refreshProgressionHighWatermarks(state.progressionState)
    local nextRankIndex = RankProgressionLogic.getCurrentRankIndex(
        state.progressionState.score,
        Constants.RANK_CONFIGS
    )
    local rankUpEvents = buildRankUpEvents(state, previousRankIndex, nextRankIndex)

    pushScore(
        player,
        state.progressionState.score,
        state.progressionState.rebirths,
        false,
        rankUpEvents
    )
    updateRankTitle(player, state.progressionState.score)
    requestGlobalTopScoreUpdate(player, state.progressionState.highestScoreAchieved)
    pushLuckyChestStatus(player, state.profileData)
    pushEquipmentState(player, state)

    luckyChestOpenedEvent:FireClient(
        player,
        spinResult.spinResult,
        state.profileData.nextLuckyChestOpenAt,
        state.profileData.scoreBoostExpiresAt
    )

    markDirty(state)
    savePlayerState(player, false)
end)

equipHatRequestEvent.OnServerEvent:Connect(function(player: Player, rewardId: any)
    local state = playerStates[player]
    if not state then
        return
    end

    local ok, message, reward = EquipmentLogic.resolveEquipReward(
        rewardId,
        'hat',
        state.profileData.unlockedHats,
        getRewardLookup()
    )
    if not ok or not reward then
        sendEquipmentResult(player, false, message)
        return
    end

    local equipOk, equipMessage = equipHatVisual(player, reward)
    if not equipOk then
        sendEquipmentResult(player, false, equipMessage)
        return
    end

    state.profileData.equippedHatId = reward.id
    markDirty(state)
    pushEquipmentState(player, state)
    savePlayerState(player, false)
    sendEquipmentResult(player, true, equipMessage)
end)

unequipHatRequestEvent.OnServerEvent:Connect(function(player: Player)
    local state = playerStates[player]
    if not state then
        return
    end

    removeEquippedHatVisual(player)
    state.profileData.equippedHatId = nil
    markDirty(state)
    pushEquipmentState(player, state)
    savePlayerState(player, false)
    sendEquipmentResult(player, true, 'Unequipped hat.')
end)

equipVehicleMountRequestEvent.OnServerEvent:Connect(function(player: Player, rewardId: any)
    local state = playerStates[player]
    if not state then
        return
    end

    local ok, message, reward = EquipmentLogic.resolveEquipReward(
        rewardId,
        'vehicleMount',
        state.profileData.unlockedVehicleMounts,
        getRewardLookup()
    )
    if not ok or not reward then
        sendEquipmentResult(player, false, message)
        return
    end

    local equipOk, equipMessage = equipMountVisual(player, state, reward)
    if not equipOk then
        sendEquipmentResult(player, false, equipMessage)
        return
    end

    state.profileData.equippedVehicleMountId = reward.id
    markDirty(state)
    pushEquipmentState(player, state)
    savePlayerState(player, false)
    sendEquipmentResult(player, true, equipMessage)
end)

unequipVehicleMountRequestEvent.OnServerEvent:Connect(function(player: Player)
    local state = playerStates[player]
    if not state then
        return
    end

    removeEquippedMountVisual(state)
    restoreWalkSpeed(player, state)
    state.profileData.equippedVehicleMountId = nil
    markDirty(state)
    pushEquipmentState(player, state)
    savePlayerState(player, false)
    sendEquipmentResult(player, true, 'Unequipped vehicle mount.')
end)

loadCustomRewardCatalog()
loadGlobalTopScoreRecord()
bindGlobalTopScoreScreen()

Players.PlayerAdded:Connect(function(player)
    initializePlayerState(player)
end)

for _, player in Players:GetPlayers() do
    initializePlayerState(player)
end

Players.PlayerRemoving:Connect(function(player)
    local state = playerStates[player]
    if state then
        removeEquippedMountVisual(state)
    end
    queuedTopScoreByUserId[player.UserId] = nil
    globalTopScoreUpdateInFlightByUserId[player.UserId] = nil
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
            rankConfigs = Constants.RANK_CONFIGS,
            rebirthCatchUpPerRebirth = Constants.REBIRTH_CATCH_UP_PER_REBIRTH,
            maxCatchUpMultiplier = Constants.MAX_CATCH_UP_MULTIPLIER,
            postRecordRebirthMultiplier = Constants.POST_RECORD_REBIRTH_MULTIPLIER,
            bonusScoreMultiplier = boostedMultiplier,
            rankScoreMultiplier = RankProgressionLogic.getScoreMultiplierForScore(
                state.progressionState.score,
                Constants.RANK_CONFIGS,
                Constants.RANK_SCORE_MULTIPLIER_STEP
            ),
            rebirthConfig = REBIRTH_CONFIG,
            nowUnixTime = os.time(),
            isInsideFinalAgeZone = isInsideAgeZones[#Constants.AGE_ZONE_CONFIGS] == true,
        })
        local scoringZoneChanged = tickResult.hasActiveScoringZone ~= state.lastHasActiveScoringZone
        state.lastHasActiveScoringZone = tickResult.hasActiveScoringZone

        if
            tickResult.state.score ~= state.progressionState.score
            or tickResult.state.rebirths ~= state.progressionState.rebirths
        then
            local previousScore = state.progressionState.score
            state.progressionState = tickResult.state

            local previousRankIndex =
                RankProgressionLogic.getCurrentRankIndex(previousScore, Constants.RANK_CONFIGS)
            local nextRankIndex = RankProgressionLogic.getCurrentRankIndex(
                tickResult.state.score,
                Constants.RANK_CONFIGS
            )
            local rankUpEvents = buildRankUpEvents(state, previousRankIndex, nextRankIndex)

            pushScore(
                player,
                state.progressionState.score,
                state.progressionState.rebirths,
                tickResult.hasActiveScoringZone,
                rankUpEvents
            )
            updateRankTitle(player, state.progressionState.score)
            requestGlobalTopScoreUpdate(player, state.progressionState.highestScoreAchieved)
            markDirty(state)
            savePlayerState(player, false)
        elseif scoringZoneChanged then
            pushScore(
                player,
                state.progressionState.score,
                state.progressionState.rebirths,
                tickResult.hasActiveScoringZone
            )
        end

        updateRankAura(player, state)
    end
end)
