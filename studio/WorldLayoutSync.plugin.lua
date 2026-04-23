local ReplicatedStorage = game:GetService('ReplicatedStorage')

local toolbar = plugin:CreateToolbar('World Layout')
local syncButton = toolbar:CreateButton(
    'Sync Layout',
    'Build world and sync Studio decor back into Shared.WorldLayout',
    ''
)

syncButton.Click:Connect(function()
    local shared = ReplicatedStorage:FindFirstChild('Shared')
    if not shared then
        warn('ReplicatedStorage.Shared not found. Connect Rojo first.')
        return
    end

    local previewModule = shared:FindFirstChild('StudioWorldPreview')
    if not previewModule or not previewModule:IsA('ModuleScript') then
        warn('ReplicatedStorage.Shared.StudioWorldPreview not found. Connect Rojo first.')
        return
    end

    local preview = require(previewModule)
    local ok, err = pcall(function()
        preview.buildInWorkspace()
        preview.syncLayoutModuleFromWorkspace()
    end)

    if ok then
        print('World layout sync complete.')
    else
        warn(string.format('World layout sync failed: %s', tostring(err)))
    end
end)
