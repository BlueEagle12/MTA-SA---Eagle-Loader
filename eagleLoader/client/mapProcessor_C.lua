

function getLines(file)
	local fData = fileRead(file, fileGetSize(file))
	local fProccessed = split(fData,10) -- Split the lines
	fileClose (file)
	return fProccessed
end


function onResourceStart(resourceThatStarted)
	local resourceName = getResourceName(resourceThatStarted)
	local path = ((":%s/%s"):format(resourceName,'eagleZones.txt'))
	local exists = fileExists(path) --// We want to check if the resource has an eagleZones file, this is so we don't have to go through server side which may cause issues.
	local definitionList = {}
	local elementList = {}
	
	if exists then
		local zones = getLines(fileOpen(path))
		for _,zone in pairs(zones) do
			local list = loadZone(resourceName,zone)
			if list then
				for i,v in pairs(list) do
					table.insert(definitionList,v)
				end
			end
		end
		

		local maps = getLines(fileOpen(path))
		for _,map in pairs(maps) do
			local list = loadMap(resourceName,map)
			for i,v in pairs(list) do
				table.insert(elementList,v)
			end
		end
	end
	

	local last = definitionList[#definitionList]
	if last then
		local lastID = last.id
		loadMapDefinitions(resourceName,definitionList,lastID)
	end
	
	local last = elementList[#elementList]
	if last then
		local lastID = last.id
		
		setTimer(streamMapElements, 8000, 1,resourceName,elementList,lastID)
	end
end


addEventHandler( "onClientResourceStart", root, onResourceStart)

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
	local mapContents = xmlLoadFile(path)

	local sContents = xmlNodeGetChildren(mapContents)
	local newTable = {}
	
	for _,definiton in pairs (sContents) do
		local attributes = xmlNodeGetAttributes(definiton)
		local elementType = xmlNodeGetName(definiton)
		attributes.type = elementType
		table.insert(newTable,attributes)
	end
	
	xmlUnloadFile(mapContents)
	return newTable
end