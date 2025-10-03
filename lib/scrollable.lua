-- Scrollable library v1.0.0
-- Author: Zeaden Beake
-- Scrollable allows users to easily make a scrollable list on a monitor. The monitor must support touch inputs.

local lib = {}

-- "Features" header defines what features this version
-- of the software supports. When a new feature is added
-- you should add a new entry with a name and the number
-- 1. For example, I would add "horizontal_1" if I added
-- support for horizontal scrolling. If the feature gets
-- updated in a breaking way, increment the number.

lib["features"] = {"vertical_1"}

function lib.start(monitor, input, step, settings)
    if not settings then settings = {} end
    sizeX, sizeY = monitor.getSize()
    scroll = 1
    
    local lines = {}
    if settings.file then
        for line in io.lines(input) do
            lines[#lines + 1] = line
        end
    else
        lines = input
    end
    
    monitor.clear()
    print("Initializing monitor...")
    for i = 1, sizeY, 1 do
        if lines[i] ~= nil then
            monitor.setCursorPos(1, i)
            monitor.write(lines[i])
        end
    end
    print("Monitor initialized.")
    
    while true do
        event, id, touchX, touchY = os.pullEvent()
        --print(event, id)
        if (id == peripheral.getName(monitor)) and event == "monitor_touch" then
            monitor.clear()
            
            if touchY > (sizeY / 2) then
                scroll = scroll + step
            else
                scroll = scroll - step
            end
            
            if not settings.backwards then
                scroll = math.max(scroll, 1)
            end
            
            for i = 1, sizeY, 1 do
                if lines[scroll + i - 1] ~= nil then
                    monitor.setCursorPos(1, i)
                    monitor.write(lines[scroll + i - 1])
                end
            end
        elseif event == "scroll_update" then
            if id == monitor then
                if settings.file then
                    oldLines = lines
                    lines = {}
                    for line in io.lines(input) do
                        lines[#lines + 1] = line
                    end
                    if lines ~= oldLines then
                        monitor.clear()
                        for i = 1, sizeY, 1 do
                            monitor.setCursorPos(1, i)
                            if lines[scroll + i - 1] ~= nil then
                                monitor.write(lines[scroll + i - 1])
                            end
                        end
                    end
                end
            end
        end
    end
end

return lib
