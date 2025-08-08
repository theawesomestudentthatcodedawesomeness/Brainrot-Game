-- ServerScriptService - CombatZoneValidation.lua
-- Server-side combat validation to prevent exploits
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create validation remote
local CombatRemotes = ReplicatedStorage:WaitForChild("CombatRemotes")
local ValidateCombatRemote = CombatRemotes:FindFirstChild("ValidateCombat")
if not ValidateCombatRemote then
	ValidateCombatRemote = Instance.new("RemoteFunction")
	ValidateCombatRemote.Name = "ValidateCombat"
	ValidateCombatRemote.Parent = CombatRemotes
end

-- Server-side validation function
ValidateCombatRemote.OnServerInvoke = function(player)
	-- Use the global function from CombatZoneManager
	if _G.IsPlayerInCombatZone then
		return _G.IsPlayerInCombatZone(player)
	end
	return false -- Default to blocking combat if system not available
end

-- Monitor for potential exploits
local function logCombatAttempt(player, allowed)
	local status = allowed and "ALLOWED" or "BLOCKED"
	print(string.format("??? Combat attempt by %s: %s", player.Name, status))
end

-- Enhanced validation with logging
_G.ValidatePlayerCombat = function(player)
	local allowed = _G.IsPlayerInCombatZone and _G.IsPlayerInCombatZone(player) or false
	logCombatAttempt(player, allowed)
	return allowed
end

print("??? Combat Zone Server Validation Ready!")