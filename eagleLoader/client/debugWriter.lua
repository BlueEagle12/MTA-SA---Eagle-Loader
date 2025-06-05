local debugLines = {}

function outputDebugString2(str, level)
    outputDebugString(str, level)
    table.insert(debugLines, str)
end

function writeDebugFile()
    if not debugLines or #debugLines == 0 then
        outputDebugString("No debug lines to write.", 3)
        return false
    end

    local f = fileCreate('debug.txt')
    if not f then
        outputDebugString("Failed to create debug.txt!", 1)
        return false
    end

    for _, entry in ipairs(debugLines) do
        fileWrite(f, entry .. "\n")
    end

    fileClose(f)
    outputDebugString("Wrote debug to: debug.txt")
    return true
end
