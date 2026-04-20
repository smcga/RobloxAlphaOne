local ScoreLogic = require('./ScoreLogic')

export type ZoneProgressionState = {
    score: number,
    rebirths: number,
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
    rebirthScoreDivisor: number,
}

export type ZoneProgressionResult = {
    state: ZoneProgressionState,
}

local ZoneProgressionLogic = {}

function ZoneProgressionLogic.newState(
    initialScore: number?,
    initialRebirths: number?
): ZoneProgressionState
    return {
        score = initialScore or 0,
        rebirths = initialRebirths or 0,
        ageAccumulatorSeconds = {},
        wasInsideRebirthZone = false,
    }
end

function ZoneProgressionLogic.tick(
    state: ZoneProgressionState,
    input: ZoneProgressionInput
): ZoneProgressionResult
    local scoreMultiplier = math.max(state.rebirths, 1)
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
        rebirths += math.floor(score / input.rebirthScoreDivisor)
        score = 0
        ageAccumulatorSeconds = {}
    end

    return {
        state = {
            score = score,
            rebirths = rebirths,
            ageAccumulatorSeconds = ageAccumulatorSeconds,
            wasInsideRebirthZone = input.isInsideRebirthZone,
        },
    }
end

return ZoneProgressionLogic
