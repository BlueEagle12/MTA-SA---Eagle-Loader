
-- Tables --
resource = {}
resourceModels = {}

streamEverything = true

function loadMapDefinitions ( resourceN,dataIn ) -- // Feed this a single line (ID,Zone,DFF,COL,TXD,alphaTransparency,LOD,LODDistance) to load a single definition.
	resourceModels[resourceN] = {}
	startTickCount = getTickCount ()
	resource[resourceN] = {}
	
	resourceName = resourceN
	
	Async:setPriority("high")
	Async:foreach(dataIn, function(data)
		local data = split(data,',')
			
		local modelID,new,exists = requestModelID(data[1],true)
		
		if new then
			resourceModels[resourceName][modelID] = true
		end
			
		if streamEverything or exists then
			
			print(data[1])
			
			engineSetModelLODDistance (modelID,math.max(tonumber(data[8] or 200),300))
						
			local LOD = data[7]
				
			if (not LOD == 'false') then
				if (LOD == 'true') then
					useLODs[modelID] = modelID
				else
					useLODs[modelID] = LOD
				end
			end
				
				
			local zone = data[2]
				
			local textureString = data[5]
			local collisionString = data[4]
			local modelString = data[1]
					
			local TXDPath = ':'..resourceName..'/zones/'..zone..'/content/txd/'..textureString..'.txd'
			local COLPath = ':'..resourceName..'/zones/'..zone..'/content/col/'..collisionString..'.col'
			local DFFPath = ':'..resourceName..'/zones/'..zone..'/content/dff/'..modelString..'.dff'

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
			
		local LOD = useLODs[getElementData(object,'definitionID')]
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

		--[[
		Async:setPriority("medium")
		Async:foreach(resourceName, function(resourceName)
			
			local objects = getElementsByType("object")
			for _,object in pairs(objects) do
				local LOD = useLODs[getElementData(object,'definitionID')]
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
			end
		end)
		]]--



function loadedFunction (resourceName)
	local endTickCount = getTickCount ()-startTickCount
	triggerServerEvent ( "onPlayerLoad", resourceRoot, tostring(endTickCount),resourceName )
	createTrayNotification( 'You have finished loading : '..resourceName, "info" )
end


function changeObjectModel (object,newModel)
	if getElementData(object,'definitionID') then
		print(getElementData(object,'definitionID')..'- Changed to : '..newModel)
		if idCache[newModel] then
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
end
addEvent( "resourceStop", true )
addEventHandler( "resourceStop", localPlayer, unloadMapDefinitions )

function onElementDestroy()
	if getElementType(source) == "object" then
		if getLowLODElement(source) then
			destroyElement(getLowLODElement(source))
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
