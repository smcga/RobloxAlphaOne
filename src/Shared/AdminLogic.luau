local AdminLogic = {}

function AdminLogic.isAllowedScoreMultiplier(
    allowedMultipliers: { number },
    multiplier: number
): boolean
    for _, allowedMultiplier in ipairs(allowedMultipliers) do
        if allowedMultiplier == multiplier then
            return true
        end
    end

    return false
end

function AdminLogic.applyScoreMultiplier(score: number, multiplier: number): number
    return math.floor(score * multiplier)
end

return AdminLogic
