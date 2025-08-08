local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local EquipBrainrotRemote = ReplicatedStorage:FindFirstChild("EquipBrainrotRemote")
if not EquipBrainrotRemote then
	EquipBrainrotRemote = Instance.new("RemoteEvent")
	EquipBrainrotRemote.Name = "EquipBrainrotRemote"
	EquipBrainrotRemote.Parent = ReplicatedStorage
end

local inventoryRemotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local equipBrainrotEvent = inventoryRemotes:WaitForChild("EquipBrainrot")

local equippedBrainrots = {}

local function broadcastEquip(player, brainrotName)
	equippedBrainrots[player.UserId] = brainrotName
	EquipBrainrotRemote:FireAllClients(player.UserId, brainrotName)
end

equipBrainrotEvent.OnServerEvent:Connect(function(player, brainrotName)
	broadcastEquip(player, brainrotName)
end)

EquipBrainrotRemote.OnServerEvent:Connect(function(player, brainrotName)
	broadcastEquip(player, brainrotName)
end)

Players.PlayerAdded:Connect(function(newPlayer)
	newPlayer.CharacterAdded:Connect(function(character)
		wait(2)
		for userId, equippedBrainrot in pairs(equippedBrainrots) do
			local player = Players:GetPlayerByUserId(userId)
			if player and player.Character then
				EquipBrainrotRemote:FireClient(newPlayer, userId, equippedBrainrot)
			end
		end
	end)
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		wait(1)
		local equippedBrainrot = equippedBrainrots[player.UserId]
		if equippedBrainrot then
			EquipBrainrotRemote:FireAllClients(player.UserId, equippedBrainrot)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	EquipBrainrotRemote:FireAllClients(player.UserId, nil)
	equippedBrainrots[player.UserId] = nil
end)