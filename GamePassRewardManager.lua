-- ServerScriptService > Enhanced_GamepassRewardsManager
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

print("?? Loading Enhanced Gamepass Rewards Manager v2...")

-- Data store for tracking granted rewards
local RewardsDataStore = DataStoreService:GetDataStore("GamepassRewards_v3")

-- Wait for all required systems
local GamepassRemotes = ReplicatedStorage:WaitForChild("GamepassRemotes", 10)
local CheckGamepassOwnership = GamepassRemotes and GamepassRemotes:WaitForChild("CheckGamepassOwnership", 5)

-- Try to find gear system
local GearRemotes = ReplicatedStorage:FindFirstChild("GearRemotes")
local AddGearToInventory, GetFormattedGearInventory

if GearRemotes then
	AddGearToInventory = GearRemotes:FindFirstChild("AddGearToInventory") 
	GetFormattedGearInventory = GearRemotes:FindFirstChild("GetFormattedGearInventory")
end

-- Try to find inventory system  
local InventoryRemotes = ReplicatedStorage:FindFirstChild("InventoryRemotes")
local AddItemToInventory, UpdateInventory

if InventoryRemotes then
	AddItemToInventory = InventoryRemotes:FindFirstChild("AddItemToInventory")
	UpdateInventory = InventoryRemotes:FindFirstChild("UpdateInventory")
end

-- Try to find brainrot system
local BrainrotRemotes = ReplicatedStorage:FindFirstChild("BrainrotRemotes") or ReplicatedStorage:FindFirstChild("BrainrotSettingsRemotes")

print("?? System Status:")
print("   Gamepass System: " .. (CheckGamepassOwnership and "?" or "?"))
print("   Gear System: " .. (GearRemotes and "?" or "?"))
print("   Inventory System: " .. (InventoryRemotes and "?" or "?"))
print("   Brainrot System: " .. (BrainrotRemotes and "?" or "?"))

-- Enhanced gamepass reward configurations
local GAMEPASS_REWARDS = {
	[1376797718] = { -- Matteoooo's VIP
		name = "Matteoooo's VIP", 
		rewards = {
			gears = {
				{
					id = "time_stop_sandals_liril",
					name = "Time-Stop Sandals of Liril™",
					rarity = "mythic",
					luckBoost = 100, -- 2x = +100%
					rollPenalty = 0,
					description = "Legendary sandals that stop time itself",
					decalId = "rbxassetid://118478805616343"
				}
			},
			brainrots = {
				"Sigma Gyatt Ohio", -- Example brainrot names
				"Skibidi Toilet Rizz"
			},
			items = {
				{
					id = "luck_potion_detector", 
					name = "Luck Potion Detector",
					description = "Detects hidden luck potions",
					quantity = 1
				}
			},
			luckMultiplier = 2.0,
			chatTag = "[Matteoooo]"
		}
	},

	[1378491109] = { -- VIP
		name = "VIP",
		rewards = {
			gears = {
				{
					id = "blueberry_octopus_necklace", 
					name = "Blueberry Octopus Necklace",
					rarity = "legendary",
					luckBoost = 25, -- 1.25x = +25%
					rollPenalty = 0,
					description = "A mystical necklace with ocean powers",
					decalId = "rbxassetid://116907983558452"
				}
			},
			luckMultiplier = 1.25,
			chatTag = "[VIP]"
		}
	},

	[1374214026] = { -- Starter Pack
		name = "Starter Pack",
		rewards = {
			gears = {
				{
					id = "bobritos_rusty_medal",
					name = "Bobrito's Rusty Medal", 
					rarity = "rare",
					luckBoost = 15,
					rollPenalty = 0,
					description = "A battle-worn medal of honor",
					decalId = "rbxassetid://125050552522929"
				}
			},
			brainrots = {
				"Perfect Starter Bundle", 
				"Din Din Melody"
			},
			items = {
				{
					id = "u_din_din_track",
					name = "U Din Din Din Din Dun Ma Din Din Din Dun",
					description = "A catchy musical track",
					quantity = 1
				},
				{
					id = "tigrrullini_watermellini",
					name = "Tigrrullini Watermellini", 
					description = "Refreshing watermelon treats",
					quantity = 2
				}
			}
		}
	},

	[1374405825] = { -- Quick Roll
		name = "Quick Roll",
		rewards = {
			features = {
				quickRoll = true
			}
		}
	}
}

-- Check if rewards were already granted
local function hasReceivedRewards(player, gamepassId)
	local success, data = pcall(function()
		local key = "Player_" .. player.UserId
		return RewardsDataStore:GetAsync(key) or {}
	end)

	if success and data then
		return data[tostring(gamepassId)] == true
	end
	return false
end

-- Mark rewards as granted
local function markRewardsGranted(player, gamepassId)
	spawn(function()
		local success, err = pcall(function()
			local key = "Player_" .. player.UserId
			local data = RewardsDataStore:GetAsync(key) or {}
			data[tostring(gamepassId)] = true
			RewardsDataStore:SetAsync(key, data)
		end)

		if not success then
			warn("? Failed to save reward status for " .. player.Name .. ": " .. tostring(err))
		else
			print("? Marked rewards as granted for gamepass " .. gamepassId)
		end
	end)
end

-- Enhanced gear granting function
local function grantGear(player, gearData)
	print("?? Attempting to grant gear: " .. gearData.name)

	-- Method 1: Try your existing gear system
	if AddGearToInventory then
		local success, result = pcall(function()
			return AddGearToInventory:InvokeServer(gearData)
		end)

		if success and result then
			print("? Granted gear via AddGearToInventory: " .. gearData.name)
			return true
		else
			print("? AddGearToInventory failed: " .. tostring(result))
		end
	end

	-- Method 2: Try alternative gear granting
	if _G.AddPlayerGear then
		local success, result = pcall(function()
			return _G.AddPlayerGear(player, gearData)
		end)

		if success then
			print("? Granted gear via _G.AddPlayerGear: " .. gearData.name)
			return true
		end
	end

	-- Method 3: Create gear data directly in player
	local success, result = pcall(function()
		local gearFolder = player:FindFirstChild("PlayerGears") or player:FindFirstChild("Gears")
		if not gearFolder then
			gearFolder = Instance.new("Folder")
			gearFolder.Name = "PlayerGears"
			gearFolder.Parent = player
		end

		-- Create gear as StringValue for now
		local gearValue = Instance.new("StringValue")
		gearValue.Name = gearData.id
		gearValue.Value = game:GetService("HttpService"):JSONEncode(gearData)
		gearValue.Parent = gearFolder

		return true
	end)

	if success then
		print("? Created gear data directly: " .. gearData.name)
		return true
	end

	warn("? All gear granting methods failed for: " .. gearData.name)
	return false
end

-- Enhanced brainrot granting function
local function grantBrainrots(player, brainrotNames)
	if not brainrotNames or #brainrotNames == 0 then return true end

	print("?? Attempting to grant " .. #brainrotNames .. " brainrots")

	for _, brainrotName in ipairs(brainrotNames) do
		-- Method 1: Try adding to inventory system
		if UpdateInventory then
			local success, result = pcall(function()
				UpdateInventory:FireClient(player, {
					{name = brainrotName, discovered = true}
				})
				return true
			end)

			if success then
				print("? Granted brainrot via UpdateInventory: " .. brainrotName)
			end
		end

		-- Method 2: Try global function
		if _G.AddPlayerBrainrot then
			local success = pcall(function()
				_G.AddPlayerBrainrot(player, brainrotName)
			end)

			if success then
				print("? Granted brainrot via _G.AddPlayerBrainrot: " .. brainrotName)
			end
		end

		-- Method 3: Add to player data directly
		local playerData = player:FindFirstChild("BrainrotCollection") 
		if not playerData then
			playerData = Instance.new("Folder")
			playerData.Name = "BrainrotCollection"
			playerData.Parent = player
		end

		local brainrotValue = Instance.new("BoolValue")
		brainrotValue.Name = brainrotName
		brainrotValue.Value = true
		brainrotValue.Parent = playerData

		print("? Added brainrot to player data: " .. brainrotName)
	end

	return true
end

-- Main reward granting function
local function grantGamepassRewards(player, gamepassId)
	local rewardConfig = GAMEPASS_REWARDS[gamepassId]
	if not rewardConfig then
		print("?? No rewards configured for gamepass " .. gamepassId)
		return
	end

	print("?? Granting " .. rewardConfig.name .. " rewards to " .. player.Name .. "...")

	local grantedItems = {}
	local allSuccessful = true

	-- Grant gears
	if rewardConfig.rewards.gears then
		for _, gearData in ipairs(rewardConfig.rewards.gears) do
			if grantGear(player, gearData) then
				table.insert(grantedItems, "?? " .. gearData.name)
			else
				allSuccessful = false
				warn("? Failed to grant gear: " .. gearData.name)
			end
		end
	end

	-- Grant brainrots
	if rewardConfig.rewards.brainrots then
		if grantBrainrots(player, rewardConfig.rewards.brainrots) then
			for _, brainrotName in ipairs(rewardConfig.rewards.brainrots) do
				table.insert(grantedItems, "?? " .. brainrotName)
			end
		else
			allSuccessful = false
		end
	end

	-- Grant items
	if rewardConfig.rewards.items then
		for _, itemData in ipairs(rewardConfig.rewards.items) do
			-- Try multiple methods for items too
			local success = false

			if AddItemToInventory then
				local result = pcall(function()
					return AddItemToInventory:InvokeServer(itemData.id, itemData.quantity or 1)
				end)
				if result then success = true end
			end

			if success then
				local quantity = itemData.quantity or 1
				table.insert(grantedItems, "?? " .. quantity .. "x " .. itemData.name)
			else
				allSuccessful = false
			end
		end
	end

	-- Apply features
	if rewardConfig.rewards.features then
		if rewardConfig.rewards.features.quickRoll then
			local quickRollValue = player:FindFirstChild("QuickRollEnabled")
			if not quickRollValue then
				quickRollValue = Instance.new("BoolValue")
				quickRollValue.Name = "QuickRollEnabled"
				quickRollValue.Parent = player
			end
			quickRollValue.Value = true
			table.insert(grantedItems, "? Quick Roll Feature")
		end
	end

	-- Only mark as granted if everything was successful
	if allSuccessful then
		markRewardsGranted(player, gamepassId)
	else
		warn("?? Some rewards failed to grant for " .. player.Name .. " - will retry next time")
	end

	-- Show results
	if #grantedItems > 0 then
		local message = "?? " .. rewardConfig.name .. " rewards!\n" .. table.concat(grantedItems, "\n")
		print("? Granted " .. #grantedItems .. " rewards to " .. player.Name)
		print("?? Items granted: " .. table.concat(grantedItems, ", "))
	else
		warn("? No rewards were successfully granted to " .. player.Name)
	end
end

-- Check all gamepass rewards for a player
local function checkAllGamepassRewards(player)
	if not CheckGamepassOwnership then
		warn("? CheckGamepassOwnership not available")
		return
	end

	print("?? Checking gamepass rewards for " .. player.Name .. "...")

	for gamepassId, config in pairs(GAMEPASS_REWARDS) do
		spawn(function()
			wait(1) -- Stagger the checks

			local success, ownsGamepass = pcall(function()
				return CheckGamepassOwnership:InvokeServer(gamepassId) 
			end)

			if success and ownsGamepass then
				if not hasReceivedRewards(player, gamepassId) then
					print("?? " .. player.Name .. " owns " .. config.name .. " but hasn't received rewards!")
					wait(2) -- Wait for systems to be ready
					grantGamepassRewards(player, gamepassId)
				else
					print("?? " .. player.Name .. " already received " .. config.name .. " rewards")
				end
			else
				print("?? " .. player.Name .. " doesn't own " .. config.name)
			end
		end)
	end
end

-- Events
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if wasPurchased and GAMEPASS_REWARDS[gamepassId] then
		print("?? " .. player.Name .. " purchased gamepass " .. gamepassId .. "!")
		wait(3) -- Wait for purchase to fully process
		grantGamepassRewards(player, gamepassId)
	end
end)

Players.PlayerAdded:Connect(function(player)
	print("?? " .. player.Name .. " joined")
	spawn(function()
		wait(8) -- Extra time for all systems to load
		checkAllGamepassRewards(player)
	end)
end)

-- Admin commands  
Players.PlayerAdded:Connect(function(player)
	if player.Name == "theawesomestudentthatcodedawesomeness" then
		player.Chatted:Connect(function(message)
			if message == "/forcerewards" then
				print("?? FORCING REWARD CHECK for " .. player.Name)
				checkAllGamepassRewards(player)
			end
		end)
	end
end)

-- Global functions
_G.CheckPlayerGamepassRewards = checkAllGamepassRewards
_G.GrantGamepassRewards = grantGamepassRewards

print("? Enhanced Gamepass Rewards Manager v2 loaded!")