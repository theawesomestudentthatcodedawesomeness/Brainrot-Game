local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ShowBrainrotOnJLoEvent = ReplicatedStorage:WaitForChild("ShowBrainrotOnJLoEvent")

local player = Players.LocalPlayer
local currentJLoTitle = nil

local function create3DTitleAboveJLo(jloModel, brainrotName, odds, color)
	if not jloModel then return nil end

	local head = jloModel:FindFirstChild("Head") or jloModel:FindFirstChildWhichIsA("BasePart")
	if not head then return nil end

	-- Clear previous JLo titles for this player
	for _, child in pairs(jloModel:GetChildren()) do
		if child:IsA("BillboardGui") and child.Name == "PlayerJLoTitle" then
			child:Destroy()
		end
	end

	local bb = Instance.new("BillboardGui")
	bb.Name = "PlayerJLoTitle"
	bb.Adornee = head
	bb.Size = UDim2.new(0, 300, 0, 70)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 50
	bb.Parent = jloModel

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("%s\n1 in %s", tostring(brainrotName), tostring(odds))
	label.TextColor3 = typeof(color) == "Color3" and color or Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.Arcade
	label.TextScaled = true
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = bb

	label.TextTransparency = 1
	TweenService:Create(label, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
		{TextTransparency = 0}):Play()

	return bb
end

ShowBrainrotOnJLoEvent.OnClientEvent:Connect(function(jloModel, brainrotName, odds, color)
	if currentJLoTitle then
		currentJLoTitle:Destroy()
		currentJLoTitle = nil
	end

	if jloModel and brainrotName then
		currentJLoTitle = create3DTitleAboveJLo(jloModel, brainrotName, odds, color)
		print("? JLo title updated for " .. player.Name .. ": " .. brainrotName)
	else
		print("? JLo title cleared for " .. player.Name)
	end
end)

print("?? Per-Player JLo Brainrot Title System Ready!")