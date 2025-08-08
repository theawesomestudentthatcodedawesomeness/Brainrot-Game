-- ServerScriptService - CombatZoneManager.lua
-- Enhanced with damage validation
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

-- Create RemoteEvents
local CombatRemotes = ReplicatedStorage:FindFirstChild("CombatRemotes")
if not CombatRemotes then
	CombatRemotes = Instance.new("Folder")
	CombatRemotes.Name = "CombatRemotes"
	CombatRemotes.Parent = ReplicatedStorage
end

local CombatZoneStatusEvent = CombatRemotes:FindFirstChild("CombatZoneStatus")
if not CombatZoneStatusEvent then
	CombatZoneStatusEvent = Instance.new("RemoteEvent")
	CombatZoneStatusEvent.Name = "CombatZoneStatus"
	CombatZoneStatusEvent.Parent = CombatRemotes
end

-- NEW: Damage validation remote
local ValidateDamageRemote = CombatRemotes:FindFirstChild("ValidateDamage")
if not ValidateDamageRemote then
	ValidateDamageRemote = Instance.new("RemoteFunction")
	ValidateDamageRemote.Name = "ValidateDamage"
	ValidateDamageRemote.Parent = CombatRemotes
end

-- Track players in combat zones
local playersInCombatZone = {}
local combatZones = {}

-- Function to check if position is in combat zone
local function isPositionInCombatZone(position)
	for _, zone in pairs(combatZones) do
		if zone and zone.Parent then
			local zonePos = zone.Position
			local zoneSize = zone.Size

			local minX, maxX = zonePos.X - zoneSize.X/2, zonePos.X + zoneSize.X/2
			local minY, maxY = zonePos.Y - zoneSize.Y/2, zonePos.Y + zoneSize.Y/2
			local minZ, maxZ = zonePos.Z - zoneSize.Z/2, zonePos.Z + zoneSize.Z/2

			if position.X >= minX and position.X <= maxX and
				position.Y >= minY and position.Y <= maxY and
				position.Z >= minZ and position.Z <= maxZ then
				return true
			end
		end
	end
	return false
end

-- Find combat zones
local function findCombatZones()
	combatZones = {}

	local function searchForCombatZones(parent)
		for _, child in pairs(parent:GetChildren()) do
			if child:IsA("BasePart") and string.find(child.Name:lower(), "combatzone") then
				table.insert(combatZones, child)
				child.CanCollide = false
				child.Transparency = 0.7
				child.Material = Enum.Material.ForceField
				child.BrickColor = BrickColor.new("Bright red")
				print("? Combat Zone registered:", child.Name)
			elseif child:IsA("Folder") or child:IsA("Model") then
				searchForCombatZones(child)
			end
		end
	end

	searchForCombatZones(workspace)
	print("?? Found", #combatZones, "combat zones")
end

-- Update player combat status
local function updatePlayerCombatStatus()
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local playerPos = player.Character.HumanoidRootPart.Position
			local inCombatZone = isPositionInCombatZone(playerPos)

			if playersInCombatZone[player.UserId] ~= inCombatZone then
				playersInCombatZone[player.UserId] = inCombatZone
				CombatZoneStatusEvent:FireClient(player, inCombatZone)

				if inCombatZone then
					print("?? " .. player.Name .. " entered combat zone")
				else
					print("??? " .. player.Name .. " left combat zone")
				end
			end
		end
	end
end

-- NEW: Damage validation function
ValidateDamageRemote.OnServerInvoke = function(player, targetPlayer)
	-- Check if BOTH attacker and target are in combat zones
	local attackerInZone = playersInCombatZone[player.UserId] or false
	local targetInZone = playersInCombatZone[targetPlayer.UserId] or false

	local canDealDamage = attackerInZone and targetInZone

	if not canDealDamage then
		print("??? Damage blocked:", player.Name, "->", targetPlayer.Name, "(Zone status: attacker=" .. tostring(attackerInZone) .. ", target=" .. tostring(targetInZone) .. ")")
	end

	return canDealDamage
end

-- Initialize
findCombatZones()

-- Update positions every 0.5 seconds
local lastUpdate = 0
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastUpdate >= 0.5 then
		lastUpdate = now
		updatePlayerCombatStatus()
	end
end)

-- Re-scan for combat zones when new parts added
workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("BasePart") and string.find(descendant.Name:lower(), "combatzone") then
		wait(0.1)
		findCombatZones()
	end
end)

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
	playersInCombatZone[player.UserId] = nil
end)

-- Global function for other scripts
_G.IsPlayerInCombatZone = function(player)
	return playersInCombatZone[player.UserId] or false
end

_G.CanPlayerDealDamage = function(attacker, target)
	local attackerInZone = playersInCombatZone[attacker.UserId] or false
	local targetInZone = playersInCombatZone[target.UserId] or false
	return attackerInZone and targetInZone
end

print("?? Enhanced Combat Zone Manager - Damage Validation Ready!")