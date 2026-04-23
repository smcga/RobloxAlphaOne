export type LeaderboardEntry = {
    userId: number,
    playerName: string,
    bestScore: number,
}

local GlobalLeaderboardLogic = {}

local function sanitizeWholeNumber(value: any): number
    if type(value) ~= 'number' then
        return 0
    end

    if value ~= value then
        return 0
    end

    if value == math.huge or value == -math.huge then
        return 0
    end

    return math.max(math.floor(value), 0)
end

local function sanitizePlayerName(value: any): string
    if type(value) ~= 'string' then
        return 'Unknown'
    end

    if value == '' then
        return 'Unknown'
    end

    return value
end

function GlobalLeaderboardLogic.normalizeEntries(
    entries: { LeaderboardEntry },
    maxEntries: number
): { LeaderboardEntry }
    local normalized: { LeaderboardEntry } = {}

    for _, entry in ipairs(entries) do
        table.insert(normalized, {
            userId = sanitizeWholeNumber(entry.userId),
            playerName = sanitizePlayerName(entry.playerName),
            bestScore = sanitizeWholeNumber(entry.bestScore),
        })
    end

    table.sort(normalized, function(a, b)
        if a.bestScore ~= b.bestScore then
            return a.bestScore > b.bestScore
        end

        if a.playerName ~= b.playerName then
            return a.playerName < b.playerName
        end

        return a.userId < b.userId
    end)

    while #normalized > maxEntries do
        table.remove(normalized)
    end

    return normalized
end

function GlobalLeaderboardLogic.buildSignText(
    entries: { LeaderboardEntry },
    formatScore: (number) -> string
): string
    local lines = {
        'GLOBAL ALL-TIME TOP SCORES',
        '',
    }

    if #entries == 0 then
        table.insert(lines, 'No scores yet')
        return table.concat(lines, '\n')
    end

    for index, entry in ipairs(entries) do
        table.insert(
            lines,
            string.format('%d) %s - %s', index, entry.playerName, formatScore(entry.bestScore))
        )
    end

    return table.concat(lines, '\n')
end

return GlobalLeaderboardLogic
