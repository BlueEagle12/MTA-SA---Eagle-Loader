
debugLines = {}
function outputDebugString2(string,a)
    outputDebugString(string,a)

    table.insert(debugLines,string)
end



function writeDebugFile()
    -- Create (or overwrite) the meta.xml file in your resource
    local f = fileCreate('debug.txt')


    for i, entry in pairs(debugLines) do
        fileWrite(f, entry.."\n")
    end

    fileClose(f)

    outputDebugString("Wrote debug to: " .. 'debug.txt')
    return true
end