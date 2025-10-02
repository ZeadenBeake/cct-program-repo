-- Chest Tools Daemon v1.0.0
-- Author: Zeaden Beake
package.path = package.path .. ";/lib/?.lua"
local scrollable = require("scrollable")
cfg = {}

configFile = fs.open("/cfg/chestTools.cfg", "r")
for key, value in string.gmatch(configFile.readAll(), "(.-)=(.-),") do
    cfg[key] = value
    --print(key, value)
end
configFile.close()
local monitor = peripheral.wrap(cfg.auditMonitor)
print("Using monitor " .. cfg.auditMonitor)

function search()
    chests = { peripheral.find("minecraft:chest") }
    contents = {}
    for _, chest in pairs(chests) do
        for slot, item in pairs(chest.list()) do
            if contents[item.name] then
                contents[item.name] = contents[item.name] + item.count
                print(item.count .. " more " .. item.name .. " found.")
            else
                contents[item.name] = item.count
                print("Added " .. item.count .. "x " .. item.name .. " to the list.")
            end
        end
    end
    lines = {}
    for name, count in pairs(contents) do
        lines[#lines + 1] = count .. "x " .. name .. "\n"
    end
    return lines
end

local passed, err = pcall(peripheral.getName, monitor)
if passed then print("Monitor is valid.") else error("Invalid monitor: " .. err) end

print("Starting monitor " .. peripheral.getName(monitor))
local file = fs.open("/lua/ct_daemon.txt", "w")
file.close()
parallel.waitForAny(
    function()
        while true do
            local lines = search()
            file = fs.open("/lua/ct_daemon.txt", "w")
            for i, line in pairs(lines) do
                file.write(line)
            end
            file.close()
            os.queueEvent("scroll_update", monitor)
            sleep(tonumber(cfg.auditRate))
        end
    end,
    function()
        print("Outputting to " .. peripheral.getName(monitor))
        scrollable.start(monitor, "/lua/ct_daemon.txt", 5, {file = true})
    end
)
