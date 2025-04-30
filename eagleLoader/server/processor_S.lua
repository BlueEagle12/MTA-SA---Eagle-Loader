

function playerLoaded ( loadTime,resource )
	local secounds = (tonumber(loadTime) / (1000 * 60))* 60
	
	print(getPlayerName(client),'Loaded '..resource..' In : '..(secounds),' Secounds')

end
addEvent( "onPlayerLoad", true )
addEventHandler( "onPlayerLoad", resourceRoot, playerLoaded )


function onResourceStop(resource) -- // Trigger the client event on resource stop ONLY when it stops on the server side, this is to prevent exit times from being extreme.
	local rName = getResourceName(resource)
	triggerClientEvent ( root, "resourceStop", root, rName )
end
addEventHandler( "onResourceStop", root, onResourceStop)

function streamObject(id,x,y,z,xr,yr,zr,interior,lod)
	local x = x or 0
	local y = y or 0
	local z = z or 0
	local obj = createObject(1337,x,y,z,xr,yr,zr)
	setElementID(obj,id)
	return obj
end

function streamBuilding(id,x,y,z,xr,yr,zr,interior,lod)
	local x = x or 0
	local y = y or 0
	local z = z or 0
	local build = createBuilding(1337,x,y,z,xr,yr,zr,interior)
	setElementID(build,id)
	return build
end

function setElementStream(object,newModel)
	triggerClientEvent ( resourceRoot,"setElementStream", root, object,newModel )
end