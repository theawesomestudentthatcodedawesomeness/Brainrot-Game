-- Place in ServerScriptService as a ModuleScript
-- AdminCommandModule - Complete with All Commands + Gamepass Support (FIXED SPAWNPOTIONS)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local BrainrotDefinitions = require(ReplicatedStorage:WaitForChild("BrainrotDefinitions"))

local AdminCommandModule = {}

-- Admin configuration
local ADMINS = {
	[377361486] = {name = "Admin1", level = 3},
	[7180677868] = {name = "Admin2", level = 2}, 
	[168722593] = {name = "Admin3", level = 6},
	[299245694] = {name = "Admin4", level = 1},
	[1710943863] = {name = "i0nii_Chann", level = 50}, -- Your username with level 50
	[1055799825] = {name = "juliovetta16", level = 50}, -- Current user with level 50
}

-- Create RemoteEvents for GUI
local AdminGUIRemotes = ReplicatedStorage:FindFirstChild("AdminGUIRemotes") or Instance.new("Folder")
AdminGUIRemotes.Name = "AdminGUIRemotes"
AdminGUIRemotes.Parent = ReplicatedStorage

-- Clear existing remotes to prevent conflicts
for _, child in pairs(AdminGUIRemotes:GetChildren()) do
	child:Destroy()
end

local OpenAdminGUI = Instance.new("RemoteEvent")
OpenAdminGUI.Name = "OpenAdminGUI"
OpenAdminGUI.Parent = AdminGUIRemotes

local UpdateAdminLog = Instance.new("RemoteEvent")
UpdateAdminLog.Name = "UpdateAdminLog"
UpdateAdminLog.Parent = AdminGUIRemotes

local SendCommandResult = Instance.new("RemoteEvent")
SendCommandResult.Name = "SendCommandResult"
SendCommandResult.Parent = AdminGUIRemotes

local SendCommandOutput = Instance.new("RemoteEvent")
SendCommandOutput.Name = "SendCommandOutput"
SendCommandOutput.Parent = AdminGUIRemotes

-- Rate limiting
local commandCooldowns = {}
local COOLDOWN_TIME = 2 -- seconds
local MAX_COMMANDS_PER_MINUTE = 20

-- Logging
local commandLogs = {}
local MAX_LOG_ENTRIES = 1000

-- Output capture for GUI
local printOutputBuffer = {}

-- Helper functions
local function isAdmin(userId)
	return ADMINS[userId] ~= nil
end

local function getAdminLevel(userId)
	local admin = ADMINS[userId]
	return admin and admin.level or 0
end

local function canUseGUI(userId)
	return getAdminLevel(userId) >= 5
end

local function canUseCommand(userId)
	local now = tick()
	local cooldownKey = tostring(userId)

	-- Check cooldown
	if commandCooldowns[cooldownKey] and now - commandCooldowns[cooldownKey] < COOLDOWN_TIME then
		return false, "Command on cooldown"
	end

	-- Check rate limit
	local commandsInLastMinute = 0
	for i = #commandLogs, 1, -1 do
		local log = commandLogs[i]
		if log.userId == userId and now - log.timestamp < 60 then
			commandsInLastMinute = commandsInLastMinute + 1
		else
			break
		end
	end

	if commandsInLastMinute >= MAX_COMMANDS_PER_MINUTE then
		return false, "Rate limit exceeded"
	end

	return true
end

-- Output capture functions
local function captureOutput(userId, text)
	if not printOutputBuffer[userId] then
		printOutputBuffer[userId] = {}
	end
	table.insert(printOutputBuffer[userId], text)
end

local function getAndClearOutput(userId)
	local output = printOutputBuffer[userId] or {}
	printOutputBuffer[userId] = {}
	return output
end

local function adminPrint(userId, text)
	print(text) -- Still print to server console
	captureOutput(userId, text) -- Also capture for GUI
end

local function logCommand(userId, command, success, error, fullOutput)
	local logEntry = {
		userId = userId,
		command = command,
		success = success,
		error = error,
		fullOutput = fullOutput or {},
		timestamp = tick(),
		timeString = os.date("%H:%M:%S", tick())
	}

	table.insert(commandLogs, logEntry)

	-- Trim logs if needed
	if #commandLogs > MAX_LOG_ENTRIES then
		table.remove(commandLogs, 1)
	end

	-- Print to console
	local admin = ADMINS[userId]
	local adminName = admin and admin.name or "Unknown"
	local status = success and "SUCCESS" or "FAILED"
	local logMessage = string.format("[ADMIN] %s (%d) %s: %s %s", 
		adminName, userId, status, command, error or "")
	print(logMessage)

	-- Send to GUI for all level 5+ admins
	for _, player in pairs(Players:GetPlayers()) do
		if canUseGUI(player.UserId) then
			UpdateAdminLog:FireClient(player, logEntry)
		end
	end
end

local function sendCommandResult(adminPlayer, success, message, fullOutput)
	if canUseGUI(adminPlayer.UserId) then
		SendCommandResult:FireClient(adminPlayer, success, message)
		if fullOutput and #fullOutput > 0 then
			SendCommandOutput:FireClient(adminPlayer, fullOutput)
		end
	end
end

local function findPlayer(partialName)
	partialName = partialName:lower()

	-- Exact match first
	for _, player in pairs(Players:GetPlayers()) do
		if player.Name:lower() == partialName then
			return player
		end
	end

	-- Partial match
	local matches = {}
	for _, player in pairs(Players:GetPlayers()) do
		if player.Name:lower():find(partialName, 1, true) then
			table.insert(matches, player)
		end
	end

	if #matches == 1 then
		return matches[1]
	elseif #matches > 1 then
		return nil, "Multiple players found"
	else
		return nil, "Player not found"
	end
end

-- Command handlers - ALL COMMANDS
local commands = {}

commands.givebrainrot = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if #args < 2 then
		return false, "Usage: !givebrainrot <player> <brainrot_name> [amount]"
	end

	local targetPlayer, findError = findPlayer(args[1])
	if not targetPlayer then
		return false, findError or "Target player not found"
	end

	local brainrotName = table.concat(args, " ", 2, #args - (#args >= 3 and 1 or 0))
	local amount = 1

	-- Check if last arg is a number
	if #args >= 3 and tonumber(args[#args]) then
		amount = tonumber(args[#args])
		-- Rebuild brainrot name without the amount
		brainrotName = table.concat(args, " ", 2, #args - 1)
	end

	-- Validate amount
	if amount < 1 or amount > 100 then
		return false, "Amount must be between 1 and 100"
	end

	-- Validate brainrot exists
	if not BrainrotDefinitions.Lookup[brainrotName] then
		adminPrint(userId, "? Brainrot '" .. brainrotName .. "' does not exist")
		adminPrint(userId, "?? Use !listbrainrots to see available items")
		return false, "Brainrot '" .. brainrotName .. "' does not exist"
	end

	-- Add to inventory (using global function from InventoryManager)
	local success = false
	if _G.AddItemToInventory then
		adminPrint(userId, "?? Adding " .. amount .. "x '" .. brainrotName .. "' to " .. targetPlayer.Name .. "'s inventory...")
		for i = 1, amount do
			_G.AddItemToInventory(targetPlayer.UserId, brainrotName)
		end
		success = true
		adminPrint(userId, "? Successfully added items to inventory")
	else
		adminPrint(userId, "? Inventory system not available")
		return false, "Inventory system not available"
	end

	if success then
		return true, string.format("Gave %d x '%s' to %s", amount, brainrotName, targetPlayer.Name)
	else
		return false, "Failed to add item to inventory"
	end
end

commands.removebrainrot = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if getAdminLevel(userId) < 2 then
		return false, "Insufficient admin level"
	end

	if #args < 2 then
		return false, "Usage: !removebrainrot <player> <brainrot_name> [amount]"
	end

	local targetPlayer, findError = findPlayer(args[1])
	if not targetPlayer then
		return false, findError or "Target player not found"
	end

	local brainrotName = table.concat(args, " ", 2, #args - (#args >= 3 and 1 or 0))
	local amount = 1

	if #args >= 3 and tonumber(args[#args]) then
		amount = tonumber(args[#args])
		brainrotName = table.concat(args, " ", 2, #args - 1)
	end

	if amount < 1 or amount > 1000 then
		return false, "Amount must be between 1 and 1000"
	end

	adminPrint(userId, "??? Removing " .. amount .. "x '" .. brainrotName .. "' from " .. targetPlayer.Name .. "'s inventory...")

	-- Remove from inventory
	if _G.RemoveItemFromInventory then
		_G.RemoveItemFromInventory(targetPlayer.UserId, brainrotName, amount)
		adminPrint(userId, "? Successfully removed items from inventory")
		return true, string.format("Removed %d x '%s' from %s", amount, brainrotName, targetPlayer.Name)
	else
		adminPrint(userId, "? Inventory system not available")
		return false, "Inventory system not available"
	end
end

-- Give gear command (Roblox catalog items)
commands.givegear = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if getAdminLevel(userId) < 2 then
		return false, "Insufficient admin level"
	end

	if #args < 2 then
		return false, "Usage: !givegear <player> <gear_id>"
	end

	local targetPlayer, findError = findPlayer(args[1])
	if not targetPlayer then
		return false, findError or "Target player not found"
	end

	local gearId = tonumber(args[2])
	if not gearId then
		return false, "Invalid gear ID"
	end

	-- Validate gear ID range
	if gearId < 1 or gearId > 999999999 then
		return false, "Gear ID must be between 1 and 999999999"
	end

	-- Check if player has a character
	if not targetPlayer.Character then
		return false, "Target player has no character"
	end

	adminPrint(userId, "?? Loading gear ID " .. gearId .. " for " .. targetPlayer.Name .. "...")

	-- Try to give the gear
	local success, result = pcall(function()
		local InsertService = game:GetService("InsertService")
		local gear = InsertService:LoadAsset(gearId)

		if gear then
			local tool = gear:FindFirstChildOfClass("Tool")
			if tool then
				tool.Parent = targetPlayer.Backpack
				return true
			else
				return false, "Asset is not a valid gear/tool"
			end
		else
			return false, "Failed to load asset"
		end
	end)

	if success and result then
		adminPrint(userId, "? Successfully gave gear to " .. targetPlayer.Name)
		return true, string.format("Gave gear ID %d to %s", gearId, targetPlayer.Name)
	else
		adminPrint(userId, "? Failed to give gear: " .. tostring(result))
		return false, result or "Failed to give gear"
	end
end

-- Give custom gear (from gear system)
commands.givecustomgear = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if getAdminLevel(userId) < 2 then
		return false, "Insufficient admin level"
	end

	if #args < 2 then
		return false, "Usage: !givecustomgear <player> <gear_name>"
	end

	local targetPlayer, findError = findPlayer(args[1])
	if not targetPlayer then
		return false, findError or "Target player not found"
	end

	local gearName = table.concat(args, " ", 2)

	adminPrint(userId, "?? Looking for custom gear: '" .. gearName .. "'...")

	-- Try to access gear data
	local GearData = ReplicatedStorage:FindFirstChild("GearData")
	if not GearData then
		adminPrint(userId, "? Gear system not available (GearData module not found)")
		return false, "Gear system not available"
	end

	local gearModule = require(GearData)
	if not gearModule or not gearModule.Gears then
		adminPrint(userId, "? Gear data not available (module structure invalid)")
		return false, "Gear data not available"
	end

	-- Find gear by name
	local gearId = nil
	for id, gearInfo in pairs(gearModule.Gears) do
		if gearInfo.name:lower() == gearName:lower() then
			gearId = id
			adminPrint(userId, "? Found gear: " .. gearInfo.name .. " (ID: " .. id .. ")")
			break
		end
	end

	if not gearId then
		adminPrint(userId, "? Gear '" .. gearName .. "' not found")
		adminPrint(userId, "?? Use !listcustomgears to see available gears")
		return false, "Gear '" .. gearName .. "' not found"
	end

	-- Add gear to player's inventory using global function
	if _G.GetPlayerGearData then
		local playerData = _G.GetPlayerGearData(targetPlayer.UserId)
		if playerData then
			if not playerData.gearInventory then
				playerData.gearInventory = {}
			end
			table.insert(playerData.gearInventory, gearId)
			adminPrint(userId, "? Successfully added custom gear to " .. targetPlayer.Name .. "'s inventory")
			return true, string.format("Gave custom gear '%s' to %s", gearName, targetPlayer.Name)
		else
			adminPrint(userId, "? Player gear data not available")
			return false, "Player gear data not available"
		end
	else
		adminPrint(userId, "? Gear system not available (_G.GetPlayerGearData not found)")
		return false, "Gear system not available"
	end
end

-- NEW: Gamepass command
commands.givegamepass = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if getAdminLevel(userId) < 5 then
		return false, "Insufficient admin level (Level 5 required)"
	end

	if #args < 2 then
		return false, "Usage: !givegamepass <player> <gamepass_name>"
	end

	local targetPlayer, findError = findPlayer(args[1])
	if not targetPlayer then
		return false, findError or "Target player not found"
	end

	local gamepassName = table.concat(args, " ", 2)

	adminPrint(userId, "?? Looking for gamepass: '" .. gamepassName .. "'")

	-- Gamepass mapping
	local GAMEPASSES = {
		["quick roll"] = {id = 1374405825, name = "Quick Roll"},
		["matteoooo's vip"] = {id = 1376797718, name = "Matteoooo's VIP"},
		["vip"] = {id = 1378491109, name = "VIP"},
		["starter pack"] = {id = 1374214026, name = "Starter Pack"}
	}

	-- Find gamepass by name (case insensitive)
	local gamepassConfig = nil
	local normalizedName = string.lower(gamepassName)

	for key, config in pairs(GAMEPASSES) do
		if string.lower(key) == normalizedName or string.lower(config.name) == normalizedName then
			gamepassConfig = config
			break
		end
	end

	if not gamepassConfig then
		adminPrint(userId, "? Gamepass '" .. gamepassName .. "' not found")
		adminPrint(userId, "?? Available gamepasses:")
		for key, config in pairs(GAMEPASSES) do
			adminPrint(userId, "   - " .. config.name .. " (ID: " .. config.id .. ")")
		end
		return false, "Gamepass '" .. gamepassName .. "' not found"
	end

	adminPrint(userId, "? Found gamepass: " .. gamepassConfig.name .. " (ID: " .. gamepassConfig.id .. ")")

	-- Check if player already owns it
	if _G.CheckPlayerGamepassOwnership and _G.CheckPlayerGamepassOwnership(targetPlayer, gamepassConfig.id) then
		adminPrint(userId, "?? " .. targetPlayer.Name .. " already owns " .. gamepassConfig.name)
		return false, targetPlayer.Name .. " already owns " .. gamepassConfig.name
	end

	-- Grant the gamepass
	if _G.GrantGamepassToPlayer then
		local success, message = _G.GrantGamepassToPlayer(targetPlayer, gamepassConfig.id, adminPlayer.Name)

		if success then
			adminPrint(userId, "?? Successfully granted " .. gamepassConfig.name .. " to " .. targetPlayer.Name)
			return true, string.format("Granted '%s' to %s", gamepassConfig.name, targetPlayer.Name)
		else
			adminPrint(userId, "? Failed to grant gamepass: " .. tostring(message))
			return false, "Failed to grant gamepass: " .. tostring(message)
		end
	else
		adminPrint(userId, "? Gamepass system not available")
		return false, "Gamepass system not available"
	end
end

-- List gamepasses command
commands.listgamepasses = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if getAdminLevel(userId) < 3 then
		return false, "Insufficient admin level (Level 3 required)"
	end

	adminPrint(userId, "?? AVAILABLE GAMEPASSES:")
	adminPrint(userId, "----------------------------------------")

	local GAMEPASSES = {
		{id = 1374405825, name = "Quick Roll", price = 50},
		{id = 1376797718, name = "Matteoooo's VIP", price = 350},
		{id = 1378491109, name = "VIP", price = 150},
		{id = 1374214026, name = "Starter Pack", price = 50}
	}

	for i, gamepass in ipairs(GAMEPASSES) do
		adminPrint(userId, string.format("%d. %s", i, gamepass.name))
		adminPrint(userId, string.format("   ID: %d | Price: %d R$", gamepass.id, gamepass.price))
	end

	adminPrint(userId, "")
	adminPrint(userId, "?? Usage: !givegamepass <player> <gamepass_name>")
	adminPrint(userId, "?? Example: !givegamepass john Quick Roll")

	return true, "Gamepass list displayed - " .. #GAMEPASSES .. " gamepasses available"
end

-- Check player gamepasses command
commands.playergamepasses = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if getAdminLevel(userId) < 3 then
		return false, "Insufficient admin level (Level 3 required)"
	end

	if #args < 1 then
		return false, "Usage: !playergamepasses <player>"
	end

	local targetPlayer, findError = findPlayer(args[1])
	if not targetPlayer then
		return false, findError or "Target player not found"
	end

	adminPrint(userId, "?? GAMEPASS INFO FOR " .. targetPlayer.Name .. ":")
	adminPrint(userId, "----------------------------------------")

	if _G.GetPlayerGamepassData then
		local data = _G.GetPlayerGamepassData(targetPlayer)
		if data and data.gamepasses then
			local count = 0
			local GAMEPASS_NAMES = {
				[1374405825] = "Quick Roll",
				[1376797718] = "Matteoooo's VIP", 
				[1378491109] = "VIP",
				[1374214026] = "Starter Pack"
			}

			for gamepassId, info in pairs(data.gamepasses) do
				if info.owned then
					count = count + 1
					local name = GAMEPASS_NAMES[gamepassId] or "Unknown"
					local date = os.date("%Y-%m-%d %H:%M", info.purchaseDate or 0)
					local source = info.grantedBy or "unknown"

					adminPrint(userId, string.format("? %s (ID: %d)", name, gamepassId))
					adminPrint(userId, string.format("   Acquired: %s | Source: %s", date, source))
				end
			end

			if count == 0 then
				adminPrint(userId, "? No gamepasses owned")
			else
				adminPrint(userId, "")
				adminPrint(userId, "?? Total gamepasses: " .. count)
			end
		else
			adminPrint(userId, "? No gamepass data found")
		end
	else
		adminPrint(userId, "? Gamepass system not available")
		return false, "Gamepass system not available"
	end

	return true, "Gamepass info displayed for " .. targetPlayer.Name
end

-- List custom gears
commands.listcustomgears = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if getAdminLevel(userId) < 2 then
		return false, "Insufficient admin level"
	end

	adminPrint(userId, "?? AVAILABLE CUSTOM GEARS:")
	adminPrint(userId, "---------------------------------------")

	-- Try to access gear data
	local GearData = ReplicatedStorage:FindFirstChild("GearData")
	if not GearData then
		adminPrint(userId, "? Gear system not available")
		return false, "Gear system not available"
	end

	local gearModule = require(GearData)
	if not gearModule or not gearModule.Gears then
		adminPrint(userId, "? Gear data not available")
		return false, "Gear data not available"
	end

	local count = 0
	for id, gearInfo in pairs(gearModule.Gears) do
		count = count + 1
		local rarity = gearInfo.rarity or "Common"
		local luckBoost = gearInfo.luckBoost or 0
		local rollPenalty = gearInfo.rollPenalty or 0

		local rarityIcon = ""
		if rarity == "Legendary" then
			rarityIcon = "??"
		elseif rarity == "Epic" then
			rarityIcon = "??"
		elseif rarity == "Rare" then
			rarityIcon = "??"
		else
			rarityIcon = "?"
		end

		adminPrint(userId, string.format("%d. %s %s (%s)", count, rarityIcon, gearInfo.name, rarity))
		adminPrint(userId, string.format("   +- ID: %s | +%d%% luck | -%d%% roll speed", id, luckBoost, rollPenalty))
	end

	adminPrint(userId, "")
	adminPrint(userId, "?? Total custom gears: " .. count)
	adminPrint(userId, "?? Use: !givecustomgear <player> <gear_name>")

	return true, "Custom gear list displayed - " .. count .. " gears total"
end

-- Set luck command with better error handling
commands.setluck = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if getAdminLevel(userId) < 2 then
		return false, "Insufficient admin level"
	end

	if #args < 2 then
		return false, "Usage: !setluck <player> <luck_amount>"
	end

	local targetPlayer, findError = findPlayer(args[1])
	if not targetPlayer then
		return false, findError or "Target player not found"
	end

	local luckAmount = tonumber(args[2])
	if not luckAmount then
		return false, "Invalid luck amount"
	end

	-- Validate luck amount
	if luckAmount < 0 or luckAmount > 10000 then
		return false, "Luck amount must be between 0 and 10000"
	end

	adminPrint(userId, "?? Setting luck for " .. targetPlayer.Name .. " to " .. luckAmount .. "%")
	adminPrint(userId, "?? Trying multiple luck update methods...")

	-- Try multiple methods to set luck
	local success = false
	local methods = {}

	-- Method 1: Direct global function
	if _G.SetPlayerLuck then
		local methodSuccess = pcall(function()
			_G.SetPlayerLuck(targetPlayer.UserId, luckAmount)
		end)
		if methodSuccess then
			success = true
			table.insert(methods, "SetPlayerLuck")
			adminPrint(userId, "? Method 1: SetPlayerLuck - Success")
		else
			adminPrint(userId, "? Method 1: SetPlayerLuck - Failed")
		end
	else
		adminPrint(userId, "?? Method 1: SetPlayerLuck - Not available")
	end

	-- Method 2: Luck GUI update
	if _G.updateLuckBoost then
		local methodSuccess = pcall(function()
			_G.updateLuckBoost(luckAmount / 100) -- Convert percentage to multiplier
		end)
		if methodSuccess then
			success = true
			table.insert(methods, "updateLuckBoost")
			adminPrint(userId, "? Method 2: updateLuckBoost - Success")
		else
			adminPrint(userId, "? Method 2: updateLuckBoost - Failed")
		end
	else
		adminPrint(userId, "?? Method 2: updateLuckBoost - Not available")
	end

	-- Method 3: Badge luck boost
	if _G.updateBadgeLuckBoost then
		local methodSuccess = pcall(function()
			_G.updateBadgeLuckBoost(luckAmount)
		end)
		if methodSuccess then
			success = true
			table.insert(methods, "updateBadgeLuckBoost")
			adminPrint(userId, "? Method 3: updateBadgeLuckBoost - Success")
		else
			adminPrint(userId, "? Method 3: updateBadgeLuckBoost - Failed")
		end
	else
		adminPrint(userId, "?? Method 3: updateBadgeLuckBoost - Not available")
	end

	if success then
		local methodList = table.concat(methods, ", ")
		adminPrint(userId, "?? Successfully set " .. targetPlayer.Name .. "'s luck to " .. luckAmount .. "% using: " .. methodList)
		return true, string.format("Set %s's luck to %d%% (methods: %s)", targetPlayer.Name, luckAmount, methodList)
	else
		adminPrint(userId, "? All luck methods failed - system not available")
		return false, "Luck system not available"
	end
end

-- FIXED: Force spawn potions command - no more green blocks!
commands.spawnpotions = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if getAdminLevel(userId) < 3 then
		return false, "Insufficient admin level (Level 3 required)"
	end

	adminPrint(userId, "?? Starting potion spawn process...")

	-- Debug: Check if LuckPotionSystem is loaded
	adminPrint(userId, "?? Checking _G.ForceSpawnAllPotions: " .. tostring(_G.ForceSpawnAllPotions ~= nil))

	if _G.ForceSpawnAllPotions then
		adminPrint(userId, "? Found LuckPotionSystem - attempting spawn...")

		local success, result = pcall(function()
			return _G.ForceSpawnAllPotions()
		end)

		if success and result then
			adminPrint(userId, "?? Successfully spawned " .. result .. " luck potions!")
			adminPrint(userId, "??? VIP players received notifications and arrow guidance")
			adminPrint(userId, "?? All potions have proper models, glow effects, and interactions")
			return true, string.format("Spawned %d luck potions with VIP features", result)
		else
			adminPrint(userId, "? ForceSpawnAllPotions failed: " .. tostring(result))
			return false, "Failed to spawn potions: " .. tostring(result)
		end
	else
		adminPrint(userId, "? LuckPotionSystem not available!")
		adminPrint(userId, "?? Make sure LuckPotionSystem.lua is running in ServerScriptService")
		adminPrint(userId, "?? Check that the script has no errors and _G.ForceSpawnAllPotions is set")
		return false, "LuckPotionSystem not loaded - check ServerScriptService"
	end
end

-- Clear all potions command
commands.clearpotions = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if getAdminLevel(userId) < 3 then
		return false, "Insufficient admin level (Level 3 required)"
	end

	adminPrint(userId, "??? Starting potion cleanup process...")
	adminPrint(userId, "?? Scanning workspace for luck potions...")

	local clearedCount = 0

	-- Find and remove all luck potions
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name and obj.Name:find("LuckPotion_") then
			adminPrint(userId, "??? Removing: " .. obj.Name)
			obj:Destroy()
			clearedCount = clearedCount + 1
		end
	end

	-- Reset potion counter if available
	if _G.ResetPotionCount then
		pcall(function()
			_G.ResetPotionCount()
		end)
		adminPrint(userId, "?? Reset potion counter")
	else
		adminPrint(userId, "?? Potion counter reset function not available")
	end

	adminPrint(userId, "? Cleanup complete! Removed " .. clearedCount .. " potions from the map")
	return true, string.format("Cleared %d luck potions from the map", clearedCount)
end

-- List available gears command
commands.listgears = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if getAdminLevel(userId) < 2 then
		return false, "Insufficient admin level"
	end

	adminPrint(userId, "?? COMMON ROBLOX GEAR IDs:")
	adminPrint(userId, "---------------------------------------")

	-- Common gear IDs
	local commonGears = {
		{id = 16895227, name = "Bloxy Cola", category = "Food"},
		{id = 35653955, name = "Sword", category = "Melee"},
		{id = 92142841, name = "Gravity Hammer", category = "Melee"},
		{id = 99119158, name = "Lightsaber", category = "Melee"},
		{id = 108158379, name = "Darkheart", category = "Melee"},
		{id = 77443491, name = "Katana", category = "Melee"},
		{id = 82357101, name = "Windforce", category = "Ranged"},
		{id = 69947367, name = "Illumina", category = "Melee"},
		{id = 93136802, name = "Firebrand", category = "Melee"},
		{id = 73089166, name = "Icedagger", category = "Melee"},
	}

	for i, gear in ipairs(commonGears) do
		adminPrint(userId, string.format("%d. [%s] %s", gear.id, gear.category, gear.name))
	end

	adminPrint(userId, "")
	adminPrint(userId, "?? Total listed gears: " .. #commonGears)
	adminPrint(userId, "?? Use: !givegear <player> <gear_id>")
	adminPrint(userId, "?? Example: !givegear juliovetta16 16895227")

	return true, "Common gear list displayed - " .. #commonGears .. " gears total"
end

-- Give brainrot materials directly to gear crafting
commands.addtogear = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if getAdminLevel(userId) < 2 then
		return false, "Insufficient admin level"
	end

	if #args < 3 then
		return false, "Usage: !addtogear <player> <gear_name> <brainrot_name> [amount]"
	end

	local targetPlayer, findError = findPlayer(args[1])
	if not targetPlayer then
		return false, findError or "Target player not found"
	end

	local gearName = args[2]
	local brainrotName = table.concat(args, " ", 3, #args - (#args >= 4 and 1 or 0))
	local amount = 1

	if #args >= 4 and tonumber(args[#args]) then
		amount = tonumber(args[#args])
		brainrotName = table.concat(args, " ", 3, #args - 1)
	end

	adminPrint(userId, "?? Adding " .. amount .. "x '" .. brainrotName .. "' to " .. targetPlayer.Name .. "'s " .. gearName .. " crafting")

	-- Use the gear system's AddBrainrot function
	if _G.AddBrainrotToPlayer then
		local success, result = pcall(function()
			return _G.AddBrainrotToPlayer(targetPlayer.UserId, brainrotName, amount, gearName)
		end)

		if success and result then
			adminPrint(userId, "? Successfully added materials to gear crafting")
			return true, string.format("Added %d x '%s' to %s's %s crafting", amount, brainrotName, targetPlayer.Name, gearName)
		else
			adminPrint(userId, "? Failed to add to gear crafting: " .. tostring(result))
			return false, result or "Failed to add to gear crafting"
		end
	else
		adminPrint(userId, "? Gear system not available (_G.AddBrainrotToPlayer not found)")
		return false, "Gear system not available"
	end
end

-- Get player's gear info
commands.playergear = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if getAdminLevel(userId) < 2 then
		return false, "Insufficient admin level"
	end

	if #args < 1 then
		return false, "Usage: !playergear <player>"
	end

	local targetPlayer, findError = findPlayer(args[1])
	if not targetPlayer then
		return false, findError or "Target player not found"
	end

	adminPrint(userId, "?? GEAR INFO FOR " .. targetPlayer.Name .. ":")
	adminPrint(userId, "---------------------------------------")

	if _G.GetPlayerGearData then
		local playerData = _G.GetPlayerGearData(targetPlayer.UserId)
		if playerData then
			adminPrint(userId, "?? Equipped gear: " .. tostring(playerData.equippedGear or "None"))
			adminPrint(userId, "?? Gear inventory: " .. #(playerData.gearInventory or {}) .. " items")
			adminPrint(userId, "?? Auto-add gear: " .. tostring(playerData.autoAddGear or "None"))

			if playerData.gearInventory and #playerData.gearInventory > 0 then
				adminPrint(userId, "")
				adminPrint(userId, "?? Owned gears:")
				for i, gearId in ipairs(playerData.gearInventory) do
					adminPrint(userId, string.format("  %d. %s", i, gearId))
				end
			end

			if playerData.craftingProgress then
				adminPrint(userId, "")
				adminPrint(userId, "?? Crafting progress:")
				local hasProgress = false
				for gearId, progress in pairs(playerData.craftingProgress) do
					if type(progress) == "table" then
						adminPrint(userId, "  " .. gearId .. ":")
						for material, amount in pairs(progress) do
							adminPrint(userId, "    - " .. material .. ": " .. amount)
						end
						hasProgress = true
					end
				end
				if not hasProgress then
					adminPrint(userId, "  No active crafting progress")
				end
			end

			return true, "Player gear info displayed for " .. targetPlayer.Name
		else
			adminPrint(userId, "? Player gear data not found")
			return false, "Player gear data not found"
		end
	else
		adminPrint(userId, "? Gear system not available")
		return false, "Gear system not available"
	end
end

commands.listbrainrots = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	adminPrint(userId, "?? AVAILABLE BRAINROT ITEMS:")
	adminPrint(userId, "---------------------------------------")

	local brainrots = {}
	for name, data in pairs(BrainrotDefinitions.Lookup) do
		table.insert(brainrots, {name = name, odds = data.odds})
	end

	-- Sort by rarity (lower odds = rarer)
	table.sort(brainrots, function(a, b) return a.odds < b.odds end)

	local count = 0
	for _, brainrot in ipairs(brainrots) do
		count = count + 1
		local rarity = ""
		if brainrot.odds <= 100 then
			rarity = "?? LEGENDARY"
		elseif brainrot.odds <= 1000 then
			rarity = "?? EPIC"
		elseif brainrot.odds <= 10000 then
			rarity = "?? RARE"
		else
			rarity = "? COMMON"
		end

		adminPrint(userId, string.format("%d. %s %s (1/%d chance)", count, rarity, brainrot.name, brainrot.odds))
	end

	adminPrint(userId, "")
	adminPrint(userId, "?? Total items: " .. count)
	adminPrint(userId, "?? Use: !givebrainrot <player> <brainrot_name> [amount]")

	return true, "Brainrot list displayed - " .. count .. " items total"
end

commands.logs = function(adminPlayer, args)
	local userId = adminPlayer.UserId

	if getAdminLevel(userId) < 3 then
		return false, "Insufficient admin level"
	end

	local count = math.min(tonumber(args[1]) or 10, 50)

	adminPrint(userId, "?? RECENT ADMIN COMMAND LOGS:")
	adminPrint(userId, "---------------------------------------")
	adminPrint(userId, "Showing last " .. count .. " commands:")
	adminPrint(userId, "")

	for i = math.max(1, #commandLogs - count + 1), #commandLogs do
		local log = commandLogs[i]
		local admin = ADMINS[log.userId]
		local adminName = admin and admin.name or "Unknown"
		local timeStr = os.date("%H:%M:%S", log.timestamp)
		local status = log.success and "?" or "?"
		adminPrint(userId, string.format("[%s] %s %s (%d): %s", 
			timeStr, status, adminName, log.userId, log.command))
		if log.error then
			adminPrint(userId, "  +- Error: " .. log.error)
		end
	end

	adminPrint(userId, "")
	adminPrint(userId, "?? Total logs in system: " .. #commandLogs)

	return true, "Command logs displayed - last " .. count .. " entries"
end

-- ENHANCED: Help command with full output including gamepass commands
commands.help = function(adminPlayer, args)
	local userId = adminPlayer.UserId
	local level = getAdminLevel(userId)

	adminPrint(userId, "?? ADMIN COMMAND HELP - Level " .. level)
	adminPrint(userId, "---------------------------------------")

	-- Level 1 commands
	adminPrint(userId, "?? LEVEL 1 COMMANDS:")
	adminPrint(userId, "  !givebrainrot <player> <brainrot_name> [amount]")
	adminPrint(userId, "    +- Give brainrot items to a player")
	adminPrint(userId, "  !listbrainrots")
	adminPrint(userId, "    +- List all available brainrot items")
	adminPrint(userId, "  !help")
	adminPrint(userId, "    +- Show this help message")

	-- Level 2 commands
	if level >= 2 then
		adminPrint(userId, "")
		adminPrint(userId, "?? LEVEL 2 COMMANDS:")
		adminPrint(userId, "  !removebrainrot <player> <brainrot_name> [amount]")
		adminPrint(userId, "    +- Remove brainrot items from a player")
		adminPrint(userId, "  !givegear <player> <gear_id>")
		adminPrint(userId, "    +- Give Roblox catalog gear to a player")
		adminPrint(userId, "  !givecustomgear <player> <gear_name>")
		adminPrint(userId, "    +- Give custom gear from gear system")
		adminPrint(userId, "  !addtogear <player> <gear_name> <brainrot_name> [amount]")
		adminPrint(userId, "    +- Add materials to gear crafting progress")
		adminPrint(userId, "  !setluck <player> <luck_amount>")
		adminPrint(userId, "    +- Set player's luck (0-10000%)")
		adminPrint(userId, "  !playergear <player>")
		adminPrint(userId, "    +- View player's gear information")
		adminPrint(userId, "  !listgears")
		adminPrint(userId, "    +- List common Roblox gear IDs")
		adminPrint(userId, "  !listcustomgears")
		adminPrint(userId, "    +- List available custom gears")
	end

	-- Level 3 commands
	if level >= 3 then
		adminPrint(userId, "")
		adminPrint(userId, "?? LEVEL 3 COMMANDS:")
		adminPrint(userId, "  !spawnpotions")
		adminPrint(userId, "    +- Force spawn all luck potions on the map (FIXED)")
		adminPrint(userId, "  !clearpotions")
		adminPrint(userId, "    +- Clear all luck potions from the map")
		adminPrint(userId, "  !logs [count]")
		adminPrint(userId, "    +- View recent command logs (max 50)")
		adminPrint(userId, "  !listgamepasses")
		adminPrint(userId, "    +- List all available gamepasses")
		adminPrint(userId, "  !playergamepasses <player>")
		adminPrint(userId, "    +- View player's owned gamepasses")
	end

	-- Level 5+ commands
	if level >= 5 then
		adminPrint(userId, "")
		adminPrint(userId, "?? LEVEL 5+ COMMANDS:")
		adminPrint(userId, "  !givegamepass <player> <gamepass_name>")
		adminPrint(userId, "    +- Grant gamepass to player without purchase")
		adminPrint(userId, "  Admin GUI Panel")
		adminPrint(userId, "    +- Look for the gear icon (??) in bottom-right corner")
		adminPrint(userId, "    +- Real-time command logging and output display")
		adminPrint(userId, "    +- Visual command status and results")
	end

	adminPrint(userId, "")
	adminPrint(userId, "---------------------------------------")
	adminPrint(userId, "?? TIP: All commands start with ! (exclamation mark)")
	adminPrint(userId, "?? Your current admin level: " .. level)
	if level >= 3 then
		adminPrint(userId, "?? SPAWNPOTIONS FIXED: No more green blocks!")
	end
	if level >= 5 then
		adminPrint(userId, "?? GUI Panel available - check bottom-right corner!")
	end

	return true, "Help command executed - check output above"
end

-- Main command processor
function AdminCommandModule.processCommand(player, message)
	if not isAdmin(player.UserId) then
		return
	end

	local canUse, error = canUseCommand(player.UserId)
	if not canUse then
		logCommand(player.UserId, message, false, error, {})
		sendCommandResult(player, false, error, {})
		return
	end

	-- Clear previous output buffer
	printOutputBuffer[player.UserId] = {}

	-- Update cooldown
	commandCooldowns[tostring(player.UserId)] = tick()

	-- Parse command
	local parts = {}
	for part in message:gmatch("%S+") do
		table.insert(parts, part)
	end

	if #parts == 0 then
		return
	end

	local command = parts[1]:sub(2):lower() -- Remove ! prefix
	local args = {}
	for i = 2, #parts do
		table.insert(args, parts[i])
	end

	-- Execute command
	local handler = commands[command]
	if handler then
		local success, result = handler(player, args)
		local fullOutput = getAndClearOutput(player.UserId)

		logCommand(player.UserId, message, success, not success and result or nil, fullOutput)
		sendCommandResult(player, success, result or "Command executed", fullOutput)

		if result then
			-- Also print to console for backwards compatibility
			print(string.format("[ADMIN RESULT] %s: %s", player.Name, result))
		end
	else
		logCommand(player.UserId, message, false, "Unknown command", {})
		sendCommandResult(player, false, "Unknown command: " .. command, {})
	end
end

-- Initialize
function AdminCommandModule.init()
	_G.SetPlayerLuck = function(userId, amount)
		local player = Players:GetPlayerByUserId(userId)
		if player then
			-- Update luck GUI if available
			if _G.updateBadgeLuckBoost then
				_G.updateBadgeLuckBoost(amount)
			end
			return true
		end
		return false
	end

	Players.PlayerAdded:Connect(function(player)
		if isAdmin(player.UserId) then
			print(string.format("[ADMIN] %s (%d) joined - Level %d", 
				player.Name, player.UserId, getAdminLevel(player.UserId)))

			-- Send GUI to level 5+ admins after a delay
			if canUseGUI(player.UserId) then
				spawn(function()
					wait(3) -- Wait for client to fully load
					OpenAdminGUI:FireClient(player)
					print("?? Admin GUI sent to " .. player.Name .. " (Level " .. getAdminLevel(player.UserId) .. ")")
				end)
			end

			player.Chatted:Connect(function(message)
				if message:sub(1, 1) == "!" then
					AdminCommandModule.processCommand(player, message)
				end
			end)
		end
	end)
end

return AdminCommandModule