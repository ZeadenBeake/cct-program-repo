chests = { peripheral.find("minecraft:chest") }
monitor = peripheral.find("monitor")
yPos = 1
contents = {}
cfg = { target = "top", auditMonitor = "left", auditRate = 5 }

if fs.exists("/cfg/chestTools.cfg") then
    configFile = fs.open("/cfg/chestTools.cfg", "r")
    for key, value in string.gmatch(configFile.readAll(), "(.-)=(.-)\n") do
        cfg[key] = value
    end
    configFile.close()
else
    configFile = fs.open("/cfg/chestTools.cfg", "w")
    for key, value in pairs(cfg) do
        configFile.write(key .. "=" .. value .. "\n")
    end
    configFile.close()
end

-- Some functions
function math.clamp(n, low, high)
    if not (n and low and high) then
        error("Inputs cannot be nil.", 2)
    end
    return math.min(math.max(n, low), high)
end 

command, arg, set = ...

if command == "audit" then
    if not (term.isColor() and fs.exists("/lua/chestTools.daemon.lua")) then
        error("Audit is not supported on this device. Make sure that the computer is an Advanced computer, and that there is an advanced monitor connected. If the system is set up correctly, try reinstalling chestTools and trying again.", 0)
    end
    
    monitor.clear()
    monitor.setTextScale(0.5)
    monitor.setCursorBlink(false)
    
    shell.run("bg /lua/chestTools.daemon.lua")        
elseif command == "search" then
    for id, chest in pairs(chests) do
        for slot, item in pairs(chest.list()) do
            if item.name == arg then
                print(("%dx %s found in chest %s slot %d"):format(item.count, item.name, id, slot))
            end
        end
    end
elseif command == "config" then
    if cfg[arg] ~= nil then
        if set then
            cfg[arg] = set
            configFile = fs.open("/cfg/chestTools.cfg", "w")
            for key, value in pairs(cfg) do
                configFile.write(key .. "=" .. value .. "\n")
            end
            configFile.close()
        else
            print(cfg[arg])
        end
    else
        print("Invalid value.")
    end
elseif command == "fetch" then
    if not set then set = 64 end
    target = peripheral.wrap(cfg.target)
    fetched = false
    countFetched = 0
    countToFetch = set
    for slot, item in pairs(target.list()) do
        if item.name == arg then
            fetched = true
            fetchCount = math.clamp(countToFetch, 0, item.count)
            print(("%dx %s already found in target chest, skipping %d items."):format(item.count, item.name, fetchCount))
            countToFetch = countToFetch - fetchCount
            countFetched = countFetched + fetchCount
            if countToFetch == 0 then
                break
            end
        end
    end
    for id, chest in pairs(chests) do
        if countToFetch == 0 then
            break
        end
        if not (cfg.target == peripheral.getName(chest)) then
            for slot, item in pairs(chest.list()) do
                if item.name == arg then
                    fetched = true
                    fetchCount = math.clamp(countToFetch, 0, item.count)
                    print(("%dx %s found in chest %s slot %d, fetching %d."):format(item.count, item.name, id, slot, fetchCount))
                    countToFetch = countToFetch - fetchCount
                    countFetched = countFetched + fetchCount
                    target.pullItems(peripheral.getName(chest), slot, fetchCount)
                    if countToFetch == 0 then
                        break
                    end
                end
            end
        end
    end
    if not fetched then
        print("Could not find target item.")
    elseif countToFetch ~= 0 then
        print(("Partial fetch. Found %d out of %d items."):format(countFetched, set))
    else
        print("Fetched Successfully!")
    end
elseif command == "flush" then
    target = peripheral.wrap(cfg.target)
    for slot, item in pairs(target.list()) do
        for id, chest in pairs(chests) do
            if chest ~= cfg.target then
                target.pushItems(peripheral.getName(chest), slot)
                goto next
            end
        end
        ::next::
    end
elseif command == "info" then
    print("Version: 1.2.1")
    print("Version date: 2025-10-3")
    print("Author: Zeaden Beake")
else
    if command ~= nil then print("Invalid command specified.") end
    print("Commands:")
    print("info - Prints out some info about the software.")
    print("audit - Searches through all connected chests and returns everything it finds.")
    print("search - Looks for the specified item (mod:name, eg minecraft:raw_copper) and displays every chest it's found in, if any.")
    print("config - Sets a value in the configuration file. View /cfg/chestTools.cfg for configuration values.")
    print("fetch - Looks for the specified item (mod:name, see search) and fetches the specified number of items into a designated output chest. (Defined in chestTools.cfg)")
    print("flush - Empties the output chest into the storage system.")
end

