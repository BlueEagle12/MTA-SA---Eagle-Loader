
-- Tables --
-- ===========================
-- Resource Management
-- ===========================
resource           = {} -- Holds map definitions and data
resourceModels     = {} -- Holds models assigned to each resource

-- ===========================
-- Streaming & Distances
-- ===========================
streamingDistances = {} -- Stores streaming distances per model
streamEverything   = true -- Set to true to stream all elements by default

-- ===========================
-- Valid IDs & Definitions
-- ===========================
validID            = {} -- Tracks valid IDs of loaded models
definitionZones    = {} -- Stores zones associated with model definitions

-- ===========================
-- LOD Attachments
-- ===========================
lodAttach = {           -- Anything that LODs should be attached to, currently includes Tram for LC.
    ["Tram"] = true
}


function loadMapDefinitions(resourceName, mapDefinitions, last)
    resourceModels[resourceName] = {}
    startTickCount = getTickCount()
    resource[resourceName] = {}


    for _, obj in pairs(getElementsByType('object')) do
        validID[getElementID(obj)] = true
    end

    Async:setPriority("medium")
    Async:foreach(mapDefinitions, function(data)
        if data.default == 'true' then
            return
        end

        local modelID, isNew = requestModelID(data.id, true)
        if not modelID then
            print(string.format("Error: Failed to request model ID for object with ID: %s", tostring(data.id)))
            return
        end

        if isNew then
            resourceModels[resourceName][modelID] = true
        end

        if streamEverything or validID[data.id] then
            local zone = data.zone
            local lodDistance = tonumber(data.lodDistance) or 200
            local lodEnabled = (data.lod == 'true')

            definitionZones[modelID] = zone
            engineSetModelLODDistance(modelID, lodDistance)
            streamingDistances[modelID] = lodDistance

            if lodEnabled then
                useLODs[data.id] = data.lodID or data.id
            end

            loadAsset('txd', data.txd, resourceName, zone, modelID)
            loadAsset('col', data.col, resourceName, zone, modelID)
            loadAsset('dff', data.dff, resourceName, zone, modelID, data.alphaTransparency == 'true')

            if data.timeIn then
                setModelStreamTime(modelID, tonumber(data.timeIn), tonumber(data.timeOut))
            end
        end

        if data.id == last then
            loaded(resourceName)
        end
    end)
end

function loadAsset(assetType, assetName, resourceName, zone, modelID, alpha)
    if not assetName then return end

    local assetPath = string.format(":%s/zones/%s/%s/%s.%s", resourceName, zone, assetType, assetName, assetType)
    local loaderFunc = assetType == 'txd' and requestTextureArchive or
                       assetType == 'col' and requestCollision or
                       assetType == 'dff' and requestModel

    local asset, cachePath = loaderFunc(assetPath, assetName)
    if asset then
        if assetType == 'txd' then
            engineImportTXD(asset, modelID)
        elseif assetType == 'col' then
            engineReplaceCOL(asset, modelID)
        elseif assetType == 'dff' then
            engineReplaceModel(asset, modelID, alpha or false)
        end

        -- Cache the loaded asset for release
        table.insert(resource[resourceName], cachePath)
    else
        print(string.format('%s: %s could not be loaded!', assetType:upper(), assetName))
    end
end

function loaded(resourceName)
	loadedFunction (resourceName)
	initializeObjects()
end
					
function initializeObjects()

    Async:setPriority("medium")

    local allElements = {}
    for _, object in ipairs(getElementsByType("object")) do
        table.insert(allElements, object)
    end
    for _, building in ipairs(getElementsByType("building")) do
        table.insert(allElements, building)
    end

    Async:foreach(allElements, function(element)
        if not isElement(element) then
            print("Warning: Encountered an invalid element during initialization.")
            return
        end

        local id = getElementID(element)
        
        if id then
            setElementStream(element, id, true, true)
        else
            print("Error: Element has no valid ID and cannot be initialized.")
        end
    end)
end



function loadedFunction(resourceName)
    if not startTickCount or type(startTickCount) ~= "number" then
        print("Error: startTickCount is invalid or not set.")
        return
    end

    local endTickCount = getTickCount() - startTickCount

    if isElement(resourceRoot) then
        triggerServerEvent("onPlayerLoad", resourceRoot, tostring(endTickCount), resourceName)
    else
        print("Error: resourceRoot is invalid or not available.")
    end

    createTrayNotification(string.format("You have finished loading: %s", resourceName), "info")
end

function setElementStream(object, newModel, streamNew, initial)

    if not isElement(object) or not newModel then
        print("Error: Invalid element or model specified.")
        return
    end

    local id = getElementID(object)
    
    if id or streamNew then
        local cachedModel = idCache[newModel]

        if cachedModel then
            if not initial then
                if id then
                    print(string.format("%s - Changed to: %s", id, newModel))
                else
                    print(string.format("New element streamed with ID: %s", newModel))
                end
            end

            setElementModel(object, cachedModel)
            setElementID(object, newModel)
            setElementData(object, "Zone", definitionZones[id])
			prepTime(object,id)

            local LOD = getLowLODElement(object)
            if LOD then
                destroyElement(LOD)
            end

            local assignedLOD = useLODs[newModel]
            if assignedLOD then
                local x, y, z = getElementPosition(object)
                local xr, yr, zr = getElementRotation(object)

                local elementType = getElementType(object)
                local nObject
                if elementType == "building" then
     
                    nObject = createBuilding(cachedModel, x, y, z, xr, yr, zr, true)
                    if nObject then
                        print(string.format("Created new LOD as building for model: %s", newModel))
                    end
                else
                    -- Create an object otherwise
                    nObject = createObject(cachedModel, x, y, z, xr, yr, zr, true)
                    if nObject then
                        print(string.format("Created new LOD as object for model: %s", newModel))
                    end
                end

                if isElement(nObject) then
                    setElementData(nObject, "Zone", definitionZones[newModel])
                    setElementDoubleSided(nObject, isElementDoubleSided(object))
                    setElementInterior(nObject, getElementInterior(object))
                    setElementDimension(nObject, getElementDimension(object))
                    setElementID(nObject, newModel)
					prepTime(nObject,id)

                    setLowLODElement(object, nObject)

                    if lodAttach[newModel] then
                        attachElements(nObject, object)
                    end
                else
                    print(string.format("Error: Failed to create LOD element for model: %s", newModel))
                end
            end
        else
            print(string.format("Error: Model ID %s not found in cache.", newModel))
        end
    end
end

-- Register the event
addEvent("setElementStream", true)
addEventHandler("setElementStream", resourceRoot, setElementStream)




function streamObject(id,x,y,z,xr,yr,zr)
	local x = x or 0
	local y = y or 0
	local z = z or 0
	local obj = createObject(1337,x,y,z,xr,yr,zr)
	setElementStream(obj,id,true)
	setElementID(obj,id)
	return obj
end

function streamBuilding(id,x,y,z,xr,yr,zr,interior)
	local x = x or 0
	local y = y or 0
	local z = z or 0
	local build = createBuilding(1337,x,y,z,xr,yr,zr,interior)
	setElementStream(build,id,true)
	setElementID(build,id)
	return build
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

function unloadMapDefinitions(name)

    if not name or not resource[name] then
        return
    end

    if resourceModels[name] then
        for ID, _ in pairs(resourceModels[name]) do
            if ID and engineFreeModel(ID) then
                print(string.format("Model ID %s successfully freed.", ID))
            else
                print(string.format("Warning: Model ID %s could not be freed or does not exist.", ID))
            end
        end
    end

    resource[name] = nil
    resourceModels[name] = nil

    print(string.format("Successfully unloaded map definitions for resource: %s", name))
end

addEvent("resourceStop", true)
addEventHandler("resourceStop", resourceRoot, unloadMapDefinitions)


function onElementDestroy()

    local elementID = getElementID(source)
    local elementType = getElementType(source)

    if elementID and idCache[elementID] then

        if elementType == "object" or elementType == "building" then
            local LOD = getLowLODElement(source)

            if isElement(LOD) then
                destroyElement(LOD)
                print(string.format("LOD for %s with ID %s destroyed successfully.", elementType, elementID))
            end
        end
    end
end

addEventHandler("onElementDestroy", resourceRoot, onElementDestroy)



function getMaps()
    local tempTable = {}

    if resource and next(resource) then
        for name, _ in pairs(resource) do
            table.insert(tempTable, name)
        end
    end

    return tempTable
end
