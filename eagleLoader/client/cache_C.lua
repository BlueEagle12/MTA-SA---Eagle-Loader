globalCache = {}
idCache = {}
useLODs = {}

-- Request a model ID
function requestModelID(modelID)
    local cachedID = idCache[modelID]
    
    if not cachedID then
        cachedID = engineRequestModel('object')
        
        if cachedID > 19999 then
            cachedID = nil
        end

        if not cachedID and allocateDefaultIDs then
            cachedID = engineRequestSAModel('object')
        end

        if cachedID then
            idCache[modelID] = cachedID
            return cachedID, true
        end
    end

    return cachedID or false
end


local function requestAsset(path, resourceName, loadFunc)

    globalCache[resourceName] = globalCache[resourceName] or {}

    if not globalCache[resourceName][path] and fileExists(path) then
        globalCache[resourceName][path] = loadFunc(path)
    end

    return globalCache[resourceName][path] or false
end

function requestTextureArchive(path, resourceName)
    return requestAsset(path, resourceName, engineLoadTXD)
end

function requestCollision(path, resourceName)
    return requestAsset(path, resourceName, engineLoadCOL)
end

function requestModel(path, resourceName)
    return requestAsset(path, resourceName, engineLoadDFF)
end

function releaseCache(resourceName)
    if globalCache[resourceName] then
        for path in pairs(globalCache[resourceName]) do
            globalCache[resourceName][path] = nil
        end
        globalCache[resourceName] = nil
        return true
    end
    return false
end
