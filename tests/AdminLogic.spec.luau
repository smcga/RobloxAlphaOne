local AdminLogic = require('../src/Shared/AdminLogic')

local function expectEqual<T>(actual: T, expected: T, message: string)
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

runCase('allowed multiplier is accepted', function()
    expectEqual(
        AdminLogic.isAllowedScoreMultiplier({ 2, 10 }, 10),
        true,
        'configured multiplier should be allowed'
    )
end)

runCase('unconfigured multiplier is rejected', function()
    expectEqual(
        AdminLogic.isAllowedScoreMultiplier({ 2, 10 }, 3),
        false,
        'unknown multiplier should be rejected'
    )
end)

runCase('score multiplier floors fractional results', function()
    expectEqual(AdminLogic.applyScoreMultiplier(3, 2.5), 7, 'multiplied score should floor')
end)

runCase('resetScoreAndRebirths zeros both values', function()
    local score, rebirths = AdminLogic.resetScoreAndRebirths()
    expectEqual(score, 0, 'reset score should be 0')
    expectEqual(rebirths, 0, 'reset rebirths should be 0')
end)

runCase('skipLuckyChestTimer sets a future chest timestamp to ready now', function()
    expectEqual(
        AdminLogic.skipLuckyChestTimer(1200),
        0,
        'future chest timestamp should be forced to ready'
    )
end)

runCase('skipLuckyChestTimer keeps already-ready chest timestamp unchanged', function()
    expectEqual(AdminLogic.skipLuckyChestTimer(0), 0, 'ready timestamp should remain unchanged')
    expectEqual(AdminLogic.skipLuckyChestTimer(-25), -25, 'past timestamp should remain unchanged')
end)
