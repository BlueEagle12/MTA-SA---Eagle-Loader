-- //Properties you can edit
removeDefaultMap = true

-- //Rest of the script
if removeDefaultMap then
	for i=550,20000 do
		removeWorldModel(i,10000,0,0,0)
	end
	setOcclusionsEnabled(false)
end

function playerLoaded ( loadTime,resource )
	local minutes = tonumber(loadTime) / (1000 * 60)
	
	print(getPlayerName(client),'Loaded '..resource..' In : '..(minutes),' Minutes')
end
addEvent( "onPlayerLoad", true )
addEventHandler( "onPlayerLoad", resourceRoot, playerLoaded )


function onResourceStop(resource) -- // Trigger the client event on resource stop ONLY when it stops on the server side, this is to prevent exit times from being extreme.
	local rName = getResourceName(resource)
	triggerClientEvent ( root, "resourceStop", root, rName )
end
addEventHandler( "onResourceStop", root, onResourceStop)

function streamObject(id,x,y,z,xr,yr,zr)
	local x = x or 0
	local y = y or 0
	local z = z or 0
	local obj = createObject(1337,x,y,z,xr,yr,zr)
	setElementID(obj,id)
	return obj
end

function streamBuilding(id,x,y,z,xr,yr,zr)
	local x = x or 0
	local y = y or 0
	local z = z or 0
	local build = createBuilding(1337,x,y,z,xr,yr,zr)
	setElementID(build,id)
	return build
end

function setElementStream(object,newModel)
	triggerClientEvent ( resourceRoot,"setElementStream", root, object,newModel )
end