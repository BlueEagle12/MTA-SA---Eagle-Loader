
-- Tables --
resource = {}
resourceModels = {}

streamEverything = true

function loadMapDefinitions ( resourceName,mapDefinitions )
	resourceModels[resourceName] = {}
	startTickCount = getTickCount ()
	resource[resourceName] = {}
	

	Async:setPriority("high")
	Async:foreach(mapDefinitions, function(data)
			
		local modelID,new,exists = requestModelID(data.id,true)
		
		if new then
			resourceModels[resourceName][modelID] = true
		end
			
		if streamEverything or exists then
			
			engineSetModelLODDistance (modelID,math.max(tonumber(data.lodDistance or 200),300))
						
			local LOD = data.lod
				
			if LOD and (not LOD == 'false') then
				if (LOD == 'true') then
					useLODs[modelID] = modelID
				else
					useLODs[modelID] = LOD
				end
			end
				
				
			local zone = data.zone
				
			local textureString = data.txd
			local collisionString = data.col
			local modelString = data.dff
					
			local TXDPath = ':'..resourceName..'/zones/'..zone..'/txd/'..textureString..'.txd'
			local COLPath = ':'..resourceName..'/zones/'..zone..'/col/'..collisionString..'.col'
			local DFFPath = ':'..resourceName..'/zones/'..zone..'/dff/'..modelString..'.dff'

			local texture,textureCache = requestTextureArchive(TXDPath,textureString)
			local collision,collisionCache = requestCollision(COLPath,collisionString)
			local model,modelCache = requestModel(DFFPath)
				
				
			if collision then
				engineReplaceCOL(collision,modelID)
				table.insert(resource[resourceName],collisionCache)
			else
				print('Collision : '..collisionString..' could not be loaded!')
			end
			
			if texture then
				engineImportTXD(texture,modelID)
				table.insert(resource[resourceName],textureCache)
			else
				print('Texture : '..textureString..' could not be loaded!')
			end
				
			if model then
				engineReplaceModel(model,modelID)
				table.insert(resource[resourceName],modelCache)
			else
				print('Model : '..modelString..' could not be loaded!')
			end
			print('Model : '..modelString..' loaded!')
		end
	end)

	loadedFunction(resourceName)
	
	Async:setPriority("medium")
	Async:foreach(getElementsByType("object"), function(object)
			
		local LOD = useLODs[getElementID(object)]
		if LOD then
			local x,y,z,xr,yr,zr = getElementPosition (object),getElementRotation (object)
			local nObject = createObject (idCache[LOD],x,y,z,xr,yr,zr,true)
			local cull,dimension,interior = isElementDoubleSided(object),getElementDimension(object),getElementInterior(object)
			setElementDoubleSided(nObject,cull)
			setElementInterior(nObject,interior)
			setElementDimension(nObject,dimension)
			setElementData(nObject,'definitionID',LOD)
			setLowLODElement(object,nObject)
		end
	end)
end

function loadedFunction (resourceName)
	local endTickCount = getTickCount ()-startTickCount
	triggerServerEvent ( "onPlayerLoad", resourceRoot, tostring(endTickCount),resourceName )
	createTrayNotification( 'You have finished loading : '..resourceName, "info" )
end


function changeObjectModel (object,newModel)
	local id = (idCache[getElementID(object)] and getElementID(object))
	
	if id then
		if idCache[newModel] then
			print(id..'- Changed to : '..newModel)
			setElementModel(object,idCache[newModel])
			setElementData(object,'definitionID',idCache[newModel])
			if getLowLODElement(object) then
				local LOD = getLowLODElement(object)
				if LOD then
					destroyElement(LOD) -- // Clear LOD if it exists
				end
				
				if useLODs[newModel] then -- // Create new LOD if this model has a LOD assigned to it
					local x,y,z,xr,yr,zr = getElementPosition (object),getElementRotation (object)
					local nObject = createObject (idCache[LOD],x,y,z,xr,yr,zr,true)
					local cull,dimension,interior = isElementDoubleSided(object),getElementDimension(object),getElementInterior(object)
					setElementDoubleSided(nObject,cull)
					setElementInterior(nObject,interior)
					setElementDimension(nObject,dimension)
					setElementData(nObject,'definitionID',LOD)
					setLowLODElement(object,nObject)
				end
			end
		end
	end
end
addEventHandler( "changeObjectModel", resourceRoot, changeObjectModel )



function onElementDataChange(dataName, oldValue)
    if (dataName == "id") then
        local newId = getElementID(source)
		if idCache[newId] then
			if (newId ~= oldValue) then
				changeObjectModel (source,newId)
			end
		end
    end
end
addEventHandler("onElementDataChange", root, onElementDataChange)

function unloadMapDefinitions(name) -- // Feed this the resource name in order to unload the definitions loaded.
	if resource[name] then
		Async:setPriority("medium")
		Async:foreach(resource[name], function(data)
			if cache[data] then
				destroyElement(cache[data])
				cache[data] = nil
			end
		end)
		
		for ID,_ in pairs(resourceModels[name]) do
			engineFreeModel(ID)
		end
	end
	resource[name] = nil
	resourceModels[name] = nil
end
addEvent( "resourceStop", true )
addEventHandler( "resourceStop", localPlayer, unloadMapDefinitions )

function onElementDestroy()
	if idCache[getElementID(source)] then -- // Only destroying the LOD if it's a custom model
		if getElementType(source) == "object" then
			if getLowLODElement(source) then
				destroyElement(getLowLODElement(source))
			end
		end
	end
end
addEventHandler("onElementDestroy",resourceRoot,onElementDestroy)


function getMaps()
	local tempTable = {}
	for i,v in pairs(resource) do
		table.insert(tempTable,i)
	end
	return tempTable
end
