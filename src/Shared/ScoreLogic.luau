export type TickState = {
    score: number,
    accumulatorSeconds: number,
}

export type ComboTickState = {
    score: number,
    accumulatorSeconds: number,
    comboTicks: number,
}

local ScoreLogic = {}

function ScoreLogic.newState(initialScore: number?): TickState
    return {
        score = initialScore or 0,
        accumulatorSeconds = 0,
    }
end

function ScoreLogic.tick(
    state: TickState,
    deltaSeconds: number,
    isInsideZone: boolean,
    intervalSeconds: number,
    increment: number
): TickState
    if not isInsideZone then
        return {
            score = state.score,
            accumulatorSeconds = 0,
        }
    end

    local accumulator = state.accumulatorSeconds + deltaSeconds
    local score = state.score

    while accumulator >= intervalSeconds do
        accumulator -= intervalSeconds
        score += increment
    end

    return {
        score = score,
        accumulatorSeconds = accumulator,
    }
end

function ScoreLogic.newComboState(initialScore: number?, initialComboTicks: number?): ComboTickState
    return {
        score = initialScore or 0,
        accumulatorSeconds = 0,
        comboTicks = initialComboTicks or 0,
    }
end

function ScoreLogic.tickWithCombo(
    state: ComboTickState,
    deltaSeconds: number,
    isInsideZone: boolean,
    intervalSeconds: number,
    increment: number,
    comboStep: number,
    maxComboMultiplier: number
): ComboTickState
    if not isInsideZone then
        return {
            score = state.score,
            accumulatorSeconds = 0,
            comboTicks = 0,
        }
    end

    local accumulator = state.accumulatorSeconds + deltaSeconds
    local score = state.score
    local comboTicks = state.comboTicks

    while accumulator >= intervalSeconds do
        accumulator -= intervalSeconds
        local comboMultiplier = math.min(1 + comboTicks * comboStep, maxComboMultiplier)
        score += increment * comboMultiplier
        comboTicks += 1
    end

    return {
        score = score,
        accumulatorSeconds = accumulator,
        comboTicks = comboTicks,
    }
end

return ScoreLogic
