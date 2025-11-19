-- This is a simple startup script that can optionally be used with scanner.lua
-- This makes the pocket computer a dedicated scanner device, and is not at all needed.

shell.run("clear")
print("What block are you looking for?")
print("(Hint: input nothing to search for ores!)")
local usrIn = io.read()
shell.run("scanner " .. usrIn)
shell.run("reboot")
