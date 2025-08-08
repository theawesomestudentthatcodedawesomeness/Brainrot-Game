-- StarterPlayerScripts - CombatZoneClient.lua
-- Clean combat zone system - allows animations but blocks damage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for combat remotes
local CombatRemotes = ReplicatedStorage:WaitForChild("CombatRemotes")
local CombatZoneStatusEvent = CombatRemotes:WaitForChild("CombatZoneStatus")

-- Combat status
local inCombatZone = false

-- Simple combat zone indicator
local function createCombatZoneIndicator()
	local existingGui = playerGui:FindFirstChild("CombatZoneGui")
	if existingGui then
		existingGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CombatZoneGui"
	screenGui.DisplayOrder = 5
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Simple combat zone indicator
	local indicator = Instance.new("Frame")
	indicator.Name = "CombatIndicator"
	indicator.Size = UDim2.new(0, 250, 0, 50)
	indicator.Position = UDim2.new(0.5, -125, 0, 20)
	indicator.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	indicator.BackgroundTransparency = 0.3
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	indicator.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = indicator

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -10, 1, -10)
	statusLabel.Position = UDim2.new(0, 5, 0, 5)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.Arcade
	statusLabel.Text = "COMBAT ZONE"
	statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	statusLabel.TextStrokeTransparency = 0.3
	statusLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	statusLabel.TextScaled = true
	statusLabel.Parent = indicator

	return screenGui
end

-- Update combat zone display
local function updateCombatZoneDisplay(show)
	local gui = playerGui:FindFirstChild("CombatZoneGui")
	if not gui then
		gui = createCombatZoneIndicator()
	end

	local indicator = gui:FindFirstChild("CombatIndicator")
	local statusLabel = indicator:FindFirstChild("StatusLabel")

	if show then
		indicator.Visible = true
		statusLabel.Text = "?? COMBAT ZONE ??"
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

		-- Gentle pulsing animation
		local pulseTween = TweenService:Create(statusLabel,
			TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{TextTransparency = 0.3}
		)
		pulseTween:Play()
	else
		indicator.Visible = false
	end
end

-- Handle combat zone status from server
CombatZoneStatusEvent.OnClientEvent:Connect(function(newInCombatZone)
	inCombatZone = newInCombatZone
	updateCombatZoneDisplay(inCombatZone)
end)

-- Set global flags for damage system to check
_G.IsInCombatZone = function()
	return inCombatZone
end

_G.CanDealDamage = function()
	return inCombatZone
end

-- Initialize
createCombatZoneIndicator()

print("?? Clean Combat Zone System Ready - Damage Control Only!")