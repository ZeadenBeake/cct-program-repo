chests = { peripheral.find("minecraft:chest") }
monitor = peripheral.find("monitor")
yPos = 1
contents = {}
cfg = { target = peripheral.wrap("top") }

if fs.exists("/cfg/chestTools.cfg") then
    configFile = fs.open("/cfg/chestTools.cfg", "r")
    for key, value in string.gmatch(configFile.readAll(), "(%w+)=(%w+)") do
        cfg[key] = peripheral.wrap(value)
    end
    configFile.close()
else
    configFile = fs.open("/cfg/chestTools.cfg", "w")
    for key, value in pairs(cfg) do
        configFile.write(key .. "=" .. perihperal.getName(value))
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
    monitor.clear()
    monitor.setTextScale(0.5)
    monitor.setCursorBlink(false)
    for _, chest in pairs(chests) do
        for slot, item in pairs(chest.list()) do
            if contents[item.name] then
                contents[item.name] = contents[item.name] + item.count
            else
                contents[item.name] = item.count
            end
        end
    end
    
    for name, count in pairs(contents) do
        monitor.setCursorPos(1, yPos)
        monitor.write(("%dx %s"):format(count, name))
        yPos = yPos + 1
    end
elseif command == "search" then
    for id, chest in pairs(chests) do
        for slot, item in pairs(chest.list()) do
            if item.name == arg then
                print(("%dx %s found in chest %s slot %d"):format(item.count, item.name, id, slot))
            end
        end
    end
elseif command == "config" then
    if arg == "target" then
        if set then
            cfg.target = peripheral.wrap(set)
            configFile = fs.open("/cfg/chestTools.cfg", "w")
            for key, value in pairs(cfg) do
                configFile.write(key .. "=" .. set)
            end
            configFile.close()
        else
            print(peripheral.getName(cfg.target))
        end
    else
        print("Invalid value.")
    end
elseif command == "fetch" then
    fetched = false
    countFetched = 0
    countToFetch = set
    for id, chest in pairs(chests) do
        for slot, item in pairs(chest.list()) do
            if item.name == arg then
                fetched = true
                fetchCount = math.clamp(countToFetch, 0, item.count)
                print(("%dx %s found in chest %s slot %d, fetching %d."):format(item.count, item.name, id, slot, fetchCount))
                countToFetch = countToFetch - fetchCount
                countFetched = countFetched + fetchCount
                cfg.target.pullItems(peripheral.getName(chest), slot, fetchCount)
                if countToFetch == 0 then
                    break
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
    target = cfg.target
    for slot, item in pairs(target.list()) do
        for id, chest in pairs(chests) do
            if chest ~= target then
                target.pushItems(peripheral.getName(chest), slot)
            end
        end
    end
else
    print("Invalid command specified.")
    print("Commands:")
    print("audit - Searches through all connected chests and returns everything it finds.")
    print("search - Looks for the specified item (mod:name, eg minecraft:raw_copper) and displays every chest it's found in, if any.")
    print("config - Sets a value in the configuration file. View /cfg/chestTools.cfg for configuration values.")
    print("fetch - Looks for the specified item (mod:name, see search) and fetches the specified number of items into a designated output chest. (Defined in chestTools.cfg)")
    print("flush - Empties the output chest into the storage system.")
end  
