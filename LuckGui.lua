-- Enhanced Luck GUI Script - Hover Bug Fixed + Gamepass Integration
-- Place this LocalScript in StarterGui

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer

-- Wait for PlayerGui to be ready
local playerGui = player:WaitForChild("PlayerGui")

-- Gamepass IDs (replace with your actual gamepass IDs)
local LUCK_BOOST_GAMEPASS_ID = 1378491109 -- Replace with your actual gamepass ID
local PREMIUM_LUCK_GAMEPASS_ID = 1376797718 -- Replace with your premium luck gamepass ID if you have one

-- Variables for luck tracking (with anti-flicker system)
local currentLuckBoost = 1
local badgeLuckBoost = 0
local gamepassLuckBoost = 0
local potionLuckBoost = 0
local maxLuckBoost = 10
local isHovering = false

-- Anti-flicker system
local lastKnownLuckState = {
	badge = 0,
	gamepass = 0,
	potion = 0,
	lastUpdate = 0
}

local FLICKER_PREVENTION_TIME = 2

-- GUI references
local gui = nil
local luckContainer = nil
local luckDecal = nil
local hoverButton = nil
local tooltip = nil
local tooltipTitle = nil
local tooltipRollValue = nil
local tooltipGearValue = nil
local tooltipGamepassValue = nil
local tooltipPotionValue = nil
local tooltipTotalValue = nil
local tooltipDesc = nil

-- Connection storage for cleanup
local connections = {}

-- Forward declarations
local setupHoverEvents
local updateLuckDisplay
local createLuckGlow
local refreshGamepassLuck

-- Function to update last known state (MOVED UP)
local function updateLastKnownState(badge, gamepass, potion)
	lastKnownLuckState.badge = badge
	lastKnownLuckState.gamepass = gamepass
	lastKnownLuckState.potion = potion
	lastKnownLuckState.lastUpdate = tick()
end

-- Anti-flicker function to validate luck changes (MOVED UP)
local function validateLuckChange(newBadgeLuck, newGamepassLuck, newPotionLuck)
	local currentTime = tick()

	-- Always allow increases immediately
	if newBadgeLuck > lastKnownLuckState.badge or 
		newGamepassLuck > lastKnownLuckState.gamepass or 
		newPotionLuck > lastKnownLuckState.potion then
		return true
	end

	-- For decreases, check if enough time has passed since last update
	if currentTime - lastKnownLuckState.lastUpdate < FLICKER_PREVENTION_TIME then
		print("?? ?? Anti-flicker: Ignoring potential luck downgrade (too soon)")
		return false
	end

	return true
end

-- Function to check gamepass ownership
local function checkGamepassOwnership(gamepassId)
	local success, ownsGamepass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)
	return success and ownsGamepass
end

-- Function to calculate gamepass luck boost
local function calculateGamepassLuckBoost()
	local totalBoost = 0

	-- Check premium luck boost first (higher priority)
	if checkGamepassOwnership(PREMIUM_LUCK_GAMEPASS_ID) then
		totalBoost = totalBoost + 100 -- 100% boost for premium
		print("?? Player has premium luck gamepass: +100%")
	end

	-- Check standard luck boost
	if checkGamepassOwnership(LUCK_BOOST_GAMEPASS_ID) then
		totalBoost = totalBoost + 25 -- 25% boost for standard (changed from 50 to match your existing system)
		print("?? Player has standard luck gamepass: +25%")
	end

	return totalBoost
end

-- Function to refresh gamepass luck boosts (NOW PROPERLY DEFINED AFTER updateLastKnownState)
refreshGamepassLuck = function()
	spawn(function()
		local newGamepassBoost = calculateGamepassLuckBoost()

		if newGamepassBoost ~= gamepassLuckBoost then
			gamepassLuckBoost = newGamepassBoost
			updateLastKnownState(badgeLuckBoost, gamepassLuckBoost, potionLuckBoost)
			if updateLuckDisplay then updateLuckDisplay() end
			if createLuckGlow then createLuckGlow() end
			print("?? ? Gamepass luck boost updated to: +" .. gamepassLuckBoost .. "%")
		end
	end)
end

-- Function to clean up all connections
local function cleanupConnections()
	for i, connection in ipairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end
	connections = {}
end

-- Helper function to create corner brackets
local function addCornerBrackets(parent, color)
	local thickness = 1
	local length = 8

	-- Clear existing brackets
	for _, child in pairs(parent:GetChildren()) do
		if child.Name:find("Bracket") then
			child:Destroy()
		end
	end

	local brackets = {
		{name = "BracketTL1", size = UDim2.new(0, length, 0, thickness), pos = UDim2.new(0, 0, 0, 0)},
		{name = "BracketTL2", size = UDim2.new(0, thickness, 0, length), pos = UDim2.new(0, 0, 0, 0)},
		{name = "BracketTR1", size = UDim2.new(0, length, 0, thickness), pos = UDim2.new(1, -length, 0, 0)},
		{name = "BracketTR2", size = UDim2.new(0, thickness, 0, length), pos = UDim2.new(1, -thickness, 0, 0)},
		{name = "BracketBL1", size = UDim2.new(0, length, 0, thickness), pos = UDim2.new(0, 0, 1, -thickness)},
		{name = "BracketBL2", size = UDim2.new(0, thickness, 0, length), pos = UDim2.new(0, 0, 1, -length)},
		{name = "BracketBR1", size = UDim2.new(0, length, 0, thickness), pos = UDim2.new(1, -length, 1, -thickness)},
		{name = "BracketBR2", size = UDim2.new(0, thickness, 0, length), pos = UDim2.new(1, -thickness, 1, -length)}
	}

	for _, bracket in ipairs(brackets) do
		local frame = Instance.new("Frame")
		frame.Name = bracket.name
		frame.Size = bracket.size
		frame.Position = bracket.pos
		frame.BackgroundColor3 = color
		frame.BorderSizePixel = 0
		frame.Parent = parent
	end
end

-- Function to calculate total luck boost
local function getTotalLuckBoost()
	local gearMultiplier = 1 + (badgeLuckBoost / 100)
	local gamepassMultiplier = 1 + (gamepassLuckBoost / 100)
	local potionMultiplier = 1 + (potionLuckBoost / 100)
	local totalMultiplier = currentLuckBoost * gearMultiplier * gamepassMultiplier * potionMultiplier
	return totalMultiplier
end

-- Function to update luck display (FIXED with anti-flicker)
updateLuckDisplay = function()
	if not gui or not gui.Parent then
		return
	end

	if not tooltipRollValue or not tooltipRollValue.Parent or
		not tooltipGearValue or not tooltipGearValue.Parent or
		not tooltipGamepassValue or not tooltipGamepassValue.Parent or 
		not tooltipPotionValue or not tooltipPotionValue.Parent or
		not tooltipTotalValue or not tooltipTotalValue.Parent or
		not tooltipDesc or not tooltipDesc.Parent or
		not tooltipTitle or not tooltipTitle.Parent or
		not luckDecal or not luckDecal.Parent then
		return
	end

	local totalLuckBoost = getTotalLuckBoost()

	-- Update tooltip text with proper gamepass display
	tooltipRollValue.Text = "Roll: " .. currentLuckBoost .. "x"
	tooltipGearValue.Text = "Gears: +" .. badgeLuckBoost .. "%"

	-- Enhanced gamepass display
	if gamepassLuckBoost > 0 then
		tooltipGamepassValue.Text = "Gamepass: +" .. gamepassLuckBoost .. "%"
		tooltipGamepassValue.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color for active gamepass
	else
		tooltipGamepassValue.Text = "Gamepass: +0%"
		tooltipGamepassValue.TextColor3 = Color3.fromRGB(150, 150, 150) -- Gray color for no gamepass
	end

	tooltipPotionValue.Text = "Potion: +" .. potionLuckBoost .. "%"
	tooltipTotalValue.Text = string.format("Total: %.2fx", totalLuckBoost)

	-- Change decal color based on total luck level
	local newColor
	local newBracketColor

	if totalLuckBoost >= 10 then
		newColor = Color3.fromRGB(255, 0, 255)
		newBracketColor = Color3.fromRGB(255, 0, 255)
		tooltipTitle.TextColor3 = Color3.fromRGB(255, 0, 255)
		tooltipTotalValue.TextColor3 = Color3.fromRGB(255, 0, 255)
		tooltipDesc.Text = "GODLIKE boost!"
		tooltipDesc.TextColor3 = Color3.fromRGB(255, 0, 255)
	elseif totalLuckBoost >= 8 then
		newColor = Color3.fromRGB(255, 100, 255)
		newBracketColor = Color3.fromRGB(255, 100, 255)
		tooltipTitle.TextColor3 = Color3.fromRGB(255, 100, 255)
		tooltipTotalValue.TextColor3 = Color3.fromRGB(255, 100, 255)
		tooltipDesc.Text = "INSANE boost!"
		tooltipDesc.TextColor3 = Color3.fromRGB(255, 100, 255)
	elseif totalLuckBoost >= 5 then
		newColor = Color3.fromRGB(255, 150, 0)
		newBracketColor = Color3.fromRGB(255, 150, 0)
		tooltipTitle.TextColor3 = Color3.fromRGB(255, 150, 0)
		tooltipTotalValue.TextColor3 = Color3.fromRGB(255, 150, 0)
		tooltipDesc.Text = "HIGH boost!"
		tooltipDesc.TextColor3 = Color3.fromRGB(255, 150, 0)
	elseif totalLuckBoost >= 3 then
		newColor = Color3.fromRGB(255, 215, 0)
		newBracketColor = Color3.fromRGB(255, 215, 0)
		tooltipTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
		tooltipTotalValue.TextColor3 = Color3.fromRGB(255, 215, 0)
		tooltipDesc.Text = "GREAT boost!"
		tooltipDesc.TextColor3 = Color3.fromRGB(255, 215, 0)
	elseif totalLuckBoost > 1 or badgeLuckBoost > 0 or gamepassLuckBoost > 0 or potionLuckBoost > 0 then
		newColor = Color3.fromRGB(100, 255, 100)
		newBracketColor = Color3.fromRGB(100, 255, 100)
		tooltipTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
		tooltipTotalValue.TextColor3 = Color3.fromRGB(100, 255, 100)
		tooltipDesc.Text = "Better odds"
		tooltipDesc.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		newColor = Color3.fromRGB(200, 200, 200)
		newBracketColor = Color3.fromRGB(200, 200, 200)
		tooltipTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
		tooltipTotalValue.TextColor3 = Color3.fromRGB(200, 200, 200)
		tooltipDesc.Text = "No boost"
		tooltipDesc.TextColor3 = Color3.fromRGB(150, 150, 150)
	end

	luckDecal.ImageColor3 = newColor
	addCornerBrackets(luckContainer, newBracketColor)
	addCornerBrackets(tooltip, newBracketColor)
end

-- Function to create compact glow effect
createLuckGlow = function()
	if not luckContainer or not luckContainer.Parent or not luckDecal then
		return
	end

	local totalLuckBoost = getTotalLuckBoost()
	if totalLuckBoost <= 1 and badgeLuckBoost <= 0 and gamepassLuckBoost <= 0 and potionLuckBoost <= 0 then 
		return 
	end

	local existingGlow = luckContainer:FindFirstChild("LuckGlow")
	if existingGlow then
		existingGlow:Destroy()
	end

	local glowFrame = Instance.new("Frame")
	glowFrame.Name = "LuckGlow"
	glowFrame.Size = UDim2.new(1, 6, 1, 6)
	glowFrame.Position = UDim2.new(0, -3, 0, -3)
	glowFrame.BackgroundColor3 = luckDecal.ImageColor3
	glowFrame.BackgroundTransparency = 0.7
	glowFrame.BorderSizePixel = 0
	glowFrame.Parent = luckContainer
	glowFrame.ZIndex = luckContainer.ZIndex - 1

	spawn(function()
		while glowFrame and glowFrame.Parent and (totalLuckBoost > 1 or badgeLuckBoost > 0 or gamepassLuckBoost > 0 or potionLuckBoost > 0) do
			local tween1 = TweenService:Create(glowFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.5})
			local tween2 = TweenService:Create(glowFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.8})

			tween1:Play()
			tween1.Completed:Wait()
			if not glowFrame or not glowFrame.Parent then break end
			tween2:Play()
			tween2.Completed:Wait()
		end
		if glowFrame then
			glowFrame:Destroy()
		end
	end)
end

-- Function to set up hover events (FIXED - prevents stuck tooltip)
setupHoverEvents = function()
	if not hoverButton or not hoverButton.Parent then 
		return 
	end

	-- Store mouse enter connection
	local mouseEnterConnection = hoverButton.MouseEnter:Connect(function()
		isHovering = true
		print("?? ??? Mouse entered luck GUI")

		if tooltip and tooltip.Parent then
			tooltip.Visible = true
			tooltip.Size = UDim2.new(0, 0, 0, 0)

			local showTween = TweenService:Create(tooltip, 
				TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
				{Size = UDim2.new(0, 180, 0, 140)}
			)
			showTween:Play()
		end

		if luckContainer and luckContainer.Parent then
			local scaleTween = TweenService:Create(luckContainer,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad),
				{Size = UDim2.new(0, 38, 0, 38)}
			)
			scaleTween:Play()
		end
	end)

	-- Store mouse leave connection
	local mouseLeaveConnection = hoverButton.MouseLeave:Connect(function()
		isHovering = false
		print("?? ??? Mouse left luck GUI")

		if tooltip and tooltip.Parent then
			local hideTween = TweenService:Create(tooltip, 
				TweenInfo.new(0.15, Enum.EasingStyle.Quad), 
				{Size = UDim2.new(0, 0, 0, 0)}
			)
			hideTween:Play()

			hideTween.Completed:Connect(function()
				if not isHovering and tooltip and tooltip.Parent then
					tooltip.Visible = false
				end
			end)
		end

		if luckContainer and luckContainer.Parent then
			local scaleTween = TweenService:Create(luckContainer,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad),
				{Size = UDim2.new(0, 35, 0, 35)}
			)
			scaleTween:Play()
		end
	end)

	-- Store connections for cleanup
	table.insert(connections, mouseEnterConnection)
	table.insert(connections, mouseLeaveConnection)
end

-- Function to force hide tooltip (FIXED - prevents stuck tooltip)
local function forceHideTooltip()
	isHovering = false
	if tooltip and tooltip.Parent then
		tooltip.Visible = false
		tooltip.Size = UDim2.new(0, 0, 0, 0)
		print("?? ??? Force hiding tooltip")
	end
	if luckContainer and luckContainer.Parent then
		luckContainer.Size = UDim2.new(0, 35, 0, 35)
	end
end

-- Function to create the GUI
local function createLuckGUI()
	-- Clean up old connections and GUI
	cleanupConnections()
	if gui then
		gui:Destroy()
	end

	-- Force hide any stuck tooltips
	forceHideTooltip()

	gui = Instance.new("ScreenGui")
	gui.Name = "LuckGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	-- Create all GUI elements (same as before, but with proper cleanup)
	luckContainer = Instance.new("Frame")
	luckContainer.Name = "LuckContainer"
	luckContainer.Size = UDim2.new(0, 35, 0, 35)
	luckContainer.Position = UDim2.new(0, 15, 1, -50)
	luckContainer.BackgroundColor3 = Color3.fromRGB(35, 40, 35)
	luckContainer.BackgroundTransparency = 0.2
	luckContainer.BorderSizePixel = 0
	luckContainer.Parent = gui

	addCornerBrackets(luckContainer, Color3.fromRGB(255, 215, 0))

	luckDecal = Instance.new("ImageLabel")
	luckDecal.Name = "LuckDecal"
	luckDecal.Size = UDim2.new(0, 25, 0, 25)
	luckDecal.Position = UDim2.new(0.5, -12.5, 0.5, -12.5)
	luckDecal.BackgroundTransparency = 1
	luckDecal.Image = "http://www.roblox.com/asset/?id=17368084270"
	luckDecal.ImageColor3 = Color3.fromRGB(255, 215, 0)
	luckDecal.ScaleType = Enum.ScaleType.Fit
	luckDecal.Parent = luckContainer

	hoverButton = Instance.new("TextButton")
	hoverButton.Name = "HoverButton"
	hoverButton.Size = UDim2.new(1, 0, 1, 0)
	hoverButton.Position = UDim2.new(0, 0, 0, 0)
	hoverButton.BackgroundTransparency = 1
	hoverButton.Text = ""
	hoverButton.Parent = luckContainer

	tooltip = Instance.new("Frame")
	tooltip.Name = "LuckTooltip"
	tooltip.Size = UDim2.new(0, 180, 0, 140)
	tooltip.Position = UDim2.new(0, 45, 0, -150)
	tooltip.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	tooltip.BackgroundTransparency = 0.1
	tooltip.BorderSizePixel = 0
	tooltip.Visible = false
	tooltip.Parent = luckContainer

	addCornerBrackets(tooltip, Color3.fromRGB(255, 215, 0))

	-- Create all tooltip elements (same as before)
	tooltipTitle = Instance.new("TextLabel")
	tooltipTitle.Name = "TooltipTitle"
	tooltipTitle.Size = UDim2.new(1, -8, 0, 18)
	tooltipTitle.Position = UDim2.new(0, 4, 0, 2)
	tooltipTitle.BackgroundTransparency = 1
	tooltipTitle.Font = Enum.Font.Arcade
	tooltipTitle.Text = "?? LUCK"
	tooltipTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	tooltipTitle.TextStrokeTransparency = 0.3
	tooltipTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	tooltipTitle.TextScaled = true
	tooltipTitle.TextXAlignment = Enum.TextXAlignment.Center
	tooltipTitle.Parent = tooltip

	tooltipRollValue = Instance.new("TextLabel")
	tooltipRollValue.Name = "TooltipRollValue"
	tooltipRollValue.Size = UDim2.new(1, -8, 0, 16)
	tooltipRollValue.Position = UDim2.new(0, 4, 0, 20)
	tooltipRollValue.BackgroundTransparency = 1
	tooltipRollValue.Font = Enum.Font.Arcade
	tooltipRollValue.Text = "Roll: " .. currentLuckBoost .. "x"
	tooltipRollValue.TextColor3 = Color3.fromRGB(255, 255, 255)
	tooltipRollValue.TextStrokeTransparency = 0.3
	tooltipRollValue.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	tooltipRollValue.TextScaled = true
	tooltipRollValue.TextXAlignment = Enum.TextXAlignment.Center
	tooltipRollValue.Parent = tooltip

	tooltipGearValue = Instance.new("TextLabel")
	tooltipGearValue.Name = "TooltipGearValue"
	tooltipGearValue.Size = UDim2.new(1, -8, 0, 16)
	tooltipGearValue.Position = UDim2.new(0, 4, 0, 36)
	tooltipGearValue.BackgroundTransparency = 1
	tooltipGearValue.Font = Enum.Font.Arcade
	tooltipGearValue.Text = "Gears: +" .. badgeLuckBoost .. "%"
	tooltipGearValue.TextColor3 = Color3.fromRGB(100, 255, 100)
	tooltipGearValue.TextStrokeTransparency = 0.3
	tooltipGearValue.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	tooltipGearValue.TextScaled = true
	tooltipGearValue.TextXAlignment = Enum.TextXAlignment.Center
	tooltipGearValue.Parent = tooltip

	tooltipGamepassValue = Instance.new("TextLabel")
	tooltipGamepassValue.Name = "TooltipGamepassValue"
	tooltipGamepassValue.Size = UDim2.new(1, -8, 0, 16)
	tooltipGamepassValue.Position = UDim2.new(0, 4, 0, 52)
	tooltipGamepassValue.BackgroundTransparency = 1
	tooltipGamepassValue.Font = Enum.Font.Arcade
	tooltipGamepassValue.Text = "Gamepass: +" .. gamepassLuckBoost .. "%"
	tooltipGamepassValue.TextColor3 = Color3.fromRGB(255, 215, 0)
	tooltipGamepassValue.TextStrokeTransparency = 0.3
	tooltipGamepassValue.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	tooltipGamepassValue.TextScaled = true
	tooltipGamepassValue.TextXAlignment = Enum.TextXAlignment.Center
	tooltipGamepassValue.Parent = tooltip

	tooltipPotionValue = Instance.new("TextLabel")
	tooltipPotionValue.Name = "TooltipPotionValue"
	tooltipPotionValue.Size = UDim2.new(1, -8, 0, 16)
	tooltipPotionValue.Position = UDim2.new(0, 4, 0, 68)
	tooltipPotionValue.BackgroundTransparency = 1
	tooltipPotionValue.Font = Enum.Font.Arcade
	tooltipPotionValue.Text = "Potion: +" .. potionLuckBoost .. "%"
	tooltipPotionValue.TextColor3 = Color3.fromRGB(255, 100, 255)
	tooltipPotionValue.TextStrokeTransparency = 0.3
	tooltipPotionValue.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	tooltipPotionValue.TextScaled = true
	tooltipPotionValue.TextXAlignment = Enum.TextXAlignment.Center
	tooltipPotionValue.Parent = tooltip

	tooltipTotalValue = Instance.new("TextLabel")
	tooltipTotalValue.Name = "TooltipTotalValue"
	tooltipTotalValue.Size = UDim2.new(1, -8, 0, 16)
	tooltipTotalValue.Position = UDim2.new(0, 4, 0, 84)
	tooltipTotalValue.BackgroundTransparency = 1
	tooltipTotalValue.Font = Enum.Font.Arcade
	tooltipTotalValue.Text = "Total Boost"
	tooltipTotalValue.TextColor3 = Color3.fromRGB(255, 215, 0)
	tooltipTotalValue.TextStrokeTransparency = 0.3
	tooltipTotalValue.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	tooltipTotalValue.TextScaled = true
	tooltipTotalValue.TextXAlignment = Enum.TextXAlignment.Center
	tooltipTotalValue.Parent = tooltip

	tooltipDesc = Instance.new("TextLabel")
	tooltipDesc.Name = "TooltipDesc"
	tooltipDesc.Size = UDim2.new(1, -8, 0, 16)
	tooltipDesc.Position = UDim2.new(0, 4, 0, 100)
	tooltipDesc.BackgroundTransparency = 1
	tooltipDesc.Font = Enum.Font.Arcade
	tooltipDesc.Text = "Better odds"
	tooltipDesc.TextColor3 = Color3.fromRGB(150, 150, 150)
	tooltipDesc.TextStrokeTransparency = 0.5
	tooltipDesc.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	tooltipDesc.TextScaled = true
	tooltipDesc.TextXAlignment = Enum.TextXAlignment.Center
	tooltipDesc.Parent = tooltip

	-- Set up hover events
	setupHoverEvents()

	-- Update display immediately
	updateLuckDisplay()
	createLuckGlow()

	print("?? Hover-Fixed Luck GUI created successfully!")
end

-- Enhanced Global functions with anti-flicker protection
_G.updateLuckBoost = function(newLuckBoost)
	currentLuckBoost = newLuckBoost or 1
	updateLuckDisplay()
	createLuckGlow()
	print("?? Roll luck boost updated to: " .. currentLuckBoost .. "x")
end

_G.updateBadgeLuckBoost = function(newBadgeLuckBoost)
	local newBoost = newBadgeLuckBoost or 0

	if not validateLuckChange(newBoost, gamepassLuckBoost, potionLuckBoost) then
		print("?? ?? Badge luck update blocked by anti-flicker system")
		return
	end

	badgeLuckBoost = newBoost
	updateLastKnownState(badgeLuckBoost, gamepassLuckBoost, potionLuckBoost)
	updateLuckDisplay()
	createLuckGlow()
	print("?? ?? Badge/Gear luck boost updated to: +" .. badgeLuckBoost.. "%")
end

_G.updateGamepassLuckBoost = function(newGamepassLuckBoost)
	local newBoost = newGamepassLuckBoost or 0

	if not validateLuckChange(badgeLuckBoost, newBoost, potionLuckBoost) then
		print("?? ?? Gamepass luck update blocked by anti-flicker system")
		return
	end

	gamepassLuckBoost = newBoost
	updateLastKnownState(badgeLuckBoost, gamepassLuckBoost, potionLuckBoost)
	updateLuckDisplay()
	createLuckGlow()
	print("?? ?? Gamepass luck boost updated to: +" .. gamepassLuckBoost .. "%")
end

_G.updatePotionLuckBoost = function(newPotionLuckBoost)
	local newBoost = newPotionLuckBoost or 0

	if newBoost == 0 or validateLuckChange(badgeLuckBoost, gamepassLuckBoost, newBoost) then
		potionLuckBoost = newBoost
		updateLastKnownState(badgeLuckBoost, gamepassLuckBoost, potionLuckBoost)
		updateLuckDisplay()
		createLuckGlow()
		print("?? ?? Potion luck boost updated to: +" .. potionLuckBoost .. "%")
	else
		print("?? ?? Potion luck update blocked by anti-flicker system")
	end
end

_G.getCurrentLuckBoost = function()
	return getTotalLuckBoost()
end

_G.getCurrentBadgeLuckBoost = function()
	return badgeLuckBoost
end

_G.getCurrentGamepassLuckBoost = function()
	return gamepassLuckBoost
end

_G.getCurrentPotionLuckBoost = function()
	return potionLuckBoost
end

-- Enhanced force refresh with gamepass checking
_G.forceRefreshLuck = function()
	print("?? ?? Forcing luck refresh...")
	updateLastKnownState(0, 0, 0)

	-- Refresh gamepass luck
	refreshGamepassLuck()

	spawn(function()
		wait(1)
		-- Also check for your existing gamepass system if it exists
		local GamepassRemotes = ReplicatedStorage:FindFirstChild("GamepassRemotes")
		if GamepassRemotes then
			local CheckGamepassOwnership = GamepassRemotes:FindFirstChild("CheckGamepassOwnership")
			if CheckGamepassOwnership then
				local success, result = pcall(function()
					local totalGamepassBoost = 0

					-- Add your existing gamepass IDs here
					if CheckGamepassOwnership:InvokeServer(1376797718) then
						totalGamepassBoost = totalGamepassBoost + 100
					end

					if CheckGamepassOwnership:InvokeServer(1378491109) then
						totalGamepassBoost = totalGamepassBoost + 25
					end

					return totalGamepassBoost
				end)

				if success then
					gamepassLuckBoost = result
					updateLastKnownState(badgeLuckBoost, gamepassLuckBoost, potionLuckBoost)
					updateLuckDisplay()
					createLuckGlow()
					print("?? ?? Forced gamepass luck refresh: +" .. result .. "%")
				end
			end
		end
	end)
end

-- DEATH-PROOF: Handle character respawning (ENHANCED with tooltip fix)
local function onCharacterAdded(character)
	print("?? Character respawned for " .. player.Name .. ", ensuring Luck GUI persists...")

	wait(2)

	-- Force hide any stuck tooltips
	forceHideTooltip()

	if not gui or not gui.Parent then
		createLuckGUI()
	end

	spawn(function()
		wait(3)
		_G.forceRefreshLuck()
		-- Also refresh gamepass luck on respawn
		refreshGamepassLuck()
	end)

	print("?? Luck GUI restored after respawn!")
end

-- Connect character events
if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Also handle character removing to force hide tooltip
player.CharacterRemoving:Connect(function(character)
	print("?? Character removing, force hiding tooltip...")
	forceHideTooltip()
end)

-- Regular gamepass check loop
spawn(function()
	while wait(10) do -- Check every 10 seconds
		refreshGamepassLuck()
	end
end)

-- Rest of the script remains the same (monitoring loops, etc.)
spawn(function()
	while true do
		wait(0.5)

		local globalLuck = _G.luckBoostMultiplier or 1
		local isLuckActive = _G.luckBoostActive or false

		local newLuck
		if isLuckActive and globalLuck > 1 then
			newLuck = globalLuck
		else
			newLuck = 1
		end

		if newLuck ~= currentLuckBoost then
			currentLuckBoost = newLuck
			updateLuckDisplay()
			if newLuck > 1 or badgeLuckBoost > 0 or gamepassLuckBoost > 0 or potionLuckBoost > 0 then
				createLuckGlow()
			end
		end
	end
end)

spawn(function()
	local luckBoostEvent = ReplicatedStorage:FindFirstChild("LuckBoostEvent")
	if not luckBoostEvent then
		luckBoostEvent = ReplicatedStorage:WaitForChild("LuckBoostEvent", 30)
	end

	if luckBoostEvent then
		luckBoostEvent.OnClientEvent:Connect(function(luckBoost, rollSpeedPenalty)
			local safeBoost = tonumber(luckBoost) or 0
			print("?? ?? Received gear luck boost from server: +" .. safeBoost .. "%")
			_G.updateBadgeLuckBoost(safeBoost)
		end)
	else
		warn("?? LuckBoostEvent not found in ReplicatedStorage")
	end
end)

spawn(function()
	wait(3)

	-- Check for existing gamepass system
	local GamepassRemotes = ReplicatedStorage:FindFirstChild("GamepassRemotes")
	if GamepassRemotes then
		local CheckGamepassOwnership = GamepassRemotes:FindFirstChild("CheckGamepassOwnership")
		if CheckGamepassOwnership then
			local success, result = pcall(function()
				local totalGamepassBoost = 0

				-- Add your existing gamepass IDs here
				if CheckGamepassOwnership:InvokeServer(1376797718) then
					totalGamepassBoost = totalGamepassBoost + 100
				end

				if CheckGamepassOwnership:InvokeServer(1378491109) then
					totalGamepassBoost = totalGamepassBoost + 25
				end

				return totalGamepassBoost
			end)

			if success then
				print("?? ?? Initial gamepass luck check: +" .. result .. "%")
				_G.updateGamepassLuckBoost(result)
			end
		end
	else
		-- Use the new direct gamepass checking if no existing system
		refreshGamepassLuck()
	end
end)

spawn(function()
	local potionLuckUpdateEvent = ReplicatedStorage:FindFirstChild("PotionLuckUpdateEvent")
	if not potionLuckUpdateEvent then
		potionLuckUpdateEvent = ReplicatedStorage:WaitForChild("PotionLuckUpdateEvent", 30)
	end

	if potionLuckUpdateEvent then
		potionLuckUpdateEvent.OnClientEvent:Connect(function(luckBoost)
			local safeBoost = tonumber(luckBoost) or 0
			print("?? ?? Received potion luck boost from server: +" .. safeBoost .. "%")
			_G.updatePotionLuckBoost(safeBoost)
		end)
	else
		warn("?? PotionLuckUpdateEvent not found in ReplicatedStorage")
	end
end)

createLuckGUI()

print("?? ?? Hover-Fixed Anti-Flicker Death-Proof Enhanced Luck GUI loaded for " .. player.Name .. "!")
print("?? ?? Anti-flicker protection enabled")
print("?? ??? Tooltip stuck bug fixed")
print("?? ?? Gamepass integration enabled")
print("?? ?? Use _G.forceRefreshLuck() to force refresh if needed")