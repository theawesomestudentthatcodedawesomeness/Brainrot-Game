-- StarterGui > LocalScript - Potion Arrow Guide System (MULTIPLE POTIONS - FIXED)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvent
local PotionArrowGuide = ReplicatedStorage:WaitForChild("PotionArrowGuide", 10)

if not PotionArrowGuide then
	warn("?? PotionArrowGuide remote not found")
	return
end

print("?? POTION ARROW GUIDE CLIENT LOADED")

-- Variables
local activeArrows = {} -- Store multiple arrows
local arrowConnections = {} -- Store multiple connections
local arrowEndTime = 0

-- Create arrow GUI
local function createArrowGUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "PotionArrowGui"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	return gui
end

local arrowGui = createArrowGUI()

-- Function to create a single arrow indicator
local function createSingleArrow(targetPosition, potionName, duration, potionId)
	print("?? Creating arrow guide to: " .. tostring(targetPosition) .. " for " .. duration .. " seconds (ID: " .. tostring(potionId) .. ")")

	-- Create arrow frame (30% smaller)
	local activeArrow = Instance.new("Frame")
	activeArrow.Name = "PotionArrow_" .. tostring(potionId)
	activeArrow.Size = UDim2.new(0, 70, 0, 70)
	activeArrow.Position = UDim2.new(0.5, -35, 0.5, -35)
	activeArrow.BackgroundTransparency = 1
	activeArrow.Parent = arrowGui

	-- Arrow icon (30% smaller)
	local arrowIcon = Instance.new("TextLabel")
	arrowIcon.Name = "ArrowIcon"
	arrowIcon.Size = UDim2.new(0, 42, 0, 42)
	arrowIcon.Position = UDim2.new(0.5, -21, 0.5, -21)
	arrowIcon.BackgroundTransparency = 1
	arrowIcon.Text = "??"
	arrowIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
	arrowIcon.TextSize = 25
	arrowIcon.Font = Enum.Font.Arcade
	arrowIcon.TextStrokeTransparency = 0.3
	arrowIcon.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	arrowIcon.Parent = activeArrow

	-- Arrow pointer (30% smaller)
	local arrowPointer = Instance.new("TextLabel")
	arrowPointer.Name = "ArrowPointer"
	arrowPointer.Size = UDim2.new(0, 28, 0, 28)
	arrowPointer.Position = UDim2.new(0.5, -14, 0, -32)
	arrowPointer.BackgroundTransparency = 1
	arrowPointer.Text = "?"
	arrowPointer.TextColor3 = Color3.fromRGB(255, 100, 255)
	arrowPointer.TextSize = 17
	arrowPointer.Font = Enum.Font.Arcade
	arrowPointer.TextStrokeTransparency = 0.3
	arrowPointer.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	arrowPointer.Parent = activeArrow

	-- Distance text (30% smaller)
	local distanceText = Instance.new("TextLabel")
	distanceText.Name = "DistanceText"
	distanceText.Size = UDim2.new(0, 70, 0, 18)
	distanceText.Position = UDim2.new(0.5, -35, 1, 4)
	distanceText.BackgroundTransparency = 1
	distanceText.Text = "0m"
	distanceText.TextColor3 = Color3.fromRGB(255, 255, 255)
	distanceText.TextSize = 12
	distanceText.Font = Enum.Font.Arcade
	distanceText.TextStrokeTransparency = 0.3
	distanceText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	distanceText.Parent = activeArrow

	-- Timer text (30% smaller)
	local timerText = Instance.new("TextLabel")
	timerText.Name = "TimerText"
	timerText.Size = UDim2.new(0, 70, 0, 14)
	timerText.Position = UDim2.new(0.5, -35, 1, 22)
	timerText.BackgroundTransparency = 1
	timerText.Text = duration .. "s"
	timerText.TextColor3 = Color3.fromRGB(255, 215, 0)
	timerText.TextSize = 10
	timerText.Font = Enum.Font.Arcade
	timerText.TextStrokeTransparency = 0.3
	timerText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	timerText.Parent = activeArrow

	-- Glow effect around arrow (30% smaller)
	local glowFrame = Instance.new("Frame")
	glowFrame.Name = "ArrowGlow"
	glowFrame.Size = UDim2.new(1, 14, 1, 14)
	glowFrame.Position = UDim2.new(0, -7, 0, -7)
	glowFrame.BackgroundColor3 = Color3.fromRGB(255, 100, 255)
	glowFrame.BackgroundTransparency = 0.7
	glowFrame.BorderSizePixel = 0
	glowFrame.ZIndex = activeArrow.ZIndex - 1
	glowFrame.Parent = activeArrow

	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(1, 0)
	glowCorner.Parent = glowFrame

	-- Store the arrow
	activeArrows[potionId] = {
		frame = activeArrow,
		targetPosition = targetPosition,
		potionName = potionName,
		endTime = tick() + duration
	}

	-- Pulsing glow animation
	spawn(function()
		while activeArrows[potionId] and activeArrows[potionId].frame and activeArrows[potionId].frame.Parent and tick() < activeArrows[potionId].endTime do
			local pulse1 = TweenService:Create(glowFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
				BackgroundTransparency = 0.5,
				Size = UDim2.new(1, 18, 1, 18)
			})
			local pulse2 = TweenService:Create(glowFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
				BackgroundTransparency = 0.8,
				Size = UDim2.new(1, 10, 1, 10)
			})

			pulse1:Play()
			pulse1.Completed:Wait()
			pulse2:Play()
			pulse2.Completed:Wait()
		end
	end)

	-- Icon pulsing animation
	spawn(function()
		while activeArrows[potionId] and activeArrows[potionId].frame and activeArrows[potionId].frame.Parent and tick() < activeArrows[potionId].endTime do
			local iconPulse1 = TweenService:Create(arrowIcon, TweenInfo.new(1, Enum.EasingStyle.Sine), {
				TextSize = 28
			})
			local iconPulse2 = TweenService:Create(arrowIcon, TweenInfo.new(1, Enum.EasingStyle.Sine), {
				TextSize = 25
			})

			iconPulse1:Play()
			iconPulse1.Completed:Wait()
			iconPulse2:Play()
			iconPulse2.Completed:Wait()
		end
	end)

	-- Entrance animation
	activeArrow.Size = UDim2.new(0, 0, 0, 0)
	local enterTween = TweenService:Create(activeArrow, 
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 70, 0, 70)}
	)
	enterTween:Play()

	return activeArrow
end

-- Function to remove a specific arrow
local function removeArrow(potionId)
	if activeArrows[potionId] then
		local arrowData = activeArrows[potionId]
		if arrowData.frame then
			local fadeOut = TweenService:Create(arrowData.frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
				Size = UDim2.new(0, 0, 0, 0)
			})
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				if arrowData.frame then
					arrowData.frame:Destroy()
				end
			end)
		end
		activeArrows[potionId] = nil
	end
end

-- ?? FIXED: Function to create arrows for multiple potions
local function createMultipleArrows(potionsData)
	print("?? Creating arrows for " .. #potionsData .. " potions")

	-- Clear existing arrows
	for potionId, _ in pairs(activeArrows) do
		removeArrow(potionId)
	end

	-- Clear existing connections
	for _, connection in pairs(arrowConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	arrowConnections = {}

	-- Create arrow for each potion
	for i, potionData in ipairs(potionsData) do
		if potionData.targetPosition and potionData.duration then
			local potionId = potionData.potionId or ("potion_" .. i)
			createSingleArrow(potionData.targetPosition, potionData.potionName or "Luck Potion", potionData.duration, potionId)
		end
	end

	-- ?? FIXED: Declare masterConnection properly
	local masterConnection
	masterConnection = RunService.Heartbeat:Connect(function()
		local currentTime = tick()
		local arrowsToRemove = {}

		-- Update all active arrows
		for potionId, arrowData in pairs(activeArrows) do
			local activeArrow = arrowData.frame
			local targetPosition = arrowData.targetPosition
			local timeLeft = arrowData.endTime - currentTime

			if not activeArrow or not activeArrow.Parent or timeLeft <= 0 then
				-- Mark for removal
				table.insert(arrowsToRemove, potionId)
			else
				-- Update this arrow
				local timerText = activeArrow:FindFirstChild("TimerText")
				local distanceText = activeArrow:FindFirstChild("DistanceText")
				local arrowIcon = activeArrow:FindFirstChild("ArrowIcon")
				local arrowPointer = activeArrow:FindFirstChild("ArrowPointer")

				if timerText then
					timerText.Text = math.ceil(timeLeft) .. "s"

					-- Change timer color as time runs out
					if timeLeft <= 3 then
						timerText.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red
					elseif timeLeft <= 6 then
						timerText.TextColor3 = Color3.fromRGB(255, 200, 100) -- Orange
					else
						timerText.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
					end
				end

				-- Get player position
				local character = player.Character
				if character and character:FindFirstChild("HumanoidRootPart") then
					local playerPosition = character.HumanoidRootPart.Position
					local camera = workspace.CurrentCamera

					if camera then
						-- Calculate direction to target
						local directionVector = (targetPosition - playerPosition).Unit
						local distance = (targetPosition - playerPosition).Magnitude

						-- Update distance text
						if distanceText then
							distanceText.Text = math.floor(distance) .. "m"
						end

						-- Position arrows to avoid overlap
						local baseOffset = (tonumber(potionId:match("(%d+)")) or 0) * 80 -- Spread arrows apart

						-- Convert 3D direction to screen direction
						local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
						local worldToScreen, onScreen = camera:WorldToScreenPoint(targetPosition)

						if onScreen then
							-- Target is on screen, position arrow pointing to it
							local screenDirection = Vector2.new(worldToScreen.X - screenCenter.X, worldToScreen.Y - screenCenter.Y)
							local screenDistance = screenDirection.Magnitude

							if screenDistance > 100 then
								-- Target is far from center, position arrow on edge
								local normalizedDirection = screenDirection.Unit
								local arrowScreenPos = screenCenter + normalizedDirection * (150 + baseOffset * 0.3)

								activeArrow.Position = UDim2.new(0, arrowScreenPos.X - 35, 0, arrowScreenPos.Y - 35)

								-- Rotate arrow pointer to point toward target
								if arrowPointer then
									local angle = math.atan2(normalizedDirection.Y, normalizedDirection.X)
									arrowPointer.Rotation = math.deg(angle) + 90
								end
							else
								-- Target is near center, offset arrows to avoid overlap
								local offsetX = math.sin(baseOffset * 0.1) * 60
								local offsetY = math.cos(baseOffset * 0.1) * 60
								activeArrow.Position = UDim2.new(0.5, -35 + offsetX, 0.5, -35 + offsetY)
								if arrowPointer then
									arrowPointer.Rotation = 0
								end
							end
						else
							-- Target is off screen, position arrow on edge of screen
							local cameraLookDirection = camera.CFrame.LookVector
							local rightVector = camera.CFrame.RightVector
							local upVector = camera.CFrame.UpVector

							-- Project direction onto camera plane
							local relativeDirection = directionVector
							local screenX = relativeDirection:Dot(rightVector)
							local screenY = -relativeDirection:Dot(upVector)

							local screenDirection = Vector2.new(screenX, screenY).Unit
							local arrowScreenPos = screenCenter + screenDirection * 200

							-- Clamp to screen edges with offset to prevent overlap
							arrowScreenPos = Vector2.new(
								math.clamp(arrowScreenPos.X, 100, camera.ViewportSize.X - 100),
								math.clamp(arrowScreenPos.Y, 100, camera.ViewportSize.Y - 100)
							)

							-- Add small offset to prevent overlapping
							local offsetAngle = baseOffset * 0.2
							local offsetRadius = 30
							arrowScreenPos = arrowScreenPos + Vector2.new(
								math.cos(offsetAngle) * offsetRadius,
								math.sin(offsetAngle) * offsetRadius
							)

							activeArrow.Position = UDim2.new(0, arrowScreenPos.X - 35, 0, arrowScreenPos.Y - 35)

							-- Rotate arrow pointer
							if arrowPointer then
								local angle = math.atan2(screenDirection.Y, screenDirection.X)
								arrowPointer.Rotation = math.deg(angle) + 90
							end
						end

						-- Change color based on distance
						if arrowIcon and arrowPointer then
							if distance < 20 then
								arrowIcon.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green when close
								arrowPointer.TextColor3 = Color3.fromRGB(100, 255, 100)
							elseif distance < 50 then
								arrowIcon.TextColor3 = Color3.fromRGB(255, 255, 100) -- Yellow when medium distance
								arrowPointer.TextColor3 = Color3.fromRGB(255, 255, 100)
							else
								arrowIcon.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold when far
								arrowPointer.TextColor3 = Color3.fromRGB(255, 100, 255)
							end
						end
					end
				end
			end
		end

		-- Remove expired arrows
		for _, potionId in ipairs(arrowsToRemove) do
			removeArrow(potionId)
		end

		-- If no arrows left, disconnect the master connection
		if next(activeArrows) == nil then
			masterConnection:Disconnect()
		end
	end)

	table.insert(arrowConnections, masterConnection)
end

-- Handle arrow guide requests
PotionArrowGuide.OnClientEvent:Connect(function(guideData)
	print("?? Received arrow guide request: " .. tostring(guideData))

	-- Handle both single potion and multiple potions
	if guideData then
		if guideData.potions and type(guideData.potions) == "table" then
			-- Multiple potions
			createMultipleArrows(guideData.potions)
		elseif guideData.targetPosition and guideData.duration then
			-- Single potion (backwards compatibility)
			createMultipleArrows({{
				targetPosition = guideData.targetPosition,
				potionName = guideData.potionName or "Luck Potion",
				duration = guideData.duration,
				potionId = "single_potion"
			}})
		else
			warn("?? Invalid guide data received")
		end
	else
		warn("?? No guide data received")
	end
end)

-- Clean up when player respawns
player.CharacterAdded:Connect(function()
	wait(2) -- Wait for character to fully load
	-- Arrows will continue working after respawn
end)

print("?? ?? Potion Arrow Guide System loaded!")
print("?? Matteoooo's VIP players will receive 12-second arrow guidance to ALL potions!")