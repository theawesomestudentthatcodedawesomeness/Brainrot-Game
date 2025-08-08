-- Place as a LocalScript in StarterPlayerScripts or StarterGui

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Wait for sound to be available
local clickSoundTemplate = ReplicatedStorage:WaitForChild("GuiClickSound")

-- Utility: plays the click sound
local function playClickSound()
	local guiSound = clickSoundTemplate:Clone()
	guiSound.Parent = workspace
	guiSound:Play()
	game.Debris:AddItem(guiSound, guiSound.TimeLength + 0.1)
end

-- Recursively connect to all buttons
local function connectButtons(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("ImageButton") then
			if not child:FindFirstChild("ClickSoundConnection") then
				child.MouseButton1Click:Connect(playClickSound)
				-- Optional: add a marker to avoid double-connecting
				local tag = Instance.new("BoolValue")
				tag.Name = "ClickSoundConnection"
				tag.Parent = child
			end
		end
		connectButtons(child)
	end
end

-- Initial connect (for all current GUI)
for _, gui in ipairs(player.PlayerGui:GetChildren()) do
	connectButtons(gui)
end

-- Listen for new GUIs added at runtime
player.PlayerGui.ChildAdded:Connect(function(newGui)
	connectButtons(newGui)
end)

-- Listen for new descendants (buttons created dynamically)
player.PlayerGui.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
		if not descendant:FindFirstChild("ClickSoundConnection") then
			descendant.MouseButton1Click:Connect(playClickSound)
			local tag = Instance.new("BoolValue")
			tag.Name = "ClickSoundConnection"
			tag.Parent = descendant
		end
	end
end)