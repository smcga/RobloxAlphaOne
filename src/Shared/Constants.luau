local RANK_COUNT = 100

local AGE_STAGE_LABELS = {
    { maxAge = 1, label = 'Newborn Spark' },
    { maxAge = 3, label = 'Curious Toddler' },
    { maxAge = 5, label = 'Playground Explorer' },
    { maxAge = 8, label = 'Bright Student' },
    { maxAge = 12, label = 'Junior Inventor' },
    { maxAge = 15, label = 'Teen Tinkerer' },
    { maxAge = 18, label = 'Rising Trailblazer' },
    { maxAge = 22, label = 'Campus Coder' },
    { maxAge = 26, label = 'Early Prodigy' },
    { maxAge = 30, label = 'Prime Builder' },
    { maxAge = 35, label = 'Seasoned Specialist' },
    { maxAge = 40, label = 'Master Operator' },
    { maxAge = 45, label = 'Veteran Architect' },
    { maxAge = 50, label = 'Legendary Strategist' },
    { maxAge = 56, label = 'Elite Visionary' },
    { maxAge = 62, label = 'Titan Mentor' },
    { maxAge = 70, label = 'Sage Innovator' },
    { maxAge = 78, label = 'Elder Luminary' },
    { maxAge = 88, label = 'Mythic Ancestor' },
    { maxAge = 99, label = 'Timeless Paragon' },
}

local function getStageLabelForAge(ageYears: number): string
    for _, stage in ipairs(AGE_STAGE_LABELS) do
        if ageYears <= stage.maxAge then
            return stage.label
        end
    end

    return AGE_STAGE_LABELS[#AGE_STAGE_LABELS].label
end

local function buildAgeRankNames(rankCount: number): { string }
    local names = {}

    for rankIndex = 1, rankCount do
        local ageYears = rankIndex - 1
        names[rankIndex] = string.format('Age %02d %s', ageYears, getStageLabelForAge(ageYears))
    end

    return names
end

local function buildRankConfigs(
    rankNames: { string },
    scoreStep: number
): { { name: string, requiredScore: number } }
    local configs = {}

    for index, name in ipairs(rankNames) do
        configs[index] = {
            name = name,
            requiredScore = (index - 1) * scoreStep,
        }
    end

    return configs
end

local Constants = {
    SCORE_INTERVAL_SECONDS = 1,
    REBIRTH_SCORE_DIVISOR = 1000,

    ADMIN_SCORE_MULTIPLIERS = {
        2,
        10,
    },

    SCORE_DATASTORE_NAME = 'PlayerScoreDataV1',
    SCORE_AUTOSAVE_INTERVAL_SECONDS = 30,
    RANK_SCORE_STEP = 1000,
    RANK_CONFIGS = buildRankConfigs(buildAgeRankNames(RANK_COUNT), 1000),

    AGE_ZONE_SECONDS_PER_AGE = 120,

    AGE_ZONE_CONFIGS = {
        {
            zoneName = 'AgeOfBeadsZone',
            displayName = 'Age of Beads',
            requiredScore = 0,
            scoreIncrement = 5,
            center = Vector3.new(-330, 1, -60),
            radius = 16,
            height = 4,
            color = Color3.fromRGB(80, 185, 255),
            outlineColor = Color3.fromRGB(198, 231, 255),
        },
        {
            zoneName = 'AgeOfBrassZone',
            displayName = 'Age of Brass',
            requiredScore = 600,
            scoreIncrement = 50,
            center = Vector3.new(-270, 1, 60),
            radius = 16,
            height = 4,
            color = Color3.fromRGB(255, 173, 56),
            outlineColor = Color3.fromRGB(255, 230, 184),
        },
        {
            zoneName = 'AgeOfRelaysZone',
            displayName = 'Age of Relays',
            requiredScore = 6600,
            scoreIncrement = 500,
            center = Vector3.new(-210, 1, -60),
            radius = 16,
            height = 4,
            color = Color3.fromRGB(255, 112, 163),
            outlineColor = Color3.fromRGB(255, 203, 224),
        },
        {
            zoneName = 'AgeOfTubesZone',
            displayName = 'Age of Tubes',
            requiredScore = 66600,
            scoreIncrement = 5000,
            center = Vector3.new(-150, 1, 60),
            radius = 16,
            height = 4,
            color = Color3.fromRGB(255, 135, 71),
            outlineColor = Color3.fromRGB(255, 214, 186),
        },
        {
            zoneName = 'AgeOfTransistorsZone',
            displayName = 'Age of Transistors',
            requiredScore = 666600,
            scoreIncrement = 50000,
            center = Vector3.new(-90, 1, -60),
            radius = 16,
            height = 4,
            color = Color3.fromRGB(132, 255, 156),
            outlineColor = Color3.fromRGB(209, 255, 218),
        },
        {
            zoneName = 'AgeOfSiliconZone',
            displayName = 'Age of Silicon',
            requiredScore = 6666600,
            scoreIncrement = 500000,
            center = Vector3.new(-30, 1, 60),
            radius = 16,
            height = 4,
            color = Color3.fromRGB(122, 220, 255),
            outlineColor = Color3.fromRGB(204, 239, 255),
        },
        {
            zoneName = 'AgeOfPersonalComputingZone',
            displayName = 'Age of Personal Computing',
            requiredScore = 66666600,
            scoreIncrement = 5000000,
            center = Vector3.new(30, 1, -60),
            radius = 16,
            height = 4,
            color = Color3.fromRGB(220, 160, 255),
            outlineColor = Color3.fromRGB(238, 220, 255),
        },
        {
            zoneName = 'AgeOfNetworksZone',
            displayName = 'Age of Networks',
            requiredScore = 666666600,
            scoreIncrement = 50000000,
            center = Vector3.new(90, 1, 60),
            radius = 16,
            height = 4,
            color = Color3.fromRGB(0, 232, 176),
            outlineColor = Color3.fromRGB(168, 255, 231),
        },
        {
            zoneName = 'AgeOfCloudAndMobileZone',
            displayName = 'Age of Cloud and Mobile',
            requiredScore = 6666666600,
            scoreIncrement = 500000000,
            center = Vector3.new(150, 1, -60),
            radius = 16,
            height = 4,
            color = Color3.fromRGB(255, 205, 97),
            outlineColor = Color3.fromRGB(255, 236, 181),
        },
        {
            zoneName = 'AgeOfMachineMindsZone',
            displayName = 'Age of Machine Minds',
            requiredScore = 66666666600,
            scoreIncrement = 5000000000,
            center = Vector3.new(210, 1, 60),
            radius = 16,
            height = 4,
            color = Color3.fromRGB(255, 123, 123),
            outlineColor = Color3.fromRGB(255, 214, 214),
        },
        {
            zoneName = 'AgeOfAutonomousOrderZone',
            displayName = 'Age of Autonomous Order',
            requiredScore = 666666666600,
            scoreIncrement = 50000000000,
            center = Vector3.new(270, 1, -60),
            radius = 16,
            height = 4,
            color = Color3.fromRGB(169, 145, 255),
            outlineColor = Color3.fromRGB(222, 213, 255),
        },
        {
            zoneName = 'AgeBeyondHumanityZone',
            displayName = 'Age Beyond Humanity',
            requiredScore = 6666666666600,
            scoreIncrement = 500000000000,
            center = Vector3.new(330, 1, 60),
            radius = 16,
            height = 4,
            color = Color3.fromRGB(255, 95, 207),
            outlineColor = Color3.fromRGB(255, 210, 241),
        },
    },

    REBIRTH_ZONE_NAME = 'RebirthZone',
    REBIRTH_ZONE_CENTER = Vector3.new(-420, 1, 0),
    REBIRTH_ZONE_RADIUS = 10,
    REBIRTH_ZONE_HEIGHT = 4,
    SPAWN_LOCATION_NAME = 'AgeOfBeadsSpawn',
    SPAWN_LOCATION_SIZE = Vector3.new(16, 1, 16),
    SPAWN_LOCATION_OFFSET = Vector3.new(0, 3, 24),

    BACKGROUND_MUSIC_NAME = 'AscensionLoop',
    BACKGROUND_MUSIC_SOUND_ID = 'rbxassetid://134983883970262',
    BACKGROUND_MUSIC_VOLUME = 0.35,

    BASEPLATE_SIZE = Vector3.new(920, 1, 420),
}

return Constants
