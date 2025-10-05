chests = { peripheral.find("minecraft:chest") }
ignored = { }
cfg = { side = "left", name="Keep Storage Cache" }
buffer = { }
cache = { }
busy = false

function updateCache()
    cache = { }
    busy = true
    for id, chest in pairs(chests) do
        for slot, item in pairs(chest.list()) do
            sleep(0.05)
            print(("%dx %s found in chest %s slot %d"):format(item.count, item.name, id, slot))
            if cache[item.name] then
                info = {item.count, id, slot}
                table.insert(cache[item.name], info)
            else
                info = {item.count, id, slot}
                cache[item.name] = {}
                table.insert(cache[item.name], info)
            end
        end
    end

    cacheFile = fs.open("/tmp/ct-cache.cache", "w")
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
        ignored[key] = value
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
            source = buffer[1].source
            message = buffer[1].message
            print(buffer[1])
            print(source, message)
            table.remove(buffer, 1)
            if message.type == "request" then
                if message.msg == "cache" then
                    while busy do
                        print("busy!")
                        coroutine.yield()
                    end
                    draft = {
                        type = "data",
                        source = "server:" .. cfg.name,
                        data = cache
                    }
                    rednet.send(source, draft, "ct-server")
                elseif message.msg == "update" then
                    draft = {
                        type = "txt",
                        source = "server:" .. cfg.name,
                        msg = "Updating cache..."
                    }
                    rednet.send(source, draft, "ct-server")
                    os.queueEvent("refresh_cache")
                    --coroutine.yield()
                end
            elseif message.type == "ping" then
                draft = {
                    type = "txt",
                    source = "server:" .. cfg.name,
                    msg = "Pong!"
                }
                rednet.send(source, draft, "ct-server")
                print("Responding to ping from " .. message.source)
            end
        else
            coroutine.yield()
        end
    end
end)

parallel.waitForAny(
    function()
        coroutine.resume(coro_reply)
        io.read()
    end,
    function()
        while true do
            os.pullEvent("refresh_cache")
            busy = true
            updateCache()
            busy = false
        end
    end,
    function()
        while true do
            local src, msg = rednet.receive("ct-client")
            table.insert(buffer, {source=src, message=msg})
            print("Got message!")
            print(src, msg)
            coroutine.resume(coro_reply)
        end
    end,
    function()
        while true do
            if busy then
                draft = {
                    type = "txt",
                    source = "server:" .. cfg.name,
                    msg = "Server is busy..."
                }
                rednet.send(source, draft, "ct-server")
                print("Reassuring " .. message.source)
                sleep(3)
            else
                coroutine.yield()
            end
        end
    end
)
