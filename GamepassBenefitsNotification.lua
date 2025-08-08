-- Gamepass Benefits Notification System (Client)
-- Place in StarterGui as LocalScript

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for benefits notification remote
local GamepassBenefitsApplied = ReplicatedStorage:WaitForChild("GamepassBenefitsApplied", 10)

if not GamepassBenefitsApplied then
	warn("? GamepassBenefitsApplied remote not found")
	return
end

print("?? GAMEPASS BENEFITS NOTIFICATION CLIENT LOADED")

-- Create notification GUI
local function createBenefitsGUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "GamepassBenefitsGui"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	return gui
end

local benefitsGui = createBenefitsGUI()

-- Function to show benefits notification
local function showBenefitsNotification(gamepassId, gamepassName)
	print("?? Showing benefits notification for: " .. gamepassName)

	-- Create notification frame
	local notification = Instance.new("Frame")
	notification.Size = UDim2.new(0, 400, 0, 120)
	notification.Position = UDim2.new(0.5, -200, 0, -150) -- Start above screen
	notification.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	notification.BorderSizePixel = 0
	notification.Parent = benefitsGui

	-- Corner styling
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = notification

	-- Gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(75, 0, 130)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35))
	}
	gradient.Rotation = 45
	gradient.Parent = notification

	-- Stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 3
	stroke.Parent = notification

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 80, 0, 80)
	icon.Position = UDim2.new(0, 20, 0.5, -40)
	icon.BackgroundTransparency = 1
	icon.Text = ""
	icon.TextColor3 = Color3.fromRGB(255, 215, 0)
	icon.TextSize = 48
	icon.Font = Enum.Font.Arcade
	icon.Parent = notification

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 280, 0, 30)
	title.Position = UDim2.new(0, 110, 0, 15)
	title.BackgroundTransparency = 1
	title.Text = "?? GAMEPASS ACTIVATED!"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextSize = 20
	title.Font = Enum.Font.Arcade
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = notification

	-- Gamepass name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 280, 0, 25)
	nameLabel.Position = UDim2.new(0, 110, 0, 45)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = gamepassName
	nameLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.Arcade
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = notification

	-- Benefits text
	local benefitsText = Instance.new("TextLabel")
	benefitsText.Size = UDim2.new(0, 280, 0, 25)
	benefitsText.Position = UDim2.new(0, 110, 0, 75)
	benefitsText.BackgroundTransparency = 1
	benefitsText.Text = "All benefits have been applied to your account!"
	benefitsText.TextColor3 = Color3.fromRGB(200, 200, 255)
	benefitsText.TextSize = 12
	benefitsText.Font = Enum.Font.Arcade
	benefitsText.TextXAlignment = Enum.TextXAlignment.Left
	benefitsText.Parent = notification

	-- Play sound effect
	spawn(function()
		local success = pcall(function()
			local sound = Instance.new("Sound")
			sound.SoundId = "95723115467488"
			sound.Volume = 0.3
			sound.Parent = notification
			sound:Play()

			sound.Ended:Connect(function()
				sound:Destroy()
			end)
		end)
	end)

	-- Slide down animation
	local slideDown = TweenService:Create(notification, 
		TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -200, 0, 50)}
	)
	slideDown:Play()

	-- Visual effects
	spawn(function()
		while notification.Parent do
			-- Pulse stroke
			TweenService:Create(stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				Transparency = 0.2
			}):Play()

			-- Pulse icon
			TweenService:Create(icon, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				TextSize = 52,
				Rotation = 10
			}):Play()

			-- Rotate gradient
			TweenService:Create(gradient, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), {
				Rotation = gradient.Rotation + 360
			}):Play()

			wait(1.5)
		end
	end)

	-- Auto-hide after 6 seconds
	spawn(function()
		wait(6)

		if notification.Parent then
			local slideUp = TweenService:Create(notification, 
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, -200, 0, -150)}
			)
			slideUp:Play()

			slideUp.Completed:Connect(function()
				notification:Destroy()
			end)
		end
	end)
end

-- Listen for gamepass benefits applied
GamepassBenefitsApplied.OnClientEvent:Connect(function(gamepassId, gamepassName)
	showBenefitsNotification(gamepassId, gamepassName)
end)

print("? Gamepass benefits notification system ready!")