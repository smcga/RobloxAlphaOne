local ScoreLogic = require('./ScoreLogic')

export type ZoneProgressionState = {
    score: number,
    rebirths: number,
    blueAccumulatorSeconds: number,
    redAccumulatorSeconds: number,
    eighteenHundredsAccumulatorSeconds: number,
    wasInsideRebirthZone: boolean,
}

export type ZoneProgressionInput = {
    deltaSeconds: number,
    isInsideBlueZone: boolean,
    isInsideRedZone: boolean,
    scoreIntervalSeconds: number,
    blueIncrement: number,
    redIncrement: number,
    redRequiredScore: number,
    isInsideEighteenHundredsZone: boolean,
    eighteenHundredsIncrement: number,
    eighteenHundredsRequiredScore: number,
    isInsideRebirthZone: boolean,
    rebirthScoreDivisor: number,
}

export type ZoneProgressionResult = {
    state: ZoneProgressionState,
    shouldPunishForRedZone: boolean,
}

local ZoneProgressionLogic = {}

function ZoneProgressionLogic.newState(
    initialScore: number?,
    initialRebirths: number?
): ZoneProgressionState
    return {
        score = initialScore or 0,
        rebirths = initialRebirths or 0,
        blueAccumulatorSeconds = 0,
        redAccumulatorSeconds = 0,
        eighteenHundredsAccumulatorSeconds = 0,
        wasInsideRebirthZone = false,
    }
end

function ZoneProgressionLogic.tick(
    state: ZoneProgressionState,
    input: ZoneProgressionInput
): ZoneProgressionResult
    local scoreMultiplier = math.max(state.rebirths, 1)
    local blueTickState = ScoreLogic.tick(
        {
            score = state.score,
            accumulatorSeconds = state.blueAccumulatorSeconds,
        },
        input.deltaSeconds,
        input.isInsideBlueZone,
        input.scoreIntervalSeconds,
        input.blueIncrement * scoreMultiplier
    )

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
        input.redIncrement * scoreMultiplier
    )

    local canUseEighteenHundredsZone = redTickState.score >= input.eighteenHundredsRequiredScore
    local eighteenHundredsTickState = ScoreLogic.tick(
        {
            score = redTickState.score,
            accumulatorSeconds = state.eighteenHundredsAccumulatorSeconds,
        },
        input.deltaSeconds,
        input.isInsideEighteenHundredsZone and canUseEighteenHundredsZone,
        input.scoreIntervalSeconds,
        input.eighteenHundredsIncrement * scoreMultiplier
    )

    local enteredRebirthZone = input.isInsideRebirthZone and not state.wasInsideRebirthZone
    local rebirths = state.rebirths
    local score = eighteenHundredsTickState.score
    local blueAccumulatorSeconds = blueTickState.accumulatorSeconds
    local redAccumulatorSeconds = redTickState.accumulatorSeconds
    local eighteenHundredsAccumulatorSeconds = eighteenHundredsTickState.accumulatorSeconds

    if enteredRebirthZone then
        rebirths += math.floor(score / input.rebirthScoreDivisor)
        score = 0
        blueAccumulatorSeconds = 0
        redAccumulatorSeconds = 0
        eighteenHundredsAccumulatorSeconds = 0
    end

    return {
        state = {
            score = score,
            rebirths = rebirths,
            blueAccumulatorSeconds = blueAccumulatorSeconds,
            redAccumulatorSeconds = redAccumulatorSeconds,
            eighteenHundredsAccumulatorSeconds = eighteenHundredsAccumulatorSeconds,
            wasInsideRebirthZone = input.isInsideRebirthZone,
        },
        shouldPunishForRedZone = shouldPunishForRedZone,
    }
end

return ZoneProgressionLogic
