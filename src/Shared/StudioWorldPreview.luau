local Workspace = game:GetService('Workspace')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage:WaitForChild('Shared')
local WorldBuilder = require(Shared:WaitForChild('WorldBuilder'))

local StudioWorldPreview = {}

function StudioWorldPreview.buildInWorkspace()
    WorldBuilder.build(Workspace)
end

return StudioWorldPreview
