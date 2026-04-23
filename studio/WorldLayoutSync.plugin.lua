local ReplicatedStorage = game:GetService('ReplicatedStorage')

local toolbar = plugin:CreateToolbar('World Layout')
local importButton =
    toolbar:CreateButton('Import World', 'Load world from Shared.WorldLayout into Workspace', '')
local exportButton =
    toolbar:CreateButton('Export World', 'Save current Workspace decor into Shared.WorldLayout', '')

local function run(mode: 'Import' | 'Export')
    local shared = ReplicatedStorage:FindFirstChild('Shared')
    if not shared then
        warn('[World Layout Sync] ReplicatedStorage.Shared not found. Connect Rojo first.')
        return
    end

    local previewModule = shared:FindFirstChild('StudioWorldPreview')
    if not previewModule or not previewModule:IsA('ModuleScript') then
        warn(
            '[World Layout Sync] ReplicatedStorage.Shared.StudioWorldPreview not found. Connect Rojo first.'
        )
        return
    end

    local flowModule = shared:FindFirstChild('WorldLayoutSyncFlowLogic')
    if not flowModule or not flowModule:IsA('ModuleScript') then
        warn(
            '[World Layout Sync] ReplicatedStorage.Shared.WorldLayoutSyncFlowLogic not found. Connect Rojo first.'
        )
        return
    end

    local preview = require(previewModule)
    local flow = require(flowModule)
    local ok, message = flow.run(preview, mode)

    if ok then
        print(message)
    else
        warn(message)
    end
end

importButton.Click:Connect(function()
    run('Import')
end)

exportButton.Click:Connect(function()
    run('Export')
end)
