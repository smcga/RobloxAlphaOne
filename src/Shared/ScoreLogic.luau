export type TickState = {
    score: number,
    accumulatorSeconds: number,
}

local ScoreLogic = {}

function ScoreLogic.newState(initialScore: number?): TickState
    return {
        score = initialScore or 0,
        accumulatorSeconds = 0,
    }
end

function ScoreLogic.tick(state: TickState, deltaSeconds: number, isInsideZone: boolean, intervalSeconds: number, increment: number): TickState
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

return ScoreLogic
