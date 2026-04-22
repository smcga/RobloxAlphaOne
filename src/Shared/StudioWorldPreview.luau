local Workspace = game:GetService('Workspace')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local WorldBuilder = require(Shared:WaitForChild('WorldBuilder'))
local StudioWorldLayoutExport = require(Shared:WaitForChild('StudioWorldLayoutExport'))

local StudioWorldPreview = {}

function StudioWorldPreview.buildInWorkspace()
    WorldBuilder.build(Workspace)
end

function StudioWorldPreview.exportLayoutFromWorkspace(): string
    return StudioWorldLayoutExport.exportLayoutFromWorkspace(Workspace)
end

return StudioWorldPreview
