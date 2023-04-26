
globalCache = {}
idCache = {}
useLODs = {}

allowcateDefaultIDs = true --// If we're out of custom IDs can we dig into SA?

function requestModelID(modelID)

	if not idCache[modelID] then
		idCache[modelID] = engineRequestModel('object')
		
		if not idCache[modelID] then
			if allowcateDefaultIDs then
				idCache[modelID] = engineRequestSAModel('object')
			end
		end
		return idCache[modelID],true
	end
		

	return idCache[modelID]
end

function requestTextureArchive(path)
	if fileExists(path) then
		globalCache[path] = globalCache[path] or engineLoadTXD(path)
		return globalCache[path],path
	else
		return false
	end
end

function requestCollision(path)
	if fileExists(path) then
		globalCache[path] = globalCache[path] or engineLoadCOL(path)
		return globalCache[path],path
	else
		return false
	end
end

function requestModel(path)
	if path then
		globalCache[path] = globalCache[path] or engineLoadDFF(path)
		return globalCache[path],path
	end
end