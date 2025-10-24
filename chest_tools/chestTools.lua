local chests = { peripheral.find("minecraft:chest") }
local monitor = peripheral.find("monitor")
local yPos = 1
local contents = {}
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
    waitForServer = "false",
    firstStart = "true"
}
local embed = false
local cache = {}
local spinner = {"|", "/", "-", "\\"}
local ticker = 0

local pretty = require "cc.pretty"

os.pullEvent = os.pullEventRaw

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

function doSpinner(text, delay)
    if not delay then delay = 0.5 end
    while true do
        local posx, posy = term.getCursorPos()
        term.blit(text .. spinner[math.fmod(ticker, 4) + 1], "eeeeeeeeeeeeeeeeeeeeeee", "fffffffffffffffffffffff")
        ticker = ticker + 1
        term.setCursorPos(posx, posy)
        coroutine.yield()
    end
    return true
end

function getCache(force)
    if (#cache > 0) and not force then
        return cache
    else
        local server, message = {}
        rednet.send(cacheServer, {
            type = "request",
            source = "client:" .. cfg.clientName,
            msg = "cache"
        }, "ct-client")
        local waiting = true
        parallel.waitForAny(
            function()
                while true do
                    local posx, posy = term.getCursorPos()
                    term.blit("Waiting for server... ".. spinner[math.fmod(ticker, 4) + 1], "eeeeeeeeeeeeeeeeeeeeeee", "fffffffffffffffffffffff")
                    ticker = ticker + 1
                    term.setCursorPos(posx, posy)
                    os.sleep(0.5)
                end
            end,
            function()
                while waiting do
                    server, message = rednet.receive("ct-server", 5)
                    if not server then
                        error("Cache requested timed out.", 0)
                    elseif server ~= cacheServer then
                        error("Invalid response server! Verify your network security.", 0)
                    end
                    if message.msg ~= "Server is busy..." then
                        waiting = false
                        term.clearLine()
                    else
                        -- nada
                    end
                end
            end
        )
        --[[
        while waiting do
            server, message = rednet.receive("ct-server", 5)
            if not server then
                error("Cache requested timed out.", 0)
            elseif server ~= cacheServer then
                error("Invalid response server! Verify your network security.", 0)
            end
            if message.msg ~= "Server is busy..." then
                waiting = false
                os.queueEvent("spinner", false)
                term.clearLine()
            else
                coroutine.resume(spin)
            end
        end
        -]]
        return message.data
    end
end

function updateCache()
    if #cache == 0 then
        return false, "Cache is empty!"
    end
    rednet.send(server, {
        type = "submit",
        source = "client:" .. cfg.clientName,
        msg = "cache",
        data = cache
    }, "ct-client")
    print("Waiting for reply...")
    local replySrv, reply = rednet.receive("ct-server", 5)
    if reply == "Update recieved." then
        return true
    else
        return reply.msg
    end
end

local function panic(reason)
    rednet.send(server, {
        type = "panic",
        source = "client:" .. cfg.clientName,
        msg = reason
    }, "ct-client")
    print("Something has broken horribly and the server is panicking! Let a ct-server administrator know immedietly, and tell them the error code displayed!")
    replySrv, reply = rednet.receive("ct-server", 5)
    print("Try the command again- the server will be back online soon!")
    error(reason, 2)
end

::cacheRetry::

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
            repeat
                io.write("Waiting for server... " .. spinner[math.fmod(ticker, 4) + 1])
                ticker = ticker + 1
                server, message = rednet.receive("ct-server", 0.5)
            until server
            --[[
            while not server do
                print("Waiting for server...")
                server, message = rednet.receive("ct-server", 15)
            end
            --]]
        else
            term.blit("Warning: Caching server not found.", "4444444444444444444444444444444444", "ffffffffffffffffffffffffffffffffff")
            print()
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
        repeat
            rednet.send(server, {
                type = "submit",
                source = "client:" .. cfg.clientName,
                msg = "register",
                data = cfg.target
            }, "ct-client")
            replySrv, reply = rednet.receive("ct-server", 5)
            if not replySrv then print("Waiting for reply...") end
        until(replySrv == cacheServer)
        cache = getCache()
    else
        goto cacheRetry
    end
end

::cacheSkip::

::loop::

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

if cfg["firstStart"] == "true" then
    print("Welcome to chestTools! The system has been installed, but not yet configured.")
    print("If there is a chestTools server ready for use, then enable \"caching\" in the configuration file. Otherwise, leave it false.")
    print("Edit the configuration at /cfg/chestTools.cfg to set up the I/O chest, set the admin password, change the client name (do not leave it default if using caching!), and other configuration options.")
    print("Thank you for using chestTools!")
    term.setCursorBlink(false)
    io.write("Press return to dismiss this message.")
    io.read()
    cfg["firstStart"] = "false"
    configFile = fs.open("/cfg/chestTools.cfg", "w")
    for key, value in pairs(cfg) do
        configFile.write(key .. "=" .. value .. "\n")
    end
    configFile.close()
    goto skip
end

if args[1] == "audit" then
    if not (term.isColor() and fs.exists("/lua/chestTools.daemon.lua") and peripheral.wrap(auditMonitor)) then
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
    countToFetch = tonumber(args[3])
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
            match = ((string.match(item.name, args[2]) ~= nil) and (string.match(item.name, "internal:") == nil))
        end
        if match then
            fetched = true
            local fetchCount = math.clamp(countToFetch, 0, item.count)
            print(("%dx %s already found in target chest, skipping %d items."):format(item.count, item.name, fetchCount))
            countToFetch = countToFetch - fetchCount
            countFetched = countFetched + fetchCount
            if countToFetch == 0 then
                break
            end
        end
    end
    local diff = false
    if countToFetch > 0 then
        diff = true
        print("Fetching from " .. #chests - 1 .. " chests...")
        if stringtoboolean[cfg.caching] then
            local exact = true
            if args[4] == "exact" then
                exact = true
            elseif args[4] == "search" then
                exact = false
            else
                exact = not stringtoboolean[cfg.fetchSearch]
            end
            if exact then
                if cache[args[2]] then
                    print("Found!")
                    stacks = cache[args[2]]
                    name = args[2]
                    repeat
                        stack = stacks[1]
                        local width, height = term.getCursorPos()
                        fetched = true
                        local sourceChest = peripheral.wrap(stack[2])
                        local fetchCount = math.clamp(countToFetch, 0, stack[1])
                        print(("%dx %s found in %s slot %d, fetching %d."):format(stack[1], name, stack[2], stack[3], fetchCount))
                        countToFetch = countToFetch - fetchCount
                        countFetched = countFetched + fetchCount
                        local moved = target.pullItems(stack[2], tonumber(stack[3]), fetchCount)
                        if moved ~= fetchCount then
                            term.blit("Something's wrong! Providing info...", "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "ffffffffffffffffffffffffffffffffffff")
                            print()
                            print("slot contents: " .. (sourceChest.getItemDetail(tonumber(stack[3])) or "nothing"))
                            print("chest: " .. stack[2])
                            panic("Invalid Fetch!")
                        end
                        cache[name][1][1] = tonumber(stack[1]) - countFetched
                        if cache[name][1][1] <= 0 then
                            table.remove(cache[name], 1)
                            local info = { 0, stack[2], stack[3] }
                            table.insert(cache["internal:empty"], info)
                        end
                    until (countToFetch == 0) or (#stacks == 0)
                end
            else
                --]]
                for name, stacks in pairs(cache) do
                    match = ((string.match(name, args[2]) ~= nil) and (string.match(name, "internal:") == nil))
                    if match then
                        repeat
                            stack = stacks[1]
                            local width, height = term.getCursorPos()
                            fetched = true
                            local sourceChest = peripheral.wrap(stack[2])
                            local fetchCount = math.clamp(countToFetch, 0, stack[1])
                            print(("%dx %s found in %s slot %d, fetching %d."):format(stack[1], name, stack[2], stack[3], fetchCount))
                            countToFetch = countToFetch - fetchCount
                            countFetched = countFetched + fetchCount
                            local moved = target.pullItems(stack[2], tonumber(stack[3]), fetchCount)
                            if moved ~= fetchCount then
                                term.blit("Something's wrong! Providing info...", "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "ffffffffffffffffffffffffffffffffffff")
                                print()
                                print("slot contents: " .. (sourceChest.getItemDetail(tonumber(stack[3])) or "nothing"))
                                print("chest: " .. stack[2])
                                panic("Invalid Fetch!")
                            end
                            cache[name][1][1] = tonumber(stack[1]) - countFetched
                            if cache[name][1][1] <= 0 then
                                table.remove(cache[name], 1)
                                local info = { 0, stack[2], stack[3] }
                                table.insert(cache["internal:empty"], info)
                            end
                        until (countToFetch == 0) or (#stacks == 0)
                        if countToFetch <= 0 then break end
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
    end
    if not fetched then
        print("Could not find target item.")
    elseif countToFetch ~= 0 then
        print(("Partial fetch. Found %d out of %d items."):format(countFetched, args[3]))
    else
        print("Fetched Successfully!")
    end
    if fetched and diff and cfg.caching then
        rednet.send(server, {
            type = "submit",
            source = "client:" .. cfg.clientName,
            msg = "cache",
            data = cache
        }, "ct-client")
        print("Updating server's cache...")
        replySrv, reply = rednet.receive("ct-server", 5)
    end
elseif args[1] == "flush" then
    target = peripheral.wrap(cfg.target)
    if cfg.caching then
        local diff = false
        for slot, item in pairs(target.list()) do
            local stacks = cache[item.name]
            print("Flushing ", item.count, item.name)
            -- First, check if there are any partial stacks we can try to fill.
            local move = item.count
            if stacks then
                --print("Item exists!", #stacks)
                for i, stack in ipairs(stacks) do
                    --print("Stack count:", stack[1])
                    if tonumber(stack[1]) < 64 then
                        local moved = target.pushItems(stack[2], slot, item.count, tonumber(stack[3]))
                        if moved == 0 then
                            print("Move failed, that slot has " .. (peripheral.wrap(stack[2]).getItemDetail(tonumber(stack[3])).count or 0) .. " of " .. (peripheral.wrap(stack[2]).getItemDetail(tonumber(stack[3])).name or "nothing") .. " but it's supposed to have " .. cache[item.name][i][1] .. " " .. item.name .. "!")
                            panic("Invalid Flush!")
                        end
                        move = move - moved
                        cache[item.name][i][1] = cache[item.name][i][1] + moved
                        stacks = cache[item.name]
                    end
                    if move == 0 then break end
                end
            end
            -- If move is still positive, then we couldn't move the whole stack. Put the remainder in an empty slot.
            if move > 0 then
                local empties = cache["internal:empty"]
                if (not empties) or (not empties[1]) then -- We've run out of empty space in the entire system!!!
                    print("Out of storage! Aborting flush!")
                    break
                end
                local destination = peripheral.wrap(empties[1][2])
                --print("Trying slot ", tonumber(empties[1][3]), " in ", peripheral.getName(destination))
                if destination.getItemDetail(tonumber(empties[1][3])) then
                    print("That slot has ", destination.getItemDetail(tonumber(empties[1][3])).count, " of ", destination.getItemDetail(tonumber(empties[1][3])).name, "! This slot is supposed to be empty- panicking!")
                    panic("Invalid Flush!")
                end
                local moved = target.pushItems(peripheral.getName(destination), slot, item.count, tonumber(empties[1][3])) -- Move the item...
                -- ...then generate a new cache entry for th filled slot...
                local info = {moved, empties[1][2], empties[1][3]}
                if not cache[item.name] then cache[item.name] = {} end
                table.insert(cache[item.name], info)
                -- ...and finally clear the no-longer empty slot from internal:empty
                local removed = table.remove(cache["internal:empty"], 1)
                -- print("Slot " .. removed[3] .. " of " .. peripheral.getName(destination) .. " filled.")
                move = move - moved
            end
            -- If it's still not zero, then something is VERY broken- panic.
            if move ~= 0 then
                panic("Invalid Flush!")
            end
            -- If we're here, "move" should be zero. We're all done, move to the next item!
            diff = true -- And make sure that we update the cache on the server, of course.
        end
        if diff then
            rednet.send(server, {
                type = "submit",
                source = "client:" .. cfg.clientName,
                msg = "cache",
                data = cache
            }, "ct-client")
            print("Updating server's cache...")
            replySrv, reply = rednet.receive("ct-server", 5)
            print("Done!")
        end
    else
        --[[
        This is a BAD solution. Ideally I should try and track *where* exactly the items go,
        but without sorting the server-side cache I just can't know for sure right now. A
        problem for future me to solve- for now, this will do. I'm only considering it even
        remotely acceptable because "flush" will likely only be sent once the user is done
        interacting with the system for now, and as such the wait won't be too much of an
        issue. I hope.
        --]]
        -- Spoiler warning: It was. Hence, the new caching behaviour defined above.
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
elseif args[1] == "cache" then
    if cfg.caching then
        if args[2] == "update" then
            rednet.send(cacheServer, {
                type="request",
                source="client:" .. cfg.clientName,
                msg="update"
            }, "ct-client")
            rednet.receive("ct-server")
            cache = getCache(true)
        elseif args[2] == "clear" then
            cache = {}
        end  
    else
        print("Caching is not enabled.")
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
elseif args[1] == "status" then
    local totalSlots = 0
    local usedSlots = 0
    local totalItems = 0
    for item, slots in pairs(cache) do
        totalItems = totalItems + 1
        totalSlots = totalSlots + #slots
        if item ~= "internal:empty" then
            usedSlots = usedSlots + #slots
        end
    end
    local percentUsed = (usedSlots / totalSlots) * 100
    local percentUsed = (math.floor((percentUsed * 10) + 0.5) / 10)

    print("Total inventory slots: " .. totalSlots)
    print("Used inventory slots: " .. usedSlots)
    print("Storage percent used: " .. percentUsed .. "%")
    print("Unique items stored: " .. totalItems)
else
    if args[1] ~= nil then print("Invalid command specified.") end
    print("Commands:")
    print("info - Prints out some info about the software.")
    print("search - Looks for the specified item (mod:name, eg minecraft:raw_copper) and displays every chest it's found in, if any.")
    print("fetch - Looks for the specified item (mod:name, see search) and fetches the specified number of items into a designated output chest. Additionally, you can specify \"exact\" or \"search\" to override the default fetch mode. Use a \".\" to leave the count default when doing so.")
    print("flush - Empties the output chest into the storage system. Takes time, please use sparingly.")
    print("status - Prints information about the storage system (caching only).")

    print(args[1])
end

if embed then
    goto loop
end

::skip::
