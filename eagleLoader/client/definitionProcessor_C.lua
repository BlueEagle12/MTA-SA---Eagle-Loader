
-- Tables --
-- ===========================
-- Resource Management
-- ===========================
resource           = {} -- Holds map definitions and data
resourceModels     = {} -- Holds models assigned to each resource

-- ===========================
-- IMG Management
-- ===========================
resourceImages     = {}
imageFiles = {}


-- ===========================
-- Streaming & Distances
-- ===========================
streamingDistances = {} -- Stores streaming distances per model

-- ===========================
-- Valid IDs & Definitions
-- ===========================
validID            = {} -- Tracks valid IDs of loaded models
definitionZones    = {} -- Stores zones associated with model definitions
timeIDs            = {}

-- ===========================
-- Item IDs
-- ===========================
itemIDList = {}    -- Used for tracking a list of "Item IDs" used current for LOD parenting
itemIDListUnique = {} -- Unique ID list (Used for duplicate IDs)
lodParents = {}
backFaceCull = {}
uniqueIDs = {}
textureIDs = {}


if engineStreamingSetMemorySize then -- Increases maximum streaming memory if on nightly
    engineStreamingSetMemorySize(streamingMemoryAllowcation * 1024 * 1024)
    engineStreamingSetBufferSize(streamingBufferAllowcation * 1024 * 1024)
end

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

    prepResourceIMGs(resourceName)

    Async:setPriority("medium")
    Async:foreach(mapDefinitions, function(data)
        if data.default == 'true' then
            --return
        end

        local modelID, isNew = requestModelID(data.id, true)
        if not tonumber(modelID) then
            outputDebugString2(string.format("Error: Failed to request model ID for object with ID: %s", tostring(data.id)))
            return
        end

        if isNew then
            if resourceModels[resourceName] then
                resourceModels[resourceName][modelID] = true
            end
        end

        if streamEverything or validID[data.id] then
            local zone = data.zone
            local lodDistance = tonumber(data.lodDistance) or 200
            local lodEnabled = (data.lod == 'true')

            definitionZones[modelID] = zone
			definitionZones[data.id] = zone



            if highDefLODs then
                engineSetModelLODDistance(modelID, 700*drawDistanceMultiplier, true )
                streamingDistances[modelID] = 700*drawDistanceMultiplier
            else
                
                if (lodDistance < 10) then
                    engineSetModelLODDistance(modelID, 700*drawDistanceMultiplier, true )
                    streamingDistances[modelID] = 700*drawDistanceMultiplier
                else
                    engineSetModelLODDistance(modelID, lodDistance*drawDistanceMultiplier, true )
                    streamingDistances[modelID] = lodDistance*drawDistanceMultiplier
                end
            end

            for i,v in pairs(objectFlags) do
                if data[v.name] then
                    engineSetModelFlag(modelID,v.name,true)
                else
                    engineSetModelFlag(modelID,v.name,false)
                end
            end


            if fileExists(string.format(":%s/imgs/dff.img", resourceName)) then
                if split(data.txd,',') then
                    txdTable = split(data.txd,',')
                    for ti=0,#txdTable do
                        loadImgAsset('txd', txdTable[ti], resourceName, modelID)
                    end
                else
                    loadImgAsset('txd', data.txd, resourceName, modelID)
                end
                loadImgAsset('col', data.col, resourceName, modelID)
                loadImgAsset('dff', data.id, resourceName, modelID)
            else
                if split(data.txd,',') then
                    txdTable = split(data.txd,',')
                    for ti=0,#txdTable do
                        loadAsset('txd', txdTable[ti], resourceName, zone, modelID)
                    end
                else
                    loadAsset('txd', data.txd, resourceName, zone, modelID)
                end
                loadAsset('col', data.col, resourceName, zone, modelID)
                loadAsset('dff', data.id, resourceName, zone, modelID, data['draw_last'] or data['additive'])
            end

            backFaceCull[data.id] = data['disable_backface_culling']

            if data.timeIn then
                timeIDs[data.id] = {tonumber(data.timeIn), tonumber(data.timeOut)}
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

function requestTextureID(assetName,img,path)
    if textureIDs[assetName] then
        return textureIDs[assetName]
    else
        textureIDs[assetName] = engineRequestTXD(assetName)

        engineImageLinkTXD( img, path, textureIDs[assetName] )

        return textureIDs[assetName]
    end
end



function loadImgAsset(assetType, assetName, resourceName, modelID)
    if not assetName then return end

    local assetPath = string.format("%s.%s", assetName, assetType)

    local img,path = imageFiles[resourceName][assetPath]

    if img then

        if assetType == 'txd' then
            local tID = requestTextureID(assetName,img,assetPath)
            engineSetModelTXDID(modelID, tID)
        elseif assetType == 'col' then
            local asset = engineImageGetFile(img, assetPath)
            local col = engineLoadCOL(asset)
            engineReplaceCOL(col, modelID)
        elseif assetType == 'dff' then
            engineImageLinkDFF(img,assetPath,modelID)
        end
    end
end

function loadAsset(assetType, assetName, resourceName, zone, modelID, alpha)
    if not assetName then return end

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
                engineReplaceModel(asset, modelID, alpha or false)
            end
        
            -- Cache the loaded asset for release
            --table.insert(resource[resourceName], cachePath)
        else
            outputDebugString2(string.format('%s: %s could not be loaded!', assetType:upper(), assetName))

            idCache[assetName] = nil
        end
    else
    local assetPath = string.format(":%s/zones/%s/%s/%s.%s", resourceName, zone, assetType, assetName, assetType)
        outputDebugString2(string.format('%s: %s could not be found!', assetType:upper(), assetName.."."..assetType))
        idCache[assetName] = nil
    end
end

local icChe = {}
idx = 0
local batchSize = 100

function loaded(resourceName)
	loadedFunction (resourceName)
	initializeObjects()
    initializeObjects()

    engineRestreamWorld()

    writeDebugFile()

    removeWorldMapConfirm()
    setTimer(removeWorldMapConfirm,1000,5) -- Repeat because for some reason sometimes it doesn't remove initially
end






function onClientElementStreamIn()
	local validElement = isElement(source)

	if (not validElement) then
		return false
	end


    local model = getElementModel(source)

    for i,v in pairs(idCache) do
        if (v == model) then
            outputDebugString2(string.format('%s: %s Streamed!', v ,i))
        end
    end

end
addEventHandler("onClientElementStreamIn", resourceRoot, onClientElementStreamIn)




function removeWorldMapConfirm()

    if removeDefaultMap then
        if not mapUnloaded then
            removeGameWorld()
            setOcclusionsEnabled(false)
        end
    end
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

selfLODList = {}

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


            if highDefLODs and lodParent then
                if getElementType(object) == 'building' then
                    if selfLODList[object] then
                        destroyElement(selfLODList[object])
                    end

                    local x,y,z = getElementPosition(object)
                    local xr,yr,zr = getElementRotation(object)
                    local build = createBuilding(1337,x,y,z,xr,yr,zr)
                    setElementModel(build,getElementModel(object))
                    setLowLODElement(object, build)

                    selfLODList[object] = build

                    prepTime(build, getElementModel(object))

                end
            else

                if lodParent then

                    if (lodParent == 'self') or (lodParent == 'Self') then --// Updated way of selfIDing.
                        if getElementType(object) == 'building' then
                            if selfLODList[object] then
                                destroyElement(selfLODList[object])
                            end
                            
                            local x,y,z = getElementPosition(object)
                            local xr,yr,zr = getElementRotation(object)
                            local build = createBuilding(1337,x,y,z,xr,yr,zr)
                            setElementModel(build,getElementModel(object))
                            setLowLODElement(object, build)

                            selfLODList[object] = build

                            prepTime(build, getElementModel(object))
                            
                            print("SELF LOD")
                        end
                    else
                        lodParents[object] = lodParent

                        local parent = (itemIDListUnique[lodParent] or {})[uniqueID or 0] or (itemIDList[lodParent] or {})[1]
                        
                        if parent then
                            setLowLODElement(object, parent)
                            if lodAttach[lodParent] then
                                attachElements(object, children)
                            end
                        end
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
    if id then
        local x = x or 0
        local y = y or 0
        local z = z or 0

        local xr = tonumber(xr) or 0
        local yr = tonumber(yr) or 0
        local zr = tonumber(zr) or 0

        local obj = createObject(1337,x,y,z,xr,yr,zr)
        
        setElementInterior(obj,(interior or 0))
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
    else
        outputDebugString2("Error: Trying to create invalid object.")
    end
end

function streamBuilding(id,x,y,z,xr,yr,zr,interior,lodParent,uniqueID,int)
    if id then
        local x = tonumber(x) or 0
        local y = tonumber(y) or 0
        local z = tonumber(z) or 0
        
        local xr = tonumber(xr) or 0
        local yr = tonumber(yr) or 0
        local zr = tonumber(zr) or 0

        local cachedModel = true --idCache[id]


        if cachedModel then
            if (x > -3000) and (x < 3000) and (y > -3000) and (y < 3000) then
                
                local build = createBuilding(1337,x,y,z,xr,yr,zr,(interior == 0 and nil or interior))
                
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
    else
        outputDebugString2("Error: Trying to create invalid building.")
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
