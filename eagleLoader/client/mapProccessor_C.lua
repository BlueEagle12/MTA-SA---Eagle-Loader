

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
	if exists then
		local zones = getLines(fileOpen(path))
		for _,zone in pairs(zones) do
			loadZone(resourceName,zone)
		end
	end
end



addEventHandler( "onClientResourceStart", root, onResourceStart)

function loadZone(resourceName,zone)
	local path = ':'..resourceName..'/zones/'..zone..'/'..zone..'.definition'
	local zoneDefinitions = xmlLoadFile(path)
	print(path)
	local sDefintions = xmlNodeGetChildren(zoneDefinitions)
	local newTable = {}
	
	for _,definiton in pairs (sDefintions) do
		local attributes = xmlNodeGetAttributes(definiton)
		table.insert(newTable,attributes)
	end
	
	loadMapDefinitions(resourceName,newTable)
	xmlUnloadFile(zoneDefinitions)
end

