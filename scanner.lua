local geo = peripheral.find("geoScanner")
local pretty = require "cc.pretty"

geo.setFuelConsumptionRate(4)

local args = { ... }

while true do
    local foundList = {}
    local closest = 0
    local closestDist = math.huge
    local found = 0
    local scan = geo.scan(8)
    
    term.clear()
    term.setCursorPos(1, 1)
    for i, block in ipairs(scan) do
        local match = args[1] or "_ore"
        if string.match(block.name, match) then
            found = found + 1
            --print("Found " .. block.name .. "!")
            local dist = math.abs(block.x) + math.abs(block.y) + math.abs(block.z)
            if dist < closestDist then
                closest = i
                closestDist = dist
            end
            if not foundList[block.name] then
                foundList[block.name] = 1
            else
                foundList[block.name] = foundList[block.name] + 1
            end
        end
    end
    if found > 0 then
        for ore, count in pairs(foundList) do
            io.write("x" .. count .. " " .. ore .. "\n")
        end
        --print("Found " .. found .. " ores!")
        io.write("Closest is " .. closestDist .. " away!\n")
        local closeBlock = scan[closest]
        io.write("It's at " .. closeBlock.x .. ", " .. closeBlock.y .. ", " .. closeBlock.z .. "\n")
    else
        io.write("Nothing found...\n")
    end
    os.sleep((geo.getOperationCooldown("scanBlocks")+10) / 1000)
end
