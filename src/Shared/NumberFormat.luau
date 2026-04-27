local NumberFormat = {}

local SUFFIXES = {
    '',
    'K',
    'M',
    'B',
    'T',
    'Qa',
    'Qi',
    'Sx',
    'Sp',
    'Oc',
    'No',
    'Dc',
    'Ud',
    'Dd',
    'Td',
    'Qad',
    'Qid',
    'Sxd',
    'Spd',
    'Ocd',
    'Nod',
    'Vg',
}

local function trimTrailingZeros(valueText: string): string
    return valueText:gsub('(%..-)0+$', '%1'):gsub('%.$', '')
end

local function formatScaled(absValue: number): string
    if absValue >= 100 then
        return string.format('%.0f', absValue)
    end

    if absValue >= 10 then
        return trimTrailingZeros(string.format('%.1f', absValue))
    end

    return trimTrailingZeros(string.format('%.2f', absValue))
end

function NumberFormat.formatCompact(value: number): string
    if value ~= value then
        return 'NaN'
    end

    local absoluteValue = math.abs(value)

    if absoluteValue < 1e3 then
        return trimTrailingZeros(string.format('%.0f', value))
    end

    local suffixIndex = math.floor(math.log10(absoluteValue) / 3)

    if suffixIndex >= #SUFFIXES then
        return string.format('%.2e', value)
    end

    local scaledValue = absoluteValue / (1000 ^ suffixIndex)
    local scaledText = formatScaled(scaledValue)
    local sign = if value < 0 then '-' else ''

    return string.format('%s%s %s', sign, scaledText, SUFFIXES[suffixIndex + 1])
end

function NumberFormat.formatWithCommas(value: number): string
    if value ~= value then
        return 'NaN'
    end

    local isNegative = value < 0
    local absoluteValue = math.abs(value)
    local integerText = string.format('%.0f', math.floor(absoluteValue))
    local withCommas = integerText:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')

    if isNegative then
        return string.format('-%s', withCommas)
    end

    return withCommas
end

return NumberFormat
