local WorldLayoutSyncFlowLogic = require('../src/Shared/WorldLayoutSyncFlowLogic')

local function expectEqual<T>(actual: T, expected: T, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function expectContains(text: string, needle: string, message: string)
    if string.find(text, needle, 1, true) == nil then
        error(message)
    end
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

runCase('import mode calls build and returns success message', function()
    local callCount = 0
    local preview = {
        buildInWorkspace = function()
            callCount += 1
        end,
        syncLayoutModuleFromWorkspace = function()
            error('should not export while importing')
        end,
    }

    local ok, message = WorldLayoutSyncFlowLogic.run(preview, 'Import')

    expectEqual(ok, true, 'import should succeed')
    expectEqual(callCount, 1, 'build should be invoked once')
    expectContains(
        message,
        'Import world from code succeeded.',
        'message should confirm import success'
    )
end)

runCase('export mode calls sync and reports byte count', function()
    local callCount = 0
    local preview = {
        buildInWorkspace = function()
            error('should not build while exporting')
        end,
        syncLayoutModuleFromWorkspace = function()
            callCount += 1
            return 'return {}'
        end,
    }

    local ok, message = WorldLayoutSyncFlowLogic.run(preview, 'Export')

    expectEqual(ok, true, 'export should succeed')
    expectEqual(callCount, 1, 'export should invoke sync once')
    expectContains(
        message,
        'Export world to code succeeded.',
        'message should confirm export success'
    )
    expectContains(message, 'Wrote 9 bytes', 'message should include source size')
end)

runCase('failures return operation-specific error context', function()
    local preview = {
        buildInWorkspace = function()
            error('missing workspace folder')
        end,
        syncLayoutModuleFromWorkspace = function()
            return ''
        end,
    }

    local ok, message = WorldLayoutSyncFlowLogic.run(preview, 'Import')

    expectEqual(ok, false, 'import should fail when preview throws')
    expectContains(message, 'Import world from code failed:', 'message should indicate failed mode')
    expectContains(
        message,
        'missing workspace folder',
        'message should include original error text'
    )
end)
