-- Place this in StarterPlayerScripts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local GearRemotes = ReplicatedStorage:WaitForChild("GearRemotes")
local GetGearInventory = GearRemotes:WaitForChild("GetGearInventory", 10)

-- Cache the last known gear boost
local lastKnownBoost = 0

-- Get the current equipped gear's luck boost
local function getEquippedGearBoost()
	local success, gearData = pcall(function() 
		return GetGearInventory:InvokeServer()
	end)

	if success and gearData then
		-- Handle different response formats
		if gearData.inventory and gearData.equippedGear then
			for _, gear in ipairs(gearData.inventory) do
				if gear.id == gearData.equippedGear then
					return gear.luckBoost or 0
				end
			end
		end
	end

	return lastKnownBoost -- Return last known boost if we can't get current
end

-- Listen for the LuckBoostEvent and override with gear boost when needed
local function protectGearBoost()
	local LuckBoostEvent = ReplicatedStorage:FindFirstChild("LuckBoostEvent")
	if not LuckBoostEvent then
		LuckBoostEvent = Instance.new("RemoteEvent")
		LuckBoostEvent.Name = "LuckBoostEvent"
		LuckBoostEvent.Parent = ReplicatedStorage
	end

	-- Get initial boost value
	wait(2) -- Wait for gear system to initialize
	lastKnownBoost = getEquippedGearBoost()
	print("? Initial equipped gear boost: +" .. lastKnownBoost .. "%")

	-- Set initial value
	if _G.updateBadgeLuckBoost then
		_G.updateBadgeLuckBoost(lastKnownBoost)
	end

	-- Listen to the event
	LuckBoostEvent.OnClientEvent:Connect(function(boost)
		-- If server is trying to set nil or 0
		if boost == nil or boost == 0 then
			-- Check current gear boost
			local currentBoost = getEquippedGearBoost()

			-- If we have an equipped gear with luck boost
			if currentBoost > 0 then
				-- Override with the gear's boost
				print("? Protecting gear boost from nil/0 override: +" .. currentBoost .. "%")

				-- Wait a moment, then reapply
				wait(0.1)
				if _G.updateBadgeLuckBoost then
					_G.updateBadgeLuckBoost(currentBoost)
				end

				-- Update cache
				lastKnownBoost = currentBoost
			end
		else
			-- Server sent a non-zero boost, update cache
			lastKnownBoost = boost
		end
	end)

	-- Periodically refresh gear boost
	spawn(function()
		while wait(5) do
			local currentBoost = getEquippedGearBoost()
			if currentBoost > 0 and _G.updateBadgeLuckBoost then
				_G.updateBadgeLuckBoost(currentBoost)
				lastKnownBoost = currentBoost
			end
		end
	end)
end

-- Start protection
protectGearBoost()

print("? Gear Boost Protection initialized")