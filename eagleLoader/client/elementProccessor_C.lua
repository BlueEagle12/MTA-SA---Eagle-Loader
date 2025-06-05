function streamMapElements(resourceName, elementList)
    local objects = {}

    if not modelCrashDebug then
        for _, element in ipairs(elementList or {}) do
            -- Skip LODs if highDefLODs and present in lodIDList
            if not (lodIDList[element.id] and highDefLODs) then
                local streamFunc = element.type == "building" and streamBuilding or streamObject
                local nElement = streamFunc(
                    element.id,
                    element.posX, element.posY, element.posZ,
                    element.rotX, element.rotY, element.rotZ,
                    element.interior, element.lodParent, element.uniqueID, true
                )
                if nElement then
                    table.insert(objects, nElement)
                end
            end
        end
    end

    return objects
end
