-- BrainrotPlayerTitleClient.lua
-- Shows equipped title above player avatars; shows preview title above JLo dummy only

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local workspace = game:GetService("Workspace")

local PlayerTitleDisplayEvent = ReplicatedStorage:WaitForChild("PlayerTitleDisplayEvent")
local ShowBrainrotOnJLoEvent = ReplicatedStorage:WaitForChild("ShowBrainrotOnJLoEvent")

local player = Players.LocalPlayer

-- Store billboards for cleanup
local activeBillboards = {} -- [character] = BillboardGui

-- Utility: Remove all billboards from character
local function cleanupBillboardsForCharacter(character)
	if not character then return end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BillboardGui") and child.Name:match("^BrainrotPlayerTitle_") then
			child:Destroy()
		end
	end
end

-- Utility: Create billboard above character's head
local function createTitleBillboard(character, userId, brainrotName, brainrotOdds, brainrotColor)
	cleanupBillboardsForCharacter(character)
	if not brainrotName or not brainrotOdds then return end
	local head = character:FindFirstChild("Head") or character:FindFirstChildWhichIsA("BasePart")
	if not head then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BrainrotPlayerTitle_" .. tostring(userId)
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 300, 0, 70)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 60
	billboard.Parent = character

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1,0,1,0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.Arcade
	titleLabel.Text = string.format("1 in %s\n%s", tostring(brainrotOdds), brainrotName)
	titleLabel.TextColor3 = brainrotColor or Color3.fromRGB(255,255,255)
	titleLabel.TextScaled = true
	titleLabel.TextStrokeTransparency = 0.3
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	titleLabel.Parent = billboard

	-- Fade in
	titleLabel.TextTransparency = 1
	TweenService:Create(titleLabel, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()

	activeBillboards[character] = billboard
end

-- Listen for equipped title display event
PlayerTitleDisplayEvent.OnClientEvent:Connect(function(userId, brainrotName, brainrotOdds, brainrotColor)
	local targetPlayer = Players:GetPlayerByUserId(userId)
	if not targetPlayer or not targetPlayer.Character then return end
	if not brainrotName then
		-- Remove billboard
		cleanupBillboardsForCharacter(targetPlayer.Character)
		activeBillboards[targetPlayer.Character] = nil
		return
	end
	createTitleBillboard(targetPlayer.Character, userId, brainrotName, brainrotOdds, brainrotColor)
end)

-- Clean up billboards on own character respawn
player.CharacterAdded:Connect(function(character)
	cleanupBillboardsForCharacter(character)
end)

-- JLo dummy preview (for collection preview only; does NOT equip for player)
local function getJLoHead()
	local JLo = workspace:FindFirstChild("JLo")
	if not JLo then return nil end
	return JLo:FindFirstChild("Head") or JLo:FindFirstChildWhichIsA("BasePart")
end

local function removeAllJLoTitles(head)
	if not head then return end
	for _, gui in ipairs(head:GetChildren()) do
		if gui:IsA("BillboardGui") and gui.Name == "BrainrotTitleBillboard" then
			gui:Destroy()
		end
	end
end

local function showJLoTitle(brainrotName, brainrotOdds, brainrotColor)
	local head = getJLoHead()
	if not head then return end
	removeAllJLoTitles(head)
	if not brainrotName or not brainrotOdds then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "BrainrotTitleBillboard"
	bb.Adornee = head
	bb.Size = UDim2.new(0, 300, 0, 70)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 30
	bb.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,0,1,0)
	label.BackgroundTransparency = 1
	label.Text = string.format("1 in %s\n%s", tostring(brainrotOdds), brainrotName)
	label.TextColor3 = brainrotColor or Color3.fromRGB(255,255,255)
	label.Font = Enum.Font.Arcade
	label.TextScaled = true
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	label.Parent = bb

	-- Fade in
	label.TextTransparency = 1
	TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
end

ShowBrainrotOnJLoEvent.OnClientEvent:Connect(showJLoTitle)

print("?? Brainrot Player Title Client: Equipped title above player, preview above JLo dummy.")