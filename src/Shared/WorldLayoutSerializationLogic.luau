local WorldLayoutSerializationLogic = {}

export type ScalarValue = string | number | boolean
export type Vector3Spec = {
    x: number,
    y: number,
    z: number,
}

export type Color3Spec = {
    r: number,
    g: number,
    b: number,
}

export type ExportDecorSpec = {
    worldId: string,
    kind: 'Part' | 'Asset',
    name: string,
    position: Vector3Spec,
    rotation: Vector3Spec?,
    shape: string?,
    size: Vector3Spec?,
    color: Color3Spec?,
    material: string?,
    transparency: number?,
    assetId: number?,
    scale: number?,
}

local FIELD_ORDER = {
    'worldId',
    'kind',
    'name',
    'assetId',
    'shape',
    'size',
    'position',
    'rotation',
    'color',
    'material',
    'transparency',
    'scale',
}

local function formatNumber(value: number): string
    if value % 1 == 0 then
        return tostring(value)
    end

    return string.format('%.4f', value):gsub('0+$', ''):gsub('%.+$', '')
end

local function formatVector3Spec(value: Vector3Spec): string
    return string.format(
        '{ x = %s, y = %s, z = %s }',
        formatNumber(value.x),
        formatNumber(value.y),
        formatNumber(value.z)
    )
end

local function formatColor3Spec(value: Color3Spec): string
    return string.format('{ r = %d, g = %d, b = %d }', value.r, value.g, value.b)
end

local function formatValue(value: ScalarValue | Vector3Spec | Color3Spec): string
    if typeof(value) == 'string' then
        return string.format("'%s'", value)
    end

    if typeof(value) == 'number' then
        return formatNumber(value)
    end

    if typeof(value) == 'boolean' then
        return if value then 'true' else 'false'
    end

    local typedValue = value :: Vector3Spec | Color3Spec
    if typedValue.r ~= nil then
        return formatColor3Spec(typedValue :: Color3Spec)
    end

    return formatVector3Spec(typedValue :: Vector3Spec)
end

local function compareDecor(a: ExportDecorSpec, b: ExportDecorSpec): boolean
    return a.worldId < b.worldId
end

function WorldLayoutSerializationLogic.serializeDecorSpecs(specs: { ExportDecorSpec }): string
    table.sort(specs, compareDecor)

    local lines = {
        'local WorldLayout = {}',
        '',
        'WorldLayout.decor = {',
    }

    for _, spec in specs do
        table.insert(lines, '    {')

        for _, fieldName in FIELD_ORDER do
            local value = (spec :: any)[fieldName]
            if value ~= nil then
                table.insert(
                    lines,
                    string.format('        %s = %s,', fieldName, formatValue(value))
                )
            end
        end

        table.insert(lines, '    },')
    end

    table.insert(lines, '}')
    table.insert(lines, '')
    table.insert(lines, 'return WorldLayout')

    return table.concat(lines, '\n')
end

return WorldLayoutSerializationLogic
