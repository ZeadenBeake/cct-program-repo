chests = { peripheral.find("minecraft:chest") }
monitor = peripheral.find("monitor")
yPos = 1
contents = {}
cfg = { target = "top", auditMonitor = "left", auditRate = "5", fetchSearch = "false", authPassword="admin", caching=false, cacheServer="" }
embed = false

os.pullEvent = os.pullEventRaw

::loop::

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
stringtoboolean={ ["true"] = true, ["false"] = false}
function auth(passwd)
    if (passwd == cfg.authPassword) or cfg.authPassword == "" then
        return true
    else
        return false
    end
end

args = { }
--command, arg, set = ...
if embed then
    io.write("> ")
    usrIn = string.gmatch(io.read(), "[^%s]+")
    i = 1
    for arg in usrIn do
        args[i] = arg
        i = i + 1
    end 
else
    args = { ... }
end

if args[1] == "audit" then
    if not (term.isColor() and fs.exists("/lua/chestTools.daemon.lua")) then
        error("Audit is not supported on this device. Make sure that the computer is an Advanced computer, and that there is an advanced monitor connected. If the system is set up correctly, try reinstalling chestTools and trying again.", 0)
    end
    
    monitor.clear()
    monitor.setTextScale(0.5)
    monitor.setCursorBlink(false)
    
    shell.run("bg /lua/chestTools.daemon.lua")        
elseif args[1] == "search" then
    results = {}
    for id, chest in pairs(chests) do
        for slot, item in pairs(chest.list()) do
            if string.match(item.name, args[2]) then
                --print(("%dx %s found in chest %s slot %d"):format(item.count, item.name, id, slot))
                if results[item.name] then
                    results[item.name] = results[item.name] + item.count
                else
                    results[item.name] = item.count
                end
            end
        end
    end
    print("Items found:")
    for item, count in pairs(results) do
        print(count .. "x " .. item)
    end
elseif args[1] == "config" then
    if cfg[args[2]] ~= nil then
        if set then
            cfg[args[2]] = set
            configFile = fs.open("/cfg/chestTools.cfg", "w")
            for key, value in pairs(cfg) do
                configFile.write(key .. "=" .. value .. "\n")
            end
            configFile.close()
        else
            print(cfg[args[2]])
        end
    else
        print("Invalid value.")
    end
elseif args[1] == "fetch" then
    if (not args[3]) or args[3] == "." then args[3] = 64 end
    target = peripheral.wrap(cfg.target)
    fetched = false
    countFetched = 0
    countToFetch = args[3]
    for slot, item in pairs(target.list()) do
        exact = true
        if args[4] == "exact" then
            exact = true
        elseif args[4] == "search" then
            exact = false
        else
            exact = not stringtoboolean[cfg.fetchSearch]
        end
        match = false
        if exact then
            match = (item.name == args[2])
        else
            match = (string.match(item.name, args[2]) ~= nil)
        end
        if match then
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
    print("Fetching from " .. #chests .. " chests...")
    for id, chest in pairs(chests) do
        if countToFetch == 0 then
            break
        end
        if cfg.target ~= peripheral.getName(chest) then
            for slot, item in pairs(chest.list()) do
                exact = true
                if args[4] == "exact" then
                    exact = true
                elseif args[4] == "search" then
                    exact = false
                else
                    exact = not stringtoboolean[cfg.fetchSearch]
                end
                match = false
                if exact then
                    match = (item.name == args[2])
                else
                    match = (string.match(item.name, args[2]) ~= nil)
                end
                if match then
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
        print(("Partial fetch. Found %d out of %d items."):format(countFetched, args[3]))
    else
        print("Fetched Successfully!")
    end
elseif args[1] == "flush" then
    target = peripheral.wrap(cfg.target)
    for slot, item in pairs(target.list()) do
        for id, chest in pairs(chests) do
            if chest ~= cfg.target then
                num = target.pushItems(peripheral.getName(chest), slot)
                if num == item.count then
                    goto next
                else
                    goto retry
                end
            end
            ::retry::
        end
        ::next::
    end
elseif args[1] == "info" then
    print("Version: 1.3.0")
    print("Version date: 2025-10-3")
    print("Author: Zeaden Beake")
elseif args[1] == "embed" then
    if args[2] == "start" then
        embed = true
    elseif args[2] == "exit" then
        if auth(args[3]) then
            embed = false
        else
            print("Failed to authenticate.")
        end
    end
else
    if args[1] ~= nil then print("Invalid command specified.") end
    print("Commands:")
    print("info - Prints out some info about the software.")
    print("audit - Searches through all connected chests and returns everything it finds.")
    print("search - Looks for the specified item (mod:name, eg minecraft:raw_copper) and displays every chest it's found in, if any.")
    print("config - Sets a value in the configuration file. View /cfg/chestTools.cfg for configuration values.")
    print("fetch - Looks for the specified item (mod:name, see search) and fetches the specified number of items into a designated output chest. (Defined in chestTools.cfg)")
    print("flush - Empties the output chest into the storage system.")
end

if embed then
    goto loop
end
