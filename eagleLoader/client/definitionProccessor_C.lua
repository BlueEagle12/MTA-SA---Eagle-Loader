
-- Tables --
resource		    = {}
resourceModels 	 	= {}

streamingDistances  = {}

validID 			= {}
streamEverything    = true

definitionZones     = {}
lodAttach 			= {}
lodAttach['tram']   = true

function loadMapDefinitions ( resourceName,mapDefinitions,last)
	resourceModels[resourceName] = {}
	startTickCount = getTickCount ()
	resource[resourceName] = {}
	

	for i,v in pairs(getElementsByType('object')) do -- // Loop through all of the objects and mark which IDs exist
		local id = getElementID(v)
		validID[id] = true
	end
	
	
	Async:setPriority("high")
	Async:foreach(mapDefinitions, function(data)
			
		if not (data.default == 'true') then
			
			local modelID,new = requestModelID(data.id,true)
			
			if modelID then
				
				if new then
					resourceModels[resourceName][modelID] = true
				end
					
				if streamEverything or validID[data.id] then
					
					local zone = data.zone
					
					definitionZones[modelID] = zone
						
					local textureString = data.txd

					local TXDPath = ':'..resourceName..'/zones/'..zone..'/txd/'..textureString..'.txd'

					local texture,textureCache = requestTextureArchive(TXDPath,textureString)

					if texture then
						engineImportTXD(texture,modelID)
						table.insert(resource[resourceName],textureCache)
						
						if (data.id == last) then
							loadModels (resourceName,mapDefinitions,last)
						end
					else
						print('Texture : '..textureString..' could not be loaded!')
					end
				end
			end
		end
	end)
end

function loadModels(resourceName,mapDefinitions,last)
	Async:setPriority("medium")
	Async:foreach(mapDefinitions, function(data)
			
		if not (data.default == 'true') then
			
			local modelID,_,exists = requestModelID(data.id)
			
			if modelID then
				
				if streamEverything or validID[data.id] then
					
					engineSetModelLODDistance (modelID,tonumber(data.lodDistance or 200))
					streamingDistances[modelID] = (tonumber(data.lodDistance or 200))

					
					local LOD = data.lod
					local LODID = data.lodID
						
					if LOD then
						if (LOD == 'true') then
							useLODs[data.id] = (data.lodID or data.id)
						end
					end
					
					local zone = data.zone
						
					local modelString = data.dff
					
					local DFFPath = ':'..resourceName..'/zones/'..zone..'/dff/'..modelString..'.dff'
					local model,modelCache = requestModel(DFFPath)
						
					if model then
						if (data.alphaTransparency == 'true') then
							engineReplaceModel(model,modelID,true)
						else
							engineReplaceModel(model,modelID)
						end
						table.insert(resource[resourceName],modelCache)
					else
						print('Model : '..modelString..' could not be loaded!')
					end
				end

				if data.timeIn then
					setModelStreamTime (modelID, tonumber(data.timeIn), tonumber(data.timeOut))
				end
				
				if (data.id == last) then
					loaded (resourceName,true)
				end
			else
				print('Object : '..data.id..' could not be loaded! : OUT OF IDs')
			end
		end
	end)
	
	Async:setPriority("medium")
	Async:foreach(mapDefinitions, function(data)
			
		if not (data.default == 'true') then
			
			local modelID,_,exists = requestModelID(data.id)
			
			if modelID then
				if streamEverything or validID[data.id] then
					
					local zone = data.zone
						
					local collisionString = data.col

					local COLPath = ':'..resourceName..'/zones/'..zone..'/col/'..collisionString..'.col'

					local collision,collisionCache = requestCollision(COLPath,collisionString)

					if collision then
						engineReplaceCOL(collision,modelID)
						table.insert(resource[resourceName],collisionCache)
					else
						print('Collision : '..collisionString..' could not be loaded!')
					end
				end
				
				if (data.id == last) then
					loaded(resourceName,false)
				end
			else
				print('Object : '..data.id..' could not be loaded! : OUT OF IDs')
			end
		end
	end)
end

resourceLoaded = {}
resourceLoaded['Models'] = {}
resourceLoaded['Collisions'] = {}

function loaded(resourceName,DFF)
	if DFF then
		resourceLoaded['Models'][resourceName] = true
		if resourceLoaded['Collisions'][resourceName] then
			loadedFunction (resourceName)
			initializeObjects()
		end
	else
		resourceLoaded['Collisions'][resourceName] = true
		if resourceLoaded['Models'][resourceName] then
			loadedFunction (resourceName)
			initializeObjects()
		end
	end
end
					

function initializeObjects()
	Async:setPriority("medium")
	Async:foreach(getElementsByType("object"), function(object)
	
		local id = getElementID(object)
		changeObjectModel(object,id,true,true)
	end)
end

function loadedFunction (resourceName)
	local endTickCount = getTickCount ()-startTickCount
	triggerServerEvent ( "onPlayerLoad", resourceRoot, tostring(endTickCount),resourceName )
	createTrayNotification( 'You have finished loading : '..resourceName, "info" )
end


function changeObjectModel (object,newModel,streamNew,inital)
	local id = getElementID(object)
	
	if id or streamNew then
		if idCache[newModel] then
			if not inital then
				if id then
					print(id..'- Changed to : '..newModel)
				else
					print('New object streamed with ID: '..newModel)
				end
			end
			setElementModel(object,idCache[newModel])
			setElementID(object,newModel)
			setElementData(object,'Zone',definitionZones[id])
			local LOD = getLowLODElement(object)
			if LOD then
				destroyElement(LOD) -- // Clear LOD if it exists
			end
				
			if useLODs[newModel] then -- // Create new LOD if this model has a LOD assigned to it
				local x,y,z,xr,yr,zr = getElementPosition (object)
				local xr,yr,zr = getElementRotation (object)
				local nObject = createObject (idCache[newModel],x,y,z,xr,yr,zr,true)
				local cull,dimension,interior = isElementDoubleSided(object),getElementDimension(object),getElementInterior(object)
				setElementData(nObject,'Zone',definitionZones[newModel])
				setElementDoubleSided(nObject,cull)
				setElementInterior(nObject,interior)
				setElementDimension(nObject,dimension)
				setElementID(nObject,newModel)
				setLowLODElement(object,nObject)
				if lodAttach[newModel] then
					attachElements(nObject,object)
				end
			end
		end
	end
end
addEvent( "changeObjectModel", true )
addEventHandler( "changeObjectModel", resourceRoot, changeObjectModel )


function streamObject(id,x,y,z,xr,yr,zr)
	local x = x or 0
	local y = y or 0
	local z = z or 0
	local obj = createObject(1337,x,y,z,xr,yr,zr)
	changeObjectModel(obj,id,true)
	setElementID(obj,id)
	return obj
end



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
