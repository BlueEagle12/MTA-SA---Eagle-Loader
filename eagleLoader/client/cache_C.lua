
globalCache = {}
idCache = {}
useLODs = {}
objectValid = {}
objectChecked = {}


function requestModelID(modelID,setModels)
	
	if not objectChecked[modelID] then
		local objects = getElementsByType("object")
		for i, object in pairs(objects) do
			if (getElementID(object) == modelID) then
				objectValid[modelID] = true
			end
		end
	end
	
	objectChecked[modelID] = true
	
	if not idCache[modelID] then
		idCache[modelID] = engineRequestModel('object')
	end
	
	if (setModels and idCache[modelID]) then
		local objects = getElementsByType("object")
		for i, object in pairs(objects) do
			if (getElementID(object) == modelID) then
				setElementModel(object,idCache[modelID])
			end
		end
	end
		

	return idCache[modelID],false,objectValid[modelID]
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