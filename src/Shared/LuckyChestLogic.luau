export type LuckyChestRarity = 'green' | 'blue' | 'purple' | 'orange' | 'gold'

export type LuckyChestCategory =
    'scoreBonus'
    | 'rebirthBonus'
    | 'hat'
    | 'pet'
    | 'scoreBoost'
    | 'vehicleMount'

export type LuckyChestRewardItem = {
    id: string,
    displayName: string,
    rarity: LuckyChestRarity,
    scoreAmount: number?,
    rebirthAmount: number?,
    assetId: number?,
    sourceUrl: string?,
    rewardKind: 'hat' | 'vehicleMount'?,
}

export type LuckyChestProfileData = {
    nextLuckyChestOpenAt: number,
    scoreBoostExpiresAt: number,
    unlockedHats: { string },
    unlockedPets: { string },
    unlockedVehicleMounts: { string },
    equippedHatId: string?,
    equippedVehicleMountId: string?,
}

export type LuckyChestSpinResult = {
    category: LuckyChestCategory,
    categoryDisplayName: string,
    categoryRarity: LuckyChestRarity,
    categorySpinOptions: { { displayName: string, rarity: LuckyChestRarity } },
    item: LuckyChestRewardItem,
    itemSpinOptions: { { displayName: string, rarity: LuckyChestRarity } },
    scoreGranted: number,
    rebirthsGranted: number,
    scoreBoostMultiplier: number,
    scoreBoostDurationSeconds: number,
}

export type LuckyChestApplyResult = {
    profileData: LuckyChestProfileData,
    score: number,
    rebirths: number,
    spinResult: LuckyChestSpinResult,
}

type WeightedEntry<T> = {
    value: T,
    weight: number,
}

local LuckyChestLogic = {}

local RARITY_WEIGHTS: { WeightedEntry<LuckyChestRarity> } = {
    { value = 'green', weight = 55 },
    { value = 'blue', weight = 25 },
    { value = 'purple', weight = 12 },
    { value = 'orange', weight = 6 },
    { value = 'gold', weight = 2 },
}

local CATEGORY_CONFIGS: {
    {
        id: LuckyChestCategory,
        displayName: string,
        rarity: LuckyChestRarity,
        items: { LuckyChestRewardItem },
    }
} =
    {
        {
            id = 'scoreBonus',
            displayName = 'Bonus Score',
            rarity = 'green',
            items = {
                {
                    id = 'score_small',
                    displayName = '+2.5k Score',
                    rarity = 'green',
                    scoreAmount = 2500,
                },
                {
                    id = 'score_medium',
                    displayName = '+15k Score',
                    rarity = 'blue',
                    scoreAmount = 15000,
                },
                {
                    id = 'score_large',
                    displayName = '+90k Score',
                    rarity = 'purple',
                    scoreAmount = 90000,
                },
                {
                    id = 'score_huge',
                    displayName = '+650k Score',
                    rarity = 'orange',
                    scoreAmount = 650000,
                },
                {
                    id = 'score_legend',
                    displayName = '+5M Score',
                    rarity = 'gold',
                    scoreAmount = 5000000,
                },
            },
        },
        {
            id = 'rebirthBonus',
            displayName = 'Bonus Rebirths',
            rarity = 'blue',
            items = {
                {
                    id = 'rebirth_1',
                    displayName = '+1 Rebirth',
                    rarity = 'green',
                    rebirthAmount = 1,
                },
                {
                    id = 'rebirth_3',
                    displayName = '+3 Rebirths',
                    rarity = 'blue',
                    rebirthAmount = 3,
                },
                {
                    id = 'rebirth_8',
                    displayName = '+8 Rebirths',
                    rarity = 'purple',
                    rebirthAmount = 8,
                },
                {
                    id = 'rebirth_20',
                    displayName = '+20 Rebirths',
                    rarity = 'orange',
                    rebirthAmount = 20,
                },
                {
                    id = 'rebirth_60',
                    displayName = '+60 Rebirths',
                    rarity = 'gold',
                    rebirthAmount = 60,
                },
            },
        },
        {
            id = 'hat',
            displayName = 'New Hat',
            rarity = 'purple',
            items = {
                { id = 'hat_copper_crown', displayName = 'Copper Crown', rarity = 'green' },
                { id = 'hat_neon_headset', displayName = 'Neon Headset', rarity = 'blue' },
                { id = 'hat_arcane_halo', displayName = 'Arcane Halo', rarity = 'purple' },
                { id = 'hat_solar_diadem', displayName = 'Solar Diadem', rarity = 'orange' },
                { id = 'hat_omega_aureole', displayName = 'Omega Aureole', rarity = 'gold' },
            },
        },
        {
            id = 'pet',
            displayName = 'New Pet',
            rarity = 'purple',
            items = {
                { id = 'pet_sprout_cube', displayName = 'Sprout Cube', rarity = 'green' },
                { id = 'pet_spark_fox', displayName = 'Spark Fox', rarity = 'blue' },
                { id = 'pet_quantum_mite', displayName = 'Quantum Mite', rarity = 'purple' },
                { id = 'pet_comet_drake', displayName = 'Comet Drake', rarity = 'orange' },
                { id = 'pet_sunbound_phoenix', displayName = 'Sunbound Phoenix', rarity = 'gold' },
            },
        },
        {
            id = 'scoreBoost',
            displayName = '10x Score Boost',
            rarity = 'orange',
            items = {
                {
                    id = 'score_boost_10x_1m',
                    displayName = '10x Score for 1 minute',
                    rarity = 'orange',
                },
                {
                    id = 'score_boost_10x_1m_gold',
                    displayName = '10x Score for 1 minute+',
                    rarity = 'gold',
                },
            },
        },
        {
            id = 'vehicleMount',
            displayName = 'Vehicle Mount',
            rarity = 'orange',
            items = {
                { id = 'mount_gear_skimmer', displayName = 'Gear Skimmer', rarity = 'blue' },
                { id = 'mount_relay_runner', displayName = 'Relay Runner', rarity = 'purple' },
                { id = 'mount_plasma_board', displayName = 'Plasma Board', rarity = 'orange' },
                {
                    id = 'mount_starlight_roadster',
                    displayName = 'Starlight Roadster',
                    rarity = 'gold',
                },
            },
        },
    }

local function cloneStringArray(values: { string }): { string }
    local cloned = {}
    for index, value in ipairs(values) do
        cloned[index] = value
    end

    return cloned
end

local function addUniqueString(values: { string }, value: string)
    for _, existing in ipairs(values) do
        if existing == value then
            return
        end
    end

    values[#values + 1] = value
end

local function rarityWeight(rarity: LuckyChestRarity): number
    for _, entry in ipairs(RARITY_WEIGHTS) do
        if entry.value == rarity then
            return entry.weight
        end
    end

    return 0
end

local function spinWeighted<T>(entries: { WeightedEntry<T> }, random01: number): T
    local totalWeight = 0
    for _, entry in ipairs(entries) do
        totalWeight += entry.weight
    end

    local threshold = math.clamp(random01, 0, 0.999999) * totalWeight
    local rolling = 0

    for _, entry in ipairs(entries) do
        rolling += entry.weight
        if threshold < rolling then
            return entry.value
        end
    end

    return entries[#entries].value
end

local function asSpinOptions(
    options: { { displayName: string, rarity: LuckyChestRarity } }
): { { displayName: string, rarity: LuckyChestRarity } }
    local cloned = {}
    for index, option in ipairs(options) do
        cloned[index] = {
            displayName = option.displayName,
            rarity = option.rarity,
        }
    end

    return cloned
end

function LuckyChestLogic.getCategoryConfigs()
    return CATEGORY_CONFIGS
end

local function cloneRewardItem(item: LuckyChestRewardItem): LuckyChestRewardItem
    return {
        id = item.id,
        displayName = item.displayName,
        rarity = item.rarity,
        scoreAmount = item.scoreAmount,
        rebirthAmount = item.rebirthAmount,
        assetId = item.assetId,
        sourceUrl = item.sourceUrl,
        rewardKind = item.rewardKind,
    }
end

local function cloneCategoryConfig(category)
    local items = {}
    for itemIndex, item in ipairs(category.items) do
        items[itemIndex] = cloneRewardItem(item)
    end

    return {
        id = category.id,
        displayName = category.displayName,
        rarity = category.rarity,
        items = items,
    }
end

function LuckyChestLogic.getEffectiveCategoryConfigs(customRewards: { LuckyChestRewardItem }?)
    local effectiveConfigs = {}
    local hatConfig = nil
    local vehicleMountConfig = nil

    for categoryIndex, category in ipairs(CATEGORY_CONFIGS) do
        local clonedConfig = cloneCategoryConfig(category)
        effectiveConfigs[categoryIndex] = clonedConfig

        if clonedConfig.id == 'hat' then
            hatConfig = clonedConfig
        elseif clonedConfig.id == 'vehicleMount' then
            vehicleMountConfig = clonedConfig
        end
    end

    if customRewards then
        for _, customReward in ipairs(customRewards) do
            if
                (customReward.rewardKind == 'hat' or string.match(customReward.id, '^admin_hat_'))
                and hatConfig
            then
                table.insert(hatConfig.items, cloneRewardItem(customReward))
            elseif
                (
                    customReward.rewardKind == 'vehicleMount'
                    or string.match(customReward.id, '^admin_vehicle_mount_')
                ) and vehicleMountConfig
            then
                table.insert(vehicleMountConfig.items, cloneRewardItem(customReward))
            end
        end
    end

    return effectiveConfigs
end

function LuckyChestLogic.getRarityWeights(): { WeightedEntry<LuckyChestRarity> }
    return RARITY_WEIGHTS
end

function LuckyChestLogic.isChestReady(
    profileData: LuckyChestProfileData,
    nowUnixSeconds: number
): boolean
    return nowUnixSeconds >= profileData.nextLuckyChestOpenAt
end

function LuckyChestLogic.getActiveScoreBoostMultiplier(
    profileData: LuckyChestProfileData,
    nowUnixSeconds: number,
    boostedMultiplier: number
): number
    if nowUnixSeconds < profileData.scoreBoostExpiresAt then
        return boostedMultiplier
    end

    return 1
end

function LuckyChestLogic.applyChestSpin(
    profileData: LuckyChestProfileData,
    score: number,
    rebirths: number,
    nowUnixSeconds: number,
    cooldownSeconds: number,
    scoreBoostDurationSeconds: number,
    random01: () -> number,
    customRewards: { LuckyChestRewardItem }?
): LuckyChestApplyResult?
    if not LuckyChestLogic.isChestReady(profileData, nowUnixSeconds) then
        return nil
    end

    local weightedCategories = {}
    local categorySpinOptions = {}
    local categoryConfigs = LuckyChestLogic.getEffectiveCategoryConfigs(customRewards)
    for _, category in ipairs(categoryConfigs) do
        weightedCategories[#weightedCategories + 1] = {
            value = category,
            weight = rarityWeight(category.rarity),
        }
        categorySpinOptions[#categorySpinOptions + 1] = {
            displayName = category.displayName,
            rarity = category.rarity,
        }
    end

    local category = spinWeighted(weightedCategories, random01())

    local weightedItems = {}
    local itemSpinOptions = {}
    for _, item in ipairs(category.items) do
        weightedItems[#weightedItems + 1] = {
            value = item,
            weight = rarityWeight(item.rarity),
        }
        itemSpinOptions[#itemSpinOptions + 1] = {
            displayName = item.displayName,
            rarity = item.rarity,
        }
    end

    local item = spinWeighted(weightedItems, random01())

    local nextProfileData: LuckyChestProfileData = {
        nextLuckyChestOpenAt = nowUnixSeconds + cooldownSeconds,
        scoreBoostExpiresAt = profileData.scoreBoostExpiresAt,
        unlockedHats = cloneStringArray(profileData.unlockedHats),
        unlockedPets = cloneStringArray(profileData.unlockedPets),
        unlockedVehicleMounts = cloneStringArray(profileData.unlockedVehicleMounts),
        equippedHatId = profileData.equippedHatId,
        equippedVehicleMountId = profileData.equippedVehicleMountId,
    }

    local scoreGranted = item.scoreAmount or 0
    local rebirthsGranted = item.rebirthAmount or 0
    local nextScore = score + scoreGranted
    local nextRebirths = rebirths + rebirthsGranted

    if category.id == 'hat' then
        -- TODO: Safe server-side hat equip flow should validate Accessory attachment before use.
        addUniqueString(nextProfileData.unlockedHats, item.id)
    elseif category.id == 'pet' then
        addUniqueString(nextProfileData.unlockedPets, item.id)
    elseif category.id == 'vehicleMount' then
        -- TODO: Safe server-owned mount spawning should validate model PrimaryPart/Seat before use.
        addUniqueString(nextProfileData.unlockedVehicleMounts, item.id)
    elseif category.id == 'scoreBoost' then
        nextProfileData.scoreBoostExpiresAt = nowUnixSeconds + scoreBoostDurationSeconds
    end

    return {
        profileData = nextProfileData,
        score = nextScore,
        rebirths = nextRebirths,
        spinResult = {
            category = category.id,
            categoryDisplayName = category.displayName,
            categoryRarity = category.rarity,
            categorySpinOptions = asSpinOptions(categorySpinOptions),
            item = item,
            itemSpinOptions = asSpinOptions(itemSpinOptions),
            scoreGranted = scoreGranted,
            rebirthsGranted = rebirthsGranted,
            scoreBoostMultiplier = category.id == 'scoreBoost' and 10 or 1,
            scoreBoostDurationSeconds = category.id == 'scoreBoost' and scoreBoostDurationSeconds
                or 0,
        },
    }
end

return LuckyChestLogic
