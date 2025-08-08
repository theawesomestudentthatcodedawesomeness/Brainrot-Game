local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Create a function to manually update luck from gears
local function updateLuckFromGear()
	-- Check if the luck GUI system is loaded
	if _G.updateBadgeLuckBoost then
		-- Wait for the LuckBoostEvent to initialize the badge boost
		local luckBoostEvent = ReplicatedStorage:WaitForChild("LuckBoostEvent", 10)
		if not luckBoostEvent then
			warn("LuckBoostEvent not found in ReplicatedStorage")
			return
		end

		-- Manually trigger update if needed
		local GearRemotes = ReplicatedStorage:FindFirstChild("GearRemotes")
		if GearRemotes then
			local GearData = require(ReplicatedStorage:WaitForChild("GearData"))

			-- Check if direct gear system is available
			local GetRawGearData = GearRemotes:FindFirstChild("GetRawGearData")
			local GetFormattedGearInventory = GearRemotes:FindFirstChild("GetFormattedGearInventory")

			if GetRawGearData or GetFormattedGearInventory then
				-- Use whichever function is available
				local remoteFunc = GetRawGearData or GetFormattedGearInventory

				-- Get gear data
				local gearData = remoteFunc:InvokeServer()

				-- Process gear data to find luck boost
				local luckBoost = 0
				local rollPenalty = 0

				if GetRawGearData and gearData and gearData.equippedGear then
					-- Raw data format
					local gearInfo = GearData.Gears[gearData.equippedGear]
					if gearInfo then
						luckBoost = gearInfo.luckBoost or 0
						rollPenalty = gearInfo.rollPenalty or 0
					end
				elseif GetFormattedGearInventory then
					-- Formatted data - find equipped gear
					for _, gear in ipairs(gearData or {}) do
						if gear.isEquipped then
							luckBoost = gear.luckBoost or 0
							rollPenalty = gear.rollPenalty or 0
							break
						end
					end
				end

				-- Update the luck GUI
				if _G.updateBadgeLuckBoost then
					_G.updateBadgeLuckBoost(luckBoost)
					print("Updated luck boost from gear: +" .. luckBoost .. "%")
				end
			end
		end
	end
end

-- Run the update when the script loads
task.wait(3)  -- Wait for other systems to initialize
updateLuckFromGear()

-- Listen for gear inventory updates
local OpenGearMerchantGUI = ReplicatedStorage:WaitForChild("OpenGearMerchantGUI", 10)
if OpenGearMerchantGUI then
	OpenGearMerchantGUI.OnClientEvent:Connect(function(action)
		if action == "updateInventory" then
			task.wait(0.5)
			updateLuckFromGear()
		end
	end)
end

-- Also listen for inventory UI visibility changes
local function onInventoryToggled()
	local PlayerGui = player:WaitForChild("PlayerGui")
	local InventoryGui = PlayerGui:WaitForChild("InventoryGui", 5)

	if InventoryGui then
		-- ? FIXED: Use safe monitoring instead of property change signal
		local function monitorInventoryChanges()
			task.spawn(function()
				local lastVisible = false
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
					end
				end
			end)
		end

		monitorInventoryChanges()
	end
end

onInventoryToggled()

-- Expose global function for manual updates
_G.UpdateLuckFromGear = updateLuckFromGear

print("Gear Luck Integration loaded - connecting gear system with luck display")