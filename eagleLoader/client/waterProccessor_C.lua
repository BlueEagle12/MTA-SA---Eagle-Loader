-- World limits
local WORLD_MIN = -3000
local WORLD_MAX = 3000
local Z_MIN = -1000
local Z_MAX = 1000
local debugWater = false

-- Water offsets
local shiftX, shiftY, shiftZ = 0, 0, 0

function clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

function parseWaterDat(filePath, resourceName)
    local waterData = {}

    local file = fileOpen(filePath)
    if not file then
        outputDebugString("parseWaterDat: failed to open “" .. tostring(filePath) .. "”", 1)
        return {}
    end

    local content = fileRead(file, fileGetSize(file))
    fileClose(file)

    local cLine = 0
    for line in content:gmatch("[^\r\n]+") do
        cLine = cLine + 1

        if line:match("^%s*#") or line:match("^%s*processed") or line:match("^%s*$") then
        else
            local nums = {}
            for num in line:gmatch("[-%d%.]+") do
                nums[#nums+1] = tonumber(num)
            end

            if #nums == 29 then
                local verts = {}
                for i = 1, 28, 7 do
                    local rawX, rawY, rawZ = nums[i], nums[i+1], nums[i+2]
                    local x = clamp(rawX + shiftX, WORLD_MIN, WORLD_MAX)
                    local y = clamp(rawY + shiftY, WORLD_MIN, WORLD_MAX)
                    local z = clamp(rawZ + shiftZ, Z_MIN, Z_MAX)
                    verts[#verts+1] = { x = x, y = y, z = z }
                end

                local wtype = nums[29]
                waterData[#waterData+1] = {
                    x1=verts[1].x; y1=verts[1].y; z1=verts[1].z;
                    x2=verts[2].x; y2=verts[2].y; z2=verts[2].z;
                    x3=verts[3].x; y3=verts[3].y; z3=verts[3].z;
                    x4=verts[4].x; y4=verts[4].y; z4=verts[4].z;
                    type = wtype,
                    name = ("water_line_%d"):format(cLine),
                }
            else
                outputDebugString(("parseWaterDat: skipping malformed line %d (got %d numbers)"):format(cLine, #nums), 2)
            end
        end
    end

    outputDebugString(("parseWaterDat: parsed %d water quads from %s"):format(#waterData, filePath))
    createWaterPlanes(waterData, resourceName)
    return waterData
end

radarAreas = {}

function createRadarFromWaterZone(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4,rName)
    local minX = math.min(x1, x2, x3, x4)
    local maxX = math.max(x1, x2, x3, x4)
    local minY = math.min(y1, y2, y3, y4)
    local maxY = math.max(y1, y2, y3, y4)

    local width = maxX - minX
    local height = maxY - minY

    local rArea = createRadarArea(minX, minY, width, height, math.random(0,255), math.random(0,255), math.random(0,255), 200)
    table.insert(radarAreas,{area = rArea,name = rName})
    return rArea
end

function isPlayerInRadarArea(area)
    local x, y = getElementPosition(localPlayer)
    local ax, ay = getElementPosition(area)
    local aw, ah = getRadarAreaSize(area)
    return x >= ax and x <= ax + aw and y >= ay and y <= ay + ah
end

addCommandHandler("currentZone", function()
    local zoneName = "Unknown"
    for _, info in ipairs(radarAreas) do
        if isPlayerInRadarArea(info.area) then
            zoneName = info.name
            break
        end
    end
    outputChatBox("You are in zone: " .. zoneName, 255, 255, 0)
end)

debugWaterLines = {}

function createWater2(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, name)
    local water = createWater(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4)

   -- local water1 = createWater(x1, y1, z1, x2, y2, z2, x3, y3, z3)

    -- Triangle B: x1,y1,z1 → x3,y3,z3 → x4,y4,z4
   -- local water2 = createWater(x1, y1, z1, x3, y3, z3, x4, y4, z4)

    if water then
        if debugWater then
            createRadarFromWaterZone(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, name)

            table.insert(debugWaterLines, {
                x1 = x1, y1 = y1, z1 = z1,
                x2 = x2, y2 = y2, z2 = z2,
                x3 = x3, y3 = y3, z3 = z3,
                x4 = x4, y4 = y4, z4 = z4,
                color = tocolor(255, 0, 0, 255)
            })
        end
    else
        outputDebugString("createWater: Failed to create water quad " .. name, 2)
    end
    return water
end


function createWaterPlanes(waterData, resourceName)
    resource = resource or {}
    resource[resourceName] = resource[resourceName] or {}

    for _, w in ipairs(waterData) do
        local water = createWater2(w.x1, w.y1, w.z1, w.x2, w.y2, w.z2, w.x3, w.y3, w.z3, w.x4, w.y4, w.z4, w.name)
        if water then
            table.insert(resource[resourceName], water)
        end
    end
end


if debugWater then
    function drawDebugWaterLines()
        for _, quad in ipairs(debugWaterLines) do
            local c = quad.color
            dxDrawLine3D(quad.x1, quad.y1, quad.z1, quad.x2, quad.y2, quad.z2, c,25)
            dxDrawLine3D(quad.x2, quad.y2, quad.z2, quad.x3, quad.y3, quad.z3, c,25)
            dxDrawLine3D(quad.x3, quad.y3, quad.z3, quad.x4, quad.y4, quad.z4, c,25)
            dxDrawLine3D(quad.x4, quad.y4, quad.z4, quad.x1, quad.y1, quad.z1, c)
        end
    end

    addEventHandler("onClientRender", root, drawDebugWaterLines)
end

