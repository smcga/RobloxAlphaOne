local NumberFormat = require('./NumberFormat')

export type TopScoreRecord = {
    userId: number,
    playerName: string,
    highestScore: number,
    updatedAt: number,
}

local GlobalTopScoreLogic = {}

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
        return 'Unknown Player'
    end

    local trimmed = string.gsub(value, '^%s*(.-)%s*$', '%1')
    if trimmed == '' then
        return 'Unknown Player'
    end

    return string.sub(trimmed, 1, 50)
end

function GlobalTopScoreLogic.normalizeRecord(rawRecord: any): TopScoreRecord
    if type(rawRecord) ~= 'table' then
        return {
            userId = 0,
            playerName = 'No champion yet',
            highestScore = 0,
            updatedAt = 0,
        }
    end

    return {
        userId = sanitizeWholeNumber(rawRecord.userId),
        playerName = sanitizePlayerName(rawRecord.playerName),
        highestScore = sanitizeWholeNumber(rawRecord.highestScore),
        updatedAt = sanitizeWholeNumber(rawRecord.updatedAt),
    }
end

function GlobalTopScoreLogic.createCandidateRecord(
    userId: number,
    playerName: string,
    highestScore: number,
    updatedAt: number
): TopScoreRecord
    return {
        userId = sanitizeWholeNumber(userId),
        playerName = sanitizePlayerName(playerName),
        highestScore = sanitizeWholeNumber(highestScore),
        updatedAt = sanitizeWholeNumber(updatedAt),
    }
end

function GlobalTopScoreLogic.shouldReplaceRecord(
    currentRecord: TopScoreRecord,
    candidateRecord: TopScoreRecord
): boolean
    if candidateRecord.highestScore > currentRecord.highestScore then
        return true
    end

    if
        candidateRecord.highestScore == currentRecord.highestScore
        and candidateRecord.userId == currentRecord.userId
        and candidateRecord.playerName ~= currentRecord.playerName
    then
        return true
    end

    return false
end

function GlobalTopScoreLogic.toScreenText(record: TopScoreRecord): string
    if record.highestScore <= 0 then
        return 'GLOBAL TOP SCORE\nNo champion yet\nSet the first record!'
    end

    local compactScore = NumberFormat.formatCompact(record.highestScore)
    return string.format('GLOBAL TOP SCORE\n%s\n%s pts', record.playerName, compactScore)
end

return GlobalTopScoreLogic
