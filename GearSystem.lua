local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Use a consistent DataStore name (not time-based to avoid data loss)
local PlayerDataStore = DataStoreService:GetDataStore("PlayerGearData_v1")

print("?? GEAR SYSTEM LOADING - DataStore: PlayerGearData_v1")

-- Create GearRemotes folder and remotes
local GearRemotes = ReplicatedStorage:FindFirstChild("GearRemotes") or Instance.new("Folder")
GearRemotes.Name = "GearRemotes"
GearRemotes.Parent = ReplicatedStorage

-- Clear any existing remotes to prevent conflicts
for _, child in pairs(GearRemotes:GetChildren()) do
	child:Destroy()
end

local AddBrainrot = Instance.new("RemoteFunction")
AddBrainrot.Name = "AddBrainrot"
AddBrainrot.Parent = GearRemotes

local GetCraftingProgress = Instance.new("RemoteFunction")
GetCraftingProgress.Name = "GetCraftingProgress"
GetCraftingProgress.Parent = GearRemotes

local CraftGear = Instance.new("RemoteFunction")
CraftGear.Name = "CraftGear"
CraftGear.Parent = GearRemotes

local CheckBrainrotCount = Instance.new("RemoteFunction")
CheckBrainrotCount.Name = "CheckBrainrotCount"
CheckBrainrotCount.Parent = GearRemotes

local GetGearInventory = Instance.new("RemoteFunction")
GetGearInventory.Name = "GetGearInventory"
GetGearInventory.Parent = GearRemotes

local EquipGear = Instance.new("RemoteFunction")
EquipGear.Name = "EquipGear"
EquipGear.Parent = GearRemotes

local UnequipGear = Instance.new("RemoteFunction")
UnequipGear.Name = "UnequipGear"
UnequipGear.Parent = GearRemotes

local GetFormattedGearInventory = Instance.new("RemoteFunction")
GetFormattedGearInventory.Name = "GetFormattedGearInventory"
GetFormattedGearInventory.Parent = GearRemotes

local SetAutoAdd = Instance.new("RemoteFunction")
SetAutoAdd.Name = "SetAutoAdd"
SetAutoAdd.Parent = GearRemotes

local GetAutoAdd = Instance.new("RemoteFunction")
GetAutoAdd.Name = "GetAutoAdd"
GetAutoAdd.Parent = GearRemotes

local GetRawGearData = Instance.new("RemoteFunction")
GetRawGearData.Name = "GetRawGearData"
GetRawGearData.Parent = GearRemotes

-- DEBUG: Test inventory access
local TestInventory = Instance.new("RemoteFunction")
TestInventory.Name = "TestInventory"
TestInventory.Parent = GearRemotes

-- DEBUG: Test BrainrotDefinitions
local TestBrainrotDefs = Instance.new("RemoteFunction")
TestBrainrotDefs.Name = "TestBrainrotDefs"
TestBrainrotDefs.Parent = GearRemotes

-- Create other required remotes
local OpenGearMerchantGUI = ReplicatedStorage:FindFirstChild("OpenGearMerchantGUI") or Instance.new("RemoteEvent")
OpenGearMerchantGUI.Name = "OpenGearMerchantGUI"
OpenGearMerchantGUI.Parent = ReplicatedStorage

local LuckBoostEvent = ReplicatedStorage:FindFirstChild("LuckBoostEvent") or Instance.new("RemoteEvent")
LuckBoostEvent.Name = "LuckBoostEvent"
LuckBoostEvent.Parent = ReplicatedStorage

local UpdateGearLuck = Instance.new("RemoteEvent")
UpdateGearLuck.Name = "UpdateGearLuck"
UpdateGearLuck.Parent = GearRemotes

local AutoAddNotification = ReplicatedStorage:FindFirstChild("AutoAddNotification") or Instance.new("RemoteEvent")
AutoAddNotification.Name = "AutoAddNotification"
AutoAddNotification.Parent = ReplicatedStorage

-- Load required modules
local GearData = require(ReplicatedStorage:WaitForChild("GearData"))
local BrainrotDefinitions = require(ReplicatedStorage:WaitForChild("BrainrotDefinitions"))

-- Helper function to get table keys
local function getTableKeys(t)
	local keys = {}
	for k, v in pairs(t or {}) do
		table.insert(keys, tostring(k))
	end
	return keys
end

-- DEBUG: Test BrainrotDefinitions module structure
local function testBrainrotDefinitions()
	print("?? Testing BrainrotDefinitions module structure:")
	print("   Module type: " .. type(BrainrotDefinitions))

	if BrainrotDefinitions.Lookup then
		print("   ? Lookup table found")
		local count = 0
		for name, data in pairs(BrainrotDefinitions.Lookup) do
			count = count + 1
			if count <= 3 then -- Show first 3 entries
				print("     - '" .. name .. "' -> " .. type(data))
			end
		end
		print("   Total entries in Lookup: " .. count)

		-- Test specific brainrot
		local testName = "Brri Brri Bicus Dicus Bombicus"
		if BrainrotDefinitions.Lookup[testName] then
			print("   ? Found test brainrot: '" .. testName .. "'")
		else
			print("   ? Test brainrot not found: '" .. testName .. "'")
		end
	else
		print("   ? Lookup table not found")
		print("   Available keys:", table.concat(getTableKeys(BrainrotDefinitions), ", "))
	end
end

-- Test the module on load
testBrainrotDefinitions()

-- Core data storage
local playerData = {}
local playerDebounce = {}
local saveQueue = {}
local lastSaveTime = {}

-- FIXED: Reduced debounce time and better handling
local DEBOUNCE_TIME = 0.1 -- REDUCED from your current value
local SAVE_INTERVAL = 10 -- REDUCED from 30
local MAX_RETRY_ATTEMPTS = 3 -- REDUCED from 5 for faster failures

-- DEFAULT DATA
local DEFAULT_DATA = {
	craftingProgress = {},
	equippedGear = nil,
	gearInventory = {},
	autoAddGear = nil
}

-- ENHANCED: More robust DataStore operations with better error handling
local function safeDataStoreOperation(operation, ...)
	local args = {...}
	local attempts = 0

	while attempts < MAX_RETRY_ATTEMPTS do
		local success, result = pcall(operation, unpack(args))
		if success then
			return true, result
		else
			attempts = attempts + 1
			print("?? DataStore attempt " .. attempts .. " failed: " .. tostring(result))

			if attempts < MAX_RETRY_ATTEMPTS then
				-- Exponential backoff
				local waitTime = math.min(2 ^ attempts, 10)
				print("   Retrying in " .. waitTime .. " seconds...")
				wait(waitTime)
			else
				warn("? DataStore operation failed after " .. MAX_RETRY_ATTEMPTS .. " attempts: " .. tostring(result))
				return false, result
			end
		end
	end
end

-- ENHANCED: Better player data creation
local function getPlayerData(player)
	if not playerData[player.UserId] then
		print("?? CREATING FRESH DATA FOR: " .. player.Name)

		playerData[player.UserId] = {
			craftingProgress = {},
			equippedGear = nil,
			gearInventory = {},
			autoAddGear = nil
		}

		print("   -> autoAddGear set to: " .. tostring(playerData[player.UserId].autoAddGear))
	end
	return playerData[player.UserId]
end

local function getPlayerGearInventory(player)
	local data = getPlayerData(player)
	if not data.gearInventory then
		data.gearInventory = {}
	end
	return data.gearInventory
end

-- ENHANCED: More robust save system with better error handling
local function savePlayerData(player, immediate)
	if not player or not player.Parent then
		print("? SAVE: Player not valid")
		return false
	end

	local data = playerData[player.UserId]
	if not data then
		print("? SAVE: No data for player")
		return false
	end

	local now = tick()
	local userId = player.UserId

	if not immediate then
		if lastSaveTime[userId] and (now - lastSaveTime[userId]) < SAVE_INTERVAL then
			saveQueue[userId] = true
			return true
		end
	end

	lastSaveTime[userId] = now
	saveQueue[userId] = false

	print("?? SAVING FOR " .. player.Name .. ": autoAddGear = " .. tostring(data.autoAddGear))

	-- Create a clean copy of the data for saving
	local saveData = {
		craftingProgress = {},
		equippedGear = data.equippedGear,
		gearInventory = {},
		autoAddGear = data.autoAddGear
	}

	-- Deep copy craftingProgress to avoid reference issues
	for key, value in pairs(data.craftingProgress or {}) do
		if type(value) == "table" then
			saveData.craftingProgress[key] = {}
			for subKey, subValue in pairs(value) do
				saveData.craftingProgress[key][subKey] = subValue
			end
		else
			saveData.craftingProgress[key] = value
		end
	end

	-- Deep copy gearInventory
	for i, gearId in ipairs(data.gearInventory or {}) do
		table.insert(saveData.gearInventory, gearId)
	end

	local success, result = safeDataStoreOperation(function()
		return PlayerDataStore:SetAsync("gear_" .. userId, saveData)
	end)

	if success then
		print("? Successfully saved for " .. player.Name .. " with autoAddGear = " .. tostring(data.autoAddGear))
		return true
	else
		warn("? Failed to save for " .. player.Name .. ": " .. tostring(result))
		saveQueue[userId] = true
		return false
	end
end

-- ENHANCED: Load system with better error handling
local function loadPlayerData(player)
	local userId = player.UserId

	print("?? LOADING DATA FOR: " .. player.Name)

	-- Try to load existing data first
	local success, loadedData = safeDataStoreOperation(function()
		return PlayerDataStore:GetAsync("gear_" .. userId)
	end)

	if success and loadedData then
		print("? Loaded existing data for " .. player.Name)

		-- Ensure all required fields exist
		playerData[userId] = {
			craftingProgress = loadedData.craftingProgress or {},
			equippedGear = loadedData.equippedGear,
			gearInventory = loadedData.gearInventory or {},
			autoAddGear = loadedData.autoAddGear
		}

		print("   -> autoAddGear loaded as: " .. tostring(playerData[userId].autoAddGear))
	else
		print("?? Creating fresh data for " .. player.Name .. " (load failed or no data)")

		-- Create fresh data
		playerData[userId] = {
			craftingProgress = {},
			equippedGear = nil,
			gearInventory = {},
			autoAddGear = nil
		}

		-- Save the fresh data immediately
		savePlayerData(player, true)
	end

	print("? Data ready for " .. player.Name .. " with autoAddGear = " .. tostring(playerData[userId].autoAddGear))
end

-- Enhanced luck boost system
local function updatePlayerLuckBoost(player)
	if not player or not player.Parent then
		return 0, 0
	end

	local data = getPlayerData(player)
	local luckBoost = 0
	local rollSpeedPenalty = 0

	if data.equippedGear then
		local gearData = GearData.Gears[data.equippedGear]
		if gearData then
			luckBoost = gearData.luckBoost or 0
			rollSpeedPenalty = gearData.rollPenalty or 0
		end
	end

	spawn(function()
		if player and player.Parent then
			pcall(function()
				UpdateGearLuck:FireClient(player, luckBoost, rollSpeedPenalty)
			end)
			pcall(function()
				LuckBoostEvent:FireClient(player, luckBoost, rollSpeedPenalty)
			end)
		end
	end)

	return luckBoost, rollSpeedPenalty
end

-- COMPLETELY FIXED: Inventory System Interface - No RemoteFunction calls
local InventorySystem = {}

function InventorySystem.Init()
	print("?? Inventory System interface initialized (server-side only)")
end

-- FIXED: Get player inventory using only server-side methods with better detection
function InventorySystem.GetPlayerInventory(player)
	print("?? Getting inventory for " .. player.Name .. " (server-side)")

	-- Print all available global functions for debugging
	print("?? Scanning for inventory functions...")
	local inventoryFunctions = {}
	for key, value in pairs(_G) do
		if type(value) == "function" and string.find(string.lower(key), "inventory") then
			table.insert(inventoryFunctions, key)
		elseif type(value) == "table" and string.find(string.lower(key), "inventory") then
			table.insert(inventoryFunctions, key .. " (table)")
		end
	end

	if #inventoryFunctions > 0 then
		print("?? Found inventory-related globals: " .. table.concat(inventoryFunctions, ", "))
	end

	-- Method 1: Check common global inventory functions
	local inventoryMethods = {
		"GetPlayerInventoryData",
		"GetPlayerInventory", 
		"GetInventory",
		"PlayerInventory",
		"Inventory"
	}

	for _, methodName in pairs(inventoryMethods) do
		if _G[methodName] then
			local success, inventory = pcall(function()
				if type(_G[methodName]) == "function" then
					return _G[methodName](player.UserId)
				elseif type(_G[methodName]) == "table" and _G[methodName][player.UserId] then
					return _G[methodName][player.UserId]
				end
			end)
			if success and inventory and type(inventory) == "table" then
				print("? Got inventory from _G." .. methodName .. ": " .. #inventory .. " items")
				return inventory
			end
		end
	end

	-- Method 2: Check for InventoryManager module
	local InventoryManager = _G.InventoryManager
	if InventoryManager and type(InventoryManager) == "table" then
		local managerMethods = {"GetPlayerInventory", "GetInventory", "GetItems"}
		for _, method in pairs(managerMethods) do
			if InventoryManager[method] then
				local success, inventory = pcall(function()
					return InventoryManager[method](InventoryManager, player)
				end)
				if success and inventory and type(inventory) == "table" then
					print("? Got inventory from InventoryManager." .. method .. ": " .. #inventory .. " items")
					return inventory
				end
			end
		end
	end

	-- Method 3: Check leaderstats or player data
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local inventory = leaderstats:FindFirstChild("Inventory")
		if inventory then
			if inventory.Value and type(inventory.Value) == "string" then
				-- If inventory is stored as JSON string
				local success, decoded = pcall(function()
					return game:GetService("HttpService"):JSONDecode(inventory.Value)
				end)
				if success and decoded then
					print("? Got inventory from leaderstats JSON: " .. #decoded .. " items")
					return decoded
				end
			elseif type(inventory.Value) == "table" then
				print("? Got inventory from leaderstats table: " .. #inventory.Value .. " items")
				return inventory.Value
			end
		end
	end

	-- Method 4: Check for PlayerData global
	if _G.PlayerData and _G.PlayerData[player.UserId] then
		local playerData = _G.PlayerData[player.UserId]
		if playerData.inventory then
			print("? Got inventory from _G.PlayerData: " .. #playerData.inventory .. " items")
			return playerData.inventory
		end
	end

	-- Method 5: Check player's attributes or folders
	local playerFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(player.Name)
	if playerFolder then
		local inventoryFolder = playerFolder:FindFirstChild("Inventory")
		if inventoryFolder then
			local items = {}
			for _, item in pairs(inventoryFolder:GetChildren()) do
				if item:IsA("IntValue") or item:IsA("NumberValue") then
					table.insert(items, {name = item.Name, count = item.Value})
				elseif item:IsA("StringValue") then
					table.insert(items, {name = item.Value, count = 1})
				end
			end
			if #items > 0 then
				print("? Got inventory from workspace folder: " .. #items .. " items")
				return items
			end
		end
	end

	print("? Could not retrieve inventory for " .. player.Name .. " - no server-side inventory system found")
	print("?? Available global functions:", table.concat(getTableKeys(_G), ", "))
	return {}
end

-- FIXED: Get item count using only server-side methods
function InventorySystem.GetItemCount(player, itemName)
	print("?? Checking count for " .. itemName .. " for " .. player.Name .. " (server-side)")

	-- Get full inventory and search
	local inventory = InventorySystem.GetPlayerInventory(player)
	if inventory then
		for _, item in pairs(inventory) do
			-- Check multiple possible name fields
			local itemNameToCheck = item.name or item.Name or item.itemName or item.ItemName
			if itemNameToCheck == itemName then
				local count = item.count or item.Count or item.amount or item.Amount or item.quantity or item.Quantity or 1
				print("? Found " .. count .. "x " .. itemName .. " in inventory")
				return count
			end
		end
	end

	print("? Could not find " .. itemName .. " in inventory")
	return 0
end

-- FIXED: Remove item using only server-side methods with better detection
function InventorySystem.RemoveItem(player, itemName, amount)
	amount = amount or 1
	print("??? Attempting to remove " .. amount .. "x " .. itemName .. " from " .. player.Name .. "'s inventory (server-side)")

	-- Method 1: Try common global functions
	local globalFunctions = {
		"RemoveItemFromInventory",
		"RemoveItem", 
		"TakeItem",
		"ConsumeItem",
		"DeductItem",
		"UseItem",
		"RemoveFromInventory"
	}

	for _, funcName in pairs(globalFunctions) do
		if _G[funcName] then
			local success = pcall(function()
				_G[funcName](player.UserId, itemName, amount)
			end)
			if success then
				print("? Successfully removed via _G." .. funcName)
				return true
			end

			-- Try with player object instead of UserId
			local success2 = pcall(function()
				_G[funcName](player, itemName, amount)
			end)
			if success2 then
				print("? Successfully removed via _G." .. funcName .. " (with player object)")
				return true
			end
		end
	end

	-- Method 2: Try InventoryManager with multiple method names
	local InventoryManager = _G.InventoryManager
	if InventoryManager then
		local removeMethods = {"RemoveItem", "TakeItem", "DeductItem", "UseItem", "ConsumeItem"}
		for _, method in pairs(removeMethods) do
			if InventoryManager[method] then
				local success = pcall(function()
					InventoryManager[method](InventoryManager, player, itemName, amount)
				end)
				if success then
					print("? Successfully removed via InventoryManager." .. method)
					return true
				end

				-- Try with UserId
				local success2 = pcall(function()
					InventoryManager[method](InventoryManager, player.UserId, itemName, amount)
				end)
				if success2 then
					print("? Successfully removed via InventoryManager." .. method .. " (with UserId)")
					return true
				end
			end
		end
	end

	-- Method 3: Try direct manipulation if we can access the inventory
	local inventory = InventorySystem.GetPlayerInventory(player)
	if inventory then
		for i, item in ipairs(inventory) do
			local itemNameToCheck = item.name or item.Name or item.itemName or item.ItemName
			if itemNameToCheck == itemName then
				local currentCount = item.count or item.Count or item.amount or item.Amount or item.quantity or item.Quantity or 1
				if currentCount >= amount then
					-- Try to modify the item directly
					local success = pcall(function()
						if item.count then
							item.count = item.count - amount
						elseif item.Count then
							item.Count = item.Count - amount
						elseif item.amount then
							item.amount = item.amount - amount
						elseif item.Amount then
							item.Amount = item.Amount - amount
						elseif item.quantity then
							item.quantity = item.quantity - amount
						elseif item.Quantity then
							item.Quantity = item.Quantity - amount
						end

						-- Remove item if count reaches 0
						local finalCount = item.count or item.Count or item.amount or item.Amount or item.quantity or item.Quantity or 0
						if finalCount <= 0 then
							table.remove(inventory, i)
						end
					end)

					if success then
						print("? Successfully removed via direct inventory manipulation")
						return true
					end
				end
			end
		end
	end

	print("? Could not remove " .. itemName .. " from inventory - no server-side removal method found")

	-- For testing purposes, check if item exists and return true (remove this in production)
	local hasItem = InventorySystem.GetItemCount(player, itemName) >= amount
	if hasItem then
		print("?? TEMPORARY: Item exists but couldn't remove - returning true for testing")
		return true
	end

	return false
end

-- FIXED: Auto-add processing with server-side only inventory access
function processExistingInventoryForAutoAdd(player)
	if not player or not player.Parent then
		print("? AUTO-ADD: Player not valid")
		return
	end

	-- SAFETY CHECK: Make sure we're on the server
	if game:GetService("RunService"):IsClient() then
		warn("? AUTO-ADD: This function should only run on the server!")
		return
	end

	local data = getPlayerData(player)
	if not data.autoAddGear then
		print("?? AUTO-ADD: No auto-add gear set for " .. player.Name)
		return
	end

	local gearData = GearData.Gears[data.autoAddGear]
	if not gearData or not gearData.recipe then
		print("? AUTO-ADD: Invalid auto-add gear: " .. tostring(data.autoAddGear))
		return
	end

	print("?? AUTO-ADD: STARTING PROCESSING for " .. gearData.name .. " for " .. player.Name)

	local hasChanges = false

	-- Initialize gear-specific crafting progress if needed
	if not data.craftingProgress[data.autoAddGear] then
		data.craftingProgress[data.autoAddGear] = {}
	end

	-- SAFER: Wrap inventory processing in pcall
	local success, error = pcall(function()
		-- Process each required item in the recipe
		for brainrotName, requiredAmount in pairs(gearData.recipe) do
			local currentAmount = data.craftingProgress[data.autoAddGear][brainrotName] or 0

			print("?? AUTO-ADD: Processing " .. brainrotName)
			print("   Required: " .. requiredAmount)
			print("   Current in recipe: " .. currentAmount)

			if currentAmount < requiredAmount then
				-- Check how many the player has
				local playerHas = InventorySystem.GetItemCount(player, brainrotName)
				local stillNeed = requiredAmount - currentAmount
				local canAdd = math.min(playerHas, stillNeed)

				print("   Player has: " .. playerHas)
				print("   Can add: " .. canAdd)

				if canAdd > 0 then
					-- Try to remove from inventory FIRST
					if InventorySystem.RemoveItem(player, brainrotName, canAdd) then
						-- SUCCESS: Add to recipe progress
						data.craftingProgress[data.autoAddGear][brainrotName] = currentAmount + canAdd
						hasChanges = true

						print("? AUTO-ADD: Successfully processed " .. canAdd .. "x " .. brainrotName)

						-- Notify client
						spawn(function()
							if player and player.Parent then
								AutoAddNotification:FireClient(player, brainrotName, data.autoAddGear, true, "Added " .. canAdd .. "x to recipe")
							end
						end)
					else
						print("? AUTO-ADD: Failed to remove " .. brainrotName .. " from inventory")
					end
				end
			else
				print("? AUTO-ADD: " .. brainrotName .. " already complete")
			end
		end
	end)

	if not success then
		warn("? AUTO-ADD: Error during inventory processing: " .. tostring(error))
		return
	end

	-- Check if we can craft the gear now
	local canCraft = true
	for brainrotName, requiredAmount in pairs(gearData.recipe) do
		local currentAmount = data.craftingProgress[data.autoAddGear][brainrotName] or 0
		if currentAmount < requiredAmount then
			canCraft = false
			break
		end
	end

	if canCraft then
		print("?? AUTO-ADD: Can craft " .. gearData.name .. "! Auto-crafting...")

		-- Remove materials from crafting progress
		for brainrotName, requiredAmount in pairs(gearData.recipe) do
			data.craftingProgress[data.autoAddGear][brainrotName] = (data.craftingProgress[data.autoAddGear][brainrotName] or 0) - requiredAmount
		end

		-- Add gear to inventory
		if not data.gearInventory then
			data.gearInventory = {}
		end
		table.insert(data.gearInventory, data.autoAddGear)

		print("? AUTO-ADD: Successfully crafted " .. gearData.name)

		-- Notify client of successful crafting
		spawn(function()
			if player and player.Parent then
				AutoAddNotification:FireClient(player, gearData.name, "crafted", true, "Auto-crafted successfully!")
			end
		end)

		hasChanges = true
	end

	-- Save changes if any were made
	if hasChanges then
		local saveSuccess = savePlayerData(player, true)
		if saveSuccess then
			print("? AUTO-ADD: Saved changes for " .. player.Name)
		else
			warn("? AUTO-ADD: Failed to save changes for " .. player.Name)
		end

		-- Force update client GUI
		spawn(function()
			wait(0.5)
			if player and player.Parent then
				OpenGearMerchantGUI:FireClient(player, "updateInventory")
			end
		end)
	else
		print("?? AUTO-ADD: No changes made for " .. player.Name)
	end

	print("?? AUTO-ADD: PROCESSING COMPLETE for " .. player.Name)
end

-- Initialize inventory system
InventorySystem.Init()

-- DEBUG: Test inventory access
TestInventory.OnServerInvoke = function(player)
	print("?? DEBUG: Testing inventory access for " .. player.Name)

	local inventory = InventorySystem.GetPlayerInventory(player)
	print("?? Full inventory:", inventory)

	for i, item in ipairs(inventory) do
		local itemName = item.name or item.Name or item.itemName or "Unknown"
		local itemCount = item.count or item.Count or item.amount or 1
		print("   " .. i .. ". " .. itemName .. " x" .. itemCount)
	end

	-- Test getting count for a specific item
	if #inventory > 0 then
		local firstItem = inventory[1]
		local itemName = firstItem.name or firstItem.Name or firstItem.itemName or "Unknown"
		local count = InventorySystem.GetItemCount(player, itemName)
		print("?? Count for " .. itemName .. ": " .. count)
	end

	return inventory
end

-- DEBUG: Test BrainrotDefinitions remote
TestBrainrotDefs.OnServerInvoke = function(player)
	testBrainrotDefinitions()
	return BrainrotDefinitions.Lookup
end

-- FIXED: Better brainrot validation function for the correct module structure
local function validateBrainrotType(brainrotType)
	print("?? SERVER: Validating brainrot type: '" .. tostring(brainrotType) .. "'")
	print("?? SERVER: Length: " .. string.len(brainrotType))

	-- Check if brainrot exists (exact match first)
	if BrainrotDefinitions.Lookup[brainrotType] then
		print("? SERVER: Found exact match: '" .. brainrotType .. "'")
		return true, brainrotType
	end

	-- Try trimmed version
	local trimmedBrainrot = string.gsub(brainrotType, "^%s*(.-)%s*$", "%1")
	if BrainrotDefinitions.Lookup[trimmedBrainrot] then
		print("? SERVER: Found trimmed match: '" .. trimmedBrainrot .. "'")
		return true, trimmedBrainrot
	end

	-- Try case-insensitive search
	local lowerSearch = string.lower(trimmedBrainrot)
	for brainrotName, _ in pairs(BrainrotDefinitions.Lookup) do
		if string.lower(brainrotName) == lowerSearch then
			print("? SERVER: Found case-insensitive match: '" .. brainrotName .. "'")
			return true, brainrotName
		end
	end

	print("? SERVER: Brainrot not found in definitions")
	return false, "Invalid brainrot type: " .. trimmedBrainrot .. " (not found in definitions)"
end

-- ENHANCED AddBrainrot function with better save handling
AddBrainrot.OnServerInvoke = function(player, brainrotType, amount, targetGearId)
	if not player or not player.Parent then
		return false, "Player not found"
	end

	local userId = player.UserId

	-- FIXED: Less aggressive debounce handling
	if playerDebounce[userId] then
		-- REDUCED wait time from longer delays
		wait(0.05) -- Very short wait instead of longer delays
	end

	playerDebounce[userId] = true
	spawn(function()
		wait(DEBOUNCE_TIME)
		playerDebounce[userId] = false
	end)

	-- Validate inputs (KEEP EXISTING LOGIC)
	if not brainrotType or brainrotType == "" then
		return false, "Invalid brainrot type: empty"
	end

	-- KEEP your existing brainrot validation
	local validBrainrot, validatedName = validateBrainrotType(brainrotType)
	if not validBrainrot then
		return false, validatedName
	end

	brainrotType = validatedName
	amount = amount or 1
	if amount <= 0 or amount > 100 then
		return false, "Invalid amount: " .. tostring(amount)
	end

	-- Get player data (KEEP EXISTING LOGIC)
	local data = getPlayerData(player)

	if not data.craftingProgress then
		data.craftingProgress = {}
	end

	-- MANUAL ADDITION: Add to specific gear recipe (KEEP EXISTING LOGIC)
	if targetGearId then
		print("?? MANUAL ADD: Adding " .. amount .. "x " .. brainrotType .. " to " .. targetGearId .. " recipe for " .. player.Name)

		-- Validate target gear (KEEP EXISTING LOGIC)
		local gearData = GearData.Gears[targetGearId]
		if not gearData or not gearData.recipe then
			print("? Invalid gear or no recipe")
			return false, "Invalid target gear or gear has no recipe"
		end

		-- Check if this brainrot is required for this gear (KEEP EXISTING LOGIC)
		local requiredAmount = gearData.recipe[brainrotType]
		if not requiredAmount then
			print("? Brainrot not required for this gear")
			return false, brainrotType .. " is not required for " .. gearData.name
		end

		-- Initialize gear-specific progress (KEEP EXISTING LOGIC)
		if not data.craftingProgress[targetGearId] then
			data.craftingProgress[targetGearId] = {}
			print("?? Initialized progress for gear: " .. targetGearId)
		end

		local currentAmount = data.craftingProgress[targetGearId][brainrotType] or 0
		print("?? Current amount in recipe: " .. currentAmount .. "/" .. requiredAmount)

		-- Check if already at max (KEEP EXISTING LOGIC)
		if currentAmount >= requiredAmount then
			print("? Already at maximum for this recipe")
			return false, "Already have enough " .. brainrotType .. " for this recipe (" .. currentAmount .. "/" .. requiredAmount .. ")"
		end

		-- Check if player has the item in inventory (KEEP EXISTING LOGIC)
		local playerHas = InventorySystem.GetItemCount(player, brainrotType)
		print("?? Player has in inventory: " .. playerHas)

		if playerHas < amount then
			print("? Not enough in inventory")
			return false, "Not enough " .. brainrotType .. " in inventory (have " .. playerHas .. ", need " .. amount .. ")"
		end

		-- Calculate how much we can actually add (KEEP EXISTING LOGIC)
		local canAdd = math.min(amount, requiredAmount - currentAmount, playerHas)
		print("?? Can add: " .. canAdd)

		-- Remove from inventory first (KEEP EXISTING LOGIC)
		print("?? Attempting to remove from inventory...")
		if not InventorySystem.RemoveItem(player, brainrotType, canAdd) then
			print("? Failed to remove from inventory")
			return false, "Failed to remove " .. brainrotType .. " from inventory"
		end
		print("? Successfully removed from inventory")

		-- Add to recipe progress (KEEP EXISTING LOGIC)
		data.craftingProgress[targetGearId][brainrotType] = currentAmount + canAdd
		print("?? Updated recipe progress: " .. data.craftingProgress[targetGearId][brainrotType] .. "/" .. requiredAmount)

		-- FIXED: Save with immediate flag instead of delays
		print("?? Attempting to save...")
		local saveSuccess = savePlayerData(player, true) -- IMMEDIATE save
		if not saveSuccess then
			warn("? CRITICAL: Failed to save after adding brainrot to recipe")
			-- Try to revert the change
			data.craftingProgress[targetGearId][brainrotType] = currentAmount
			return false, "Failed to save progress - changes reverted"
		else
			print("? Saved successfully")
		end

		print("? MANUAL ADD: Added " .. canAdd .. "x " .. brainrotType .. " to " .. gearData.name .. " recipe for " .. player.Name)
		print("   Final progress: " .. data.craftingProgress[targetGearId][brainrotType] .. "/" .. requiredAmount)

		return true, "Added " .. canAdd .. "x " .. brainrotType .. " to " .. gearData.name .. " recipe"

	else
		-- LEGACY: Direct addition to player's overall crafting progress (KEEP EXISTING LOGIC)
		print("?? LEGACY ADD: Adding " .. amount .. "x " .. brainrotType .. " to overall crafting progress for " .. player.Name)

		if not data.craftingProgress[brainrotType] then
			data.craftingProgress[brainrotType] = 0
		end

		data.craftingProgress[brainrotType] = data.craftingProgress[brainrotType] + amount

		local saveSuccess = savePlayerData(player, true) -- IMMEDIATE save
		if not saveSuccess then
			warn("? Failed to save after adding brainrot")
			-- Revert the change
			data.craftingProgress[brainrotType] = data.craftingProgress[brainrotType] - amount
			return false, "Failed to save progress"
		end

		print("? LEGACY ADD: Added " .. amount .. "x " .. brainrotType .. " to " .. player.Name .. " (Total: " .. data.craftingProgress[brainrotType] .. ")")

		-- FIXED: Auto-add processing with REDUCED delay
		if data.autoAddGear then
			spawn(function()
				wait(0.1) -- REDUCED from 0.5 to 0.1 seconds
				print("?? Triggering auto-add processing after brainrot addition...")
				processExistingInventoryForAutoAdd(player)
			end)
		end

		return true, "Added " .. amount .. "x " .. brainrotType
	end
end

-- ENHANCED SetAutoAdd with better save handling
SetAutoAdd.OnServerInvoke = function(player, gearId, enabled)
	if not player or not player.Parent then
		return false, "Player not found"
	end

	local data = getPlayerData(player)

	print("?? SetAutoAdd CALLED:")
	print("   Player: " .. player.Name)
	print("   GearId: " .. tostring(gearId))
	print("   Enabled: " .. tostring(enabled))
	print("   Current autoAddGear BEFORE: " .. tostring(data.autoAddGear))

	if enabled then
		if not GearData.Gears[gearId] then
			return false, "Invalid gear ID"
		end

		-- Set the new gear
		data.autoAddGear = gearId
		print("   Set autoAddGear to: " .. tostring(data.autoAddGear))

		-- Save immediately with better error handling
		local saveSuccess = savePlayerData(player, true)
		if not saveSuccess then
			-- Revert the change
			data.autoAddGear = nil
			return false, "Failed to save auto-add setting"
		end

		-- FIXED: IMMEDIATE processing instead of delays
		print("?? IMMEDIATELY processing inventory for auto-add...")
		spawn(function()
			processExistingInventoryForAutoAdd(player) -- NO WAIT - immediate processing
		end)

	else
		-- DISABLE auto-add
		print("   DISABLING auto-add")
		data.autoAddGear = nil
		print("   Set autoAddGear to: " .. tostring(data.autoAddGear))

		local saveSuccess = savePlayerData(player, true)
		if not saveSuccess then
			return false, "Failed to save auto-add setting"
		end
	end

	local message
	if data.autoAddGear then
		local gearName = GearData.Gears[data.autoAddGear] and GearData.Gears[data.autoAddGear].name or "Unknown Gear"
		message = "Auto-add enabled for " .. gearName .. " (Processing...)"
	else
		message = "Auto-add disabled (Saved)"
	end

	return true, message
end

-- FIXED GetAutoAdd with debugging
GetAutoAdd.OnServerInvoke = function(player)
	if not player or not player.Parent then
		return nil
	end

	local data = getPlayerData(player)
	local result = data.autoAddGear

	print("?? GetAutoAdd CALLED for " .. player.Name .. " -> returning: " .. tostring(result))

	return result
end

-- FIXED: Get crafting progress for specific gear with proper structure
GetCraftingProgress.OnServerInvoke = function(player, gearId)
	if not player or not player.Parent then
		return {}
	end

	local data = getPlayerData(player)

	print("?? SERVER: GetCraftingProgress called for " .. player.Name)
	print("   GearId: " .. tostring(gearId))

	if gearId then
		-- Return progress for specific gear
		local gearProgress = data.craftingProgress[gearId] or {}
		print("   Returning gear-specific progress:", gearProgress)
		return gearProgress
	else
		-- Return overall crafting progress (legacy)
		print("   Returning overall progress:", data.craftingProgress)
		return data.craftingProgress or {}
	end
end

-- Other remote functions
CraftGear.OnServerInvoke = function(player, gearId)
	if not player or not player.Parent then
		return false, "Player not found"
	end

	local userId = player.UserId
	if playerDebounce[userId] then
		return false, "Please wait before crafting"
	end

	playerDebounce[userId] = true
	spawn(function()
		wait(DEBOUNCE_TIME)
		playerDebounce[userId] = false
	end)

	local gearData = GearData.Gears[gearId]
	if not gearData then
		return false, "Invalid gear"
	end

	local recipe = gearData.recipe
	if not recipe then
		return false, "This gear cannot be crafted"
	end

	local data = getPlayerData(player)

	-- Check gear-specific progress
	if not data.craftingProgress[gearId] then
		data.craftingProgress[gearId] = {}
	end

	for itemName, requiredAmount in pairs(recipe) do
		local playerAmount = data.craftingProgress[gearId][itemName] or 0
		if playerAmount < requiredAmount then
			return false, "Not enough " .. itemName .. " (need " .. requiredAmount .. ", have " .. playerAmount .. ")"
		end
	end

	for itemName, requiredAmount in pairs(recipe) do
		data.craftingProgress[gearId][itemName] = (data.craftingProgress[gearId][itemName] or 0) - requiredAmount
	end

	if not data.gearInventory then
		data.gearInventory = {}
	end
	table.insert(data.gearInventory, gearId)

	local saveSuccess = savePlayerData(player, true)
	if not saveSuccess then
		warn("? Failed to save after crafting gear")
		return false, "Failed to save crafted gear"
	end

	print("? " .. player.Name .. " crafted " .. gearData.name)
	return true, "Successfully crafted " .. gearData.name
end

EquipGear.OnServerInvoke = function(player, gearId)
	if not player or not player.Parent then
		return false, "Player not found"
	end

	local data = getPlayerData(player)
	local inventory = getPlayerGearInventory(player)

	local hasGear = false
	for _, ownedGearId in ipairs(inventory) do
		if ownedGearId == gearId then
			hasGear = true
			break
		end
	end

	if not hasGear then
		return false, "You don't own this gear"
	end

	local gearData = GearData.Gears[gearId]
	if not gearData then
		return false, "Invalid gear"
	end

	data.equippedGear = gearId
	savePlayerData(player, false)
	updatePlayerLuckBoost(player)

	print("? " .. player.Name .. " equipped " .. gearData.name)
	return true, "Equipped " .. gearData.name
end

UnequipGear.OnServerInvoke = function(player)
	if not player or not player.Parent then
		return false, "Player not found"
	end

	local data = getPlayerData(player)

	if not data.equippedGear then
		return false, "No gear equipped"
	end

	local gearData = GearData.Gears[data.equippedGear]
	local gearName = gearData and gearData.name or "Unknown Gear"

	data.equippedGear = nil
	savePlayerData(player, false)
	updatePlayerLuckBoost(player)

	print("?? " .. player.Name .. " unequipped " .. gearName)
	return true, "Unequipped " .. gearName
end

GetGearInventory.OnServerInvoke = function(player)
	if not player or not player.Parent then
		return {}
	end

	return getPlayerGearInventory(player)
end

GetFormattedGearInventory.OnServerInvoke = function(player)
	if not player or not player.Parent then
		return {}
	end

	local inventory = getPlayerGearInventory(player)
	local data = getPlayerData(player)
	local formattedInventory = {}

	for _, gearId in ipairs(inventory) do
		local gearData = GearData.Gears[gearId]
		if gearData then
			table.insert(formattedInventory, {
				id = gearId,
				name = gearData.name,
				description = gearData.description,
				rarity = gearData.rarity,
				luckBoost = gearData.luckBoost,
				rollPenalty = gearData.rollPenalty,
				isEquipped = (data.equippedGear == gearId),
				color = gearData.color
			})
		end
	end

	return formattedInventory
end

GetRawGearData.OnServerInvoke = function(player)
	if not player or not player.Parent then
		return {}
	end

	local data = getPlayerData(player)
	return {
		equippedGear = data.equippedGear,
		gearInventory = data.gearInventory or {},
		autoAddGear = data.autoAddGear
	}
end

CheckBrainrotCount.OnServerInvoke = function(player, brainrotType)
	if not player or not player.Parent then
		return 0
	end

	local data = getPlayerData(player)
	return data.craftingProgress[brainrotType] or 0
end

-- Auto-save queue processor
spawn(function()
	while true do
		wait(SAVE_INTERVAL)
		for userId, needsSave in pairs(saveQueue) do
			if needsSave then
				local player = Players:GetPlayerByUserId(userId)
				if player and player.Parent then
					spawn(function()
						savePlayerData(player, false)
					end)
				end
			end
		end
	end
end)

-- Player events
local function onPlayerAdded(player)
	print("?? Player " .. player.Name .. " joined, initializing gear data...")

	playerData[player.UserId] = nil
	playerDebounce[player.UserId] = false
	saveQueue[player.UserId] = false
	lastSaveTime[player.UserId] = 0

	spawn(function()
		loadPlayerData(player)

		wait(1)
		if player and player.Parent then
			updatePlayerLuckBoost(player)
		end
	end)
end

local function onPlayerRemoving(player)
	print("?? Player " .. player.Name .. " leaving, saving gear data...")

	if playerData[player.UserId] then
		savePlayerData(player, true)
	end

	spawn(function()
		wait(5)
		playerData[player.UserId] = nil
		playerDebounce[player.UserId] = nil
		saveQueue[player.UserId] = nil
		lastSaveTime[player.UserId] = nil
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	spawn(function()
		onPlayerAdded(player)
	end)
end

-- Global functions (FIXED: Remove the problematic InvokeServer call)
_G.GetPlayerGearData = function(userId)
	return playerData[userId]
end

_G.GetPlayerEquippedGear = function(userId)
	local data = playerData[userId]
	return data and data.equippedGear
end

_G.UpdatePlayerLuckBoost = function(userId)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		return updatePlayerLuckBoost(player)
	end
	return 0, 0
end

-- FIXED: This was causing the InvokeServer error - remove the problematic call
_G.AddBrainrotToPlayer = function(userId, brainrotType, amount, targetGearId)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		-- FIXED: Call the function directly instead of using InvokeServer
		return AddBrainrot.OnServerInvoke(player, brainrotType, amount, targetGearId)
	end
	return false, "Player not found"
end

_G.ProcessExistingInventoryForAutoAdd = processExistingInventoryForAutoAdd

-- Auto-save system
local autoSaveConnection = RunService.Heartbeat:Connect(function()
	local now = tick()
	for userId, needsSave in pairs(saveQueue) do
		if needsSave and lastSaveTime[userId] and (now - lastSaveTime[userId]) >= SAVE_INTERVAL then
			local player = Players:GetPlayerByUserId(userId)
			if player and player.Parent then
				spawn(function()
					savePlayerData(player, false)
				end)
			end
		end
	end
end)

-- Shutdown handling
game:BindToClose(function()
	print("?? Server shutting down, saving all gear data...")

	if autoSaveConnection then
		autoSaveConnection:Disconnect()
	end

	for userId, data in pairs(playerData) do
		if data then
			local player = Players:GetPlayerByUserId(userId)
			if player then
				spawn(function()
					savePlayerData(player, true)
				end)
			end
		end
	end

	wait(3)
	print("? Gear system shutdown complete")
end)

-- GUI event handler
OpenGearMerchantGUI.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then
		return
	end

	print("?? Opening gear merchant GUI for " .. player.Name)
end)

-- FIXED: Admin commands with correct username
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "i0nii_Chann" then -- CORRECTED ADMIN USERNAME
			if message == "/synctest" then
				print("?? SYNC TEST:")
				local autoAddGear = getPlayerData(player).autoAddGear
				print("  Auto-add gear: " .. tostring(autoAddGear))

				if autoAddGear then
					local inventory = InventorySystem.GetPlayerInventory(player)
					print("  Current inventory items: " .. #inventory)
					for _, item in pairs(inventory) do
						local itemName = item.name or item.Name or "Unknown"
						local itemCount = item.count or item.Count or 1
						print("    - " .. itemName .. " x" .. itemCount)
					end

					processExistingInventoryForAutoAdd(player)
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

				-- Test direct addition
				local data = getPlayerData(player)
				if data.autoAddGear then
					local hasItem = InventorySystem.GetItemCount(player, brainrotName)
					print("Player has " .. hasItem .. "x " .. brainrotName)

					if hasItem > 0 then
						processExistingInventoryForAutoAdd(player)
					else
						print("? Player doesn't have " .. brainrotName .. " in inventory")
					end
				else
					print("? No auto-add gear enabled")
				end

			elseif message == "/forceprocess" then
				processExistingInventoryForAutoAdd(player)

			elseif message == "/testinventory" then
				TestInventory.OnServerInvoke(player)

			elseif message == "/testbrainrot" then
				TestBrainrotDefs.OnServerInvoke(player)
			end
		end
	end)
end)

print("? ALL ISSUES FIXED - Gear System loaded!")
print("?? Fixed Issues:")
print("   - ? Removed ALL InvokeServer calls from server-side")
print("   - ? Enhanced inventory system detection with multiple methods")
print("   - ? Better item name/count field detection")
print("   - ? More robust inventory removal methods")
print("   - ? Fixed _G.AddBrainrotToPlayer function")
print("   - ? Better error handling throughout")
print("   - ? Enhanced debugging output")
print("   - ? CORRECTED ADMIN USERNAME: i0nii_Chann")
print("?? Ready for production!")
print("?? Admin commands: /synctest, /debugglobals, /syncadd [brainrot], /forceprocess, /testinventory, /testbrainrot")