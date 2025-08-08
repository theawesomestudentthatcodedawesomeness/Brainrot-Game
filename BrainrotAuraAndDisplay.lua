-- Place this LocalScript in StarterCharacterScripts or StarterPlayerScripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local BrainrotDefinitions = require(ReplicatedStorage:WaitForChild("BrainrotDefinitions"))
local inventoryRemotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local equipEvent = inventoryRemotes:WaitForChild("EquipBrainrot")
local getEquipped = inventoryRemotes:WaitForChild("GetEquippedBrainrot")
local EquipBrainrotRemote = ReplicatedStorage:FindFirstChild("EquipBrainrotRemote")

local unwantedNames = { ["BrainrotBillboard"] = true }

local function clearVisuals(char)
	char = char or player.Character
	if not char then return end
	for _, descendant in ipairs(char:GetDescendants()) do
		if unwantedNames[descendant.Name] then
			descendant:Destroy()
		end
	end
end

local function displayBillboard(def, char)
	local head = char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
	if not head then return end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BrainrotBillboard"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 300, 0, 70)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = char

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1,0,1,0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = string.format("1 in %s\n%s", tostring(def.odds), def.name)
	textLabel.Font = Enum.Font.Arcade
	textLabel.TextScaled = true
	textLabel.TextColor3 = def.titleColor or def.color or Color3.fromRGB(255,255,255)
	textLabel.TextStrokeTransparency = 0.3
	textLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	textLabel.Parent = billboard
end

local function waitForHead(character, timeout)
	timeout = timeout or 5
	local head
	local start = tick()
	repeat
		head = character:FindFirstChild("Head") or character:FindFirstChildWhichIsA("BasePart")
		if not head then wait(0.1) end
	until head or tick() - start > timeout
	return head
end

local function applyBrainrotDisplay(char, brainrotName)
	clearVisuals(char)
	local def = BrainrotDefinitions.Lookup[brainrotName]
	if not def then return end
	waitForHead(char)
	displayBillboard(def, char)
end

-- Listen for broadcasts of other players' equipped brainrot and show on their characters
if EquipBrainrotRemote then
	EquipBrainrotRemote.OnClientEvent:Connect(function(targetUserId, brainrotName)
		local playerObj = Players:GetPlayerByUserId(targetUserId)
		if playerObj and playerObj.Character then
			applyBrainrotDisplay(playerObj.Character, brainrotName)
		end
	end)
end

equipEvent.OnClientEvent:Connect(function(brainrotName)
	applyBrainrotDisplay(player.Character, brainrotName)
end)

local function applyLastEquippedBrainrot()
	local equipped
	pcall(function()
		equipped = getEquipped:InvokeServer()
	end)
	if equipped then
		local char = player.Character
		if char and waitForHead(char) then
			applyBrainrotDisplay(char, equipped)
		end
	end
end

player.CharacterAdded:Connect(function(char)
	wait(1)
	if waitForHead(char) then
		applyLastEquippedBrainrot()
	end
end)

if player.Character and waitForHead(player.Character) then
	applyLastEquippedBrainrot()
end