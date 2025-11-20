-- This is a simple block scanner, which finds nearby blocks and shows them om the display.
-- Additionally, it shows the closest matching block's name, distance and relative position.
-- By default this is configured to search for ores.

local geo = peripheral.find("geoScanner")
local pretty = require "cc.pretty"

geo.setFuelConsumptionRate(4)

local args = { ... }

local x, y = term.getSize()

while true do
    local foundList = {}
    local closest = 0
    local closestDist = math.huge
    local found = 0
    local scan = geo.scan(8)
    if scan then
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
        term.clear()
        term.setCursorPos(1, y-3)
        io.write(string.rep("-", x))
        if found > 0 then
            local closeBlock = scan[closest]
            term.setCursorPos(1, 1)
            for ore, count in pairs(foundList) do
                io.write("x" .. count .. " " .. ore .. "\n")
            end
            --print("Found " .. found .. " ores!")
            term.setCursorPos(1, y-2)
            io.write(closeBlock.name)
            term.setCursorPos(1, y-1)
            io.write("is " .. closestDist .. " blocks away!")
            term.setCursorPos(1, y)
            io.write("It's at " .. closeBlock.x .. ", " .. closeBlock.y .. ", " .. closeBlock.z)
        else
            term.setCursorPos(6, y-1)
            io.write("Nothing found...")
        end
        os.sleep((geo.getOperationCooldown("scanBlocks")+10) / 1000)
    end
end
