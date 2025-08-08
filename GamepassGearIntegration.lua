-- Script: ServerScriptService>GamepassGearIntegration
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for systems to load
wait(5)

-- Hook into gear system
spawn(function()
	local GearRemotes = ReplicatedStorage:WaitForChild("GearRemotes", 30)
	if GearRemotes then
		print("?? Gear system found - setting up gamepass integration")

		-- Function to give gear to player via gear system
		_G.GiveGearViaSystem = function(player, gearId)
			if not _G.GetPlayerGearData then
				warn("? Gear system not available")
				return false
			end

			local playerData = _G.GetPlayerGearData(player.UserId)
			if not playerData then
				warn("? No player data found")
				return false
			end

			if not playerData.gearInventory then
				playerData.gearInventory = {}
			end

			-- Check if already has gear
			for _, ownedGearId in ipairs(playerData.gearInventory) do
				if ownedGearId == gearId then
					print("?? Player already has gear:", gearId)
					return true
				end
			end

			-- Add gear
			table.insert(playerData.gearInventory, gearId)

			-- Save data
			if _G.SavePlayerGearData then
				_G.SavePlayerGearData(player)
			end

			print("? Successfully gave gear", gearId, "to", player.Name)
			return true
		end

		print("? Gamepass-Gear integration ready")
	else
		warn("? Gear system not found after 30 seconds")
	end
end)