-- LocalScript: Workspace>JLo>LocalScript

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local ShowBrainrotOnJLoEvent = ReplicatedStorage:WaitForChild("ShowBrainrotOnJLoEvent")

-- Track current player's JLo title
local currentPlayerTitle = nil

local function getJLoHead()
	local JLo = workspace:FindFirstChild("JLo")
	if not JLo then 
		return nil 
	end
	return JLo:FindFirstChild("Head") or JLo:FindFirstChildWhichIsA("BasePart")
end

local function getJLoModel()
	return workspace:FindFirstChild("JLo")
end

local function removeAllJLoTitles(head)
	if not head then 
		head = getJLoHead()
		if not head then return end
	end

	-- Remove titles from head
	for _, gui in ipairs(head:GetChildren()) do
		if gui:IsA("BillboardGui") and (
			gui.Name == "BrainrotTitleBillboard" or 
				gui.Name == "PlayerJLoTitle" or
				gui.Name:find("JLoTitle")
			) then
			gui:Destroy()
			print("??? Removed JLo title GUI from head")
		end
	end

	-- Also check the main JLo model for any stray billboards
	local jloModel = getJLoModel()
	if jloModel then
		for _, gui in ipairs(jloModel:GetChildren()) do
			if gui:IsA("BillboardGui") and (
				gui.Name == "BrainrotTitleBillboard" or 
					gui.Name == "PlayerJLoTitle" or
					gui.Name:find("JLoTitle")
				) then
				gui:Destroy()
				print("??? Removed JLo title GUI from model")
			end
		end
	end
end

local function showJLoTitle(jloModel, brainrotName, brainrotOdds, brainrotColor)
	print("?? showJLoTitle called for player:", player.Name)
	print("?? Parameters:", brainrotName, brainrotOdds, brainrotColor)

	local head = getJLoHead()
	if not head then
		print("? JLo head not found!")
		return
	end

	-- Clear any existing titles for this player
	removeAllJLoTitles(head)

	if not brainrotName or not brainrotOdds then
		print("? Cleared JLo title for " .. player.Name .. " (nil values)")
		currentPlayerTitle = nil
		return
	end

	-- Store current player's title data
	currentPlayerTitle = {
		name = brainrotName,
		odds = brainrotOdds,
		color = brainrotColor,
		timestamp = tick()
	}

	-- Create unique billboard for this player
	local bb = Instance.new("BillboardGui")
	bb.Name = "PlayerJLoTitle_" .. player.UserId .. "_" .. tick()
	bb.Adornee = head
	bb.Size = UDim2.new(0, 300, 0, 80)
	bb.StudsOffset = Vector3.new(0, 3.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 50
	bb.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("1 in %s\n%s", tostring(brainrotOdds), brainrotName)
	label.TextColor3 = brainrotColor or Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.Arcade
	label.TextScaled = true
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = bb

	-- Fade in animation
	label.TextTransparency = 1
	local fadeIn = TweenService:Create(label, 
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
		{TextTransparency = 0}
	)
	fadeIn:Play()

	print("? Showed JLo preview for " .. player.Name .. ":", brainrotName)
	print("?? Billboard created with name:", bb.Name)
end

-- Connect to the event
ShowBrainrotOnJLoEvent.OnClientEvent:Connect(showJLoTitle)

-- Clear any existing titles on script start
removeAllJLoTitles()

-- Monitor for JLo model changes
workspace.ChildAdded:Connect(function(child)
	if child.Name == "JLo" then
		wait(1) -- Wait for JLo to fully load
		removeAllJLoTitles()

		-- Restore current player's title if they had one
		if currentPlayerTitle then
			showJLoTitle(
				child,
				currentPlayerTitle.name,
				currentPlayerTitle.odds,
				currentPlayerTitle.color
			)
		end
	end
end)

-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == player then
		removeAllJLoTitles()
		currentPlayerTitle = nil
	end
end)

-- Debug functions
_G.ClearJLoTitles = function()
	removeAllJLoTitles()
	currentPlayerTitle = nil
	print("?? Manually cleared all JLo titles for " .. player.Name)
end

_G.ShowJLoTitle = function(name, odds, color)
	local jloModel = getJLoModel()
	if jloModel then
		showJLoTitle(jloModel, name, odds, color or Color3.fromRGB(255, 255, 255))
	else
		print("? JLo model not found for manual title show")
	end
end

_G.GetCurrentJLoTitle = function()
	return currentPlayerTitle
end

print("?? Per-Player JLo Title Handler Ready!")
print("?? Player:", player.Name, "| UserId:", player.UserId)
print("?? Debug commands: _G.ClearJLoTitles(), _G.ShowJLoTitle(name, odds, color)")