-- Modify StarterPlayer>StarterCharacterScripts>JLoTileBillboardClient

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ShowBrainrotOnJLoEvent = ReplicatedStorage:WaitForChild("ShowBrainrotOnJLoEvent")

local function clearExistingTitles(head)
	if not head then return end
	for _, child in pairs(head:GetChildren()) do
		if child:IsA("BillboardGui") then
			child:Destroy()
		end
	end
end

local function createBillboard(head, brainrotName, brainrotOdds, brainrotColor)
	-- Clear existing titles first
	clearExistingTitles(head)

	local bb = Instance.new("BillboardGui")
	bb.Name = "BrainrotTitleBillboard"
	bb.Adornee = head
	bb.Size = UDim2.new(0, 300, 0, 70)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 30
	bb.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("1 in %s\n%s", tostring(brainrotOdds), tostring(brainrotName))
	if typeof(brainrotColor) == "Color3" then
		label.TextColor3 = brainrotColor
	else
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	label.Font = Enum.Font.Arcade
	label.TextScaled = true
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = bb

	label.TextTransparency = 1
	local fadeIn = TweenService:Create(label, 
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)
	fadeIn:Play()

	return bb
end

local function updateJLoTitle(jloModel, brainrotName, brainrotOdds, brainrotColor)
	if not jloModel then return end

	local head = jloModel:FindFirstChild("Head") or jloModel:FindFirstChildWhichIsA("BasePart")
	if not head then return end

	clearExistingTitles(head)

	if brainrotName and brainrotOdds then
		createBillboard(head, brainrotName, brainrotOdds, brainrotColor)
	end
end

ShowBrainrotOnJLoEvent.OnClientEvent:Connect(updateJLoTitle)
print("? JLo Billboard Client Ready!")