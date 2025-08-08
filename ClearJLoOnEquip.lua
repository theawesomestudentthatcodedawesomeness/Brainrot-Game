-- ServerScriptService/ClearJLoOnEquip.lua
-- Ensures JLo doesn't show titles when players equip

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local EquipBrainrotVisual = ReplicatedStorage:WaitForChild("EquipBrainrotVisual")
local ShowBrainrotOnJLoEvent = ReplicatedStorage:WaitForChild("ShowBrainrotOnJLoEvent")

-- When a player equips a title, clear JLo
EquipBrainrotVisual.OnServerEvent:Connect(function(player, brainrotName, brainrotOdds, color)
	-- Clear JLo title for this player
	ShowBrainrotOnJLoEvent:FireClient(player, nil, nil, nil)
	print("??? Cleared JLo title for " .. player.Name .. " (player equipped: " .. brainrotName .. ")")
end)

print("??? JLo Clear System Ready!")