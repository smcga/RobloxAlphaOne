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
    activeComboAgeZoneIndex: number?,
    scoreComboTicks: number,
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
    postRecordRebirthMultiplier: number?,
    rebirthMultiplierScale: number?,
    rebirthMultiplierPower: number?,
    maxRebirthScoreMultiplier: number?,
    bonusScoreMultiplier: number?,
    rankScoreMultiplier: number?,
    rebirthConfig: RebirthLogic.RebirthConfig?,
    nowUnixTime: number?,
    isInsideFinalAgeZone: boolean?,
    zoneComboStep: number?,
    maxZoneComboMultiplier: number?,
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
        activeComboAgeZoneIndex = nil,
        scoreComboTicks = 0,
    }
end

function ZoneProgressionLogic.tick(
    state: ZoneProgressionState,
    input: ZoneProgressionInput
): ZoneProgressionResult
    local postRecordRebirthMultiplier = input.postRecordRebirthMultiplier
        or ProgressionBalance.POST_RECORD_REBIRTH_MULTIPLIER
    local rebirthMultiplier = ProgressionBalance.getRebirthScoreMultiplier(
        state.rebirths,
        input.rebirthMultiplierScale,
        input.rebirthMultiplierPower,
        input.maxRebirthScoreMultiplier
    )

    local scoreMultiplier = rebirthMultiplier
        * (input.bonusScoreMultiplier or 1)
        * (input.rankScoreMultiplier or 1)
        * postRecordRebirthMultiplier

    local score = state.score
    local ageAccumulatorSeconds = {}
    local zoneCount = #input.ageZoneConfigs
    local comboStep = input.zoneComboStep or 0
    local maxComboMultiplier = input.maxZoneComboMultiplier or 1
    local activeComboAgeZoneIndex = nil

    for index = 1, zoneCount do
        local zoneConfig = input.ageZoneConfigs[index]
        local isInsideZone = input.isInsideAgeZones[index] == true
        local canUseZone = score >= zoneConfig.requiredScore

        if isInsideZone and canUseZone and activeComboAgeZoneIndex == nil then
            activeComboAgeZoneIndex = index
        end
    end

    local scoreComboTicks = state.scoreComboTicks
    if activeComboAgeZoneIndex ~= state.activeComboAgeZoneIndex then
        scoreComboTicks = 0
    end

    for index = 1, zoneCount do
        local zoneConfig = input.ageZoneConfigs[index]
        local zoneAccumulator = state.ageAccumulatorSeconds[index] or 0
        local isComboZone = index == activeComboAgeZoneIndex

        if isComboZone and comboStep > 0 and maxComboMultiplier > 1 then
            local zoneTickState = ScoreLogic.tickWithCombo(
                {
                    score = score,
                    accumulatorSeconds = zoneAccumulator,
                    comboTicks = scoreComboTicks,
                },
                input.deltaSeconds,
                true,
                input.scoreIntervalSeconds,
                zoneConfig.scoreIncrement * scoreMultiplier,
                comboStep,
                maxComboMultiplier
            )
            score = zoneTickState.score
            ageAccumulatorSeconds[index] = zoneTickState.accumulatorSeconds
            scoreComboTicks = zoneTickState.comboTicks
        else
            local zoneTickState = ScoreLogic.tick(
                {
                    score = score,
                    accumulatorSeconds = zoneAccumulator,
                },
                input.deltaSeconds,
                isComboZone,
                input.scoreIntervalSeconds,
                zoneConfig.scoreIncrement * scoreMultiplier
            )
            score = zoneTickState.score
            ageAccumulatorSeconds[index] = zoneTickState.accumulatorSeconds
        end
    end

    if activeComboAgeZoneIndex == nil then
        scoreComboTicks = 0
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
                activeComboAgeZoneIndex = nil
                scoreComboTicks = 0
            end
        else
            rebirths += 1
            score = 0
            ageAccumulatorSeconds = {}
            activeComboAgeZoneIndex = nil
            scoreComboTicks = 0
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
            activeComboAgeZoneIndex = activeComboAgeZoneIndex,
            scoreComboTicks = scoreComboTicks,
        },
    }
end

return ZoneProgressionLogic
