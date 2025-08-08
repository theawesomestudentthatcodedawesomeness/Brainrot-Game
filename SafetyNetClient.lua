-- StarterPlayerScripts - SafetyNetClient.lua
-- Handles the black screen effect when player goes out of bounds
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remote events
local SafetyNetRemotes = ReplicatedStorage:WaitForChild("SafetyNetRemotes")
local ShowBlackScreenEvent = SafetyNetRemotes:WaitForChild("ShowBlackScreen")

-- Create black screen GUI
local function createBlackScreenGui()
	local existingGui = playerGui:FindFirstChild("SafetyNetGui")
	if existingGui then
		existingGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SafetyNetGui"
	screenGui.DisplayOrder = 10
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local blackFrame = Instance.new("Frame")
	blackFrame.Name = "BlackScreen"
	blackFrame.Size = UDim2.new(1, 0, 1, 0)
	blackFrame.Position = UDim2.new(0, 0, 0, 0)
	blackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	blackFrame.BackgroundTransparency = 1
	blackFrame.BorderSizePixel = 0
	blackFrame.Visible = false
	blackFrame.Parent = screenGui

	-- Warning message
	local warningLabel = Instance.new("TextLabel")
	warningLabel.Name = "WarningText"
	warningLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
	warningLabel.Position = UDim2.new(0.1, 0, 0.4, 0)
	warningLabel.BackgroundTransparency = 1
	warningLabel.Font = Enum.Font.Arcade
	warningLabel.Text = "?? OUT OF BOUNDS ??\nReturning to spawn..."
	warningLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	warningLabel.TextStrokeTransparency = 0.3
	warningLabel.TextStrokeColor3 = Color3.fromRGB(255, 0, 0)
	warningLabel.TextScaled = true
	warningLabel.TextWrapped = true
	warningLabel.TextTransparency = 1
	warningLabel.Parent = blackFrame

	return screenGui
end

-- Show/hide black screen with animation
local function toggleBlackScreen(show)
	local gui = playerGui:FindFirstChild("SafetyNetGui")
	if not gui then
		gui = createBlackScreenGui()
	end

	local blackFrame = gui:FindFirstChild("BlackScreen")
	local warningText = blackFrame:FindFirstChild("WarningText")

	if show then
		-- Show black screen
		blackFrame.Visible = true

		-- Play warning sound
		local warningSound = Instance.new("Sound")
		warningSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		warningSound.Volume = 0.5
		warningSound.Parent = SoundService
		warningSound:Play()
		warningSound.Ended:Connect(function() warningSound:Destroy() end)

		-- Fade in black screen
		local fadeInTween = TweenService:Create(blackFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 0}
		)
		fadeInTween:Play()

		-- Fade in warning text
		local textFadeTween = TweenService:Create(warningText,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{TextTransparency = 0}
		)
		textFadeTween:Play()

	else
		-- Hide black screen
		local fadeOutTween = TweenService:Create(blackFrame,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		)

		local textFadeOutTween = TweenService:Create(warningText,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{TextTransparency = 1}
		)

		fadeOutTween:Play()
		textFadeOutTween:Play()

		fadeOutTween.Completed:Connect(function()
			blackFrame.Visible = false
		end)
	end
end

-- Handle server events
ShowBlackScreenEvent.OnClientEvent:Connect(function(show)
	toggleBlackScreen(show)
end)

-- Initialize
createBlackScreenGui()

print("??? Safety Net Client Ready!")