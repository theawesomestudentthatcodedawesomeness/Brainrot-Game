-- Enhanced Brainrot Settings UI with Gear System
-- Complete version with all fixes integrated
-- Created: 2025-07-29 06:44:41 UTC
-- User: theawesomestudentthatcodedawesomeness

local ShowBrainrotOnJLoEvent = game:GetService("ReplicatedStorage"):WaitForChild("ShowBrainrotOnJLoEvent")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("BrainrotSettingsRemotes")
local BrainrotDefinitions = require(ReplicatedStorage:WaitForChild("BrainrotDefinitions"))
local player = game.Players.LocalPlayer
local Players = game:GetService("Players")
local playerGui = player:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local workspace = game:GetService("Workspace")

-- ? SAFE GEAR SYSTEM INITIALIZATION
local GearRemotes = ReplicatedStorage:WaitForChild("GearRemotes", 10)
local GetFormattedGearInventory = nil

if GearRemotes then
	GetFormattedGearInventory = GearRemotes:FindFirstChild("GetFormattedGearInventory")
	if GetFormattedGearInventory and not GetFormattedGearInventory:IsA("RemoteFunction") then
		warn("GetFormattedGearInventory exists but is not a RemoteFunction")
		GetFormattedGearInventory = nil
	end
else
	warn("GearRemotes not found - gear functionality will be disabled")
end

-- Safe function to get player gear data
local function getPlayerData(player)
	if not GetFormattedGearInventory then
		return {}
	end

	local success, result = pcall(function()
		return GetFormattedGearInventory:InvokeServer()
	end)

	if success and result then
		return result
	else
		warn("Failed to get player gear data:", tostring(result))
		return {}
	end
end

-- Clean up any existing GUI
if playerGui:FindFirstChild("IconMenuGui") then
	playerGui.IconMenuGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "IconMenuGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Only one popup GUI can be open at a time
local currentPopup = nil
local function closeCurrentPopup()
	if currentPopup then
		currentPopup:Destroy()
		currentPopup = nil
	end
end

-- FORWARD DECLARATIONS
local showInventoryPopup
local createBrainrotSettingsMenuWithTabs
local currentActiveTab = "gears"

-- Sound Volume Settings (default and global)
local soundSettings = {
	BGVolume = _G.BrainrotBGVolume or 0.02,
	SFXVolume = _G.BrainrotSFXVolume or 0.2,
}
_G.BrainrotBGVolume = soundSettings.BGVolume
_G.BrainrotSFXVolume = soundSettings.SFXVolume

-- Inventory sync for discovered brainrots (but not used in Items tab)
local inventoryRemotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local updateInventoryEvent = inventoryRemotes:WaitForChild("UpdateInventory")
local currentInventory = {}
updateInventoryEvent.OnClientEvent:Connect(function(inventory)
	if inventory and type(inventory) == "table" then
		currentInventory = inventory
	else
		currentInventory = {}
	end
end)

-- Helper for retro brackets (icons)
local function addCornerBrackets(parent, color, isLarge, hasGlow)
	local thickness = isLarge and 2 or 1
	local length = isLarge and 18 or 8
	local positions = {
		{UDim2.new(0,0,0,0), UDim2.new(0,length,0,thickness)},
		{UDim2.new(0,0,0,0), UDim2.new(0,thickness,0,length)},
		{UDim2.new(1,-length,0,0), UDim2.new(0,length,0,thickness)},
		{UDim2.new(1,-thickness,0,0), UDim2.new(0,thickness,0,length)},
		{UDim2.new(0,0,1,-thickness), UDim2.new(0,length,0,thickness)},
		{UDim2.new(0,0,1,-length), UDim2.new(0,thickness,0,length)},
		{UDim2.new(1,-length,1,-thickness), UDim2.new(0,length,0,thickness)},
		{UDim2.new(1,-thickness,1,-length), UDim2.new(0,thickness,0,length)}
	}
	for _, pos in ipairs(positions) do
		local bracket = Instance.new("Frame")
		bracket.Position = pos[1]
		bracket.Size = pos[2]
		bracket.BackgroundColor3 = color
		bracket.BorderSizePixel = 0
		bracket.Parent = parent
		if hasGlow then
			bracket.BackgroundTransparency = 0.1
			local glow = Instance.new("Frame")
			glow.Size = UDim2.new(1, 4, 1, 4)
			glow.Position = UDim2.new(0, -2, 0, -2)
			glow.BackgroundColor3 = color
			glow.BackgroundTransparency = 0.8
			glow.BorderSizePixel = 0
			glow.ZIndex = bracket.ZIndex - 1
			glow.Parent = parent
		end
	end
end

-- Settings and inventory data
local savedSettings = Remotes.RequestSettings:InvokeServer()
if not savedSettings then
	savedSettings = {AutoSave = 0, SkipBrainrots = 0, SkipCutscene = 0, SkipList = {}, SaveList = {}}
end
local skipList = savedSettings.SkipList or {}
local saveList = savedSettings.SaveList or {}

local rarityOrder = { secret=0, mythic=1, legendary=2, rare=3, uncommon=4, common=5 }
local function sortByRarity(a, b)
	local ra = rarityOrder[a.rarity or "common"] or 5
	local rb = rarityOrder[b.rarity or "common"] or 5
	if ra ~= rb then
		return ra > rb
	else
		return a.name < b.name
	end
end

-- Collection Popup
local function getUnlockedBrainrotsSet()
	local collected = {}
	for _, item in ipairs(currentInventory) do
		collected[item.name] = true
	end
	return collected
end

local function showCollectionPopup()
	closeCurrentPopup()

	-- HIDE the roll gui when opening collection
	local bottomBar = playerGui:FindFirstChild("BottomBarGui")
	if bottomBar then bottomBar.Enabled = false end

	local camera = workspace.CurrentCamera
	local prevType = camera.CameraType
	local prevCFrame = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(Vector3.new(318.56, 14.381, 82.965), Vector3.new(352.007, -0.016, 83.743))

	local popup = Instance.new("Frame")
	popup.Name = "CollectionPopupGui"
	popup.Size = UDim2.new(1, 0, 1, 0)
	popup.Position = UDim2.new(0, 0, 0, 0)
	popup.BackgroundTransparency = 1
	popup.Parent = gui
	currentPopup = popup

	local leftPanel = Instance.new("Frame")
	leftPanel.Size = UDim2.new(0, 320, 1, 0)
	leftPanel.Position = UDim2.new(0, 0, 0, 0)
	leftPanel.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	leftPanel.BackgroundTransparency = 0.12
	leftPanel.BorderSizePixel = 0
	leftPanel.Parent = popup

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 52)
	title.Position = UDim2.new(0, 0, 0, 20)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Arcade
	title.Text = "Collection"
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.TextSize = 38
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.Parent = leftPanel

	local topDivider = Instance.new("Frame")
	topDivider.Size = UDim2.new(1, -32, 0, 2)
	topDivider.Position = UDim2.new(0, 16, 0, 74)
	topDivider.BackgroundColor3 = Color3.fromRGB(44,44,44)
	topDivider.BorderSizePixel = 0
	topDivider.Parent = leftPanel

	local allBrainrots = {}
	for _, item in ipairs(BrainrotDefinitions.List) do
		table.insert(allBrainrots, item)
	end
	
	table.sort(allBrainrots, function(a, b)
		local oddsA = a.odds or 999999
		local oddsB = b.odds or 999999
		return oddsA < oddsB  -- Lower odds = more common = appears first
	end)
	
	local unlockedSet = getUnlockedBrainrotsSet()

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -22, 1, -145)
	scroll.Position = UDim2.new(0, 11, 0, 78)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ScrollBarThickness = 8
	scroll.Parent = leftPanel

	local itemHeight = 42
	local selectedIndex = 1

	-- Declare updateDetails before it's used
	local updateDetails

	local btns = {}
	for i, brainrot in ipairs(allBrainrots) do
		local isUnlocked = unlockedSet[brainrot.name]
		local btn = Instance.new("TextButton")
		btn.Name = "BrainrotBtn_"..brainrot.name
		btn.Size = UDim2.new(1, 0, 0, itemHeight)
		btn.Position = UDim2.new(0, 0, 0, (i-1)*itemHeight)
		btn.BackgroundColor3 = Color3.fromRGB(24,24,24)
		btn.Font = Enum.Font.Arcade
		btn.TextSize = 22
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.TextColor3 = isUnlocked and (brainrot.color or Color3.fromRGB(220,220,220)) or Color3.fromRGB(120,120,120)
		btn.TextStrokeTransparency = 0.5
		btn.TextStrokeColor3 = Color3.fromRGB(0,0,0)
		btn.BorderSizePixel = 0
		if isUnlocked then
			btn.Text = string.format("%s    1 in %s", brainrot.name, tostring(brainrot.odds))
		else
			btn.Text = "[ Locked ]"
		end
		btn.Parent = scroll
		btns[i] = btn
		btn.MouseButton1Click:Connect(function()
			selectedIndex = i
			if updateDetails then
				updateDetails()
			end
			if isUnlocked and ShowBrainrotOnJLoEvent then
				-- Use titleColor if available, otherwise fallback to regular color
				local displayColor = brainrot.titleColor or brainrot.color
				ShowBrainrotOnJLoEvent:FireServer(brainrot.name, brainrot.odds, displayColor)
			end
		end)
		if i < #allBrainrots then
			local divider = Instance.new("Frame")
			divider.Size = UDim2.new(1, -6, 0, 2)
			divider.Position = UDim2.new(0, 3, 0, itemHeight-2)
			divider.BackgroundColor3 = Color3.fromRGB(44,44,44)
			divider.BorderSizePixel = 0
			divider.Parent = btn
		end
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, #allBrainrots*itemHeight)

	local rightPanel = Instance.new("Frame")
	rightPanel.Size = UDim2.new(0, 340, 0, 410)
	rightPanel.Position = UDim2.new(1, -360, 0.5, -205)
	rightPanel.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	rightPanel.BackgroundTransparency = 0.12
	rightPanel.BorderSizePixel = 0
	rightPanel.Parent = popup

	local nameTitle = Instance.new("TextLabel")
	nameTitle.Size = UDim2.new(1, -32, 0, 52)
	nameTitle.Position = UDim2.new(0, 16, 0, 18)
	nameTitle.BackgroundTransparency = 1
	nameTitle.Font = Enum.Font.Arcade
	nameTitle.Text = ""
	nameTitle.TextColor3 = Color3.fromRGB(255,140,70)
	nameTitle.TextSize = 32
	nameTitle.TextXAlignment = Enum.TextXAlignment.Left
	nameTitle.TextWrapped = true
	nameTitle.TextTruncate = Enum.TextTruncate.AtEnd
	nameTitle.Parent = rightPanel

	local detailsDivider = Instance.new("Frame")
	detailsDivider.Size = UDim2.new(1, -32, 0, 2)
	detailsDivider.Position = UDim2.new(0, 16, 0, 70)
	detailsDivider.BackgroundColor3 = Color3.fromRGB(44,44,44)
	detailsDivider.BorderSizePixel = 0
	detailsDivider.Parent = rightPanel

	local indexLabel = Instance.new("TextLabel")
	indexLabel.Size = UDim2.new(1, -32, 0, 28)
	indexLabel.Position = UDim2.new(0, 16, 0, 78)
	indexLabel.BackgroundTransparency = 1
	indexLabel.Font = Enum.Font.Arcade
	indexLabel.Text = ""
	indexLabel.TextColor3 = Color3.fromRGB(255,255,255)
	indexLabel.TextSize = 22
	indexLabel.TextXAlignment = Enum.TextXAlignment.Left
	indexLabel.Parent = rightPanel

	local descTitle = Instance.new("TextLabel")
	descTitle.Size = UDim2.new(1, -32, 0, 26)
	descTitle.Position = UDim2.new(0, 16, 0, 110)
	descTitle.BackgroundTransparency = 1
	descTitle.Font = Enum.Font.Arcade
	descTitle.Text = "Description"
	descTitle.TextColor3 = Color3.fromRGB(255,255,255)
	descTitle.TextSize = 18
	descTitle.TextXAlignment = Enum.TextXAlignment.Left
	descTitle.Parent = rightPanel

	local descBox = Instance.new("TextLabel")
	descBox.Size = UDim2.new(1, -32, 0, 80)
	descBox.Position = UDim2.new(0, 16, 0, 136)
	descBox.BackgroundColor3 = Color3.fromRGB(16,16,16)
	descBox.BorderSizePixel = 0
	descBox.Font = Enum.Font.Arcade
	descBox.Text = ""
	descBox.TextColor3 = Color3.fromRGB(220,220,220)
	descBox.TextSize = 16
	descBox.TextWrapped = true
	descBox.TextXAlignment = Enum.TextXAlignment.Left
	descBox.TextYAlignment = Enum.TextYAlignment.Top
	descBox.Parent = rightPanel
	local descCorner = Instance.new("UICorner")
	descCorner.CornerRadius = UDim.new(0, 8)
	descCorner.Parent = descBox

	local detailsBottomDivider = Instance.new("Frame")
	detailsBottomDivider.Size = UDim2.new(1, -32, 0, 2)
	detailsBottomDivider.Position = UDim2.new(0, 16, 1, -50)
	detailsBottomDivider.BackgroundColor3 = Color3.fromRGB(44,44,44)
	detailsBottomDivider.BorderSizePixel = 0
	detailsBottomDivider.Parent = rightPanel

	local checkmark = Instance.new("TextLabel")
	checkmark.Size = UDim2.new(0, 28, 0, 28)
	checkmark.Position = UDim2.new(1, -36, 1, -40)
	checkmark.BackgroundTransparency = 1
	checkmark.Font = Enum.Font.Arcade
	checkmark.Text = "?"
	checkmark.TextColor3 = Color3.fromRGB(90,180,255)
	checkmark.TextSize = 22
	checkmark.Parent = rightPanel

	local exitBtn = Instance.new("TextButton")
	exitBtn.Name = "ExitBtn"
	exitBtn.Size = UDim2.new(0.25, 0, 0, 38)
	exitBtn.Position = UDim2.new(0.75, -12, 1, -50)
	exitBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
	exitBtn.Font = Enum.Font.Arcade
	exitBtn.Text = "Exit"
	exitBtn.TextColor3 = Color3.fromRGB(255,255,255)
	exitBtn.TextSize = 20
	exitBtn.BorderSizePixel = 0
	exitBtn.Parent = leftPanel
	local exitCorner = Instance.new("UICorner")
	exitCorner.CornerRadius = UDim.new(0, 8)
	exitCorner.Parent = exitBtn
	exitBtn.MouseButton1Click:Connect(function()
		camera.CameraType = prevType
		camera.CFrame = prevCFrame
		closeCurrentPopup()

		-- SHOW the roll gui again
		local bottomBar = playerGui:FindFirstChild("BottomBarGui")
		if bottomBar then bottomBar.Enabled = true end
	end)

	-- NOW define updateDetails function
	updateDetails = function()
		local brainrot = allBrainrots[selectedIndex]
		local isUnlocked = unlockedSet[brainrot.name]
		if not isUnlocked then
			nameTitle.Text = "[ Locked ]"
			nameTitle.TextColor3 = Color3.fromRGB(140,140,140)
			indexLabel.Text = ""
			descBox.Text = ""
		else
			nameTitle.Text = brainrot.name
			nameTitle.TextColor3 = brainrot.color or Color3.fromRGB(255,255,255)
			indexLabel.Text = string.format("1 in %s", tostring(brainrot.odds))
			descBox.Text = brainrot.description or ""
			descTitle.Text = "Description"
		end
	end

	-- Call updateDetails after it's defined
	updateDetails()
end

-- ? ENHANCED GEAR INVENTORY DISPLAY FUNCTION
-- ? ARCADE-STYLE GEAR INVENTORY DISPLAY FUNCTION
-- ? ARCADE-STYLE GEAR INVENTORY DISPLAY FUNCTION WITH CUSTOM DECALS
-- ? CLEAN ARCADE-STYLE GEAR INVENTORY DISPLAY FUNCTION
-- ? COMPLETE RESTORED GEAR INVENTORY DISPLAY FUNCTION
local function updateGearInventoryDisplay(contentFrame, searchTerm)
	-- Clear existing content
	for _, child in pairs(contentFrame:GetChildren()) do
		if (child:IsA("Frame") or child:IsA("TextLabel")) and child.Name ~= "UICorner" and child.Name ~= "UIStroke" then
			child:Destroy()
		end
	end

	if not GetFormattedGearInventory then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, -20, 0, 100)
		emptyLabel.Position = UDim2.new(0, 10, 0, 50)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Font = Enum.Font.Arcade
		emptyLabel.Text = "[ GEAR SYSTEM OFFLINE ]\n[ CHECK SERVER CONFIG ]"
		emptyLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		emptyLabel.TextStrokeTransparency = 0.3
		emptyLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		emptyLabel.TextSize = 20
		emptyLabel.TextWrapped = true
		emptyLabel.Parent = contentFrame
		return
	end

	-- Show loading state while fetching data
	local loadingLabel = Instance.new("TextLabel")
	loadingLabel.Name = "LoadingLabel"
	loadingLabel.Size = UDim2.new(1, -20, 0, 100)
	loadingLabel.Position = UDim2.new(0, 10, 0, 50)
	loadingLabel.BackgroundTransparency = 1
	loadingLabel.Font = Enum.Font.Arcade
	loadingLabel.Text = "[ LOADING GEAR DATA... ]"
	loadingLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	loadingLabel.TextStrokeTransparency = 0.3
	loadingLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	loadingLabel.TextSize = 18
	loadingLabel.TextWrapped = true
	loadingLabel.Parent = contentFrame

	-- Fetch gear data with retry mechanism
	local function fetchGearData()
		local attempts = 0
		local maxAttempts = 3

		local function tryFetch()
			attempts = attempts + 1

			local success, formattedGears = pcall(function()
				return GetFormattedGearInventory:InvokeServer()
			end)

			if success and formattedGears then
				-- Remove loading label
				if loadingLabel and loadingLabel.Parent then
					loadingLabel:Destroy()
				end

				print("Successfully fetched gear data:", #formattedGears, "gears")

				-- Process the gear data
				local filteredGears = {}
				searchTerm = string.lower(searchTerm or "")

				for _, gear in ipairs(formattedGears) do
					if searchTerm == "" or string.find(string.lower(gear.name or ""), searchTerm) then
						table.insert(filteredGears, gear)
					end
				end

				if #filteredGears == 0 then
					local emptyLabel = Instance.new("TextLabel")
					emptyLabel.Size = UDim2.new(1, -20, 0, 120)
					emptyLabel.Position = UDim2.new(0, 10, 0, 50)
					emptyLabel.BackgroundTransparency = 1
					emptyLabel.Font = Enum.Font.Arcade
					emptyLabel.Text = searchTerm ~= "" and "[ NO MATCHES FOUND ]\n[ TRY DIFFERENT SEARCH ]" or "[ NO GEARS AVAILABLE ]\n[ VISIT GEAR MERCHANT ]\n[ TO CRAFT EQUIPMENT ]"
					emptyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
					emptyLabel.TextStrokeTransparency = 0.3
					emptyLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
					emptyLabel.TextSize = 18
					emptyLabel.TextWrapped = true
					emptyLabel.Parent = contentFrame
					return
				end

				-- Sort gears (equipped first, then by rarity)
				table.sort(filteredGears, function(a, b)
					if a.isEquipped ~= b.isEquipped then
						return a.isEquipped
					end
					local rarityOrder = {mythic = 1, legendary = 2, rare = 3, uncommon = 4, common = 5}
					return (rarityOrder[a.rarity] or 5) < (rarityOrder[b.rarity] or 5)
				end)

				-- Create gear cards
				local cardHeight = 110
				local cardSpacing = 12

				for i, gear in ipairs(filteredGears) do
					local gearCard = Instance.new("Frame")
					gearCard.Name = "GearCard_" .. tostring(gear.id or i)
					gearCard.Size = UDim2.new(1, -20, 0, cardHeight)
					gearCard.Position = UDim2.new(0, 10, 0, (i-1) * (cardHeight + cardSpacing) + 10)
					gearCard.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
					gearCard.BorderSizePixel = 0
					gearCard.Parent = contentFrame

					-- Rarity styling
					local rarityData = {
						mythic = {bg = Color3.fromRGB(25, 15, 35), border = Color3.fromRGB(180, 100, 255), text = "MYTHIC"},
						legendary = {bg = Color3.fromRGB(35, 25, 10), border = Color3.fromRGB(255, 165, 0), text = "LEGENDARY"},
						rare = {bg = Color3.fromRGB(10, 18, 35), border = Color3.fromRGB(100, 150, 255), text = "RARE"},
						uncommon = {bg = Color3.fromRGB(10, 25, 15), border = Color3.fromRGB(100, 255, 150), text = "UNCOMMON"},
						common = {bg = Color3.fromRGB(22, 22, 22), border = Color3.fromRGB(150, 150, 150), text = "COMMON"}
					}

					local rarity = rarityData[gear.rarity] or rarityData.common
					gearCard.BackgroundColor3 = rarity.bg

					local stroke = Instance.new("UIStroke")
					stroke.Color = rarity.border
					stroke.Thickness = 3
					stroke.Parent = gearCard

					-- Equipped indicator
					if gear.isEquipped then
						local equippedIndicator = Instance.new("Frame")
						equippedIndicator.Size = UDim2.new(0, 90, 0, 24)
						equippedIndicator.Position = UDim2.new(0, 8, 0, 8)
						equippedIndicator.BackgroundColor3 = Color3.fromRGB(30, 120, 30)
						equippedIndicator.BorderSizePixel = 0
						equippedIndicator.Parent = gearCard

						local equippedStroke = Instance.new("UIStroke")
						equippedStroke.Color = Color3.fromRGB(80, 200, 80)
						equippedStroke.Thickness = 2
						equippedStroke.Parent = equippedIndicator

						local equippedText = Instance.new("TextLabel")
						equippedText.Size = UDim2.new(1, 0, 1, 0)
						equippedText.BackgroundTransparency = 1
						equippedText.Font = Enum.Font.Arcade
						equippedText.Text = "EQUIPPED"
						equippedText.TextColor3 = Color3.fromRGB(255, 255, 255)
						equippedText.TextStrokeTransparency = 0.2
						equippedText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
						equippedText.TextSize = 14
						equippedText.Parent = equippedIndicator

						-- Enhance background for equipped gear
						gearCard.BackgroundColor3 = Color3.new(
							math.min(1, gearCard.BackgroundColor3.R + 0.08),
							math.min(1, gearCard.BackgroundColor3.G + 0.08),
							math.min(1, gearCard.BackgroundColor3.B + 0.08)
						)
					end

					-- Gear info panel
					local infoPanel = Instance.new("Frame")
					infoPanel.Size = UDim2.new(0, 275, 1, -20)
					infoPanel.Position = UDim2.new(0, 125, 0, 10)
					infoPanel.BackgroundTransparency = 1
					infoPanel.Parent = gearCard

					local nameLabel = Instance.new("TextLabel")
					nameLabel.Size = UDim2.new(1, 0, 0, 30)
					nameLabel.Position = UDim2.new(0, 0, 0, 5)
					nameLabel.BackgroundTransparency = 1
					nameLabel.Font = Enum.Font.Arcade
					nameLabel.Text = string.upper(tostring(gear.name or "UNKNOWN GEAR"))
					nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
					nameLabel.TextStrokeTransparency = 0.2
					nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
					nameLabel.TextSize = 18
					nameLabel.TextXAlignment = Enum.TextXAlignment.Left
					nameLabel.Parent = infoPanel

					local statsLabel = Instance.new("TextLabel")
					statsLabel.Size = UDim2.new(1, 0, 0, 22)
					statsLabel.Position = UDim2.new(0, 0, 0, 38)
					statsLabel.BackgroundTransparency = 1
					statsLabel.Font = Enum.Font.Arcade
					local statsText = "LUCK: +" .. tostring(gear.luckBoost or 0) .. "%"
					if gear.rollPenalty and gear.rollPenalty > 0 then
						statsText = statsText .. " • SPEED: -" .. tostring(gear.rollPenalty) .. "%"
					end
					statsLabel.Text = statsText
					statsLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
					statsLabel.TextStrokeTransparency = 0.3
					statsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
					statsLabel.TextSize = 16
					statsLabel.TextXAlignment = Enum.TextXAlignment.Left
					statsLabel.Parent = infoPanel

					local rarityContainer = Instance.new("Frame")
					rarityContainer.Size = UDim2.new(0, 100, 0, 20)
					rarityContainer.Position = UDim2.new(0, 0, 0, 65)
					rarityContainer.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
					rarityContainer.BorderSizePixel = 0
					rarityContainer.Parent = infoPanel

					local rarityStroke = Instance.new("UIStroke")
					rarityStroke.Color = rarity.border
					rarityStroke.Thickness = 1
					rarityStroke.Parent = rarityContainer

					local rarityText = Instance.new("TextLabel")
					rarityText.Size = UDim2.new(1, 0, 1, 0)
					rarityText.BackgroundTransparency = 1
					rarityText.Font = Enum.Font.Arcade
					rarityText.Text = rarity.text
					rarityText.TextColor3 = rarity.border
					rarityText.TextStrokeTransparency = 0.3
					rarityText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
					rarityText.TextSize = 12
					rarityText.Parent = rarityContainer

					-- Action button
					local actionButton = Instance.new("TextButton")
					actionButton.Size = UDim2.new(0, 130, 0, 35)
					actionButton.Position = UDim2.new(1, -145, 0.5, -17.5)
					actionButton.BackgroundColor3 = gear.isEquipped and Color3.fromRGB(120, 50, 50) or Color3.fromRGB(50, 100, 50)
					actionButton.BorderSizePixel = 0
					actionButton.Font = Enum.Font.Arcade
					actionButton.Text = gear.isEquipped and "UNEQUIP" or "EQUIP"
					actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
					actionButton.TextStrokeTransparency = 0.2
					actionButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
					actionButton.TextSize = 16
					actionButton.Parent = gearCard

					local actionStroke = Instance.new("UIStroke")
					actionStroke.Color = gear.isEquipped and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(120, 200, 120)
					actionStroke.Thickness = 2
					actionStroke.Parent = actionButton

					-- Button interactions
					actionButton.MouseEnter:Connect(function()
						local targetColor = gear.isEquipped and Color3.fromRGB(150, 70, 70) or Color3.fromRGB(70, 130, 70)
						TweenService:Create(actionButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
							BackgroundColor3 = targetColor,
							TextSize = 17
						}):Play()
					end)

					actionButton.MouseLeave:Connect(function()
						local targetColor = gear.isEquipped and Color3.fromRGB(120, 50, 50) or Color3.fromRGB(50, 100, 50)
						TweenService:Create(actionButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
							BackgroundColor3 = targetColor,
							TextSize = 16
						}):Play()
					end)

					actionButton.MouseButton1Click:Connect(function()
						if not GearRemotes then
							warn("GearRemotes not available")
							return
						end

						local EquipGear = GearRemotes:FindFirstChild("EquipGear")
						local UnequipGear = GearRemotes:FindFirstChild("UnequipGear")

						if not EquipGear or not UnequipGear then
							warn("Gear equip/unequip remotes not found")
							return
						end

						actionButton.Text = "WORKING..."
						actionButton.Active = false

						local success, message = pcall(function()
							if gear.isEquipped then
								return UnequipGear:InvokeServer()
							else
								return EquipGear:InvokeServer(gear.id)
							end
						end)

						-- Refresh the inventory after equip/unequip
						task.delay(0.3, function()
							if contentFrame and contentFrame.Parent then
								updateGearInventoryDisplay(contentFrame, searchTerm)
							end
						end)

						-- Update luck display if available
						if _G.UpdateLuckFromGear then
							task.delay(0.3, _G.UpdateLuckFromGear)
						elseif _G.ForceUpdateGearLuck then
							task.delay(0.3, _G.ForceUpdateGearLuck)
						end
					end)
				end

				-- Update canvas size
				local totalHeight = #filteredGears * (cardHeight + cardSpacing) + 20
				contentFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)

				print("Created " .. #filteredGears .. " gear cards successfully")

			elseif attempts < maxAttempts then
				-- Retry after delay
				warn("Failed to get gear data, attempt " .. attempts .. "/" .. maxAttempts .. ": " .. tostring(formattedGears))
				task.delay(1, tryFetch)
			else
				-- All attempts failed
				if loadingLabel and loadingLabel.Parent then
					loadingLabel:Destroy()
				end

				local errorLabel = Instance.new("TextLabel")
				errorLabel.Size = UDim2.new(1, -20, 0, 100)
				errorLabel.Position = UDim2.new(0, 10, 0, 50)
				errorLabel.BackgroundTransparency = 1
				errorLabel.Font = Enum.Font.Arcade
				errorLabel.Text = "[ CONNECTION ERROR ]\n[ RETRY LATER ]"
				errorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
				errorLabel.TextStrokeTransparency = 0.3
				errorLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
				errorLabel.TextSize = 22
				errorLabel.TextWrapped = true
				errorLabel.Parent = contentFrame

				warn("Failed to get gear data after all retries:", tostring(formattedGears))
			end
		end

		tryFetch()
	end

	fetchGearData()
end

-- ? SEPARATE ITEMS TAB DISPLAY FUNCTION
local function updateItemsInventoryDisplay(contentFrame, searchTerm)
	-- Clear existing content
	for _, child in pairs(contentFrame:GetChildren()) do
		if (child:IsA("Frame") or child:IsA("TextLabel")) and 
			child.Name ~= "UICorner" and child.Name ~= "UIStroke" then
			child:Destroy()
		end
	end

	-- ? ARCADE-STYLE ITEMS DISPLAY (placeholder for now)
	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Size = UDim2.new(1, -20, 0, 150)
	emptyLabel.Position = UDim2.new(0, 10, 0.5, -75)
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Font = Enum.Font.Arcade
	emptyLabel.Text = "[ ITEMS SYSTEM ]\n[ COMING SOON ]\n\n[ VISIT BONEY'S SHOP ]\n[ TO CRAFT ITEMS ]"
	emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	emptyLabel.TextStrokeTransparency = 0.3
	emptyLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	emptyLabel.TextSize = 20
	emptyLabel.TextWrapped = true
	emptyLabel.Parent = contentFrame

	-- Add a retro computer-style border around the message
	local messageFrame = Instance.new("Frame")
	messageFrame.Size = UDim2.new(0, 300, 0, 120)
	messageFrame.Position = UDim2.new(0.5, -150, 0.5, -60)
	messageFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
	messageFrame.BorderSizePixel = 0
	messageFrame.Parent = contentFrame

	-- Pixelated border for message frame
	local function createPixelBorder(parent, thickness, color)
		local positions = {
			{UDim2.new(0, thickness, 0, 0), UDim2.new(1, -thickness*2, 0, thickness)},
			{UDim2.new(0, thickness, 1, -thickness), UDim2.new(1, -thickness*2, 0, thickness)},
			{UDim2.new(0, 0, 0, thickness), UDim2.new(0, thickness, 1, -thickness*2)},
			{UDim2.new(1, -thickness, 0, thickness), UDim2.new(0, thickness, 1, -thickness*2)},
			{UDim2.new(0, 0, 0, 0), UDim2.new(0, thickness, 0, thickness)},
			{UDim2.new(1, -thickness, 0, 0), UDim2.new(0, thickness, 0, thickness)},
			{UDim2.new(0, 0, 1, -thickness), UDim2.new(0, thickness, 0, thickness)},
			{UDim2.new(1, -thickness, 1, -thickness), UDim2.new(0, thickness, 0, thickness)}
		}

		for _, pos in ipairs(positions) do
			local pixel = Instance.new("Frame")
			pixel.Position = pos[1]
			pixel.Size = pos[2]
			pixel.BackgroundColor3 = color
			pixel.BorderSizePixel = 0
			pixel.Parent = parent
		end
	end

	createPixelBorder(messageFrame, 2, Color3.fromRGB(100, 100, 100))

	emptyLabel.Parent = messageFrame
	emptyLabel.Size = UDim2.new(1, -20, 1, -20)
	emptyLabel.Position = UDim2.new(0, 10, 0, 10)

	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
end

-- ? ENHANCED INVENTORY POPUP WITH COMPLETE GEAR FUNCTIONALITY
showInventoryPopup = function()
	closeCurrentPopup()

	local popup = Instance.new("Frame")
	popup.Name = "InventoryPopupGui"
	popup.Size = UDim2.new(0, 600, 0, 500)
	popup.Position = UDim2.new(0.5, -300, 0.5, -250)
	popup.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	popup.BackgroundTransparency = 0.18
	popup.BorderSizePixel = 0
	popup.Parent = gui
	currentPopup = popup

	local outline = Instance.new("UIStroke")
	outline.Color = Color3.fromRGB(255, 255, 255)
	outline.Thickness = 2
	outline.Transparency = 0.1
	outline.Parent = popup
	addCornerBrackets(popup, Color3.fromRGB(255,255,255), true, false)

	-- Simple title
	local titleFrame = Instance.new("Frame")
	titleFrame.Name = "TitleFrame"
	titleFrame.Size = UDim2.new(1, 0, 0, 54)
	titleFrame.Position = UDim2.new(0, 0, 0, 0)
	titleFrame.BackgroundTransparency = 1
	titleFrame.Parent = popup

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 1, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Arcade
	title.Text = "Inventory"
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.TextSize = 40
	title.TextStrokeTransparency = 0.4
	title.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = titleFrame

	-- Tab bar
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, -20, 0, 38)
	tabBar.Position = UDim2.new(0, 10, 0, 54)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = popup

	local tabGap = 6
	local tabWidth = math.floor((popup.Size.X.Offset - 20 - tabGap) / 2)

	local gearsTab = Instance.new("TextButton")
	gearsTab.Name = "GearsTab"
	gearsTab.Size = UDim2.new(0, tabWidth, 1, 0)
	gearsTab.Position = UDim2.new(0, 0, 0, 0)
	gearsTab.BackgroundColor3 = currentActiveTab == "gears" and Color3.fromRGB(70, 130, 200) or Color3.fromRGB(32, 32, 32)
	gearsTab.Font = Enum.Font.Arcade
	gearsTab.Text = "Gears"
	gearsTab.TextColor3 = Color3.fromRGB(255,255,255)
	gearsTab.TextSize = 30
	gearsTab.AutoButtonColor = true
	gearsTab.BorderSizePixel = 0
	gearsTab.Parent = tabBar
	addCornerBrackets(gearsTab, Color3.fromRGB(255,255,255), false, false)

	local itemsTab = Instance.new("TextButton")
	itemsTab.Name = "ItemsTab"
	itemsTab.Size = UDim2.new(0, tabWidth, 1, 0)
	itemsTab.Position = UDim2.new(0, tabWidth + tabGap, 0, 0)
	itemsTab.BackgroundColor3 = currentActiveTab == "items" and Color3.fromRGB(70, 130, 200) or Color3.fromRGB(32, 32, 32)
	itemsTab.Font = Enum.Font.Arcade
	itemsTab.Text = "Items"
	itemsTab.TextColor3 = Color3.fromRGB(255,255,255)
	itemsTab.TextSize = 30
	itemsTab.AutoButtonColor = true
	itemsTab.BorderSizePixel = 0
	itemsTab.Parent = tabBar
	addCornerBrackets(itemsTab, Color3.fromRGB(255,255,255), false, false)

	-- Search bar
	local searchBar = Instance.new("TextBox")
	searchBar.Name = "SearchBar"
	searchBar.Size = UDim2.new(1, -24, 0, 32)
	searchBar.Position = UDim2.new(0, 12, 0, 98)
	searchBar.BackgroundColor3 = Color3.fromRGB(22,22,22)
	searchBar.Font = Enum.Font.Arcade
	searchBar.Text = "Search..."
	searchBar.TextColor3 = Color3.fromRGB(200,200,200)
	searchBar.TextSize = 22
	searchBar.BorderSizePixel = 0
	searchBar.TextXAlignment = Enum.TextXAlignment.Left
	searchBar.ClearTextOnFocus = true
	searchBar.Parent = popup
	addCornerBrackets(searchBar, Color3.fromRGB(255,255,255), false, false)

	-- Content frame
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, -24, 1, -146)
	contentFrame.Position = UDim2.new(0, 12, 0, 134)
	contentFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	contentFrame.BackgroundTransparency = 0.35
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 8
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentFrame.Parent = popup
	addCornerBrackets(contentFrame, Color3.fromRGB(255,255,255), false, false)

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 38, 0, 38)
	closeBtn.Position = UDim2.new(1, -48, 0, 12)
	closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
	closeBtn.BackgroundTransparency = 0.12
	closeBtn.Text = "X"
	closeBtn.Font = Enum.Font.Arcade
	closeBtn.TextSize = 34
	closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
	closeBtn.Parent = popup
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 12)
	cc.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(function()
		closeCurrentPopup()
	end)

	-- Function to populate content based on active tab
	local function populateContent(searchTerm)
		searchTerm = searchTerm or ""

		-- ? FIXED: Proper tab separation
		if currentActiveTab == "gears" then
			-- Display gear inventory with custom decals
			updateGearInventoryDisplay(contentFrame, searchTerm)
		else
			-- Display items inventory (separate from gears)
			updateItemsInventoryDisplay(contentFrame, searchTerm)
		end
	end

	-- Tab switching functionality
	local function switchTab(newTab)
		currentActiveTab = newTab
		gearsTab.BackgroundColor3 = currentActiveTab == "gears" and Color3.fromRGB(70, 130, 200) or Color3.fromRGB(32, 32, 32)
		itemsTab.BackgroundColor3 = currentActiveTab == "items" and Color3.fromRGB(70, 130, 200) or Color3.fromRGB(32, 32, 32)
		populateContent(searchBar.Text == "Search..." and "" or searchBar.Text)
	end

	-- Connect tab buttons
	gearsTab.MouseButton1Click:Connect(function()
		switchTab("gears")
	end)

	itemsTab.MouseButton1Click:Connect(function()
		switchTab("items")
	end)

	-- Connect search functionality
	searchBar:GetPropertyChangedSignal("Text"):Connect(function()
		local searchTerm = searchBar.Text == "Search..." and "" or searchBar.Text
		populateContent(searchTerm)
	end)

	searchBar.FocusLost:Connect(function()
		if searchBar.Text == "" then
			searchBar.Text = "Search..."
		end
	end)

	searchBar.Focused:Connect(function()
		if searchBar.Text == "Search..." then
			searchBar.Text = ""
		end
	end)

	-- Initial population
	populateContent()
end

-- Brainrot Filter Popup (keeping existing implementation)
-- In your showBrainrotFilterPopup function, find this section and replace it:

local function showBrainrotFilterPopup()
	closeCurrentPopup()
	local popup = Instance.new("Frame")
	popup.Name = "BrainrotFilterPopup"
	popup.Size = UDim2.new(0, 500, 0, 600)
	popup.Position = UDim2.new(0.5, -250, 0.5, -300)
	popup.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	popup.BackgroundTransparency = 0.08
	popup.BorderSizePixel = 0
	popup.Parent = gui
	currentPopup = popup

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Arcade
	title.Text = "Brainrot Filter"
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.TextSize = 34
	title.Parent = popup

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -24, 1, -90)
	scroll.Position = UDim2.new(0, 12, 0, 60)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ScrollBarThickness = 8
	scroll.Parent = popup

	local allBrainrots = {}
	for _, item in pairs(BrainrotDefinitions.List) do
		table.insert(allBrainrots, item)
	end

	-- ? Sort by odds (most common first - lowest odds to highest odds)
	table.sort(allBrainrots, function(a, b)
		local oddsA = a.odds or 999999
		local oddsB = b.odds or 999999
		return oddsA < oddsB  -- Lower odds = more common = appears first
	end)

	-- ? GET DISCOVERED BRAINROTS SET
	local discoveredBrainrots = getUnlockedBrainrotsSet()

	local buttonHeight = 36
	for i, item in ipairs(allBrainrots) do
		-- ? CHECK IF USER HAS EVER HAD THIS BRAINROT
		local hasDiscovered = discoveredBrainrots[item.name] == true

		local btn = Instance.new("TextButton")
		btn.Name = "BrainrotBtn_"..item.name
		btn.Size = UDim2.new(1, -10, 0, buttonHeight)
		btn.Position = UDim2.new(0, 5, 0, (i-1)*(buttonHeight+5))
		btn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
		btn.Font = Enum.Font.Arcade
		btn.TextScaled = true
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = scroll

		-- ? SET TEXT AND INTERACTION BASED ON DISCOVERY STATUS
		if hasDiscovered then
			-- User has discovered this brainrot - allow filtering
			btn.Text = item.name
			btn.TextColor3 = Color3.fromRGB(255,255,255)

			local state = 0
			if skipList[item.name] then state = 1 end
			if saveList[item.name] then state = 2 end

			local function updateBtnColor()
				if state == 0 then
					btn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
					btn.TextColor3 = Color3.fromRGB(230,230,230)
				elseif state == 1 then
					btn.BackgroundColor3 = Color3.fromRGB(170, 40, 40)
					btn.TextColor3 = Color3.fromRGB(255,255,255)
				elseif state == 2 then
					btn.BackgroundColor3 = Color3.fromRGB(50, 180, 70)
					btn.TextColor3 = Color3.fromRGB(255,255,255)
				end
			end
			updateBtnColor()

			btn.MouseButton1Click:Connect(function()
				if state == 0 then
					state = 1
					skipList[item.name] = true
					saveList[item.name] = nil
				elseif state == 1 then
					state = 2
					skipList[item.name] = nil
					saveList[item.name] = true
				elseif state == 2 then
					state = 0
					skipList[item.name] = nil
					saveList[item.name] = nil
				end
				updateBtnColor()
			end)
		else
			-- ? USER HAS NEVER DISCOVERED THIS BRAINROT - SHOW AS MYSTERIOUS LOCKED
			btn.Text = "[ ? ? ? ? ? ? ? ]"
			btn.TextColor3 = Color3.fromRGB(100, 100, 100)
			btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

			-- ? ADD LOCK ICON
			local lockIcon = Instance.new("TextLabel")
			lockIcon.Size = UDim2.new(0, 30, 1, 0)
			lockIcon.Position = UDim2.new(1, -35, 0, 0)
			lockIcon.BackgroundTransparency = 1
			lockIcon.Font = Enum.Font.Arcade
			lockIcon.Text = "??"
			lockIcon.TextColor3 = Color3.fromRGB(80, 80, 80)
			lockIcon.TextSize = 18
			lockIcon.Parent = btn

			-- ? DISABLE INTERACTION FOR LOCKED BRAINROTS
			btn.AutoButtonColor = false

			-- ? MYSTERIOUS HOVER TEXT
			btn.MouseEnter:Connect(function()
				btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				btn.Text = "[ UNDISCOVERED ]"
			end)

			btn.MouseLeave:Connect(function()
				btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
				btn.Text = "[ ? ? ? ? ? ? ? ]"
			end)
		end

		-- ? ADD DIVIDER BETWEEN ITEMS (except for last item)
		if i < #allBrainrots then
			local divider = Instance.new("Frame")
			divider.Size = UDim2.new(1, -6, 0, 2)
			divider.Position = UDim2.new(0, 3, 0, buttonHeight-2)
			divider.BackgroundColor3 = Color3.fromRGB(44,44,44)
			divider.BorderSizePixel = 0
			divider.Parent = btn
		end
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, #allBrainrots*(buttonHeight+5)+10)

	local saveBtn = Instance.new("TextButton")
	saveBtn.Size = UDim2.new(0, 120, 0, 38)
	saveBtn.Position = UDim2.new(0.5, -60, 1, -48)
	saveBtn.BackgroundColor3 = Color3.fromRGB(40,130,230)
	saveBtn.Font = Enum.Font.Arcade
	saveBtn.Text = "Save & Close"
	saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
	saveBtn.TextScaled = true
	saveBtn.Parent = popup

	saveBtn.MouseButton1Click:Connect(function()
		Remotes.UpdateSetting:FireServer("SkipList", skipList)
		Remotes.UpdateSetting:FireServer("SaveList", saveList)
		closeCurrentPopup()
	end)
end

-- Settings creation function (keeping existing implementation but simplified)
local function createSettingsTabBar(parent, onTabChanged)
	local tabBar = Instance.new("Frame")
	tabBar.Name = "SettingsTabBar"
	tabBar.Size = UDim2.new(1, 0, 0, 46)
	tabBar.Position = UDim2.new(0, 0, 0, 0)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = parent

	local gap = 18
	local tabCount = 2
	local totalWidth = 700
	local tabWidth = (totalWidth - gap) / tabCount

	local tabNames = {"Rolling", "Sound Effects"}
	local tabButtons = {}

	for i, tabName in ipairs(tabNames) do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = tabName.."TabBtn"
		tabBtn.Size = UDim2.new(0, tabWidth, 1, 0)
		tabBtn.Position = UDim2.new(0, ((i-1)*(tabWidth+gap)), 0, 0)
		tabBtn.BackgroundColor3 = (i==1) and Color3.fromRGB(70,130,200) or Color3.fromRGB(34,36,39)
		tabBtn.BorderSizePixel = 0
		tabBtn.Font = Enum.Font.Arcade
		tabBtn.Text = tabName
		tabBtn.TextColor3 = Color3.fromRGB(255,255,255)
		tabBtn.TextSize = 28
		tabBtn.AutoButtonColor = true
		tabBtn.Parent = tabBar
		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 15)
		tabCorner.Parent = tabBtn

		local shadow = Instance.new("UIStroke")
		shadow.Color = Color3.fromRGB(0,0,0)
		shadow.Thickness = 2
		shadow.Transparency = 0.5
		shadow.Parent = tabBtn

		tabBtn.MouseButton1Click:Connect(function()
			onTabChanged(tabName)
			for j, btn in ipairs(tabButtons) do
				btn.BackgroundColor3 = (btn == tabBtn) and Color3.fromRGB(70,130,200) or Color3.fromRGB(34,36,39)
			end
		end)
		table.insert(tabButtons, tabBtn)
	end
	return tabBar
end

local function createSlider(parent, labelText, initialValue, yOffset, onChanged, maxPercent)
	maxPercent = maxPercent or 100
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 210, 0, 30)
	label.Position = UDim2.new(0, 32, 0, yOffset)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Arcade
	label.Text = labelText
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Parent = parent

	local sliderBack = Instance.new("Frame")
	sliderBack.Size = UDim2.new(0, 180, 0, 18)
	sliderBack.Position = UDim2.new(0, 260, 0, yOffset+6)
	sliderBack.BackgroundColor3 = Color3.fromRGB(50,50,50)
	sliderBack.BorderSizePixel = 0
	sliderBack.Parent = parent

	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new(initialValue,0,1,0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(120,210,100)
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBack

	local thumb = Instance.new("Frame")
	thumb.Size = UDim2.new(0,14,1,8)
	thumb.Position = UDim2.new(initialValue,-7,0,-4)
	thumb.BackgroundColor3 = Color3.fromRGB(210,210,210)
	thumb.BorderSizePixel = 0
	thumb.Parent = sliderBack

	local percentTxt = Instance.new("TextLabel")
	percentTxt.Size = UDim2.new(0, 54, 0, 18)
	percentTxt.Position = UDim2.new(0, 450, 0, yOffset+6)
	percentTxt.BackgroundTransparency = 1
	percentTxt.Font = Enum.Font.Arcade
	percentTxt.Text = tostring(math.floor(initialValue*maxPercent)).."%"
	percentTxt.TextColor3 = Color3.new(1,1,1)
	percentTxt.TextScaled = true
	percentTxt.Parent = parent

	local dragging = false

	local function setSlider(val)
		val = math.clamp(val, 0, 1)
		sliderFill.Size = UDim2.new(val,0,1,0)
		thumb.Position = UDim2.new(val, -7, 0, -4)
		percentTxt.Text = tostring(math.floor(val*maxPercent)).."%"
		onChanged(val)
	end

	sliderBack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			local abs = sliderBack.AbsolutePosition.X
			local size = sliderBack.AbsoluteSize.X
			local mouse = UserInputService:GetMouseLocation().X
			setSlider((mouse-abs)/size)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local abs = sliderBack.AbsolutePosition.X
			local size = sliderBack.AbsoluteSize.X
			local mouse = input.Position.X
			setSlider((mouse-abs)/size)
		end
	end)
end

-- Main settings function (simplified)
createBrainrotSettingsMenuWithTabs = function()
	closeCurrentPopup()
	if gui:FindFirstChild("BrainrotSettingsMenu") then
		gui.BrainrotSettingsMenu:Destroy()
	end

	local bg = Instance.new("Frame")
	bg.Name = "BrainrotSettingsMenu"
	bg.Size = UDim2.new(0, 700, 0, 430)
	bg.Position = UDim2.new(0.5, -350, 0.5, -215)
	bg.BackgroundColor3 = Color3.fromRGB(24,26,28)
	bg.BackgroundTransparency = 0.08
	bg.BorderSizePixel = 0
	bg.Visible = false
	bg.Parent = gui
	currentPopup = bg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 28)
	corner.Parent = bg

	local outline = Instance.new("UIStroke")
	outline.Color = Color3.fromRGB(255,255,255)
	outline.Thickness = 2
	outline.Transparency = 0.13
	outline.Parent = bg

	local currentTab
	local tabBar = createSettingsTabBar(bg, function(tabName)
		currentTab = tabName
		bg.RollingFrame.Visible = (tabName == "Rolling")
		bg.SoundFrame.Visible = (tabName == "Sound Effects")
	end)

	local rollingFrame = Instance.new("Frame")
	rollingFrame.Name = "RollingFrame"
	rollingFrame.Size = UDim2.new(1, 0, 1, -48)
	rollingFrame.Position = UDim2.new(0, 0, 0, 44)
	rollingFrame.BackgroundTransparency = 1
	rollingFrame.Visible = true
	rollingFrame.Parent = bg

	local soundFrame = Instance.new("Frame")
	soundFrame.Name = "SoundFrame"
	soundFrame.Size = UDim2.new(1, 0, 1, -48)
	soundFrame.Position = UDim2.new(0, 0, 0, 44)
	soundFrame.BackgroundTransparency = 1
	soundFrame.Visible = false
	soundFrame.Parent = bg

	local y = 16
	local sectionGap = 82

	local function createSection(label, desc, defaultVal, ypos, isEdit, key)
		local sec = Instance.new("Frame")
		sec.Size = UDim2.new(1, -28, 0, 74)
		sec.Position = UDim2.new(0, 14, 0, ypos)
		sec.BackgroundColor3 = Color3.fromRGB(34,36,39)
		sec.BackgroundTransparency = 0.05
		sec.BorderSizePixel = 0
		sec.Parent = rollingFrame
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 14)
		c.Parent = sec
		local s = Instance.new("UIStroke")
		s.Color = Color3.fromRGB(180,180,180)
		s.Thickness = 1.25
		s.Transparency = 0.2
		s.Parent = sec

		local l = Instance.new("TextLabel")
		l.Text = label
		l.Size = UDim2.new(1, -180, 0, 32)
		l.Position = UDim2.new(0, 18, 0, 3)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.Arcade
		l.TextColor3 = Color3.fromRGB(255,255,255)
		l.TextSize = 30
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.ZIndex = 3
		l.Parent = sec

		local d = Instance.new("TextLabel")
		d.Text = desc
		d.Size = UDim2.new(1, -180, 0, 22)
		d.Position = UDim2.new(0, 18, 0, 38)
		d.BackgroundTransparency = 1
		d.Font = Enum.Font.Arcade
		d.TextColor3 = Color3.fromRGB(255,70,70)
		d.TextSize = 18
		d.TextXAlignment = Enum.TextXAlignment.Left
		d.ZIndex = 3
		d.Parent = sec

		if isEdit then
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 155, 0, 46)
			btn.Position = UDim2.new(1, -168, 0, 14)
			btn.BackgroundColor3 = Color3.fromRGB(38, 110, 180)
			btn.Text = "Edit"
			btn.TextSize = 27
			btn.Font = Enum.Font.Arcade
			btn.TextColor3 = Color3.fromRGB(255,255,255)
			btn.BorderSizePixel = 0
			btn.ZIndex = 3
			btn.Parent = sec
			local cc = Instance.new("UICorner")
			cc.CornerRadius = UDim.new(0, 10)
			cc.Parent = btn
			btn.MouseButton1Click:Connect(showBrainrotFilterPopup)
		else
			local box = Instance.new("TextBox")
			box.Size = UDim2.new(0, 88, 0, 46)
			box.Position = UDim2.new(1, -107, 0, 14)
			box.BackgroundColor3 = Color3.fromRGB(20,20,20)
			box.Text = tostring(savedSettings[key])
			box.TextSize = 28
			box.Font = Enum.Font.Arcade
			box.TextColor3 = Color3.fromRGB(255,255,255)
			box.TextXAlignment = Enum.TextXAlignment.Center
			box.TextYAlignment = Enum.TextYAlignment.Center
			box.BorderSizePixel = 0
			box.ZIndex = 3
			box.Parent = sec
			local cc = Instance.new("UICorner")
			cc.CornerRadius = UDim.new(0, 8)
			cc.Parent = box
			box.ClearTextOnFocus = false
			box.TextEditable = true
			box.Active = true
			box.FocusLost:Connect(function(enter)
				local newVal = tonumber(box.Text)
				if newVal == nil then
					box.Text = tostring(savedSettings[key])
				else
					savedSettings[key] = newVal
					box.Text = tostring(newVal)
					Remotes.UpdateSetting:FireServer(key, newVal)
				end
			end)
		end
		return sec
	end

	createSection("Auto Save", "(Auto save Brainrots over the value)", savedSettings.AutoSave, y, false, "AutoSave")
	y = y + sectionGap
	createSection("Skip Brainrots", "(Skips Brainrots under the value set)", savedSettings.SkipBrainrots, y, false, "SkipBrainrots")
	y = y + sectionGap
	createSection("Skip Cutscene", "(Skips cutscenes, -1 to skip all)", savedSettings.SkipCutscene, y, false, "SkipCutscene")
	y = y + sectionGap
	createSection("Brainrot Filter", "Select Brainrots to auto delete", nil, y, true)

	local title = Instance.new("TextLabel")
	title.Text = "Sound Settings"
	title.Size = UDim2.new(1, 0, 0, 36)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Arcade
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.TextSize = 32
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Top
	title.ZIndex = 2
	title.Parent = soundFrame

	createSlider(soundFrame, "Background Volume", soundSettings.BGVolume, 52, function(val)
		soundSettings.BGVolume = val
		_G.BrainrotBGVolume = val
		for _,sound in ipairs(workspace:GetChildren()) do
			if sound:IsA("Sound") and sound.Name:match("^BackgroundAmbience_Local_") then
				sound.Volume = (val or 0.8) * 0.2
			end
		end
	end, 200)

	createSlider(soundFrame, "Effect Volume", soundSettings.SFXVolume, 125, function(val)
		soundSettings.SFXVolume = val
		_G.BrainrotSFXVolume = val

		-- Adjust current brainrot sounds
		local character = game.Players.LocalPlayer.Character
		if character then
			-- Find all sounds in character that might be from brainrot effects
			for _, sound in ipairs(character:GetDescendants()) do
				if sound:IsA("Sound") and 
					(sound.Name:match("^BrainrotMusic") or 
						sound.Name:match("^BrainrotSound") or 
						sound.Parent.Name == "BrainrotVFX" or 
						sound:GetAttribute("IsBrainrotSound")) then

					sound.Volume = val * (sound:GetAttribute("BaseVolume") or 1)
				end
			end
		end

		-- Test click sound
		local SFXFolder = ReplicatedStorage:FindFirstChild("BrainrotSounds")
		if SFXFolder then
			local click = SFXFolder:FindFirstChild("GuiClickSound")
			if click then
				local test = click:Clone()
				test.Volume = (val or 0.5) * 2
				test.Parent = workspace
				test:Play()
				game:GetService("Debris"):AddItem(test, test.TimeLength+0.1)
			end
		end
	end, 200)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0,36,0,36)
	closeBtn.Position = UDim2.new(1, -44, 0, 12)
	closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
	closeBtn.BackgroundTransparency = 0.18
	closeBtn.Text = "X"
	closeBtn.Font = Enum.Font.Arcade
	closeBtn.TextSize = 28
	closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
	closeBtn.Parent = bg
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 10)
	cc.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(function()
		bg.Visible = false
		closeCurrentPopup()
	end)

	local function show()
		bg.Visible = true
		bg.Size = UDim2.new(0,0,0,0)
		bg.Position = UDim2.new(0.5,0,0.5,0)
		TweenService:Create(bg, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 700, 0, 430), Position = UDim2.new(0.5, -350, 0.5, -215)
		}):Play()
	end

	return {show = show, frame = bg}
end

-- Simple Quest Popup (keeping just the GUI structure without data)
local function showQuestsPopup()
	closeCurrentPopup()

	local popup = Instance.new("Frame")
	popup.Name = "QuestPopupGui"
	popup.Size = UDim2.new(0, 800, 0, 500)
	popup.Position = UDim2.new(0.5, -400, 0.5, -250)
	popup.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	popup.BackgroundTransparency = 0.08
	popup.BorderSizePixel = 0
	popup.Parent = gui
	currentPopup = popup

	-- Add corner brackets
	addCornerBrackets(popup, Color3.fromRGB(255,255,255), true, false)

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = popup

	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, -50, 1, 0)
	titleText.Position = UDim2.new(0, 25, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.Font = Enum.Font.Arcade
	titleText.Text = "Quests"
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText.TextSize = 32
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Parent = titleBar

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 24
	closeButton.Font = Enum.Font.Arcade
	closeButton.Parent = titleBar
	closeButton.MouseButton1Click:Connect(function()
		closeCurrentPopup()
	end)

	-- Quest panels
	local questListPanel = Instance.new("Frame")
	questListPanel.Name = "QuestListPanel"
	questListPanel.Size = UDim2.new(0.3, 0, 1, -60)
	questListPanel.Position = UDim2.new(0, 10, 0, 55)
	questListPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	questListPanel.BorderSizePixel = 0
	questListPanel.Parent = popup

	local questDetailsPanel = Instance.new("Frame")
	questDetailsPanel.Name = "QuestDetailsPanel"
	questDetailsPanel.Size = UDim2.new(0.67, 0, 1, -60)
	questDetailsPanel.Position = UDim2.new(0.32, 0, 0, 55)
	questDetailsPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	questDetailsPanel.BorderSizePixel = 0
	questDetailsPanel.Parent = popup

	-- Message for no quests
	local noQuestsLabel = Instance.new("TextLabel")
	noQuestsLabel.Size = UDim2.new(1, -20, 0, 60)
	noQuestsLabel.Position = UDim2.new(0, 10, 0, 20)
	noQuestsLabel.BackgroundTransparency = 1
	noQuestsLabel.Font = Enum.Font.Arcade
	noQuestsLabel.Text = "No quests available yet.\nCheck back later!"
	noQuestsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	noQuestsLabel.TextSize = 24
	noQuestsLabel.TextWrapped = true
	noQuestsLabel.Parent = questListPanel
end

-- ICON BUTTON CREATOR
local function createIconButton(parent, position, iconImage, labelText, clickFunction)
	local iconContainer = Instance.new("Frame")
	iconContainer.Name = labelText .. "Icon"
	iconContainer.Size = UDim2.new(0, 38, 0, 38)
	iconContainer.Position = position
	iconContainer.BackgroundColor3 = Color3.fromRGB(45, 50, 45)
	iconContainer.BackgroundTransparency = 0.1
	iconContainer.BorderSizePixel = 0
	iconContainer.Parent = parent

	addCornerBrackets(iconContainer, Color3.fromRGB(200, 200, 200), false, false)

	local iconImageLabel = Instance.new("ImageLabel")
	iconImageLabel.Name = "Icon"
	iconImageLabel.Size = UDim2.new(0, 28, 0, 28)
	iconImageLabel.Position = UDim2.new(0.5, -14, 0.5, -14)
	iconImageLabel.BackgroundTransparency = 1
	iconImageLabel.Image = iconImage
	iconImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
	iconImageLabel.ScaleType = Enum.ScaleType.Fit
	iconImageLabel.Parent = iconContainer

	local clickButton = Instance.new("TextButton")
	clickButton.Name = "ClickButton"
	clickButton.Size = UDim2.new(1, 0, 1, 0)
	clickButton.Position = UDim2.new(0, 0, 0, 0)
	clickButton.BackgroundTransparency = 1
	clickButton.Text = ""
	clickButton.Parent = iconContainer

	local hoverLabel = Instance.new("Frame")
	hoverLabel.Name = "HoverLabel"
	hoverLabel.Size = UDim2.new(0, 0, 0, 28)
	hoverLabel.Position = UDim2.new(1, 8, 0.5, -14)
	hoverLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	hoverLabel.BackgroundTransparency = 0.1
	hoverLabel.BorderSizePixel = 0
	hoverLabel.Visible = false
	hoverLabel.Parent = iconContainer

	addCornerBrackets(hoverLabel, Color3.fromRGB(200, 200, 200), false, false)

	local labelTextLabel = Instance.new("TextLabel")
	labelTextLabel.Name = "LabelText"
	labelTextLabel.Size = UDim2.new(1, -8, 1, 0)
	labelTextLabel.Position = UDim2.new(0, 4, 0, 0)
	labelTextLabel.BackgroundTransparency = 1
	labelTextLabel.Font = Enum.Font.Arcade
	labelTextLabel.Text = labelText
	labelTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	labelTextLabel.TextStrokeTransparency = 0.3
	labelTextLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	labelTextLabel.TextScaled = true
	labelTextLabel.TextXAlignment = Enum.TextXAlignment.Left
	labelTextLabel.Parent = hoverLabel

	clickButton.MouseEnter:Connect(function()
		hoverLabel.Visible = true
		local textService = game:GetService("TextService")
		local textSize = textService:GetTextSize(labelText, 18, Enum.Font.Arcade, Vector2.new(200, 28))
		local labelWidth = math.max(80, textSize.X + 12)

		local showTween = TweenService:Create(hoverLabel, 
			TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
			{Size = UDim2.new(0, labelWidth, 0, 28)}
		)
		showTween:Play()

		local scaleTween = TweenService:Create(iconContainer,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad),
			{Size = UDim2.new(0, 42, 0, 42)}
		)
		scaleTween:Play()

		local brightTween = TweenService:Create(iconImageLabel,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad),
			{ImageColor3 = Color3.fromRGB(255, 255, 100)}
		)
		brightTween:Play()
	end)

	clickButton.MouseLeave:Connect(function()
		local hideTween = TweenService:Create(hoverLabel, 
			TweenInfo.new(0.15, Enum.EasingStyle.Quad), 
			{Size = UDim2.new(0, 0, 0, 28)}
		)
		hideTween:Play()

		hideTween.Completed:Connect(function()
			hoverLabel.Visible = false
		end)

		local scaleTween = TweenService:Create(iconContainer,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad),
			{Size = UDim2.new(0, 38, 0, 38)}
		)
		scaleTween:Play()

		local normalTween = TweenService:Create(iconImageLabel,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad),
			{ImageColor3 = Color3.fromRGB(255, 255, 255)}
		)
		normalTween:Play()
	end)

	if clickFunction then
		clickButton.MouseButton1Click:Connect(clickFunction)
	end

	return iconContainer
end

-- GAMEPASS SHOP SYSTEM
local MarketplaceService = game:GetService("MarketplaceService")

-- Gamepass configuration - Replace these IDs with your actual gamepass IDs
local GAMEPASSES = {
	{
		id = 1374405825, -- Replace with your actual gamepass ID
		name = "Quick Roll",
		description = "• Unlock Quick Roll\n• Allows you to skip the rolling animation\n• Rare auto purchases will not be skipped!",
		price = 100,
		icon = "rbxassetid://6035067836", -- Fast forward icon
		color = Color3.fromRGB(100, 255, 100),
		glowColor = Color3.fromRGB(50, 200, 50),
		category = "rolling"
	},
	{
		id = 1378491109, -- Replace with your actual gamepass ID
		name = "VIP",
		description = "• x1.2 Final Luck\n• x1.2 Daily Quest Rewards\n• +3 Daily Quest Rerolls\n• +1 Extra Daily Shop Slot\n• [VIP] Chat Tag\n• Vip-only Speed Boost",
		price = 249,
		icon = "rbxassetid://7485051715", -- Crown icon
		color = Color3.fromRGB(255, 215, 0),
		glowColor = Color3.fromRGB(255, 255, 0),
		category = "vip",
		popular = true
	},
	{
		id = 123456791, -- Replace with your actual gamepass ID
		name = "Invisible Gear",
		description = "• Hide Equipped Gear\n• Toggle visibility on/off\n• Keep all gear benefits\n• Clean character appearance",
		price = 80,
		icon = "rbxassetid://6764432408", -- Eye slash icon
		color = Color3.fromRGB(150, 150, 255),
		glowColor = Color3.fromRGB(100, 100, 200),
		category = "cosmetic"
	},
	{
		id = 1376797718, -- Replace with your actual gamepass ID
		name = "VIP+",
		description = "• x1.2 Final Luck (x1.3 if VIP is also owned)\n• +2 Extra Daily Shop Slots\n• Auto Item Pickup (20% duplication chance if\n  Item collector is owned)\n• [VIP+] Chat Tag\n• Bag 1.2x Capacity & Drill",
		price = 350,
		icon = "rbxassetid://7485051715", -- Premium crown
		color = Color3.fromRGB(0, 255, 200),
		glowColor = Color3.fromRGB(0, 200, 255),
		category = "vip",
		best_value = true
	},
	{
		id = 123456793, -- Replace with your actual gamepass ID
		name = "Merchant Teleporter",
		description = "• Instantly teleport to the merchant when they\n  appear in the world\n• Never miss limited time offers\n• Exclusive merchant notifications",
		price = 60,
		icon = "rbxassetid://6172765079", -- Teleport icon
		color = Color3.fromRGB(255, 150, 255),
		glowColor = Color3.fromRGB(200, 100, 200),
		category = "utility"
	},
	{
		id = 123456794, -- Replace with your actual gamepass ID
		name = "RNG Premium Pass - Season 1",
		description = "• Unlocks premium track from \"Season 1\" Season\n  Pass which gives tons of rewards!\n• Exclusive seasonal items\n• Bonus XP and rewards",
		price = 199,
		icon = "rbxassetid://6034287594", -- Star icon
		color = Color3.fromRGB(255, 100, 150),
		glowColor = Color3.fromRGB(255, 50, 100),
		category = "seasonal"
	}
}

-- Enhanced gamepass shop function
-- COMPLETE GAMEPASS SHOP FUNCTION - WITH OWNERSHIP DETECTION
-- ADD THIS TO YOUR EXISTING GAMEPASS SHOP SCRIPT
-- Replace your showGamepassShop function with this enhanced version

-- Enhanced gamepass shop with ownership detection
-- Enhanced gamepass shop with proper ownership detection
local function showGamepassShop()
	closeCurrentPopup()

	-- Wait for gamepass system to be ready
	local GamepassRemotes = ReplicatedStorage:WaitForChild("GamepassRemotes", 5)
	local CheckGamepassOwnership = GamepassRemotes and GamepassRemotes:FindFirstChild("CheckGamepassOwnership")

	-- Create main shop frame
	local shopFrame = Instance.new("Frame")
	shopFrame.Name = "GamepassShopGui"
	shopFrame.Size = UDim2.new(0, 800, 0, 600)
	shopFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
	shopFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	shopFrame.BackgroundTransparency = 0.05
	shopFrame.BorderSizePixel = 0
	shopFrame.Parent = gui
	currentPopup = shopFrame

	-- Styling
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = shopFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 80, 120)
	stroke.Thickness = 3
	stroke.Transparency = 0.4
	stroke.Parent = shopFrame

	-- Title with retro styling
	local titleFrame = Instance.new("Frame")
	titleFrame.Size = UDim2.new(1, 0, 0, 70)
	titleFrame.Position = UDim2.new(0, 0, 0, 0)
	titleFrame.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
	titleFrame.BorderSizePixel = 0
	titleFrame.Parent = shopFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 15)
	titleCorner.Parent = titleFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -80, 1, 0)
	title.Position = UDim2.new(0, 40, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Arcade
	title.Text = "GAMEPASSES"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextStrokeTransparency = 0.3
	title.TextStrokeColor3 = Color3.fromRGB(60, 80, 120)
	title.TextSize = 42
	title.Parent = titleFrame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 50, 0, 50)
	closeBtn.Position = UDim2.new(1, -60, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
	closeBtn.Text = "?"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 28
	closeBtn.Font = Enum.Font.Arcade
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = shopFrame

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 12)
	closeBtnCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		closeCurrentPopup()
	end)

	-- Enhanced GAMEPASSES matching your image layout
	local GAMEPASSES = {
		{
			id = 1376797718, -- Matteoooo's VIP
			name = "Matteoooo's VIP",
			description = "• 2x Luck\n• Luck Potion Detector\n• Time-Stop Sandals of Liril™\n• [Matteoooo] Chat Tag",
			price = 350,
			icon = "rbxassetid://118478805616343",
			color = Color3.fromRGB(255, 165, 0), -- Gold
			position = {row = 0, col = 0}
		},
		{
			id = 1378491109, -- VIP
			name = "VIP",
			description = "• 1.25x Luck\n• Blueberry Octopus Necklace\n• [VIP] Chat Tag",
			price = 150,
			icon = "rbxassetid://116907983558452",
			color = Color3.fromRGB(255, 215, 0), -- Gold
			position = {row = 0, col = 1}
		},
		{
			id = 1374214026, -- Starter Pack
			name = "Starter Pack",
			description = "• Perfect starter bundle\n• Bobrito's Rusty Medal\n• U Din Din Din Din Dun Ma Din Din Din Dun\n• 2x Tigrrullini Watermellini",
			price = 50,
			icon = "rbxassetid://125050552522929",
			color = Color3.fromRGB(100, 200, 100), -- Green
			position = {row = 1, col = 0}
		},
		{
			id = 1374405825, -- Quick Roll
			name = "Quick Roll",
			description = "• Unlock Quick Roll\n• Allows you to skip the rolling animation",
			price = 50,
			icon = "rbxassetid://74913560486938",
			color = Color3.fromRGB(100, 200, 100), -- Green
			position = {row = 1, col = 1}
		}
	}

	-- Function to check gamepass ownership with multiple fallbacks
	-- Enhanced ownership checking function with better error handling
	-- Enhanced ownership checking function with better error handling
	local function checkGamepassOwnership(gamepassId, callback)
		local attempts = 0
		local maxAttempts = 5

		local function tryCheck()
			attempts = attempts + 1
			print("?? Checking ownership attempt " .. attempts .. " for gamepass " .. gamepassId)

			-- Method 1: Use enhanced server gamepass system
			if CheckGamepassOwnership then
				spawn(function()
					local success, owns = pcall(function()
						return CheckGamepassOwnership:InvokeServer(gamepassId)
					end)

					if success then
						print("? Server check successful for gamepass " .. gamepassId .. ": " .. tostring(owns))
						callback(owns)
						return
					end

					print("?? Server check failed, attempt " .. attempts .. "/" .. maxAttempts)

					if attempts < maxAttempts then
						wait(1) -- Wait before retry
						tryCheck()
					else
						print("? All server checks failed, using MarketplaceService fallback")
						-- Fallback to direct MarketplaceService check
						spawn(function()
							local fallbackSuccess, fallbackOwns = pcall(function()
								return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
							end)
							callback(fallbackSuccess and fallbackOwns or false)
						end)
					end
				end)
			else
				print("? CheckGamepassOwnership not available, using fallback")
				-- Direct fallback
				spawn(function()
					local success, owns = pcall(function()
						return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
					end)
					callback(success and owns or false)
				end)
			end
		end

		tryCheck()
	end

	-- Scrolling frame for gamepass cards
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -30, 1, -90)
	scrollFrame.Position = UDim2.new(0, 15, 0, 75)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 10
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 100, 140)
	scrollFrame.Parent = shopFrame

	-- Card dimensions matching your image
	local cardWidth = 370
	local cardHeight = 220
	local padding = 20
	local columns = 2

	-- Create gamepass cards in a 2x2 grid layout
	for i, gamepass in ipairs(GAMEPASSES) do
		local row = gamepass.position.row
		local col = gamepass.position.col

		local xPos = col * (cardWidth + padding)
		local yPos = row * (cardHeight + padding)

		-- Main gamepass card
		local card = Instance.new("Frame")
		card.Name = "GamepassCard_" .. gamepass.id
		card.Size = UDim2.new(0, cardWidth, 0, cardHeight)
		card.Position = UDim2.new(0, xPos, 0, yPos)
		card.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
		card.BorderSizePixel = 0
		card.Parent = scrollFrame

		-- Card styling with rounded corners
		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 15)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = gamepass.color
		cardStroke.Thickness = 2
		cardStroke.Transparency = 0.5
		cardStroke.Parent = card

		-- Header section with icon and title
		local headerFrame = Instance.new("Frame")
		headerFrame.Size = UDim2.new(1, -20, 0, 80)
		headerFrame.Position = UDim2.new(0, 10, 0, 10)
		headerFrame.BackgroundTransparency = 1
		headerFrame.Parent = card

		-- Icon
		local iconFrame = Instance.new("Frame")
		iconFrame.Size = UDim2.new(0, 60, 0, 60)
		iconFrame.Position = UDim2.new(0, 10, 0, 10)
		iconFrame.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
		iconFrame.BorderSizePixel = 0
		iconFrame.Parent = headerFrame

		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 8)
		iconCorner.Parent = iconFrame

		local iconStroke = Instance.new("UIStroke")
		iconStroke.Color = gamepass.color
		iconStroke.Thickness = 2
		iconStroke.Transparency = 0.4
		iconStroke.Parent = iconFrame

		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(0, 40, 0, 40)
		icon.Position = UDim2.new(0.5, -20, 0.5, -20)
		icon.BackgroundTransparency = 1
		icon.Image = gamepass.icon
		icon.ImageColor3 = gamepass.color
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Parent = iconFrame

		-- Title
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(0, 280, 0, 35)
		titleLabel.Position = UDim2.new(0, 80, 0, 5)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.Arcade
		titleLabel.Text = gamepass.name
		titleLabel.TextColor3 = gamepass.color
		titleLabel.TextSize = 24
		titleLabel.TextStrokeTransparency = 0.6
		titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextScaled = true
		titleLabel.Parent = headerFrame

		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -20, 0, 80)
		descLabel.Position = UDim2.new(0, 10, 0, 95)
		descLabel.BackgroundTransparency = 1
		descLabel.Font = Enum.Font.Arcade
		descLabel.Text = gamepass.description
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.TextSize = 14
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Parent = card

		-- Purchase/Owned button
		local purchaseBtn = Instance.new("TextButton")
		purchaseBtn.Size = UDim2.new(1, -20, 0, 40)
		purchaseBtn.Position = UDim2.new(0, 10, 1, -50)
		purchaseBtn.BorderSizePixel = 0
		purchaseBtn.Font = Enum.Font.Arcade
		purchaseBtn.TextSize = 20
		purchaseBtn.TextStrokeTransparency = 0.3
		purchaseBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		purchaseBtn.Text = "CHECKING..."
		purchaseBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		purchaseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		purchaseBtn.Active = false
		purchaseBtn.Parent = card

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 10)
		btnCorner.Parent = purchaseBtn

		-- Check ownership and update button
		checkGamepassOwnership(gamepass.id, function(ownsGamepass)
			if not purchaseBtn.Parent then return end -- Card was destroyed

			if ownsGamepass then
				-- Player owns this gamepass - SHOW ALREADY OWNED
				purchaseBtn.BackgroundColor3 = Color3.fromRGB(46, 125, 50) -- Green
				purchaseBtn.Text = "ALREADY OWNED!"
				purchaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				purchaseBtn.Active = false

				-- Update card styling to show it's owned
				cardStroke.Color = Color3.fromRGB(120, 255, 120)
				cardStroke.Transparency = 0.2
				iconStroke.Color = Color3.fromRGB(120, 255, 120)
				icon.ImageColor3 = Color3.fromRGB(120, 255, 120)
				titleLabel.TextColor3 = Color3.fromRGB(120, 255, 120)

				-- Add checkmark to button
				local checkmark = Instance.new("TextLabel")
				checkmark.Size = UDim2.new(0, 30, 0, 30)
				checkmark.Position = UDim2.new(0, 10, 0.5, -15)
				checkmark.BackgroundTransparency = 1
				checkmark.Font = Enum.Font.Arcade
				checkmark.Text = "?"
				checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
				checkmark.TextSize = 24
				checkmark.Parent = purchaseBtn

				-- Add owned badge
				local ownedBadge = Instance.new("Frame")
				ownedBadge.Size = UDim2.new(0, 80, 0, 30)
				ownedBadge.Position = UDim2.new(1, -88, 0, -10)
				ownedBadge.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
				ownedBadge.BorderSizePixel = 0
				ownedBadge.Rotation = 15
				ownedBadge.ZIndex = 5
				ownedBadge.Parent = card

				local ownedCorner = Instance.new("UICorner")
				ownedCorner.CornerRadius = UDim.new(0, 8)
				ownedCorner.Parent = ownedBadge

				local ownedText = Instance.new("TextLabel")
				ownedText.Size = UDim2.new(1, 0, 1, 0)
				ownedText.BackgroundTransparency = 1
				ownedText.Font = Enum.Font.Arcade
				ownedText.Text = "OWNED"
				ownedText.TextColor3 = Color3.fromRGB(255, 255, 255)
				ownedText.TextSize = 14
				ownedText.TextStrokeTransparency = 0.5
				ownedText.Parent = ownedBadge

				print("? " .. gamepass.name .. " - ALREADY OWNED!")
			else
				-- Player doesn't own gamepass - SHOW PURCHASE BUTTON
				purchaseBtn.BackgroundColor3 = gamepass.color
				purchaseBtn.Text = "BUY FOR " .. gamepass.price .. " R$"
				purchaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				purchaseBtn.Active = true

				-- Purchase functionality
				purchaseBtn.MouseButton1Click:Connect(function()
					if not purchaseBtn.Active then return end

					purchaseBtn.Text = "PURCHASING..."
					purchaseBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
					purchaseBtn.Active = false

					local success, error = pcall(function()
						MarketplaceService:PromptGamePassPurchase(player, gamepass.id)
					end)

					if not success then
						warn("Failed to prompt gamepass purchase:", error)
						purchaseBtn.Text = "ERROR - RETRY"
						purchaseBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)

						wait(2)
						purchaseBtn.Text = "BUY FOR " .. gamepass.price .. " R$"
						purchaseBtn.BackgroundColor3 = gamepass.color
						purchaseBtn.Active = true
					else
						wait(1)
						purchaseBtn.Text = "BUY FOR " .. gamepass.price .. " R$"
						purchaseBtn.BackgroundColor3 = gamepass.color
						purchaseBtn.Active = true
					end
				end)

				-- Hover effects for purchase button
				purchaseBtn.MouseEnter:Connect(function()
					if not purchaseBtn.Active then return end

					TweenService:Create(purchaseBtn, TweenInfo.new(0.2), {
						BackgroundColor3 = Color3.new(
							math.min(1, gamepass.color.R + 0.2),
							math.min(1, gamepass.color.G + 0.2),
							math.min(1, gamepass.color.B + 0.2)
						),
						TextSize = 22
					}):Play()
				end)

				purchaseBtn.MouseLeave:Connect(function()
					if not purchaseBtn.Active then return end

					TweenService:Create(purchaseBtn, TweenInfo.new(0.2), {
						BackgroundColor3 = gamepass.color,
						TextSize = 20
					}):Play()
				end)

				print("?? " .. gamepass.name .. " - Available for purchase")
			end
		end)
	end

	-- Update scroll canvas size
	local maxRow = 1 -- Since we have 2 rows (0 and 1)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, (maxRow + 1) * (cardHeight + padding) + padding)

	-- Entrance animation
	shopFrame.Size = UDim2.new(0, 0, 0, 0)
	shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	TweenService:Create(shopFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 800, 0, 600),
		Position = UDim2.new(0.5, -400, 0.5, -300)
	}):Play()

	-- Listen for gamepass purchase completion
	if MarketplaceService.PromptGamePassPurchaseFinished then
		local connection
		connection = MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(playerWhoSold, gamepassId, wasPurchased)
			if playerWhoSold == player and wasPurchased then
				print("?? Gamepass purchased! Refreshing shop...")
				-- Refresh the shop to show new ownership status
				task.delay(1, function()
					if shopFrame.Parent then
						closeCurrentPopup()
						task.delay(0.2, showGamepassShop)
					end
				end)
				connection:Disconnect()
			end
		end)
	end

	-- Listen for gamepass updates from your custom system
	local UpdateGamepassUI = ReplicatedStorage:FindFirstChild("UpdateGamepassUI")
	if UpdateGamepassUI then
		local connection
		connection = UpdateGamepassUI.OnClientEvent:Connect(function()
			if shopFrame.Parent then
				print("?? Received gamepass update event - refreshing shop...")
				closeCurrentPopup()
				task.delay(0.1, showGamepassShop)
				connection:Disconnect()
			end
		end)
	end

	print("??? Enhanced gamepass shop opened with ownership detection!")
end

-- ICON MENU section
local iconMenuContainer = Instance.new("Frame")
iconMenuContainer.Name = "IconMenuContainer"
iconMenuContainer.Size = UDim2.new(0, 38, 0, 200)
iconMenuContainer.Position = UDim2.new(0, 15, 0.5, -60)
iconMenuContainer.BackgroundTransparency = 1
iconMenuContainer.Parent = gui

local iconData = {
	{
		image = "rbxassetid://6966623635",
		label = "Collection",
		onClick = function()
			showCollectionPopup()
		end
	},
	{
		image = "rbxassetid://13793184787",
		label = "Quests",
		onClick = function()
			showQuestsPopup()
		end
	},
	{
		image = "rbxassetid://9405933217",
		label = "Shop",
		onClick = function()
			showGamepassShop()  -- This will now open our amazing shop!
		end
	},
	{
		image = "rbxassetid://6774409960",
		label = "Settings",
		onClick = function()
			if createBrainrotSettingsMenuWithTabs then
				createBrainrotSettingsMenuWithTabs().show()
			else
				warn("Settings menu not available yet")
			end
		end
	}
}

local iconRefs = {}
for i, data in ipairs(iconData) do
	local yOffset = (i - 1) * 44
	local iconRef = createIconButton(
		iconMenuContainer,
		UDim2.new(0, 0, 0, yOffset),
		data.image,
		data.label,
		data.onClick
	)
	iconRefs[data.label] = iconRef
end

-- BADGE ICON ON TOP OF COLLECTION ICON (keeping the Gears icon)
local badgeAsset = "rbxassetid://7485051715"
local badgeLabel = "Gears"

local inventoryIcon = iconRefs["Collection"]
if inventoryIcon then
	local badgeIcon = createIconButton(
		inventoryIcon,
		UDim2.new(0.5, -19, 0, -90),
		badgeAsset,
		badgeLabel,
		function()
			showInventoryPopup()
		end
	)
	local iconImage = badgeIcon:FindFirstChild("Icon")
	if iconImage then
		iconImage.ImageColor3 = Color3.fromRGB(255,255,120)
	end
end

-- ? ENHANCED GEAR SYSTEM MONITORING
local function setupGearSystemMonitoring()
	if not GetFormattedGearInventory then
		print("Gear system not available - skipping monitoring setup")
		return
	end

	local lastKnownGearState = {}

	local function monitorGearChanges()
		task.spawn(function()
			while task.wait(2) do
				local success, currentGears = pcall(function()
					return GetFormattedGearInventory:InvokeServer()
				end)

				if success and currentGears then
					local currentEquipped = nil
					for _, gear in ipairs(currentGears) do
						if gear.isEquipped then
							currentEquipped = gear.id
							break
						end
					end

					-- Check if equipped gear changed
					if lastKnownGearState.equippedGear ~= currentEquipped then
						print("Detected gear change through monitoring")
						lastKnownGearState.equippedGear = currentEquipped

						-- Update luck display
						if _G.UpdateLuckFromGear then
							task.delay(0.3, _G.UpdateLuckFromGear)
						elseif _G.ForceUpdateGearLuck then
							task.delay(0.3, _G.ForceUpdateGearLuck)
						end
					end
				end
			end
		end)
	end

	-- Start monitoring
	monitorGearChanges()

	-- Initial luck update
	local function updateLuckFromGear()
		local success, gears = pcall(function()
			return GetFormattedGearInventory:InvokeServer()
		end)

		if success and gears then
			local equippedGear = nil
			for _, gear in ipairs(gears) do
				if gear.isEquipped then
					equippedGear = gear
					break
				end
			end

			if equippedGear and _G.updateBadgeLuckBoost then
				_G.updateBadgeLuckBoost(equippedGear.luckBoost)
				print("Updated luck boost from equipped gear: +" .. equippedGear.luckBoost .. "%")
			end
		end
	end

	-- Run initial update
	task.delay(1, updateLuckFromGear)

	-- Create global function to manually update luck from gear
	_G.UpdateLuckFromGear = updateLuckFromGear
	

	print("Gear system monitoring setup completed successfully")
end

-- Add this near the end of the setupGearSystemMonitoring function:
local function setupAutoRefresh()
	-- Player tracking system
	Players.PlayerAdded:Connect(function(player)
		if player == game.Players.LocalPlayer then
			task.delay(2, function()
				if currentActiveTab == "gears" and currentPopup and currentPopup.Name == "InventoryPopupGui" then
					local contentFrame = currentPopup:FindFirstChild("ContentFrame")
					if contentFrame then
						updateGearInventoryDisplay(contentFrame, "")
					end
				end
			end)
		end
	end)

	-- Refresh when gear system updates
	if GearRemotes then
		local UpdateGearLuck = GearRemotes:FindFirstChild("UpdateGearLuck")
		if UpdateGearLuck then
			UpdateGearLuck.OnClientEvent:Connect(function()
				task.delay(0.5, function()
					if currentActiveTab == "gears" and currentPopup and currentPopup.Name == "InventoryPopupGui" then
						local contentFrame = currentPopup:FindFirstChild("ContentFrame")
						if contentFrame then
							updateGearInventoryDisplay(contentFrame, "")
						end
					end
				end)
			end)
		end
	end
end

setupAutoRefresh()
-- Initialize gear system monitoring
setupGearSystemMonitoring()

-- Create global function for manually refreshing gear display
_G.RefreshGearIcons = function()
	if currentActiveTab == "gears" and currentPopup and currentPopup.Name == "InventoryPopupGui" then
		-- Refresh the currently open inventory popup
		closeCurrentPopup()
		task.delay(0.1, showInventoryPopup)
	end
end

print("IconCreator loaded successfully with complete gear system integration!")