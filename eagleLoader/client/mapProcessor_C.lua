resourceLoaded = {}
mapUnloaded = false
lodIDList = {}

-- Utility: Read all lines from a file handle, returns a table of lines
local function fileToLines(fh)
    if not fh then return {} end
    local size = fileGetSize(fh)
    if not size or size == 0 then fileClose(fh); return {} end
    local data = fileRead(fh, size)
    fileClose(fh)
    local result = {}
    for line in data:gmatch("[^\r\n]+") do
        table.insert(result, line)
    end
    return result
end

-- Load a zone .definition file (returns table of attribute tables)
function loadZone(resourceName, zone)
    zone = zone:gsub("%s+", "")
    local path = (":%s/zones/%s/%s.definition"):format(resourceName, zone, zone)
    if not fileExists(path) then
        print(string.format("Unable to find zone: %s", path))
        return
    end
    local xml = xmlLoadFile(path)
    if not xml then return end
    local defs = {}
    for _, node in ipairs(xmlNodeGetChildren(xml)) do
        local attributes = xmlNodeGetAttributes(node)
        getFlags(attributes)
        table.insert(defs, attributes)
    end
    xmlUnloadFile(xml)
    return defs
end

-- Load a zone .map file (returns table of attribute tables with .type field)
function loadMap(resourceName, zone)
    zone = zone:gsub("%s+", "")
    local path = (":%s/zones/%s/%s.map"):format(resourceName, zone, zone)
    if not fileExists(path) then return end
    local xml = xmlLoadFile(path)
    if not xml then return end
    local entries = {}
    for _, node in ipairs(xmlNodeGetChildren(xml)) do
        local attributes = xmlNodeGetAttributes(node)
        attributes.type = xmlNodeGetName(node)
        table.insert(entries, attributes)
    end
    xmlUnloadFile(xml)
    return entries
end

-- Remove world map and/or interiors as needed
function removeWorldMapConfirm(water)
    if removeDefaultMap then
        if water then
            setWaterLevel(-10000000)
        end
        if removeDefaultInteriors then
            removeGameWorld()
        else
            for i = 0, 20000 do
                removeWorldModel(i, 10000, 0, 0, 0, 0)
                removeWorldModel(i, 10000, 0, 0, 0, 256)
                removeWorldModel(i, 10000, 0, 0, 0, 1024)
                removeWorldModel(i, 10000, 0, 0, 0, 768)
                removeWorldModel(i, 10000, 0, 0, 0, 4096)
                removeWorldModel(i, 10000, 0, 0, 0, 274)
                removeWorldModel(i, 10000, 0, 0, 0, 6114)
                removeWorldModel(i, 10000, 0, 0, 0, 2048)
                removeWorldModel(i, 10000, 0, 0, 0, 128)
            end
        end
        setOcclusionsEnabled(false)
    end
end

-- Handles loading zones, maps, and water on resource start
function onResourceStartTimer(resourceThatStarted)
    local resourceName = getResourceName(resourceThatStarted)
    local zoneFilePath = (":%s/eagleZones.txt"):format(resourceName)
    local waterFilePath = (":%s/water.dat"):format(resourceName)
    if not fileExists(zoneFilePath) or resourceLoaded[resourceName] then return end

    local elementList, definitionList = {}, {}

    -- Load maps first
    local fh = fileOpen(zoneFilePath)
    local maps = fileToLines(fh)
    for _, map in ipairs(maps) do
        for _, v in ipairs(loadMap(resourceName, map) or {}) do
            table.insert(elementList, v)
            if v.lodParent then lodIDList[v.lodParent] = true end
        end
    end

    -- Then definitions
    local fh2 = fileOpen(zoneFilePath)
    local zones = fileToLines(fh2)
    for _, zone in ipairs(zones) do
        for _, v in ipairs(loadZone(resourceName, zone) or {}) do
            if not (lodIDList[v.id] and highDefLODs) then
                table.insert(definitionList, v)
            end
        end
    end

    removeWorldMapConfirm(true)
    engineRestreamWorld()
    streamMapElements(resourceName, elementList)

    local lastDef = definitionList[#definitionList]
    if lastDef then
        loadMapDefinitions(resourceName, definitionList, lastDef.id)
    end

    parseWaterDat(waterFilePath, resourceName)
end

addEventHandler("onClientResourceStart", root, onResourceStartTimer)
