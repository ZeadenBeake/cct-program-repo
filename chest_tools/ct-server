local chests = { peripheral.find("minecraft:chest") }
local registered = { }
local ignored = { }
local cfg = { side = "left", name="Keep Storage Cache" }
local buffer = { }
local cache = { }
local busy = false
local termReady = true
local pretty = require "cc.pretty"

function updateCache()
    cache = { }
    busy = true
    termReady = false
    for id, chest in pairs(chests) do
        --print("Searching chest ", chest)
        if not ignored[peripheral.getName(chest)] then
            for i = 1, chest.size() do
                --print("Searching slot ", i)
                local slot = i
                local item = chest.getItemDetail(slot)
                if not item then
                    item = { name="internal:empty", count=0 }
                end
                --print(("%dx %s found in chest %s slot %d"):format(item.count, item.name, id, slot))
                if cache[item.name] then
                    local info = {item.count, peripheral.getName(chest), slot}
                    table.insert(cache[item.name], info)
                else
                    local info = {item.count, peripheral.getName(chest), slot}
                    cache[item.name] = {}
                    table.insert(cache[item.name], info)
                end
                --coroutine.yield()
            end
        end
    end

    local cacheFile = fs.open("/tmp/ct-cache.cache", "w")
    for key, value in pairs(cache) do
        strOut = ""
        for _, each in pairs(value) do
            tblOut = ("%s,%s,%s"):format(each[1], each[2], each[3])
            strOut = strOut .. tblOut .. "|"
        end
        strOut = strOut:sub(1, -2)
        cacheFile.write(key .. "=" .. strOut .. "\n")
    end
    cacheFile.close()
    busy = false
    termReady = true
    print("Update finished!")
    os.queueEvent("done")
    coroutine.resume(coro_reply)
    return true
end

if fs.exists("/cfg/ct-server.cfg") then
    configFile = fs.open("/cfg/ct-server.cfg", "r")
    for key, value in string.gmatch(configFile.readAll(), "(.-)=(.-)\n") do
        cfg[key] = value
    end
    configFile.close()
else
    configFile = fs.open("/cfg/ct-server.cfg", "w")
    for key, value in pairs(cfg) do
        configFile.write(key .. "=" .. value .. "\n")
    end
    configFile.close()
end

if fs.exists("/cfg/ct-server-ignore.cfg") then
    ignoreFile = fs.open("/cfg/ct-server-ignore.cfg", "r")
    for key, value in string.gmatch(ignoreFile.readAll(), "(.-)=(.-)\n") do
        registered[key] = value
        ignored[value] = key
    end
    ignoreFile.close()
else
    ignoreFile = fs.open("/cfg/ct-server-ignore.cfg", "w")
    for key, value in pairs(cfg) do
        ignoreFile.write(key .. "=" .. value .. "\n")
    end
    ignoreFile.close()
end

if fs.exists("/tmp/ct-cache.cache") then
    cacheFile = fs.open("/tmp/ct-cache.cache", "r")
    for item, stacks in string.gmatch(cacheFile.readAll(), "(.-)=(.-)\n") do
        local itemStacks = {}
        for each in string.gmatch(stacks, "([^|]+)") do
            itemStacks[#itemStacks + 1] = { }
            for entry in string.gmatch(each, "([^,]+)") do
                itemStacks[#itemStacks][#itemStacks[#itemStacks] + 1] = entry
            end
        end
        cache[item] = itemStacks
    end
    cacheFile.close()
else
    updateCache()
end

modem = peripheral.wrap(cfg.side)
rednet.open(peripheral.getName(modem))
rednet.host("ct-server", cfg.name)
rednet.broadcast({
    source = "server:" .. cfg.name,
    type = "motd",
    msg = cfg.name .. " booted!"
}, "ct-server")

coro_reply = coroutine.create(function ()
    while true do
        if buffer[1] then
            local source = buffer[1].source
            local message = buffer[1].message
            local processed = table.remove(buffer, 1)
            --print(message.type, message.source, message.msg)
            if message.type == "request" then
                if message.msg == "cache" then
                    while busy do
                        print("main: Busy!")
                        table.insert(buffer, processed)
                        coroutine.yield()
                    end
                    draft = {
                        type = "data",
                        source = "server:" .. cfg.name,
                        data = cache
                    }
                    rednet.send(source, draft, "ct-server")
                    print("main: Gave cache to " .. message.source)
                elseif message.msg == "update" then
                    draft = {
                        type = "txt",
                        source = "server:" .. cfg.name,
                        msg = "Updating cache..."
                    }
                    rednet.send(source, draft, "ct-server")
                    print("main: Refreshing cache as asked by " .. message.source)
                    os.queueEvent("refresh_cache")
                    --coroutine.yield()
                elseif message.msg == "lookup" then
                    draft = {
                        type = "txt",
                        source = "server:" .. cfg.name,
                        msg = registered[message.data]
                    }
                    print("main: Gave " .. message.source .. " " .. message.data .. "'s target chest name.")
                end
            elseif message.type == "submit" then
                if message.msg == "cache" then
                    draft = {
                        type = "txt",
                        source = "server" .. cfg.name,
                        msg = "Update recieved."
                    }
                    rednet.send(source, draft, "ct-server")
                    cache = message.data
                elseif message.msg == "register" then
                    draft = {
                        type = "txt",
                        source = "server:" .. cfg.name,
                        msg = "Adding " .. message.source .. " to target-ignore list."
                    }
                    rednet.send(source, draft, "ct-server")
                    registered[message.source] = message.data
                    ignored[message.data] = message.source
                    print("main: Added " .. message.source .. "'s target to ignore list.")
                end
            elseif message.type == "ping" then
                draft = {
                    type = "txt",
                    source = "server:" .. cfg.name,
                    msg = "Pong!"
                }
                rednet.send(source, draft, "ct-server")
                print("main: Responding to ping from " .. message.source)
            elseif message.type == "panic" then
                draft = {
                    type = "demand",
                    source = "server:" .. cfg.name,
                    msg = "Server Panic!"
                }
                rednet.broadcast(draft, "ct-server")
                print("main: Panic from " .. message.source .. "!")
                os.queueEvent("refresh_cache")
            end
        else
            coroutine.yield()
        end
    end
end)

parallel.waitForAny(
    function()
        coroutine.resume(coro_reply)
        print("Console started!")
        while true do
            if termReady then
                io.write("> ")
                console = string.lower(io.read())
                if console == "update" then
                    print("Refreshing cache...")
                    os.queueEvent("refresh_cache")
                elseif console == "shutdown" then
                    print("Goodbye!")
                    return true
                elseif console == "dump_cache" then
                    local width, height = term.getCursorPos()
                    textutils.pagedPrint(pretty.render(pretty.pretty(cache)), height - 2)
                end
            else
                coroutine.yield()
            end
            sleep(0.1)
        end
    end,
    function()
        while true do
            os.pullEvent("refresh_cache")
            busy = true
            parallel.waitForAny(
                function()
                    if updateCache() then
                        busy = false
                    else
                        error()
                    end
                end,
                function()
                    while true do
                        if busy then
                            sent = {}
                            for _, message in ipairs(buffer) do
                                draft = {
                                    type = "txt",
                                    source = "server:" .. cfg.name,
                                    msg = "Server is busy..."
                                }
                                if not sent[message.source] then
                                    print("KeepAlive: Reassuring " .. message.source)
                                    rednet.send(message.source, draft, "ct-server")
                                    sent[message.source] = true
                                end
                            end
                        end
                        --print("Heartbeat...")
                        --print(busy, #buffer)
                        sleep(3)
                    end
                end
            )
            --updateCache()
            busy = false
        end
    end,
    function()
        while true do
            local src, msg = rednet.receive("ct-client")
            table.insert(buffer, {source=src, message=msg})
            print("msgQueue: Got message from " .. src)
            coroutine.resume(coro_reply)
        end
    end
)

