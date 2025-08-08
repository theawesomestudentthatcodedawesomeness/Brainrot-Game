-- Script: ServerScriptService>GamePassLuckBoostFix (CORRECTED)
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("?? GAMEPASS LUCK BOOST FIX LOADING (Compatible with existing system)...")

-- Gamepass IDs
local LUCK_BOOST_GAMEPASS_ID = 1378491109  -- VIP
local PREMIUM_LUCK_GAMEPASS_ID = 1376797718 -- Matteoooo's VIP

-- Luck boost percentages (not multipliers)
local STANDARD_LUCK_BOOST = 25  -- +25% luck
local PREMIUM_LUCK_BOOST = 100  -- +100% luck (2x)

-- Function to check if player owns gamepass
local function playerOwnsGamepass(player, gamepassId)
	-- First try the existing gamepass system
	if _G.CheckPlayerGamepassOwnership then
		local success, owns = pcall(function()
			return _G.CheckPlayerGamepassOwnership(player, gamepassId)
		end)
		if success then
			return owns
		end
	end

	-- Fallback to direct marketplace check
	local success, ownsGamepass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)
	return success and ownsGamepass
end

-- Function to calculate and apply gamepass luck boost
local function applyGamepassLuckBoost(player)
	local totalLuckBoost = 0

	-- Check for premium luck boost first (higher priority)
	if playerOwnsGamepass(player, PREMIUM_LUCK_GAMEPASS_ID) then
		totalLuckBoost = PREMIUM_LUCK_BOOST
		print("?? " .. player.Name .. " has Matteoooo's VIP: +" .. totalLuckBoost .. "% luck")
	elseif playerOwnsGamepass(player, LUCK_BOOST_GAMEPASS_ID) then
		totalLuckBoost = STANDARD_LUCK_BOOST
		print("? " .. player.Name .. " has VIP: +" .. totalLuckBoost .. "% luck")
	end

	-- Apply the luck boost using your existing system
	if totalLuckBoost > 0 then
		-- Try multiple methods to apply the luck boost
		local applied = false

		-- Method 1: Use existing updateGamepassLuckBoost function
		if _G.updateGamepassLuckBoost then
			local success = pcall(function()
				_G.updateGamepassLuckBoost(totalLuckBoost)
			end)
			if success then
				applied = true
				print("? Applied gamepass luck via _G.updateGamepassLuckBoost")
			end
		end

		-- Method 2: Use existing updateBadgeLuckBoost function
		if not applied and _G.updateBadgeLuckBoost then
			local success = pcall(function()
				_G.updateBadgeLuckBoost(totalLuckBoost)
			end)
			if success then
				applied = true
				print("? Applied gamepass luck via _G.updateBadgeLuckBoost")
			end
		end

		-- Method 3: Use LuckBoostEvent
		if not applied then
			local LuckBoostEvent = ReplicatedStorage:FindFirstChild("LuckBoostEvent")
			if LuckBoostEvent then
				local success = pcall(function()
					LuckBoostEvent:FireClient(player, totalLuckBoost, 0)
				end)
				if success then
					applied = true
					print("? Applied gamepass luck via LuckBoostEvent")
				end
			end
		end

		-- Method 4: Store in player for other systems to use
		if not applied then
			local gamepassLuckValue = player:FindFirstChild("GamepassLuckBoost")
			if not gamepassLuckValue then
				gamepassLuckValue = Instance.new("NumberValue")
				gamepassLuckValue.Name = "GamepassLuckBoost"
				gamepassLuckValue.Parent = player
			end
			gamepassLuckValue.Value = totalLuckBoost
			print("? Stored gamepass luck in player object: +" .. totalLuckBoost .. "%")
			applied = true
		end

		if applied then
			print("?? Successfully applied +" .. totalLuckBoost .. "% gamepass luck boost to " .. player.Name)
		else
			warn("? Failed to apply gamepass luck boost to " .. player.Name)
		end
	else
		print("?? " .. player.Name .. " has no gamepass luck boosts")

		-- Reset any existing boosts
		if _G.updateGamepassLuckBoost then
			pcall(function() _G.updateGamepassLuckBoost(0) end)
		end

		local gamepassLuckValue = player:FindFirstChild("GamepassLuckBoost")
		if gamepassLuckValue then
			gamepassLuckValue.Value = 0
		end
	end

	return totalLuckBoost
end

-- Function to handle player joining
local function onPlayerAdded(player)
	print("?? Setting up gamepass luck for " .. player.Name)

	-- Wait for other systems to load
	spawn(function()
		wait(3)
		applyGamepassLuckBoost(player)
	end)

	-- Reapply on character spawn
	player.CharacterAdded:Connect(function()
		spawn(function()
			wait(2) -- Wait for character to fully load
			applyGamepassLuckBoost(player)
		end)
	end)

	-- If character already exists
	if player.Character then
		spawn(function()
			wait(2)
			applyGamepassLuckBoost(player)
		end)
	end
end

-- Function to handle player leaving
local function onPlayerRemoving(player)
	-- Clean up any stored values
	local gamepassLuckValue = player:FindFirstChild("GamepassLuckBoost")
	if gamepassLuckValue then
		gamepassLuckValue:Destroy()
	end

	print("?? Cleaned up gamepass luck data for " .. player.Name)
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Apply to existing players
for _, player in pairs(Players:GetPlayers()) do
	spawn(function()
		onPlayerAdded(player)
	end)
end

-- Global function for other scripts to use
_G.GetPlayerGamepassLuckBoost = function(player)
	local gamepassLuckValue = player:FindFirstChild("GamepassLuckBoost")
	if gamepassLuckValue then
		return gamepassLuckValue.Value
	end
	return 0
end

-- Global function to refresh a specific player's gamepass luck
_G.RefreshPlayerGamepassLuck = function(player)
	return applyGamepassLuckBoost(player)
end

-- Optional: Function to refresh all player luck boosts (useful for testing)
_G.RefreshAllGamepassLuck = function()
	print("?? Refreshing gamepass luck for all players...")
	for _, player in pairs(Players:GetPlayers()) do
		spawn(function()
			applyGamepassLuckBoost(player)
		end)
	end
end

-- Listen for gamepass purchase events
if MarketplaceService.PromptGamePassPurchaseFinished then
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
		if wasPurchased and (gamepassId == LUCK_BOOST_GAMEPASS_ID or gamepassId == PREMIUM_LUCK_GAMEPASS_ID) then
			print("?? " .. player.Name .. " purchased gamepass " .. gamepassId .. ", applying luck boost...")
			spawn(function()
				wait(1) -- Wait for purchase to register
				applyGamepassLuckBoost(player)
			end)
		end
	end)
end

-- Connect to existing gamepass system updates
local UpdateGamepassUI = ReplicatedStorage:FindFirstChild("UpdateGamepassUI")
if UpdateGamepassUI then
	UpdateGamepassUI.OnServerEvent:Connect(function(player)
		spawn(function()
			wait(0.5)
			applyGamepassLuckBoost(player)
		end)
	end)
end

-- Admin command for testing
Players.PlayerAdded:Connect(function(player)
	if player.Name == "i0nii_Chann" or player.UserId == 1710943863 then
		player.Chatted:Connect(function(message)
			if message == "/testluck" then
				print("?? TESTING GAMEPASS LUCK for " .. player.Name)
				local luckBoost = applyGamepassLuckBoost(player)
				print("?? Result: +" .. luckBoost .. "% luck boost applied")

				-- Also test the global function
				local storedLuck = _G.GetPlayerGamepassLuckBoost(player)
				print("?? Stored luck boost: +" .. storedLuck .. "%")

			elseif message == "/refreshallluck" then
				print("?? ADMIN: Refreshing all player gamepass luck...")
				_G.RefreshAllGamepassLuck()
			end
		end)
	end
end)

print("? GAMEPASS LUCK BOOST FIX LOADED SUCCESSFULLY!")
print("?? Compatible with your existing luck system")
print("?? VIP: +" .. STANDARD_LUCK_BOOST .. "% luck")
print("?? Matteoooo's VIP: +" .. PREMIUM_LUCK_BOOST .. "% luck")
print("?? Admin commands: /testluck, /refreshallluck")
print("?? Global functions available:")
print("   _G.GetPlayerGamepassLuckBoost(player)")
print("   _G.RefreshPlayerGamepassLuck(player)")
print("   _G.RefreshAllGamepassLuck()")