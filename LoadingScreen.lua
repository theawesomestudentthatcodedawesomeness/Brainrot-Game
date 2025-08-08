-- Enhanced LoadingScreen.lua - Direct transition to main menu without random camera positions
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("?? Enhanced LoadingScreen: Starting with direct main menu transition...")

-- ======================== CONFIGURATION ========================
local CONFIG = {
	-- Loading Settings
	TOTAL_ASSETS = 300,
	MIN_LOADING_TIME = 3,
	SKIP_AFTER_SECONDS = 2,
	FADE_DURATION = 1.2,
	ASSET_LOAD_SPEED = {8, 16},

	-- Visual Settings
	SPINNER_DECAL_ID = "http://www.roblox.com/asset/?id=124019391307480",
	SPINNER_SIZE = UDim2.new(0.08, 150, 0.08, 150),
	SPINNER_SPEED = 2,

	-- Colors
	BACKGROUND_COLOR = Color3.fromRGB(15, 18, 22),
	ACCENT_COLOR = Color3.fromRGB(120, 140, 255),
	TEXT_COLOR = Color3.fromRGB(220, 230, 245),
	BORDER_COLOR = Color3.fromRGB(80, 100, 140),

	-- Effects
	PARTICLE_COUNT = 0,
	GRADIENT_ANIMATION = false,
}

-- State Management
local LoadingState = {
	isActive = true,
	startTime = tick(),
	assetsLoaded = 0,
	skipPressed = false,
	guiHidden = {},
	connections = {},
	inputBlocked = true,
	cameraBlocked = true,
	originalCameraSettings = {} -- Store original camera settings
}

-- ======================== CAMERA MANAGEMENT ========================
local function preserveOriginalCamera()
	local camera = workspace.CurrentCamera
	LoadingState.originalCameraSettings = {
		cameraType = camera.CameraType,
		cameraSubject = camera.CameraSubject,
		cframe = camera.CFrame
	}
	print("?? Preserved original camera settings")
end

local function blockCameraForLoading()
	print("?? Blocking camera during loading...")

	local camera = workspace.CurrentCamera

	-- Store original settings first
	preserveOriginalCamera()

	-- Set camera to scriptable with a neutral loading position
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(Vector3.new(0, 50, 0), Vector3.new(0, 0, 0))

	-- Lock camera in place during loading
	LoadingState.connections.cameraLocker = RunService.RenderStepped:Connect(function()
		if LoadingState.cameraBlocked then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = CFrame.new(Vector3.new(0, 50, 0), Vector3.new(0, 0, 0))
		end
	end)
end

-- ? ENHANCED: Directly transition to main menu camera position
local function transitionToMainMenu()
	print("?? TRANSITIONING DIRECTLY TO MAIN MENU...")

	LoadingState.cameraBlocked = false

	-- Disconnect camera locker immediately
	if LoadingState.connections.cameraLocker then
		LoadingState.connections.cameraLocker:Disconnect()
		LoadingState.connections.cameraLocker = nil
	end

	local camera = workspace.CurrentCamera

	-- Set camera directly to main menu position (from your MainMenu script)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(
		Vector3.new(344.138, 109.998, 21.026),  -- Main menu camera position
		Vector3.new(357.277, 100.34, 5.186)    -- Main menu look at position
	)

	print("?? Camera set directly to main menu position")

	-- Create main menu signals immediately
	local loadingCompleteSignal = Instance.new("BoolValue")
	loadingCompleteSignal.Name = "LoadingComplete"
	loadingCompleteSignal.Value = true
	loadingCompleteSignal.Parent = ReplicatedStorage

	local startMenuSignal = Instance.new("BoolValue")
	startMenuSignal.Name = "StartMainMenu"
	startMenuSignal.Value = true
	startMenuSignal.Parent = ReplicatedStorage

	print("?? Created main menu signals - ready for main menu script")
end

-- ======================== INPUT BLOCKING ========================
local function blockAllInputs()
	print("?? Blocking all user inputs...")

	-- Block character movement
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.PlatformStand = true
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end

	-- Block input events
	LoadingState.connections.inputBlocker = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if LoadingState.inputBlocked and not gameProcessed then
			-- Only allow mouse clicks for UI interaction
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
		end
	end)

	print("?? All inputs locked for loading screen")
end

-- ======================== SAFE INPUT RESTORATION ========================
local function unblockAllInputs()
	print("? Starting safe input restoration...")

	-- Disable blocking flags
	LoadingState.inputBlocked = false
	LoadingState.cameraBlocked = false

	-- Disconnect ALL loading screen connections
	for name, connection in pairs(LoadingState.connections) do
		if connection then
			connection:Disconnect()
			print("? Disconnected:", name)
		end
	end
	LoadingState.connections = {}

	-- DON'T restore camera here - let the main menu handle it
	print("? Inputs unblocked - camera management passed to main menu")
end

-- ======================== GUI MANAGEMENT ========================
local function hideAllGuis()
	print("??? Hiding all GUIs during loading...")

	-- Hide core GUIs
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		print("? Core GUIs hidden")
	end)

	-- Hide existing custom GUIs
	for _, gui in pairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name ~= "LoadingScreen" then
			if gui.Enabled then
				LoadingState.guiHidden[gui] = true
				gui.Enabled = false
				print("?? Hidden GUI:", gui.Name)
			end
		end
	end

	-- Monitor for new GUIs during loading
	LoadingState.connections.guiMonitor = playerGui.ChildAdded:Connect(function(child)
		if child:IsA("ScreenGui") and child.Name ~= "LoadingScreen" and LoadingState.isActive then
			LoadingState.guiHidden[child] = true
			child.Enabled = false
			print("?? Auto-hidden new GUI:", child.Name)
		end
	end)
end

-- ======================== BEAUTIFUL LOADING SCREEN CREATION ========================
local function createEnhancedLoadingScreen()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LoadingScreen"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 1000
	screenGui.Parent = playerGui

	-- Main background frame
	local backgroundFrame = Instance.new("Frame")
	backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
	backgroundFrame.Position = UDim2.new(0, 0, 0, 0)
	backgroundFrame.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
	backgroundFrame.BorderSizePixel = 0
	backgroundFrame.Parent = screenGui

	-- Animated gradient overlay
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 18, 22)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 30, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 18, 22))
	}
	gradient.Rotation = 45
	gradient.Parent = backgroundFrame

	-- Animate gradient rotation
	if CONFIG.GRADIENT_ANIMATION then
		local gradientTween = TweenService:Create(gradient, 
			TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Rotation = gradient.Rotation + 360}
		)
		gradientTween:Play()
	end

	-- Floating particles background effect
	local particleFrame = Instance.new("Frame")
	particleFrame.Size = UDim2.new(1, 0, 1, 0)
	particleFrame.BackgroundTransparency = 1
	particleFrame.Parent = backgroundFrame

	-- Create floating particles
	for i = 1, CONFIG.PARTICLE_COUNT do
		local particle = Instance.new("Frame")
		particle.Size = UDim2.new(0, math.random(3, 8), 0, math.random(3, 8))
		particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
		particle.BackgroundColor3 = CONFIG.ACCENT_COLOR
		particle.BackgroundTransparency = math.random(60, 85) / 100
		particle.BorderSizePixel = 0
		particle.Parent = particleFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = particle

		-- Animate particle floating
		local floatTween = TweenService:Create(particle,
			TweenInfo.new(math.random(4, 10), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{
				Position = UDim2.new(math.random(), 0, math.random(), 0),
				BackgroundTransparency = math.random(40, 90) / 100
			}
		)
		floatTween:Play()
	end

	-- Enhanced corner decorations with glow effect
	local function createGlowCorner(position, size, anchorPoint)
		local cornerFrame = Instance.new("Frame")
		cornerFrame.Size = size
		cornerFrame.Position = position
		cornerFrame.AnchorPoint = anchorPoint
		cornerFrame.BackgroundColor3 = CONFIG.BORDER_COLOR
		cornerFrame.BorderSizePixel = 0
		cornerFrame.Parent = backgroundFrame

		local glow = Instance.new("UIStroke")
		glow.Color = CONFIG.ACCENT_COLOR
		glow.Thickness = 2
		glow.Transparency = 0.6
		glow.Parent = cornerFrame

		-- Animate glow pulsing
		local glowTween = TweenService:Create(glow,
			TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Transparency = 0.2, Thickness = 3}
		)
		glowTween:Play()

		return cornerFrame
	end

	-- Create all corner decorations
	createGlowCorner(UDim2.new(0, 0, 0, 0), UDim2.new(0, 120, 0, 4), Vector2.new(0, 0))
	createGlowCorner(UDim2.new(0, 0, 0, 0), UDim2.new(0, 4, 0, 120), Vector2.new(0, 0))
	createGlowCorner(UDim2.new(1, 0, 0, 0), UDim2.new(0, 120, 0, 4), Vector2.new(1, 0))
	createGlowCorner(UDim2.new(1, 0, 0, 0), UDim2.new(0, 4, 0, 120), Vector2.new(1, 0))
	createGlowCorner(UDim2.new(0, 0, 1, 0), UDim2.new(0, 120, 0, 4), Vector2.new(0, 1))
	createGlowCorner(UDim2.new(0, 0, 1, 0), UDim2.new(0, 4, 0, 120), Vector2.new(0, 1))
	createGlowCorner(UDim2.new(1, 0, 1, 0), UDim2.new(0, 120, 0, 4), Vector2.new(1, 1))
	createGlowCorner(UDim2.new(1, 0, 1, 0), UDim2.new(0, 4, 0, 120), Vector2.new(1, 1))

	-- Game title with enhanced styling
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0, 600, 0, 90)
	titleLabel.Position = UDim2.new(0.5, 0, 0.15, 0)
	titleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.Arcade
	titleLabel.Text = "Brainrot RNG"
	titleLabel.TextColor3 = CONFIG.TEXT_COLOR
	titleLabel.TextSize = 52
	titleLabel.TextStrokeTransparency = 0.1
	titleLabel.TextStrokeColor3 = CONFIG.ACCENT_COLOR
	titleLabel.Parent = backgroundFrame

	-- Title glow effect
	local titleGlow = Instance.new("UIStroke")
	titleGlow.Color = CONFIG.ACCENT_COLOR
	titleGlow.Thickness = 3
	titleGlow.Transparency = 0.4
	titleGlow.Parent = titleLabel

	-- Animated title glow
	local titleGlowTween = TweenService:Create(titleGlow,
		TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Transparency = 0.1, Thickness = 5}
	)
	titleGlowTween:Play()

	-- Loading spinner with custom decal
	local spinnerContainer = Instance.new("Frame")
	spinnerContainer.Size = CONFIG.SPINNER_SIZE
	spinnerContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	spinnerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	spinnerContainer.BackgroundTransparency = 1
	spinnerContainer.BorderSizePixel = 0
	spinnerContainer.Parent = backgroundFrame

	local spinnerDecal = Instance.new("ImageLabel")
	spinnerDecal.Size = UDim2.new(1, 0, 1, 0)
	spinnerDecal.Position = UDim2.new(0, 0, -0.25, 0)
	spinnerDecal.BackgroundTransparency = 1
	spinnerDecal.BorderSizePixel = 0
	spinnerDecal.Image = CONFIG.SPINNER_DECAL_ID
	spinnerDecal.ImageColor3 = Color3.fromRGB(255, 255, 255)
	spinnerDecal.Parent = spinnerContainer

	-- Continuous spinning animation
	local spinTween = TweenService:Create(spinnerDecal,
		TweenInfo.new(CONFIG.SPINNER_SPEED, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{Rotation = 360}
	)
	spinTween:Play()

	-- Loading text with dynamic updates
	local loadingText = Instance.new("TextLabel")
	loadingText.Size = UDim2.new(0, 700, 0, 50)
	loadingText.Position = UDim2.new(0.5, 0, 0.72, 0)
	loadingText.AnchorPoint = Vector2.new(0.5, 0.5)
	loadingText.BackgroundTransparency = 1
	loadingText.Font = Enum.Font.Arcade
	loadingText.Text = "Loading Assets... [0/" .. CONFIG.TOTAL_ASSETS .. "]"
	loadingText.TextColor3 = CONFIG.TEXT_COLOR
	loadingText.TextSize = 22
	loadingText.TextStrokeTransparency = 0.2
	loadingText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	loadingText.Parent = backgroundFrame

	-- Progress bar background
	local progressBarBG = Instance.new("Frame")
	progressBarBG.Size = UDim2.new(0, 450, 0, 10)
	progressBarBG.Position = UDim2.new(0.5, 0, 0.78, 0)
	progressBarBG.AnchorPoint = Vector2.new(0.5, 0.5)
	progressBarBG.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
	progressBarBG.BorderSizePixel = 0
	progressBarBG.Parent = backgroundFrame

	local progressBarBGCorner = Instance.new("UICorner")
	progressBarBGCorner.CornerRadius = UDim.new(0, 5)
	progressBarBGCorner.Parent = progressBarBG

	-- Actual progress bar
	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.Position = UDim2.new(0, 0, 0, 0)
	progressBar.BackgroundColor3 = CONFIG.ACCENT_COLOR
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressBarBG

	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(0, 5)
	progressBarCorner.Parent = progressBar

	-- Progress bar glow effect
	local progressGlow = Instance.new("UIStroke")
	progressGlow.Color = CONFIG.ACCENT_COLOR
	progressGlow.Thickness = 2
	progressGlow.Transparency = 0.3
	progressGlow.Parent = progressBar

	-- Skip button with enhanced styling
	local skipButton = Instance.new("TextButton")
	skipButton.Size = UDim2.new(0, 200, 0, 55)
	skipButton.Position = UDim2.new(0.5, 0, 0.88, 0)
	skipButton.AnchorPoint = Vector2.new(0.5, 0.5)
	skipButton.BackgroundColor3 = Color3.fromRGB(40, 50, 65)
	skipButton.BorderSizePixel = 0
	skipButton.Font = Enum.Font.Arcade
	skipButton.Text = "[ SKIP LOADING ]"
	skipButton.TextColor3 = CONFIG.TEXT_COLOR
	skipButton.TextSize = 18
	skipButton.TextStrokeTransparency = 0.2
	skipButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	skipButton.Visible = false
	skipButton.Parent = backgroundFrame

	local skipButtonCorner = Instance.new("UICorner")
	skipButtonCorner.CornerRadius = UDim.new(0, 8)
	skipButtonCorner.Parent = skipButton

	local skipButtonStroke = Instance.new("UIStroke")
	skipButtonStroke.Color = CONFIG.BORDER_COLOR
	skipButtonStroke.Thickness = 2
	skipButtonStroke.Parent = skipButton

	-- Skip button hover animations
	skipButton.MouseEnter:Connect(function()
		if LoadingState.isActive then
			TweenService:Create(skipButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				BackgroundColor3 = Color3.fromRGB(70, 80, 95),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.new(0, 210, 0, 60)
			}):Play()
			TweenService:Create(skipButtonStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				Color = CONFIG.ACCENT_COLOR,
				Thickness = 3
			}):Play()
		end
	end)

	skipButton.MouseLeave:Connect(function()
		if LoadingState.isActive then
			TweenService:Create(skipButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				BackgroundColor3 = Color3.fromRGB(40, 50, 65),
				TextColor3 = CONFIG.TEXT_COLOR,
				Size = UDim2.new(0, 200, 0, 55)
			}):Play()
			TweenService:Create(skipButtonStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				Color = CONFIG.BORDER_COLOR,
				Thickness = 2
			}):Play()
		end
	end)

	-- Show skip button after delay
	task.spawn(function()
		task.wait(CONFIG.SKIP_AFTER_SECONDS)
		if LoadingState.isActive then
			skipButton.Visible = true
			TweenService:Create(skipButton, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 0, 
				TextTransparency = 0, 
				TextStrokeTransparency = 0.2
			}):Play()
			TweenService:Create(skipButtonStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
				Transparency = 0
			}):Play()
		end
	end)

	return screenGui, loadingText, progressBar, skipButton
end

-- ======================== REALISTIC LOADING SIMULATION ========================
local function simulateLoading(loadingText, progressBar, skipButton)
	task.spawn(function()
		print("?? Starting enhanced loading simulation...")

		local loadingMessages = {
			"Grabbing Tun Tun Tun Sahur's bat...",
			"Tra-la-la la la...", 
			"Studying Italian Brainrot Lore...",
			"La Vaca Saturna Saturnita will visit...",
			"Loading Game Assets...",
			"Preparing Main Menu..."
		}

		for phase = 1, #loadingMessages do
			if not LoadingState.isActive then break end

			-- Update phase message
			loadingText.Text = loadingMessages[phase]
			print("?? Loading Phase " .. phase .. ": " .. loadingMessages[phase])

			-- Simulate loading this phase
			local phaseStart = (phase - 1) / #loadingMessages
			local phaseEnd = phase / #loadingMessages

			for step = 1, 25 do
				if not LoadingState.isActive then break end

				local phaseProgress = step / 25
				local totalProgress = phaseStart + (phaseEnd - phaseStart) * phaseProgress

				LoadingState.assetsLoaded = math.floor(totalProgress * CONFIG.TOTAL_ASSETS)

				-- Update text with current progress
				loadingText.Text = loadingMessages[phase] .. " [" .. LoadingState.assetsLoaded .. "/" .. CONFIG.TOTAL_ASSETS .. "]"

				-- Smooth progress bar animation
				TweenService:Create(progressBar, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
					Size = UDim2.new(totalProgress, 0, 1, 0)
				}):Play()

				-- Random delay to simulate real loading
				task.wait(math.random(40, 120) / 1000)
			end
		end

		-- Final completion sequence
		if LoadingState.isActive then
			LoadingState.assetsLoaded = CONFIG.TOTAL_ASSETS
			loadingText.Text = "Loading Complete! Launching Main Menu... [" .. CONFIG.TOTAL_ASSETS .. "/" .. CONFIG.TOTAL_ASSETS .. "]"

			-- Final progress bar completion
			TweenService:Create(progressBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
				Size = UDim2.new(1, 0, 1, 0)
			}):Play()

			print("? Loading simulation completed successfully!")
			task.wait(1) -- Brief pause to show completion
			LoadingState.isActive = false
		end
	end)
end

-- ======================== MAIN EXECUTION ========================
print("?? Enhanced LoadingScreen: Full initialization with direct main menu transition...")

-- Step 1: Lock everything down
blockAllInputs()
blockCameraForLoading() -- New: Block camera specifically for loading
hideAllGuis()

-- Step 2: Create beautiful loading screen
local screenGui, loadingText, progressBar, skipButton = createEnhancedLoadingScreen()

-- Step 3: Set up skip functionality
skipButton.Activated:Connect(function()
	if LoadingState.isActive then
		print("?? Loading manually skipped by user")
		LoadingState.skipPressed = true
		LoadingState.isActive = false
		loadingText.Text = "Loading Skipped! Launching Main Menu... [" .. LoadingState.assetsLoaded .. "/" .. CONFIG.TOTAL_ASSETS .. "]"
	end
end)

-- Step 4: Start loading simulation
simulateLoading(loadingText, progressBar, skipButton)

-- Step 5: Wait for loading to complete
print("? Waiting for loading to complete...")
while LoadingState.isActive do
	task.wait(0.1)
end

print("? Loading completed! Starting main menu transition sequence...")

-- Step 6: Fade out loading screen
local function fadeOutLoadingScreen()
	print("?? Starting fade out animation...")
	local elements = screenGui:GetDescendants()

	for _, element in ipairs(elements) do
		if element:IsA("GuiObject") then
			local fadeProps = {}

			if element.BackgroundTransparency < 1 then
				fadeProps.BackgroundTransparency = 1
			end
			if element:IsA("TextLabel") or element:IsA("TextButton") then
				fadeProps.TextTransparency = 1
				fadeProps.TextStrokeTransparency = 1
			end
			if element:IsA("ImageLabel") then
				fadeProps.ImageTransparency = 1
			end

			if next(fadeProps) then
				TweenService:Create(element, TweenInfo.new(CONFIG.FADE_DURATION, Enum.EasingStyle.Quad), fadeProps):Play()
			end
		end
	end
end

fadeOutLoadingScreen()

-- Step 7: Wait for fade completion
task.wait(CONFIG.FADE_DURATION)

-- Step 8: Transition directly to main menu
transitionToMainMenu() -- New: Direct transition to main menu position
unblockAllInputs()

-- Clean up loading screen
screenGui:Destroy()

print("?? LoadingScreen complete! Main menu should now start with correct camera position!")
print("?? All signals created and camera positioned for main menu")