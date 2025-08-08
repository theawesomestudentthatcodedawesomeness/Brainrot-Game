-- Script: ServerScriptService>UnifiedGamepassSystem
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create remotes
local GamepassRemotes = ReplicatedStorage:FindFirstChild("GamepassRemotes") or Instance.new("Folder")
GamepassRemotes.Name = "GamepassRemotes"
GamepassRemotes.Parent = ReplicatedStorage

local CheckGamepassOwnership = Instance.new("RemoteFunction")
CheckGamepassOwnership.Name = "CheckGamepassOwnership"
CheckGamepassOwnership.Parent = GamepassRemotes

local GamepassBenefitsApplied = ReplicatedStorage:FindFirstChild("GamepassBenefitsApplied") or Instance.new("RemoteEvent")
GamepassBenefitsApplied.Name = "GamepassBenefitsApplied"
GamepassBenefitsApplied.Parent = ReplicatedStorage

local UpdateGamepassUI = ReplicatedStorage:FindFirstChild("UpdateGamepassUI") or Instance.new("RemoteEvent")
UpdateGamepassUI.Name = "UpdateGamepassUI"
UpdateGamepassUI.Parent = ReplicatedStorage

-- Datastore
local GamepassDataStore = DataStoreService:GetDataStore("GamepassData_v1")

-- Configuration
local GAMEPASSES = {
	[1376797718] = {
		name = "Matteoooo's VIP",
		luckMultiplier = 2,
		gears = {"time_stop_sandals"},
		brainrots = {
			{"Lirilì Larilà", 50}
		}
	},
	[1378491109] = {
		name = "VIP",
		luckMultiplier = 1.25,
		gears = {"blueberry_octopus_necklace"},
		brainrots = {
			{"Blueberrinni Octopussini", 10}
		}
	},
	[1374214026] = {
		name = "Starter Pack", 
		luckMultiplier = 1,
		gears = {"bobrito_rusty_medal"},
		brainrots = {
			{"U Din Din Din Din Dun Ma Din Din Din Dun", 2},
			{"Tigrrullini Watermellini", 2}
		}
	},
	[1374405825] = {
		name = "Quick Roll",
		luckMultiplier = 1,
		gears = {},
		brainrots = {}
	}
}

local playerGamepassData = {}

-- Fixed updatePlayerLuckBoost function
local function updatePlayerLuckBoost(userId)
	print("?? Updating luck boost for userId:", userId)

	local player = Players:GetPlayerByUserId(userId)
	if not player then
		print("? Player not found for userId:", userId)
		return
	end

	local totalLuckMultiplier = 1
	local data = playerGamepassData[userId]

	if data and data.gamepasses then
		for gamepassId, gamepassInfo in pairs(data.gamepasses) do
			if gamepassInfo.owned then
				local config = GAMEPASSES[gamepassId]
				if config and config.luckMultiplier then
					totalLuckMultiplier = totalLuckMultiplier * config.luckMultiplier
					print("? Applied luck from gamepass:", config.name, "Multiplier:", config.luckMultiplier)
				end
			end
		end
	end

	local luckBoostPercentage = (totalLuckMultiplier - 1) * 100
	print("?? Final luck boost for", player.Name, ":", luckBoostPercentage, "%")

	-- Update the luck system
	if _G.updateGamepassLuckBoost then
		_G.updateGamepassLuckBoost(luckBoostPercentage)
		print("? Updated _G.updateGamepassLuckBoost")
	end

	-- Also try other luck update methods
	local LuckBoostEvent = ReplicatedStorage:FindFirstChild("LuckBoostEvent")
	if LuckBoostEvent then
		pcall(function()
			LuckBoostEvent:FireClient(player, luckBoostPercentage, 0)
		end)
		print("? Fired LuckBoostEvent")
	end
end

-- Save player data
local function savePlayerData(userId)
	local data = playerGamepassData[userId]
	if not data then return end

	local success, err = pcall(function()
		GamepassDataStore:SetAsync("player_" .. userId, data)
	end)

	if not success then
		warn("? Failed to save gamepass data for userId " .. userId .. ":", err)
	else
		print("? Saved gamepass data for userId:", userId)
	end
end

-- Load player data
local function loadPlayerData(userId)
	local success, data = pcall(function()
		return GamepassDataStore:GetAsync("player_" .. userId)
	end)

	if success and data then
		playerGamepassData[userId] = data
		print("? Loaded existing gamepass data for userId:", userId)
	else
		playerGamepassData[userId] = {
			gamepasses = {},
			giftedItems = {},
			lastUpdate = os.time()
		}
		print("?? Created new gamepass data for userId:", userId)
	end

	return playerGamepassData[userId]
end

-- Give gear to player
local function giveGearToPlayer(player, gearId)
	print("?? Attempting to give gear to", player.Name, "- Gear ID:", gearId)

	-- Try multiple methods to give gear
	local success = false
	local methods = {}

	-- Method 1: Use gear system directly
	if _G.GetPlayerGearData then
		local gearData = _G.GetPlayerGearData(player.UserId)
		if gearData then
			if not gearData.gearInventory then
				gearData.gearInventory = {}
			end

			-- Check if player already has this gear
			local hasGear = false
			for _, ownedGearId in ipairs(gearData.gearInventory) do
				if ownedGearId == gearId then
					hasGear = true
					break
				end
			end

			if not hasGear then
				table.insert(gearData.gearInventory, gearId)
				success = true
				table.insert(methods, "Direct gear system")
				print("? Added gear via direct gear system")

				-- Save gear data
				if _G.SavePlayerGearData then
					_G.SavePlayerGearData(player)
				end
			else
				print("?? Player already has gear:", gearId)
				success = true
			end
		end
	end

	-- Method 2: Try GearRemotes
	if not success then
		local GearRemotes = ReplicatedStorage:FindFirstChild("GearRemotes")
		if GearRemotes then
			local AddGear = GearRemotes:FindFirstChild("AddGear")
			if AddGear and AddGear:IsA("RemoteFunction") then
				local gearSuccess = pcall(function()
					return AddGear:InvokeServer(player, gearId)
				end)
				if gearSuccess then
					success = true
					table.insert(methods, "GearRemotes")
					print("? Added gear via GearRemotes")
				end
			end
		end
	end

	-- Method 3: Force add to gear inventory table
	if not success and _G.playerData and _G.playerData[player.UserId] then
		local playerData = _G.playerData[player.UserId]
		if not playerData.gearInventory then
			playerData.gearInventory = {}
		end

		local hasGear = false
		for _, ownedGearId in ipairs(playerData.gearInventory) do
			if ownedGearId == gearId then
				hasGear = true
				break
			end
		end

		if not hasGear then
			table.insert(playerData.gearInventory, gearId)
			success = true
			table.insert(methods, "Force playerData")
			print("? Added gear via force playerData method")
		end
	end

	if success then
		print("?? Successfully gave gear", gearId, "to", player.Name, "using methods:", table.concat(methods, ", "))
		return true
	else
		warn("? Failed to give gear", gearId, "to", player.Name, "- All methods failed")
		return false
	end
end

-- Give brainrot to player
local function giveBrainrotToPlayer(player, brainrotName, amount)
	print("?? Giving", amount, "x", brainrotName, "to", player.Name)

	if _G.AddItemToInventory then
		for i = 1, amount do
			_G.AddItemToInventory(player.UserId, brainrotName)
		end
		print("? Added brainrots via _G.AddItemToInventory")
		return true
	end

	local InventoryRemotes = ReplicatedStorage:FindFirstChild("InventoryRemotes")
	if InventoryRemotes then
		local AddBrainrotItem = InventoryRemotes:FindFirstChild("AddBrainrotItem")
		if AddBrainrotItem then
			for i = 1, amount do
				AddBrainrotItem:FireServer(brainrotName)
			end
			print("? Added brainrots via InventoryRemotes")
			return true
		end
	end

	warn("? Failed to give brainrots - no inventory system found")
	return false
end

-- Process gamepass benefits
local function processGamepassBenefits(player, gamepassId, grantedBy)
	local userId = player.UserId
	local config = GAMEPASSES[gamepassId]

	if not config then
		warn("? Unknown gamepass ID:", gamepassId)
		return false
	end

	print("?? Processing benefits for", config.name, "for player", player.Name)

	local data = playerGamepassData[userId]
	if not data then
		data = loadPlayerData(userId)
	end

	-- Mark gamepass as owned
	if not data.gamepasses[gamepassId] then
		data.gamepasses[gamepassId] = {}
	end

	data.gamepasses[gamepassId].owned = true
	data.gamepasses[gamepassId].purchaseDate = os.time()
	data.gamepasses[gamepassId].grantedBy = grantedBy or "purchase"

	-- Give gears
	if config.gears and #config.gears > 0 then
		print("?? Giving gears:", table.concat(config.gears, ", "))
		for _, gearId in ipairs(config.gears) do
			local gearKey = gamepassId .. "_gear_" .. gearId
			if not data.giftedItems[gearKey] then
				local success = giveGearToPlayer(player, gearId)
				if success then
					data.giftedItems[gearKey] = os.time()
					print("? Successfully gave gear:", gearId)
				else
					warn("? Failed to give gear:", gearId)
				end
			else
				print("?? Gear already given:", gearId)
			end
		end
	end

	-- Give brainrots
	if config.brainrots and #config.brainrots > 0 then
		print("?? Giving brainrots:")
		for _, brainrotInfo in ipairs(config.brainrots) do
			local brainrotName = brainrotInfo[1]
			local amount = brainrotInfo[2] or 1

			local brainrotKey = gamepassId .. "_brainrot_" .. brainrotName
			if not data.giftedItems[brainrotKey] then
				local success = giveBrainrotToPlayer(player, brainrotName, amount)
				if success then
					data.giftedItems[brainrotKey] = os.time()
					print("? Successfully gave", amount, "x", brainrotName)
				else
					warn("? Failed to give brainrot:", brainrotName)
				end
			else
				print("?? Brainrot already given:", brainrotName)
			end
		end
	end

	-- Update luck boost
	updatePlayerLuckBoost(userId)

	-- Save data
	savePlayerData(userId)

	-- Notify client
	spawn(function()
		wait(1)
		if player and player.Parent then
			GamepassBenefitsApplied:FireClient(player, gamepassId, config.name)
			UpdateGamepassUI:FireClient(player)
		end
	end)

	print("?? Finished processing benefits for", config.name)
	return true
end

-- Check if player owns gamepass
local function checkGamepassOwnership(player, gamepassId)
	-- First check our data
	local data = playerGamepassData[player.UserId]
	if data and data.gamepasses and data.gamepasses[gamepassId] and data.gamepasses[gamepassId].owned then
		return true
	end

	-- Then check with Roblox
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)

	if success and owns then
		-- Player owns it but we don't have it recorded - process benefits
		processGamepassBenefits(player, gamepassId, "retroactive")
		return true
	end

	return false
end

-- Handle gamepass purchase
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if wasPurchased then
		print("?? Gamepass purchased:", gamepassId, "by", player.Name)

		-- Wait a moment for the purchase to process
		wait(2)

		-- Verify the purchase
		local success, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
		end)

		if success and owns then
			processGamepassBenefits(player, gamepassId, "purchase")
		else
			warn("? Purchase verification failed for", player.Name, "gamepass", gamepassId)
		end
	end
end)

-- Player events
Players.PlayerAdded:Connect(function(player)
	print("?? Player joined:", player.Name)

	-- Load their data
	loadPlayerData(player.UserId)

	-- Check all gamepasses they might own
	spawn(function()
		wait(3) -- Wait for other systems to load

		for gamepassId, config in pairs(GAMEPASSES) do
			local owns = checkGamepassOwnership(player, gamepassId)
			if owns then
				print("?", player.Name, "owns", config.name)
			end
		end

		-- Update their luck
		updatePlayerLuckBoost(player.UserId)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player.UserId)
	playerGamepassData[player.UserId] = nil
end)

-- Remote function
CheckGamepassOwnership.OnServerInvoke = function(player, gamepassId)
	return checkGamepassOwnership(player, gamepassId)
end

-- Global functions
_G.CheckPlayerGamepassOwnership = checkGamepassOwnership
_G.GrantGamepassToPlayer = function(player, gamepassId, grantedBy)
	return processGamepassBenefits(player, gamepassId, grantedBy or "admin")
end
_G.GetPlayerGamepassData = function(player)
	return playerGamepassData[player.UserId]
end

print("?? Unified Gamepass System loaded successfully!")