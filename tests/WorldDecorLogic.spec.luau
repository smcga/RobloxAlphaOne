local WorldDecorLogic = require('../src/Shared/WorldDecorLogic')

local FLOOR_Y = -0.5
local BASEPLATE_HALF_X = 920 / 2
local BASEPLATE_HALF_Z = 420 / 2
local REALISTIC_TREES_ASSET_ID = 3256343670
local REALISTIC_BUSH_FLOWERS_ASSET_ID = 9187138703
local ROCK_ASSET_ID = 4038061999
local LIGHT_GRASS_ASSET_ID = 2846635652
local ROCK_REALISTIC_ASSET_ID = 9217425479
local ROCKS_ASSET_ID = 4453595550
local COZY_ROCK_ASSET_ID = 13785580624
local SMALL_ROCKS_ASSET_ID = 1925262929
local RAKE_CAVE_ASSET_ID = 16170402764

local function expectEqual<T>(actual: T, expected: T, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function expectTruthy(value: unknown, message: string)
    if not value then
        error(message)
    end
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

local function getVerticalHalfExtent(spec: WorldDecorLogic.PartDecorSpec): number
    if spec.shape == 'Cylinder' then
        local rotation = spec.rotation
        if rotation and math.abs(rotation.z) % 180 == 90 then
            return spec.size.x / 2
        end
    end

    return spec.size.y / 2
end

runCase('decor specs include stable scene pieces', function()
    local specs = WorldDecorLogic.getDecorSpecs()
    expectEqual(#specs, 24, 'scene should include the expected number of decor entries')

    local foundMainPath = false
    local foundRockCluster = false
    local foundAssetTree = false
    local foundFlowerBush = false
    local foundAgeOfBeadsDecor = false

    for _, spec in specs do
        if spec.name == 'MainPath' then
            foundMainPath = true
        end

        if spec.name == 'NorthRockCluster' then
            foundRockCluster = true
        end

        if spec.name == 'RealisticTreeNorth' then
            foundAssetTree = true
        end

        if spec.name == 'FlowerBushCenterNorth' then
            foundFlowerBush = true
        end

        if spec.name == 'AgeOfBeadsRock' then
            foundAgeOfBeadsDecor = true
        end
    end

    expectTruthy(foundMainPath, 'main path decor should exist')
    expectTruthy(foundRockCluster, 'rock cluster decor should exist')
    expectTruthy(foundAssetTree, 'asset tree decor should exist')
    expectTruthy(foundFlowerBush, 'flower bush decor should exist')
    expectTruthy(foundAgeOfBeadsDecor, 'age of beads decor should exist')
end)

runCase('asset entries keep a deterministic unique asset-id set', function()
    local specs = WorldDecorLogic.getDecorSpecs()
    local uniqueIds: { [number]: boolean } = {}

    for _, spec in specs do
        if spec.kind == 'Asset' then
            uniqueIds[spec.assetId] = true
        end
    end

    local idCount = 0
    for _ in uniqueIds do
        idCount += 1
    end

    expectEqual(idCount, 9, 'expected nine unique creator store asset ids in world decor')
    expectTruthy(uniqueIds[REALISTIC_TREES_ASSET_ID], 'expected realistic trees id in unique set')
    expectTruthy(
        uniqueIds[REALISTIC_BUSH_FLOWERS_ASSET_ID],
        'expected realistic bush flowers id in unique set'
    )
    expectTruthy(uniqueIds[ROCK_ASSET_ID], 'expected rock id in unique set')
    expectTruthy(uniqueIds[LIGHT_GRASS_ASSET_ID], 'expected light grass id in unique set')
    expectTruthy(uniqueIds[ROCK_REALISTIC_ASSET_ID], 'expected rock realistic id in unique set')
    expectTruthy(uniqueIds[ROCKS_ASSET_ID], 'expected rocks id in unique set')
    expectTruthy(uniqueIds[COZY_ROCK_ASSET_ID], 'expected cozy rock id in unique set')
    expectTruthy(uniqueIds[SMALL_ROCKS_ASSET_ID], 'expected small rocks id in unique set')
    expectTruthy(uniqueIds[RAKE_CAVE_ASSET_ID], 'expected rake cave id in unique set')
end)

runCase('realistic tree entries use creator store asset id', function()
    local specs = WorldDecorLogic.getDecorSpecs()
    local foundAssetCount = 0

    for _, spec in specs do
        if spec.kind == 'Asset' and string.sub(spec.name, 1, 13) == 'RealisticTree' then
            foundAssetCount += 1
            expectEqual(
                spec.assetId,
                REALISTIC_TREES_ASSET_ID,
                string.format('%s should use expected asset id', spec.name)
            )
            expectTruthy(spec.scale ~= nil and spec.scale > 0, 'asset entry should define a scale')
        end
    end

    expectEqual(foundAssetCount, 4, 'expected exactly four realistic tree asset placements')
end)

runCase('flower bush entries use creator store asset id', function()
    local specs = WorldDecorLogic.getDecorSpecs()
    local foundAssetCount = 0

    for _, spec in specs do
        if spec.kind == 'Asset' and string.sub(spec.name, 1, 10) == 'FlowerBush' then
            foundAssetCount += 1
            expectEqual(
                spec.assetId,
                REALISTIC_BUSH_FLOWERS_ASSET_ID,
                string.format('%s should use expected asset id', spec.name)
            )
            expectTruthy(spec.scale ~= nil and spec.scale > 0, 'asset entry should define a scale')
        end
    end

    expectEqual(foundAssetCount, 4, 'expected exactly four flower bush asset placements')
end)

runCase('age of beads creator-store decor entries use requested asset ids', function()
    local specs = WorldDecorLogic.getDecorSpecs()
    local expectedIdsByName = {
        AgeOfBeadsRock = ROCK_ASSET_ID,
        AgeOfBeadsLightGrass = LIGHT_GRASS_ASSET_ID,
        AgeOfBeadsRockRealistic = ROCK_REALISTIC_ASSET_ID,
        AgeOfBeadsRocks = ROCKS_ASSET_ID,
        AgeOfBeadsCozyRock = COZY_ROCK_ASSET_ID,
        AgeOfBeadsSmallRocks = SMALL_ROCKS_ASSET_ID,
        AgeOfBeadsRakeCave = RAKE_CAVE_ASSET_ID,
    }

    for decorName, expectedAssetId in expectedIdsByName do
        local foundSpec = nil

        for _, spec in specs do
            if spec.kind == 'Asset' and spec.name == decorName then
                foundSpec = spec
                break
            end
        end

        expectTruthy(foundSpec, string.format('missing decor spec for %s', decorName))
        expectEqual(
            foundSpec.assetId,
            expectedAssetId,
            string.format('%s should use expected asset id', decorName)
        )
        expectTruthy(
            foundSpec.scale ~= nil and foundSpec.scale > 0,
            'asset entry should define scale'
        )
    end
end)

runCase('critical cylinder props are rotated into their intended orientation', function()
    local specs = WorldDecorLogic.getDecorSpecs()
    local expectedRotations = {
        CenterPad = 90,
    }

    for decorName, expectedZRotation in expectedRotations do
        local foundSpec = nil

        for _, spec in specs do
            if spec.name == decorName and spec.kind == 'Part' then
                foundSpec = spec
                break
            end
        end

        expectTruthy(foundSpec, string.format('missing decor spec for %s', decorName))
        expectTruthy(foundSpec.rotation, string.format('%s should define rotation', decorName))
        expectEqual(
            foundSpec.rotation.z,
            expectedZRotation,
            string.format('%s should have expected z-axis rotation', decorName)
        )
    end
end)

runCase('decor specs stay near the base playable area', function()
    local specs = WorldDecorLogic.getDecorSpecs()

    for _, spec in specs do
        if
            math.abs(spec.position.x) > BASEPLATE_HALF_X
            or math.abs(spec.position.z) > BASEPLATE_HALF_Z
        then
            error(string.format('decor %s is outside the baseplate bounds', spec.name))
        end
    end
end)

runCase('part-based decor does not clip deeply below the floor', function()
    local specs = WorldDecorLogic.getDecorSpecs()

    for _, spec in specs do
        if spec.kind == 'Part' then
            local bottomY = spec.position.y - getVerticalHalfExtent(spec)
            if bottomY < FLOOR_Y then
                error(
                    string.format('decor %s clips below floor (bottomY=%0.2f)', spec.name, bottomY)
                )
            end
        end
    end
end)
