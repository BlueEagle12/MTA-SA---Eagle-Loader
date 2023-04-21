-- //Properties you can edit
removeDefaultMap = true


-- //Rest of the script
if removeDefaultMap then
	for i=550,20000 do
		removeWorldModel(i,10000,0,0,0)
	end
	setOcclusionsEnabled(false)
	setWaterLevel(-5000)
end

function changeObjectModel(object,newModel)
	triggerServerEvent ( root,"changeObjectModel", root, object,newModel )
end

function playerLoaded ( loadTime,resource )
	print(getPlayerName(client),'Loaded '..resource..' In : '..(tonumber(loadTime)*0.01),' Secounds')
end
addEvent( "onPlayerLoad", true )
addEventHandler( "onPlayerLoad", resourceRoot, playerLoaded )


function onResourceStop(resource) -- // Trigger the client event on resource stop ONLY when it stops on the server side, this is to prevent exit times from being extreme.
	local rName = getResourceName(resource)
	triggerClientEvent ( root, "resourceStop", root, rName )
end
addEventHandler( "onResourceStop", root, onResourceStop)