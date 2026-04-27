local RankUiLayoutLogic = require('../src/Shared/RankUiLayoutLogic')

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

runCase('getRankPanelLayout exposes centered bottom panel dimensions', function()
    local layout = RankUiLayoutLogic.getRankPanelLayout()
    expectEqual(layout.width, 460, 'rank panel width should remain consistent')
    expectEqual(layout.height, 88, 'rank panel height should remain compact')
    expectEqual(layout.bottomPadding, 24, 'rank panel should sit above bottom edge')
end)

runCase('getRankPanelLayout returns a clone for safe local edits', function()
    local layout = RankUiLayoutLogic.getRankPanelLayout()
    layout.bottomPadding = 999

    local freshLayout = RankUiLayoutLogic.getRankPanelLayout()
    expectEqual(freshLayout.bottomPadding, 24, 'layout should not mutate shared defaults')
end)
