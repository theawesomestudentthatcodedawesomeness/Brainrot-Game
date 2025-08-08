-- Place this LocalScript in StarterGui
-- Creates a bottom-center bar with three clickable buttons with toggle functionality and roll counter
-- Enhanced with Quick Roll gamepass integration - FIXED STATE PERSISTENCE

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

if playerGui:FindFirstChild("BottomBarGui") then
	playerGui.BottomBarGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "BottomBarGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- GAMEPASS CONFIGURATION
local QUICK_ROLL_GAMEPASS_ID = 1374405825 -- Your actual Quick Roll gamepass ID

-- Toggle states and cooldowns
local autoRollEnabled = false
local quickRollEnabled = false
local autoRollCooldown = false
local quickRollCooldown = false
local rollButtonCooldown = false
local rollCount = 1
local autoRollRunning = false

-- Gamepass ownership tracking
local hasQuickRollGamepass = false
local gamepassCheckInProgress = false
local lastGamepassCheck = 0

local luckBoostMultiplier = 3

local container = Instance.new("Frame")
container.Name = "ButtonBar"
container.Size = UDim2.new(0, 750, 0, 90)
container.Position = UDim2.new(0.5, -375, 1, -105)
container.BackgroundTransparency = 1
container.Parent = gui

local function addCornerBrackets(parent, color)
	local thickness = 2
	local length = 20
	local tl1 = Instance.new("Frame")
	tl1.Size = UDim2.new(0, length, 0, thickness)
	tl1.Position = UDim2.new(0, 0, 0, 0)
	tl1.BackgroundColor3 = color
	tl1.BorderSizePixel = 0
	tl1.Parent = parent
	local tl2 = Instance.new("Frame")
	tl2.Size = UDim2.new(0, thickness, 0, length)
	tl2.Position = UDim2.new(0, 0, 0, 0)
	tl2.BackgroundColor3 = color
	tl2.BorderSizePixel = 0
	tl2.Parent = parent
	local tr1 = Instance.new("Frame")
	tr1.Size = UDim2.new(0, length, 0, thickness)
	tr1.Position = UDim2.new(1, -length, 0, 0)
	tr1.BackgroundColor3 = color
	tr1.BorderSizePixel = 0
	tr1.Parent = parent
	local tr2 = Instance.new("Frame")
	tr2.Size = UDim2.new(0, thickness, 0, length)
	tr2.Position = UDim2.new(1, -thickness, 0, 0)
	tr2.BackgroundColor3 = color
	tr2.BorderSizePixel = 0
	tr2.Parent = parent
	local bl1 = Instance.new("Frame")
	bl1.Size = UDim2.new(0, length, 0, thickness)
	bl1.Position = UDim2.new(0, 0, 1, -thickness)
	bl1.BackgroundColor3 = color
	bl1.BorderSizePixel = 0
	bl1.Parent = parent
	local bl2 = Instance.new("Frame")
	bl2.Size = UDim2.new(0, thickness, 0, length)
	bl2.Position = UDim2.new(0, 0, 1, -length)
	bl2.BackgroundColor3 = color
	bl2.BorderSizePixel = 0
	bl2.Parent = parent
	local br1 = Instance.new("Frame")
	br1.Size = UDim2.new(0, length, 0, thickness)
	br1.Position = UDim2.new(1, -length, 1, -thickness)
	br1.BackgroundColor3 = color
	br1.BorderSizePixel = 0
	br1.Parent = parent
	local br2 = Instance.new("Frame")
	br2.Size = UDim2.new(0, thickness, 0, length)
	br2.Position = UDim2.new(1, -thickness, 1, -length)
	br2.BackgroundColor3 = color
	br2.BorderSizePixel = 0
	br2.Parent = parent
end

local function createButton(parent, size, pos, mainText, subText, isMainButton)
	local btn = Instance.new("TextButton")
	btn.Size = size
	btn.Position = pos
	btn.BackgroundColor3 = Color3.fromRGB(35, 40, 35)
	btn.BackgroundTransparency = 0.2
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.Parent = parent
	btn.AutoButtonColor = true
	addCornerBrackets(btn, Color3.fromRGB(200, 200, 200))
	local mainLabel = Instance.new("TextLabel")
	mainLabel.Name = "MainLabel"
	mainLabel.BackgroundTransparency = 1
	mainLabel.Size = UDim2.new(0.9, 0, isMainButton and 0.55 or 0.45, 0)
	mainLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
	mainLabel.Font = Enum.Font.Arcade
	mainLabel.Text = mainText
	mainLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	mainLabel.TextStrokeTransparency = 0.3
	mainLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	mainLabel.TextScaled = true
	mainLabel.Parent = btn
	if subText and subText ~= "" then
		local subLabel = Instance.new("TextLabel")
		subLabel.Name = "SubLabel"
		subLabel.BackgroundTransparency = 1
		subLabel.Size = UDim2.new(0.9, 0, 0.25, 0)
		subLabel.Position = UDim2.new(0.05, 0, isMainButton and 0.65 or 0.55, 0)
		subLabel.Font = Enum.Font.Arcade
		subLabel.Text = subText
		subLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
		subLabel.TextStrokeTransparency = 0.5
		subLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		subLabel.TextScaled = true
		subLabel.Parent = btn
	end
	return btn
end

-- DECLARE QUICKBTN VARIABLE
local quickBtn

-- DEFINE updateQuickButtonAppearance FIRST
local function updateQuickButtonAppearance()
	if not quickBtn then return end

	local mainLabel = quickBtn:FindFirstChild("MainLabel")
	local subLabel = quickBtn:FindFirstChild("SubLabel")

	if not mainLabel or not subLabel then return end

	print("?? Updating Quick Roll button - hasGamepass: " .. tostring(hasQuickRollGamepass) .. ", enabled: " .. tostring(quickRollEnabled))

	if hasQuickRollGamepass then
		if quickRollEnabled then
			mainLabel.Text = "Quick roll : ON"
			mainLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
			subLabel.Text = "*Faster rolling!"
			subLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
		else
			mainLabel.Text = "Quick roll : OFF"
			mainLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			subLabel.Text = "*Gamepass owned"
			subLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
		end
	else
		mainLabel.Text = "Quick roll : LOCKED"
		mainLabel.TextColor3 = Color3.fromRGB(200, 100, 100)
		subLabel.Text = "*Click to buy!"
		subLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
		-- CRITICAL FIX: Only disable if we're absolutely sure they don't own it
		if not gamepassCheckInProgress then
			quickRollEnabled = false
		end
	end
end

-- ENHANCED GAMEPASS CHECK WITH BETTER STATE MANAGEMENT
local function checkQuickRollOwnership(forceCheck)
	local currentTime = tick()

	-- Only allow checks every 2 seconds unless forced
	if not forceCheck and (gamepassCheckInProgress or (currentTime - lastGamepassCheck) < 2) then
		print("?? Gamepass check skipped - too recent or in progress")
		return hasQuickRollGamepass
	end

	gamepassCheckInProgress = true
	lastGamepassCheck = currentTime

	print("?? Checking gamepass ownership... (forced: " .. tostring(forceCheck or false) .. ")")

	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, QUICK_ROLL_GAMEPASS_ID)
	end)

	if success then
		local previousState = hasQuickRollGamepass
		hasQuickRollGamepass = owns

		print("?? Quick Roll gamepass check result: " .. (owns and "OWNED" or "NOT OWNED"))

		-- CRITICAL FIX: If they own the gamepass and quickRoll was disabled, re-enable it
		if hasQuickRollGamepass and not quickRollEnabled and previousState ~= hasQuickRollGamepass then
			print("?? Re-enabling Quick Roll since gamepass is owned")
			quickRollEnabled = true
		end

		-- If ownership changed, update UI immediately
		if previousState ~= hasQuickRollGamepass then
			print("?? Gamepass ownership changed from " .. tostring(previousState) .. " to " .. tostring(hasQuickRollGamepass))
			updateQuickButtonAppearance()
		end
	else
		warn("?? Failed to check Quick Roll gamepass ownership")
	end

	gamepassCheckInProgress = false
	return hasQuickRollGamepass
end

local function promptQuickRollPurchase()
	print("?? Prompting Quick Roll gamepass purchase...")

	local success, error = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, QUICK_ROLL_GAMEPASS_ID)
	end)

	if not success then
		warn("?? Failed to prompt gamepass purchase: " .. tostring(error))
	end
end

-- ENHANCED PURCHASE DETECTION
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(playerWho, gamepassId, wasPurchased)
	if playerWho == player and gamepassId == QUICK_ROLL_GAMEPASS_ID then
		print("?? Purchase prompt finished - wasPurchased: " .. tostring(wasPurchased))

		if wasPurchased then
			print("?? Quick Roll gamepass purchased successfully!")

			-- IMMEDIATELY update ownership status
			hasQuickRollGamepass = true
			quickRollEnabled = true -- CRITICAL: Enable quick roll immediately

			-- Show success message
			local mainLabel = quickBtn:FindFirstChild("MainLabel")
			local subLabel = quickBtn:FindFirstChild("SubLabel")

			if mainLabel and subLabel then
				mainLabel.Text = "PURCHASED!"
				mainLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
				subLabel.Text = "*Now enabled!"
				subLabel.TextColor3 = Color3.fromRGB(120, 255, 120)

				-- Update appearance after showing success message
				spawn(function()
					wait(3)
					updateQuickButtonAppearance()
				end)
			end

		else
			print("? Quick Roll gamepass purchase cancelled")
			updateQuickButtonAppearance()
		end
	end
end)

-- CREATE BUTTONS
local autoBtn = createButton(
	container,
	UDim2.new(0, 220, 0, 70),
	UDim2.new(0, 0, 0, 10),
	"Auto roll : OFF",
	"*Group join required",
	false
)

local rollBtn = createButton(
	container,
	UDim2.new(0, 260, 0, 90),
	UDim2.new(0, 245, 0, 0),
	"Roll",
	"1/10",
	true
)

-- Create quickBtn with initial placeholder text
quickBtn = createButton(
	container,
	UDim2.new(0, 220, 0, 70),
	UDim2.new(0, 530, 0, 10),
	"Quick roll : CHECKING",
	"*Loading...",
	false
)

local function showRollCooldown(duration)
	local mainLabel = rollBtn:FindFirstChild("MainLabel")
	if not mainLabel then return end
	local originalText = mainLabel.Text
	local startTime = tick()
	spawn(function()
		while tick() - startTime < duration and rollButtonCooldown do
			local remaining = math.ceil(duration - (tick() - startTime))
			mainLabel.Text = "Cooldown: " .. remaining .. "s"
			mainLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			wait(0.1)
		end
		if not rollButtonCooldown then
			mainLabel.Text = originalText
			mainLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)
end

-- FIXED: Enhanced performRoll with state preservation
local function performRoll(isAutoRoll, isQuick)
	if _G.canRoll and not _G.canRoll() then
		if not isAutoRoll then
			print("Cannot roll - already rolling!")
		end
		return false
	end

	-- CRITICAL: Store current quick roll state before rolling
	local quickRollWasEnabled = quickRollEnabled
	local gamepassWasOwned = hasQuickRollGamepass

	print("?? Starting roll - Quick Roll enabled: " .. tostring(quickRollWasEnabled) .. ", Gamepass owned: " .. tostring(gamepassWasOwned))

	local subLabel = rollBtn:FindFirstChild("SubLabel")
	local mainLabel = rollBtn:FindFirstChild("MainLabel")
	if not isAutoRoll or not autoRollRunning then
		rollButtonCooldown = true
		if not quickRollEnabled then
			showRollCooldown(2)
		else
			showRollCooldown(0.5)
		end
	end

	local isLuckyRoll = (rollCount == 10)
	if isLuckyRoll then
		_G.luckBoostActive = true
		_G.luckBoostMultiplier = luckBoostMultiplier
		if subLabel then
			subLabel.Text = "? LUCKY ROLL!"
			subLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		end
		print("? LUCKY 10/10 ROLL! This roll has " .. luckBoostMultiplier .. "x better odds for rare items!")
	end

	wait(0.1)
	if _G.createRollPopup then
		_G.createRollPopup(isQuick or false)
	else
		local rollEvent = ReplicatedStorage:FindFirstChild("RollEvent")
		if not rollEvent then
			rollEvent = Instance.new("BindableEvent")
			rollEvent.Name = "RollEvent"
			rollEvent.Parent = ReplicatedStorage
		end
		rollEvent:Fire()
	end

	if rollCount == 10 then
		rollCount = 1
		if subLabel then
			subLabel.Text = "1/10"
			subLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
		end
		-- Reset luck boost after lucky roll is spent
		_G.luckBoostActive = false
		_G.luckBoostMultiplier = 1
	else
		rollCount = rollCount + 1
		if subLabel then
			subLabel.Text = rollCount .. "/10"
		end
	end

	-- CRITICAL FIX: Preserve quick roll state after rolling
	spawn(function()
		local cooldownTime = quickRollWasEnabled and 0.5 or 2
		wait(cooldownTime)

		-- Restore the quick roll state if it was changed
		if gamepassWasOwned and not hasQuickRollGamepass then
			print("?? Restoring gamepass ownership after roll")
			hasQuickRollGamepass = gamepassWasOwned
		end

		if gamepassWasOwned and quickRollWasEnabled and not quickRollEnabled then
			print("?? Restoring Quick Roll enabled state after roll")
			quickRollEnabled = quickRollWasEnabled
			updateQuickButtonAppearance()
		end

		rollButtonCooldown = false
		if mainLabel and mainLabel.Text:find("Cooldown") then
			mainLabel.Text = "Roll"
			mainLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
		if not isAutoRoll then
			print("Roll button ready!")
		end
	end)
	return true
end

local function startAutoRoll()
	if autoRollRunning then return end
	autoRollRunning = true
	spawn(function()
		while autoRollEnabled and autoRollRunning do
			if not rollButtonCooldown then
				local success = performRoll(true, quickRollEnabled)
				if success then
					local waitTime = quickRollEnabled and 1.5 or 4
					wait(waitTime)
				else
					wait(1)
				end
			else
				wait(0.5)
			end
		end
		autoRollRunning = false
		print("Auto roll stopped")
	end)
end

-- AUTO ROLL BUTTON
autoBtn.MouseButton1Click:Connect(function()
	if autoRollCooldown then return end
	autoRollCooldown = true
	autoRollEnabled = not autoRollEnabled
	local mainLabel = autoBtn:FindFirstChild("MainLabel")
	if autoRollEnabled then
		mainLabel.Text = "Auto roll : ON"
		mainLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
		print("Auto roll enabled")
		startAutoRoll()
	else
		mainLabel.Text = "Auto roll : OFF"
		mainLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		print("Auto roll disabled")
		autoRollRunning = false
	end
	spawn(function()
		task.wait(2)
		autoRollCooldown = false
	end)
end)

-- ENHANCED QUICK ROLL BUTTON WITH STATE PROTECTION
quickBtn.MouseButton1Click:Connect(function()
	if quickRollCooldown then return end
	quickRollCooldown = true

	print("??? Quick Roll button clicked - Current state: hasGamepass=" .. tostring(hasQuickRollGamepass) .. ", enabled=" .. tostring(quickRollEnabled))

	-- If we already know they have the gamepass, don't check again
	if hasQuickRollGamepass then
		-- Player owns gamepass - toggle quick roll
		quickRollEnabled = not quickRollEnabled

		print("?? Toggling Quick Roll: " .. tostring(quickRollEnabled))
		updateQuickButtonAppearance()

		if quickRollEnabled then
			print("?? Quick roll enabled - Faster rolling!")
		else
			print("?? Quick roll disabled")
		end
	else
		-- Double-check gamepass ownership before prompting purchase
		print("?? Double-checking gamepass ownership before purchase prompt...")
		local ownsGamepass = checkQuickRollOwnership(true) -- Force check

		if ownsGamepass then
			-- They actually do own it, enable quick roll
			quickRollEnabled = true
			updateQuickButtonAppearance()
			print("?? Quick roll enabled - Gamepass verified!")
		else
			-- Player doesn't own gamepass - prompt purchase
			print("?? Player doesn't own Quick Roll gamepass - prompting purchase")

			local mainLabel = quickBtn:FindFirstChild("MainLabel")
			local subLabel = quickBtn:FindFirstChild("SubLabel")

			-- Show "opening shop" feedback
			if mainLabel and subLabel then
				mainLabel.Text = "Opening shop..."
				mainLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
				subLabel.Text = "*Quick Roll - 50 R$"
				subLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
			end

			-- Prompt purchase
			promptQuickRollPurchase()

			-- Reset appearance after a moment
			spawn(function()
				wait(3)
				updateQuickButtonAppearance()
			end)
		end
	end

	spawn(function()
		task.wait(2)
		quickRollCooldown = false
	end)
end)

-- MAIN ROLL BUTTON
rollBtn.MouseButton1Click:Connect(function()
	if rollButtonCooldown then
		print("Roll button on cooldown!")
		return
	end
	if autoRollEnabled and not autoRollRunning then
		print("Starting auto roll sequence...")
		startAutoRoll()
	else
		-- Pass quickRollEnabled as isQuick to performRoll
		performRoll(false, quickRollEnabled)
	end
end)

-- INITIALIZE GAMEPASS CHECK
spawn(function()
	wait(3) -- Wait for game to fully load
	print("?? Initial gamepass ownership check...")
	checkQuickRollOwnership(true) -- Force initial check
	updateQuickButtonAppearance()
end)

-- REDUCED FREQUENCY PERIODIC CHECK
spawn(function()
	while wait(60) do
		-- Only do periodic checks if we don't think they own it
		if not hasQuickRollGamepass then
			print("?? Periodic gamepass check (player doesn't own)")
			checkQuickRollOwnership(false)
		end
	end
end)

print("?? Enhanced Roll System with STATE PERSISTENCE FIXES loaded!")
print("?? Quick Roll Gamepass ID: " .. QUICK_ROLL_GAMEPASS_ID)
print("?? Critical fixes applied:")
print("  - State preservation after rolling")
print("  - Protected against unwanted resets")
print("  - Better gamepass ownership persistence")