-- // Load the definition and placement files outputted from Blender.
saIDList = {}
defaultIDs = {}
currentSAIndex = 0

function getLines(file)
    local fData = fileRead(file, fileGetSize(file))
    
    if not fData then
        print("Error: Unable to read file - " .. file)
        return {}
    end

    local fProcessed = split(fData, 10)
    fileClose(file)
    return fProcessed
end

local idList = getLines(fileOpen("client/validID/sa_id_list.ID"))
local fullidList = getLines(fileOpen("client/validID/sa_full_id_list.ID"))


for _, v in ipairs(idList) do
    local strings = split(v, ",")
    if strings[1] then
        table.insert(saIDList, strings[1])
    end
end

-- Use the full ID list to account for special objects that we normally would not use
for _, v in ipairs(fullidList) do
    local strings = split(v, ",")
    if strings[1] then
		local name = strings[2]
		defaultIDs[name:gsub("%s+", "")] = tonumber(strings[1])
    end
end


function engineRequestSAModel()
    if currentSAIndex >= #saIDList then
        return false
    end

    local model = saIDList[currentSAIndex]
    currentSAIndex = currentSAIndex + 1
    return model
end
