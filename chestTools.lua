chests = { peripheral.find("minecraft:chest") }
monitor = peripheral.find("monitor")
yPos = 1
contents = {}

command, arg = ...

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
else
    print("Invalid command specified.")
    print("Commands:")
    print("audit - Searches through all connected chests and returns everything it finds.")
    print("search - Looks for the specified item (mod:name, eg minecraft:raw_copper) and displays every chest it's found in, if any.")
end  

