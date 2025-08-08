-- LocalScript: StarterPlayer>StarterPlayerScripts>AutoAddNotificationClient
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the notification event with robust error handling
local AutoAddNotification
local maxWait = 45
local waited = 0
local checkInterval = 1

print("?? AutoAdd Client: Starting initialization...")

-- Function to wait for AutoAddNotification event
local function waitForAutoAddEvent()
	while not AutoAddNotification and waited < maxWait do
		AutoAddNotification = ReplicatedStorage:FindFirstChild("AutoAddNotification")
		if not AutoAddNotification then
			wait(checkInterval)
			waited = waited + checkInterval
			if waited % 5 == 0 then -- Print every 5 seconds
				print("?? AutoAdd Client: Waiting for AutoAddNotification event... (" .. waited .. "/" .. maxWait .. "s)")
			end
		end
	end

	if AutoAddNotification then
		print("?? AutoAdd Client: AutoAddNotification event found successfully!")
		return true
	else
		warn("?? AutoAdd Client: AutoAddNotification event not found after " .. maxWait .. " seconds!")
		warn("?? AutoAdd Client: Auto-add notifications will not work!")
		return false
	end
end

-- Initialize the event connection
local eventConnected = false
local notificationQueue = {}

-- Notification display function
local function showAutoAddNotification(brainrotName, gearName, success, isRetry)
	if not brainrotName or not gearName then
		warn("?? AutoAdd Client: Invalid notification parameters")
		return
	end

	local message = success and 
		("?? AUTO-ADD: " .. brainrotName .. " ? " .. gearName) or
		("?? AUTO-ADD FAILED: " .. brainrotName)

	local color = success and Color3.fromRGB(60, 120, 80) or Color3.fromRGB(180, 60, 60)

	print("?? AutoAdd Client: Showing notification - " .. message)

	-- Create notification frame
	local notif = Instance.new("Frame")
	notif.Name = "AutoAddNotification_" .. tick()
	notif.Size = UDim2.new(0, 380, 0, 75)
	notif.Position = UDim2.new(1, 20, 0.25, math.random(-50, 50))
	notif.BackgroundColor3 = color
	notif.BorderSizePixel = 0
	notif.ZIndex = 1000
	notif.Parent = playerGui

	-- Add gradient for visual appeal
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(0.8, 0.8, 0.8))
	})
	gradient.Rotation = 45
	gradient.Parent = notif

	-- Add corner brackets for style consistency
	local function addBracket(pos, size)
		local bracket = Instance.new("Frame")
		bracket.Size = size
		bracket.Position = pos
		bracket.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		bracket.BorderSizePixel = 0
		bracket.ZIndex = 1001
		bracket.Parent = notif
	end

	-- Corner brackets
	addBracket(UDim2.new(0, 0, 0, 0), UDim2.new(0, 18, 0, 3))
	addBracket(UDim2.new(0, 0, 0, 0), UDim2.new(0, 3, 0, 18))
	addBracket(UDim2.new(1, -18, 0, 0), UDim2.new(0, 18, 0, 3))
	addBracket(UDim2.new(1, -3, 0, 0), UDim2.new(0, 3, 0, 18))
	addBracket(UDim2.new(0, 0, 1, -3), UDim2.new(0, 18, 0, 3))
	addBracket(UDim2.new(0, 0, 1, -18), UDim2.new(0, 3, 0, 18))
	addBracket(UDim2.new(1, -18, 1, -3), UDim2.new(0, 18, 0, 3))
	addBracket(UDim2.new(1, -3, 1, -18), UDim2.new(0, 3, 0, 18))

	-- Add icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 50, 0, 50)
	icon.Position = UDim2.new(0, 12, 0.5, -25)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.Arcade
	icon.Text = success and "??" or "?"
	icon.TextColor3 = Color3.fromRGB(255, 255, 255)
	icon.TextSize = 32
	icon.TextStrokeTransparency = 0.3
	icon.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	icon.ZIndex = 1001
	icon.Parent = notif

	-- Add main text
	local notifText = Instance.new("TextLabel")
	notifText.Size = UDim2.new(1, -75, 1, -10)
	notifText.Position = UDim2.new(0, 65, 0, 5)
	notifText.BackgroundTransparency = 1
	notifText.Font = Enum.Font.Arcade
	notifText.Text = message
	notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
	notifText.TextSize = 16
	notifText.TextWrapped = true
	notifText.TextXAlignment = Enum.TextXAlignment.Left
	notifText.TextYAlignment = Enum.TextYAlignment.Center
	notifText.TextStrokeTransparency = 0.4
	notifText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	notifText.ZIndex = 1001
	notifText.Parent = notif

	-- Add timestamp
	local timeStamp = Instance.new("TextLabel")
	timeStamp.Size = UDim2.new(0, 60, 0, 15)
	timeStamp.Position = UDim2.new(1, -65, 1, -18)
	timeStamp.BackgroundTransparency = 1
	timeStamp.Font = Enum.Font.Arcade
	timeStamp.Text = os.date("%H:%M:%S")
	timeStamp.TextColor3 = Color3.fromRGB(200, 200, 200)
	timeStamp.TextSize = 10
	timeStamp.TextStrokeTransparency = 0.5
	timeStamp.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	timeStamp.ZIndex = 1001
	timeStamp.Parent = notif

	-- Animate in with bounce effect
	local slideInTween = TweenService:Create(notif, 
		TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(1, -400, 0.25, math.random(-50, 50))}
	)
	slideInTween:Play()

	-- Pulse effect for the icon
	local pulseIn = TweenService:Create(icon,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{TextSize = 36}
	)
	pulseIn:Play()

	-- Auto-hide after 4 seconds
	local hideDelay = success and 4 or 6

	task.delay(hideDelay, function()
		if notif and notif.Parent then
			pulseIn:Cancel()

			local slideOutTween = TweenService:Create(notif,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{
					Position = UDim2.new(1, 50, 0.25, notif.Position.Y.Offset),
					BackgroundTransparency = 1
				}
			)

			for _, child in pairs(notif:GetDescendants()) do
				if child:IsA("GuiObject") then
					local fadeOut = TweenService:Create(child,
						TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{
							BackgroundTransparency = 1,
							TextTransparency = 1
						}
					)
					fadeOut:Play()
				end
			end

			slideOutTween:Play()

			slideOutTween.Completed:Connect(function()
				if notif and notif.Parent then
					notif:Destroy()
				end
			end)
		end
	end)

	-- Manual close on click
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 20, 0, 20)
	closeButton.Position = UDim2.new(1, -25, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.Arcade
	closeButton.Text = "×"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 14
	closeButton.TextStrokeTransparency = 0.3
	closeButton.ZIndex = 1002
	closeButton.Parent = notif

	closeButton.MouseButton1Click:Connect(function()
		if notif and notif.Parent then
			notif:Destroy()
		end
	end)
end

-- Process queued notifications
local function processNotificationQueue()
	for _, notification in ipairs(notificationQueue) do
		showAutoAddNotification(notification.brainrotName, notification.gearName, notification.success, true)
	end
	notificationQueue = {}
end

-- Connect to the event once it's found
local function connectToEvent()
	if not AutoAddNotification then return false end

	AutoAddNotification.OnClientEvent:Connect(function(brainrotName, gearName, success)
		showAutoAddNotification(brainrotName, gearName, success, false)
		print("?? AutoAdd Client: Notification received - " .. tostring(brainrotName) .. " ? " .. tostring(gearName) .. " (Success: " .. tostring(success) .. ")")
	end)

	eventConnected = true
	print("?? AutoAdd Client: Event connection established successfully!")

	if #notificationQueue > 0 then
		print("?? AutoAdd Client: Processing " .. #notificationQueue .. " queued notifications")
		processNotificationQueue()
	end

	return true
end

-- Initialize everything
spawn(function()
	local success = waitForAutoAddEvent()

	if success then
		connectToEvent()
	else
		spawn(function()
			while not eventConnected do
				wait(10)
				print("?? AutoAdd Client: Retrying connection...")
				AutoAddNotification = ReplicatedStorage:FindFirstChild("AutoAddNotification")
				if AutoAddNotification then
					connectToEvent()
					break
				end
			end
		end)
	end
end)

-- Global function for testing
_G.TestAutoAddNotification = function(brainrotName, gearName, success)
	showAutoAddNotification(brainrotName or "Test Brainrot", gearName or "Test Gear", success ~= false, false)
end

-- Debug command for testing
player.Chatted:Connect(function(message)
	if message == "/testautoadd" then
		showAutoAddNotification("Sigma", "Diamond Gear", true, false)
	elseif message == "/testautoaddfail" then
		showAutoAddNotification("Ohio", "Bronze Gear", false, false)
	end
end)

print("?? Auto-Add Notification Client initialized!")
print("?? Debug commands: /testautoadd, /testautoaddfail")
print("?? Ready to display auto-add notifications")