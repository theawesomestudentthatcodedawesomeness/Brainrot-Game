local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local equipBrainrotTitle = ReplicatedStorage:WaitForChild("EquipBrainrotTitle")
local equipBrainrotVisual = ReplicatedStorage:WaitForChild("EquipBrainrotVisual")
local BrainrotDefinitions = require(ReplicatedStorage:WaitForChild("BrainrotDefinitions"))

-- Handle equip requests
equipBrainrotTitle.OnServerEvent:Connect(function(player, brainrotName)
	-- Verify the player has this brainrot (add your own verification logic)
	local brainrot = BrainrotDefinitions.Lookup[brainrotName]
	if not brainrot then return end

	-- Fire the visual event to all clients
	equipBrainrotVisual:FireAllClients(player, brainrotName, brainrot.odds, brainrot.titleColor)
end)