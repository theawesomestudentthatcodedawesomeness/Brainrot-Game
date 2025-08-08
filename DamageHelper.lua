-- ReplicatedStorage - DamageHelper.lua
-- Helper functions for damage validation

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CombatRemotes = ReplicatedStorage:WaitForChild("CombatRemotes")
local ValidateDamageRemote = CombatRemotes:WaitForChild("ValidateDamage")

local DamageHelper = {}

-- Client-side damage check
function DamageHelper.CanDealDamage()
	if _G.CanDealDamage then
		return _G.CanDealDamage()
	end
	return true -- Default to allowing damage if system not loaded
end

-- Server-side damage validation
function DamageHelper.ValidateServerDamage(attacker, target)
	if _G.CanPlayerDealDamage then
		return _G.CanPlayerDealDamage(attacker, target)
	end

	-- Fallback to remote validation
	local success, result = pcall(function()
		return ValidateDamageRemote:InvokeServer(target)
	end)

	return success and result
end

-- Show subtle "no damage" effect
function DamageHelper.ShowNoDamageEffect(character)
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Create subtle "blocked" effect
	local effect = Instance.new("Explosion")
	effect.Position = humanoidRootPart.Position
	effect.BlastRadius = 0
	effect.BlastPressure = 0
	effect.Visible = false
	effect.Parent = game.Workspace

	-- Just a small visual effect, no damage
	print("??? Attack blocked - outside combat zone")
end

return DamageHelper