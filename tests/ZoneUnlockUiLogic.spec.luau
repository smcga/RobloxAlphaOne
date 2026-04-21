local NumberFormat = require('../src/Shared/NumberFormat')
local ZoneUnlockUiLogic = require('../src/Shared/ZoneUnlockUiLogic')

local function expectEqual(actual: any, expected: any, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

local ageZoneConfigs = {
    {
        displayName = 'Age of Beads',
        requiredScore = 0,
    },
    {
        displayName = 'Age of Brass',
        requiredScore = 600,
    },
    {
        displayName = 'Age of Relays',
        requiredScore = 6600,
    },
}

runCase('returns first locked age as next unlock', function()
    local nextUnlock = ZoneUnlockUiLogic.getNextUnlock(600, ageZoneConfigs)
    expectEqual(
        nextUnlock and nextUnlock.displayName,
        'Age of Relays',
        'should pick next locked age'
    )
end)

runCase('returns nil when all ages are unlocked', function()
    local nextUnlock = ZoneUnlockUiLogic.getNextUnlock(6600, ageZoneConfigs)
    expectEqual(nextUnlock, nil, 'should return nil when no ages remain')
end)

runCase('formats next unlock text with required and remaining score', function()
    local unlockText =
        ZoneUnlockUiLogic.buildNextUnlockText(599, ageZoneConfigs, NumberFormat.formatCompact)
    expectEqual(
        unlockText,
        'Next: Age of Brass at 600 (1 to go)',
        'should show requirement and remaining score'
    )
end)

runCase('formats all unlocked text when no unlock remains', function()
    local unlockText =
        ZoneUnlockUiLogic.buildNextUnlockText(10000, ageZoneConfigs, NumberFormat.formatCompact)
    expectEqual(unlockText, 'All ages unlocked', 'should show all ages unlocked text')
end)
