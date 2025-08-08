-- Script: ServerScriptService>AutoAddVerification (Optional debugging script)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for all systems to load
local function waitForSystems()
	local InventoryRemotes = ReplicatedStorage:WaitForChild("InventoryRemotes", 10)
	local GearRemotes = ReplicatedStorage:WaitForChild("GearRemotes", 10)

	if not InventoryRemotes then
		warn("?? VERIFICATION: InventoryRemotes not found!")
		return false
	end

	if not GearRemotes then
		warn("?? VERIFICATION: GearRemotes not found!")
		return false
	end

	local AddBrainrotItem = InventoryRemotes:FindFirstChild("AddBrainrotItem")
	local GetAutoAdd = GearRemotes:FindFirstChild("GetAutoAdd")
	local AddBrainrot = GearRemotes:FindFirstChild("AddBrainrot")

	if not AddBrainrotItem then
		warn("?? VERIFICATION: AddBrainrotItem not found!")
		return false
	end

	if not GetAutoAdd then
		warn("?? VERIFICATION: GetAutoAdd not found!")
		return false
	end

	if not AddBrainrot then
		warn("?? VERIFICATION: AddBrainrot not found!")
		return false
	end

	print("?? VERIFICATION: All auto-add systems ready!")
	return true
end

-- Test the integration
spawn(function()
	wait(5) -- Let everything load

	if waitForSystems() then
		print("?? VERIFICATION: Auto-Add integration successfully loaded!")
		print("?? VERIFICATION: When players roll brainrots, they will be auto-added to gear recipes if enabled.")
	else
		warn("?? VERIFICATION: Auto-Add integration failed to load properly!")
	end
end)