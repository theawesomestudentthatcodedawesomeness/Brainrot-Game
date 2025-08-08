local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Wait for necessary remotes with error handling
local GearRemotes = ReplicatedStorage:WaitForChild("GearRemotes", 10)
if not GearRemotes then
	warn("GearRemotes not found, aborting GearInventoryIntegration")
	return
end

local GetFormattedGearInventory = GearRemotes:WaitForChild("GetFormattedGearInventory", 10)
local EquipGear = GearRemotes:FindFirstChild("EquipGear")
local UnequipGear = GearRemotes:FindFirstChild("UnequipGear")

-- Validate critical remotes
if not GetFormattedGearInventory or not GetFormattedGearInventory:IsA("RemoteFunction") then
	warn("GetFormattedGearInventory not found or invalid type")
	return
end

-- Function to get the exact gear container based on your UI structure
local function getGearContainer()
	-- Wait for the inventory GUI
	local success, InventoryGui = pcall(function()
		return PlayerGui:WaitForChild("InventoryGui", 10)
	end)

	if not success or not InventoryGui then
		warn("InventoryGui not found in PlayerGui")
		return nil
	end

	print("DEBUG: Found InventoryGui, structure analysis:")

	-- Print top-level children to understand structure
	print("Top-level children of InventoryGui:")
	for _, child in pairs(InventoryGui:GetChildren()) do
		print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
	end

	-- DIRECT TARGETING - Based on your specific UI structure
	-- First try to find the most common tab names
	local gearsTab = InventoryGui:FindFirstChild("GearsTab", true) or 
		InventoryGui:FindFirstChild("GearTab", true)

	if gearsTab then
		print("Found gear tab directly: " .. gearsTab:GetFullName())
		return gearsTab
	end

	-- Look for the tab system
	local tabSystem = InventoryGui:FindFirstChild("TabSystem") or 
		InventoryGui:FindFirstChild("Tabs") or
		InventoryGui:FindFirstChild("TabsFrame")

	if tabSystem then
		print("Found tab system: " .. tabSystem:GetFullName())
		-- Look for gear tab in tab system
		for _, tab in pairs(tabSystem:GetDescendants()) do
			if tab:IsA("Frame") or tab:IsA("ScrollingFrame") then
				if string.lower(tab.Name):find("gear") then
					print("Found gear tab in tab system: " .. tab:GetFullName())
					return tab
				end
			end
		end
	end

	-- SPECIFICALLY FOR YOUR UI - Look at structure from screenshots
	-- Look for items container or main content area
	local mainContent = InventoryGui:FindFirstChild("MainContent") or
		InventoryGui:FindFirstChild("Content") or
		InventoryGui:FindFirstChild("ItemsContainer")

	if mainContent then
		print("Found main content area: " .. mainContent:GetFullName())

		-- Try to find something that looks like a tab content area
		for _, child in pairs(mainContent:GetChildren()) do
			if child:IsA("Frame") or child:IsA("ScrollingFrame") then
				print("  Checking potential content frame: " .. child.Name)

				-- If we find something that's visible and meant for gears
				if child.Visible and (
					string.lower(child.Name):find("gear") or
						child.Name == "GearsContent" or
						child.Name == "GearItems") then
					print("  Found gear content frame: " .. child:GetFullName())
					return child
				end
			end
		end
	end

	-- LAST RESORT: Create a new frame to hold gears
	print("Creating a new frame to hold gears")

	-- Find where to position it - look for Items tab or main content area
	local itemsTab = nil
	for _, obj in pairs(InventoryGui:GetDescendants()) do
		if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
			if obj.Name == "Items" or obj.Name == "ItemsTab" or obj.Name == "ItemsFrame" then
				itemsTab = obj
				break
			end
		end
	end

	if itemsTab then
		-- Create a gear tab beside the items tab
		local gearsFrame = Instance.new("ScrollingFrame")
		gearsFrame.Name = "GearsFrame"
		gearsFrame.Size = itemsTab.Size
		gearsFrame.Position = itemsTab.Position
		gearsFrame.BackgroundColor3 = itemsTab.BackgroundColor3
		gearsFrame.BorderSizePixel = 0
		gearsFrame.ScrollBarThickness = 6
		gearsFrame.Parent = itemsTab.Parent

		-- Make sure the items tab is visible and our new tab is initially invisible
		if itemsTab.Visible then
			gearsFrame.Visible = false
		else
			gearsFrame.Visible = true
		end

		-- Find the tab buttons and clone one for gears
		local itemsButton = nil
		for _, obj in pairs(InventoryGui:GetDescendants()) do
			if obj:IsA("TextButton") and (obj.Name == "ItemsButton" or string.find(string.lower(obj.Name), "item")) then
				itemsButton = obj
				break
			end
		end

		if itemsButton then
			local success2, gearsButton = pcall(function()
				local button = itemsButton:Clone()
				button.Name = "GearsButton"
				button.Text = "Gears"
				button.Parent = itemsButton.Parent
				return button
			end)

			if success2 and gearsButton then
				-- Position the button next to the items button
				gearsButton.Position = UDim2.new(itemsButton.Position.X.Scale + 1, 0, itemsButton.Position.Y.Scale, 0)

				-- Connect button functionality
				gearsButton.MouseButton1Click:Connect(function()
					-- Hide all sibling tabs
					for _, child in pairs(itemsTab.Parent:GetChildren()) do
						if child:IsA("Frame") or child:IsA("ScrollingFrame") then
							child.Visible = false
						end
					end

					-- Show the gears frame
					gearsFrame.Visible = true

					-- Update gear display
					pcall(refreshGearDisplay)
				end)

				-- Make items button hide gears tab
				itemsButton.MouseButton1Click:Connect(function()
					gearsFrame.Visible = false
					itemsTab.Visible = true
				end)
			end
		end

		print("Created new gear frame: " .. gearsFrame:GetFullName())
		return gearsFrame
	end

	-- If we can't find or create a tab, just insert a frame directly into the inventory GUI
	local gearsFrame = Instance.new("Frame")
	gearsFrame.Name = "GearsFrame"
	gearsFrame.Size = UDim2.new(1, -20, 1, -100)
	gearsFrame.Position = UDim2.new(0, 10, 0, 50)
	gearsFrame.BackgroundTransparency = 0.8
	gearsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	gearsFrame.BorderSizePixel = 0
	gearsFrame.Visible = true
	gearsFrame.Parent = InventoryGui

	print("Created fallback gear frame: " .. gearsFrame:GetFullName())
	return gearsFrame
end

-- Function to refresh the gears in the inventory UI
function refreshGearDisplay() -- ? Made global function with error handling
	local success, result = pcall(function()
		-- Get the gear container
		local GearsTab = getGearContainer()

		if not GearsTab then 
			warn("Could not find or create gears container in inventory GUI")
			return 
		end

		print("DEBUG: Using gear container: " .. GearsTab:GetFullName())

		-- Clear existing gear displays
		for _, child in pairs(GearsTab:GetChildren()) do
			if child:IsA("Frame") and child.Name:match("GearItem_") then
				child:Destroy()
			end
		end

		-- Get formatted gear data with error handling
		print("DEBUG: Requesting formatted gear data from server")
		local success2, gears = pcall(function()
			return GetFormattedGearInventory:InvokeServer()
		end)

		if not success2 or not gears then
			warn("Failed to get gear data:", tostring(gears))
			return
		end

		print("DEBUG: Received " .. #gears .. " gears from server")

		if #gears == 0 then
			-- Create "No gears" message
			local noGearsLabel = GearsTab:FindFirstChild("NoGearsLabel")
			if not noGearsLabel then
				noGearsLabel = Instance.new("TextLabel")
				noGearsLabel.Name = "NoGearsLabel"
				noGearsLabel.Size = UDim2.new(1, -20, 0, 100)
				noGearsLabel.Position = UDim2.new(0, 10, 0.3, 0)
				noGearsLabel.BackgroundTransparency = 1
				noGearsLabel.Font = Enum.Font.Arcade
				noGearsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				noGearsLabel.TextSize = 20
				noGearsLabel.Text = "No gears found...\nCraft some at the Gear Merchant!"
				noGearsLabel.TextWrapped = true
				noGearsLabel.Parent = GearsTab
			end
			print("DEBUG: No gears found, displaying empty message")
			return
		else
			-- Remove "No gears" message if it exists
			local noGearsLabel = GearsTab:FindFirstChild("NoGearsLabel")
			if noGearsLabel then
				noGearsLabel:Destroy()
			end
		end

		-- Display each gear
		for i, gear in ipairs(gears) do
			print("DEBUG: Creating UI for gear " .. tostring(gear.id) .. " - " .. tostring(gear.name))

			-- Create gear item frame
			local gearFrame = Instance.new("Frame")
			gearFrame.Name = "GearItem_" .. tostring(gear.id)
			gearFrame.Size = UDim2.new(1, -20, 0, 60)
			gearFrame.Position = UDim2.new(0, 10, 0, (i-1) * 70 + 10)
			gearFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
			gearFrame.BorderSizePixel = 0

			-- Add corners
			local function addCorner(pos, size, color)
				local corner = Instance.new("Frame")
				corner.Size = size
				corner.Position = pos
				corner.BackgroundColor3 = color or gear.color or Color3.fromRGB(200, 200, 200)
				corner.BorderSizePixel = 0
				corner.Parent = gearFrame
			end

			-- Add corners safely
			pcall(addCorner, UDim2.new(0, 0, 0, 0), UDim2.new(0, 10, 0, 2))
			pcall(addCorner, UDim2.new(0, 0, 0, 0), UDim2.new(0, 2, 0, 10))
			pcall(addCorner, UDim2.new(1, -10, 0, 0), UDim2.new(0, 10, 0, 2))
			pcall(addCorner, UDim2.new(1, -2, 0, 0), UDim2.new(0, 2, 0, 10))
			pcall(addCorner, UDim2.new(0, 0, 1, -2), UDim2.new(0, 10, 0, 2))
			pcall(addCorner, UDim2.new(0, 0, 1, -10), UDim2.new(0, 2, 0, 10))
			pcall(addCorner, UDim2.new(1, -10, 1, -2), UDim2.new(0, 10, 0, 2))
			pcall(addCorner, UDim2.new(1, -2, 1, -10), UDim2.new(0, 2, 0, 10))

			-- Icon (if available)
			if gear.icon and gear.icon ~= "rbxassetid://0" then
				local icon = Instance.new("ImageLabel")
				icon.Size = UDim2.new(0, 40, 0, 40)
				icon.Position = UDim2.new(0, 10, 0.5, -20)
				icon.BackgroundTransparency = 1
				icon.Image = gear.icon
				icon.Parent = gearFrame
			end

			-- Gear name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.6, -60, 0, 25)
			nameLabel.Position = UDim2.new(0, 60, 0, 5)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Font = Enum.Font.Arcade
			nameLabel.Text = tostring(gear.name or "Unknown Gear")
			nameLabel.TextColor3 = gear.color or Color3.fromRGB(255, 255, 255)
			nameLabel.TextSize = 18
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = gearFrame

			-- Gear stats
			local statsLabel = Instance.new("TextLabel")
			statsLabel.Size = UDim2.new(0.6, -60, 0, 20)
			statsLabel.Position = UDim2.new(0, 60, 0, 30)
			statsLabel.BackgroundTransparency = 1
			statsLabel.Font = Enum.Font.Arcade
			statsLabel.Text = "+" .. tostring(gear.luckBoost or 0) .. "% Luck"

			if gear.rollPenalty and gear.rollPenalty > 0 then
				statsLabel.Text = statsLabel.Text .. ", -" .. tostring(gear.rollPenalty) .. "% Roll Speed"
			end

			statsLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
			statsLabel.TextSize = 14
			statsLabel.TextXAlignment = Enum.TextXAlignment.Left
			statsLabel.Parent = gearFrame

			-- Equip/Unequip button
			local equipButton = Instance.new("TextButton")
			equipButton.Size = UDim2.new(0, 100, 0, 30)
			equipButton.Position = UDim2.new(1, -110, 0.5, -15)
			equipButton.BackgroundColor3 = gear.isEquipped 
				and Color3.fromRGB(60, 60, 80) 
				or Color3.fromRGB(40, 80, 120)
			equipButton.BorderSizePixel = 0
			equipButton.Font = Enum.Font.Arcade
			equipButton.Text = gear.isEquipped and "EQUIPPED" or "EQUIP"
			equipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			equipButton.TextSize = 16
			equipButton.Parent = gearFrame

			-- Button functionality with error handling
			equipButton.MouseButton1Click:Connect(function()
				local success3, result3 = pcall(function()
					if gear.isEquipped then
						-- Unequip the gear
						if UnequipGear and UnequipGear:IsA("RemoteFunction") then
							return UnequipGear:InvokeServer()
						end
					else
						-- Equip the gear
						if EquipGear and EquipGear:IsA("RemoteFunction") then
							return EquipGear:InvokeServer(gear.id)
						end
					end
				end)

				if success3 then
					task.delay(0.5, function()
						pcall(refreshGearDisplay)
					end)
				else
					warn("Failed to equip/unequip gear:", tostring(result3))
				end
			end)

			gearFrame.Parent = GearsTab
		end

		-- Update scroll size if it's a ScrollingFrame
		if GearsTab:IsA("ScrollingFrame") then
			GearsTab.CanvasSize = UDim2.new(0, 0, 0, #gears * 70 + 20)
		end

		print("DEBUG: Finished refreshing gear display with " .. #gears .. " items")
	end)

	if not success then
		warn("Error in refreshGearDisplay:", tostring(result))
	end
end

-- Connect to inventory open events with error handling
local success, InventoryGui = pcall(function()
	return PlayerGui:WaitForChild("InventoryGui", 10)
end)

if success and InventoryGui then
	-- Connect to visibility changes
	InventoryGui:GetPropertyChangedSignal("Visible"):Connect(function()
		if InventoryGui.Visible then
			print("DEBUG: Inventory became visible, refreshing gear display")
			pcall(refreshGearDisplay)
		end
	end)
end

-- Call refresh function after a delay with error handling
task.delay(2, function() pcall(refreshGearDisplay) end)
task.delay(5, function() pcall(refreshGearDisplay) end)  -- Try again after a few seconds

-- Listen for gear inventory updates with error handling
local openGearMerchantEvent = ReplicatedStorage:FindFirstChild("OpenGearMerchantGUI")
if openGearMerchantEvent then
	openGearMerchantEvent.OnClientEvent:Connect(function(action)
		if action == "updateInventory" then
			print("DEBUG: Received updateInventory event, refreshing gear display")
			task.delay(0.5, function()
				pcall(refreshGearDisplay)
			end)
		end
	end)
end

-- Add a function to update luck from gears with error handling
local function updateLuckFromGear()
	pcall(function()
		-- Check if the luck GUI system is loaded
		if _G.updateBadgeLuckBoost then
			-- Wait for the LuckBoostEvent to initialize the badge boost
			local luckBoostEvent = ReplicatedStorage:WaitForChild("LuckBoostEvent", 10)
			if not luckBoostEvent then
				warn("LuckBoostEvent not found in ReplicatedStorage")
				return
			end

			-- Get gear data
			local success, gears = pcall(function()
				return GetFormattedGearInventory:InvokeServer()
			end)

			if not success or not gears then
				warn("Failed to get gear data for luck update")
				return
			end

			-- Find equipped gear
			local luckBoost = 0
			local rollPenalty = 0

			for _, gear in ipairs(gears) do
				if gear.isEquipped then
					luckBoost = gear.luckBoost or 0
					rollPenalty = gear.rollPenalty or 0
					break
				end
			end

			-- Update the luck GUI
			if _G.updateBadgeLuckBoost then
				_G.updateBadgeLuckBoost(luckBoost)
				print("Updated luck boost from gear: +" .. luckBoost .. "%")
			end
		end
	end)
end

-- Run luck update when script loads and after inventory refreshes
task.delay(3, function() pcall(updateLuckFromGear) end)
task.spawn(function()
	while task.wait(10) do
		pcall(updateLuckFromGear)
	end
end)

-- Add a command to force refresh
_G.RefreshGearDisplay = refreshGearDisplay
_G.UpdateLuckFromGear = updateLuckFromGear

print("Gear inventory integration loaded with luck integration and full error handling")