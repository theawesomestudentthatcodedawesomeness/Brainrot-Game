local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Throttling to prevent excessive updates
local lastUpdateTime = 0
local UPDATE_COOLDOWN = 2 -- seconds between updates

-- Create a function to manually update luck from gears with error handling
local function updateLuckFromGear()
	local success, err = pcall(function()
		-- Check if the luck GUI system is loaded
		if not _G.updateBadgeLuckBoost then
			warn("Luck GUI system not available (_G.updateBadgeLuckBoost not found)")
			return false
		end

		-- Wait for the LuckBoostEvent to initialize the badge boost
		local luckBoostEvent = ReplicatedStorage:WaitForChild("LuckBoostEvent", 10)
		if not luckBoostEvent then
			warn("LuckBoostEvent not found in ReplicatedStorage")
			return false
		end

		-- Manually trigger update if needed
		local GearRemotes = ReplicatedStorage:FindFirstChild("GearRemotes")
		if not GearRemotes then
			warn("GearRemotes not found in ReplicatedStorage")
			return false
		end

		local GearData = ReplicatedStorage:FindFirstChild("GearData")
		if not GearData then
			warn("GearData module not found")
			return false
		end

		local gearModule = require(GearData)
		if not gearModule or not gearModule.Gears then
			warn("GearData module has invalid structure")
			return false
		end

		-- Check if direct gear system is available
		local GetRawGearData = GearRemotes:FindFirstChild("GetRawGearData")
		local GetFormattedGearInventory = GearRemotes:FindFirstChild("GetFormattedGearInventory")

		if not (GetRawGearData or GetFormattedGearInventory) then
			warn("No gear data remote functions found")
			return false
		end

		-- Use whichever function is available
		local remoteFunc = GetRawGearData or GetFormattedGearInventory

		-- Get gear data with timeout protection
		local gearData = nil
		local getDataSuccess = false
		
		spawn(function()
			local dataSuccess, dataResult = pcall(function()
				return remoteFunc:InvokeServer()
			end)
			
			if dataSuccess then
				gearData = dataResult
				getDataSuccess = true
			else
				warn("Failed to get gear data: " .. tostring(dataResult))
			end
		end)
		
		-- Wait for data with timeout
		local timeout = 0
		while not getDataSuccess and timeout < 5 do
			wait(0.1)
			timeout = timeout + 0.1
		end
		
		if not getDataSuccess then
			warn("Timeout getting gear data")
			return false
		end

		-- Process gear data to find luck boost
		local luckBoost = 0
		local rollPenalty = 0

		if GetRawGearData and gearData and gearData.equippedGear then
			-- Raw data format
			local gearInfo = gearModule.Gears[gearData.equippedGear]
			if gearInfo then
				luckBoost = gearInfo.luckBoost or 0
				rollPenalty = gearInfo.rollPenalty or 0
			end
		elseif GetFormattedGearInventory and gearData then
			-- Formatted data - find equipped gear
			for _, gear in ipairs(gearData or {}) do
				if gear and gear.isEquipped then
					luckBoost = gear.luckBoost or 0
					rollPenalty = gear.rollPenalty or 0
					break
				end
			end
		end

		-- Update the luck GUI
		_G.updateBadgeLuckBoost(luckBoost)
		print("✅ Updated luck boost from gear: +" .. luckBoost .. "%")
		return true
	end)
	
	if not success then
		warn("❌ Error updating luck from gear: " .. tostring(err))
		return false
	end
	
	return success
end

-- Throttled update function
local function throttledUpdateLuckFromGear()
	local currentTime = tick()
	if currentTime - lastUpdateTime < UPDATE_COOLDOWN then
		return -- Skip update if too soon
	end
	
	lastUpdateTime = currentTime
	return updateLuckFromGear()
end

-- Run the update when the script loads
wait(3)  -- Wait for other systems to initialize
updateLuckFromGear()

-- Listen for gear inventory updates
local OpenGearMerchantGUI = ReplicatedStorage:WaitForChild("OpenGearMerchantGUI", 10)
if OpenGearMerchantGUI then
	OpenGearMerchantGUI.OnClientEvent:Connect(function(action)
		if action == "updateInventory" then
			wait(0.5)
			throttledUpdateLuckFromGear()
		end
	end)
end

-- Also listen for inventory UI visibility changes with throttling
local function onInventoryToggled()
	local PlayerGui = player:WaitForChild("PlayerGui")
	local InventoryGui = PlayerGui:WaitForChild("InventoryGui", 5)

	if InventoryGui then
		InventoryGui:GetPropertyChangedSignal("Visible"):Connect(function()
			if InventoryGui.Visible then
				wait(0.5)
				throttledUpdateLuckFromGear()
			end
		end)
	end
end

onInventoryToggled()

-- Expose global function for manual updates (with throttling)
_G.UpdateLuckFromGear = throttledUpdateLuckFromGear

-- Cleanup connections when player leaves to prevent memory leaks
Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == player then
		-- Clean up any global references
		if _G.UpdateLuckFromGear == throttledUpdateLuckFromGear then
			_G.UpdateLuckFromGear = nil
		end
		print("🧹 Cleaned up Gear Luck Integration for " .. player.Name)
	end
end)

print("✅ Gear Luck Integration loaded - connecting gear system with luck display")