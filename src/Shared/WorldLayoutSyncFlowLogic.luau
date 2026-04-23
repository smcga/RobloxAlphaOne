local WorldLayoutSyncFlowLogic = {}

export type SyncMode = 'Import' | 'Export'

type PreviewModule = {
    buildInWorkspace: () -> (),
    syncLayoutModuleFromWorkspace: () -> string,
}

local SUCCESS_PREFIX = '[World Layout Sync]'

local function formatSuccessMessage(mode: SyncMode, details: string?): string
    if mode == 'Import' then
        return string.format(
            '%s Import world from code succeeded. Workspace now matches Shared.WorldLayout.',
            SUCCESS_PREFIX
        )
    end

    if details then
        return string.format('%s Export world to code succeeded. %s', SUCCESS_PREFIX, details)
    end

    return string.format('%s Export world to code succeeded.', SUCCESS_PREFIX)
end

local function formatFailureMessage(mode: SyncMode, err: unknown): string
    local modeLabel = if mode == 'Import' then 'Import world from code' else 'Export world to code'
    return string.format('%s %s failed: %s', SUCCESS_PREFIX, modeLabel, tostring(err))
end

function WorldLayoutSyncFlowLogic.run(preview: PreviewModule, mode: SyncMode): (boolean, string)
    local ok, payload = pcall(function()
        if mode == 'Import' then
            preview.buildInWorkspace()
            return nil
        end

        local moduleSource = preview.syncLayoutModuleFromWorkspace()
        return string.format('Wrote %d bytes into Shared.WorldLayout.Source.', #moduleSource)
    end)

    if ok then
        return true, formatSuccessMessage(mode, payload)
    end

    return false, formatFailureMessage(mode, payload)
end

return WorldLayoutSyncFlowLogic
