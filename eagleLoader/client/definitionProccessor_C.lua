
-- Tables --
resource = {}
resourceModels = {}

streamEverything = true
streamingDistances = {}

function loadMapDefinitions ( resourceName,mapDefinitions,last)
	resourceModels[resourceName] = {}
	startTickCount = getTickCount ()
	resource[resourceName] = {}
	

	Async:setPriority("high")
	Async:foreach(mapDefinitions, function(data)
			
		if not (data.default == 'true') then
			
			local modelID,new,exists = requestModelID(data.id,true)
			
			if new then
				resourceModels[resourceName][modelID] = true
			end
				
			if streamEverything or exists then
				
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
					if (data.alphaTransparency == 'true') then
						engineReplaceModel(model,modelID,true)
					else
						engineReplaceModel(model,modelID)
					end
					table.insert(resource[resourceName],modelCache)
				else
					print('Model : '..modelString..' could not be loaded!')
				end
				--print('Model : '..modelString..' loaded!')
			end
			
			
			if data.timeIn then
				print(data.timeIn)
				setModelStreamTime (modelID, tonumber(data.timeIn), tonumber(data.timeOut))
			end
			
			if (data.id == last) then
				loadedFunction (resourceName)
				prepLODs()
			end
		end
	end)
end

function prepLODs()
	Async:setPriority("medium")
	Async:foreach(getElementsByType("object"), function(object)

		local LOD = useLODs[getElementID(object)]
		if LOD then
			local x,y,z = getElementPosition (object)
			local xr,yr,zr = getElementRotation (object)
			local nObject = createObject (idCache[LOD],x,y,z,xr,yr,zr,true)
			local cull = isElementDoubleSided(object)
			local dimension = getElementDimension(object)
			local interior  = getElementInterior(object)
			
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


function changeObjectModel (object,newModel,streamNew)
	local id = getElementID(object)
	
	if id or streamNew then
		if idCache[newModel] then
			if id then
				print(id..'- Changed to : '..newModel)
			else
				print('New object streamed with ID: '..newModel)
			end
			setElementModel(object,idCache[newModel])
			setElementID(object,newModel)
			if getLowLODElement(object) then
				local LOD = getLowLODElement(object)
				if LOD then
					destroyElement(LOD) -- // Clear LOD if it exists
				end
				
				if useLODs[newModel] then -- // Create new LOD if this model has a LOD assigned to it
					local x,y,z,xr,yr,zr = getElementPosition (object),getElementRotation (object)
					local nObject = createObject (idCache[newModel],x,y,z,xr,yr,zr,true)
					local cull,dimension,interior = isElementDoubleSided(object),getElementDimension(object),getElementInterior(object)
					setElementDoubleSided(nObject,cull)
					setElementInterior(nObject,interior)
					setElementDimension(nObject,dimension)
					setElementID(nObject,newModel)
					setLowLODElement(object,nObject)
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
