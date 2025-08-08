local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Enhanced error handling wrapper
local function safeCall(func, ...)
	local success, result = pcall(func, ...)
	if not success then
		warn("BrainrotEquipServer Error: " .. tostring(result))
		return nil
	end
	return result
end

-- Parameter validation function
local function validateBrainrotName(brainrotName)
	return type(brainrotName) == "string" and 
	       string.len(brainrotName) > 0 and 
	       string.len(brainrotName) <= 100 and
	       not string.find(brainrotName, "[^%w%s%-_%.!@#%$%%^&*%(%)+={}%[%]|\\:;\"'<>,?/~`]")
end

local EquipBrainrotRemote = ReplicatedStorage:FindFirstChild("EquipBrainrotRemote")
if not EquipBrainrotRemote then
	EquipBrainrotRemote = Instance.new("RemoteEvent")
	EquipBrainrotRemote.Name = "EquipBrainrotRemote"
	EquipBrainrotRemote.Parent = ReplicatedStorage
end

local inventoryRemotes = ReplicatedStorage:WaitForChild("InventoryRemotes", 30)
if not inventoryRemotes then
	warn("InventoryRemotes not found - BrainrotEquipServer may not function properly")
	return
end

local equipBrainrotEvent = inventoryRemotes:WaitForChild("EquipBrainrot", 10)
if not equipBrainrotEvent then
	warn("EquipBrainrot event not found - BrainrotEquipServer may not function properly")
	return
end

local equippedBrainrots = {}

local function broadcastEquip(player, brainrotName)
	-- Validate inputs
	if not player or not player.Parent then
		warn("Invalid player in broadcastEquip")
		return
	end
	
	if brainrotName and not validateBrainrotName(brainrotName) then
		warn("Invalid brainrot name from player:", player.Name)
		return
	end
	
	-- Update tracking
	if brainrotName then
		equippedBrainrots[player.UserId] = brainrotName
	else
		equippedBrainrots[player.UserId] = nil
	end
	
	-- Safely broadcast to all clients
	safeCall(function()
		EquipBrainrotRemote:FireAllClients(player.UserId, brainrotName)
	end)
	
	print("Broadcasting brainrot equip:", player.Name, "->", tostring(brainrotName))
end

-- Enhanced event handlers with validation
equipBrainrotEvent.OnServerEvent:Connect(function(player, brainrotName)
	-- Validate player
	if not player or not player.Parent then
		warn("Invalid player in equipBrainrotEvent")
		return
	end
	
	-- Allow nil/empty to unequip
	if brainrotName == "" then
		brainrotName = nil
	end
	
	broadcastEquip(player, brainrotName)
end)

EquipBrainrotRemote.OnServerEvent:Connect(function(player, brainrotName)
	-- Validate player
	if not player or not player.Parent then
		warn("Invalid player in EquipBrainrotRemote")
		return
	end
	
	-- Allow nil/empty to unequip
	if brainrotName == "" then
		brainrotName = nil
	end
	
	broadcastEquip(player, brainrotName)
end)

-- Enhanced player connection handling
Players.PlayerAdded:Connect(function(newPlayer)
	if not newPlayer or not newPlayer.Parent then
		return
	end
	
	newPlayer.CharacterAdded:Connect(function(character)
		if not character or not character.Parent then
			return
		end
		
		-- Wait for character to fully load
		task.wait(2)
		
		-- Safely sync equipped brainrots to new player
		safeCall(function()
			for userId, equippedBrainrot in pairs(equippedBrainrots) do
				local player = Players:GetPlayerByUserId(userId)
				if player and player.Character and equippedBrainrot then
					EquipBrainrotRemote:FireClient(newPlayer, userId, equippedBrainrot)
				end
			end
		end)
	end)
end)

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
	if player and player.UserId then
		equippedBrainrots[player.UserId] = nil
	end
end)

print("Enhanced BrainrotEquipServer loaded with parameter validation and error handling")

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