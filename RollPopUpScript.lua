-- LocalScript: StarterGui>RollGui>RollPopUpScript
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local BrainrotDefinitions = require(ReplicatedStorage:WaitForChild("BrainrotDefinitions"))
local brainrotItems = BrainrotDefinitions.List
local BrainrotSounds = ReplicatedStorage:WaitForChild("BrainrotSounds")

-- Destroy existing GUI
if playerGui:FindFirstChild("RollPopupGui") then
	playerGui.RollPopupGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "RollPopupGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- State Management
local isRolling = false
local inventoryRemotes = nil
local currentRollSound = nil

-- Wait for inventory system
local function waitForInventorySystem()
	local maxWait = 10
	local waited = 0
	while not inventoryRemotes and waited < maxWait do
		inventoryRemotes = ReplicatedStorage:FindFirstChild("InventoryRemotes")
		if not inventoryRemotes then
			wait(0.5)
			waited = waited + 0.5
		end
	end
	return inventoryRemotes ~= nil
end

spawn(function()
	local success = waitForInventorySystem()
	if success then
		print("? Roll Popup: Inventory system connected")
	else
		warn("? Roll Popup: Inventory system not found")
	end
end)

-- Enhanced Inventory Integration
local function addToInventory(itemName)
	if inventoryRemotes then
		local addItemEvent = inventoryRemotes:FindFirstChild("AddBrainrotItem")
		if addItemEvent then
			local success = pcall(function()
				addItemEvent:FireServer(itemName)
			end)
			if success then
				print("? Roll Popup: Added " .. itemName .. " to inventory")
				return true
			else
				warn("? Roll Popup: Failed to add " .. itemName .. " to inventory")
			end
		else
			warn("? Roll Popup: AddBrainrotItem event not found")
		end
	else
		warn("? Roll Popup: Inventory remotes not available")
	end
	return false
end

-- Settings Integration
local BrainrotSettingsRemotes = ReplicatedStorage:WaitForChild("BrainrotSettingsRemotes")
local skipBrainrotsValue = 0
local autoSaveValue = 0
local skipList = {}
local saveList = {}

local function fetchSettings()
	local success, settings = pcall(function()
		return BrainrotSettingsRemotes.RequestSettings:InvokeServer()
	end)

	if success and settings then
		skipBrainrotsValue = tonumber(settings.SkipBrainrots or 0)
		autoSaveValue = tonumber(settings.AutoSave or 0)
		skipList = settings.SkipList or {}
		saveList = settings.SaveList or {}
		print("? Roll Popup: Settings loaded")
	else
		warn("? Roll Popup: Failed to fetch settings")
	end
end

-- Listen for setting updates
if BrainrotSettingsRemotes:FindFirstChild("UpdateSetting") then
	BrainrotSettingsRemotes.UpdateSetting.OnClientEvent:Connect(function(key, value)
		if key == "SkipBrainrots" then
			skipBrainrotsValue = tonumber(value) or 0
		elseif key == "AutoSave" then
			autoSaveValue = tonumber(value) or 0
		elseif key == "SkipList" then
			skipList = value or {}
		elseif key == "SaveList" then
			saveList = value or {}
		end
		print("?? Roll Popup: Setting updated - " .. key)
	end)
end

-- FIXED: Simplified Corner Brackets (was causing visibility issues)
local function addCornerBrackets(parent, color)
	color = color or Color3.fromRGB(255, 255, 255)
	local thickness = 2
	local length = 20

	-- Top-left corner
	local tl1 = Instance.new("Frame")
	tl1.Size = UDim2.new(0, length, 0, thickness)
	tl1.Position = UDim2.new(0, 0, 0, 0)
	tl1.BackgroundColor3 = color
	tl1.BorderSizePixel = 0
	tl1.ZIndex = parent.ZIndex + 1
	tl1.Parent = parent

	local tl2 = Instance.new("Frame")
	tl2.Size = UDim2.new(0, thickness, 0, length)
	tl2.Position = UDim2.new(0, 0, 0, 0)
	tl2.BackgroundColor3 = color
	tl2.BorderSizePixel = 0
	tl2.ZIndex = parent.ZIndex + 1
	tl2.Parent = parent

	-- Top-right corner
	local tr1 = Instance.new("Frame")
	tr1.Size = UDim2.new(0, length, 0, thickness)
	tr1.Position = UDim2.new(1, -length, 0, 0)
	tr1.BackgroundColor3 = color
	tr1.BorderSizePixel = 0
	tr1.ZIndex = parent.ZIndex + 1
	tr1.Parent = parent

	local tr2 = Instance.new("Frame")
	tr2.Size = UDim2.new(0, thickness, 0, length)
	tr2.Position = UDim2.new(1, -thickness, 0, 0)
	tr2.BackgroundColor3 = color
	tr2.BorderSizePixel = 0
	tr2.ZIndex = parent.ZIndex + 1
	tr2.Parent = parent

	-- Bottom-left corner
	local bl1 = Instance.new("Frame")
	bl1.Size = UDim2.new(0, length, 0, thickness)
	bl1.Position = UDim2.new(0, 0, 1, -thickness)
	bl1.BackgroundColor3 = color
	bl1.BorderSizePixel = 0
	bl1.ZIndex = parent.ZIndex + 1
	bl1.Parent = parent

	local bl2 = Instance.new("Frame")
	bl2.Size = UDim2.new(0, thickness, 0, length)
	bl2.Position = UDim2.new(0, 0, 1, -length)
	bl2.BackgroundColor3 = color
	bl2.BorderSizePixel = 0
	bl2.ZIndex = parent.ZIndex + 1
	bl2.Parent = parent

	-- Bottom-right corner
	local br1 = Instance.new("Frame")
	br1.Size = UDim2.new(0, length, 0, thickness)
	br1.Position = UDim2.new(1, -length, 1, -thickness)
	br1.BackgroundColor3 = color
	br1.BorderSizePixel = 0
	br1.ZIndex = parent.ZIndex + 1
	br1.Parent = parent

	local br2 = Instance.new("Frame")
	br2.Size = UDim2.new(0, thickness, 0, length)
	br2.Position = UDim2.new(1, -thickness, 1, -length)
	br2.BackgroundColor3 = color
	br2.BorderSizePixel = 0
	br2.ZIndex = parent.ZIndex + 1
	br2.Parent = parent
end

-- Enhanced Sound System
local function getSFXVolume()
	return (_G.BrainrotSFXVolume or 1) * 2
end

local function playSuspenseSound()
	local suspenseSoundTemplate = BrainrotSounds:FindFirstChild("RollSuspenseSound")
	if suspenseSoundTemplate then
		local sound = suspenseSoundTemplate:Clone()
		sound.Name = "ActiveRollSound"
		sound.Parent = workspace
		sound.Looped = true
		sound.Volume = getSFXVolume()
		sound:Play()
		currentRollSound = sound
		print("?? Roll Popup: Playing suspense sound")
		return sound
	else
		warn("? Roll Popup: Suspense sound not found")
	end
	return nil
end

local function stopSuspenseSound()
	if currentRollSound and currentRollSound:IsA("Sound") then
		currentRollSound:Stop()
		currentRollSound:Destroy()
		currentRollSound = nil
		print("?? Roll Popup: Stopped suspense sound")
	end

	-- Cleanup any other roll sounds
	for _, sound in ipairs(workspace:GetChildren()) do
		if sound:IsA("Sound") and sound.Name == "ActiveRollSound" then
			sound:Stop()
			sound:Destroy()
		end
	end
end

local function playBrainrotResultSound(brainrotName)
	local resultSoundTemplate = BrainrotSounds:FindFirstChild(brainrotName)
	if resultSoundTemplate and resultSoundTemplate:IsA("Sound") then
		local sound = resultSoundTemplate:Clone()
		sound.Name = "RollResultSound"
		sound.Parent = workspace
		sound.Looped = false
		sound.Volume = getSFXVolume()
		sound:Play()
		Debris:AddItem(sound, sound.TimeLength + 1)
		print("?? Roll Popup: Playing result sound for " .. brainrotName)
	else
		print("?? Roll Popup: No sound found for " .. brainrotName)
	end
end

local function playGuiClickSound()
	local clickSoundTemplate = BrainrotSounds:FindFirstChild("GuiClickSound")
	if clickSoundTemplate then
		local sound = clickSoundTemplate:Clone()
		sound.Volume = getSFXVolume()
		sound.Parent = workspace
		sound:Play()
		Debris:AddItem(sound, sound.TimeLength + 0.1)
	end
end

-- FIXED: Enhanced Final Popup with Proper Visibility
local function showFinalPopup(rolledItem, autoAction)
	stopSuspenseSound()
	playBrainrotResultSound(rolledItem.name)

	local existingPopup = gui:FindFirstChild("RollPopup")
	if existingPopup then
		existingPopup:Destroy()
	end

	-- Main popup frame with high ZIndex
	local popup = Instance.new("Frame")
	popup.Name = "RollPopup"
	popup.Size = UDim2.new(0, 500, 0, 300)
	popup.Position = UDim2.new(0.5, -250, 0.5, -150)
	popup.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	popup.BackgroundTransparency = 0
	popup.BorderSizePixel = 0
	popup.ZIndex = 10
	popup.Visible = true
	popup.Parent = gui

	-- Add corner brackets
	addCornerBrackets(popup, rolledItem.color or Color3.fromRGB(200, 200, 200))

	-- Item name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ItemName"
	nameLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Arcade
	nameLabel.Text = rolledItem.name
	nameLabel.TextColor3 = rolledItem.color
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.ZIndex = popup.ZIndex + 1
	nameLabel.Visible = true
	nameLabel.Parent = popup

	-- Odds label
	local oddsLabel = Instance.new("TextLabel")
	oddsLabel.Name = "ItemOdds"
	oddsLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	oddsLabel.Position = UDim2.new(0.05, 0, 0.45, 0)
	oddsLabel.BackgroundTransparency = 1
	oddsLabel.Font = Enum.Font.Arcade
	oddsLabel.Text = "1 in " .. rolledItem.odds
	oddsLabel.TextColor3 = rolledItem.color
	oddsLabel.TextStrokeTransparency = 0.5
	oddsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	oddsLabel.TextScaled = true
	oddsLabel.ZIndex = popup.ZIndex + 1
	oddsLabel.Visible = true
	oddsLabel.Parent = popup

	-- Rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "ItemRarity"
	rarityLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	rarityLabel.Position = UDim2.new(0.05, 0, 0.6, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.Arcade
	rarityLabel.Text = rolledItem.rarity:upper()
	rarityLabel.TextColor3 = rolledItem.color
	rarityLabel.TextStrokeTransparency = 0.5
	rarityLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rarityLabel.TextScaled = true
	rarityLabel.ZIndex = popup.ZIndex + 1
	rarityLabel.Visible = true
	rarityLabel.Parent = popup

	-- Button container
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Size = UDim2.new(0.9, 0, 0.15, 0)
	buttonContainer.Position = UDim2.new(0.05, 0, 0.8, 0)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.ZIndex = popup.ZIndex + 1
	buttonContainer.Visible = true
	buttonContainer.Parent = popup

	-- Equip button
	local equipBtn = Instance.new("TextButton")
	equipBtn.Name = "EquipButton"
	equipBtn.Size = UDim2.new(0.45, 0, 1, 0)
	equipBtn.Position = UDim2.new(0, 0, 0, 0)
	equipBtn.BackgroundColor3 = Color3.fromRGB(25, 60, 25)
	equipBtn.BackgroundTransparency = 0
	equipBtn.BorderSizePixel = 0
	equipBtn.Font = Enum.Font.Arcade
	equipBtn.Text = "Equip"
	equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	equipBtn.TextStrokeTransparency = 0.3
	equipBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	equipBtn.TextScaled = true
	equipBtn.ZIndex = buttonContainer.ZIndex + 1
	equipBtn.Visible = true
	equipBtn.Parent = buttonContainer

	addCornerBrackets(equipBtn, Color3.fromRGB(100, 200, 100))

	-- Skip button
	local skipBtn = Instance.new("TextButton")
	skipBtn.Name = "SkipButton"
	skipBtn.Size = UDim2.new(0.45, 0, 1, 0)
	skipBtn.Position = UDim2.new(0.55, 0, 0, 0)
	skipBtn.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
	skipBtn.BackgroundTransparency = 0
	skipBtn.BorderSizePixel = 0
	skipBtn.Font = Enum.Font.Arcade
	skipBtn.Text = "Skip"
	skipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	skipBtn.TextStrokeTransparency = 0.3
	skipBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	skipBtn.TextScaled = true
	skipBtn.ZIndex = buttonContainer.ZIndex + 1
	skipBtn.Visible = true
	skipBtn.Parent = buttonContainer

	addCornerBrackets(skipBtn, Color3.fromRGB(200, 100, 100))

	local function cleanupRoll()
		isRolling = false
		if popup and popup.Parent then
			popup:Destroy()
		end
	end

	local function doEquip()
		playGuiClickSound()
		local success = addToInventory(rolledItem.name)
		if success then
			equipBtn.Text = "Added!"
			equipBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
		else
			equipBtn.Text = "Failed!"
			equipBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
		end
		wait(0.3)
		cleanupRoll()
	end

	local function doSkip()
		playGuiClickSound()
		skipBtn.Text = "Skipped!"
		skipBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
		wait(0.3)
		cleanupRoll()
	end

	equipBtn.Activated:Connect(doEquip)
	skipBtn.Activated:Connect(doSkip)

	-- Auto-action handling
	if autoAction == "equip" then
		spawn(function()
			wait(0.6)
			if equipBtn and equipBtn.Parent then
				doEquip()
			end
		end)
	elseif autoAction == "skip" then
		spawn(function()
			wait(0.6)
			if skipBtn and skipBtn.Parent then
				doSkip()
			end
		end)
	end

	print("?? Roll Popup: Final popup shown for " .. rolledItem.name .. (autoAction and (" (auto: " .. autoAction .. ")") or ""))
end

-- Enhanced Rolling Logic
local function rollForItem()
	local totalWeight = 0
	for _, item in pairs(brainrotItems) do
		totalWeight = totalWeight + (1000 / item.odds)
	end

	local randomValue = math.random() * totalWeight
	local currentWeight = 0

	for _, item in pairs(brainrotItems) do
		currentWeight = currentWeight + (1000 / item.odds)
		if randomValue <= currentWeight then
			return item
		end
	end

	return brainrotItems[1] -- Fallback
end

local function getRareBrainrot()
	local rares = {}
	for _, item in pairs(brainrotItems) do
		if item.rarity == "rare" or item.rarity == "mythic" or item.rarity == "legendary" then
			table.insert(rares, item)
		end
	end

	if #rares > 0 then
		return rares[math.random(1, #rares)]
	else
		return brainrotItems[#brainrotItems]
	end
end

-- FIXED: Enhanced Animation System with Proper Visibility
local function playSuspenseAnimation(cycleList, finishedCallback)
	currentRollSound = playSuspenseSound()

	local animationPopup = Instance.new("Frame")
	animationPopup.Name = "RollPopup"
	animationPopup.Size = UDim2.new(0, 500, 0, 300)
	animationPopup.Position = UDim2.new(0.5, -250, 0.5, -150)
	animationPopup.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	animationPopup.BackgroundTransparency = 0
	animationPopup.BorderSizePixel = 0
	animationPopup.ZIndex = 10
	animationPopup.Visible = true
	animationPopup.Parent = gui

	addCornerBrackets(animationPopup, Color3.fromRGB(200, 200, 200))

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ItemName"
	nameLabel.Size = UDim2.new(0.9, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.2, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Arcade
	nameLabel.Text = "Rolling..."
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.ZIndex = animationPopup.ZIndex + 1
	nameLabel.Visible = true
	nameLabel.Parent = animationPopup

	local oddsLabel = Instance.new("TextLabel")
	oddsLabel.Name = "ItemOdds"
	oddsLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	oddsLabel.Position = UDim2.new(0.05, 0, 0.6, 0)
	oddsLabel.BackgroundTransparency = 1
	oddsLabel.Font = Enum.Font.Arcade
	oddsLabel.Text = ""
	oddsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	oddsLabel.TextStrokeTransparency = 0.5
	oddsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	oddsLabel.TextScaled = true
	oddsLabel.ZIndex = animationPopup.ZIndex + 1
	oddsLabel.Visible = true
	oddsLabel.Parent = animationPopup

	local function cycleStep(i)
		if not animationPopup.Parent then return end

		local thisItem = cycleList[i]
		nameLabel.Text = thisItem.name
		nameLabel.TextColor3 = thisItem.color
		oddsLabel.Text = "1 in " .. thisItem.odds
		oddsLabel.TextColor3 = thisItem.color

		if i == #cycleList then
			wait(0.15)
			if animationPopup.Parent then
				animationPopup:Destroy()
			end
			stopSuspenseSound()
			if finishedCallback then
				finishedCallback()
			end
			return
		end

		if i == #cycleList - 1 then
			wait(1) -- Dramatic pause
		else
			local nextWait = 0.08
			if i > #cycleList - 6 then
				nextWait = 0.15
			elseif i > #cycleList - 12 then
				nextWait = 0.10
			end
			wait(nextWait)
		end

		cycleStep(i + 1)
	end

	print("?? Roll Popup: Starting suspense animation with " .. #cycleList .. " items")
	cycleStep(1)
end

-- Enhanced Roll Creation
local function createRollPopup(isQuick)
	if isRolling then
		print("?? Roll Popup: Already rolling, ignoring request")
		return false
	end

	isRolling = true
	print("?? Roll Popup: Creating roll popup (quick: " .. tostring(isQuick) .. ")")

	local existingPopup = gui:FindFirstChild("RollPopup")
	if existingPopup then
		existingPopup:Destroy()
	end

	fetchSettings()

	local function isSelected(name)
		return (skipList and skipList[name]) or (saveList and saveList[name])
	end

	local function getAutoAction(item)
		if isSelected(item.name) then
			if skipList and skipList[item.name] then
				return "skip"
			elseif saveList and saveList[item.name] then
				return "equip"
			end
		else
			local odds = tonumber(item.odds)
			if skipBrainrotsValue and skipBrainrotsValue > 0 and odds < skipBrainrotsValue then
				return "skip"
			end
			if autoSaveValue and autoSaveValue > 0 and odds > autoSaveValue then
				return "equip"
			end
		end
		return nil
	end

	if isQuick then
		local rolledItem = rollForItem()
		local autoAction = getAutoAction(rolledItem)
		print("?? Roll Popup: Quick roll - " .. rolledItem.name .. " (odds: " .. rolledItem.odds .. ")")
		showFinalPopup(rolledItem, autoAction)
	else
		local cycleList = {}
		local extraCycles = 20 + math.random(5, 10)

		-- Add random items for suspense
		for i = 1, extraCycles - 2 do
			local randItem = brainrotItems[math.random(1, #brainrotItems)]
			table.insert(cycleList, randItem)
		end

		-- Add a rare item for dramatic effect
		local panicRare = getRareBrainrot()
		table.insert(cycleList, panicRare)

		-- Add the actual rolled item
		local rolledItem = rollForItem()
		table.insert(cycleList, rolledItem)

		print("?? Roll Popup: Full roll - " .. rolledItem.name .. " (odds: " .. rolledItem.odds .. ") with " .. extraCycles .. " suspense items")

		playSuspenseAnimation(cycleList, function()
			local autoAction = getAutoAction(rolledItem)
			showFinalPopup(rolledItem, autoAction)
		end)
	end

	return true
end

-- Enhanced Utilities
local function canRoll()
	return not isRolling
end

-- Global Functions
_G.createRollPopup = createRollPopup
_G.canRoll = canRoll

-- Enhanced Roll Event Handler
local function onRollButtonPressed(isQuick)
	if not canRoll() then
		print("?? Roll Popup: Cannot roll - already rolling!")
		return false
	end

	local success = pcall(function()
		createRollPopup(isQuick)
	end)

	if not success then
		isRolling = false
		warn("? Roll Popup: Error during roll creation")
	end

	return success
end

-- Event Connections
local rollEvent = ReplicatedStorage:FindFirstChild("RollEvent")
if not rollEvent then
	rollEvent = Instance.new("BindableEvent")
	rollEvent.Name = "RollEvent"
	rollEvent.Parent = ReplicatedStorage
	print("?? Roll Popup: Created RollEvent")
end

rollEvent.Event:Connect(function()
	print("?? Roll Popup: Roll event received")
	onRollButtonPressed(false)
end)

-- Cleanup on player removal
game.Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == player then
		stopSuspenseSound()
		isRolling = false
		print("?? Roll Popup: Cleaned up for leaving player")
	end
end)

-- Enhanced Error Handling
spawn(function()
	while true do
		wait(60) -- Check every minute
		if currentRollSound and not currentRollSound.Playing then
			currentRollSound = nil
		end
	end
end)

-- Debug GUI visibility test
spawn(function()
	wait(5)
	print("?? Roll Popup Debug: GUI exists = " .. tostring(gui and gui.Parent))
	print("?? Roll Popup Debug: GUI name = " .. (gui and gui.Name or "nil"))
	print("?? Roll Popup Debug: PlayerGui children count = " .. #playerGui:GetChildren())
end)

print("? Roll popup GUI with FIXED VISIBILITY loaded!")
print("?? Key fixes applied:")
print(" - Fixed GUI ZIndex and visibility properties")
print(" - Simplified corner bracket system")
print(" - Explicit Visible = true on all elements")
print(" - BackgroundTransparency = 0 for main frames")
print(" - Debug logging for troubleshooting")
print("?? GUI should now be visible when rolling!")