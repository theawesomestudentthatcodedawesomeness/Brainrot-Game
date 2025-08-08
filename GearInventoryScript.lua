local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for gear remotes
local GearRemotes = ReplicatedStorage:WaitForChild("GearRemotes")
local GetRawGearData = GearRemotes:FindFirstChild("GetRawGearData") or GearRemotes:WaitForChild("GetFormattedGearInventory")
local LuckBoostEvent = ReplicatedStorage:WaitForChild("LuckBoostEvent")

-- Load gear data module
local GearData = require(ReplicatedStorage:WaitForChild("GearData"))

-- Connect to original inventory events
local InventoryRemotes = ReplicatedStorage:FindFirstChild("InventoryRemotes")
if not InventoryRemotes then
	InventoryRemotes = Instance.new("Folder")
	InventoryRemotes.Name = "InventoryRemotes"
	InventoryRemotes.Parent = ReplicatedStorage
end

-- Create a new RemoteEvent for inventory updates
local InventoryUpdated = InventoryRemotes:FindFirstChild("InventoryUpdated") or Instance.new("RemoteEvent")
InventoryUpdated.Name = "InventoryUpdated"
InventoryUpdated.Parent = InventoryRemotes

-- Track when inventory is opened to refresh gear tab
local OpenInventory = ReplicatedStorage:FindFirstChild("OpenInventory") or Instance.new("RemoteEvent")
OpenInventory.Name = "OpenInventory"
OpenInventory.Parent = ReplicatedStorage

-- Function to get player's current equipped gear and luck boost
local function getPlayerLuckFromGear(player)
	-- Try to get gear data directly from remotes
	local gearData = nil
	local luckBoost = 0
	local rollPenalty = 0

	pcall(function()
		gearData = GetRawGearData:InvokeServer(player)
	end)

	if gearData and gearData.equippedGear then
		local gearInfo = GearData.Gears[gearData.equippedGear]
		if gearInfo then
			luckBoost = gearInfo.luckBoost or 0
			rollPenalty = gearInfo.rollPenalty or 0
			print("Player " .. player.Name .. " has gear equipped: +" .. luckBoost .. "% luck")
		end
	end

	return luckBoost, rollPenalty
end

-- Update luck boost for all players periodically
local function updateAllPlayersLuckBoost()
	for _, player in pairs(Players:GetPlayers()) do
		local luckBoost, rollPenalty = getPlayerLuckFromGear(player)

		-- Update the client-side luck GUI
		LuckBoostEvent:FireClient(player, luckBoost, rollPenalty)
	end
end

-- Run update on a timer
spawn(function()
	while wait(10) do  -- Check every 10 seconds
		updateAllPlayersLuckBoost()
	end
end)

-- Also update when inventory is opened
OpenInventory.OnServerEvent:Connect(function(player)
	wait(0.5)  -- Short delay to ensure everything is loaded
	local luckBoost, rollPenalty = getPlayerLuckFromGear(player)
	LuckBoostEvent:FireClient(player, luckBoost, rollPenalty)
end)

print("Gear Inventory Bridge loaded - connecting gear system with luck GUI")