-- Global asset/model cache tables
globalCache = {}
idCache     = {}
useLODs     = {}
reverseID   = {}

-- Request a unique model ID for a given logical model key
function requestModelID(modelID)
    if not modelID then return false end

    local cachedID = idCache[modelID]
    if cachedID then
        return cachedID
    end

    local newID = engineRequestModel('object')
    if newID and newID <= 19999 then
        idCache[modelID] = newID

        reverseID[newID] = modelID
        return newID, true
    end

    -- Fallback: allocate from SA pool if configured
    if not newID and allocateDefaultIDs then
        newID = engineRequestSAModel('object')
        if newID then
            idCache[modelID] = newID

            reverseID[newID] = modelID
            return newID, true
        end
    end

    return false
end

-- Generic asset loader with caching per resource
local function requestAsset(path, resourceName, loadFunc)
    if not (path and resourceName and loadFunc) then return false end

    globalCache[resourceName] = globalCache[resourceName] or {}

    if not globalCache[resourceName][path] and fileExists(path) then
        globalCache[resourceName][path] = loadFunc(path)
    end

    return globalCache[resourceName][path] or false
end

-- Specialized asset requests
function requestTextureArchive(path, resourceName)
    return requestAsset(path, resourceName, engineLoadTXD)
end

function requestCollision(path, resourceName)
    return requestAsset(path, resourceName, engineLoadCOL)
end

function requestModel(path, resourceName)
    return requestAsset(path, resourceName, engineLoadDFF)
end

-- Release all cached assets for a given resource
function releaseCache(resourceName)
    if not resourceName or not globalCache[resourceName] then return false end
    globalCache[resourceName] = nil
    return true
end
