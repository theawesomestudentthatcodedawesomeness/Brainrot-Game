-- Script: ServerScriptService>AutoAddInventorySync (COMPLETE FIX)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

print("?? AUTO-ADD INVENTORY SYNC: Starting (NO REMOTE CALLS VERSION)...")

-- Local storage for auto-add settings
local playerAutoAddData = {}
local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_V1")

-- Wait for required systems
local function waitForRequiredSystems()
	local GearData, BrainrotDefinitions

	while not GearData do
		local success, result = pcall(function()
			return require(ReplicatedStorage:WaitForChild("GearData"))
		end)
		if success then
			GearData = result
		else
			wait(1)
		end
	end

	while not BrainrotDefinitions do
		local success, result = pcall(function()
			return require(ReplicatedStorage:WaitForChild("BrainrotDefinitions"))
		end)
		if success then
			BrainrotDefinitions = result
		else
			wait(1)
		end
	end

	print("? Required modules loaded")
	return GearData, BrainrotDefinitions
end

-- Load/Save player auto-add data
local function loadPlayerAutoAdd(player)
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync("gear_" .. player.UserId)
	end)

	if success and data and data.autoAddGear then
		playerAutoAddData[player.UserId] = data.autoAddGear
		print("? Loaded auto-add gear for " .. player.Name .. ": " .. data.autoAddGear)
		return data.autoAddGear
	else
		playerAutoAddData[player.UserId] = nil
		return nil
	end
end

local function savePlayerAutoAdd(player, gearId)
	playerAutoAddData[player.UserId] = gearId

	spawn(function()
		local success, data = pcall(function()
			return PlayerDataStore:GetAsync("gear_" .. player.UserId)
		end)

		local playerData = {}
		if success and data then
			playerData = data
		end

		playerData.autoAddGear = gearId

		local saveSuccess = pcall(function()
			PlayerDataStore:SetAsync("gear_" .. player.UserId, playerData)
		end)

		if saveSuccess then
			print("? Saved auto-add gear for " .. player.Name .. ": " .. tostring(gearId))
		else
			warn("? Failed to save auto-add gear for " .. player.Name)
		end
	end)
end

local function getPlayerAutoAdd(player)
	return playerAutoAddData[player.UserId] or loadPlayerAutoAdd(player)
end

local function setPlayerAutoAdd(player, gearId, enabled)
	if enabled then
		local currentGear = getPlayerAutoAdd(player)
		if currentGear and currentGear ~= gearId then
			return false, "Auto-add is already enabled on another gear. Disable it first."
		end

		playerAutoAddData[player.UserId] = gearId
		savePlayerAutoAdd(player, gearId)

		print("? ENABLED auto-add for " .. player.Name .. ": " .. gearId)

		-- ?? TRIGGER IMMEDIATE INVENTORY PROCESSING
		spawn(function()
			wait(1)
			processExistingInventory(player)
		end)

		return true, "Auto-add enabled for " .. gearId
	else
		local currentGear = getPlayerAutoAdd(player)
		if currentGear == gearId then
			playerAutoAddData[player.UserId] = nil
			savePlayerAutoAdd(player, nil)

			print("? DISABLED auto-add for " .. player.Name .. ": " .. gearId)
			return true, "Auto-add disabled"
		else
			return false, "This gear doesn't have auto-add enabled"
		end
	end
end

-- COMPLETELY FIXED: Server-side inventory access functions
local function getServerInventory(player)
	print("?? Getting server-side inventory for " .. player.Name)
	
	-- Method 1: Try global inventory function
	if _G.GetPlayerInventoryData then
		local success, inventory = pcall(function()
			return _G.GetPlayerInventoryData(player.UserId)
		end)
		if success and inventory then
			print("? Got inventory via _G.GetPlayerInventoryData: " .. #inventory .. " items")
			return inventory
		end
	end
	
	-- Method 2: Check available global functions
	print("?? Available global functions:")
	for key, value in pairs(_G) do
		if type(value) == "function" and string.find(string.lower(key), "inventory") then
			print("   - _G." .. key)
		end
	end
	
	print("? Could not get server-side inventory for " .. player.Name)
	return {}
end

local function removeServerInventoryItem(player, itemName, amount)
	print("??? Removing " .. amount .. "x " .. itemName .. " from " .. player.Name .. "'s inventory (server-side)")
	
	-- Method 1: Try global removal functions
	local removalFunctions = {"RemoveItemFromInventory", "RemoveItem", "TakeItem", "ConsumeItem", "DeductItem"}
	
	for _, funcName in pairs(removalFunctions) do
		if _G[funcName] then
			local success = pcall(function()
				_G[funcName](player.UserId, itemName, amount)
			end)
			if success then
				print("? Successfully removed via _G." .. funcName)
				return true
			end
		end
	end
	
	print("? Could not remove " .. itemName .. " from inventory")
	return false
end

-- COMPLETELY FIXED: Process auto-add using ONLY global functions
local function processAutoAdd(player, brainrotName, skipInventoryCheck)
	print("?? PROCESSING AUTO-ADD: " .. player.Name .. " + " .. brainrotName)

	local autoAddGear = getPlayerAutoAdd(player)
	if not autoAddGear then
		print("?? No auto-add gear enabled")
		return false
	end

	print("? Auto-add gear: " .. autoAddGear)

	local GearData = waitForRequiredSystems()

	if not GearData.Gears[autoAddGear] then
		warn("? Gear data not found for: " .. autoAddGear)
		return false
	end

	local gearData = GearData.Gears[autoAddGear]
	if not gearData.recipe[brainrotName] then
		print("?? " .. brainrotName .. " not needed for " .. gearData.name)
		return false
	end

	print("? " .. brainrotName .. " IS needed for " .. gearData.name)

	-- FIXED: Get inventory using server-side only methods
	local inventory = getServerInventory(player)
	local availableCount = 0
	local foundItem = false

	-- Check for the item in current inventory
	for _, item in pairs(inventory) do
		if item.name == brainrotName then
			availableCount = item.count or 1
			foundItem = true
			break
		end
	end

	if not foundItem or availableCount <= 0 then
		print("?? No " .. brainrotName .. " available in inventory")
		return false
	end

	print("? Found " .. availableCount .. "x " .. brainrotName .. " in current inventory")

	-- COMPLETELY FIXED: Use ONLY global functions - NO RemoteFunction calls
	local requiredAmount = gearData.recipe[brainrotName]
	
	-- Get current progress directly from gear system global data
	local currentAmount = 0
	if _G.GetPlayerGearData then
		local playerGearData = _G.GetPlayerGearData(player.UserId)
		if playerGearData and playerGearData.craftingProgress and playerGearData.craftingProgress[autoAddGear] then
			currentAmount = playerGearData.craftingProgress[autoAddGear][brainrotName] or 0
		end
	end

	if currentAmount >= requiredAmount then
		print("?? Already at max: " .. currentAmount .. "/" .. requiredAmount)
		return false
	end

	print("?? Current progress: " .. currentAmount .. "/" .. requiredAmount)

	-- Add to recipe using ONLY global functions
	local toAdd = math.min(availableCount, requiredAmount - currentAmount)
	local totalAdded = 0

	-- COMPLETELY FIXED: Use global function that the GearSystem provides
	if _G.AddBrainrotToPlayer then
		for i = 1, toAdd do
			local success, message = pcall(function()
				return _G.AddBrainrotToPlayer(player.UserId, brainrotName, 1, autoAddGear)
			end)

			if success and success ~= false then
				totalAdded = totalAdded + 1
				print("? Added " .. brainrotName .. " (" .. totalAdded .. "/" .. toAdd .. ") via global function")
			else
				print("? Failed to add via global function: " .. tostring(message))
				break
			end

			wait(0.1)
		end
	else
		-- Alternative: Try to access the gear system's AddBrainrot function directly
		print("? _G.AddBrainrotToPlayer not available, trying alternative...")
		
		-- Method: Trigger the main gear system's processExistingInventoryForAutoAdd
		if _G.ProcessExistingInventoryForAutoAdd then
			local success = pcall(function()
				_G.ProcessExistingInventoryForAutoAdd(player)
			end)
			if success then
				print("? Triggered main gear system auto-add processing")
				return true
			end
		end
		
		print("? No available method to add brainrot to gear system")
		return false
	end

	if totalAdded > 0 then
		print("?? AUTO-ADD SUCCESS: " .. totalAdded .. "x " .. brainrotName .. " ? " .. gearData.name)

		-- Send notification
		local autoAddNotif = ReplicatedStorage:FindFirstChild("AutoAddNotification")
		if autoAddNotif then
			spawn(function()
				pcall(function()
					autoAddNotif:FireClient(player, brainrotName, gearData.name, true)
				end)
			end)
		end

		return true
	else
		print("? Could not add any " .. brainrotName)
		return false
	end
end

-- FIXED: Process existing inventory using server-side only
function processExistingInventory(player)
	print("?? PROCESSING EXISTING INVENTORY: " .. player.Name)

	local autoAddGear = getPlayerAutoAdd(player)
	if not autoAddGear then
		print("?? No auto-add gear enabled")
		return
	end

	local GearData = waitForRequiredSystems()
	if not GearData.Gears[autoAddGear] then
		warn("? Gear data not found")
		return
	end

	local gearData = GearData.Gears[autoAddGear]

	-- FIXED: Get fresh inventory using server-side methods
	local inventory = getServerInventory(player)

	if #inventory == 0 then
		print("?? No inventory items to process")
		return
	end

	print("?? Found " .. #inventory .. " items in inventory")

	local itemsProcessed = 0

	for brainrotName, requiredAmount in pairs(gearData.recipe) do
		for _, item in pairs(inventory) do
			if item.name == brainrotName and (item.count or 1) > 0 then
				print("?? Processing existing: " .. brainrotName .. " x" .. (item.count or 1))

				local wasAdded = processAutoAdd(player, brainrotName, true)
				if wasAdded then
					itemsProcessed = itemsProcessed + 1
				end
				break
			end
		end
	end

	if itemsProcessed > 0 then
		print("?? Processed " .. itemsProcessed .. " existing items")
	else
		print("?? No matching items found for auto-add")
	end
end

-- FIXED: Setup without RemoteFunction conflicts
local function setupGearRemotes()
	-- Don't create conflicting remotes, just hook into the existing ones
	print("? Gear remote setup (hook mode only)")
end

-- Initialize system
spawn(function()
	waitForRequiredSystems()
	setupGearRemotes()

	-- Override global functions for integration
	_G.HandleAutoAdd = processAutoAdd
	_G.ProcessExistingInventoryForAutoAdd = processExistingInventory

	print("? AUTO-ADD INVENTORY SYNC READY (NO REMOTE CALLS)!")
end)

-- Player connections
Players.PlayerAdded:Connect(function(player)
	spawn(function()
		wait(5) -- Give time for systems to load
		loadPlayerAutoAdd(player)

		wait(3)
		processExistingInventory(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerAutoAddData[player.UserId] = nil
end)

-- Admin commands
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "juliovetta16" then
			if message == "/synctest" then
				print("?? SYNC TEST:")
				local autoAddGear = getPlayerAutoAdd(player)
				print("  Auto-add gear: " .. tostring(autoAddGear))

				if autoAddGear then
					local inventory = getServerInventory(player)
					print("  Current inventory items: " .. #inventory)
					for _, item in pairs(inventory) do
						print("    - " .. item.name .. " x" .. (item.count or 1))
					end

					processExistingInventory(player)
				end

			elseif message == "/debugglobals" then
				print("?? DEBUG GLOBALS:")
				print("Available global functions:")
				for key, value in pairs(_G) do
					if type(value) == "function" then
						print("   - _G." .. key)
					end
				end

			elseif message:sub(1, 9) == "/syncadd " then
				local brainrotName = message:sub(10)
				print("?? SYNC ADD TEST: " .. brainrotName)

				local result = processAutoAdd(player, brainrotName, true)
				print("?? Result: " .. tostring(result))

			elseif message == "/forceprocess" then
				processExistingInventory(player)
			end
		end
	end)
end)

print("? Auto-Add Inventory Sync loaded!")
print("?? Commands: /synctest, /syncadd [brainrot], /forceprocess, /debugglobals")
print("?? COMPLETELY FIXED: Zero RemoteFunction calls from server!")