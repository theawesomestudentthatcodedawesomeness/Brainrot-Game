-- LocalScript in StarterPlayerScripts
-- Name: BrainrotVisualsClient

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BrainrotDefinitions = require(ReplicatedStorage:WaitForChild("BrainrotDefinitions"))
local EquipBrainrotRemote = ReplicatedStorage:WaitForChild("EquipBrainrotRemote")

local function removeOldVisuals(character)
	for _, child in ipairs(character:GetChildren()) do
		if child.Name == "BrainrotStand" or child.Name == "BrainrotBillboard" then
			child:Destroy()
		end
	end
end

local function applyBrainrotVisuals(character, brainrotName)
	if not character or not character.Parent then return end

	removeOldVisuals(character)

	if not brainrotName then return end -- If nil, just remove visuals

	local def = BrainrotDefinitions.Lookup[brainrotName]
	if not def then return end

	-- Create Billboard (title and odds) 
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BrainrotBillboard"
	billboard.Adornee = character:FindFirstChild("Head") or character:FindFirstChildWhichIsA("BasePart")
	billboard.Size = UDim2.new(0, 300, 0, 70)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = character

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1,0,1,0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = string.format("1 in %s\n%s", tostring(def.odds), brainrotName)
	textLabel.Font = Enum.Font.Arcade
	textLabel.TextScaled = true
	textLabel.TextColor3 = def.titleColor or def.color or Color3.new(1,1,1)
	textLabel.TextStrokeTransparency = 0.3
	textLabel.TextStrokeColor3 = Color3.new(0,0,0)
	textLabel.Parent = billboard
end

-- Listen for equip broadcasts from server
EquipBrainrotRemote.OnClientEvent:Connect(function(userId, brainrotName)
	local player = Players:GetPlayerByUserId(userId)
	if player and player.Character then
		applyBrainrotVisuals(player.Character, brainrotName)
	end
end)

-- Handle when players spawn after we're already in the game
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- The server will send us this player's equipped brainrot shortly
	end)
end)