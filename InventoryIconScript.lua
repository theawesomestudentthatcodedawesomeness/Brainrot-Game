local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local BrainrotDefinitions = require(ReplicatedStorage:WaitForChild("BrainrotDefinitions"))

local function getBrainrotDisplayColor(brainrotName)
	local def = BrainrotDefinitions.Lookup[brainrotName]
	if not def then return Color3.fromRGB(255, 255, 255) end
	return def.titleColor or def.color or Color3.fromRGB(255, 255, 255)
end

if playerGui:FindFirstChild("InventoryIconGui") then
	playerGui.InventoryIconGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "InventoryIconGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = playerGui

local currentInventory = {}
local selectedItem = nil
local inventoryOpen = false
local updateInventoryDisplay
local createItemTile
local addCornerBrackets

-- Wait for inventory system
local inventoryRemotes = nil
spawn(function()
	local maxWait = 30
	local waited = 0
	while not inventoryRemotes and waited < maxWait do
		inventoryRemotes = ReplicatedStorage:FindFirstChild("InventoryRemotes")
		if not inventoryRemotes then
			wait(1)
			waited = waited + 1
		end
	end

	if inventoryRemotes then
		local updateEvent = inventoryRemotes:WaitForChild("UpdateInventory", 10)
		if updateEvent then
			updateEvent.OnClientEvent:Connect(function(inventory)
				if inventory and type(inventory) == "table" then
					currentInventory = inventory
					if inventoryOpen and updateInventoryDisplay then
						updateInventoryDisplay()
					end
				else
					currentInventory = {}
				end
			end)
		end
	end
end)

addCornerBrackets = function(parent, color)
	local thickness = 1
	local length = 6
	local function addCorner(px, py)
		local f1 = Instance.new("Frame")
		f1.Size = UDim2.new(0, length, 0, thickness)
		f1.Position = UDim2.new(px, px == 0 and 0 or -length, py, py == 0 and 0 or -thickness)
		f1.BackgroundColor3 = color
		f1.BorderSizePixel = 0
		f1.Parent = parent

		local f2 = Instance.new("Frame")
		f2.Size = UDim2.new(0, thickness, 0, length)
		f2.Position = UDim2.new(px, px == 0 and 0 or -thickness, py, py == 0 and 0 or -length)
		f2.BackgroundColor3 = color
		f2.BorderSizePixel = 0
		f2.Parent = parent
	end
	addCorner(0,0)
	addCorner(1,0)
	addCorner(0,1)
	addCorner(1,1)
end

local function toggleRollButtons(hide)
	local bottomBarGui = playerGui:FindFirstChild("BottomBarGui")
	if bottomBarGui then
		local buttonBar = bottomBarGui:FindFirstChild("ButtonBar")
		if buttonBar then
			buttonBar.Visible = not hide
		end
	end
end

createItemTile = function(itemData, parent)
	if not itemData or not parent then return nil end

	local def = BrainrotDefinitions.Lookup[itemData.name]
	local odds = def and def.odds or itemData.odds or ""
	local rarity = def and def.rarity or itemData.rarity or "UNKNOWN"
	local color = def and def.color or itemData.color or Color3.fromRGB(200,200,200)
	local description = def and def.description or "No description available."
	local displayColor = getBrainrotDisplayColor(itemData.name)

	local tile = Instance.new("Frame")
	tile.Name = "ItemTile_" .. (itemData.name and itemData.name:gsub("%s+", "_") or "Unknown")
	tile.Size = UDim2.new(0, 140, 0, 140)
	tile.BackgroundColor3 = color
	tile.BackgroundTransparency = 0.7
	tile.BorderSizePixel = 0

	addCornerBrackets(tile, color)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ItemNameLabel"
	nameLabel.Size = UDim2.new(0.9, 0, 0.27, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Arcade
	nameLabel.Text = itemData.name or "Unknown Item"
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.TextWrapped = true
	nameLabel.Parent = tile

	local oddsLabel = Instance.new("TextLabel")
	oddsLabel.Name = "OddsLabel"
	oddsLabel.Size = UDim2.new(0.9, 0, 0.14, 0)
	oddsLabel.Position = UDim2.new(0.05, 0, 0.32, 0)
	oddsLabel.BackgroundTransparency = 1
	oddsLabel.Font = Enum.Font.Arcade
	oddsLabel.Text = odds ~= "" and ("1 in " .. tostring(odds)) or ""
	oddsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	oddsLabel.TextStrokeTransparency = 0.6
	oddsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	oddsLabel.TextScaled = true
	oddsLabel.TextWrapped = true
	oddsLabel.Parent = tile

	if itemData.count and itemData.count > 1 then
		local countLabel = Instance.new("TextLabel")
		countLabel.Name = "CountLabel"
		countLabel.Size = UDim2.new(0, 30, 0, 30)
		countLabel.Position = UDim2.new(1, -35, 0, 5)
		countLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		countLabel.BackgroundTransparency = 0.2
		countLabel.BorderSizePixel = 0
		countLabel.Font = Enum.Font.Arcade
		countLabel.Text = tostring(itemData.count)
		countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		countLabel.TextStrokeTransparency = 0.3
		countLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		countLabel.TextScaled = true
		countLabel.Parent = tile

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = countLabel
	end

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(0.9, 0, 0.22, 0)
	rarityLabel.Position = UDim2.new(0.05, 0, 0.48, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.Arcade
	rarityLabel.Text = rarity:upper()
	rarityLabel.TextColor3 = displayColor
	rarityLabel.TextStrokeTransparency = 0.3
	rarityLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rarityLabel.TextScaled = true
	rarityLabel.Parent = tile

	local clickButton = Instance.new("TextButton")
	clickButton.Name = "ClickButton"
	clickButton.Size = UDim2.new(1, 0, 1, 0)
	clickButton.BackgroundTransparency = 1
	clickButton.Text = ""
	clickButton.Parent = tile

	-- Store brainrot name as attribute for equip button
	clickButton:SetAttribute("BrainrotName", itemData.name)

	clickButton.MouseButton1Click:Connect(function()
		if selectedItem then
			selectedItem.BackgroundTransparency = 0.7
		end
		selectedItem = tile
		tile.BackgroundTransparency = 0.3

		-- Update preview panels
		local inventoryMenu = gui:FindFirstChild("InventoryMenu")
		if inventoryMenu then
			local previewStatsLabel, descLabel
			for _, d in ipairs(inventoryMenu:GetDescendants()) do
				if d:IsA("TextLabel") and d.Name == "PreviewStatsLabel" then
					previewStatsLabel = d
				elseif d:IsA("TextLabel") and d.Name == "DescriptionLabel" then
					descLabel = d
				end
			end

			if previewStatsLabel and def then
				previewStatsLabel.Text = string.format("%s\n1 in %s\n%s", def.name, tostring(def.odds), string.upper(def.rarity))
				previewStatsLabel.TextColor3 = getBrainrotDisplayColor(def.name)
			end

			if descLabel and def then
				descLabel.Text = description
			end
		end
	end)

	tile.Parent = parent
	return tile
end

updateInventoryDisplay = function(searchTerm)
	searchTerm = searchTerm or ""

	local inventoryMenu = gui:FindFirstChild("InventoryMenu")
	if not inventoryMenu then return end

	local inventoryGrid = inventoryMenu:FindFirstChild("ScrollingFrame")
	if not inventoryGrid then return end

	-- Clear existing items
	for _, child in pairs(inventoryGrid:GetChildren()) do
		if child then
			child:Destroy()
		end
	end

	-- Filter and display items
	local filteredItems = {}
	if currentInventory and type(currentInventory) == "table" then
		for _, item in pairs(currentInventory) do
			if item and item.name then
				if searchTerm == "" or item.name:lower():find(searchTerm:lower()) then
					table.insert(filteredItems, item)
				end
			end
		end
	end

	if #filteredItems > 0 then
		local gridWidth = inventoryGrid.AbsoluteSize.X
		if gridWidth <= 0 then
			spawn(function()
				wait(0.5)
				if updateInventoryDisplay then
					updateInventoryDisplay(searchTerm)
				end
			end)
			return
		end

		local tileSize = 140
		local padding = 15
		local tileSizeWithPadding = tileSize + padding
		local columns = math.floor(gridWidth / tileSizeWithPadding)
		columns = math.max(1, columns)

		for i, itemData in pairs(filteredItems) do
			local tile = createItemTile(itemData, inventoryGrid)
			if tile then
				local column = (i - 1) % columns
				local row = math.floor((i - 1) / columns)

				local xPos = column * tileSizeWithPadding + padding / 2
				local yPos = row * tileSizeWithPadding + padding / 2

				tile.Position = UDim2.new(0, xPos, 0, yPos)
			end
		end

		local rows = math.ceil(#filteredItems / columns)
		local contentHeight = rows * tileSizeWithPadding + padding
		inventoryGrid.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
	else
		inventoryGrid.CanvasSize = UDim2.new(0, 0, 0, 0)

		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "EmptyMessage"
		emptyLabel.Size = UDim2.new(1, -20, 0, 100)
		emptyLabel.Position = UDim2.new(0, 10, 0, 50)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Font = Enum.Font.Arcade
		emptyLabel.Text = "No brainrots found...\nGo roll some!"
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.TextStrokeTransparency = 0.5
		emptyLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		emptyLabel.TextScaled = true
		emptyLabel.TextWrapped = true
		emptyLabel.Parent = inventoryGrid
	end
end

-- Create inventory button
local inventoryBtn = Instance.new("TextButton")
inventoryBtn.Name = "InventoryButton"
inventoryBtn.Size = UDim2.new(0, 38, 0, 38)
inventoryBtn.Position = UDim2.new(0, 15, 0.5, -104)
inventoryBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 45)
inventoryBtn.BackgroundTransparency = 0.1
inventoryBtn.BorderSizePixel = 0
inventoryBtn.Text = ""
inventoryBtn.Parent = gui
inventoryBtn.AutoButtonColor = false

addCornerBrackets(inventoryBtn, Color3.fromRGB(200, 200, 200))

local inventoryIcon = Instance.new("ImageLabel")
inventoryIcon.Name = "InventoryIcon"
inventoryIcon.Size = UDim2.new(0, 28, 0, 28)
inventoryIcon.Position = UDim2.new(0.5, -14, 0.5, -14)
inventoryIcon.BackgroundTransparency = 1
inventoryIcon.Image = "http://www.roblox.com/asset/?id=124233015832617"
inventoryIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
inventoryIcon.ScaleType = Enum.ScaleType.Fit
inventoryIcon.ImageTransparency = 0
inventoryIcon.BorderSizePixel = 0
inventoryIcon.Parent = inventoryBtn

local hoverLabel = Instance.new("Frame")
hoverLabel.Name = "HoverLabel"
hoverLabel.Size = UDim2.new(0, 0, 0, 28)
hoverLabel.Position = UDim2.new(1, 8, 0.5, -14)
hoverLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
hoverLabel.BackgroundTransparency = 0.1
hoverLabel.BorderSizePixel = 0
hoverLabel.Visible = false
hoverLabel.Parent = inventoryBtn

addCornerBrackets(hoverLabel, Color3.fromRGB(200, 200, 200))

local hoverText = Instance.new("TextLabel")
hoverText.Name = "LabelText"
hoverText.Size = UDim2.new(1, -8, 1, 0)
hoverText.Position = UDim2.new(0, 4, 0, 0)
hoverText.BackgroundTransparency = 1
hoverText.Font = Enum.Font.Arcade
hoverText.Text = "Inventory"
hoverText.TextColor3 = Color3.fromRGB(255, 255, 255)
hoverText.TextStrokeTransparency = 0.3
hoverText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
hoverText.TextScaled = true
hoverText.TextXAlignment = Enum.TextXAlignment.Left
hoverText.Parent = hoverLabel

local function createInventoryMenu()
	local existingMenu = gui:FindFirstChild("InventoryMenu")
	if existingMenu then
		existingMenu:Destroy()
		toggleRollButtons(false)
		inventoryOpen = false
		return false
	end

	toggleRollButtons(true)
	inventoryOpen = true

	local inventoryMenu = Instance.new("Frame")
	inventoryMenu.Name = "InventoryMenu"
	inventoryMenu.Size = UDim2.new(0, 800, 0, 600)
	inventoryMenu.Position = UDim2.new(0.5, -400, 0.5, -300)
	inventoryMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	inventoryMenu.BackgroundTransparency = 0.1
	inventoryMenu.BorderSizePixel = 0
	inventoryMenu.Parent = gui

	local function addLargeCornerBrackets(parent, color)
		local thickness = 2
		local length = 15
		local function addCorner(px, py)
			local f1 = Instance.new("Frame")
			f1.Size = UDim2.new(0, length, 0, thickness)
			f1.Position = UDim2.new(px, px == 0 and 0 or -length, py, py == 0 and 0 or -thickness)
			f1.BackgroundColor3 = color
			f1.BorderSizePixel = 0
			f1.Parent = parent

			local f2 = Instance.new("Frame")
			f2.Size = UDim2.new(0, thickness, 0, length)
			f2.Position = UDim2.new(px, px == 0 and 0 or -thickness, py, py == 0 and 0 or -length)
			f2.BackgroundColor3 = color
			f2.BorderSizePixel = 0
			f2.Parent = parent
		end
		addCorner(0,0)
		addCorner(1,0)
		addCorner(0,1)
		addCorner(1,1)
	end

	addLargeCornerBrackets(inventoryMenu, Color3.fromRGB(200, 200, 200))

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(35, 40, 35)
	titleBar.BackgroundTransparency = 0.2
	titleBar.BorderSizePixel = 0
	titleBar.Parent = inventoryMenu

	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(0.8, 0, 1, 0)
	titleText.Position = UDim2.new(0.1, 0, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.Font = Enum.Font.Arcade
	titleText.Text = "Brainrot Storage"
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText.TextStrokeTransparency = 0.3
	titleText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleText.TextScaled = true
	titleText.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -45, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
	closeBtn.BackgroundTransparency = 0.2
	closeBtn.BorderSizePixel = 0
	closeBtn.Font = Enum.Font.Arcade
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextStrokeTransparency = 0.3
	closeBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	closeBtn.TextScaled = true
	closeBtn.Parent = titleBar

	addLargeCornerBrackets(closeBtn, Color3.fromRGB(200, 100, 100))

	-- Tab frame
	local tabFrame = Instance.new("Frame")
	tabFrame.Size = UDim2.new(1, 0, 0, 40)
	tabFrame.Position = UDim2.new(0, 0, 0, 55)
	tabFrame.BackgroundTransparency = 1
	tabFrame.Parent = inventoryMenu

	local savedBrainrotsTab = Instance.new("TextButton")
	savedBrainrotsTab.Size = UDim2.new(1, -20, 1, 0)
	savedBrainrotsTab.Position = UDim2.new(0, 10, 0, 0)
	savedBrainrotsTab.BackgroundColor3 = Color3.fromRGB(35, 40, 35)
	savedBrainrotsTab.BackgroundTransparency = 0.2
	savedBrainrotsTab.BorderSizePixel = 0
	savedBrainrotsTab.Font = Enum.Font.Arcade
	savedBrainrotsTab.Text = "Saved Brainrots"
	savedBrainrotsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	savedBrainrotsTab.TextStrokeTransparency = 0.3
	savedBrainrotsTab.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	savedBrainrotsTab.TextScaled = true
	savedBrainrotsTab.Parent = tabFrame

	addLargeCornerBrackets(savedBrainrotsTab, Color3.fromRGB(200, 200, 200))

	-- Search frame
	local searchFrame = Instance.new("Frame")
	searchFrame.Size = UDim2.new(1, -20, 0, 35)
	searchFrame.Position = UDim2.new(0, 10, 0, 105)
	searchFrame.BackgroundColor3 = Color3.fromRGB(35, 40, 35)
	searchFrame.BackgroundTransparency = 0.2
	searchFrame.BorderSizePixel = 0
	searchFrame.Parent = inventoryMenu

	addLargeCornerBrackets(searchFrame, Color3.fromRGB(200, 200, 200))

	local searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1, -20, 1, -10)
	searchBox.Position = UDim2.new(0, 10, 0, 5)
	searchBox.BackgroundTransparency = 1
	searchBox.Font = Enum.Font.Arcade
	searchBox.PlaceholderText = "Search..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	searchBox.Text = ""
	searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	searchBox.TextStrokeTransparency = 0.3
	searchBox.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	searchBox.TextScaled = true
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.Parent = searchFrame

	-- Left panel
	local leftPanel = Instance.new("Frame")
	leftPanel.Size = UDim2.new(0.3, -10, 0, 420)
	leftPanel.Position = UDim2.new(0, 10, 0, 150)
	leftPanel.BackgroundColor3 = Color3.fromRGB(35, 40, 35)
	leftPanel.BackgroundTransparency = 0.2
	leftPanel.BorderSizePixel = 0
	leftPanel.Parent = inventoryMenu

	addLargeCornerBrackets(leftPanel, Color3.fromRGB(200, 200, 200))

	-- Preview frame
	local previewFrame = Instance.new("Frame")
	previewFrame.Size = UDim2.new(1, -20, 0, 180)
	previewFrame.Position = UDim2.new(0, 10, 0, 10)
	previewFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	previewFrame.BackgroundTransparency = 0.3
	previewFrame.BorderSizePixel = 0
	previewFrame.Parent = leftPanel

	addLargeCornerBrackets(previewFrame, Color3.fromRGB(150, 150, 150))

	local previewStatsLabel = Instance.new("TextLabel")
	previewStatsLabel.Name = "PreviewStatsLabel"
	previewStatsLabel.Size = UDim2.new(1, -10, 0, 80)
	previewStatsLabel.Position = UDim2.new(0, 5, 0, 5)
	previewStatsLabel.BackgroundTransparency = 1
	previewStatsLabel.Font = Enum.Font.Arcade
	previewStatsLabel.Text = ""
	previewStatsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	previewStatsLabel.TextStrokeTransparency = 0.3
	previewStatsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	previewStatsLabel.TextScaled = true
	previewStatsLabel.TextWrapped = true
	previewStatsLabel.TextXAlignment = Enum.TextXAlignment.Center
	previewStatsLabel.TextYAlignment = Enum.TextYAlignment.Top
	previewStatsLabel.Parent = previewFrame

	-- Info frame
	local infoFrame = Instance.new("Frame")
	infoFrame.Size = UDim2.new(1, -20, 0, 150)
	infoFrame.Position = UDim2.new(0, 10, 0, 200)
	infoFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	infoFrame.BackgroundTransparency = 0.3
	infoFrame.BorderSizePixel = 0
	infoFrame.Parent = leftPanel

	addLargeCornerBrackets(infoFrame, Color3.fromRGB(150, 150, 150))

	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "DescriptionLabel"
	descLabel.Size = UDim2.new(1, -10, 0, 135)
	descLabel.Position = UDim2.new(0, 5, 0, 5)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Arcade
	descLabel.Text = "Select a brainrot to see its description."
	descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	descLabel.TextStrokeTransparency = 0.5
	descLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	descLabel.TextScaled = true
	descLabel.TextWrapped = true
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Parent = infoFrame

	-- Equip button (FIXED)
	local equipBtn = Instance.new("TextButton")
	equipBtn.Size = UDim2.new(1, -20, 0, 35)
	equipBtn.Position = UDim2.new(0, 10, 0, 360)
	equipBtn.BackgroundColor3 = Color3.fromRGB(25, 60, 25)
	equipBtn.BackgroundTransparency = 0.2
	equipBtn.BorderSizePixel = 0
	equipBtn.Font = Enum.Font.Arcade
	equipBtn.Text = "Equip as Title"
	equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	equipBtn.TextStrokeTransparency = 0.3
	equipBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	equipBtn.TextScaled = true
	equipBtn.Parent = leftPanel

	addLargeCornerBrackets(equipBtn, Color3.fromRGB(100, 200, 100))

	-- Erase button
	local eraseBtn = Instance.new("TextButton")
	eraseBtn.Size = UDim2.new(1, -20, 0, 35)
	eraseBtn.Position = UDim2.new(0, 10, 0, 405)
	eraseBtn.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
	eraseBtn.BackgroundTransparency = 0.2
	eraseBtn.BorderSizePixel = 0
	eraseBtn.Font = Enum.Font.Arcade
	eraseBtn.Text = "Erase"
	eraseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	eraseBtn.TextStrokeTransparency = 0.3
	eraseBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	eraseBtn.TextScaled = true
	eraseBtn.Parent = leftPanel

	addLargeCornerBrackets(eraseBtn, Color3.fromRGB(200, 100, 100))

	-- Inventory grid
	local inventoryGrid = Instance.new("ScrollingFrame")
	inventoryGrid.Name = "ScrollingFrame"
	inventoryGrid.Size = UDim2.new(0.7, -20, 0, 455)
	inventoryGrid.Position = UDim2.new(0.3, 10, 0, 150)
	inventoryGrid.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	inventoryGrid.BackgroundTransparency = 0.3
	inventoryGrid.BorderSizePixel = 0
	inventoryGrid.ScrollBarThickness = 12
	inventoryGrid.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
	inventoryGrid.ScrollBarImageTransparency = 0.2
	inventoryGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
	inventoryGrid.Parent = inventoryMenu

	addLargeCornerBrackets(inventoryGrid, Color3.fromRGB(150, 150, 150))

	-- Connect search functionality
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if updateInventoryDisplay then
			pcall(function()
				updateInventoryDisplay(searchBox.Text)
			end)
		end
	end)

	-- Connect close button
	closeBtn.MouseButton1Click:Connect(function()
		inventoryMenu:Destroy()
		inventoryOpen = false
		toggleRollButtons(false)
	end)

	-- FIXED: Connect equip button to proper server event
	equipBtn.MouseButton1Click:Connect(function()
		if selectedItem and inventoryRemotes then
			local nameLabel = selectedItem:FindFirstChild("ItemNameLabel")
			if nameLabel then
				local itemName = nameLabel.Text
				local def = BrainrotDefinitions.Lookup[itemName]
				if def then
					-- Fire the proper equip event to server
					local equipEvent = inventoryRemotes:FindFirstChild("EquipBrainrot")
					if equipEvent then
						equipEvent:FireServer(itemName)
						print("?? Equipped brainrot as title: " .. itemName)

						-- Visual feedback
						equipBtn.Text = "Equipped!"
						equipBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
						spawn(function()
							wait(1)
							if equipBtn and equipBtn.Parent then
								equipBtn.Text = "Equip as Title"
								equipBtn.BackgroundColor3 = Color3.fromRGB(25, 60, 25)
							end
						end)
					else
						warn("? EquipBrainrot event not found in inventory remotes!")
					end
				else
					warn("? Brainrot definition not found: " .. itemName)
				end
			end
		else
			print("? No item selected or inventory system not ready!")
		end
	end)

	-- Connect erase button
	eraseBtn.MouseButton1Click:Connect(function()
		if selectedItem and inventoryRemotes then
			local nameLabel = selectedItem:FindFirstChild("ItemNameLabel")
			if nameLabel then
				local itemName = nameLabel.Text
				local removeEvent = inventoryRemotes:FindFirstChild("RemoveItem")
				if removeEvent then
					removeEvent:FireServer(itemName, 1)
					selectedItem = nil
					print("??? Erased: " .. itemName)
				end
			end
		end
	end)

	-- Load inventory display
	spawn(function()
		wait(0.1)
		if updateInventoryDisplay then
			pcall(function()
				updateInventoryDisplay()
			end)
		end
	end)

	return true
end

-- Button hover effects and click handling
local buttonCooldown = false

inventoryBtn.MouseEnter:Connect(function()
	if not buttonCooldown then
		inventoryIcon.ImageColor3 = Color3.fromRGB(255, 255, 100)
		hoverLabel.Visible = true

		local textService = game:GetService("TextService")
		local textSize = textService:GetTextSize("Inventory", 18, Enum.Font.Arcade, Vector2.new(200, 28))
		local labelWidth = math.max(80, textSize.X + 12)

		local showTween = TweenService:Create(hoverLabel, 
			TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
			{Size = UDim2.new(0, labelWidth, 0, 28)}
		)
		showTween:Play()

		local scaleTween = TweenService:Create(inventoryBtn, 
			TweenInfo.new(0.15, Enum.EasingStyle.Quad), 
			{Size = UDim2.new(0, 42, 0, 42)}
		)
		scaleTween:Play()
	end
end)

inventoryBtn.MouseLeave:Connect(function()
	if not buttonCooldown then
		inventoryIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)

		local hideTween = TweenService:Create(hoverLabel, 
			TweenInfo.new(0.15, Enum.EasingStyle.Quad), 
			{Size = UDim2.new(0, 0, 0, 28)}
		)
		hideTween:Play()

		hideTween.Completed:Connect(function()
			hoverLabel.Visible = false
		end)

		local scaleTween = TweenService:Create(inventoryBtn, 
			TweenInfo.new(0.15, Enum.EasingStyle.Quad), 
			{Size = UDim2.new(0, 38, 0, 38)}
		)
		scaleTween:Play()
	end
end)

inventoryBtn.MouseButton1Click:Connect(function()
	if buttonCooldown then return end

	buttonCooldown = true
	inventoryIcon.ImageColor3 = Color3.fromRGB(150, 150, 150)

	local menuOpened = createInventoryMenu()

	spawn(function()
		wait(1)
		buttonCooldown = false
		inventoryIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end)
end)

print("?? FIXED Inventory GUI: Equip as Title now works properly!")