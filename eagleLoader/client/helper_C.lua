function isStringTrue (str)
	return (str == 'true')
end


onScreen = {}


function onElementStreamIn()
    if getElementType(source) == "object" then
        outputChatBox("Object streamed in: "..getElementID(source))
    end
end
addEventHandler("onClientElementStreamIn", root, onElementStreamIn)

function onElementStreamOut()
    if getElementType(source) == "object" then
        outputChatBox("Object streamed out: "..getElementID(source))
		print("Object streamed out: "..getElementID(source))
    end
end
addEventHandler("onClientElementStreamOut", root, onElementStreamOut)