-- This is a simple startup script that can optionally be used with scanner.lua
-- This makes the pocket computer a dedicated scanner device, and is not at all needed.

shell.run("clear")
print("What are you looking for?")
print("(Hint: input nothing to just search for ore!)")
local usrIn = io.read()
shell.run("test " .. usrIn)

print("")
print("Program terminated. Restart?")
print("(y/n)")
usrIn = string.lower(io.read())
if (usrIn == "y") or (usrIn == "yes") then
    shell.run("reboot")
else
    print("Good day, to the shell.")
end
