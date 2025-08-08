local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("GEAR MERCHANT SERVER: Script starting")

-- Create remote event for opening GUI
local OpenGearMerchantGUI
if ReplicatedStorage:FindFirstChild("OpenGearMerchantGUI") then
	OpenGearMerchantGUI = ReplicatedStorage.OpenGearMerchantGUI
	print("GEAR MERCHANT SERVER: Found existing OpenGearMerchantGUI remote")
else
	OpenGearMerchantGUI = Instance.new("RemoteEvent")
	OpenGearMerchantGUI.Name = "OpenGearMerchantGUI"
	OpenGearMerchantGUI.Parent = ReplicatedStorage
	print("GEAR MERCHANT SERVER: Created new OpenGearMerchantGUI remote")
end

-- Get the NPC
local gearMerchant = script.Parent
local humanoidRootPart = gearMerchant:FindFirstChild("HumanoidRootPart")

-- Create humanoid root part if it doesn't exist
if not humanoidRootPart then
	print("GEAR MERCHANT SERVER: HumanoidRootPart not found - creating one")
	humanoidRootPart = Instance.new("Part")
	humanoidRootPart.Name = "HumanoidRootPart"
	humanoidRootPart.Size = Vector3.new(2, 2, 2)
	humanoidRootPart.Transparency = 1
	humanoidRootPart.CanCollide = false
	humanoidRootPart.Anchored = true

	-- Ensure the HumanoidRootPart has a position
	local existingPart = gearMerchant:FindFirstChildWhichIsA("BasePart")
	if existingPart then
		humanoidRootPart.Position = existingPart.Position
	end

	humanoidRootPart.Parent = gearMerchant
end

-- Recreate proximity prompt
local proximityPrompt = humanoidRootPart:FindFirstChildOfClass("ProximityPrompt")
if proximityPrompt then
	proximityPrompt:Destroy()
	print("GEAR MERCHANT SERVER: Removed existing proximity prompt")
end

-- Create a new prompt
proximityPrompt = Instance.new("ProximityPrompt")
proximityPrompt.Name = "GearMerchantPrompt"
proximityPrompt.ActionText = "Open Gear Shop"
proximityPrompt.ObjectText = "Gear Merchant"
proximityPrompt.HoldDuration = 0.5
proximityPrompt.MaxActivationDistance = 8
proximityPrompt.RequiresLineOfSight = false
proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
proximityPrompt.Parent = humanoidRootPart

print("GEAR MERCHANT SERVER: Created proximity prompt")

-- Handle proximity prompt triggered
proximityPrompt.Triggered:Connect(function(player)
	print("GEAR MERCHANT SERVER: Proximity prompt triggered by " .. player.Name)
	-- Only open the GUI when the player triggers the prompt
	OpenGearMerchantGUI:FireClient(player)
end)

print("GEAR MERCHANT SERVER: Script initialized")