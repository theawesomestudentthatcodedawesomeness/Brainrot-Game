local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("?? STARTUP: Looking for existing folders and creating remotes...")

-- Wait for the BrainrotVFX folder
local vfxFolder = ReplicatedStorage:WaitForChild("BrainrotVFX", 5) -- waits up to 10 seconds
if not vfxFolder then
	warn("! WARNING: BrainrotVFX folder not found in ReplicatedStorage after 10 seconds!")
	return
end
print("? Found BrainrotVFX folder")

-- Create MerchantRemotes folder and events
local merchantRemotes = ReplicatedStorage:FindFirstChild("MerchantRemotes")
if not merchantRemotes then
	merchantRemotes = Instance.new("Folder")
	merchantRemotes.Name = "MerchantRemotes"
	merchantRemotes.Parent = ReplicatedStorage
	print("? Created MerchantRemotes folder")
end

local function initializeBadgeSystem()
	local badgeRemotes = ReplicatedStorage:FindFirstChild("BadgeRemotes")
	if not badgeRemotes then
		badgeRemotes = Instance.new("Folder")
		badgeRemotes.Name = "BadgeRemotes"
		badgeRemotes.Parent = ReplicatedStorage
	end

	local badgeSystemReady = Instance.new("BoolValue")
	badgeSystemReady.Name = "BadgeSystemReady"
	badgeSystemReady.Value = true
	badgeSystemReady.Parent = badgeRemotes
end

spawn(initializeBadgeSystem)

-- MerchantRemotes Events
local merchantEvents = {
	"OpenShop",
	"AddIngredient", 
	"CraftItem",
	"CloseShop"
}

for _, eventName in ipairs(merchantEvents) do
	if not merchantRemotes:FindFirstChild(eventName) then
		local newEvent = Instance.new("RemoteEvent")
		newEvent.Name = eventName
		newEvent.Parent = merchantRemotes
		print("? Created MerchantRemote: " .. eventName)
	end
end

-- Create BadgeRemotes folder and events
local badgeRemotes = ReplicatedStorage:FindFirstChild("BadgeRemotes")
if not badgeRemotes then
	badgeRemotes = Instance.new("Folder")
	badgeRemotes.Name = "BadgeRemotes"
	badgeRemotes.Parent = ReplicatedStorage
	print("? Created BadgeRemotes folder")
end

-- BadgeRemotes Events
local badgeEvents = {
	"UpdateBadges",
	"EquipBadge",
	"UnequipBadge"
}

for _, eventName in ipairs(badgeEvents) do
	if not badgeRemotes:FindFirstChild(eventName) then
		local newEvent = Instance.new("RemoteEvent")
		newEvent.Name = eventName
		newEvent.Parent = badgeRemotes
		print("? Created BadgeRemote: " .. eventName)
	end
end

-- BadgeRemotes Functions
local badgeFunctions = {
	"GetBadges",
	"GetEquippedBadges"
}

for _, functionName in ipairs(badgeFunctions) do
	if not badgeRemotes:FindFirstChild(functionName) then
		local newFunction = Instance.new("RemoteFunction")
		newFunction.Name = functionName
		newFunction.Parent = badgeRemotes
		print("? Created BadgeFunction: " .. functionName)
	end
end

-- Create LuckBoostEvent for badge system
if not ReplicatedStorage:FindFirstChild("LuckBoostEvent") then
	local luckBoostEvent = Instance.new("RemoteEvent")
	luckBoostEvent.Name = "LuckBoostEvent"
	luckBoostEvent.Parent = ReplicatedStorage
	print("? Created LuckBoostEvent")
end

-- Create BrainrotSounds folder if it doesn't exist
local soundsFolder = ReplicatedStorage:FindFirstChild("BrainrotSounds")
if not soundsFolder then
	soundsFolder = Instance.new("Folder")
	soundsFolder.Name = "BrainrotSounds"
	soundsFolder.Parent = ReplicatedStorage
	print("? Created BrainrotSounds folder")
end

-- Create EquipBrainrotVisual RemoteEvent if it doesn't exist
if not ReplicatedStorage:FindFirstChild("EquipBrainrotVisual") then
	local equipBrainrotVisual = Instance.new("RemoteEvent")
	equipBrainrotVisual.Name = "EquipBrainrotVisual"
	equipBrainrotVisual.Parent = ReplicatedStorage
	print("? Created EquipBrainrotVisual RemoteEvent")
end

-- Create ShowBrainrotOnJLoEvent RemoteEvent if it doesn't exist
if not ReplicatedStorage:FindFirstChild("ShowBrainrotOnJLoEvent") then
	local showBrainrotOnJLo = Instance.new("RemoteEvent")
	showBrainrotOnJLo.Name = "ShowBrainrotOnJLoEvent"
	showBrainrotOnJLo.Parent = ReplicatedStorage
	print("? Created ShowBrainrotOnJLoEvent RemoteEvent")
end

-- Create EquipBrainrotTitle RemoteEvent if it doesn't exist
if not ReplicatedStorage:FindFirstChild("EquipBrainrotTitle") then
	local equipBrainrotTitle = Instance.new("RemoteEvent")
	equipBrainrotTitle.Name = "EquipBrainrotTitle"
	equipBrainrotTitle.Parent = ReplicatedStorage
	print("? Created EquipBrainrotTitle RemoteEvent")
end

print("?? STARTUP: All systems initialized successfully!")

-- Small delay to ensure everything is ready
wait(1)