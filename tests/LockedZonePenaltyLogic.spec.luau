local LockedZonePenaltyLogic = require('../src/Shared/LockedZonePenaltyLogic')

local function expectEqual(actual, expected, message)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function expectNumberClose(
    actual: number,
    expected: number,
    tolerance: number,
    message: string
)
    if math.abs(actual - expected) > tolerance then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function runCase(name, callback)
    local ok, err = pcall(callback)
    if not ok then
        error(string.format('LockedZonePenaltyLogic failed: %s\n%s', name, err))
    end
end

runCase('returns first locked zone index when inside locked zone', function()
    local index = LockedZonePenaltyLogic.getFirstLockedZoneIndex(599, { false, true, false }, {
        {
            requiredScore = 0,
            center = { X = 0, Z = 0 },
        },
        {
            requiredScore = 600,
            center = { X = 10, Z = 0 },
        },
        {
            requiredScore = 6600,
            center = { X = 20, Z = 0 },
        },
    })

    expectEqual(index, 2, 'should return the locked zone index')
end)

runCase('returns nil when inside unlocked zones only', function()
    local index = LockedZonePenaltyLogic.getFirstLockedZoneIndex(7000, { true, true, true }, {
        {
            requiredScore = 0,
            center = { X = 0, Z = 0 },
        },
        {
            requiredScore = 600,
            center = { X = 10, Z = 0 },
        },
        {
            requiredScore = 6600,
            center = { X = 20, Z = 0 },
        },
    })

    expectEqual(index, nil, 'unlocked zones should not trigger penalty')
end)

runCase('knockback direction points away from zone center', function()
    local direction = LockedZonePenaltyLogic.getKnockbackHorizontalDirection(
        { X = 15, Z = 10 },
        { X = 10, Z = 10 }
    )

    expectNumberClose(direction.X, 1, 0.001, 'x direction should point away from center')
    expectNumberClose(direction.Z, 0, 0.001, 'z direction should point away from center')
end)

runCase('knockback uses fallback direction when player is exactly at zone center', function()
    local direction = LockedZonePenaltyLogic.getKnockbackHorizontalDirection(
        { X = 10, Z = 10 },
        { X = 10, Z = 10 }
    )

    expectNumberClose(direction.X, 0, 0.001, 'fallback x direction should be deterministic')
    expectNumberClose(direction.Z, -1, 0.001, 'fallback z direction should be deterministic')
end)
