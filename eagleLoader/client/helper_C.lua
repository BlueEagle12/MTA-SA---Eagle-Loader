timeTable = {}

-- Check if a string equals "true"
function isStringTrue(str)
    return str == "true"
end

-- Model streaming data
streamTimes = {}
streamTimeObj = {}

-- Set stream time for models
function setModelStreamTime(model, sIn, sOut)
    streamTimes[model] = {sIn, sOut}
end

-- Check if the current time is between start and end time
function isTimeBetween(startTimeHour, startTimeMinute, endTimeHour, endTimeMinute)
    local currentHour, currentMinute = getTime()

    local startTotalMinutes = startTimeHour * 60 + startTimeMinute
    local endTotalMinutes = endTimeHour * 60 + endTimeMinute
    local currentTotalMinutes = currentHour * 60 + currentMinute

    -- Handle time wrapping over midnight
    if startTotalMinutes <= endTotalMinutes then
        return currentTotalMinutes >= startTotalMinutes and currentTotalMinutes <= endTotalMinutes
    else
        return currentTotalMinutes >= startTotalMinutes or currentTotalMinutes <= endTotalMinutes
    end
end

-- Timer to manage object scaling and LOD distance

setTimer(function()
    local hours, minutes = getTime()
    for obj, _ in pairs(timeTable) do
        local model = getElementModel(obj)
        local timeData = streamTimes[model]

        if timeData then
            local sIn, sOut = timeData[1], timeData[2]
            if sIn and sOut then
                local shouldStreamIn = isTimeBetween(sIn, 0, sOut, 0)
                local currentState = streamTimeObj[obj]

                if shouldStreamIn and currentState ~= 1 then
                    streamTimeObj[obj] = 1
                    setObjectScale(obj, 1)
                    local lodDistance = streamingDistances[model] or 0
                    engineSetModelLODDistance(model, lodDistance)
                elseif not shouldStreamIn and currentState ~= 2 then
                    streamTimeObj[obj] = 2
                    setObjectScale(obj, 0)
                    engineSetModelLODDistance(model, 0)
                end
            end
        end
    end
end, 500, 0)

function prepTime(element, id)
    timeTable[element] = streamTimes[id] and true or nil
end


-- Process flags table to optimize lookups
local flagsTableNew = {}
local flagsTable = {
    {1, "IS_ROAD"},
    {2, "-"},
    {4, "DRAW_LAST", "alphaTransparency"},
    {8, "ADDITIVE", "alphaTransparency"},
    {16, "-"},
    {32, ""},
    {64, "NO_ZBUFFER_WRITE"},
    {128, "DONT_RECEIVE_SHADOWS"},
    {256, "-"},
    {512, "IS_GLASS_TYPE_1"},
    {1024, "IS_GLASS_TYPE_2"},
    {2048, "IS_GARAGE_DOOR"},
    {4096, "IS_DAMAGABLE", "breakable"},
    {8192, "IS_TREE"},
    {16384, "IS_PALM"},
    {32768, "DOES_NOT_COLLIDE_WITH_FLYER"},
    {65536, "-"},
    {131072, "-"},
    {262144, "-"},
    {524288, "-"},
    {1048576, "IS_TAG"},
    {2097152, "DISABLE_BACKFACE_CULLING", "doubleSided"},
    {4194304, "IS_BREAKABLE_STATUE"}
}

for _, data in pairs(flagsTable) do
    if data[3] then
        flagsTableNew[data[1]] = data[3]
    end
end

function countCommas(str)
    local _, count = str:gsub(",", "")
    return count
end

function flagList(flags)
    if countCommas(flags) > 0 then
        return split(flags, ",")
    else
        return {flags}
    end
end

function getFlags(attribute, flags)
    local list = flagList(flags)
    for _, flag in pairs(list) do
        local flagValue = tonumber(flag)
        if flagsTableNew[flagValue] then
            attribute[flagsTableNew[flagValue]] = true
        end
    end
end
