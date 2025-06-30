-- =========================
-- Crash Finder
-- =========================

if modelCrashDebug then
    LOG_FILE  = "spawned_objects.log"
    SKIP_FILE = "skip_objects.log"

    if fileExists(LOG_FILE) then
        LOG_FILE_HANDLE = fileOpen(LOG_FILE)
    else
        LOG_FILE_HANDLE = fileCreate(LOG_FILE)
    end

    if fileExists(SKIP_FILE) then
        SKIP_FILE_HANDLE = fileOpen(SKIP_FILE)
    end
end
local loggedIds   = {}
local skippedIds  = {}
local spawnedObjects = {}
local lastSpawned = nil

-- Load previously logged IDs
local function loadLoggedIds()
    if LOG_FILE_HANDLE then
        local content = fileRead(LOG_FILE_HANDLE, fileGetSize(LOG_FILE_HANDLE))
        for id in string.gmatch(content, "[^\r\n]+") do
            loggedIds[id] = true
        end
    end
end

local function loadSkippedIds()
    if SKIP_FILE_HANDLE then
        local content = fileRead(SKIP_FILE_HANDLE, fileGetSize(SKIP_FILE_HANDLE))
        for id in string.gmatch(content, "[^\r\n]+") do
            skippedIds[id] = true
        end
    end
end

local function appendLoggedId(id)
    fileSetPos(LOG_FILE_HANDLE, fileGetSize(LOG_FILE_HANDLE))
    fileWrite(LOG_FILE_HANDLE, tostring(id) .. "\n")
    loggedIds[tostring(id)] = true
end

loadLoggedIds()
loadSkippedIds()

objectsToSpawn = {}
objList = {}

function addToSpawnList(id)
    if id and not objList[id] then
        objList[id] = true
        table.insert(objectsToSpawn, {id = id, x = 0, y = 0, z = 10})
    end
end

-- Main crash-finding spawn loop
function spawnNextObject()
    if not modelCrashDebug then return end

    movePlayer()
    crashIndex = crashIndex + 1
    if crashIndex > #objectsToSpawn then
        outputChatBox("Finished spawning all objects.")
        return
    end

    local data = objectsToSpawn[crashIndex]

    -- Skip already logged/skipped
    if loggedIds[tostring(data.id)] or skippedIds[tostring(data.id)] then
        spawnNextObject()
        return
    end

    local model = idCache[data.id]
    if tonumber(model) then
        outputChatBox("Trying to spawn object ID " .. data.id .. " at index " .. crashIndex .. '/' .. #objectsToSpawn)
        if lastSpawned then appendLoggedId(lastSpawned) end

        spawnedObjects[model] = createObject(model, 0, 0, 0)
        setElementID(spawnedObjects[model], data.id)

        addEventHandler("onClientElementStreamIn", spawnedObjects[model],
            function()
                lastSpawned = data.id
                setTimer(function()
                    outputChatBox("Spawned object ID " .. data.id .. " at index " .. crashIndex .. '/' .. #objectsToSpawn)
                    if despawnDebug then destroyElement(spawnedObjects[model]) end
                    spawnedObjects[model] = nil
                    spawnNextObject()
                end, modelCrashDebugRate, 1)
            end
        )
    else
        if lastSpawned then
            appendLoggedId(lastSpawned)
            lastSpawned = nil
        end
        outputChatBox("Skipping Object " .. data.id)
        setTimer(spawnNextObject, modelCrashDebugRate, 1)
    end
end

-- Repeatedly move the player (for streaming tests)
local playerMoved = false
function movePlayer()
    if not playerMoved then
        addEventHandler("onClientRender", root, function()
            setElementPosition(localPlayer, 0, 0, 0)
        end)
        playerMoved = true
    end
end

-- Global streaming debug print
addEventHandler("onClientElementStreamIn", root,
    function()
        if getElementType(source) == "object" or getElementType(source) == "building" then
            local model = getElementModel(source)
            if streamDebug then
                print(string.format("Building streamed in: ID %s, Element ID %s", model, getElementID(source) or ''))
            end
        end
    end
)

-- =========================
-- Debug File Handling
-- =========================

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
