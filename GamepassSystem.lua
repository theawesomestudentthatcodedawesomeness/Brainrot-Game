-- Script: ServerScriptService>GamepassSystem (UPDATED)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GamepassDataStore = DataStoreService:GetDataStore("PlayerGamepassData_v5") -- Updated version
print("?? FIXED GAMEPASS SYSTEM LOADING - No Duplicate Items...")

-- Create remotes function (keep existing)
local function createRemotes()
	local GamepassRemotes = ReplicatedStorage:FindFirstChild("GamepassRemotes") or Instance.new("Folder")
	GamepassRemotes.Name = "GamepassRemotes"
	GamepassRemotes.Parent = ReplicatedStorage

	for _, child in pairs(GamepassRemotes:GetChildren()) do
		child:Destroy()
	end

	local CheckGamepassOwnership = Instance.new("RemoteFunction")
	CheckGamepassOwnership.Name = "CheckGamepassOwnership"
	CheckGamepassOwnership.Parent = GamepassRemotes

	local GetOwnedGamepasses = Instance.new("RemoteFunction")
	GetOwnedGamepasses.Name = "GetOwnedGamepasses"
	GetOwnedGamepasses.Parent = GamepassRemotes

	local UpdateGamepassUI = Instance.new("RemoteEvent")
	UpdateGamepassUI.Name = "UpdateGamepassUI"
	UpdateGamepassUI.Parent = ReplicatedStorage

	local GamepassBenefitsApplied = Instance.new("RemoteEvent")
	GamepassBenefitsApplied.Name = "GamepassBenefitsApplied"
	GamepassBenefitsApplied.Parent = ReplicatedStorage

	local PotionSpawnNotification = Instance.new("RemoteEvent")
	PotionSpawnNotification.Name = "PotionSpawnNotification"
	PotionSpawnNotification.Parent = ReplicatedStorage

	local UpdateGamepassBenefits = Instance.new("RemoteEvent")
	UpdateGamepassBenefits.Name = "UpdateGamepassBenefits"
	UpdateGamepassBenefits.Parent = GamepassRemotes

	return {
		CheckGamepassOwnership = CheckGamepassOwnership,
		GetOwnedGamepasses = GetOwnedGamepasses,
		UpdateGamepassUI = UpdateGamepassUI,
		GamepassBenefitsApplied = GamepassBenefitsApplied,
		PotionSpawnNotification = PotionSpawnNotification,
		UpdateGamepassBenefits = UpdateGamepassBenefits
	}
end

local remotes = createRemotes()

-- Updated gamepass configuration
local GAMEPASSES = {
	[1376797718] = {
		name = "Matteoooo's VIP",
		benefits = {
			luckMultiplier = 2.0,
			luckPotionDetector = true,
			gears = {"time_stop_sandals"},
			chatTag = "[Matteoooooo]",
			potionNotifications = true
		}
	},
	[1378491109] = {
		name = "VIP",
		benefits = {
			luckMultiplier = 1.25,
			gears = {"blueberry_octopus_necklace"},
			chatTag = "[VIP]"
		}
	},
	[1374214026] = {
		name = "Starter Pack",
		benefits = {
			gears = {"bobrito_rusty_medal"},
			brainrots = {
				["U Din Din Din Din Dun Ma Din Din Din Dun"] = 1,
				["Tigrrullini Watermellini"] = 2
			}
		}
	},
	[1374405825] = {
		name = "Quick Roll",
		benefits = {
			quickRoll = true
		}
	}
}

local ADMIN_LEVELS = {
	[377361486] = {name = "Admin1", level = 3},
	[7180677868] = {name = "Admin2", level = 2},
	[168722593] = {name = "Admin3", level = 6},
	[299245694] = {name = "Admin4", level = 1},
	[1710943863] = {name = "i0nii_Chann", level = 50},
}

local playerGamepassData = {}
local dataLoadPromises = {}
local activeLuckBonuses = {}

local function getDefaultData()
	return {
		gamepasses = {},
		itemsGranted = {}, -- NEW: Track which items have been granted
		lastUpdated = os.time(),
		version = 5 -- Updated version
	}
end

local function safeDataStoreCall(operation, ...)
	local success, result = pcall(operation, ...)
	if success then
		return true, result
	else
		warn("? DataStore Error: " .. tostring(result))
		return false, result
	end
end

local savePlayerData, checkOwnership, applyPassiveBenefits, calculatePlayerBenefits
local loadPlayerData, grantGamepass, showBenefitsNotification

checkOwnership = function(player, gamepassId)
	local userId = player.UserId
	local data = playerGamepassData[userId]
	if not data then
		return false
	end
	return data.gamepasses[gamepassId] and data.gamepasses[gamepassId].owned == true
end

savePlayerData = function(player, immediate)
	if not player or not player.Parent then
		return false
	end

	local userId = player.UserId
	local data = playerGamepassData[userId]
	if not data then
		return false
	end

	data.lastUpdated = os.time()

	local success, error = safeDataStoreCall(function()
		return GamepassDataStore:SetAsync("player_" .. userId, data)
	end)

	if success then
		print("? Successfully saved gamepass data for " .. player.Name)
		return true
	else
		warn("? Failed to save gamepass data for " .. player.Name .. ": " .. tostring(error))
		return false
	end
end

-- NEW: Function to check if items have been granted
local function hasReceivedItems(player, gamepassId)
	local userId = player.UserId
	local data = playerGamepassData[userId]
	if not data or not data.itemsGranted then
		return false
	end
	return data.itemsGranted[gamepassId] == true
end

-- NEW: Function to mark items as granted
local function markItemsAsGranted(player, gamepassId)
	local userId = player.UserId
	local data = playerGamepassData[userId]
	if not data then
		return
	end

	if not data.itemsGranted then
		data.itemsGranted = {}
	end

	data.itemsGranted[gamepassId] = true
	print("?? MARKED items as granted for gamepass " .. gamepassId .. " for " .. player.Name)
end

-- UPDATED: Function to give gamepass items (only once)
local function giveGamepassItems(player, gamepassId, config)
	-- Check if items have already been granted
	if hasReceivedItems(player, gamepassId) then
		print("?? SKIPPING item grant for " .. config.name .. " - already given to " .. player.Name)
		return
	end

	print("?? GIVING ITEMS (FIRST TIME ONLY) for " .. config.name .. " to " .. player.Name)

	-- Give gears
	if config.benefits.gears then
		if _G.GetPlayerGearData then
			local gearData = _G.GetPlayerGearData(player.UserId)
			if gearData then
				if not gearData.gearInventory then
					gearData.gearInventory = {}
				end

				for _, gearId in ipairs(config.benefits.gears) do
					-- Check if player already has this gear
					local alreadyHas = false
					for _, ownedGear in ipairs(gearData.gearInventory) do
						if ownedGear == gearId then
							alreadyHas = true
							break
						end
					end

					if not alreadyHas then
						table.insert(gearData.gearInventory, gearId)
						print("?? Gave gear " .. gearId .. " to " .. player.Name)
					else
						print("?? Player " .. player.Name .. " already has gear " .. gearId)
					end
				end

				-- Save gear data
				if _G.SavePlayerGearData then
					_G.SavePlayerGearData(player)
				end
			end
		else
			warn("? Gear system not available for " .. player.Name)
		end
	end

	-- Give brainrots
	if config.benefits.brainrots then
		local inventoryRemotes = ReplicatedStorage:FindFirstChild("InventoryRemotes")
		if inventoryRemotes and inventoryRemotes:FindFirstChild("AddBrainrotItem") then
			for brainrotName, amount in pairs(config.benefits.brainrots) do
				for i = 1, amount do
					spawn(function()
						wait(0.1 * i) -- Small delay between each item
						if _G.AddItemToInventory then
							_G.AddItemToInventory(player.UserId, brainrotName)
							print("?? Gave brainrot " .. brainrotName .. " (" .. i .. "/" .. amount .. ") to " .. player.Name)
						end
					end)
				end
			end
		else
			warn("? Inventory system not available for " .. player.Name)
		end
	end

	-- Mark items as granted
	markItemsAsGranted(player, gamepassId)
end

applyPassiveBenefits = function(player)
	local userId = player.UserId
	local data = playerGamepassData[userId]
	if not data then
		return
	end

	print("?? Applying passive benefits to " .. player.Name)
	activeLuckBonuses[userId] = 1

	for gamepassId, gamepassInfo in pairs(data.gamepasses) do
		if gamepassInfo.owned and GAMEPASSES[gamepassId] then
			local config = GAMEPASSES[gamepassId]

			if config.benefits.luckMultiplier then
				activeLuckBonuses[userId] = activeLuckBonuses[userId] * config.benefits.luckMultiplier
				print("?? Applied " .. config.benefits.luckMultiplier .. "x luck from " .. config.name .. " to " .. player.Name)
			end
		end
	end

	remotes.UpdateGamepassBenefits:FireClient(player, calculatePlayerBenefits(player))
end

calculatePlayerBenefits = function(player)
	local benefits = {
		luckMultiplier = 1.0,
		luckPotionDetector = false,
		quickRoll = false,
		chatTag = nil,
		ownedGamepasses = {}
	}

	local userId = player.UserId
	if not playerGamepassData[userId] then
		return benefits
	end

	for gamepassId, gamepassInfo in pairs(playerGamepassData[userId].gamepasses) do
		if gamepassInfo.owned and GAMEPASSES[gamepassId] then
			local gamepassBenefits = GAMEPASSES[gamepassId].benefits
			benefits.ownedGamepasses[gamepassId] = true

			if gamepassBenefits.luckMultiplier then
				benefits.luckMultiplier = benefits.luckMultiplier * gamepassBenefits.luckMultiplier
			end

			if gamepassBenefits.luckPotionDetector then
				benefits.luckPotionDetector = true
			end

			if gamepassBenefits.quickRoll then
				benefits.quickRoll = true
			end

			if gamepassBenefits.chatTag then
				benefits.chatTag = gamepassBenefits.chatTag
			end
		end
	end

	return benefits
end

showBenefitsNotification = function(player, gamepassId, gamepassName)
	remotes.GamepassBenefitsApplied:FireClient(player, gamepassId, gamepassName)
end

loadPlayerData = function(player)
	local userId = player.UserId
	print("?? Loading gamepass data for " .. player.Name .. " (FIXED VERSION)")

	local success, data = safeDataStoreCall(function()
		return GamepassDataStore:GetAsync("player_" .. userId)
	end)

	if success and data then
		playerGamepassData[userId] = data

		-- Ensure new fields exist
		if not playerGamepassData[userId].itemsGranted then
			playerGamepassData[userId].itemsGranted = {}
		end
		if not playerGamepassData[userId].version or playerGamepassData[userId].version < 5 then
			playerGamepassData[userId].version = 5
			-- Don't reset itemsGranted - let existing data persist
		end

		print("? Loaded existing gamepass data for " .. player.Name)

		local ownedList = {}
		for gamepassId, info in pairs(data.gamepasses) do
			if info.owned and GAMEPASSES[gamepassId] then
				table.insert(ownedList, GAMEPASSES[gamepassId].name)
			end
		end

		if #ownedList > 0 then
			print("?? " .. player.Name .. " owns: " .. table.concat(ownedList, ", "))

			-- Show items granted status
			for gamepassId, info in pairs(data.gamepasses) do
				if info.owned and GAMEPASSES[gamepassId] then
					local hasItems = hasReceivedItems(player, gamepassId)
					print("?? " .. GAMEPASSES[gamepassId].name .. " items granted: " .. tostring(hasItems))
				end
			end
		end
	else
		playerGamepassData[userId] = getDefaultData()
		print("?? Created new gamepass data for " .. player.Name)
	end

	spawn(function()
		wait(1)
		applyPassiveBenefits(player)
		if player and player.Parent then
			remotes.UpdateGamepassUI:FireClient(player)
		end
	end)
end

grantGamepass = function(player, gamepassId, grantedBy)
	local userId = player.UserId
	local data = playerGamepassData[userId]
	if not data then
		data = getDefaultData()
		playerGamepassData[userId] = data
	end

	if data.gamepasses[gamepassId] and data.gamepasses[gamepassId].owned then
		return false, "Player already owns this gamepass"
	end

	local config = GAMEPASSES[gamepassId]
	if not config then
		return false, "Invalid gamepass ID"
	end

	data.gamepasses[gamepassId] = {
		owned = true,
		purchaseDate = os.time(),
		grantedBy = grantedBy or "admin"
	}

	print("?? Granted gamepass " .. gamepassId .. " (" .. config.name .. ") to " .. player.Name .. " by " .. tostring(grantedBy))

	-- Give items (will check if already granted)
	giveGamepassItems(player, gamepassId, config)

	applyPassiveBenefits(player)
	showBenefitsNotification(player, gamepassId, config.name)

	local success = savePlayerData(player, true)
	if success then
		if player and player.Parent then
			remotes.UpdateGamepassUI:FireClient(player)
		end
		return true, "Successfully granted gamepass and applied benefits"
	else
		return false, "Failed to save gamepass data"
	end
end

-- Remote function handlers
remotes.CheckGamepassOwnership.OnServerInvoke = function(player, gamepassId)
	return checkOwnership(player, gamepassId)
end

remotes.GetOwnedGamepasses.OnServerInvoke = function(player)
	local userId = player.UserId
	local data = playerGamepassData[userId]
	if not data then
		return {}
	end

	local ownedList = {}
	for gamepassId, info in pairs(data.gamepasses) do
		if info.owned then
			table.insert(ownedList, {
				id = gamepassId,
				name = GAMEPASSES[gamepassId] and GAMEPASSES[gamepassId].name or "Unknown",
				purchaseDate = info.purchaseDate,
				grantedBy = info.grantedBy,
				itemsGranted = hasReceivedItems(player, gamepassId)
			})
		end
	end

	return ownedList
end

-- Purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if wasPurchased and GAMEPASSES[gamepassId] then
		print("?? Player " .. player.Name .. " purchased gamepass " .. gamepassId .. " (" .. GAMEPASSES[gamepassId].name .. ")")

		local userId = player.UserId
		local data = playerGamepassData[userId]
		if not data then
			data = getDefaultData()
			playerGamepassData[userId] = data
		end

		data.gamepasses[gamepassId] = {
			owned = true,
			purchaseDate = os.time(),
			grantedBy = "purchase"
		}

		local config = GAMEPASSES[gamepassId]

		-- Give items (will check if already granted)
		giveGamepassItems(player, gamepassId, config)

		applyPassiveBenefits(player)
		showBenefitsNotification(player, gamepassId, config.name)

		savePlayerData(player, true)

		if player and player.Parent then
			remotes.UpdateGamepassUI:FireClient(player)
		end
	end
end)

-- Player event handlers
Players.PlayerAdded:Connect(function(player)
	print("?? Player " .. player.Name .. " joined - loading gamepass data...")
	dataLoadPromises[player.UserId] = true

	wait(2)
	spawn(function()
		loadPlayerData(player)
		dataLoadPromises[player.UserId] = nil

		wait(1)
		if player and player.Parent then
			remotes.UpdateGamepassBenefits:FireClient(player, calculatePlayerBenefits(player))
		end
	end)

	-- Admin command handler
	player.Chatted:Connect(function(message)
		if message:sub(1, 1) == "/" then
			local response = processAdminCommand(player, message)
			if response then
				print("[ADMIN] " .. player.Name .. ": " .. response)
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	print("?? Player " .. player.Name .. " leaving - saving gamepass data...")
	savePlayerData(player, true)

	spawn(function()
		wait(5)
		playerGamepassData[player.UserId] = nil
		dataLoadPromises[player.UserId] = nil
		activeLuckBonuses[player.UserId] = nil
	end)
end)

-- Auto-save
spawn(function()
	while true do
		wait(300) -- Save every 5 minutes
		for _, player in pairs(Players:GetPlayers()) do
			if playerGamepassData[player.UserId] then
				spawn(function()
					savePlayerData(player, false)
				end)
			end
		end
	end
end)

-- Shutdown handler
game:BindToClose(function()
	print("?? Game shutting down - saving all gamepass data...")
	for _, player in pairs(Players:GetPlayers()) do
		if playerGamepassData[player.UserId] then
			savePlayerData(player, true)
		end
	end
	wait(3)
	print("? Gamepass system shutdown complete")
end)

-- Admin command processing function
function processAdminCommand(player, message)
	local args = string.split(message:lower(), " ")
	local command = args[1]
	local adminLevel = ADMIN_LEVELS[player.UserId] or 0

	if adminLevel < 5 then
		return
	end

	if command == "/resetitems" and #args >= 2 then
		local targetName = args[2]
		local targetPlayer = nil

		for _, p in ipairs(Players:GetPlayers()) do
			if p.Name:lower():find(targetName:lower()) then
				targetPlayer = p
				break
			end
		end

		if not targetPlayer then
			return "? Player not found: " .. targetName
		end

		local data = playerGamepassData[targetPlayer.UserId]
		if data then
			data.itemsGranted = {} -- Reset item grants
			savePlayerData(targetPlayer, true)
			return "? Reset item grants for " .. targetPlayer.Name .. " - they will receive items again"
		else
			return "? No gamepass data found for " .. targetPlayer.Name
		end

	elseif command == "/checkitems" and #args >= 2 then
		local targetName = args[2]
		local targetPlayer = nil

		for _, p in ipairs(Players:GetPlayers()) do
			if p.Name:lower():find(targetName:lower()) then
				targetPlayer = p
				break
			end
		end

		if not targetPlayer then
			return "? Player not found: " .. targetName
		end

		local data = playerGamepassData[targetPlayer.UserId]
		if data and data.itemsGranted then
			local result = "?? Item grant status for " .. targetPlayer.Name .. ":\n"
			for gamepassId, granted in pairs(data.itemsGranted) do
				local gamepassName = GAMEPASSES[gamepassId] and GAMEPASSES[gamepassId].name or "Unknown"
				result = result .. "• " .. gamepassName .. ": " .. (granted and "? Granted" or "? Not granted") .. "\n"
			end
			return result
		else
			return "? No item grant data found for " .. targetPlayer.Name
		end
	end
end

-- Global functions
_G.GrantGamepassToPlayer = function(player, gamepassId, grantedBy)
	return grantGamepass(player, gamepassId, grantedBy)
end

_G.CheckPlayerGamepassOwnership = function(player, gamepassId)
	return checkOwnership(player, gamepassId)
end

_G.GetPlayerGamepassData = function(player)
	return playerGamepassData[player.UserId]
end

_G.GetPlayerChatTag = function(player)
	local benefits = calculatePlayerBenefits(player)
	return benefits.chatTag
end

_G.GetPlayerLuckMultiplier = function(player)
	local benefits = calculatePlayerBenefits(player)
	return benefits.luckMultiplier
end

_G.HasPotionNotifications = function(player)
	return checkOwnership(player, 1376797718)
end

_G.NotifyPotionSpawn = function(position)
	for _, player in pairs(Players:GetPlayers()) do
		if checkOwnership(player, 1376797718) then
			remotes.PotionSpawnNotification:FireClient(player, position)
		end
	end
end

_G.ownsGamepass = checkOwnership
_G.getPlayerLuckMultiplier = _G.GetPlayerLuckMultiplier

print("? FIXED GAMEPASS SYSTEM LOADED SUCCESSFULLY!")
print("?? Available gamepasses:")
for id, config in pairs(GAMEPASSES) do
	print(" - " .. config.name .. " (ID: " .. id .. ")")
end
print("?? Admin commands: /resetitems <player>, /checkitems <player>")
print("?? Items will only be given ONCE per gamepass!")
print("?? Use /resetitems to allow items to be given again for testing")