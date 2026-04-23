local WorldLayoutExportLogic = {}

type Vector3Spec = {
    x: number,
    y: number,
    z: number,
}

type Color3Spec = {
    r: number,
    g: number,
    b: number,
}

type PartDecorSpec = {
    id: string,
    kind: 'Part',
    name: string,
    shape: string,
    size: Vector3Spec,
    position: Vector3Spec,
    rotation: Vector3Spec?,
    color: Color3Spec,
    material: string,
    transparency: number?,
}

type AssetDecorSpec = {
    id: string,
    kind: 'Asset',
    name: string,
    assetId: number,
    position: Vector3Spec,
    rotation: Vector3Spec?,
    scale: number?,
}

type DecorSpec = PartDecorSpec | AssetDecorSpec

local function compareSpecs(a: DecorSpec, b: DecorSpec): boolean
    return a.id < b.id
end

local function fmtNumber(value: number): string
    if value == math.floor(value) then
        return tostring(math.floor(value))
    end

    return string.format('%.4f', value):gsub('0+$', ''):gsub('%.$', '')
end

local function fmtVector3(value: Vector3Spec): string
    return string.format(
        '{ x = %s, y = %s, z = %s }',
        fmtNumber(value.x),
        fmtNumber(value.y),
        fmtNumber(value.z)
    )
end

local function fmtColor3(value: Color3Spec): string
    return string.format(
        '{ r = %s, g = %s, b = %s }',
        fmtNumber(value.r),
        fmtNumber(value.g),
        fmtNumber(value.b)
    )
end

local function appendLine(lines: { string }, depth: number, text: string)
    table.insert(lines, string.rep('    ', depth) .. text)
end

local function appendHeader(lines: { string })
    appendLine(lines, 0, "export type DecorShape = 'Block' | 'Cylinder' | 'Ball'")
    appendLine(lines, 0, '')
    appendLine(lines, 0, 'export type Vector3Spec = {')
    appendLine(lines, 1, 'x: number,')
    appendLine(lines, 1, 'y: number,')
    appendLine(lines, 1, 'z: number,')
    appendLine(lines, 0, '}')
    appendLine(lines, 0, '')
    appendLine(lines, 0, 'export type Color3Spec = {')
    appendLine(lines, 1, 'r: number,')
    appendLine(lines, 1, 'g: number,')
    appendLine(lines, 1, 'b: number,')
    appendLine(lines, 0, '}')
    appendLine(lines, 0, '')
    appendLine(lines, 0, 'export type PartDecorSpec = {')
    appendLine(lines, 1, 'id: string,')
    appendLine(lines, 1, "kind: 'Part',")
    appendLine(lines, 1, 'name: string,')
    appendLine(lines, 1, 'shape: DecorShape,')
    appendLine(lines, 1, 'size: Vector3Spec,')
    appendLine(lines, 1, 'position: Vector3Spec,')
    appendLine(lines, 1, 'rotation: Vector3Spec?,')
    appendLine(lines, 1, 'color: Color3Spec,')
    appendLine(lines, 1, 'material: string,')
    appendLine(lines, 1, 'transparency: number?,')
    appendLine(lines, 0, '}')
    appendLine(lines, 0, '')
    appendLine(lines, 0, 'export type AssetDecorSpec = {')
    appendLine(lines, 1, 'id: string,')
    appendLine(lines, 1, "kind: 'Asset',")
    appendLine(lines, 1, 'name: string,')
    appendLine(lines, 1, 'assetId: number,')
    appendLine(lines, 1, 'position: Vector3Spec,')
    appendLine(lines, 1, 'rotation: Vector3Spec?,')
    appendLine(lines, 1, 'scale: number?,')
    appendLine(lines, 0, '}')
    appendLine(lines, 0, '')
    appendLine(lines, 0, 'export type DecorSpec = PartDecorSpec | AssetDecorSpec')
    appendLine(lines, 0, '')
    appendLine(lines, 0, 'local WorldLayout = {}')
    appendLine(lines, 0, '')
end

function WorldLayoutExportLogic.serializeWorldLayoutModule(specs: { DecorSpec }): string
    table.sort(specs, compareSpecs)

    local lines: { string } = {}
    appendHeader(lines)
    appendLine(lines, 0, 'local DECOR_SPECS: { DecorSpec } = {')

    for _, spec in specs do
        appendLine(lines, 1, '{')
        appendLine(lines, 2, string.format("id = '%s',", spec.id))
        appendLine(lines, 2, string.format("kind = '%s',", spec.kind))
        appendLine(lines, 2, string.format("name = '%s',", spec.name))
        appendLine(lines, 2, string.format('position = %s,', fmtVector3(spec.position)))

        if spec.rotation then
            appendLine(lines, 2, string.format('rotation = %s,', fmtVector3(spec.rotation)))
        end

        if spec.kind == 'Asset' then
            appendLine(lines, 2, string.format('assetId = %d,', spec.assetId))
            if spec.scale then
                appendLine(lines, 2, string.format('scale = %s,', fmtNumber(spec.scale)))
            end
        else
            appendLine(lines, 2, string.format("shape = '%s',", spec.shape))
            appendLine(lines, 2, string.format('size = %s,', fmtVector3(spec.size)))
            appendLine(lines, 2, string.format('color = %s,', fmtColor3(spec.color)))
            appendLine(lines, 2, string.format("material = '%s',", spec.material))
            if spec.transparency then
                appendLine(
                    lines,
                    2,
                    string.format('transparency = %s,', fmtNumber(spec.transparency))
                )
            end
        end

        appendLine(lines, 1, '},')
    end

    appendLine(lines, 0, '}')
    appendLine(lines, 0, '')
    appendLine(lines, 0, 'function WorldLayout.getDecorSpecs(): { DecorSpec }')
    appendLine(lines, 1, 'return DECOR_SPECS')
    appendLine(lines, 0, 'end')
    appendLine(lines, 0, '')
    appendLine(lines, 0, 'return WorldLayout')

    return table.concat(lines, '\n')
end

return WorldLayoutExportLogic
