local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Wait for necessary remotes with error handling
local LuckBoostEvent = ReplicatedStorage:WaitForChild("LuckBoostEvent", 10)
local GearRemotes = ReplicatedStorage:WaitForChild("GearRemotes", 10)

if not GearRemotes then
	warn("GearRemotes not found, aborting GearLuckUpdater")
	return
end

local GetFormattedGearInventory = GearRemotes:WaitForChild("GetFormattedGearInventory", 10)

if not GetFormattedGearInventory then
	warn("GetFormattedGearInventory not found, aborting GearLuckUpdater")
	return
end

-- Function to manually update luck boost from gear
local function updateLuckFromEquippedGear()
	-- Check if luck update function exists
	if not _G.updateBadgeLuckBoost then
		task.wait(1) -- Brief wait in case it's still initializing
		if not _G.updateBadgeLuckBoost then
			print("Luck GUI system not yet initialized")
			return false
		end
	end

	-- Get gear inventory data with error handling
	local success, gears = pcall(function()
		return GetFormattedGearInventory:InvokeServer()
	end)

	if not success or not gears then
		warn("Failed to get gear data:", tostring(gears))
		return false
	end

	-- Find equipped gear
	local equippedGear = nil
	for _, gear in ipairs(gears) do
		if gear.isEquipped then
			equippedGear = gear
			break
		end
	end

	-- Apply luck boost from equipped gear
	if equippedGear then
		print("Updating luck boost from equipped gear: " .. equippedGear.name)
		print("Applying +" .. equippedGear.luckBoost .. "% luck boost")
		_G.updateBadgeLuckBoost(equippedGear.luckBoost)
		return true
	else
		print("No equipped gear found, setting luck boost to 0")
		_G.updateBadgeLuckBoost(0)
		return true
	end
end

-- Create a function to continuously check and update luck
local function startLuckUpdateLoop()
	task.spawn(function()
		-- Initial delay to allow systems to initialize
		task.wait(5)

		-- Initial update attempt
		if not updateLuckFromEquippedGear() then
			-- If failed, try a few more times with increasing delays
			for i = 1, 5 do
				task.wait(i * 2)
				if updateLuckFromEquippedGear() then
					break
				end
			end
		end

		-- Then check periodically
		while task.wait(15) do
			updateLuckFromEquippedGear()
		end
	end)
end

-- Connect to relevant events
if LuckBoostEvent then
	LuckBoostEvent.OnClientEvent:Connect(function(luckBoost, rollPenalty)
		print("Received luck boost update from server: +" .. tostring(luckBoost) .. "%")

		if _G.updateBadgeLuckBoost then
			_G.updateBadgeLuckBoost(luckBoost)
		end
	end)
end

-- ? COMPLETELY FIXED: Listen for gear equipment changes
local EquipGear = GearRemotes:FindFirstChild("EquipGear")
local UnequipGear = GearRemotes:FindFirstChild("UnequipGear")

-- ? FIX: Use proper method to hook RemoteFunction calls from client side
-- We can't hook InvokeServer directly, instead we monitor results
if EquipGear and EquipGear:IsA("RemoteFunction") then
	print("Found EquipGear RemoteFunction")
	-- We'll use a different approach - monitoring inventory changes
else
	warn("EquipGear not found or is not a RemoteFunction")
end

if UnequipGear and UnequipGear:IsA("RemoteFunction") then
	print("Found UnequipGear RemoteFunction")
	-- We'll use a different approach - monitoring inventory changes
else
	warn("UnequipGear not found or is not a RemoteFunction")
end

-- ? ALTERNATIVE APPROACH: Monitor for inventory changes instead of hooking functions
local lastKnownGearState = {}

local function monitorGearChanges()
	task.spawn(function()
		while task.wait(1) do
			local success, currentGears = pcall(function()
				return GetFormattedGearInventory:InvokeServer()
			end)

			if success and currentGears then
				local currentEquipped = nil
				for _, gear in ipairs(currentGears) do
					if gear.isEquipped then
						currentEquipped = gear.id
						break
					end
				end

				-- Check if equipped gear changed
				if lastKnownGearState.equippedGear ~= currentEquipped then
					print("Detected gear change - updating luck")
					lastKnownGearState.equippedGear = currentEquipped
					task.wait(0.5) -- Small delay for server processing
					updateLuckFromEquippedGear()
				end
			end
		end
	end)
end

-- Start monitoring systems
startLuckUpdateLoop()
monitorGearChanges()

-- Add a global function to manually trigger the update
_G.ForceUpdateGearLuck = updateLuckFromEquippedGear

print("GearLuckUpdater initialized successfully with monitoring approach!")