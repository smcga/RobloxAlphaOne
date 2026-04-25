local RebirthLogic = require('../src/Shared/RebirthLogic')

local function expectEqual(actual: any, expected: any, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function expectTruthy(value: boolean, message: string)
    if not value then
        error(message)
    end
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

local config: RebirthLogic.RebirthConfig = {
    baseRequirementScore = 1000,
    requirementGrowthPerRebirth = 0,
    scoreToBonusPower = 0.72,
    scoreToBonusScale = 2.6,
    maxBonusRebirthsFromScore = 20,
    hourlyFinalZoneBonus = {
        chancePerHour = 0.35,
        activeWindowSeconds = 180,
        bonusRebirths = 2,
    },
}

runCase('required score stays fixed at 1000 for every rebirth', function()
    expectEqual(RebirthLogic.getRequiredScore(0, config), 1000, 'base requirement should be used')
    expectEqual(
        RebirthLogic.getRequiredScore(3, config),
        1000,
        'requirement should remain fixed regardless of rebirth count'
    )
end)

runCase('preview grant is zero when score is below requirement', function()
    local grant = RebirthLogic.getPreviewGrant(999, 0, false, 0, config)
    expectEqual(grant, 0, 'not enough score should block rebirth grant')
end)

runCase('preview grant adds score-based rebirth bonus above requirement', function()
    local grant = RebirthLogic.getPreviewGrant(3600, 0, false, 0, config)
    expectTruthy(grant > 1, 'extra score should yield more than one rebirth')
end)

runCase('hourly bonus only applies inside the final age zone', function()
    local hour = 3
    local deterministicBonusTime = (hour * 3600) + 60
    local inFinalZone = RebirthLogic.getPreviewGrant(3600, 0, true, deterministicBonusTime, config)
    local outOfFinalZone =
        RebirthLogic.getPreviewGrant(3600, 0, false, deterministicBonusTime, config)
    expectTruthy(inFinalZone >= outOfFinalZone, 'final zone should never be worse than outside')
end)
