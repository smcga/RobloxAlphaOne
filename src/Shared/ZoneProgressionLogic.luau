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

function ZoneProgressionLogic.newState(
    initialScore: number?,
    initialRebirths: number?,
    initialHighestScoreAchieved: number?,
    initialHighestRankAchieved: number?,
    initialHighestAgeAchieved: number?
): ZoneProgressionState
    local score = initialScore or 0
    local highestScoreAchieved = math.max(initialHighestScoreAchieved or score, score)

    return {
        score = score,
        rebirths = initialRebirths or 0,
        highestScoreAchieved = highestScoreAchieved,
        highestRankAchieved = initialHighestRankAchieved or 1,
        highestAgeAchieved = initialHighestAgeAchieved or 1,
        ageAccumulatorSeconds = {},
        wasInsideRebirthZone = false,
    }
end

function ZoneProgressionLogic.tick(
    state: ZoneProgressionState,
    input: ZoneProgressionInput
): ZoneProgressionResult
    local catchUpPerRebirth = input.rebirthCatchUpPerRebirth
        or ProgressionBalance.REBIRTH_CATCH_UP_PER_REBIRTH
    local postRecordRebirthMultiplier = input.postRecordRebirthMultiplier
        or ProgressionBalance.POST_RECORD_REBIRTH_MULTIPLIER

    local catchUpMultiplier = ProgressionBalance.getCatchUpMultiplier(
        state.score,
        state.highestScoreAchieved,
        state.rebirths,
        input.maxCatchUpMultiplier
    )
    if catchUpPerRebirth ~= ProgressionBalance.REBIRTH_CATCH_UP_PER_REBIRTH then
        catchUpMultiplier = math.max(1, 1 + state.rebirths * catchUpPerRebirth)
        if input.maxCatchUpMultiplier ~= nil then
            catchUpMultiplier = math.min(catchUpMultiplier, math.max(input.maxCatchUpMultiplier, 1))
        end
    end

    local scoreMultiplier = catchUpMultiplier
        * (input.bonusScoreMultiplier or 1)
        * (input.rankScoreMultiplier or 1)
        * postRecordRebirthMultiplier

    local score = state.score
    local ageAccumulatorSeconds = {}
    local zoneCount = #input.ageZoneConfigs

    for index = 1, zoneCount do
        local zoneConfig = input.ageZoneConfigs[index]
        local zoneAccumulator = state.ageAccumulatorSeconds[index] or 0
        local isInsideZone = input.isInsideAgeZones[index] == true
        local canUseZone = score >= zoneConfig.requiredScore

        local zoneTickState = ScoreLogic.tick(
            {
                score = score,
                accumulatorSeconds = zoneAccumulator,
            },
            input.deltaSeconds,
            isInsideZone and canUseZone,
            input.scoreIntervalSeconds,
            zoneConfig.scoreIncrement * scoreMultiplier
        )
        score = zoneTickState.score
        ageAccumulatorSeconds[index] = zoneTickState.accumulatorSeconds
    end

    local enteredRebirthZone = input.isInsideRebirthZone and not state.wasInsideRebirthZone
    local rebirths = state.rebirths

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

    local highestScoreAchieved = math.max(state.highestScoreAchieved, score)
    local highestRankAchieved = math.max(
        state.highestRankAchieved,
        ProgressionBalance.getRankIndexForScore(score, input.rankConfigs)
    )
    local highestAgeAchieved = math.max(
        state.highestAgeAchieved,
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
