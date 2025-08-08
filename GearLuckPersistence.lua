-- Place this in StarterPlayerScripts to ensure gear luck bonus persists
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Wait for GearRemotes with error handling
local GearRemotes = ReplicatedStorage:WaitForChild("GearRemotes", 10)
if not GearRemotes then
	warn("GearRemotes not found, aborting GearLuckPersistence")
	return
end

-- Track the last known gear boost
local lastGearBoost = 0
local persistenceActive = true

-- Function to get the current equipped gear bonus
local function getCurrentGearBoost()
	-- Try different methods to get gear data
	local gearData = nil
	local equippedGearBoost = 0

	-- Method 1: Try GetFormattedGearInventory
	local GetFormattedGearInventory = GearRemotes:FindFirstChild("GetFormattedGearInventory")
	if GetFormattedGearInventory and GetFormattedGearInventory:IsA("RemoteFunction") then
		local success, data = pcall(function() 
			return GetFormattedGearInventory:InvokeServer() 
		end)
		if success and data then
			for _, gear in ipairs(data) do
				if gear.isEquipped then
					return gear.luckBoost or 0
				end
			end
		end
	end

	-- Method 2: Try GetGearInventory
	local GetGearInventory = GearRemotes:FindFirstChild("GetGearInventory")
	if GetGearInventory and GetGearInventory:IsA("RemoteFunction") then
		local success, data = pcall(function() 
			return GetGearInventory:InvokeServer() 
		end)
		if success and data then
			-- Handle data structure with inventory field
			if data.inventory and data.equippedGear then
				for _, gear in ipairs(data.inventory) do
					if gear.id == data.equippedGear then
						return gear.luckBoost or 0
					end
				end
			end

			-- Try to get data from GearData module
			local GearDataModule = ReplicatedStorage:FindFirstChild("GearData")
			if GearDataModule and data.equippedGear then
				local success2, gearModule = pcall(require, GearDataModule)
				if success2 and gearModule and gearModule.Gears then
					local gearInfo = gearModule.Gears[data.equippedGear]
					if gearInfo then
						return gearInfo.luckBoost or 0
					end
				end
			end
		end
	end

	return 0
end

-- Function to apply the gear boost to luck GUI
local function applyGearBoost(boost)
	if not _G.updateBadgeLuckBoost and not _G.updateGearLuckBoost then
		return false
	end

	-- Save the last known boost
	if boost ~= nil then
		lastGearBoost = boost
	else
		boost = lastGearBoost
	end

	-- Apply the boost using all possible functions
	if _G.updateGearLuckBoost then
		pcall(_G.updateGearLuckBoost, boost)
		return true
	elseif _G.updateBadgeLuckBoost then
		pcall(_G.updateBadgeLuckBoost, boost)
		return true
	end

	return false
end

-- Function to ensure the gear boost is consistently applied
local function ensureGearBoostApplied()
	-- Get the current boost from equipped gear
	local currentBoost = getCurrentGearBoost()

	-- Update lastGearBoost if current is different
	if currentBoost ~= lastGearBoost then
		print("Gear boost changed from " .. lastGearBoost .. "% to " .. currentBoost .. "%")
		lastGearBoost = currentBoost
	end

	-- Apply the boost (force update even if same value)
	applyGearBoost(currentBoost)
end

-- Initial setup
local function initialize()
	-- Get initial boost
	local initialBoost = getCurrentGearBoost()
	lastGearBoost = initialBoost
	print("Initial gear boost: " .. initialBoost .. "%")

	-- Apply initial boost
	task.delay(1, function()
		applyGearBoost(initialBoost)
	end)

	-- Create update loops at different intervals for robustness

	-- Every 1 second fast check
	task.spawn(function()
		while task.wait(1) do
			if persistenceActive then
				pcall(applyGearBoost, lastGearBoost) -- Just ensure value is set
			end
		end
	end)

	-- Every 5 seconds full refresh
	task.spawn(function()
		while task.wait(5) do
			if persistenceActive then
				pcall(ensureGearBoostApplied) -- Check gear and update if needed
			end
		end
	end)

	-- React to inventory GUI opening/closing
	local playerGui = player:WaitForChild("PlayerGui")
	local success, inventoryGui = pcall(function()
		return playerGui:WaitForChild("InventoryGui", 30)
	end)

	if success and inventoryGui then
		inventoryGui:GetPropertyChangedSignal("Visible"):Connect(function()
			if inventoryGui.Visible then
				-- When opening inventory, refresh gear boost
				task.delay(0.2, function()
					pcall(ensureGearBoostApplied)
				end)
			end
		end)
	end

	-- ? COMPLETELY FIXED: Hook into gear equip/unequip events
	local EquipGear = GearRemotes:FindFirstChild("EquipGear")
	local UnequipGear = GearRemotes:FindFirstChild("UnequipGear")

	if EquipGear and EquipGear:IsA("RemoteFunction") then
		local oldEquipInvoke = EquipGear.InvokeServer
		if oldEquipInvoke then
			EquipGear.InvokeServer = function(self, ...)
				local args = {...}
				local result = oldEquipInvoke(self, unpack(args))
				task.delay(0.3, function()
					pcall(ensureGearBoostApplied)
				end)
				return result
			end
			print("Successfully hooked EquipGear for persistence")
		end
	end

	if UnequipGear and UnequipGear:IsA("RemoteFunction") then
		local oldUnequipInvoke = UnequipGear.InvokeServer
		if oldUnequipInvoke then
			UnequipGear.InvokeServer = function(self, ...)
				local args = {...}
				local result = oldUnequipInvoke(self, unpack(args))
				task.delay(0.3, function()
					pcall(ensureGearBoostApplied)
				end)
				return result
			end
			print("Successfully hooked UnequipGear for persistence")
		end
	end

	-- Create global functions for controlling this system
	_G.PersistGearLuck = function(active)
		persistenceActive = active ~= false
		print("Gear luck persistence " .. (persistenceActive and "enabled" or "disabled"))
		if persistenceActive then
			pcall(ensureGearBoostApplied)
		end
	end

	_G.GetCurrentGearBoost = getCurrentGearBoost
	_G.ForceGearBoostUpdate = ensureGearBoostApplied

	print("Gear luck persistence system initialized successfully")
end

-- Start the system with error handling
pcall(initialize)