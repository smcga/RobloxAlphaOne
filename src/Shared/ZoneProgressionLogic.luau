local ProgressionBalance = require('./ProgressionBalance')
local RebirthLogic = require('./RebirthLogic')
local ScoreLogic = require('./ScoreLogic')

export type ZoneProgressionState = {
    score: number,
    rebirths: number,
    highestScoreAchieved: number,
    highestRankAchieved: number,
    highestAgeAchieved: number,
    ageAccumulatorSeconds: { [number]: number },
    wasInsideRebirthZone: boolean,
}

export type AgeZoneProgressionConfig = {
    requiredScore: number,
    scoreIncrement: number,
}

export type ZoneProgressionInput = {
    deltaSeconds: number,
    isInsideAgeZones: { [number]: boolean },
    ageZoneConfigs: { AgeZoneProgressionConfig },
    scoreIntervalSeconds: number,
    isInsideRebirthZone: boolean,
    rankConfigs: { ProgressionBalance.RankConfig },
    rebirthCatchUpPerRebirth: number?,
    maxCatchUpMultiplier: number?,
    postRecordRebirthMultiplier: number?,
    bonusScoreMultiplier: number?,
    rankScoreMultiplier: number?,
    rebirthConfig: RebirthLogic.RebirthConfig?,
    nowUnixTime: number?,
    isInsideFinalAgeZone: boolean?,
}

export type ZoneProgressionResult = {
    state: ZoneProgressionState,
}

local ZoneProgressionLogic = {}

local function sanitizeFiniteNumber(value: number?, fallback: number?): number?
    if type(value) ~= 'number' then
        return fallback
    end

    if value ~= value then
        return fallback
    end

    if value == math.huge or value == -math.huge then
        return fallback
    end

    return value
end

local function sanitizeWholeNumber(value: number?, fallback: number): number
    local normalized = sanitizeFiniteNumber(value, fallback) or fallback
    return math.max(math.floor(normalized), 0)
end

function ZoneProgressionLogic.newState(
    initialScore: number?,
    initialRebirths: number?,
    initialHighestScoreAchieved: number?,
    initialHighestRankAchieved: number?,
    initialHighestAgeAchieved: number?
): ZoneProgressionState
    local score = sanitizeFiniteNumber(initialScore, 0) or 0
    local highestScoreAchieved = math.max(
        sanitizeFiniteNumber(initialHighestScoreAchieved, score) or score,
        score
    )

    return {
        score = score,
        rebirths = sanitizeWholeNumber(initialRebirths, 0),
        highestScoreAchieved = highestScoreAchieved,
        highestRankAchieved = math.max(sanitizeWholeNumber(initialHighestRankAchieved, 1), 1),
        highestAgeAchieved = math.max(sanitizeWholeNumber(initialHighestAgeAchieved, 1), 1),
        ageAccumulatorSeconds = {},
        wasInsideRebirthZone = false,
    }
end

function ZoneProgressionLogic.tick(
    state: ZoneProgressionState,
    input: ZoneProgressionInput
): ZoneProgressionResult
    local catchUpPerRebirth = sanitizeFiniteNumber(input.rebirthCatchUpPerRebirth, nil)
        or ProgressionBalance.REBIRTH_CATCH_UP_PER_REBIRTH
    local maxCatchUpMultiplier = sanitizeFiniteNumber(input.maxCatchUpMultiplier, nil)
        or ProgressionBalance.MAX_CATCH_UP_MULTIPLIER
    local postRecordRebirthMultiplier = sanitizeFiniteNumber(input.postRecordRebirthMultiplier, nil)
        or ProgressionBalance.POST_RECORD_REBIRTH_MULTIPLIER
    local safeCatchUpPerRebirth = math.max(catchUpPerRebirth, 0)
    local safeMaxCatchUpMultiplier = math.max(maxCatchUpMultiplier, 1)
    local safePostRecordRebirthMultiplier = math.max(postRecordRebirthMultiplier, 1)
    local safeBonusScoreMultiplier = math.max(
        sanitizeFiniteNumber(input.bonusScoreMultiplier, 1) or 1,
        1
    )
    local safeRankScoreMultiplier = math.max(
        sanitizeFiniteNumber(input.rankScoreMultiplier, 1) or 1,
        1
    )

    local stateScore = sanitizeFiniteNumber(state.score, 0) or 0
    local highestScoreAchievedState = math.max(
        sanitizeFiniteNumber(state.highestScoreAchieved, stateScore) or stateScore,
        stateScore
    )
    local stateRebirths = sanitizeWholeNumber(state.rebirths, 0)

    local catchUpMultiplier = 1
    if stateScore < highestScoreAchievedState then
        catchUpMultiplier = math.min(
            safeMaxCatchUpMultiplier,
            1 + stateRebirths * safeCatchUpPerRebirth
        )
    end

    local postRecordMultiplier = 1
    if stateRebirths > 0 and stateScore >= highestScoreAchievedState then
        postRecordMultiplier = safePostRecordRebirthMultiplier
    end

    local scoreMultiplier = catchUpMultiplier
        * safeBonusScoreMultiplier
        * safeRankScoreMultiplier
        * postRecordMultiplier

    local score = stateScore
    local ageAccumulatorSeconds = {}
    local zoneCount = #input.ageZoneConfigs

    for index = 1, zoneCount do
        local zoneConfig = input.ageZoneConfigs[index]
        local zoneAccumulator = sanitizeFiniteNumber(state.ageAccumulatorSeconds[index], 0) or 0
        local isInsideZone = input.isInsideAgeZones[index] == true
        local canUseZone = score >= zoneConfig.requiredScore

        local zoneTickState = ScoreLogic.tick(
            {
                score = score,
                accumulatorSeconds = zoneAccumulator,
            },
            math.max(sanitizeFiniteNumber(input.deltaSeconds, 0) or 0, 0),
            isInsideZone and canUseZone,
            math.max(sanitizeFiniteNumber(input.scoreIntervalSeconds, 1) or 1, 1e-6),
            (sanitizeFiniteNumber(zoneConfig.scoreIncrement, 0) or 0) * scoreMultiplier
        )
        score = zoneTickState.score
        ageAccumulatorSeconds[index] = zoneTickState.accumulatorSeconds
    end

    local enteredRebirthZone = input.isInsideRebirthZone and not state.wasInsideRebirthZone
    local rebirths = stateRebirths

    if enteredRebirthZone then
        local rebirthConfig = input.rebirthConfig
        if rebirthConfig then
            local rebirthGrant = RebirthLogic.getPreviewGrant(
                score,
                rebirths,
                input.isInsideFinalAgeZone == true,
                input.nowUnixTime or 0,
                rebirthConfig
            )
            if rebirthGrant > 0 then
                rebirths += rebirthGrant
                score = 0
                ageAccumulatorSeconds = {}
            end
        else
            rebirths += 1
            score = 0
            ageAccumulatorSeconds = {}
        end
    end

    local highestScoreAchieved = math.max(highestScoreAchievedState, score)
    local highestRankAchieved = math.max(
        math.max(sanitizeWholeNumber(state.highestRankAchieved, 1), 1),
        ProgressionBalance.getRankIndexForScore(score, input.rankConfigs)
    )
    local highestAgeAchieved = math.max(
        math.max(sanitizeWholeNumber(state.highestAgeAchieved, 1), 1),
        ProgressionBalance.getHighestUnlockedAgeIndex(score, input.ageZoneConfigs)
    )

    return {
        state = {
            score = score,
            rebirths = rebirths,
            highestScoreAchieved = highestScoreAchieved,
            highestRankAchieved = highestRankAchieved,
            highestAgeAchieved = highestAgeAchieved,
            ageAccumulatorSeconds = ageAccumulatorSeconds,
            wasInsideRebirthZone = input.isInsideRebirthZone,
        },
    }
end

return ZoneProgressionLogic
