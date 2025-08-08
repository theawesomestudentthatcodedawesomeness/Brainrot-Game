-- GearLuckProtectorFixed.client.lua
-- Place in StarterPlayerScripts
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Get GearRemotes without infinitely waiting
local GearRemotes = ReplicatedStorage:FindFirstChild("GearRemotes")
if not GearRemotes then
	GearRemotes = ReplicatedStorage:WaitForChild("GearRemotes", 10) -- Wait with timeout
	if not GearRemotes then
		warn("? GearRemotes not found, gear luck protection limited")
		GearRemotes = {} -- Empty table as fallback
	end
end

-- Safe way to get remotes without infinite yield
local function safeGetRemote(parent, name, timeout)
	if not parent then return nil end

	local remote = parent:FindFirstChild(name)
	if remote then return remote end

	-- Try to wait for it with a timeout
	local success = pcall(function()
		remote = parent:WaitForChild(name, timeout or 5)
	end)

	return remote
end

-- Get gear inventory remote safely
local GetGearInventory = safeGetRemote(GearRemotes, "GetGearInventory")

-- Function to get current equipped gear's luck boost
local function getEquippedGearBoost()
	if not GetGearInventory then return 0 end

	local success, gearData = pcall(function()
		return GetGearInventory:InvokeServer()
	end)

	if success and gearData then
		if gearData.inventory and gearData.equippedGear then
			for _, gear in ipairs(gearData.inventory) do
				if gear.id == gearData.equippedGear then
					return gear.luckBoost or 0
				end
			end
		end
	end

	return 0
end

-- Wait a moment for other scripts to initialize
wait(2)

-- Setup protection
local function setupProtection()
	-- Cache the last valid gear boost
	local lastKnownBoost = getEquippedGearBoost()
	print("?? Initial gear boost: +" .. lastKnownBoost .. "%")

	-- Apply boost if needed
	if lastKnownBoost > 0 and _G.updateBadgeLuckBoost then
		_G.updateBadgeLuckBoost(lastKnownBoost)
	end

	-- Create a new handler for the update function
	if _G.updateBadgeLuckBoost then
		local originalUpdate = _G.updateBadgeLuckBoost

		_G.updateBadgeLuckBoost = function(newBoost)
			-- If server tries to set to 0 but we have a gear with boost
			if (newBoost == 0 or newBoost == nil) and lastKnownBoost > 0 then
				print("??? Blocking server attempt to set gear boost to 0")
				-- Call original with the last known boost instead
				originalUpdate(lastKnownBoost)
				return
			end

			-- Update our cache if it's a real boost
			if newBoost and newBoost > 0 then
				lastKnownBoost = newBoost
			end

			-- Call original function
			originalUpdate(newBoost)
		end

		print("??? Gear luck protection enabled")
	end

	-- Periodically check and restore gear boost (without UpdateGearLuck remote dependency)
	spawn(function()
		while wait(5) do
			local currentBoost = getEquippedGearBoost()

			-- Only update if we have a real boost from gear
			if currentBoost > 0 then
				lastKnownBoost = currentBoost

				-- Apply the boost (will be protected by our handler)
				if _G.updateBadgeLuckBoost then
					_G.updateBadgeLuckBoost(currentBoost)
				end
			end
		end
	end)
end

-- Try to run protection setup
local success, errorMsg = pcall(setupProtection)
if not success then
	warn("? Error in gear luck protection: " .. tostring(errorMsg))
	-- Try basic protection as fallback
	if _G.updateBadgeLuckBoost then
		local originalUpdate = _G.updateBadgeLuckBoost
		_G.updateBadgeLuckBoost = function(newBoost)
			if newBoost and newBoost > 0 then
				originalUpdate(newBoost)
			end
			-- Ignore attempts to set to 0
		end
	end
end

print("??? Gear Luck Protector loaded")