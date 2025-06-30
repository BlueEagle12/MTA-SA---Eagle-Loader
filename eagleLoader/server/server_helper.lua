-- =========================
-- Player Load Event Handler
-- =========================

function playerLoaded(loadTime, resource)
    local seconds = tonumber(loadTime) / 1000
    print(getPlayerName(client), 'Loaded ' .. tostring(resource) .. ' In: ' .. string.format('%.2f', seconds) .. ' Seconds')
end
addEvent("onPlayerLoad", true)
addEventHandler("onPlayerLoad", resourceRoot, playerLoaded)

-- =========================
-- Resource Stop Handler
-- =========================

function onResourceStop(stoppedResource)
    -- Trigger the client event on resource stop ONLY when it stops on the server side
    if getResourceName(stoppedResource) ~= getResourceName(getThisResource()) then
        local rName = getResourceName(stoppedResource)
        triggerClientEvent(root, "resourceStop", root, rName)
    end
end
addEventHandler("onResourceStop", root, onResourceStop)

-- =========================
-- Streamed Element Creators
-- =========================

function streamObject(id, x, y, z, xr, yr, zr, interior, lod)
    x, y, z = tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0
    xr, yr, zr = tonumber(xr) or 0, tonumber(yr) or 0, tonumber(zr) or 0
    local obj = createObject(1337, x, y, z, xr, yr, zr)
    setElementID(obj, id)
    return obj
end

function streamBuilding(id, x, y, z, xr, yr, zr, interior, lod)
    x, y, z = tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0
    xr, yr, zr = tonumber(xr) or 0, tonumber(yr) or 0, tonumber(zr) or 0
    local build = createBuilding(1337, x, y, z, xr, yr, zr, interior)
    setElementID(build, id)
    return build
end

function setElementStream(object, newModel)
    triggerClientEvent(resourceRoot, "setElementStream", root, object, newModel)
end
