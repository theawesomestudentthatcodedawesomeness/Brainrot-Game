local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerTitleDisplayEvent = ReplicatedStorage:WaitForChild("PlayerTitleDisplayEvent")

local function getHead(character)
	return character:FindFirstChild("Head") or character:FindFirstChildWhichIsA("BasePart")
end

local function removeOldBillboard(head)
	if not head then return end
	-- Remove ALL old billboards named "BrainrotTitleBillboard"
	for _, gui in ipairs(head:GetChildren()) do
		if gui:IsA("BillboardGui") and gui.Name == "BrainrotTitleBillboard" then
			gui:Destroy()
		end
	end
end

local function createPlayerBrainrotBillboard(head, brainrotName, brainrotOdds, brainrotColor, playerName)
	removeOldBillboard(head)

	if not brainrotName or not brainrotOdds then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "BrainrotTitleBillboard"
	bb.Adornee = head
	bb.Size = UDim2.new(0, 300, 0, 90)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 30
	bb.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,0,0.7,0)
	label.Position = UDim2.new(0,0,0,0)
	label.BackgroundTransparency = 1
	label.Text = string.format("1 in %s\n%s", tostring(brainrotOdds), brainrotName)
	label.TextColor3 = brainrotColor or Color3.fromRGB(255,140,70)
	label.Font = Enum.Font.Arcade
	label.TextScaled = true
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	label.Parent = bb

	local choiceLabel = Instance.new("TextLabel")
	choiceLabel.Size = UDim2.new(1,0,0.3,0)
	choiceLabel.Position = UDim2.new(0,0,0.7,0)
	choiceLabel.BackgroundTransparency = 1
	choiceLabel.Text = string.format("(%s's choice)", playerName)
	choiceLabel.TextColor3 = Color3.fromRGB(200,200,200)
	choiceLabel.Font = Enum.Font.Arcade
	choiceLabel.TextScaled = true
	choiceLabel.TextStrokeTransparency = 0.7
	choiceLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	choiceLabel.Parent = bb
end

PlayerTitleDisplayEvent.OnClientEvent:Connect(function(userId, brainrotName, brainrotOdds, brainrotColor)
	local targetPlayer = Players:GetPlayerByUserId(userId)
	if targetPlayer and targetPlayer.Character then
		local head = getHead(targetPlayer.Character)
		createPlayerBrainrotBillboard(head, brainrotName, brainrotOdds, brainrotColor, targetPlayer.Name)
	end
end)