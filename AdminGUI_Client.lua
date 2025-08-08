-- Place in StarterGui > LocalScript
-- Admin GUI with Full Command Output Display (FIXED - Auto-close on death)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local AdminGUIRemotes = ReplicatedStorage:WaitForChild("AdminGUIRemotes")
local OpenAdminGUI = AdminGUIRemotes:WaitForChild("OpenAdminGUI")
local UpdateAdminLog = AdminGUIRemotes:WaitForChild("UpdateAdminLog")
local SendCommandResult = AdminGUIRemotes:WaitForChild("SendCommandResult")
local SendCommandOutput = AdminGUIRemotes:WaitForChild("SendCommandOutput")

local adminGui = nil
local isGuiOpen = false
local logEntries = {}
local MAX_LOG_ENTRIES = 50

-- Store references separately
local logScrollFrame = nil
local statusText = nil
local mainPanel = nil
local toggleButton = nil

-- Connection storage for cleanup
local connections = {}

-- Function to clean up all connections
local function cleanupConnections()
	for i, connection in ipairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end
	connections = {}
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

-- Function to create the admin GUI
local function createAdminGUI()
	-- Clean up old GUI and connections
	if adminGui then
		cleanupConnections()
		adminGui:Destroy()
	end

	print("?? Creating Admin GUI...")

	-- Main ScreenGui
	adminGui = Instance.new("ScreenGui")
	adminGui.Name = "AdminGUI"
	adminGui.ResetOnSpawn = false
	adminGui.DisplayOrder = 100
	adminGui.Parent = playerGui

	-- Toggle button (bottom right)
	toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(0, 50, 0, 50)
	toggleButton.Position = UDim2.new(1, -65, 1, -65)
	toggleButton.BackgroundColor3 = Color3.fromRGB(70, 40, 100)
	toggleButton.BackgroundTransparency = 0.2
	toggleButton.BorderSizePixel = 0
	toggleButton.Text = "??"
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.TextSize = 24
	toggleButton.Font = Enum.Font.Arcade
	toggleButton.Parent = adminGui

	addCornerBrackets(toggleButton, Color3.fromRGB(255, 100, 255))

	-- LARGER Main panel for more output
	mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.new(0, 700, 0, 500) -- Larger size
	mainPanel.Position = UDim2.new(1, -720, 1, -570)
	mainPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	mainPanel.BackgroundTransparency = 0.1
	mainPanel.BorderSizePixel = 0
	mainPanel.Visible = false
	mainPanel.Parent = adminGui

	addCornerBrackets(mainPanel, Color3.fromRGB(255, 100, 255))

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(70, 40, 100)
	titleBar.BackgroundTransparency = 0.2
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainPanel

	local titleText = Instance.new("TextLabel")
	titleText.Name = "TitleText"
	titleText.Size = UDim2.new(1, -80, 1, 0)
	titleText.Position = UDim2.new(0, 10, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = "?? ADMIN PANEL - FULL OUTPUT"
	titleText.TextColor3 = Color3.fromRGB(255, 100, 255)
	titleText.TextSize = 18
	titleText.Font = Enum.Font.Arcade
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Parent = titleBar

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -35, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "?"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 16
	closeButton.Font = Enum.Font.Arcade
	closeButton.Parent = titleBar

	-- Content area
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, -20, 1, -60)
	contentFrame.Position = UDim2.new(0, 10, 0, 50)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = mainPanel

	-- Log title
	local logTitle = Instance.new("TextLabel")
	logTitle.Name = "LogTitle"
	logTitle.Size = UDim2.new(1, 0, 0, 25)
	logTitle.Position = UDim2.new(0, 0, 0, 0)
	logTitle.BackgroundTransparency = 1
	logTitle.Text = "?? COMMAND OUTPUT & LOGS"
	logTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	logTitle.TextSize = 16
	logTitle.Font = Enum.Font.Arcade
	logTitle.TextXAlignment = Enum.TextXAlignment.Left
	logTitle.Parent = contentFrame

	-- Scrolling frame for logs
	logScrollFrame = Instance.new("ScrollingFrame")
	logScrollFrame.Name = "LogScrollFrame"
	logScrollFrame.Size = UDim2.new(1, -10, 1, -35)
	logScrollFrame.Position = UDim2.new(0, 0, 0, 30)
	logScrollFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	logScrollFrame.BackgroundTransparency = 0.3
	logScrollFrame.BorderSizePixel = 0
	logScrollFrame.ScrollBarThickness = 8
	logScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 100, 255)
	logScrollFrame.Parent = contentFrame

	-- Status bar at bottom of main panel
	local statusBar = Instance.new("Frame")
	statusBar.Name = "StatusBar"
	statusBar.Size = UDim2.new(1, 0, 0, 25)
	statusBar.Position = UDim2.new(0, 0, 1, -25)
	statusBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	statusBar.BorderSizePixel = 0
	statusBar.Parent = mainPanel

	statusText = Instance.new("TextLabel")
	statusText.Name = "StatusText"
	statusText.Size = UDim2.new(1, -10, 1, 0)
	statusText.Position = UDim2.new(0, 5, 0, 0)
	statusText.BackgroundTransparency = 1
	statusText.Text = "Ready - Admin Level 50"
	statusText.TextColor3 = Color3.fromRGB(100, 255, 100)
	statusText.TextSize = 12
	statusText.Font = Enum.Font.Arcade
	statusText.TextXAlignment = Enum.TextXAlignment.Left
	statusText.Parent = statusBar

	-- Toggle functionality
	local function togglePanel()
		isGuiOpen = not isGuiOpen
		mainPanel.Visible = isGuiOpen

		if isGuiOpen then
			-- Slide in animation
			mainPanel.Position = UDim2.new(1, 20, 1, -570)
			local slideIn = TweenService:Create(mainPanel,
				TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Position = UDim2.new(1, -720, 1, -570)}
			)
			slideIn:Play()
		end
	end

	-- FIXED: Store connections for proper cleanup
	table.insert(connections, toggleButton.MouseButton1Click:Connect(togglePanel))
	table.insert(connections, closeButton.MouseButton1Click:Connect(togglePanel))

	print("?? Admin GUI created successfully!")
end

-- ENHANCED: Function to add log entry with full output
local function addLogEntry(logData)
	if not logScrollFrame or not logScrollFrame.Parent then
		return
	end

	-- Add to entries list
	table.insert(logEntries, logData)

	-- Trim if too many entries
	if #logEntries > MAX_LOG_ENTRIES then
		table.remove(logEntries, 1)
	end

	-- Clear existing log entries
	for _, child in pairs(logScrollFrame:GetChildren()) do
		if child.Name:find("LogEntry") then
			child:Destroy()
		end
	end

	-- Add all entries
	local yOffset = 0
	for i, entry in ipairs(logEntries) do
		-- Command header
		local commandEntry = Instance.new("Frame")
		commandEntry.Name = "LogEntry_Command_" .. i
		commandEntry.Size = UDim2.new(1, -10, 0, 30)
		commandEntry.Position = UDim2.new(0, 5, 0, yOffset)
		commandEntry.BackgroundColor3 = entry.success and Color3.fromRGB(20, 40, 20) or Color3.fromRGB(40, 20, 20)
		commandEntry.BackgroundTransparency = 0.3
		commandEntry.BorderSizePixel = 0
		commandEntry.Parent = logScrollFrame

		local commandText = Instance.new("TextLabel")
		commandText.Size = UDim2.new(1, -10, 1, 0)
		commandText.Position = UDim2.new(0, 5, 0, 0)
		commandText.BackgroundTransparency = 1
		commandText.Text = string.format("?? [%s] %s", 
			entry.timeString or "00:00:00", 
			entry.command or "Unknown")
		commandText.TextColor3 = Color3.fromRGB(255, 215, 0)
		commandText.TextSize = 14
		commandText.Font = Enum.Font.Arcade
		commandText.TextXAlignment = Enum.TextXAlignment.Left
		commandText.TextTruncate = Enum.TextTruncate.AtEnd
		commandText.Parent = commandEntry

		yOffset = yOffset + 35

		-- Output lines
		if entry.fullOutput and #entry.fullOutput > 0 then
			for _, outputLine in ipairs(entry.fullOutput) do
				local outputEntry = Instance.new("Frame")
				outputEntry.Name = "LogEntry_Output_" .. i
				outputEntry.Size = UDim2.new(1, -20, 0, 20)
				outputEntry.Position = UDim2.new(0, 15, 0, yOffset)
				outputEntry.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
				outputEntry.BackgroundTransparency = 0.7
				outputEntry.BorderSizePixel = 0
				outputEntry.Parent = logScrollFrame

				local outputText = Instance.new("TextLabel")
				outputText.Size = UDim2.new(1, -10, 1, 0)
				outputText.Position = UDim2.new(0, 5, 0, 0)
				outputText.BackgroundTransparency = 1
				outputText.Text = outputLine
				outputText.TextColor3 = Color3.fromRGB(200, 200, 200)
				outputText.TextSize = 11
				outputText.Font = Enum.Font.Code
				outputText.TextXAlignment = Enum.TextXAlignment.Left
				outputText.TextTruncate = Enum.TextTruncate.AtEnd
				outputText.Parent = outputEntry

				yOffset = yOffset + 25
			end
		else
			-- Show result if no full output
			if entry.error then
				local resultEntry = Instance.new("Frame")
				resultEntry.Name = "LogEntry_Result_" .. i
				resultEntry.Size = UDim2.new(1, -20, 0, 20)
				resultEntry.Position = UDim2.new(0, 15, 0, yOffset)
				resultEntry.BackgroundColor3 = Color3.fromRGB(40, 15, 15)
				resultEntry.BackgroundTransparency = 0.7
				resultEntry.BorderSizePixel = 0
				resultEntry.Parent = logScrollFrame

				local resultText = Instance.new("TextLabel")
				resultText.Size = UDim2.new(1, -10, 1, 0)
				resultText.Position = UDim2.new(0, 5, 0, 0)
				resultText.BackgroundTransparency = 1
				resultText.Text = "? " .. entry.error
				resultText.TextColor3 = Color3.fromRGB(255, 100, 100)
				resultText.TextSize = 11
				resultText.Font = Enum.Font.Code
				resultText.TextXAlignment = Enum.TextXAlignment.Left
				resultText.TextTruncate = Enum.TextTruncate.AtEnd
				resultText.Parent = resultEntry

				yOffset = yOffset + 25
			end
		end

		yOffset = yOffset + 10 -- Spacing between entries
	end

	-- Update canvas size
	logScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)

	-- Auto-scroll to bottom
	logScrollFrame.CanvasPosition = Vector2.new(0, math.max(0, yOffset - logScrollFrame.AbsoluteSize.Y))
end

-- Function to update status
local function updateStatus(success, message)
	if not statusText or not statusText.Parent then
		return
	end

	statusText.Text = message or "Ready - Admin Level 50"
	statusText.TextColor3 = success and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)

	-- Reset to ready after 3 seconds
	spawn(function()
		wait(3)
		if statusText and statusText.Parent then
			statusText.Text = "Ready - Admin Level 50"
			statusText.TextColor3 = Color3.fromRGB(100, 255, 100)
		end
	end)
end

-- FIXED: Character death handling - Auto-close GUI
local function onCharacterDied()
	print("?? Character died - closing admin GUI")
	if mainPanel and mainPanel.Visible then
		isGuiOpen = false
		mainPanel.Visible = false
	end
end

local function onCharacterAdded(character)
	print("?? Character respawned - setting up death detection")

	-- Wait for Humanoid
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(onCharacterDied)
end

-- Connect character events
if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Event handlers
OpenAdminGUI.OnClientEvent:Connect(function()
	print("?? Admin GUI requested!")
	createAdminGUI()
end)

UpdateAdminLog.OnClientEvent:Connect(function(logData)
	print("?? Received log update: " .. tostring(logData.command))
	addLogEntry(logData)
end)

SendCommandResult.OnClientEvent:Connect(function(success, message)
	print("?? Received command result: " .. tostring(message))
	updateStatus(success, message)
end)

SendCommandOutput.OnClientEvent:Connect(function(outputLines)
	print("?? Received command output: " .. #outputLines .. " lines")
	-- Output is already included in the log entry, so this is just for debugging
end)

print("?? Admin GUI Client with Full Output loaded!")