-- Place this simple script in ServerScriptService
-- AdminInit - Initialize admin command system (FIXED)

print("?? AdminInit.lua loading...")

local AdminCommandModule = require(script.Parent:WaitForChild("AdminCommandModule"))

-- IMPORTANT: This line was missing!
AdminCommandModule.init()

print("? Admin command system initialized!")
print("?? Checking if LuckPotionSystem loaded global functions...")
print("?? _G.ForceSpawnAllPotions available:", _G.ForceSpawnAllPotions ~= nil)