-- StarterGui > LocalScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local potionPickedUpEvent = ReplicatedStorage:WaitForChild("PotionPickedUpEvent", 10)
local potionLuckUpdateEvent = ReplicatedStorage:WaitForChild("PotionLuckUpdateEvent", 10)
local PotionSpawnNotification = ReplicatedStorage:WaitForChild("PotionSpawnNotification", 10)

-- Variables
local currentPotionLuck = 0
local potionEndTime = 0
local notificationGui = nil

print("?? POTION NOTIFICATION CLIENT LOADED")

-- Function to create corner brackets
local function addCornerBrackets(parent, color)
	local thickness = 2
	local length = 12

	local corners = {
		{UDim2.new(0, 0, 0, 0), UDim2.new(0, length, 0, thickness)}, -- TL horizontal
		{UDim2.new(0, 0, 0, 0), UDim2.new(0, thickness, 0, length)}, -- TL vertical
		{UDim2.new(1, -length, 0, 0), UDim2.new(0, length, 0, thickness)}, -- TR horizontal
		{UDim2.new(1, -thickness, 0, 0), UDim2.new(0, thickness, 0, length)}, -- TR vertical
		{UDim2.new(0, 0, 1, -thickness), UDim2.new(0, length, 0, thickness)}, -- BL horizontal
		{UDim2.new(0, 0, 1, -length), UDim2.new(0, thickness, 0, length)}, -- BL vertical
		{UDim2.new(1, -length, 1, -thickness), UDim2.new(0, length, 0, thickness)}, -- BR horizontal
		{UDim2.new(1, -thickness, 1, -length), UDim2.new(0, thickness, 0, length)} -- BR vertical
	}

	for _, corner in ipairs(corners) do
		local bracket = Instance.new("Frame")
		bracket.Size = corner[2]
		bracket.Position = corner[1]
		bracket.BackgroundColor3 = color
		bracket.BorderSizePixel = 0
		bracket.ZIndex = parent.ZIndex + 1
		bracket.Parent = parent
	end
end

-- NEW: Function to show potion spawn notification for Matteoooo's VIP
local function showPotionSpawnNotification(position)
	print("?? Showing VIP potion spawn notification at: " .. tostring(position))

	-- Create spawn notification frame
	local spawnNotification = Instance.new("Frame")
	spawnNotification.Size = UDim2.new(0, 300, 0, 80)
	spawnNotification.Position = UDim2.new(1, 0, 0, 50) -- Start off-screen
	spawnNotification.BackgroundColor3 = Color3.fromRGB(75, 0, 130) -- Purple background
	spawnNotification.BorderSizePixel = 0
	spawnNotification.Parent = playerGui

	-- Corner styling
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = spawnNotification

	-- Stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0) -- Gold stroke
	stroke.Thickness = 2
	stroke.Parent = spawnNotification

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 60, 0, 60)
	icon.Position = UDim2.new(0, 10, 0.5, -30)
	icon.BackgroundTransparency = 1
	icon.Text = "??"
	icon.TextColor3 = Color3.fromRGB(255, 215, 0)
	icon.TextSize = 36
	icon.Font = Enum.Font.Arcade
	icon.Parent = spawnNotification

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 220, 0, 25)
	title.Position = UDim2.new(0, 75, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "?? LUCK POTION SPAWNED!"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextSize = 16
	title.Font = Enum.Font.Arcade
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = spawnNotification

	-- Description
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(0, 220, 0, 20)
	desc.Position = UDim2.new(0, 75, 0, 35)
	desc.BackgroundTransparency = 1
	desc.Text = "A luck potion has appeared on the map!"
	desc.TextColor3 = Color3.fromRGB(200, 200, 255)
	desc.TextSize = 12
	desc.Font = Enum.Font.Arcade
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Parent = spawnNotification

	-- VIP badge
	local vipBadge = Instance.new("TextLabel")
	vipBadge.Size = UDim2.new(0, 220, 0, 15)
	vipBadge.Position = UDim2.new(0, 75, 0, 55)
	vipBadge.BackgroundTransparency = 1
	vipBadge.Text = "Matteoooo's VIP Exclusive"
	vipBadge.TextColor3 = Color3.fromRGB(255, 255, 100)
	vipBadge.TextSize = 10
	vipBadge.Font = Enum.Font.Arcade
	vipBadge.TextXAlignment = Enum.TextXAlignment.Left
	vipBadge.Parent = spawnNotification

	-- Play sound
	local success, error = pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.Volume = 0.5
		sound.Parent = spawnNotification
		sound:Play()

		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)

	-- Slide in animation
	local slideIn = TweenService:Create(spawnNotification, 
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(1, -320, 0, 50)}
	)
	slideIn:Play()

	-- Glow and pulse effects
	spawn(function()
		while spawnNotification.Parent do
			-- Pulse stroke
			TweenService:Create(stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				Transparency = 0.2
			}):Play()

			-- Pulse icon
			TweenService:Create(icon, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				TextSize = 40,
				Rotation = 10
			}):Play()

			wait(1.5)
		end
	end)

	-- Auto-hide after 5 seconds
	spawn(function()
		wait(5)

		if spawnNotification.Parent then
			local slideOut = TweenService:Create(spawnNotification, 
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(1, 0, 0, 50)}
			)
			slideOut:Play()

			slideOut.Completed:Connect(function()
				spawnNotification:Destroy()
			end)
		end
	end)
end

-- Function to create potion notification in bottom right
local function createPotionNotification(luckBoost, duration)
	-- Remove existing notification
	if notificationGui then
		notificationGui:Destroy()
	end

	-- Create notification GUI
	notificationGui = Instance.new("Frame")
	notificationGui.Name = "PotionNotification"
	notificationGui.Size = UDim2.new(0, 120, 0, 60)
	notificationGui.Position = UDim2.new(1, -140, 1, -80) -- Bottom right
	notificationGui.BackgroundColor3 = Color3.fromRGB(40, 25, 60)
	notificationGui.BackgroundTransparency = 0.2
	notificationGui.BorderSizePixel = 0
	notificationGui.Parent = playerGui

	addCornerBrackets(notificationGui, Color3.fromRGB(255, 215, 0))

	-- Potion icon
	local potionIcon = Instance.new("ImageLabel")
	potionIcon.Name = "PotionIcon"
	potionIcon.Size = UDim2.new(0, 30, 0, 30)
	potionIcon.Position = UDim2.new(0, 10, 0.5, -15)
	potionIcon.BackgroundTransparency = 1
	potionIcon.Image = "http://www.roblox.com/asset/?id=17368084270" -- Same as luck GUI
	potionIcon.ImageColor3 = Color3.fromRGB(255, 100, 255) -- Purple tint for potion
	potionIcon.ScaleType = Enum.ScaleType.Fit
	potionIcon.Parent = notificationGui

	-- Luck boost text
	local luckText = Instance.new("TextLabel")
	luckText.Name = "LuckText"
	luckText.Size = UDim2.new(0, 60, 0, 20)
	luckText.Position = UDim2.new(0, 45, 0, 5)
	luckText.BackgroundTransparency = 1
	luckText.Font = Enum.Font.Arcade
	luckText.Text = "+" .. luckBoost .. "% LUCK"
	luckText.TextColor3 = Color3.fromRGB(255, 215, 0)
	luckText.TextStrokeTransparency = 0.3
	luckText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	luckText.TextScaled = true
	luckText.Parent = notificationGui

	-- Timer text
	local timerText = Instance.new("TextLabel")
	timerText.Name = "TimerText"
	timerText.Size = UDim2.new(0, 60, 0, 20)
	timerText.Position = UDim2.new(0, 45, 0, 25)
	timerText.BackgroundTransparency = 1
	timerText.Font = Enum.Font.Arcade
	timerText.Text = duration .. "s"
	timerText.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerText.TextStrokeTransparency = 0.3
	timerText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	timerText.TextScaled = true
	timerText.Parent = notificationGui

	-- Glow effect
	local glowFrame = Instance.new("Frame")
	glowFrame.Name = "Glow"
	glowFrame.Size = UDim2.new(1, 8, 1, 8)
	glowFrame.Position = UDim2.new(0, -4, 0, -4)
	glowFrame.BackgroundColor3 = Color3.fromRGB(255, 100, 255)
	glowFrame.BackgroundTransparency = 0.7
	glowFrame.BorderSizePixel = 0
	glowFrame.ZIndex = notificationGui.ZIndex - 1
	glowFrame.Parent = notificationGui

	-- Slide in animation
	notificationGui.Position = UDim2.new(1, 20, 1, -80)
	local slideIn = TweenService:Create(notificationGui, 
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
		{Position = UDim2.new(1, -140, 1, -80)}
	)
	slideIn:Play()

	-- Pulsing glow animation
	spawn(function()
		while notificationGui.Parent do
			local pulse1 = TweenService:Create(glowFrame, TweenInfo.new(1, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.5})
			local pulse2 = TweenService:Create(glowFrame, TweenInfo.new(1, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.8})
			pulse1:Play()
			pulse1.Completed:Wait()
			pulse2:Play()
			pulse2.Completed:Wait()
		end
	end)

	-- Update timer
	spawn(function()
		while notificationGui.Parent and potionEndTime > tick() do
			local timeLeft = math.ceil(potionEndTime - tick())
			timerText.Text = timeLeft .. "s"

			-- Change color as time runs out
			if timeLeft <= 10 then
				timerText.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red
			elseif timeLeft <= 30 then
				timerText.TextColor3 = Color3.fromRGB(255, 200, 100) -- Orange
			end

			wait(1)
		end

		-- Slide out when expired
		if notificationGui.Parent then
			local slideOut = TweenService:Create(notificationGui, 
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
				{Position = UDim2.new(1, 20, 1, -80)}
			)
			slideOut:Play()
			slideOut.Completed:Connect(function()
				notificationGui:Destroy()
				notificationGui = nil
			end)
		end
	end)

	-- Hover tooltip
	local hoverButton = Instance.new("TextButton")
	hoverButton.Size = UDim2.new(1, 0, 1, 0)
	hoverButton.BackgroundTransparency = 1
	hoverButton.Text = ""
	hoverButton.Parent = notificationGui

	local tooltip = Instance.new("Frame")
	tooltip.Size = UDim2.new(0, 150, 0, 60)
	tooltip.Position = UDim2.new(0, -160, 0, 0)
	tooltip.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	tooltip.BackgroundTransparency = 0.1
	tooltip.BorderSizePixel = 0
	tooltip.Visible = false
	tooltip.Parent = notificationGui

	addCornerBrackets(tooltip, Color3.fromRGB(255, 100, 255))

	local tooltipTitle = Instance.new("TextLabel")
	tooltipTitle.Size = UDim2.new(1, -8, 0, 20)
	tooltipTitle.Position = UDim2.new(0, 4, 0, 5)
	tooltipTitle.BackgroundTransparency = 1
	tooltipTitle.Font = Enum.Font.Arcade
	tooltipTitle.Text = "LUCK POTION"
	tooltipTitle.TextColor3 = Color3.fromRGB(255, 100, 255)
	tooltipTitle.TextStrokeTransparency = 0.3
	tooltipTitle.TextScaled = true
	tooltipTitle.Parent = tooltip

	local tooltipBoost = Instance.new("TextLabel")
	tooltipBoost.Size = UDim2.new(1, -8, 0, 20)
	tooltipBoost.Position = UDim2.new(0, 4, 0, 25)
	tooltipBoost.BackgroundTransparency = 1
	tooltipBoost.Font = Enum.Font.Arcade
	tooltipBoost.Text = "+" .. luckBoost .. "% Luck Boost"
	tooltipBoost.TextColor3 = Color3.fromRGB(255, 215, 0)
	tooltipBoost.TextStrokeTransparency = 0.3
	tooltipBoost.TextScaled = true
	tooltipBoost.Parent = tooltip

	hoverButton.MouseEnter:Connect(function()
		tooltip.Visible = true
		tooltip.Size = UDim2.new(0, 0, 0, 0)
		local showTween = TweenService:Create(tooltip, 
			TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
			{Size = UDim2.new(0, 150, 0, 60)}
		)
		showTween:Play()
	end)

	hoverButton.MouseLeave:Connect(function()
		local hideTween = TweenService:Create(tooltip, 
			TweenInfo.new(0.15, Enum.EasingStyle.Quad), 
			{Size = UDim2.new(0, 0, 0, 0)}
		)
		hideTween:Play()
		hideTween.Completed:Connect(function()
			tooltip.Visible = false
		end)
	end)
end

-- Handle potion pickup
potionPickedUpEvent.OnClientEvent:Connect(function(luckBoost, duration)
	currentPotionLuck = luckBoost
	potionEndTime = tick() + duration

	print("?? Picked up luck potion! +" .. luckBoost .. "% luck for " .. duration .. "s")

	-- Create notification
	createPotionNotification(luckBoost, duration)
end)

-- Handle potion luck updates
potionLuckUpdateEvent.OnClientEvent:Connect(function(luckBoost)
	currentPotionLuck = luckBoost

	-- Update main luck GUI
	if _G.updatePotionLuckBoost then
		_G.updatePotionLuckBoost(luckBoost)
	end

	if luckBoost == 0 then
		print("?? Luck potion effect expired")
		potionEndTime = 0
	end
end)

-- NEW: Handle potion spawn notifications for Matteoooo's VIP
if PotionSpawnNotification then
	PotionSpawnNotification.OnClientEvent:Connect(function(position)
		print("?? VIP Notification: Potion spawned at " .. tostring(position))
		showPotionSpawnNotification(position)
	end)
else
	warn("?? PotionSpawnNotification remote not found - VIP notifications disabled")
end

-- Global function to get current potion luck
_G.getCurrentPotionLuck = function()
	if potionEndTime > tick() then
		return currentPotionLuck
	end
	return 0
end

print("?? ? Potion Notification Client loaded with VIP spawn notifications!")