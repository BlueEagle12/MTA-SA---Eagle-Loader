
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
removeDefaultMap = true   -- Disable if you'd like to keep the SA map

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

-- ===========================
-- Item IDs
-- ===========================
itemIDList = {}    -- Used for tracking a list of "Item IDs" used current for LOD parenting
itemIDListUnique = {} -- Unique ID list (Used for duplicate IDs)
lodParents = {}
backFaceCull = {}
uniqueIDs = {}
drawDistanceMultiplier = 5




function loadMapDefinitions(resourceName, mapDefinitions, last)
    resourceModels[resourceName] = {}
    startTickCount = getTickCount()
   resource[resourceName]  = {}


    for _, obj in pairs(getElementsByType('object')) do
        validID[getElementID(obj)] = true
    end

    for _, obj in pairs(getElementsByType('building')) do
        validID[getElementID(obj)] = true
    end

    Async:setPriority("medium")
    Async:foreach(mapDefinitions, function(data)
        if data.default == 'true' then
            --return
        end

        local modelID, isNew = requestModelID(data.id, true)
        if not modelID then
            outputDebugString2(string.format("Error: Failed to request model ID for object with ID: %s", tostring(data.id)))
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
			

            if (lodDistance < 10) then
                engineSetModelLODDistance(modelID, 700*drawDistanceMultiplier, true )
                streamingDistances[modelID] = 700*drawDistanceMultiplier
            else
                engineSetModelLODDistance(modelID, lodDistance*drawDistanceMultiplier, true )
                streamingDistances[modelID] = lodDistance*drawDistanceMultiplier
            end

            for i,v in pairs(objectFlags) do
                if data[v.name] then
                    engineSetModelFlag(modelID,v.name,true)
                else
                    engineSetModelFlag(modelID,v.name,false)
                end
            end

            loadAsset('txd', data.txd, resourceName, zone, modelID)
            loadAsset('col', data.col, resourceName, zone, modelID)
            loadAsset('dff', data.id, resourceName, zone, modelID, data['draw_last'] or data['additive'])



            backFaceCull[data.id] = data['disable_backface_culling']

            if data.timeIn then
                setModelStreamTime(modelID,data.id, tonumber(data.timeIn), tonumber(data.timeOut))
            end
        end

        if data.id == last then
            loaded(resourceName)
        end
    end)
end

function findFile(assetName,assetType,resourceName,zone)
    local assetPath = string.format(":%s/zones/%s/%s/%s.%s", resourceName, zone, assetType, assetName, assetType)
    local assetPathTextures = string.format(':%s/textures/%s.txd',resourceName,assetName)
    if fileExists(assetPath) then
        return assetPath
    else
        if fileExists(assetPathTextures) then
            return assetPathTextures
        end
    end
end

function loadAsset(assetType, assetName, resourceName, zone, modelID, alpha)
    if not assetName then return end


    local isTXD = (assetType == "txd")
    local assetPath = findFile(assetName,assetType,resourceName,zone)

    if assetPath then
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
                local loaded = engineReplaceModel(asset, modelID, alpha or false)
            end
        
            -- Cache the loaded asset for release
            table.insert(resource[resourceName], cachePath)
        else
            outputDebugString2(string.format('%s: %s could not be loaded!', assetType:upper(), assetName))
        end
    else
    local assetPath = string.format(":%s/zones/%s/%s/%s.%s", resourceName, zone, assetType, assetName, assetType)
        outputDebugString2(string.format('%s: %s could not be found!', assetType:upper(), assetName.."."..assetType))
    end
end

function loaded(resourceName)
	loadedFunction (resourceName)
	initializeObjects()
    initializeObjects()
    writeDebugFile()
end
				
function initializeObjects()

    local allElements = {}
    for _, object in ipairs(getElementsByType("object")) do
        table.insert(allElements, object)
    end
    for _, building in ipairs(getElementsByType("building")) do
        table.insert(allElements, building)
    end

    for i,element in pairs (allElements) do
        if not isElement(element) then
            return
        end

        local id = getElementID(element)
        
        if id then
            setElementStream(element, id, true, true)
        else
           -- print("Error: Element has no valid ID and cannot be initialized.")
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

function setElementStream(object, newModel, streamNew, initial, lodParent,uniqueID)

    if not isElement(object) or not newModel then
        outputDebugString2("Error: Invalid element or model specified.")
        return
    end

    local id = getElementID(object) or newModel

    if id then


        local cachedModel = idCache[id]

        setElementDoubleSided(object,(backFaceCull[id] or false))

        if cachedModel then

            
            local lodParent = lodParent or lodParents[object]

            local uniqueID = uniqueID or uniqueIDs[object]

            if uniqueID then
                uniqueIDs[object] = uniqueID
            end


            setElementModel(object, cachedModel)
            setElementID(object, id)
            setElementData(object, "Zone", definitionZones[id] or "")
			prepTime(object,id)
            
            if uniqueID then
                itemIDListUnique[id] = itemIDListUnique[id] or {}
                itemIDListUnique[id][uniqueID] = object
            else
                itemIDList[id] = itemIDList[id] or {}
                table.insert(itemIDList[id],object)
            end


            
            if lodParent then
                lodParents[object] = lodParent

                local parent = (itemIDListUnique[lodParent] or {})[uniqueID or 0] or (itemIDList[lodParent] or {})[1]
                
                if parent then
                    setLowLODElement(object, parent)
                    if lodAttach[lodParent] then
                        attachElements(object, children)
                    end
                end
            end
        else
			local model = defaultIDs[id]
			if model then
				setElementModel(object, model)
				setElementID(object, id)
			else
				outputDebugString2(string.format("Error: Model ID %s not found in cache (Default).", id))
			end
        end
    end
end

-- Register the event
addEvent("setElementStream", true)
addEventHandler("setElementStream", resourceRoot, setElementStream)


function streamObject(id,x,y,z,xr,yr,zr,interior,lodParent,uniqueID,int)
	local x = x or 0
	local y = y or 0
	local z = z or 0

	local xr = tonumber(xr) or 0
	local yr = tonumber(yr) or 0
	local zr = tonumber(zr) or 0

	local obj = createObject(1337,x,y,z,xr,yr,zr)
	
	local cachedModel = true--idCache[id]
	
    if lodParent then
        lodParents[obj] = lodParent
    end

    if uniqueID then
        uniqueIDs[obj] = uniqueID
    end

    backFaceCull[id] = true


	if cachedModel then


		if (not int) then
			setElementStream(obj,id,true,nil,lodParent,uniqueID)
		end
			
		setElementID(obj,id)
		
		return obj
	else
		outputDebugString2(string.format("Error: Model ID %s not found in cache.", id))
	end
end

function streamBuilding(id,x,y,z,xr,yr,zr,interior,lodParent,uniqueID,int)
	local x = tonumber(x) or 0
	local y = tonumber(y) or 0
	local z = tonumber(z) or 0
	
	local xr = tonumber(xr) or 0
	local yr = tonumber(yr) or 0
	local zr = tonumber(zr) or 0

	local cachedModel = true --idCache[id]


	if cachedModel then
		if (x > -3000) and (x < 3000) and (y > -3000) and (y < 3000) then
			
			local build = createBuilding(1337,x,y,z,xr,yr,zr)
			
			if (not int) then
				setElementStream(build,id,true,nil,lodParent,uniqueID)
			end

            if lodParent then
                lodParents[build] = lodParent
            end
        
            if uniqueID then
                uniqueIDs[build] = uniqueID
            end
			
			setElementID(build,id)
			return build
		end
	else
		outputDebugString2(string.format("Error: Model ID %s not found in cache.", id))
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

--addEventHandler("onElementDataChange", root, onElementDataChange)

function unloadMapDefinitions(name)

    if not name or not resource[name] then
        return
    end

    if resourceModels[name] then
        for ID, _ in pairs(resourceModels[name]) do
            if ID and engineFreeModel(ID) then
                --print(string.format("Model ID %s successfully freed.", ID))
            else
                --print(string.format("Warning: Model ID %s could not be freed or does not exist.", ID))
            end
        end
    end

    for i,v in pairs(resource[name]) do
        if isElement(resource[name]) then
            destroyElement(resource[name])
        end
    end

    resource[name] = nil
    resourceModels[name] = nil

    outputDebugString2(string.format("Successfully unloaded map definitions for resource: %s", name))
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
                outputDebugString2(string.format("LOD for %s with ID %s destroyed successfully.", elementType, elementID))
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
