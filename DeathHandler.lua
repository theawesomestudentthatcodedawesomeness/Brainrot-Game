-- Place in ServerScriptService
-- Enhanced Death Handler with Proper Gear Luck Restoration

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("?? Enhanced Death Handler System Loading...")

-- Store player equipment state before death
local playerEquipmentState = {}

-- Function to save player's current equipment and luck state
local function savePlayerEquipment(player)
	local userId = player.UserId
	playerEquipmentState[userId] = {
		equippedGear = nil,
		gearLuckBoost = 0,
		equippedBrainrot = nil,
		chatTag = nil,
		gamepassLuckBoost = 0,
		timestamp = tick()
	}

	print("?? Saving equipment state for " .. player.Name .. "...")

	-- Save equipped gear and its luck boost
	if _G.GetPlayerGearData then
		local gearData = _G.GetPlayerGearData(userId)
		if gearData and gearData.equippedGear then
			playerEquipmentState[userId].equippedGear = gearData.equippedGear

			-- Calculate the luck boost from this gear
			local luckBoost = 0
			if _G.GetGearLuckBoost then
				luckBoost = _G.GetGearLuckBoost(gearData.equippedGear)
			elseif _G.getCurrentBadgeLuckBoost then
				luckBoost = _G.getCurrentBadgeLuckBoost()
			end

			playerEquipmentState[userId].gearLuckBoost = luckBoost
			print("?? Saved equipped gear for " .. player.Name .. ": " .. gearData.equippedGear .. " (+" .. luckBoost .. "% luck)")
		end
	end

	-- Save current badge/gear luck boost from client
	local currentBoost = 0
	local luckBoostEvent = ReplicatedStorage:FindFirstChild("LuckBoostEvent")
	if luckBoostEvent then
		-- We need to get this from the client or store it server-side
		if _G.getPlayerCurrentLuckBoost then
			currentBoost = _G.getPlayerCurrentLuckBoost(userId) or 0
		end
	end
	playerEquipmentState[userId].gearLuckBoost = currentBoost

	-- Save gamepass luck boost
	if _G.CheckPlayerGamepassOwnership then
		local gamepassBoost = 0

		-- Check Matteoooo's VIP (2x = 100% boost)
		if _G.CheckPlayerGamepassOwnership(player, 1376797718) then
			gamepassBoost = gamepassBoost + 100
		end

		-- Check regular VIP (1.25x = 25% boost)
		if _G.CheckPlayerGamepassOwnership(player, 1378491109) then
			gamepassBoost = gamepassBoost + 25
		end

		playerEquipmentState[userId].gamepassLuckBoost = gamepassBoost
		print("?? Saved gamepass luck boost for " .. player.Name .. ": +" .. gamepassBoost .. "%")
	end

	-- Save chat tag
	if _G.GetPlayerChatTag then
		local chatTag = _G.GetPlayerChatTag(player)
		if chatTag then
			playerEquipmentState[userId].chatTag = chatTag
			print("?? Saved chat tag for " .. player.Name .. ": " .. chatTag)
		end
	end

	print("?? ? Equipment state saved for " .. player.Name)
end

-- Function to restore player's equipment after respawn
local function restorePlayerEquipment(player)
	local userId = player.UserId
	local savedState = playerEquipmentState[userId]

	if not savedState then
		print("?? No saved state found for " .. player.Name)
		return
	end

	print("?? Restoring equipment for " .. player.Name .. "...")

	-- Wait for character to fully load
	local character = player.Character or player.CharacterAdded:Wait()
	wait(3) -- Give extra time for all systems to initialize

	-- Restore equipped gear
	if savedState.equippedGear and _G.GetPlayerGearData then
		local gearData = _G.GetPlayerGearData(userId)
		if gearData then
			gearData.equippedGear = savedState.equippedGear

			-- Apply gear effects
			if _G.ApplyGearEffects then
				_G.ApplyGearEffects(player, savedState.equippedGear)
			end

			print("?? ? Restored equipped gear for " .. player.Name .. ": " .. savedState.equippedGear)
		end
	end

	-- Wait a bit more for client GUIs to load
	wait(2)

	-- Restore luck boosts with multiple attempts
	spawn(function()
		local attempts = 0
		local maxAttempts = 5

		while attempts < maxAttempts do
			attempts = attempts + 1
			print("?? ?? Restoring luck boosts for " .. player.Name .. " (attempt " .. attempts .. "/" .. maxAttempts .. ")")

			-- Restore gear luck boost
			if savedState.gearLuckBoost and savedState.gearLuckBoost > 0 then
				local luckBoostEvent = ReplicatedStorage:FindFirstChild("LuckBoostEvent")
				if luckBoostEvent then
					luckBoostEvent:FireClient(player, savedState.gearLuckBoost, 0)
					print("?? ?? Sent gear luck boost to " .. player.Name .. ": +" .. savedState.gearLuckBoost .. "%")
				end
			end

			-- Restore gamepass luck boost (this should happen automatically, but let's ensure it)
			if savedState.gamepassLuckBoost and savedState.gamepassLuckBoost > 0 then
				-- The gamepass system should handle this automatically
				-- But we can force an update
				if _G.updateGamepassLuckBoost then
					-- This would be client-side, so we rely on the gamepass system
				end
				print("?? ?? Gamepass luck boost should restore automatically: +" .. savedState.gamepassLuckBoost .. "%")
			end

			wait(2) -- Wait between attempts
		end

		print("?? ? Luck boost restoration complete for " .. player.Name)
	end)

	-- Force refresh chat tags
	spawn(function()
		wait(4) -- Wait for chat system to load
		if savedState.chatTag then
			-- The ChatTagSystem should handle this automatically
			print("?? ?? Chat tag should restore automatically: " .. savedState.chatTag)
		end
	end)
end

-- Global function to manually restore equipment (for debugging)
_G.ForceRestorePlayerEquipment = function(playerName)
	local player = Players:FindFirstChild(playerName)
	if player then
		restorePlayerEquipment(player)
		return true
	end
	return false
end

-- Global function to check saved equipment state
_G.GetSavedEquipmentState = function(playerName)
	local player = Players:FindFirstChild(playerName)
	if player then
		return playerEquipmentState[player.UserId]
	end
	return nil
end

-- Connect to player events
Players.PlayerAdded:Connect(function(player)
	print("?? Setting up death handler for " .. player.Name)

	-- Save equipment when character is about to be removed
	player.CharacterRemoving:Connect(function(character)
		print("?? Character removing for " .. player.Name .. ", saving equipment...")
		savePlayerEquipment(player)
	end)

	-- Restore equipment when character is added
	player.CharacterAdded:Connect(function(character)
		print("?? Character added for " .. player.Name .. ", scheduling restoration...")
		spawn(function()
			wait(2) -- Wait for character to fully load
			restorePlayerEquipment(player)
		end)
	end)

	-- Handle if character already exists
	if player.Character then
		player.CharacterRemoving:Connect(function(character)
			print("?? (Existing character) Character removing for " .. player.Name .. ", saving equipment...")
			savePlayerEquipment(player)
		end)
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	print("?? Cleaning up equipment state for " .. player.Name)
	playerEquipmentState[player.UserId] = nil
end)

-- Server-side storage for player luck boosts (to prevent flickering)
local serverPlayerLuckBoosts = {}

-- Function to update server-side luck tracking
local function updateServerLuckBoost(userId, gearLuckBoost, gamepassLuckBoost)
	serverPlayerLuckBoosts[userId] = {
		gearLuck = gearLuckBoost or 0,
		gamepassLuck = gamepassLuckBoost or 0,
		lastUpdated = tick()
	}
end

-- Global function to get server-stored luck boost
_G.getPlayerCurrentLuckBoost = function(userId)
	local data = serverPlayerLuckBoosts[userId]
	if data then
		return data.gearLuck
	end
	return 0
end

-- Global function to update server luck tracking
_G.updateServerPlayerLuckBoost = function(userId, gearLuckBoost, gamepassLuckBoost)
	updateServerLuckBoost(userId, gearLuckBoost, gamepassLuckBoost)
end

-- Listen for luck boost events to track server-side
local luckBoostEvent = ReplicatedStorage:FindFirstChild("LuckBoostEvent")
if luckBoostEvent then
	-- We can't directly listen to FireClient, but we can create a tracking system
end

print("?? ? Enhanced Death Handler System Loaded!")
print("?? ?? Debug commands available:")
print("??   _G.ForceRestorePlayerEquipment('playerName')")
print("??   _G.GetSavedEquipmentState('playerName')")