-- Place this in StarterPlayerScripts to connect gear system with luck display
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Wait for necessary components with proper error handling
local GearRemotes = ReplicatedStorage:WaitForChild("GearRemotes", 10)
if not GearRemotes then
	warn("GearRemotes not found, aborting luck integration")
	return
end

local GetGearInventory = GearRemotes:WaitForChild("GetGearInventory", 5)

-- Validate remotes exist and are correct type
if not GetGearInventory or not GetGearInventory:IsA("RemoteFunction") then
	warn("GetGearInventory not found or invalid type")
	return
end

-- Create or get the LuckBoostEvent
local LuckBoostEvent = ReplicatedStorage:FindFirstChild("LuckBoostEvent")
if not LuckBoostEvent then
	LuckBoostEvent = Instance.new("RemoteEvent")
	LuckBoostEvent.Name = "LuckBoostEvent"
	LuckBoostEvent.Parent = ReplicatedStorage
	print("Created LuckBoostEvent")
end

-- Helper function to get player data
local function getPlayerData()
	local GetFormattedGearInventory = GearRemotes:FindFirstChild("GetFormattedGearInventory")

	if GetFormattedGearInventory and GetFormattedGearInventory:IsA("RemoteFunction") then
		local success, result = pcall(function()
			return GetFormattedGearInventory:InvokeServer()
		end)
		if success then
			return result
		else
			warn("Failed to get formatted gear data:", tostring(result))
		end
	end

	return nil
end

-- Function to update luck display from equipped gear
local function updateLuckFromGear()
	-- Wait for luck display system to initialize
	if not _G.updateBadgeLuckBoost then
		task.wait(1)
		if not _G.updateBadgeLuckBoost then
			return false
		end
	end

	-- Get gear data with error handling
	local success, gearData = pcall(function()
		return GetGearInventory:InvokeServer()
	end)

	if not success or not gearData then
		warn("Failed to get gear data:", tostring(gearData))
		return false
	end

	-- Find equipped gear and its luck boost
	local luckBoost = 0

	-- Handle case where gearData is just an array of gear IDs or has different structure
	if gearData and type(gearData) == "table" then
		-- If we have a properly structured response with inventory field
		if gearData.inventory then
			for _, gear in pairs(gearData.inventory) do
				if gear.id == gearData.equippedGear then
					luckBoost = gear.luckBoost or 0
					print("Found equipped gear with +" .. luckBoost .. "% luck boost")
					break
				end
			end
		else
			-- Try to get the data from GearData module directly
			local GearDataModule = ReplicatedStorage:FindFirstChild("GearData")
			if GearDataModule then
				local success2, GearData = pcall(require, GearDataModule)
				if success2 and GearData and GearData.Gears then
					local data = getPlayerData()
					if data and data.equippedGear and GearData.Gears[data.equippedGear] then
						luckBoost = GearData.Gears[data.equippedGear].luckBoost or 0
						print("Found equipped gear from player data with +" .. luckBoost .. "% luck boost")
					end
				else
					warn("Failed to require GearData module:", tostring(GearData))
				end
			end
		end
	end

	-- Update the luck display
	if _G.updateBadgeLuckBoost then
		_G.updateBadgeLuckBoost(luckBoost)
		print("Updated luck display with +" .. luckBoost .. "% from gear")
		return true
	end

	return false
end

-- ? FIXED: Use monitoring approach instead of trying to hook InvokeServer
local lastKnownEquippedGear = nil

local function monitorGearEquipChanges()
	task.spawn(function()
		while task.wait(2) do
			local success, gearData = pcall(function()
				return GetGearInventory:InvokeServer()
			end)

			if success and gearData then
				local currentEquipped = nil

				if gearData.inventory then
					for _, gear in pairs(gearData.inventory) do
						if gear.id == gearData.equippedGear then
							currentEquipped = gear.id
							break
						end
					end
				else
					-- Handle different data formats
					local data = getPlayerData()
					if data then
						currentEquipped = data.equippedGear
					end
				end

				-- Check if equipped gear changed
				if lastKnownEquippedGear ~= currentEquipped then
					print("Detected gear equipment change")
					lastKnownEquippedGear = currentEquipped
					task.delay(0.5, updateLuckFromGear)
				end
			end
		end
	end)
end

-- Run initial update after delay to ensure all systems are loaded
task.delay(3, function()
	pcall(updateLuckFromGear)
end)

-- Start monitoring for gear changes
monitorGearEquipChanges()

-- Create update loop with error handling
task.spawn(function()
	while task.wait(5) do
		pcall(updateLuckFromGear)
	end
end)

-- Expose function globally
_G.ForceUpdateGearLuck = updateLuckFromGear

print("GearLuckBridge initialized successfully with monitoring approach")