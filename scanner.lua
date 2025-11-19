-- This is a scanner program that looks for ores around the computer.
-- This program is made for a pocket computer with a AP GeoScanner equpped.

local geo = peripheral.find("geoScanner")
local pretty = require "cc.pretty"

geo.setFuelConsumptionRate(4)

local args = { ... }

while true do
    local closest = 0
    local closestDist = math.huge
    local found = 0
    local scan = geo.scan(8)
    for i, block in ipairs(scan) do
        local match = args[1] or "ore"
        if string.match(block.name, match) then
            found = found + 1
            print("Found " .. block.name .. "!")
            local dist = math.abs(block.x) + math.abs(block.y) + math.abs(block.z)
            if dist < closestDist then
                closest = i
                closestDist = dist
            end
        end
    end
    if found > 0 then
        print("Found " .. found .. " ores!")
        print("Closest is " .. closestDist .. " away!")
        local closeBlock = scan[closest]
        print("It's at ", closeBlock.x, closeBlock.y, closeBlock.z)
    else
        print("Nothing found...")
    end
    print("Cooling down...")
    os.sleep((geo.getOperationCooldown("scanBlocks")+10) / 1000)
end
