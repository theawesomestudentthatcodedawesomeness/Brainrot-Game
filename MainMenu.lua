-- MainMenu.lua - Complete enhanced main menu with fixed parent validation
-- Created: 2025-07-29 06:24:56 UTC  
-- User: theawesomestudentthatcodedawesomeness

-- Wait for loading screen completion
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("?? MainMenu: Waiting for loading screen to complete...")

-- Wait for completion signals with timeout
local loadingComplete = ReplicatedStorage:WaitForChild("LoadingComplete", 15)
local startMenuSignal = ReplicatedStorage:WaitForChild("StartMainMenu", 15)

if loadingComplete or startMenuSignal then
	print("?? MainMenu: Loading screen completed successfully!")

	-- Clean up signals
	if loadingComplete then loadingComplete:Destroy() end
	if startMenuSignal then startMenuSignal:Destroy() end

	-- ? IMPORTANT: The camera should already be in the correct position!
	local camera = workspace.CurrentCamera
	print("?? Current camera position:", camera.CFrame.Position)
	print("?? Current camera type:", camera.CameraType)

	-- Verify camera is in main menu position
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(
		Vector3.new(344.138, 109.998, 21.026),
		Vector3.new(357.277, 100.34, 5.186)
	)

	task.wait(0.2) -- Brief delay for stability
else
	print("?? MainMenu: Starting without loading screen (timeout)")
end

-- ======================== MAIN MENU INITIALIZATION ========================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

print("?? MainMenu: Starting enhanced initialization...")

-- ======================== CONFIGURATION ========================
local CONFIG = {
	-- Camera positions
	CAMERA_POSITION = Vector3.new(611.414, 106.382, 163.037),
	CAMERA_LOOK_AT = Vector3.new(479.75, 98.984, 103.237),

	-- Animation timings
	FADE_DURATION = 1,
	TITLE_DELAY = 0.3,
	SUBTITLE_DELAY = 0.6,
	UPDATE_DELAY = 9999,
	BUTTON_DELAY = 2,

	-- Enhanced colors
	BUTTON_COLOR = Color3.fromRGB(50, 60, 80),
	BUTTON_HOVER_COLOR = Color3.fromRGB(80, 90, 110),
	BUTTON_BORDER_COLOR = Color3.fromRGB(80, 100, 140),
	BUTTON_ACCENT_COLOR = Color3.fromRGB(120, 140, 255),
	BUTTON_TEXT_COLOR = Color3.fromRGB(220, 230, 245),
}

-- State Management
local MenuState = {
	isActive = true,
	inputBlocked = true,
	connections = {},
	guiHidden = {},
	gameStarted = false
}

local cameraLockerConnection = nil

-- ======================== ENHANCED SAFE TWEEN FUNCTION ========================
local function safeTween(instance, tweenInfo, properties, description)
	-- ? ENHANCED: Multiple validation checks
	if not instance then
		warn("?? SafeTween: Cannot tween nil instance for " .. (description or "unknown"))
		return nil
	end

	-- ? FIXED: Better parent validation
	if not instance.Parent then
		warn("?? SafeTween: Instance has no parent for " .. (description or "unknown"))
		return nil
	end

	-- ? NEW: Check if parent is still valid
	local parentValid = false
	pcall(function()
		parentValid = instance.Parent ~= nil and instance.Parent.Parent ~= nil
	end)

	if not parentValid then
		warn("?? SafeTween: Instance parent chain is invalid for " .. (description or "unknown"))
		return nil
	end

	-- ? NEW: Additional validation for GUI objects
	if instance:IsA("GuiObject") then
		local gui = instance
		while gui and not gui:IsA("ScreenGui") do
			gui = gui.Parent
			if not gui then
				warn("?? SafeTween: GUI object not connected to ScreenGui for " .. (description or "unknown"))
				return nil
			end
		end
	end

	-- Create and play tween with error handling
	local success, tween = pcall(function()
		return TweenService:Create(instance, tweenInfo, properties)
	end)

	if success and tween then
		-- ? ENHANCED: Verify tween creation was successful
		local playSuccess = pcall(function()
			tween:Play()
		end)

		if playSuccess then
			print("? SafeTween: Successfully created and played tween for " .. (description or "unknown"))
			return tween
		else
			warn("?? SafeTween: Failed to play tween for " .. (description or "unknown"))
			return nil
		end
	else
		warn("?? SafeTween: Failed to create tween for " .. (description or "unknown") .. ": " .. tostring(tween))
		return nil
	end
end

-- ======================== CAMERA AND INPUT CONTROL ========================
local function lockCameraAndInputs()
	print("?? MainMenu: Locking camera and inputs...")

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(CONFIG.CAMERA_POSITION, CONFIG.CAMERA_LOOK_AT)

	-- Lock character movement
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.PlatformStand = true
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end

	-- Camera locking connection
	cameraLockerConnection = RunService.RenderStepped:Connect(function()
		if MenuState.inputBlocked then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = CFrame.lookAt(CONFIG.CAMERA_POSITION, CONFIG.CAMERA_LOOK_AT)
		end
	end)

	print("? Camera and inputs locked for main menu")
end

-- ? ENHANCED CAMERA RESTORATION SYSTEM ?
local function unlockCameraAndInputs()
	print("?? MainMenu: Starting complete camera and input restoration...")

	-- Stop blocking immediately
	MenuState.inputBlocked = false

	-- Disconnect camera locker first
	if cameraLockerConnection then
		cameraLockerConnection:Disconnect()
		cameraLockerConnection = nil
		print("? Camera locker connection disconnected")
	end

	-- Disconnect all other connections
	for name, connection in pairs(MenuState.connections) do
		if connection then
			connection:Disconnect()
			print("? Disconnected:", name)
		end
	end
	MenuState.connections = {}

	-- CRITICAL: Comprehensive camera restoration
	task.spawn(function()
		task.wait(0.2) -- Allow disconnections to process

		print("?? RESTORING CAMERA TO PLAYER...")

		local currentCamera = workspace.CurrentCamera

		-- Reset camera to custom mode
		currentCamera.CameraType = Enum.CameraType.Custom

		-- Ensure we have a character
		local character = player.Character
		if not character then
			print("? Waiting for character to spawn...")
			character = player.CharacterAdded:Wait()
		end

		-- Wait for essential character parts
		local humanoid = character:WaitForChild("Humanoid", 10)
		local rootPart = character:WaitForChild("HumanoidRootPart", 10)

		if humanoid and rootPart then
			-- Set camera subject
			currentCamera.CameraSubject = humanoid

			-- Restore character movement capabilities
			humanoid.PlatformStand = false
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50

			-- Position camera properly behind player
			task.wait(0.3)
			local lookDirection = rootPart.CFrame.LookVector
			local cameraPosition = rootPart.Position - lookDirection * 10 + Vector3.new(0, 6, 0)

			currentCamera.CFrame = CFrame.lookAt(cameraPosition, rootPart.Position + Vector3.new(0, 2, 0))

			print("? CAMERA FULLY RESTORED TO PLAYER!")
			print("? CHARACTER MOVEMENT RESTORED!")
		else
			warn("? Camera restoration failed - attempting character respawn...")
			player:LoadCharacter()
		end
	end)
end

-- ======================== GUI MANAGEMENT ========================
local function hideAllGuis()
	print("??? MainMenu: Managing GUIs...")

	-- Hide core GUIs
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		print("? Core GUIs hidden")
	end)

	-- Hide existing custom GUIs
	for _, gui in pairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name ~= "MainMenu" then
			if gui.Enabled then
				MenuState.guiHidden[gui] = true
				gui.Enabled = false
				print("?? Hidden GUI:", gui.Name)
			end
		end
	end

	-- Monitor for new GUIs
	MenuState.connections.guiMonitor = playerGui.ChildAdded:Connect(function(child)
		if child:IsA("ScreenGui") and child.Name ~= "MainMenu" then
			if MenuState.isActive then
				MenuState.guiHidden[child] = true
				child.Enabled = false
				print("?? Auto-hidden new GUI:", child.Name)
			elseif MenuState.gameStarted then
				child.Enabled = true
				print("??? Auto-enabled new GUI:", child.Name)
			end
		end
	end)
end

local function restoreAllGuis()
	print("?? MainMenu: Restoring all GUIs...")
	MenuState.gameStarted = true

	-- Re-enable core GUIs
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		print("? Core GUIs restored")
	end)

	-- Restore all existing GUIs
	local guiCount = 0
	for _, gui in pairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name ~= "MainMenu" then
			gui.Enabled = true
			guiCount = guiCount + 1
			print("? Restored GUI:", gui.Name)
		end
	end

	print("?? Total GUIs restored:", guiCount)
	MenuState.guiHidden = {}
end

-- ======================== ENHANCED MAIN MENU CREATION ========================
local function createMainMenu()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainMenu"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 1000
	screenGui.Parent = playerGui

	-- ? VERIFICATION: Ensure ScreenGui is properly parented
	if not screenGui.Parent then
		error("Failed to parent ScreenGui to PlayerGui")
	end
	print("? ScreenGui successfully created and parented")

	-- Semi-transparent background
	local backgroundFrame = Instance.new("Frame")
	backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
	backgroundFrame.Position = UDim2.new(0, 0, 0, 0)
	backgroundFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backgroundFrame.BackgroundTransparency = 1 -- Start invisible
	backgroundFrame.BorderSizePixel = 0
	backgroundFrame.Parent = screenGui

	-- ? VERIFICATION: Ensure background is properly parented
	if not backgroundFrame.Parent then
		error("Failed to parent backgroundFrame to screenGui")
	end
	print("? Background frame successfully created and parented")

	-- Game title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(0, 600, 0, 100)
	titleLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.Arcade
	titleLabel.Text = "BRAINROT RNG"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 48
	titleLabel.TextStrokeTransparency = 1 -- Start invisible
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.TextTransparency = 1 -- Start invisible
	titleLabel.Parent = backgroundFrame

	-- Subtitle
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "SubtitleLabel"
	subtitleLabel.Size = UDim2.new(0, 400, 0, 30)
	subtitleLabel.Position = UDim2.new(0.1, 0, 0.22, 0)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Font = Enum.Font.Arcade
	subtitleLabel.Text = "Los Tralalelitos Dicen Tralala"
	subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	subtitleLabel.TextSize = 16
	subtitleLabel.TextStrokeTransparency = 1 -- Start invisible
	subtitleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	subtitleLabel.TextTransparency = 1 -- Start invisible
	subtitleLabel.Parent = backgroundFrame

	-- Update text
	local updateLabel = Instance.new("TextLabel")
	updateLabel.Name = "updateLabel"
	updateLabel.Size = UDim2.new(0, 400, 0, 30)
	updateLabel.Position = UDim2.new(0.35, 0, 0.35, 0)
	updateLabel.BackgroundTransparency = 1
	updateLabel.Font = Enum.Font.Arcade
	updateLabel.Text = "Gears finally added! New brainrots and Auras coming out."
	updateLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	updateLabel.TextSize = 16
	updateLabel.TextStrokeTransparency = 1 -- Start invisible
	updateLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	updateLabel.TextTransparency = 1 -- Start invisible
	updateLabel.Parent = backgroundFrame

	-- Corner decorations
	local function createCornerBorder(position, size, anchorPoint)
		local border = Instance.new("Frame")
		border.Size = size
		border.Position = position
		border.AnchorPoint = anchorPoint
		border.BackgroundColor3 = Color3.fromRGB(100, 120, 140)
		border.BackgroundTransparency = 1 -- Start invisible
		border.BorderSizePixel = 0
		border.Parent = backgroundFrame
		return border
	end

	-- Create corner decorations
	local corners = {}
	corners[1] = createCornerBorder(UDim2.new(0, 0, 0, 0), UDim2.new(0, 100, 0, 3), Vector2.new(0, 0))
	corners[2] = createCornerBorder(UDim2.new(0, 0, 0, 0), UDim2.new(0, 3, 0, 100), Vector2.new(0, 0))
	corners[3] = createCornerBorder(UDim2.new(1, 0, 0, 0), UDim2.new(0, 100, 0, 3), Vector2.new(1, 0))
	corners[4] = createCornerBorder(UDim2.new(1, 0, 0, 0), UDim2.new(0, 3, 0, 100), Vector2.new(1, 0))
	corners[5] = createCornerBorder(UDim2.new(0, 0, 1, 0), UDim2.new(0, 100, 0, 3), Vector2.new(0, 1))
	corners[6] = createCornerBorder(UDim2.new(0, 0, 1, 0), UDim2.new(0, 3, 0, 100), Vector2.new(0, 1))
	corners[7] = createCornerBorder(UDim2.new(1, 0, 1, 0), UDim2.new(0, 100, 0, 3), Vector2.new(1, 1))
	corners[8] = createCornerBorder(UDim2.new(1, 0, 1, 0), UDim2.new(0, 3, 0, 100), Vector2.new(1, 1))

	-- Enhanced start button
	local startButton = Instance.new("TextButton")
	startButton.Name = "StartButton"
	startButton.Size = UDim2.new(0, 250, 0, 70)
	startButton.Position = UDim2.new(0.5, -125, 0.8, -35)
	startButton.BackgroundColor3 = CONFIG.BUTTON_COLOR
	startButton.BackgroundTransparency = 1 -- Start invisible
	startButton.BorderSizePixel = 0
	startButton.Font = Enum.Font.Arcade
	startButton.Text = "PLAY"
	startButton.TextColor3 = CONFIG.BUTTON_TEXT_COLOR
	startButton.TextSize = 24
	startButton.TextStrokeTransparency = 1 -- Start invisible
	startButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	startButton.TextTransparency = 1 -- Start invisible
	startButton.Parent = backgroundFrame

	-- ? VERIFICATION: Ensure button is properly parented
	if not startButton.Parent then
		error("Failed to parent startButton to backgroundFrame")
	end
	print("? Start button successfully created and parented")

	-- Enhanced button styling
	local startButtonCorner = Instance.new("UICorner")
	startButtonCorner.CornerRadius = UDim.new(0, 8)
	startButtonCorner.Parent = startButton

	local startButtonStroke = Instance.new("UIStroke")
	startButtonStroke.Color = CONFIG.BUTTON_BORDER_COLOR
	startButtonStroke.Thickness = 2
	startButtonStroke.Transparency = 1 -- Start invisible
	startButtonStroke.Parent = startButton

	-- ? VERIFICATION: Ensure all button components are properly parented
	if not startButtonStroke.Parent then
		error("Failed to parent startButtonStroke to startButton")
	end
	print("? Button stroke successfully created and parented")

	-- ? FIXED BUTTON HOVER EFFECTS WITH ENHANCED VALIDATION ?
	startButton.MouseEnter:Connect(function()
		if MenuState.isActive and startButton.Parent and startButtonStroke.Parent then
			print("??? Button hover detected")

			-- Safe tween for button
			safeTween(startButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				BackgroundColor3 = CONFIG.BUTTON_HOVER_COLOR,
				Size = UDim2.new(0, 260, 0, 75),
				Position = UDim2.new(0.5, -130, 0.8, -37.5)
			}, "button hover")

			-- Safe tween for stroke with enhanced validation
			if startButtonStroke and startButtonStroke.Parent and startButtonStroke.Parent.Parent then
				safeTween(startButtonStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
					Color = CONFIG.BUTTON_ACCENT_COLOR, 
					Thickness = 3
				}, "button stroke hover")
			end
		end
	end)

	startButton.MouseLeave:Connect(function()
		if MenuState.isActive and startButton.Parent and startButtonStroke.Parent then
			print("??? Button hover ended")

			-- Safe tween for button
			safeTween(startButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				BackgroundColor3 = CONFIG.BUTTON_COLOR,
				Size = UDim2.new(0, 250, 0, 70),
				Position = UDim2.new(0.5, -125, 0.8, -35)
			}, "button unhover")

			-- Safe tween for stroke with enhanced validation
			if startButtonStroke and startButtonStroke.Parent and startButtonStroke.Parent.Parent then
				safeTween(startButtonStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
					Color = CONFIG.BUTTON_BORDER_COLOR, 
					Thickness = 2
				}, "button stroke unhover")
			end
		end
	end)

	print("? All GUI elements successfully created with proper parent validation")
	return screenGui, startButton, backgroundFrame, titleLabel, subtitleLabel, updateLabel, corners, startButtonStroke
end

-- ======================== SAFE CASCADING ANIMATIONS WITH ENHANCED VALIDATION ========================
local function startCascadingAnimations(titleLabel, subtitleLabel, updateLabel, startButton, backgroundFrame, corners, startButtonStroke)
	print("?? Starting enhanced cascading animations with full validation...")

	-- ? VERIFICATION: Check all elements exist and are properly parented before starting animations
	local elementsToCheck = {
		{backgroundFrame, "backgroundFrame"},
		{titleLabel, "titleLabel"},
		{subtitleLabel, "subtitleLabel"}, 
		{updateLabel, "updateLabel"},
		{startButton, "startButton"},
		{startButtonStroke, "startButtonStroke"}
	}

	for _, elementData in ipairs(elementsToCheck) do
		local element, name = elementData[1], elementData[2]
		if not element or not element.Parent then
			warn("?? Animation Error: " .. name .. " is missing or has no parent!")
			return
		end
	end

	for i, corner in ipairs(corners) do
		if not corner or not corner.Parent then
			warn("?? Animation Error: corner " .. i .. " is missing or has no parent!")
			return
		end
	end

	print("? All animation elements validated successfully")

	-- Background fade in
	safeTween(backgroundFrame, TweenInfo.new(CONFIG.FADE_DURATION, Enum.EasingStyle.Quad), {
		BackgroundTransparency = 0.3
	}, "background fade in")

	-- Fade in corners
	for i, corner in ipairs(corners) do
		if corner and corner.Parent then
			safeTween(corner, TweenInfo.new(CONFIG.FADE_DURATION, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 0
			}, "corner " .. i .. " fade in")
		end
	end

	-- Title animation (first)
	task.spawn(function()
		task.wait(CONFIG.TITLE_DELAY)
		if titleLabel and titleLabel.Parent then
			safeTween(titleLabel, TweenInfo.new(CONFIG.FADE_DURATION, Enum.EasingStyle.Quad), {
				TextTransparency = 0, 
				TextStrokeTransparency = 0.3
			}, "title animation")
			print("?? Title animated")
		end
	end)

	-- Subtitle animation (second)
	task.spawn(function()
		task.wait(CONFIG.SUBTITLE_DELAY)
		if subtitleLabel and subtitleLabel.Parent then
			safeTween(subtitleLabel, TweenInfo.new(CONFIG.FADE_DURATION, Enum.EasingStyle.Quad), {
				TextTransparency = 0, 
				TextStrokeTransparency = 0.5
			}, "subtitle animation")
			print("?? Subtitle animated")
		end
	end)

	-- Update text animation (third)
	task.spawn(function()
		task.wait(CONFIG.UPDATE_DELAY)
		if updateLabel and updateLabel.Parent then
			safeTween(updateLabel, TweenInfo.new(CONFIG.FADE_DURATION, Enum.EasingStyle.Quad), {
				TextTransparency = 0, 
				TextStrokeTransparency = 0.5
			}, "update text animation")
			print("?? Update text animated")
		end
	end)

	-- ? ENHANCED: Start button animation with comprehensive validation
	task.spawn(function()
		task.wait(CONFIG.BUTTON_DELAY)

		-- Triple-check button existence and parent chain before animating
		if startButton and startButton.Parent and startButton.Parent.Parent then
			print("?? Starting button animation - all validations passed")

			safeTween(startButton, TweenInfo.new(CONFIG.FADE_DURATION, Enum.EasingStyle.Quad), {
				TextTransparency = 0, 
				TextStrokeTransparency = 0.3,
				BackgroundTransparency = 0
			}, "start button animation")

			-- Enhanced stroke animation with thorough validation
			if startButtonStroke and startButtonStroke.Parent and startButtonStroke.Parent.Parent and startButtonStroke.Parent.Parent.Parent then
				print("?? Starting button stroke animation - all validations passed")
				safeTween(startButtonStroke, TweenInfo.new(CONFIG.FADE_DURATION, Enum.EasingStyle.Quad), {
					Transparency = 0
				}, "start button stroke animation")
			else
				warn("?? Skipping stroke animation - validation failed")
				if startButtonStroke then
					print("Debug: startButtonStroke exists:", startButtonStroke ~= nil)
					print("Debug: startButtonStroke.Parent:", startButtonStroke.Parent ~= nil)
					if startButtonStroke.Parent then
						print("Debug: startButtonStroke.Parent.Parent:", startButtonStroke.Parent.Parent ~= nil)
					end
				end
			end
			print("?? Start button animated")
		else
			warn("?? Skipping button animation - validation failed")
			if startButton then
				print("Debug: startButton exists:", startButton ~= nil)
				print("Debug: startButton.Parent:", startButton.Parent ~= nil)
				if startButton.Parent then
					print("Debug: startButton.Parent.Parent:", startButton.Parent.Parent ~= nil)
				end
			end
		end
	end)
end

-- ======================== MAIN EXECUTION ========================
print("?? MainMenu: Starting complete enhanced menu system...")

-- Initialize menu systems
lockCameraAndInputs()
hideAllGuis()

local screenGui, startButton, backgroundFrame, titleLabel, subtitleLabel, updateLabel, corners, startButtonStroke = createMainMenu()

-- ? VERIFICATION: Final check before starting animations
task.wait(0.1) -- Brief delay to ensure all elements are fully initialized

print("?? Final validation before starting animations...")
if screenGui and screenGui.Parent and 
	backgroundFrame and backgroundFrame.Parent and 
	startButton and startButton.Parent and 
	startButtonStroke and startButtonStroke.Parent then
	print("? All elements validated - starting animations")
	-- Start the beautiful cascading animations
	startCascadingAnimations(titleLabel, subtitleLabel, updateLabel, startButton, backgroundFrame, corners, startButtonStroke)
else
	error("? Critical elements missing or not properly parented - cannot start animations")
end

print("?? Setting up enhanced button click handler...")

-- Handle start button click with complete restoration
startButton.Activated:Connect(function()
	print("?????? START BUTTON CLICKED! ??????")

	if not MenuState.isActive then
		print("?? Menu already deactivated, ignoring click")
		return
	end

	MenuState.isActive = false

	-- Visual feedback
	startButton.Text = "STARTING..."
	startButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)

	-- Restore all game systems
	restoreAllGuis()
	unlockCameraAndInputs()

	-- Safe fade out animations with validation
	if backgroundFrame and backgroundFrame.Parent then
		safeTween(backgroundFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1
		}, "background fade out")
	end

	if titleLabel and titleLabel.Parent then
		safeTween(titleLabel, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
			TextTransparency = 1, TextStrokeTransparency = 1
		}, "title fade out")
	end

	if subtitleLabel and subtitleLabel.Parent then
		safeTween(subtitleLabel, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
			TextTransparency = 1, TextStrokeTransparency = 1
		}, "subtitle fade out")
	end

	if updateLabel and updateLabel.Parent then
		safeTween(updateLabel, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
			TextTransparency = 1, TextStrokeTransparency = 1
		}, "update label fade out")
	end

	if startButton and startButton.Parent then
		safeTween(startButton, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
			TextTransparency = 1, TextStrokeTransparency = 1, BackgroundTransparency = 1
		}, "start button fade out")
	end

	-- Fade out corners safely
	for i, corner in ipairs(corners) do
		if corner and corner.Parent then
			safeTween(corner, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 1
			}, "corner " .. i .. " fade out")
		end
	end

	-- Destroy menu after fade
	task.spawn(function()
		task.wait(0.8)
		if screenGui and screenGui.Parent then
			screenGui:Destroy()
		end

		-- Final safety check for GUIs
		task.wait(1)
		local finalGuiCount = 0
		for _, gui in pairs(playerGui:GetChildren()) do
			if gui:IsA("ScreenGui") then
				finalGuiCount = finalGuiCount + 1
				if not gui.Enabled then
					gui.Enabled = true
					print("? Final-enabled GUI:", gui.Name)
				end
			end
		end
		print("?? Final GUI count:", finalGuiCount)
		print("?????? GAME FULLY STARTED! ??????")
	end)
end)

-- Create backward compatibility signals
local gameStartedSignal = Instance.new("BoolValue")
gameStartedSignal.Name = "GameStarted"
gameStartedSignal.Parent = ReplicatedStorage

startButton.Activated:Connect(function()
	print("?? Setting GameStarted signal to true...")
	gameStartedSignal.Value = true
end)

print("?? Enhanced MainMenu with Complete Parent Validation Ready!")
print("?? All parent chains validated and error handling implemented!")