if fs.exists("/chestTools.lua") or fs.exists("/lua/chestTools.daemon.lua") then
    print("Chest Tools detected. Proceed anyway? (Original will be overwritten)")
    local choice = io.read()
    if not ((string.lower(choice) == "y") or (string.lower(choice) == "yes")) then
        error("Chest Tools installtion aborted. Exiting.")
    end
end

if fs.exists("/chestTools.lua") then fs.delete("/chestTools.lua") end
if fs.exists("/lua/chestTools.daemon.lua") then fs.delete("/lua/chestTools.daemon.lua") end
if fs.exists("/lib/scrollable.lua") then
    compatible = false
    package.path = package.path .. ";/lib/?.lua"
    local ok, err pcall(require, "scrollable")
    if ok then
        features = err.features
        for feature in features do
            if feature == "vertical_1" then compatible = true end
        end
    end
    if not compatible then
        print("scrollable library incompatible, updating...")
        fs.delete("/lib/scrollable.lua")
        shell.run("wget https://raw.githubusercontent.com/ZeadenBeake/cct-program-repo/refs/heads/main/lib/scrollable.lua /lib/scrollable.lua")
    end
else
    shell.run("wget https://raw.githubusercontent.com/ZeadenBeake/cct-program-repo/refs/heads/main/lib/scrollable.lua /lib/scrollable.lua")
end

shell.run("wget https://raw.githubusercontent.com/ZeadenBeake/cct-program-repo/refs/heads/main/chest_tools/chestTools.lua /chestTools.lua")
shell.run("wget https://raw.githubusercontent.com/ZeadenBeake/cct-program-repo/refs/heads/main/chest_tools/chestTools.daemon.lua /lua/chestTools.daemon.lua")

print("Installtion complete!")
print("Try running \"chestTools\" to see available commands to get started.")
