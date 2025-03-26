
-- // Load the defintion, and placement files we outputted from blender.
saIDList = {}
currentSAIndex = 0

function getLines(file)
	local fData = fileRead(file, fileGetSize(file))
	if not fData then
		print(file)
	end
	
	local fProccessed = split(fData,10) -- Split the lines
	fileClose (file)
	return fProccessed
end

idList = getLines(fileOpen('client/validID/sa_id_list.ID'))

for i,v in pairs(idList) do
	local strings = split(v,',')
	table.insert(saIDList,strings[1])
end


function engineRequestSAModel()
	local model = saIDList[currentSAIndex]
	
	currentSAIndex = currentSAIndex + 1
	
	return model
end