local WorldLayoutExportLogic = require('../src/Shared/WorldLayoutExportLogic')

local function expectTruthy(value: unknown, message: string)
    if not value then
        error(message)
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

runCase('serializeWorldLayoutModule sorts by id and emits module source', function()
    local exported = WorldLayoutExportLogic.serializeWorldLayoutModule({
        {
            id = 'B',
            kind = 'Asset',
            name = 'B',
            assetId = 123,
            position = { x = 1.25, y = 0, z = -4 },
            rotation = { x = 0, y = 10, z = 0 },
            scale = 0.5,
        },
        {
            id = 'A',
            kind = 'Part',
            name = 'A',
            shape = 'Block',
            size = { x = 10, y = 1, z = 5 },
            position = { x = 0, y = 0.5, z = 0 },
            color = { r = 90, g = 120, b = 100 },
            material = 'Slate',
        },
    })

    local partIndex = string.find(exported, "id = 'A'", 1, true)
    local assetIndex = string.find(exported, "id = 'B'", 1, true)
    expectTruthy(
        partIndex ~= nil and assetIndex ~= nil and partIndex < assetIndex,
        'entries should be sorted by id'
    )
    expectContains(exported, 'local WorldLayout = {}', 'module table should be emitted')
    expectContains(exported, "kind = 'Part'", 'part kind should be emitted')
    expectContains(exported, "kind = 'Asset'", 'asset kind should be emitted')
    expectContains(
        exported,
        'position = { x = 1.25, y = 0, z = -4 }',
        'position should be formatted'
    )
    expectContains(exported, 'scale = 0.5', 'asset scale should be exported when present')
    expectContains(exported, 'return WorldLayout', 'module should return WorldLayout table')
end)
