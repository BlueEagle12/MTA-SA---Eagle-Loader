
for i=550,20000 do
    removeWorldModel(i,10000,0,0,0)
end
setOcclusionsEnabled(false)
setWaterLevel(-5000)

offSet = {0,0,60}

resourceObjects = {}
function isTrue(inString)
	if (inString == 'True') or (inString == 'true') then
		return true
	end
end


function streamObject(tableIn,resource)
	if resource then
		resourceObjects = resourceObjects[resource] or {}
	end
	
	local dataTable = split(tableIn,',')

	if (#dataTable) > 1 then
		local sID,x,y,z,xR,yZ,zR,doubleSidedCull,interior,dimension = unpack(dataTable)
		
		
		local object = createObject(8585,(tonumber(x) or 0)+offSet[1],(tonumber(y) or 0)+offSet[2],(tonumber(z) or 0)+offSet[3],tonumber(xR) or 0,tonumber(yZ) or 0,tonumber(zR) or 0)
		setElementData(object,'definitionID',sID)	
		setElementID(object,sID)	
		
		if resource then
			table.insert(data.resourceObjects[resource],object)
		end
			

		setElementInterior(object,(interior or 0))
		setElementDimension(object,(dimension or -1))
		
		if isTrue(doubleSidedCull) then
			setElementDoubleSided(object,true)
		end
		return object
	end
end

function changeObjectModel(object,newModel)
	triggerServerEvent ( root,"changeObjectModel", root, object,newModel )
end

function playerLoaded ( loadTime,resource )
	print(getPlayerName(client),'Loaded '..resource..' In : '..(tonumber(loadTime)*0.01),' Secounds')
end
addEventHandler( "onPlayerLoad", resourceRoot, playerLoaded )

function onResourceStop(resource)
	if resourceObjects[resource] then
		for i,v in pairs(resourceObjects[resource]) do
			destroyElement(resource)
		end
		resourceObjects[resource] = nil
	end
end
addEventHandler( "onResourceStop", root,onResourceStop)

function getMaps()
	local tempTable = {}
	for i,v in pairs(data.resourceObjects) do
		table.insert(tempTable,i)
	end
	return tempTable
end

function getMapElements(map)
	return data.resourceObjects[map]
end
