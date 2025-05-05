resourceLoaded = {}
mapUnloaded = false
lodIDList = {}

function getLines(file)
	local fData = fileRead(file, fileGetSize(file))
	local fProccessed = split(fData,10) -- Split the lines
	fileClose (file)
	return fProccessed
end

function splitFileLines(file)
	local data = fileRead(file, fileGetSize(file))
	fileClose (file)


    local result = {}
    for line in data:gmatch("[^\r\n]+") do
        table.insert(result, line)
    end
    return result
end



function onResourceStartTimer(resourceThatStarted)
	local resourceName = getResourceName(resourceThatStarted)
	local path = ((":%s/%s"):format(resourceName,'eagleZones.txt'))
	local waterPath = ((":%s/%s"):format(resourceName,'water.dat'))
	local exists = fileExists(path) --// Confirm eagleZones exists, if so latch onto this resource.
	local definitionList = {}
	local elementList = {}
	
	if exists then
		if not resourceLoaded[resourceName] then -- Confirm resource is not already loaded


			-- [[ Load maps first ]] -- 
			local maps = splitFileLines(fileOpen(path))
			for _,map in pairs(maps) do
				local list = loadMap(resourceName,map)
				if list then
					for i,v in ipairs(list) do
						table.insert(elementList,v)

						local lod = v.lodParent
						if lod then
							lodIDList[lod] = true
						end
					end
				end
			end

			local zones = splitFileLines(fileOpen(path))
			for _,zone in pairs(zones) do
				local list = loadZone(resourceName,zone)
				if list then
					for i,v in pairs(list) do

						if (lodIDList[v.id] and highDefLODs) then
							-- Ignore
						else
							table.insert(definitionList,v)
						end
					end
				end
			end
		end


		if removeDefaultMap then
			setWaterLevel (-10000000)
			removeGameWorld()
			setOcclusionsEnabled(false)
		end
		
		streamMapElements(resourceName,elementList)

		local last = definitionList[#definitionList]
		if last then
			local lastID = last.id
			loadMapDefinitions(resourceName,definitionList,lastID)
		end

		parseWaterDat(waterPath,resourceName)
	end
end

addEventHandler( "onClientResourceStart", root, onResourceStartTimer)

function loadZone(resourceName,zone)

	local zone = zone:gsub("%s+", "")
	
	local path = (":%s/zones/%s/%s.definition"):format(resourceName, zone, zone)
	
	local test = fileExists(path)

	local zoneDefinitions = xmlLoadFile(path)
	
	if zoneDefinitions then

		local sDefintions = xmlNodeGetChildren(zoneDefinitions)
		local newTable = {}
		
		for _,definiton in pairs (sDefintions) do
			local attributes = xmlNodeGetAttributes(definiton)
			getFlags(attributes)
			table.insert(newTable,attributes)
		end
		
		xmlUnloadFile(zoneDefinitions)
		return newTable
	else
		print(string.format("Unable to find zone: %s", path))
	end
end


function loadMap(resourceName,zone)
	local zone = zone:gsub("%s+", "")
	
	local path = (":%s/zones/%s/%s.map"):format(resourceName, zone, zone)

	if fileExists(path) then -- Removed debug because some zones are strictly definition zones.
		local mapContents = xmlLoadFile(path)

		local sContents = xmlNodeGetChildren(mapContents)
		local newTable = {}
		
		if sContents then
			for _,definiton in ipairs (sContents) do
				local attributes = xmlNodeGetAttributes(definiton)
				local elementType = xmlNodeGetName(definiton)
				attributes.type = elementType
				table.insert(newTable,attributes)
			end
			
			xmlUnloadFile(mapContents)
		end
		return newTable
	end
end