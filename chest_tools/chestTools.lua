local chests = { peripheral.find("minecraft:chest") }
local monitor = peripheral.find("monitor")
local yPos = 1
contents = {}
local cfg = { 
    target = "top",
    auditMonitor = "left",
    auditRate = "5",
    fetchSearch = "false",
    authPassword = "admin",
    caching = "false",
    cacheServer = "any",
    clientName = "default",
    modem = "back",
    waitForServer = "true"
}
embed = false
local cache = {}

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

function getCache()
    if #cache > 0 then
        return cache
    else
        local server, message = {}
        rednet.send(cacheServer, {
            type = "request",
            source = "client:" .. cfg.clientName,
            msg = "cache"
        }, "ct-client")
        waiting = true
        while waiting do
            server, message = rednet.receive("ct-server", 5)
            if not server then
                error("Cache requested timed out.", 0)
            elseif server ~= cacheServer then
                error("Invalid response server! Verify your network security.", 0)
            end
            if message.msg ~= "Server is busy..." then
                waiting = false
            else
                print("Waiting for server...")
            end
        end
        return message.data
    end
end

cacheServer = 0
if stringtoboolean[cfg.caching] then
    rednet.open(cfg.modem)
    rednet.broadcast(
        {
            type = "ping",
            source = "client:" .. cfg.clientName
        },
        "ct-client"
    )
    server, message = rednet.receive("ct-server", 5)
    if not server then
        if stringtoboolean[cfg.waitForServer] then
            while not server do
                print("Waiting for server...")
                server, message = rednet.receive("ct-server", 15)
            end
        else
            print("Warning: Caching server not found.")
            print("Disable cache lookup?")
            io.write("> ")
            local option = io.read()
            if (string.lower(option) == "y") or (string.lower(option) == "yes") then
                cfg.caching = false
                print("Permanantly?")
                print("(Reversable in config file)")
                io.write("> ")
                local option = io.read()
                if (string.lower(option) == "y") or (string.lower(option) == "yes") then
                    configFile = fs.open("/cfg/chestTools.cfg", "w")
                    for key, value in pairs(cfg) do
                        configFile.write(key .. "=" .. tostring(value) .. "\n")
                    end
                    configFile.close()
                else
                    print("Disabling for this command only.")
                end
                goto cacheSkip
            else
                error("Failed to reach caching server.")
            end
            goto cacheSkip
        end
    end
    if (message.source == "server:" .. cfg.cacheServer) or (cfg.cacheServer == "any")  then
        cacheServer = server
    end
end

::cacheSkip::

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
    if stringtoboolean[cfg.caching] then
        items = getCache()
        for name, stacks in pairs(items) do
            if string.match(name, args[2]) then
                for _, stack in pairs(stacks) do
                    if results[name] then
                        results[name] = results[name] + stack[1]
                    else
                        results[name] = stack[1]
                    end
                end
            end
        end
    else
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
    end
    print("Items found:")
    for item, count in pairs(results) do
        print(count .. "x " .. item)
    end
elseif args[1] == "config" then
    if cfg[args[2]] ~= nil then
        if args[3] then
            cfg[args[2]] = args[3]
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
    if not stringtoboolean[cfg.caching] then
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
    else
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
    end
    print("Fetching from " .. #chests .. " chests...")
    if stringtoboolean[cfg.caching] then
        items = getCache()
        exact = true
        if args[4] == "exact" then
            exact = true
        elseif args[4] == "search" then
            exact = false
        else
            exact = not stringtoboolean[cfg.fetchSearch]
        end
        if exact then
            match = (items[args[2]])
            if match then
                for index, stack in pairs(items[args[2]]) do
                    fetched = true
                    fetchCount = math.clamp(countToFetch, 0, item.count)
                    print(("%dx %s found in chest %s slot %d, fetching %d."):format(item.count, item.name, id, slot, fetchCount))
                    countToFetch = countToFetch - fetchCount
                    countFetched = countFetched + fetchCount
                    target.pullItems(peripheral.getName(chest), slot, fetchCount)
                end
            end
        else
            for item, stack in pairs(items) do
                if string.match(item.name, args[2]) ~= nil then
                    fetched = true
                    fetchCount = math.clamp(countToFetch, 0, item.count)
                    print(("%dx %s found in chest %s slot %d, fetching %d."):format(item.count, item.name, id, slot, fetchCount))
                    countToFetch = countToFetch - fetchCount
                    countFetched = countFetched + fetchCount
                    target.pullItems(peripheral.getName(chest), slot, fetchCount)
                end
            end
        end
        
    else
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
