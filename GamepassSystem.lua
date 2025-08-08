-- OptimizedGamepassSystem.lua - Consolidated Gamepass Management System
-- Replaces: GamePassRewardManager, UnifiedGamepassSystem, GamepassGearIntegration, GamepassManager, GamepassSystem
-- Features: Comprehensive error handling, duplicate prevention, performance optimization

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("🎮 Loading Optimized Gamepass System v1.0...")

-- Enhanced error handling wrapper
local function safeCall(func, ...)
	local success, result = pcall(func, ...)
	if not success then
		warn("Gamepass System Error: " .. tostring(result))
		return nil, result
	end
	return result
end

-- Retry wrapper for critical operations
local function retryOperation(operation, maxRetries, backoffDelay, ...)
	maxRetries = maxRetries or 3
	backoffDelay = backoffDelay or 1
	
	for attempt = 1, maxRetries do
		local success, result = safeCall(operation, ...)
		if success then
			return result
		end
		
		if attempt < maxRetries then
			task.wait(backoffDelay * attempt) -- Exponential backoff
		end
	end
	
	warn("Operation failed after " .. maxRetries .. " attempts")
	return nil
end

-- Create/Get remotes with validation
local function createRemoteSystem()
	local GamepassRemotes = ReplicatedStorage:FindFirstChild("GamepassRemotes")
	if not GamepassRemotes then
		GamepassRemotes = Instance.new("Folder")
		GamepassRemotes.Name = "GamepassRemotes"
		GamepassRemotes.Parent = ReplicatedStorage
	end

	-- Clean up existing remotes to prevent conflicts
	for _, child in ipairs(GamepassRemotes:GetChildren()) do
		if child.Name:find("CheckGamepassOwnership") or child.Name:find("GetOwnedGamepasses") then
			child:Destroy()
		end
	end

	local CheckGamepassOwnership = Instance.new("RemoteFunction")
	CheckGamepassOwnership.Name = "CheckGamepassOwnership"
	CheckGamepassOwnership.Parent = GamepassRemotes

	local GetOwnedGamepasses = Instance.new("RemoteFunction")
	GetOwnedGamepasses.Name = "GetOwnedGamepasses"
	GetOwnedGamepasses.Parent = GamepassRemotes

	-- Create events if they don't exist
	local UpdateGamepassUI = ReplicatedStorage:FindFirstChild("UpdateGamepassUI")
	if not UpdateGamepassUI then
		UpdateGamepassUI = Instance.new("RemoteEvent")
		UpdateGamepassUI.Name = "UpdateGamepassUI"
		UpdateGamepassUI.Parent = ReplicatedStorage
	end

	local GamepassBenefitsApplied = ReplicatedStorage:FindFirstChild("GamepassBenefitsApplied")
	if not GamepassBenefitsApplied then
		GamepassBenefitsApplied = Instance.new("RemoteEvent")
		GamepassBenefitsApplied.Name = "GamepassBenefitsApplied"
		GamepassBenefitsApplied.Parent = ReplicatedStorage
	end

	return {
		CheckGamepassOwnership = CheckGamepassOwnership,
		GetOwnedGamepasses = GetOwnedGamepasses,
		UpdateGamepassUI = UpdateGamepassUI,
		GamepassBenefitsApplied = GamepassBenefitsApplied
	}
end

local remotes = createRemoteSystem()

-- Data store with throttling
local GamepassDataStore = safeCall(function()
	return DataStoreService:GetDataStore("OptimizedGamepassData_v1")
end)

if not GamepassDataStore then
	error("Failed to initialize GamepassDataStore")
end

-- Consolidated gamepass configuration
local GAMEPASSES = {
	[1376797718] = {
		name = "Matteoooo's VIP",
		benefits = {
			luckMultiplier = 2.0,
			luckPotionDetector = true,
			chatTag = "[Matteoooo]",
			potionNotifications = true
		},
		rewards = {
			gears = {
				{
					id = "time_stop_sandals_liril",
					name = "Time-Stop Sandals of Liril⚡",
					rarity = "mythic",
					luckBoost = 100,
					rollPenalty = 0,
					description = "Legendary sandals that stop time itself"
				}
			},
			brainrots = {
				{name = "Sigma Gyatt Ohio", amount = 1},
				{name = "Skibidi Toilet Rizz", amount = 1}
			},
			items = {
				{id = "luck_potion_detector", name = "Luck Potion Detector", quantity = 1}
			}
		}
	},
	
	[1378491109] = {
		name = "VIP",
		benefits = {
			luckMultiplier = 1.25,
			chatTag = "[VIP]"
		},
		rewards = {
			gears = {
				{
					id = "blueberry_octopus_necklace",
					name = "Blueberry Octopus Necklace",
					rarity = "legendary",
					luckBoost = 25,
					rollPenalty = 0,
					description = "A mystical necklace with ocean powers"
				}
			}
		}
	},
	
	[1374214026] = {
		name = "Starter Pack",
		benefits = {},
		rewards = {
			gears = {
				{
					id = "bobritos_rusty_medal",
					name = "Bobrito's Rusty Medal",
					rarity = "rare",
					luckBoost = 15,
					rollPenalty = 0,
					description = "A battle-worn medal of honor"
				}
			},
			brainrots = {
				{name = "Perfect Starter Bundle", amount = 1},
				{name = "Din Din Melody", amount = 1}
			},
			items = {
				{id = "u_din_din_track", name = "U Din Din Din Din Dun Ma Din Din Din Dun", quantity = 1},
				{id = "tigrrullini_watermellini", name = "Tigrrullini Watermellini", quantity = 2}
			}
		}
	},
	
	[1374405825] = {
		name = "Quick Roll",
		benefits = {
			quickRoll = true
		},
		rewards = {}
	}
}

-- Player data management
local playerData = {}
local dataLoadStatus = {}
local lastDataStoreCall = {}

-- Throttling for data store operations
local function throttleDataStoreCall(key, operation, ...)
	local now = tick()
	if lastDataStoreCall[key] and (now - lastDataStoreCall[key]) < 6 then
		task.wait(6 - (now - lastDataStoreCall[key]))
	end
	
	lastDataStoreCall[key] = tick()
	return operation(...)
end

-- Enhanced data management functions
local function savePlayerData(userId)
	local data = playerData[userId]
	if not data then return false end
	
	data.lastUpdated = os.time()
	data.version = 1
	
	return retryOperation(function()
		return throttleDataStoreCall("save_" .. userId, function()
			GamepassDataStore:SetAsync("player_" .. userId, data)
			return true
		end)
	end, 3, 2)
end

local function loadPlayerData(userId)
	local data = retryOperation(function()
		return throttleDataStoreCall("load_" .. userId, function()
			return GamepassDataStore:GetAsync("player_" .. userId)
		end)
	end, 3, 2)
	
	if data and type(data) == "table" then
		-- Validate and migrate data structure
		data.gamepasses = data.gamepasses or {}
		data.rewardsGranted = data.rewardsGranted or {}
		data.version = data.version or 1
		data.lastUpdated = data.lastUpdated or os.time()
		
		playerData[userId] = data
		return data
	else
		-- Create new data structure
		local newData = {
			gamepasses = {},
			rewardsGranted = {},
			version = 1,
			lastUpdated = os.time()
		}
		playerData[userId] = newData
		return newData
	end
end

-- Enhanced gamepass ownership checking with caching
local gamepassCache = {}
local cacheExpiration = {}

local function checkGamepassOwnership(userId, gamepassId)
	local cacheKey = userId .. "_" .. gamepassId
	local now = tick()
	
	-- Check cache first (5 minute expiration)
	if gamepassCache[cacheKey] and cacheExpiration[cacheKey] and (now - cacheExpiration[cacheKey]) < 300 then
		return gamepassCache[cacheKey]
	end
	
	-- Check our data first
	local data = playerData[userId]
	if data and data.gamepasses[gamepassId] and data.gamepasses[gamepassId].owned then
		gamepassCache[cacheKey] = true
		cacheExpiration[cacheKey] = now
		return true
	end
	
	-- Check with Roblox (with retry)
	local owns = retryOperation(function()
		return MarketplaceService:UserOwnsGamePassAsync(userId, gamepassId)
	end, 3, 1)
	
	if owns == nil then owns = false end
	
	-- Update cache
	gamepassCache[cacheKey] = owns
	cacheExpiration[cacheKey] = now
	
	-- If player owns it but we don't have it recorded, update our data
	if owns and data and (not data.gamepasses[gamepassId] or not data.gamepasses[gamepassId].owned) then
		grantGamepassBenefits(userId, gamepassId, "retroactive")
	end
	
	return owns
end

-- Reward granting functions with enhanced error handling
local function grantGear(userId, gearData)
	print("🎯 Attempting to grant gear:", gearData.name, "to userId:", userId)
	
	-- Method 1: Try existing gear system
	if _G.GetPlayerGearData and _G.SavePlayerGearData then
		local playerGearData = safeCall(_G.GetPlayerGearData, userId)
		if playerGearData then
			playerGearData.gearInventory = playerGearData.gearInventory or {}
			
			-- Check if already has gear
			local hasGear = false
			for _, ownedGearId in ipairs(playerGearData.gearInventory) do
				if ownedGearId == gearData.id then
					hasGear = true
					break
				end
			end
			
			if not hasGear then
				table.insert(playerGearData.gearInventory, gearData.id)
				local player = Players:GetPlayerByUserId(userId)
				if player then
					safeCall(_G.SavePlayerGearData, player)
				end
				print("✅ Granted gear via gear system:", gearData.name)
				return true
			else
				print("ℹ️ Player already has gear:", gearData.name)
				return true
			end
		end
	end
	
	-- Method 2: Try gear remotes
	local GearRemotes = ReplicatedStorage:FindFirstChild("GearRemotes")
	if GearRemotes then
		local AddGearToInventory = GearRemotes:FindFirstChild("AddGearToInventory")
		if AddGearToInventory and AddGearToInventory:IsA("RemoteFunction") then
			local success = safeCall(function()
				return AddGearToInventory:InvokeServer(gearData)
			end)
			if success then
				print("✅ Granted gear via gear remotes:", gearData.name)
				return true
			end
		end
	end
	
	-- Method 3: Store in player data structure
	local player = Players:GetPlayerByUserId(userId)
	if player then
		local gearFolder = player:FindFirstChild("PlayerGears")
		if not gearFolder then
			gearFolder = Instance.new("Folder")
			gearFolder.Name = "PlayerGears"
			gearFolder.Parent = player
		end
		
		-- Create gear data
		local gearValue = Instance.new("StringValue")
		gearValue.Name = gearData.id
		gearValue.Value = game:GetService("HttpService"):JSONEncode(gearData)
		gearValue.Parent = gearFolder
		
		print("✅ Stored gear in player data:", gearData.name)
		return true
	end
	
	warn("❌ Failed to grant gear:", gearData.name)
	return false
end

local function grantBrainrots(userId, brainrotList)
	if not brainrotList or #brainrotList == 0 then return true end
	
	print("🧠 Granting", #brainrotList, "brainrots to userId:", userId)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return false end
	
	local successCount = 0
	
	for _, brainrotData in ipairs(brainrotList) do
		local amount = brainrotData.amount or 1
		
		-- Method 1: Try inventory system
		if _G.AddItemToInventory then
			for i = 1, amount do
				local success = safeCall(_G.AddItemToInventory, userId, brainrotData.name)
				if success then
					successCount = successCount + 1
				end
			end
		end
		
		-- Method 2: Try inventory remotes
		local InventoryRemotes = ReplicatedStorage:FindFirstChild("InventoryRemotes")
		if InventoryRemotes then
			local AddBrainrotItem = InventoryRemotes:FindFirstChild("AddBrainrotItem")
			if AddBrainrotItem and AddBrainrotItem:IsA("RemoteEvent") then
				for i = 1, amount do
					safeCall(function()
						AddBrainrotItem:FireServer(brainrotData.name)
					end)
					successCount = successCount + 1
				end
			end
		end
		
		-- Method 3: Store in player data
		local brainrotFolder = player:FindFirstChild("BrainrotCollection")
		if not brainrotFolder then
			brainrotFolder = Instance.new("Folder")
			brainrotFolder.Name = "BrainrotCollection"
			brainrotFolder.Parent = player
		end
		
		local brainrotValue = Instance.new("IntValue")
		brainrotValue.Name = brainrotData.name
		brainrotValue.Value = amount
		brainrotValue.Parent = brainrotFolder
		
		print("✅ Granted brainrot:", brainrotData.name, "x" .. amount)
	end
	
	return successCount > 0
end

local function grantItems(userId, itemList)
	if not itemList or #itemList == 0 then return true end
	
	print("📦 Granting", #itemList, "items to userId:", userId)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return false end
	
	local successCount = 0
	
	for _, itemData in ipairs(itemList) do
		local quantity = itemData.quantity or 1
		
		-- Try multiple item granting methods
		if _G.AddItemToInventory then
			for i = 1, quantity do
				local success = safeCall(_G.AddItemToInventory, userId, itemData.id)
				if success then
					successCount = successCount + 1
				end
			end
		end
		
		-- Fallback: Store in player data
		local itemFolder = player:FindFirstChild("PlayerItems")
		if not itemFolder then
			itemFolder = Instance.new("Folder")
			itemFolder.Name = "PlayerItems"
			itemFolder.Parent = player
		end
		
		local itemValue = Instance.new("IntValue")
		itemValue.Name = itemData.id
		itemValue.Value = quantity
		itemValue.Parent = itemFolder
		
		print("✅ Granted item:", itemData.name, "x" .. quantity)
		successCount = successCount + 1
	end
	
	return successCount > 0
end

-- Main gamepass benefit granting function
local function grantGamepassBenefits(userId, gamepassId, grantedBy)
	local config = GAMEPASSES[gamepassId]
	if not config then
		warn("❌ Unknown gamepass ID:", gamepassId)
		return false
	end
	
	local data = playerData[userId]
	if not data then
		data = loadPlayerData(userId)
	end
	
	-- Check if already processed
	if data.gamepasses[gamepassId] and data.gamepasses[gamepassId].owned then
		print("ℹ️ Gamepass", config.name, "already owned by userId:", userId)
		return true
	end
	
	print("🎮 Granting", config.name, "benefits to userId:", userId, "- granted by:", grantedBy or "system")
	
	-- Mark as owned
	data.gamepasses[gamepassId] = {
		owned = true,
		purchaseDate = os.time(),
		grantedBy = grantedBy or "system"
	}
	
	local rewardKey = gamepassId .. "_rewards"
	
	-- Grant rewards only if not already granted
	if not data.rewardsGranted[rewardKey] then
		local allSuccessful = true
		
		-- Grant gears
		if config.rewards.gears then
			for _, gearData in ipairs(config.rewards.gears) do
				if not grantGear(userId, gearData) then
					allSuccessful = false
				end
			end
		end
		
		-- Grant brainrots
		if config.rewards.brainrots then
			if not grantBrainrots(userId, config.rewards.brainrots) then
				allSuccessful = false
			end
		end
		
		-- Grant items
		if config.rewards.items then
			if not grantItems(userId, config.rewards.items) then
				allSuccessful = false
			end
		end
		
		-- Only mark as granted if everything succeeded
		if allSuccessful then
			data.rewardsGranted[rewardKey] = true
			print("✅ All rewards granted successfully for", config.name)
		else
			warn("⚠️ Some rewards failed to grant for", config.name)
		end
	else
		print("ℹ️ Rewards already granted for", config.name)
	end
	
	-- Apply passive benefits
	applyPassiveBenefits(userId)
	
	-- Save data
	savePlayerData(userId)
	
	-- Notify client
	local player = Players:GetPlayerByUserId(userId)
	if player then
		remotes.GamepassBenefitsApplied:FireClient(player, gamepassId, config.name)
		remotes.UpdateGamepassUI:FireClient(player)
	end
	
	return true
end

-- Passive benefit application
local function applyPassiveBenefits(userId)
	local data = playerData[userId]
	if not data then return end
	
	local totalLuckMultiplier = 1.0
	local benefits = {
		luckMultiplier = 1.0,
		luckPotionDetector = false,
		quickRoll = false,
		chatTag = nil,
		potionNotifications = false
	}
	
	-- Calculate combined benefits
	for gamepassId, gamepassInfo in pairs(data.gamepasses) do
		if gamepassInfo.owned then
			local config = GAMEPASSES[gamepassId]
			if config and config.benefits then
				if config.benefits.luckMultiplier then
					benefits.luckMultiplier = benefits.luckMultiplier * config.benefits.luckMultiplier
				end
				if config.benefits.luckPotionDetector then
					benefits.luckPotionDetector = true
				end
				if config.benefits.quickRoll then
					benefits.quickRoll = true
				end
				if config.benefits.chatTag then
					benefits.chatTag = config.benefits.chatTag
				end
				if config.benefits.potionNotifications then
					benefits.potionNotifications = true
				end
			end
		end
	end
	
	-- Apply luck boost
	local luckBoostPercentage = (benefits.luckMultiplier - 1) * 100
	
	-- Update global luck system
	if _G.updateGamepassLuckBoost then
		safeCall(_G.updateGamepassLuckBoost, luckBoostPercentage)
	end
	
	-- Update client luck system
	local player = Players:GetPlayerByUserId(userId)
	if player then
		local LuckBoostEvent = ReplicatedStorage:FindFirstChild("LuckBoostEvent")
		if LuckBoostEvent then
			safeCall(function()
				LuckBoostEvent:FireClient(player, luckBoostPercentage, 0)
			end)
		end
		
		-- Apply quick roll feature
		if benefits.quickRoll then
			local quickRollValue = player:FindFirstChild("QuickRollEnabled")
			if not quickRollValue then
				quickRollValue = Instance.new("BoolValue")
				quickRollValue.Name = "QuickRollEnabled"
				quickRollValue.Parent = player
			end
			quickRollValue.Value = true
		end
	end
	
	print("🎯 Applied passive benefits to userId:", userId, "- Luck:", luckBoostPercentage .. "%")
end

-- Initialize player data
local function initializePlayer(player)
	local userId = player.UserId
	print("👤 Initializing gamepass data for:", player.Name)
	
	dataLoadStatus[userId] = {loading = true, loaded = false}
	
	-- Load player data
	loadPlayerData(userId)
	
	-- Check all gamepass ownership
	for gamepassId, config in pairs(GAMEPASSES) do
		task.spawn(function()
			local owns = checkGamepassOwnership(userId, gamepassId)
			if owns then
				print("✅", player.Name, "owns", config.name)
			end
		end)
	end
	
	dataLoadStatus[userId] = {loading = false, loaded = true}
	
	-- Apply benefits after loading
	task.wait(1)
	applyPassiveBenefits(userId)
	
	-- Update UI
	remotes.UpdateGamepassUI:FireClient(player)
end

-- Remote function handlers
remotes.CheckGamepassOwnership.OnServerInvoke = function(player, gamepassId)
	if not player or not gamepassId then
		return false
	end
	
	return checkGamepassOwnership(player.UserId, gamepassId)
end

remotes.GetOwnedGamepasses.OnServerInvoke = function(player)
	if not player then return {} end
	
	local data = playerData[player.UserId]
	if not data then return {} end
	
	local ownedList = {}
	for gamepassId, gamepassInfo in pairs(data.gamepasses) do
		if gamepassInfo.owned then
			table.insert(ownedList, {
				id = gamepassId,
				name = GAMEPASSES[gamepassId] and GAMEPASSES[gamepassId].name or "Unknown",
				purchaseDate = gamepassInfo.purchaseDate,
				grantedBy = gamepassInfo.grantedBy
			})
		end
	end
	
	return ownedList
end

-- Event handlers
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if not wasPurchased or not GAMEPASSES[gamepassId] then return end
	
	print("💰", player.Name, "purchased gamepass:", gamepassId, "-", GAMEPASSES[gamepassId].name)
	
	-- Wait for purchase to process
	task.wait(2)
	
	-- Double-check ownership
	local owns = retryOperation(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end, 3, 1)
	
	if owns then
		grantGamepassBenefits(player.UserId, gamepassId, "purchase")
	else
		warn("❌ Purchase verification failed for", player.Name, "gamepass", gamepassId)
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		task.wait(3) -- Wait for other systems to load
		initializePlayer(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player.UserId)
	
	-- Cleanup after delay
	task.spawn(function()
		task.wait(5)
		playerData[player.UserId] = nil
		dataLoadStatus[player.UserId] = nil
		
		-- Clear gamepass cache for this player
		for cacheKey, _ in pairs(gamepassCache) do
			if cacheKey:find("^" .. player.UserId .. "_") then
				gamepassCache[cacheKey] = nil
				cacheExpiration[cacheKey] = nil
			end
		end
	end)
end)

-- Auto-save system
task.spawn(function()
	while true do
		task.wait(300) -- Save every 5 minutes
		for userId, data in pairs(playerData) do
			if data then
				task.spawn(function()
					savePlayerData(userId)
				end)
			end
		end
	end
end)

-- Shutdown handler
game:BindToClose(function()
	print("🔄 Saving all gamepass data before shutdown...")
	for userId, data in pairs(playerData) do
		if data then
			savePlayerData(userId)
		end
	end
	task.wait(3)
	print("✅ Gamepass system shutdown complete")
end)

-- Global functions for compatibility
_G.CheckPlayerGamepassOwnership = function(player, gamepassId)
	return checkGamepassOwnership(player.UserId, gamepassId)
end

_G.GrantGamepassToPlayer = function(player, gamepassId, grantedBy)
	return grantGamepassBenefits(player.UserId, gamepassId, grantedBy)
end

_G.GetPlayerGamepassData = function(player)
	return playerData[player.UserId]
end

_G.GetPlayerLuckMultiplier = function(player)
	local data = playerData[player.UserId]
	if not data then return 1.0 end
	
	local multiplier = 1.0
	for gamepassId, gamepassInfo in pairs(data.gamepasses) do
		if gamepassInfo.owned then
			local config = GAMEPASSES[gamepassId]
			if config and config.benefits and config.benefits.luckMultiplier then
				multiplier = multiplier * config.benefits.luckMultiplier
			end
		end
	end
	
	return multiplier
end

_G.GetPlayerChatTag = function(player)
	local data = playerData[player.UserId]
	if not data then return nil end
	
	for gamepassId, gamepassInfo in pairs(data.gamepasses) do
		if gamepassInfo.owned then
			local config = GAMEPASSES[gamepassId]
			if config and config.benefits and config.benefits.chatTag then
				return config.benefits.chatTag
			end
		end
	end
	
	return nil
end

_G.HasPotionNotifications = function(player)
	return checkGamepassOwnership(player.UserId, 1376797718)
end

-- Legacy compatibility
_G.ownsGamepass = function(player, gamepassId)
	return checkGamepassOwnership(player.UserId, gamepassId)
end

_G.getPlayerLuckMultiplier = _G.GetPlayerLuckMultiplier

print("✅ Optimized Gamepass System loaded successfully!")
print("🎮 Available gamepasses:")
for id, config in pairs(GAMEPASSES) do
	print("   -", config.name, "(ID:", id .. ")")
end
print("🛡️ Features: Error handling, duplicate prevention, performance optimization, data consistency")