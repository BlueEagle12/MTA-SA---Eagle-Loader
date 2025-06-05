-- =========================
-- Resource Management State
-- =========================
resource           = {}   -- Holds map definitions and data
resourceModels     = {}   -- Holds models assigned to each resource
resourceImages     = {}
imageFiles         = {}

streamingDistances = {}   -- Stores streaming distances per model
validID            = {}   -- Tracks valid IDs of loaded models
definitionZones    = {}   -- Stores zones associated with model definitions
timeIDs            = {}

itemIDList         = {}   -- Used for tracking a list of "Item IDs" for LOD parenting
itemIDListUnique   = {}   -- Unique ID list (used for duplicate IDs)
lodParents         = {}
backFaceCull       = {}
uniqueIDs          = {}
textureIDs         = {}
definedProperties  = {}

selfLODList        = {}

-- Optionally increase streaming memory on nightly builds
if engineStreamingSetMemorySize then
    engineStreamingSetMemorySize(streamingMemoryAllowcation * 1024 * 1024)
    engineStreamingSetBufferSize(streamingBufferAllowcation * 1024 * 1024)
end

-- ==============================
-- Asset Loading / Streaming Core
-- ==============================
local function collectValidIDs()
    for _, obj in ipairs(getElementsByType('object')) do
        validID[getElementID(obj)] = true
    end
    for _, obj in ipairs(getElementsByType('building')) do
        validID[getElementID(obj)] = true
    end
end

local function findFile(assetName, assetType, resourceName, zone)
    local assetPath        = string.format(":%s/zones/%s/%s/%s.%s", resourceName, zone, assetType, assetName, assetType)
    local assetPathTexture = string.format(":%s/textures/%s.txd", resourceName, assetName)
    if fileExists(assetPath) then
        return assetPath
    elseif fileExists(assetPathTexture) then
        return assetPathTexture
    end
end

local function requestTextureID(assetName, img, path)
    if not textureIDs[assetName] then
        textureIDs[assetName] = engineRequestTXD(assetName)
        engineImageLinkTXD(img, path, textureIDs[assetName])
    end
    return textureIDs[assetName]
end

local function loadImgAsset(assetType, assetName, resourceName, modelID)
    if not assetName then return end
    local assetPath = string.format("%s.%s", assetName, assetType)
    local img = imageFiles[resourceName] and imageFiles[resourceName][assetPath]
    if not img then return end

    if assetType == "txd" then
        local tID = requestTextureID(assetName, img, assetPath)
        engineSetModelTXDID(modelID, tID)
    elseif assetType == "col" then
        local asset = engineImageGetFile(img, assetPath)
        local col   = engineLoadCOL(asset)
        engineReplaceCOL(col, modelID)
    elseif assetType == "dff" then
        engineImageLinkDFF(img, assetPath, modelID)
    end
end

local function loadAsset(assetType, assetName, resourceName, zone, modelID, alpha)
    if not assetName then return end
    local assetPath = findFile(assetName, assetType, resourceName, zone)
    if not assetPath then
        outputDebugString2(string.format("%s: %s could not be found!", assetType:upper(), assetName.."."..assetType))
        idCache[assetName] = nil
        return
    end

    local loaderFunc =
        (assetType == "txd" and requestTextureArchive) or
        (assetType == "col" and requestCollision) or
        (assetType == "dff" and requestModel)

    local asset, cachePath = loaderFunc(assetPath, assetName)
    if not asset then
        outputDebugString2(string.format("%s: %s could not be loaded!", assetType:upper(), assetName))
        idCache[assetName] = nil
        return
    end

    if assetType == "txd" then
        engineImportTXD(asset, modelID)
    elseif assetType == "col" then
        engineReplaceCOL(asset, modelID)
    elseif assetType == "dff" then
        engineReplaceModel(asset, modelID, alpha or false)
    end
    -- Optionally: cache loaded asset
    -- table.insert(resource[resourceName], cachePath)
end

local function tryLoadAsset(assetType, fileName, resourceName, zone, modelID, ...)
    if not fileName then return end
    if inIMGAsset(fileName, assetType, resourceName) then
        loadImgAsset(assetType, fileName, resourceName, modelID)
    else
        if findFile(fileName, assetType, resourceName, zone) then
            loadAsset(assetType, fileName, resourceName, zone, modelID, ...)
        end
    end
end

-- =========================
-- Map Definitions Loading
-- =========================
function loadMapDefinitions(resourceName, mapDefinitions, last)
    resourceModels[resourceName] = {}
    resource[resourceName] = {}
    startTickCount = getTickCount()
    collectValidIDs()
    prepIMGContainers(resourceName)
    Async:setPriority("medium")
    Async:foreach(mapDefinitions, function(data)
        local modelID, isNew = requestModelID(data.id, true)
        if not tonumber(modelID) then
            outputDebugString2(string.format("Error: Failed to request model ID for object with ID: %s", tostring(data.id)))
            return
        end

        if isNew then
            resourceModels[resourceName][modelID] = true
        end

        if streamEverything or validID[data.id] then
            definedProperties[data.id] = definedProperties[data.id] or {}
            local zone        = data.zone
            local lodDistance = tonumber(data.lodDistance) or 200

            definitionZones[modelID] = zone
            definitionZones[data.id] = zone

            -- LOD distance logic
            local finalDist = (highDefLODs or lodDistance < 10) and 700 or lodDistance
            finalDist = finalDist * drawDistanceMultiplier
            engineSetModelLODDistance(modelID, finalDist, true)
            streamingDistances[modelID] = finalDist

            -- Set model flags and custom funs
            for _, v in pairs(objectFlags) do
                if v.fun then
                    if data[v.name] then
                        definedProperties[data.id][v.fun] = v.value
                    end
                else
                    engineSetModelFlag(modelID, v.name, data[v.name] or false)
                end
            end

            -- Load assets
            local txdTable = split(data.txd, ',')
            if txdTable then
                for _, txd in ipairs(txdTable) do
                    tryLoadAsset('txd', txd, resourceName, zone, modelID)
                end
            else
                tryLoadAsset('txd', data.txd, resourceName, zone, modelID)
            end
            tryLoadAsset('col', data.col, resourceName, zone, modelID)
            tryLoadAsset('dff', data.dff or data.id, resourceName, zone, modelID, data['draw_last'] or data['additive'])

            backFaceCull[data.id] = data['disable_backface_culling']

            -- Time window
            if data.timeIn then
                timeIDs[data.id] = {tonumber(data.timeIn), tonumber(data.timeOut)}
                setModelStreamTime(modelID, data.id, tonumber(data.timeIn), tonumber(data.timeOut))
            end
        end

        if data.id == last then
            loaded(resourceName)
        end
    end)
end

-- =========================
-- Unloading & Cleanup
-- =========================
function unloadMapDefinitions(name)
    if not name or not resource[name] then return end

    -- Destroy associated elements

    unloadResourceIMGs(name)


    for i,v in pairs(reverseID) do
        if resourceModels[name][i] then
            idCache[v] = nil
            reverseID[i] = nil
        end
    end

    -- Free all models assigned to this resource
    if resourceModels[name] then
        for ID in pairs(resourceModels[name]) do
            engineFreeModel(ID)
        end
    end

    resource[name] = nil
    resourceModels[name] = nil

    outputDebugString2(string.format("Successfully unloaded map definitions for resource: %s", name))
end

addEvent("resourceStop", true)
addEventHandler("resourceStop", resourceRoot, unloadMapDefinitions)

-- =========================
-- Event Handling & Streaming
-- =========================

-- Loads objects and buildings, sets up streaming etc.
function initializeObjects()
    local allElements = {}
    for _, object in ipairs(getElementsByType("object")) do
        table.insert(allElements, object)
    end
    for _, building in ipairs(getElementsByType("building")) do
        table.insert(allElements, building)
    end

    for _, element in ipairs(allElements) do
        if isElement(element) then
            local id = getElementID(element)
            if id then
                setElementStream(element, id, true, true)
            end
        end
    end
end

function loadedFunction(resourceName)
    if not startTickCount or type(startTickCount) ~= "number" then
        outputDebugString2("Error: startTickCount is invalid or not set.")
        return
    end
    local endTickCount = getTickCount() - startTickCount
    if isElement(resourceRoot) then
        triggerServerEvent("onPlayerLoad", resourceRoot, tostring(endTickCount), resourceName)
    else
        outputDebugString2("Error: resourceRoot is invalid or not available.")
    end
    createTrayNotification(string.format("You have finished loading: %s", resourceName), "info")
end

function loaded(resourceName)
    loadedFunction(resourceName)
    initializeObjects()
    engineRestreamWorld()
    writeDebugFile()
    removeWorldMapConfirm()
    setTimer(removeWorldMapConfirm, 1000, 5)
end

-- =========================
-- Streaming and Object Creation
-- =========================

selfLODList = {}

function setElementStream(object, newModel, streamNew, initial, lodParent, uniqueID)
    if not isElement(object) or not newModel then
        outputDebugString2("Error: Invalid element or model specified.")
        return
    end

    local id = getElementID(object) or newModel
    if not id then
        outputDebugString2("Error: Could not determine element ID.")
        return
    end

    setElementDoubleSided(object, backFaceCull[id] or false)

    local cachedModel = idCache[id]
    if cachedModel then
        -- Assign unique ID if provided
        if uniqueID then
            uniqueIDs[object] = uniqueID
        end

        -- Set element properties
        setElementModel(object, cachedModel)
        setElementID(object, id)
        setElementData(object, "Zone", definitionZones[id] or "")
        prepTime(object, id)

        -- Track by unique or non-unique lists
        if uniqueID then
            itemIDListUnique[id] = itemIDListUnique[id] or {}
            itemIDListUnique[id][uniqueID] = object
        else
            itemIDList[id] = itemIDList[id] or {}
            table.insert(itemIDList[id], object)
        end
            
        local properties = definedProperties[id] or {} -- Fall back if non existant

        for i,v in ipairs(definedProperties) do
            i(id,v)
        end

        lodParent = lodParents[object] or lodParent

        if highDefLODs and lodParent then
            if getElementType(object) == "building" then
                if selfLODList[object] then
                    destroyElement(selfLODList[object])
                end
                local x, y, z = getElementPosition(object)
                local xr, yr, zr = getElementRotation(object)
                local build = createBuilding(1337, x, y, z, xr, yr, zr)
                setElementModel(build, getElementModel(object))
                setLowLODElement(object, build)
                selfLODList[object] = build
                prepTime(build, getElementModel(object))
                setElementCollisionsEnabled(build, false)
            end
        else
            if lodParent then

                if string.lower(lodParent) == "self" then
                    if getElementType(object) == "building" then
                        if selfLODList[object] then
                            destroyElement(selfLODList[object])
                        end
                        local x, y, z = getElementPosition(object)
                        local xr, yr, zr = getElementRotation(object)
                        local build = createBuilding(1337, x, y, z, xr, yr, zr)
                        setElementModel(build, getElementModel(object))
                        setLowLODElement(object, build)
                        selfLODList[object] = build
                        prepTime(build, getElementModel(object))
                        setElementCollisionsEnabled(build, false)
                    end
                else

                    lodParents[object] = lodParent
                    local parent = (itemIDListUnique[lodParent] or {})[uniqueID or 0] or (itemIDList[lodParent] or {})[1]
                    if parent then
                        setLowLODElement(object, parent)
                        if lodAttach and lodAttach[lodParent] then
                            attachElements(object, parent)
                        end
                    end
                end
            end
        end

    else
        -- Fallback if no cached model: use defaultIDs
        local model = defaultIDs[id]
        if model then
            setElementModel(object, model)
            setElementID(object, id)
        else
            --outputDebugString2(string.format("Error: Model ID %s not found in cache (Default).", id))
        end
    end
end

-- Register the event
addEvent("setElementStream", true)
addEventHandler("setElementStream", resourceRoot, setElementStream)


function streamObject(id, x, y, z, xr, yr, zr, interior, lodParent, uniqueID, int)
    if not id then
        outputDebugString2("Error: Trying to create invalid object.")
        return
    end
    x, y, z = x or 0, y or 0, z or 0
    xr, yr, zr = tonumber(xr) or 0, tonumber(yr) or 0, tonumber(zr) or 0

    local obj = createObject(1337, x, y, z, xr, yr, zr)
    if tonumber(interior) and tonumber(interior) <= 18 then
        setElementInterior(obj, tonumber(interior) or 0)
    end
    if lodParent then lodParents[obj] = lodParent end
    if uniqueID then uniqueIDs[obj] = uniqueID end
    backFaceCull[id] = true

    if not int then
        setElementStream(obj, id, true, nil, lodParent, uniqueID)
    end
    setElementID(obj, id)
    return obj
end

function streamBuilding(id, x, y, z, xr, yr, zr, interior, lodParent, uniqueID, int)
    if not id then
        outputDebugString2("Error: Trying to create invalid building.")
        return
    end
    x, y, z = tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0
    xr, yr, zr = tonumber(xr) or 0, tonumber(yr) or 0, tonumber(zr) or 0

    if (x > -3000) and (x < 3000) and (y > -3000) and (y < 3000) then
        local build = createBuilding(1337, x, y, z, xr, yr, zr, (interior == 0 and nil or interior))
        if lodParent then lodParents[build] = lodParent end
        if uniqueID then uniqueIDs[build] = uniqueID end
        if not int then setElementStream(build, id, true, nil, lodParent, uniqueID) end
        setElementID(build, id)
        return build
    end
end




function onElementDataChange(dataName, oldValue)
    if dataName == "id" and isElement(source) then
        local newId = getElementID(source)
        if newId and idCache[newId] and newId ~= oldValue then
            setElementStream(source, newId)
        end
    end
end

addEventHandler("onElementDataChange", root, onElementDataChange)

function onElementDestroy()
    local elementID = getElementID(source)
    local elementType = getElementType(source)
    if elementID and idCache[elementID] and (elementType == "object" or elementType == "building") then
        local LOD = getLowLODElement(source)
        if isElement(LOD) then
            destroyElement(LOD)
            outputDebugString2(string.format("LOD for %s with ID %s destroyed successfully.", elementType, elementID))
        end
    end
end

addEventHandler("onElementDestroy", resourceRoot, onElementDestroy)




function getMaps()
    local tempTable = {}
    for name in pairs(resource) do
        table.insert(tempTable, name)
    end
    return tempTable
end