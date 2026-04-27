local AgeUiLayoutLogic = require('../src/Shared/AgeUiLayoutLogic')

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

runCase('getAgeStatusPanelLayout keeps top-centered panel compact and near top', function()
    local layout = AgeUiLayoutLogic.getAgeStatusPanelLayout()
    expectEqual(layout.width, 460, 'age panel width should stay consistent')
    expectEqual(layout.height, 100, 'age panel height should fit two labels with padding')
    expectEqual(layout.topPadding, 6, 'age panel should sit near the top edge')
end)

runCase('getAgeStatusPanelLayout returns a clone for safe local edits', function()
    local layout = AgeUiLayoutLogic.getAgeStatusPanelLayout()
    layout.topPadding = 999

    local freshLayout = AgeUiLayoutLogic.getAgeStatusPanelLayout()
    expectEqual(freshLayout.topPadding, 6, 'layout should not mutate shared defaults')
end)
