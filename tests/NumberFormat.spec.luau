local NumberFormat = require('../src/Shared/NumberFormat')

local function expectEqual(actual: string, expected: string, message: string)
    if actual ~= expected then
        error(
            string.format('%s (expected %s, got %s)', message, tostring(expected), tostring(actual))
        )
    end
end

local function runCase(name: string, fn: () -> ())
    fn()
    print(string.format('[PASS] %s', name))
end

runCase('shows small numbers without suffix', function()
    expectEqual(NumberFormat.formatCompact(0), '0', 'zero should remain plain')
    expectEqual(NumberFormat.formatCompact(999), '999', 'three digit values should stay plain')
end)

runCase('formats thousands and millions with expected suffixes', function()
    expectEqual(NumberFormat.formatCompact(1000), '1 K', 'one thousand should use K')
    expectEqual(
        NumberFormat.formatCompact(15300),
        '15.3 K',
        'thousands should keep useful precision'
    )
    expectEqual(NumberFormat.formatCompact(1000000), '1 M', 'one million should use M')
end)

runCase('supports large idle-style suffixes', function()
    expectEqual(NumberFormat.formatCompact(10 ^ 18), '1 Qi', 'quintillion should use Qi')
    expectEqual(NumberFormat.formatCompact(10 ^ 21), '1 Sx', 'sextillion should use Sx')
    expectEqual(NumberFormat.formatCompact(10 ^ 24), '1 Sp', 'septillion should use Sp')
    expectEqual(NumberFormat.formatCompact(10 ^ 33), '1 Dc', 'decillion should use Dc')
end)

runCase('preserves sign for negative values', function()
    expectEqual(NumberFormat.formatCompact(-12345), '-12.3 K', 'negative values keep minus sign')
end)
