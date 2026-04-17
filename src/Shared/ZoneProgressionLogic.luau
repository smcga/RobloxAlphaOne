local ScoreLogic = require('./ScoreLogic')

export type ZoneProgressionState = {
    score: number,
    blueAccumulatorSeconds: number,
    redAccumulatorSeconds: number,
}

export type ZoneProgressionInput = {
    deltaSeconds: number,
    isInsideBlueZone: boolean,
    isInsideRedZone: boolean,
    scoreIntervalSeconds: number,
    blueIncrement: number,
    redIncrement: number,
    redRequiredScore: number,
}

export type ZoneProgressionResult = {
    state: ZoneProgressionState,
    shouldPunishForRedZone: boolean,
}

local ZoneProgressionLogic = {}

function ZoneProgressionLogic.newState(initialScore: number?): ZoneProgressionState
    return {
        score = initialScore or 0,
        blueAccumulatorSeconds = 0,
        redAccumulatorSeconds = 0,
    }
end

function ZoneProgressionLogic.tick(
    state: ZoneProgressionState,
    input: ZoneProgressionInput
): ZoneProgressionResult
    local blueTickState = ScoreLogic.tick({
        score = state.score,
        accumulatorSeconds = state.blueAccumulatorSeconds,
    }, input.deltaSeconds, input.isInsideBlueZone, input.scoreIntervalSeconds, input.blueIncrement)

    local canUseRedZone = blueTickState.score >= input.redRequiredScore
    local shouldPunishForRedZone = input.isInsideRedZone and not canUseRedZone

    local redTickState = ScoreLogic.tick(
        {
            score = blueTickState.score,
            accumulatorSeconds = state.redAccumulatorSeconds,
        },
        input.deltaSeconds,
        input.isInsideRedZone and canUseRedZone,
        input.scoreIntervalSeconds,
        input.redIncrement
    )

    return {
        state = {
            score = redTickState.score,
            blueAccumulatorSeconds = blueTickState.accumulatorSeconds,
            redAccumulatorSeconds = redTickState.accumulatorSeconds,
        },
        shouldPunishForRedZone = shouldPunishForRedZone,
    }
end

return ZoneProgressionLogic
