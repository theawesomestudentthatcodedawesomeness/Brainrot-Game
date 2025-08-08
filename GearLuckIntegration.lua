local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Error handling wrapper
local function safeCall(func, ...)
	local success, result = pcall(func, ...)
	if not success then
		warn("GearLuckIntegration Error: " .. tostring(result))
		return nil
	end
	return result
end

-- Create a function to manually update luck from gears with comprehensive error handling
local function updateLuckFromGear()
	local success = safeCall(function()
		-- Check if the luck GUI system is loaded
		if not _G.updateBadgeLuckBoost then
			return -- Luck system not ready yet
		end

		-- Wait for the LuckBoostEvent to initialize the badge boost
		local luckBoostEvent = ReplicatedStorage:WaitForChild("LuckBoostEvent", 10)
		if not luckBoostEvent then
			warn("LuckBoostEvent not found in ReplicatedStorage")
			return
		end

		-- Manually trigger update if needed
		local GearRemotes = ReplicatedStorage:FindFirstChild("GearRemotes")
		if not GearRemotes then
			return -- Gear system not available
		end

		local GearData = ReplicatedStorage:FindFirstChild("GearData")
		if not GearData then
			warn("GearData module not found")
			return
		end

		local gearDataModule = safeCall(require, GearData)
		if not gearDataModule then
			return
		end

		-- Check if direct gear system is available
		local GetRawGearData = GearRemotes:FindFirstChild("GetRawGearData")
		local GetFormattedGearInventory = GearRemotes:FindFirstChild("GetFormattedGearInventory")

		if not (GetRawGearData or GetFormattedGearInventory) then
			return -- No gear remotes available
		end

		-- Use whichever function is available
		local remoteFunc = GetRawGearData or GetFormattedGearInventory
		if not remoteFunc or not remoteFunc:IsA("RemoteFunction") then
			return
		end

		-- Get gear data with error handling
		local gearData = safeCall(function()
			return remoteFunc:InvokeServer()
		end)

		if not gearData then
			return -- Failed to get gear data
		end

		-- Process gear data to find luck boost
		local luckBoost = 0
		local rollPenalty = 0

		if GetRawGearData and gearData and gearData.equippedGear then
			-- Raw data format
			local gearInfo = gearDataModule.Gears and gearDataModule.Gears[gearData.equippedGear]
			if gearInfo then
				luckBoost = tonumber(gearInfo.luckBoost) or 0
				rollPenalty = tonumber(gearInfo.rollPenalty) or 0
			end
		elseif GetFormattedGearInventory and type(gearData) == "table" then
			-- Formatted data - find equipped gear
			for _, gear in ipairs(gearData) do
				if gear and gear.isEquipped then
					luckBoost = tonumber(gear.luckBoost) or 0
					rollPenalty = tonumber(gear.rollPenalty) or 0
					break
				end
			end
		end

		-- Update the luck GUI with validation
		if _G.updateBadgeLuckBoost and type(luckBoost) == "number" and luckBoost >= 0 then
			safeCall(_G.updateBadgeLuckBoost, luckBoost)
			print("Updated luck boost from gear: +" .. luckBoost .. "%")
		end
	end)
	
	if not success then
		-- Silently fail - this function gets called frequently
	end
end

-- Run the update when the script loads with delay and error handling
local function initializeWithDelay()
	task.wait(3)  -- Wait for other systems to initialize
	updateLuckFromGear()
end

safeCall(initializeWithDelay)

-- Listen for gear inventory updates with error handling
local function setupInventoryListeners()
	local OpenGearMerchantGUI = ReplicatedStorage:WaitForChild("OpenGearMerchantGUI", 10)
	if OpenGearMerchantGUI and OpenGearMerchantGUI:IsA("RemoteEvent") then
		OpenGearMerchantGUI.OnClientEvent:Connect(function(action)
			if action == "updateInventory" then
				task.wait(0.5)
				updateLuckFromGear()
			end
		end)
	end
end

safeCall(setupInventoryListeners)

-- Enhanced inventory UI monitoring with error recovery
local function setupInventoryMonitoring()
	local function monitorInventory()
		local PlayerGui = player:WaitForChild("PlayerGui", 30)
		if not PlayerGui then return end

		local InventoryGui = PlayerGui:WaitForChild("InventoryGui", 5)
		if not InventoryGui then return end

		-- Use safe monitoring approach
		local lastVisible = false
		local connection
		
		connection = task.spawn(function()
			while task.wait(0.5) do
				local success, currentVisible = pcall(function()
					return InventoryGui.Visible
				end)

				if success and currentVisible ~= lastVisible then
					if currentVisible then
						task.wait(0.5)
						updateLuckFromGear()
					end
					lastVisible = currentVisible
				elseif not success then
					-- Alternative monitoring - check for UI activity
					safeCall(function()
						local activeChildren = 0
						for _, child in pairs(InventoryGui:GetChildren()) do
							if child:IsA("Frame") and child.Size.X.Scale > 0 then
								activeChildren = activeChildren + 1
							end
						end

						local currentlyActive = activeChildren > 0
						if currentlyActive ~= lastVisible then
							if currentlyActive then
								task.wait(0.5)
								updateLuckFromGear()
							end
							lastVisible = currentlyActive
						end
					end)
				end
			end
		end)
		
		-- Cleanup on character removal
		player.CharacterRemoving:Connect(function()
			if connection then
				task.cancel(connection)
			end
		end)
	end
	
	monitorInventory()
end

safeCall(setupInventoryMonitoring)

-- Expose global function for manual updates with error handling
_G.UpdateLuckFromGear = function()
	safeCall(updateLuckFromGear)
end

print("Optimized Gear Luck Integration loaded - connecting gear system with luck display")