
function streamMapElements(resourceName, elementList)
	local objects = {}
	
    for _, element in ipairs(elementList) do

		if lodIDList[element.id] and highDefLODs then
			
		else
			if element.type == "building" then
				local nElement = streamBuilding(element.id,element.posX,element.posY,element.posZ,element.rotX,element.rotY,element.rotZ,element.interior,element.lodParent,element.uniqueID,true)
				if nElement then
					table.insert(objects,nElement)
				end
			else
				local nElement = streamObject(element.id,element.posX,element.posY,element.posZ,element.rotX,element.rotY,element.rotZ,element.interior,element.lodParent,element.uniqueID,true)
				if nElement then
					table.insert(objects,nElement)
				end
			end
		end
    end

    return objects
end