-- StarterGui > LocalScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local potionPickedUpEvent = ReplicatedStorage:WaitForChild("PotionPickedUpEvent")
local potionLuckUpdateEvent = ReplicatedStorage:WaitForChild("PotionLuckUpdateEvent")
local potionHoldEvent = ReplicatedStorage:WaitForChild("PotionHoldEvent")

-- Variables
local currentPotionLuck = 0
local potionEndTime = 0
local notificationGui = nil
local potionTimerGui = nil
local nearbyPotion = nil
local holdPrompt = nil
local isHolding = false
local holdStartTime = 0
local holdProgress = 0
local HOLD_TIME = 2
local DETECTION_RANGE = 10 -- Slightly reduced since no detection part
local holdSound = nil -- NEW: Sound variable

-- NEW: Create hold sound
local function createHoldSound()
	if holdSound then
		holdSound:Destroy()
	end

	holdSound = Instance.new("Sound")
	holdSound.Name = "PotionHoldSound"
	holdSound.SoundId = "rbxassetid://140057358567917" -- The sound ID you requested
	holdSound.Volume = 0.5
	holdSound.Looped = true
	holdSound.Parent = SoundService

	print("?? Created hold sound with ID: 140057358567917")
end

-- NEW: Play hold sound
local function playHoldSound()
	if holdSound and not holdSound.IsPlaying then
		holdSound:Play()
		print("?? Playing hold sound")
	end
end

-- NEW: Stop hold sound
local function stopHoldSound()
	if holdSound and holdSound.IsPlaying then
		holdSound:Stop()
		print("?? Stopped hold sound")
	end
end

-- Function to create corner brackets
local function addCornerBrackets(parent, color)
	local thickness = 2
	local length = 12

	local corners = {
		{UDim2.new(0, 0, 0, 0), UDim2.new(0, length, 0, thickness)},
		{UDim2.new(0, 0, 0, 0), UDim2.new(0, thickness, 0, length)},
		{UDim2.new(1, -length, 0, 0), UDim2.new(0, length, 0, thickness)},
		{UDim2.new(1, -thickness, 0, 0), UDim2.new(0, thickness, 0, length)},
		{UDim2.new(0, 0, 1, -thickness), UDim2.new(0, length, 0, thickness)},
		{UDim2.new(0, 0, 1, -length), UDim2.new(0, thickness, 0, length)},
		{UDim2.new(1, -length, 1, -thickness), UDim2.new(0, length, 0, thickness)},
		{UDim2.new(1, -thickness, 1, -length), UDim2.new(0, thickness, 0, length)}
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

-- Function to create hold prompt
local function createHoldPrompt()
	if holdPrompt then 
		holdPrompt:Destroy()
	end

	holdPrompt = Instance.new("ScreenGui")
	holdPrompt.Name = "PotionHoldPrompt"
	holdPrompt.ResetOnSpawn = false
	holdPrompt.Parent = playerGui

	local promptFrame = Instance.new("Frame")
	promptFrame.Size = UDim2.new(0, 240, 0, 100) -- Slightly larger for "RARE" text
	promptFrame.Position = UDim2.new(0.5, -120, 0.75, -50)
	promptFrame.BackgroundColor3 = Color3.fromRGB(40, 25, 60)
	promptFrame.BackgroundTransparency = 0.1
	promptFrame.BorderSizePixel = 0
	promptFrame.Parent = holdPrompt

	addCornerBrackets(promptFrame, Color3.fromRGB(100, 255, 100))

	-- E key icon
	local eKeyIcon = Instance.new("TextLabel")
	eKeyIcon.Size = UDim2.new(0, 35, 0, 35)
	eKeyIcon.Position = UDim2.new(0, 10, 0.5, -17.5)
	eKeyIcon.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	eKeyIcon.BackgroundTransparency = 0.2
	eKeyIcon.BorderSizePixel = 0
	eKeyIcon.Font = Enum.Font.Arcade
	eKeyIcon.Text = "E"
	eKeyIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	eKeyIcon.TextSize = 20
	eKeyIcon.TextScaled = true
	eKeyIcon.Parent = promptFrame

	addCornerBrackets(eKeyIcon, Color3.fromRGB(255, 255, 255))

	-- Hold text
	local holdText = Instance.new("TextLabel")
	holdText.Size = UDim2.new(0, 170, 0, 25)
	holdText.Position = UDim2.new(0, 55, 0, 5)
	holdText.BackgroundTransparency = 1
	holdText.Font = Enum.Font.Arcade
	holdText.Text = "Hold to collect"
	holdText.TextColor3 = Color3.fromRGB(100, 255, 100)
	holdText.TextStrokeTransparency = 0.3
	holdText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	holdText.TextSize = 16
	holdText.TextScaled = true
	holdText.Parent = promptFrame

	-- RARE text
	local rareText = Instance.new("TextLabel")
	rareText.Size = UDim2.new(0, 170, 0, 20)
	rareText.Position = UDim2.new(0, 55, 0, 25)
	rareText.BackgroundTransparency = 1
	rareText.Font = Enum.Font.Arcade
	rareText.Text = ""
	rareText.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
	rareText.TextStrokeTransparency = 0.3
	rareText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rareText.TextSize = 14
	rareText.TextScaled = true
	rareText.Parent = promptFrame

	-- Luck boost text
	local luckText = Instance.new("TextLabel")
	luckText.Size = UDim2.new(0, 170, 0, 18)
	luckText.Position = UDim2.new(0, 55, 0, 45)
	luckText.BackgroundTransparency = 1
	luckText.Font = Enum.Font.Arcade
	luckText.Text = "+35% LUCK FOR 60s"
	luckText.TextColor3 = Color3.fromRGB(100, 255, 100)
	luckText.TextStrokeTransparency = 0.3
	luckText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	luckText.TextSize = 12
	luckText.TextScaled = true
	luckText.Parent = promptFrame

	-- Progress bar background
	local progressBG = Instance.new("Frame")
	progressBG.Name = "ProgressBG"
	progressBG.Size = UDim2.new(0, 170, 0, 12)
	progressBG.Position = UDim2.new(0, 55, 0, 70)
	progressBG.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	progressBG.BorderSizePixel = 0
	progressBG.Parent = promptFrame

	-- Progress bar fill
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.Position = UDim2.new(0, 0, 0, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBG

	-- Enhanced glow effect for rare potion
	local glowFrame = Instance.new("Frame")
	glowFrame.Name = "Glow"
	glowFrame.Size = UDim2.new(1, 15, 1, 15)
	glowFrame.Position = UDim2.new(0, -7.5, 0, -7.5)
	glowFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold glow
	glowFrame.BackgroundTransparency = 0.7
	glowFrame.BorderSizePixel = 0
	glowFrame.ZIndex = promptFrame.ZIndex - 1
	glowFrame.Parent = promptFrame

	-- Enhanced pulsing animation for rare potion
	spawn(function()
		while holdPrompt and holdPrompt.Parent do
			local pulse1 = TweenService:Create(glowFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.5, BackgroundColor3 = Color3.fromRGB(255, 215, 0)})
			local pulse2 = TweenService:Create(glowFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.8, BackgroundColor3 = Color3.fromRGB(100, 255, 100)})
			pulse1:Play()
			pulse1.Completed:Wait()
			if glowFrame and glowFrame.Parent then
				pulse2:Play()
				pulse2.Completed:Wait()
			else
				break
			end
		end
	end)

	print("?? RARE potion hold prompt created!")
end

-- Function to remove hold prompt
local function removeHoldPrompt()
	if holdPrompt then
		holdPrompt:Destroy()
		holdPrompt = nil
		print("?? Hold prompt removed!")
	end
end

-- Function to update progress bar
local function updateProgressBar()
	if holdPrompt then
		local promptFrame = holdPrompt:FindFirstChild("Frame")
		if promptFrame then
			local progressBG = promptFrame:FindFirstChild("ProgressBG")
			if progressBG then
				local progressFill = progressBG:FindFirstChild("ProgressFill")
				if progressFill then
					local targetSize = UDim2.new(holdProgress, 0, 1, 0)
					TweenService:Create(progressFill, TweenInfo.new(0.1), {Size = targetSize}):Play()
				end
			end
		end
	end
end

-- Function to create smaller, subtle potion timer GUI
local function createPotionTimerGui()
	if potionTimerGui then
		potionTimerGui:Destroy()
	end

	potionTimerGui = Instance.new("ScreenGui")
	potionTimerGui.Name = "PotionTimerGui"
	potionTimerGui.ResetOnSpawn = false
	potionTimerGui.Parent = playerGui

	-- Main container
	local timerContainer = Instance.new("Frame")
	timerContainer.Name = "TimerContainer"
	timerContainer.Size = UDim2.new(0, 50, 0, 50)
	timerContainer.Position = UDim2.new(1, -65, 1, -65)
	timerContainer.BackgroundColor3 = Color3.fromRGB(40, 25, 60)
	timerContainer.BackgroundTransparency = 0.4
	timerContainer.BorderSizePixel = 0
	timerContainer.Parent = potionTimerGui

	-- Smaller corner brackets
	local function addSmallCornerBrackets(parent, color)
		local thickness = 1
		local length = 6

		local corners = {
			{UDim2.new(0, 0, 0, 0), UDim2.new(0, length, 0, thickness)},
			{UDim2.new(0, 0, 0, 0), UDim2.new(0, thickness, 0, length)},
			{UDim2.new(1, -length, 0, 0), UDim2.new(0, length, 0, thickness)},
			{UDim2.new(1, -thickness, 0, 0), UDim2.new(0, thickness, 0, length)},
			{UDim2.new(0, 0, 1, -thickness), UDim2.new(0, length, 0, thickness)},
			{UDim2.new(0, 0, 1, -length), UDim2.new(0, thickness, 0, length)},
			{UDim2.new(1, -length, 1, -thickness), UDim2.new(0, length, 0, thickness)},
			{UDim2.new(1, -thickness, 1, -length), UDim2.new(0, thickness, 0, length)}
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

	addSmallCornerBrackets(timerContainer, Color3.fromRGB(100, 255, 100))

	-- Luck symbol
	local luckSymbol = Instance.new("ImageLabel")
	luckSymbol.Name = "LuckSymbol"
	luckSymbol.Size = UDim2.new(0, 25, 0, 25)
	luckSymbol.Position = UDim2.new(0.5, -12.5, 0, 3)
	luckSymbol.BackgroundTransparency = 1
	luckSymbol.Image = "http://www.roblox.com/asset/?id=17368084270"
	luckSymbol.ImageColor3 = Color3.fromRGB(100, 255, 100)
	luckSymbol.ImageTransparency = 0.1
	luckSymbol.ScaleType = Enum.ScaleType.Fit
	luckSymbol.Parent = timerContainer

	-- Timer text
	local timerText = Instance.new("TextLabel")
	timerText.Name = "TimerText"
	timerText.Size = UDim2.new(1, -4, 0, 18)
	timerText.Position = UDim2.new(0, 2, 0, 30)
	timerText.BackgroundTransparency = 1
	timerText.Font = Enum.Font.Arcade
	timerText.Text = "60s"
	timerText.TextColor3 = Color3.fromRGB(100, 255, 100)
	timerText.TextStrokeTransparency = 0.5
	timerText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	timerText.TextSize = 10
	timerText.TextScaled = true
	timerText.TextXAlignment = Enum.TextXAlignment.Center
	timerText.Parent = timerContainer

	-- Subtle glow effect
	local glowFrame = Instance.new("Frame")
	glowFrame.Name = "Glow"
	glowFrame.Size = UDim2.new(1, 4, 1, 4)
	glowFrame.Position = UDim2.new(0, -2, 0, -2)
	glowFrame.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	glowFrame.BackgroundTransparency = 0.9
	glowFrame.BorderSizePixel = 0
	glowFrame.ZIndex = timerContainer.ZIndex - 1
	glowFrame.Parent = timerContainer

	-- Slide in animation
	timerContainer.Position = UDim2.new(1, 10, 1, -65)
	local slideIn = TweenService:Create(timerContainer, 
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
		{Position = UDim2.new(1, -65, 1, -65)}
	)
	slideIn:Play()

	-- Gentle pulsing animation
	spawn(function()
		while potionTimerGui and potionTimerGui.Parent do
			local pulse1 = TweenService:Create(glowFrame, TweenInfo.new(2, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.85})
			local pulse2 = TweenService:Create(glowFrame, TweenInfo.new(2, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.95})
			pulse1:Play()
			pulse1.Completed:Wait()
			if glowFrame and glowFrame.Parent then
				pulse2:Play()
				pulse2.Completed:Wait()
			else
				break
			end
		end
	end)

	print("?? Subtle potion timer GUI created!")
end

-- Function to update potion timer
local function updatePotionTimer()
	if potionTimerGui and potionEndTime > 0 then
		local timerContainer = potionTimerGui:FindFirstChild("TimerContainer")
		if timerContainer then
			local timerText = timerContainer:FindFirstChild("TimerText")
			if timerText then
				local timeLeft = math.max(0, math.ceil(potionEndTime - tick()))
				timerText.Text = timeLeft .. "s"

				-- Color changes
				if timeLeft <= 10 then
					timerText.TextColor3 = Color3.fromRGB(255, 150, 150)
				elseif timeLeft <= 30 then
					timerText.TextColor3 = Color3.fromRGB(255, 220, 150)
				else
					timerText.TextColor3 = Color3.fromRGB(100, 255, 100)
				end

				-- Remove when expired
				if timeLeft <= 0 then
					local slideOut = TweenService:Create(timerContainer, 
						TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
						{Position = UDim2.new(1, 10, 1, -65)}
					)
					slideOut:Play()
					slideOut.Completed:Connect(function()
						if potionTimerGui then
							potionTimerGui:Destroy()
							potionTimerGui = nil
						end
					end)
				end
			end
		end
	end
end

-- UPDATED: Function to check for nearby potions (without detection part)
local function checkForNearbyPotions()
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local playerPosition = player.Character.HumanoidRootPart.Position
	local closestPotion = nil
	local closestDistance = math.huge

	-- Check all children in workspace
	for _, obj in pairs(workspace:GetChildren()) do
		if obj and obj.Name and obj.Name:find("LuckPotion_") then
			-- Calculate center position of all parts in the potion
			local totalPosition = Vector3.new(0, 0, 0)
			local partCount = 0

			for _, child in pairs(obj:GetChildren()) do
				if child:IsA("BasePart") then
					totalPosition = totalPosition + child.Position
					partCount = partCount + 1
				end
			end

			if partCount > 0 then
				local centerPosition = totalPosition / partCount
				local distance = (playerPosition - centerPosition).Magnitude

				if distance <= DETECTION_RANGE and distance < closestDistance then
					closestDistance = distance
					closestPotion = obj
				end
			end
		end
	end

	-- Update nearby potion
	if closestPotion ~= nearbyPotion then
		nearbyPotion = closestPotion

		if nearbyPotion and not holdPrompt then
			print("?? RARE potion detected at distance: " .. math.floor(closestDistance))
			createHoldPrompt()
			-- NEW: Create sound when potion is detected
			createHoldSound()
		elseif not nearbyPotion and holdPrompt then
			print("?? No potion nearby")
			removeHoldPrompt()
			isHolding = false
			holdProgress = 0
			-- NEW: Stop and clean up sound
			stopHoldSound()
			if holdSound then
				holdSound:Destroy()
				holdSound = nil
			end
		end
	end
end

-- UPDATED: Handle input with sound
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E and nearbyPotion and not isHolding then
		isHolding = true
		holdStartTime = tick()
		holdProgress = 0
		-- NEW: Play hold sound when starting to hold
		playHoldSound()
		print("?? Started holding E for RARE potion")
	end
end)

-- UPDATED: Handle input end with sound stop
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.E and isHolding then
		isHolding = false
		holdProgress = 0
		updateProgressBar()
		-- NEW: Stop hold sound when releasing E
		stopHoldSound()
		print("?? Stopped holding E")
	end
end)

-- Main loop
RunService.Heartbeat:Connect(function()
	checkForNearbyPotions()
	updatePotionTimer()

	if isHolding and nearbyPotion then
		local holdTime = tick() - holdStartTime
		holdProgress = math.min(holdTime / HOLD_TIME, 1)
		updateProgressBar()

		if holdProgress >= 1 then
			isHolding = false
			holdProgress = 0

			-- NEW: Stop sound when pickup is complete
			stopHoldSound()

			if nearbyPotion and nearbyPotion.Parent then
				potionHoldEvent:FireServer(nearbyPotion)
				print("?? RARE potion pickup sent to server")
			end

			removeHoldPrompt()
			nearbyPotion = nil

			-- NEW: Clean up sound
			if holdSound then
				holdSound:Destroy()
				holdSound = nil
			end
		end
	end
end)

-- Function to create potion notification
local function createPotionNotification(luckBoost, duration)
	if notificationGui then
		notificationGui:Destroy()
	end

	notificationGui = Instance.new("Frame")
	notificationGui.Name = "PotionNotification"
	notificationGui.Size = UDim2.new(0, 150, 0, 80) -- Larger for "RARE"
	notificationGui.Position = UDim2.new(1, -170, 1, -150)
	notificationGui.BackgroundColor3 = Color3.fromRGB(40, 25, 60)
	notificationGui.BackgroundTransparency = 0.2
	notificationGui.BorderSizePixel = 0
	notificationGui.Parent = playerGui

	addCornerBrackets(notificationGui, Color3.fromRGB(255, 215, 0)) -- Gold brackets for rare

	-- Potion icon
	local potionIcon = Instance.new("ImageLabel")
	potionIcon.Size = UDim2.new(0, 35, 0, 35)
	potionIcon.Position = UDim2.new(0, 10, 0, 5)
	potionIcon.BackgroundTransparency = 1
	potionIcon.Image = "http://www.roblox.com/asset/?id=17368084270"
	potionIcon.ImageColor3 = Color3.fromRGB(255, 215, 0) -- Gold tint for rare
	potionIcon.ScaleType = Enum.ScaleType.Fit
	potionIcon.Parent = notificationGui

	-- RARE text
	local rareText = Instance.new("TextLabel")
	rareText.Size = UDim2.new(0, 90, 0, 20)
	rareText.Position = UDim2.new(0, 55, 0, 5)
	rareText.BackgroundTransparency = 1
	rareText.Font = Enum.Font.Arcade
	rareText.Text = ""
	rareText.TextColor3 = Color3.fromRGB(255, 215, 0)
	rareText.TextStrokeTransparency = 0.3
	rareText.TextScaled = true
	rareText.Parent = notificationGui

	-- Luck text
	local luckText = Instance.new("TextLabel")
	luckText.Size = UDim2.new(0, 90, 0, 25)
	luckText.Position = UDim2.new(0, 55, 0, 25)
	luckText.BackgroundTransparency = 1
	luckText.Font = Enum.Font.Arcade
	luckText.Text = "+" .. luckBoost .. "% LUCK"
	luckText.TextColor3 = Color3.fromRGB(100, 255, 100)
	luckText.TextStrokeTransparency = 0.3
	luckText.TextScaled = true
	luckText.Parent = notificationGui

	-- Timer text
	local timerText = Instance.new("TextLabel")
	timerText.Size = UDim2.new(0, 90, 0, 25)
	timerText.Position = UDim2.new(0, 55, 0, 50)
	timerText.BackgroundTransparency = 1
	timerText.Font = Enum.Font.Arcade
	timerText.Text = duration .. "s"
	timerText.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerText.TextStrokeTransparency = 0.3
	timerText.TextScaled = true
	timerText.Parent = notificationGui

	-- Enhanced glow for rare
	local glowFrame = Instance.new("Frame")
	glowFrame.Name = "Glow"
	glowFrame.Size = UDim2.new(1, 10, 1, 10)
	glowFrame.Position = UDim2.new(0, -5, 0, -5)
	glowFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	glowFrame.BackgroundTransparency = 0.7
	glowFrame.BorderSizePixel = 0
	glowFrame.ZIndex = notificationGui.ZIndex - 1
	glowFrame.Parent = notificationGui

	-- Slide in
	notificationGui.Position = UDim2.new(1, 20, 1, -150)
	TweenService:Create(notificationGui, 
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
		{Position = UDim2.new(1, -170, 1, -150)}
	):Play()

	-- Enhanced pulsing for rare
	spawn(function()
		while notificationGui and notificationGui.Parent do
			local pulse1 = TweenService:Create(glowFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.5})
			local pulse2 = TweenService:Create(glowFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.8})
			pulse1:Play()
			pulse1.Completed:Wait()
			if glowFrame and glowFrame.Parent then
				pulse2:Play()
				pulse2.Completed:Wait()
			else
				break
			end
		end
	end)

	-- Auto-remove after 4 seconds (longer for rare)
	spawn(function()
		wait(4)
		if notificationGui then
			TweenService:Create(notificationGui, 
				TweenInfo.new(0.5, Enum.EasingStyle.Quad), 
				{Position = UDim2.new(1, 20, 1, -150)}
			):Play()

			wait(0.5)
			if notificationGui then
				notificationGui:Destroy()
				notificationGui = nil
			end
		end
	end)
end

-- Handle events
potionPickedUpEvent.OnClientEvent:Connect(function(luckBoost, duration)
	currentPotionLuck = luckBoost
	potionEndTime = tick() + duration
	createPotionNotification(luckBoost, duration)
	createPotionTimerGui()
	print("?? RARE potion effect received: +" .. luckBoost .. "% for " .. duration .. "s")
end)

potionLuckUpdateEvent.OnClientEvent:Connect(function(luckBoost)
	currentPotionLuck = luckBoost
	if _G.updatePotionLuckBoost then
		_G.updatePotionLuckBoost(luckBoost)
	end

	if luckBoost == 0 then
		potionEndTime = 0
		print("?? RARE potion effect expired")
	end
end)

_G.getCurrentPotionLuck = function()
	return potionEndTime > tick() and currentPotionLuck or 0
end

-- NEW: Clean up sound when script is destroyed or player leaves
Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == player then
		stopHoldSound()
		if holdSound then
			holdSound:Destroy()
		end
	end
end)

print("?? RARE Potion Client loaded!")
print("?? Detection range: " .. DETECTION_RANGE .. " studs")
print("?? No transparent detection parts!")
print("?? Enhanced RARE potion experience!")
print("?? Hold sound ID: 140057358567917")