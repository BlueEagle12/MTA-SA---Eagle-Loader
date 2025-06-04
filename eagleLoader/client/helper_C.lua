timeTable = {}

-- Check if a string equals "true"
function isStringTrue(str)
    return str == "true"
end

-- Model streaming data
streamTimes = {}
streamTimeObj = {}

-- Set stream time for models
function setModelStreamTime(model, name, sIn, sOut)
    if model then
        streamTimes[model] = {sIn, sOut}
    end
    streamTimes[name] = {sIn, sOut}
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

        if not isElement(obj) then
            timeTable[obj] = nil
        end
        local model = getElementModel(obj)
        local timeData = streamTimes[model]

        if timeData then
            local sIn, sOut = timeData[1], timeData[2]
            if sIn and sOut then
                local shouldStreamIn = isTimeBetween(sIn, 0, sOut, 0)
                local currentState = streamTimeObj[obj]

                if shouldStreamIn and currentState ~= 1 then
                    streamTimeObj[obj] = 1
                    setElementInterior(obj, 0)
                    setElementAlpha(obj,1)
                    local lodDistance = streamingDistances[model] or 0

                elseif not shouldStreamIn and currentState ~= 2 then
                    streamTimeObj[obj] = 2
                    setElementInterior(obj, 52)
                    setElementAlpha(obj,0)
                end
            end
        end
    end
end, 500, 0)

function prepTime(element, id)
    timeTable[element] = streamTimes[id] and true or nil
end


flagsTableNew = {}

objectFlags = {
    {bit = 0, dec = 1, hex = "0x1", name = "is_road", description = "This model is a road.", examples = "Roads"},
    --{bit = 1, dec = 2, hex = "0x2", name = "-", description = "Not read, but present in IDE files.", examples = ""},
    {bit = 2, dec = 4, hex = "0x4", name = "draw_last", description = "Model is transparent. Render this object after all opaque objects, allowing transparencies of other objects to be visible through this object.", examples = "Fences, trees"},
    {bit = 3, dec = 8, hex = "0x8", name = "additive", description = "Render with additive blending. Previous flag will be enabled automatically.", examples = "Night windows"},
    --{bit = 4, dec = 16, hex = "0x10", name = "-", description = "Not read, not present in IDE files.", examples = "-"},
    --{bit = 5, dec = 32, hex = "0x20", name = "-", description = "Works only with animated objects ('anim' section in IDE).", examples = "Doors"},
    {bit = 6, dec = 64, hex = "0x40", name = "no_zbuffer_write", description = "Disable writing to z-buffer when rendering this model, allowing transparencies of other objects, shadows, and lights to be visible through this object.", examples = "Shadows, lights"},
    {bit = 7, dec = 128, hex = "0x80", name = "dont_receive_shadows", description = "Do not draw shadows on this object.", examples = "Small objects, pickups, lamps, trees"},
    --{bit = 8, dec = 256, hex = "0x100", name = "-", description = "Not read, not present in IDE files.", examples = "-"},
    {bit = 9, dec = 512, hex = "0x200", name = "is_glass_type_1", description = "Breakable glass type 1 (additional parameters defined inside the object.dat file, otherwise there is no effect).", examples = "Small windows"},
    {bit = 10, dec = 1024, hex = "0x400", name = "is_glass_type_2", description = "Breakable glass type 2: object first cracks on a strong collision, then it breaks (does also require object.dat registration).", examples = "Large windows"},
    {bit = 11, dec = 2048, hex = "0x800", name = "is_garage_door", description = "Indicates an object as a garage door (for more information see GRGE – requires object.dat registration).", examples = "Garage doors"},
    {bit = 12, dec = 4096, hex = "0x1000", name = "is_damagable", description = "Model with ok/dam states.", examples = "Vehicle upgrades, barriers"},
    {bit = 13, dec = 8192, hex = "0x2000", name = "is_tree", description = "Trees and some plants. These objects move on wind.", examples = "Trees, some plants"},
    {bit = 14, dec = 16384, hex = "0x4000", name = "is_palm", description = "Palms. These objects move on wind.", examples = "Palms"},
    {bit = 15, dec = 32768, hex = "0x8000", name = "does_not_collide_with_flyer", description = "Does not collide with flyer (plane or heli).", examples = "Trees, street lights, traffic lights, road signs, telegraph pole"},
    --{bit = 16, dec = 65536, hex = "0x10000", name = "-", description = "Not read, but present in IDE files.", examples = "Explosive things"},
    --{bit = 17, dec = 131072, hex = "0x20000", name = "-", description = "Not read, but present in IDE files.", examples = "chopcop_ models"},
    --{bit = 18, dec = 262144, hex = "0x40000", name = "-", description = "Not read, but present in IDE files.", examples = "pleasure-DL.dff"},
    --{bit = 19, dec = 524288, hex = "0x80000", name = "-", description = "Unused special object type. Read, but not present in IDE files.", examples = "-"},
    {bit = 20, dec = 1048576, hex = "0x100000", name = "is_tag", description = "This model is a tag. Object will switch from mesh 2 to mesh 1 after getting sprayed by the player.", examples = "Tags"},
    {bit = 21, dec = 2097152, hex = "0x200000", name = "disable_backface_culling", description = "Disables backface culling – as a result the texture will be drawn on both sides of the model.", examples = "Roads, houses, trees, vehicle parts"},
    {bit = 22, dec = 4194304, hex = "0x400000", name = "is_breakable_statue", description = "Object with this model can't be used as cover, i.e., peds won't try to cover behind this object.", examples = "Statue parts in atrium"},
    {bit = 50, dec = 0, hex = "0x000000", name = "disable_collisions", description = "Objects with this flag will have collisions disabled", examples = "Certain vegitation items", fun = setElementCollisionsEnabled, value = false}
}

for _, data in pairs(objectFlags) do
    flagsTableNew[data.bit] = data.name
    flagsTableNew[data.name] = data.name
end

function countCommas(str)
    local str = str or ""
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

function getFlags(attribute)
    local list = flagList(attribute.flags)
    for _, flag in pairs(list) do

        if tonumber(flag) then
            if flagsTableNew[tonumber(flag)] then
                attribute[flagsTableNew[tonumber(flag)]] = true
            end
        else
            if flagsTableNew[flagValue] then
                attribute[flagsTableNew[flagValue]] = true
            end
        end
    end
end


function splitStringByComma(inputString)
    -- Check if the string contains a comma
    if string.find(inputString, ",") then
        local result = {}
        -- Iterate through each value separated by commas
        for value in string.gmatch(inputString, "([^,]+)") do
            -- Trim spaces from the value and insert it into the result table
            local trimmedValue = string.gsub(value, "^%s*(.-)%s*$", "%1")
            table.insert(result, trimmedValue)
        end
        return result
    else
        -- If no comma, return the original string in a table
        return {inputString}
    end
end




function findImg(assetType,resourceName)
    if not resourceImages[resourceName] then
        resourceImages[resourceName] = {}
    end

    if not resourceImages[resourceName][assetType] then
        resourceImages[resourceName][assetType] = engineLoadIMG(string.format(":%s/imgs/%s.img", resourceName, assetType))
        engineAddImage( resourceImages[resourceName][assetType] )
    end

    local img = resourceImages[resourceName][assetType]

    return img,string.format(":%s/imgs/%s.img", resourceName, assetType)
end

function prepIMGFiles(img,resourceName,path)
    local filesInArchive = engineImageGetFiles( img )

    for i = 1, #filesInArchive do
        imageFiles[resourceName][filesInArchive[i]] = img
    end

    print(path)
end


function prepResourceIMGs(resourceName)
    if fileExists(string.format(":%s/imgs/dff.img", resourceName)) then
        imageFiles[resourceName] = {}

        for _,v in pairs(IMGNames) do
            for i = 1, maxIMG do
                if (i == 1) then
                    if fileExists(string.format(":%s/imgs/%s_%s.img", resourceName,v,i)) then
                        local img = findImg(v..'_'..i,resourceName)
                        prepIMGFiles(img,resourceName,string.format(":%s/imgs/%s_%s.img", resourceName,v,i))
                    elseif fileExists(string.format(":%s/imgs/%s.img", resourceName,v)) then
                        local img = findImg(v,resourceName)
                        prepIMGFiles(img,resourceName,string.format(":%s/imgs/%s.img", resourceName,v))
                    end
                else
                    if fileExists(string.format(":%s/imgs/%s_%s.img", resourceName,v,i)) then
                        local img = findImg(v..'_'..i,resourceName)
                        prepIMGFiles(img,resourceName,string.format(":%s/imgs/%s_%s.img", resourceName,v,i))
                    end
                end
            end
        end
    end
end

function split(str, sep)
    if type(str) ~= "string" or str == "" or not string.find(str, sep, 1, true) then
        return false
    end

    local result = {}
    for token in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(result, token)
    end

    if #result == 0 then
        return false
    end

    return result
end

function showNearbyBuildings(_,radius)
    local px, py, pz = getElementPosition(localPlayer)
    radius = tonumber(radius) or 35
    local buildings = getElementsByType("building")
    local count = 0

    outputChatBox("#0066CC[Nearby Buildings]#FFFFFF Scanning within #FFFF00" .. radius .. "m#FFFFFF...", 255, 255, 255,true)

    for _, b in ipairs(buildings) do
        local ox, oy, oz = getElementPosition(b)
        local dist = getDistanceBetweenPoints3D(px, py, pz, ox, oy, oz)

        if dist <= radius then
            local model = getElementModel(b)
            local id = getElementID(b) or "N/A"
            local zone = definitionZones[id] or "Unknown"

            outputChatBox(string.format(
                "#CCCCCC • #00BFFFModel: #FFFFFF%s  #AAAAAA|  #00BFFFID: #FFFFFF%s  #AAAAAA|  #00BFFFZone: #FFFFFF%s  #AAAAAA|  #00BFFFDist: #FFFFFF%sm",
                model, id, zone, math.floor(dist)
            ), 255, 255, 255,true)

            count = count + 1
        end
    end

    if count == 0 then
        outputChatBox("#FF4444No buildings found within #FFFF00" .. radius .. "m#FF4444.", 255, 255, 255,true)
    else
        outputChatBox("#00FF00Total buildings found: #FFFFFF" .. count, 255, 255, 255,true)
    end
end

addCommandHandler("nearbybuildings", showNearbyBuildings)



function showNearbyObjects(_,radius)
    local px, py, pz = getElementPosition(localPlayer)
    radius = tonumber(radius) or 35
    local objects = getElementsByType("object")
    local count = 0

    outputChatBox("#0066CC[Nearby Objects]#FFFFFF Scanning within #FFFF00" .. radius .. "m#FFFFFF...", 255, 255, 255,true)

    for _, obj in ipairs(objects) do
        local ox, oy, oz = getElementPosition(obj)
        local dist = getDistanceBetweenPoints3D(px, py, pz, ox, oy, oz)

        if dist <= radius then
            local model = getElementModel(obj)
            local id = getElementID(obj) or "N/A"
            local zone = definitionZones[id] or "Unknown"

            outputChatBox(string.format(
                "#CCCCCC • #00BFFFModel: #FFFFFF%s  #AAAAAA|  #00BFFFID: #FFFFFF%s  #AAAAAA|  #00BFFFZone: #FFFFFF%s  #AAAAAA|  #00BFFFDist: #FFFFFF%sm",
                model, id, zone, math.floor(dist)
            ), 255, 255, 255,true)

            count = count + 1
        end
    end

    if count == 0 then
        outputChatBox("#FF4444No objects found within #FFFF00" .. radius .. "m#FF4444.", 255, 255, 255,true)
    else
        outputChatBox("#00FF00Total objects found: #FFFFFF" .. count, 255, 255, 255,true)
    end
end

addCommandHandler("nearbyobjects", showNearbyObjects)



