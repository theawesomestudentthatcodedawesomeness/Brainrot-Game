local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Wait for necessary remotes
local GearRemotes = ReplicatedStorage:WaitForChild("GearRemotes")
local GetFormattedGearInventory = GearRemotes:WaitForChild("GetFormattedGearInventory")

-- Define the functions first, before they're used

-- Function to request gear refresh from IconCreator
local function requestGearRefresh()
	-- Try to find an existing refresh function in IconCreator
	local iconCreatorRefresh = _G.RefreshGearIcons or 
		_G.UpdateGearDisplay or 
		_G.RefreshInventoryGears

	if iconCreatorRefresh and type(iconCreatorRefresh) == "function" then
		print("Calling existing icon refresh function")
		iconCreatorRefresh()
		return true
	end

	-- Find the gear container
	local InventoryGui = PlayerGui:FindFirstChild("InventoryGui")
	if not InventoryGui then return false end

	-- Find the container showing "No gears found..."
	local gearContainer = nil
	for _, obj in ipairs(InventoryGui:GetDescendants()) do
		if obj:IsA("TextLabel") and obj.Text:find("No gears found") then
			gearContainer = obj.Parent
			break
		end
	end

	if not gearContainer then
		-- Look for the gear tab or content area
		for _, obj in ipairs(InventoryGui:GetDescendants()) do
			if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
				if obj.Name:find("Gear") or obj.Name == "GearsContent" or obj.Name == "GearsTab" then
					gearContainer = obj
					break
				end
			end
		end
	end

	if not gearContainer then return false end

	-- We found the container, now check if we need to update it
	local currentGearData = GetFormattedGearInventory:InvokeServer()

	-- If we have gears but "No gears found" is showing, force update
	if #currentGearData > 0 then
		local noGearsLabel = nil
		for _, obj in ipairs(gearContainer:GetDescendants()) do
			if obj:IsA("TextLabel") and obj.Text:find("No gears found") then
				noGearsLabel = obj
				break
			end
		end

		if noGearsLabel then
			-- Send event that would normally trigger IconCreator
			print("Triggering gear refresh for container:", gearContainer:GetFullName())

			-- Look for and fire events that might refresh the gear UI
			local events = {
				ReplicatedStorage:FindFirstChild("RefreshInventory"),
				ReplicatedStorage:FindFirstChild("UpdateInventory"),
				ReplicatedStorage:FindFirstChild("InventoryUpdated")
			}

			for _, event in ipairs(events) do
				if event and (event:IsA("RemoteEvent") or event:IsA("BindableEvent")) then
					pcall(function()
						if event:IsA("RemoteEvent") then
							event:FireServer("gears")
						else
							event:Fire("gears")
						end
					end)
				end
			end

			return true
		end
	end

	return false
end

-- Function to refresh gear display manually (fallback if IconCreator doesn't handle it)
local function refreshGearDisplay()
	local InventoryGui = PlayerGui:FindFirstChild("InventoryGui")
	if not InventoryGui then return end

	-- Find the gear container
	local gearContainer = nil
	for _, obj in ipairs(InventoryGui:GetDescendants()) do
		if (obj:IsA("Frame") or obj:IsA("ScrollingFrame")) and 
			(obj.Name:find("Gear") or obj.Name == "GearsContent" or obj.Name == "GearsTab") then
			gearContainer = obj
			break
		end
	end

	if not gearContainer then return end

	-- Get gear data
	local gearData = GetFormattedGearInventory:InvokeServer()

	-- Clear existing gear items
	for _, child in ipairs(gearContainer:GetChildren()) do
		if child:IsA("Frame") and child.Name:find("GearItem") then
			child:Destroy()
		end
	end

	-- No gears case
	if #gearData == 0 then
		local noGearsLabel = gearContainer:FindFirstChild("NoGearsLabel")
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
			noGearsLabel.Parent = gearContainer
		end
		return
	else
		-- Remove "No gears" label if it exists
		local noGearsLabel = gearContainer:FindFirstChild("NoGearsLabel")
		if noGearsLabel then
			noGearsLabel:Destroy()
		end
	end

	-- Create gear items
	for i, gear in ipairs(gearData) do
		-- This is a simplified version - IconCreator would handle the full UI
		local gearFrame = Instance.new("Frame")
		gearFrame.Name = "GearItem_" .. gear.id
		gearFrame.Size = UDim2.new(1, -20, 0, 60)
		gearFrame.Position = UDim2.new(0, 10, 0, (i-1) * 70 + 10)
		gearFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		gearFrame.BorderSizePixel = 0

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.7, 0, 0, 25)
		nameLabel.Position = UDim2.new(0, 10, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.Arcade
		nameLabel.Text = gear.name
		nameLabel.TextColor3 = gear.color or Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 16
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = gearFrame

		local statsLabel = Instance.new("TextLabel")
		statsLabel.Size = UDim2.new(0.7, 0, 0, 20)
		statsLabel.Position = UDim2.new(0, 10, 0, 30)
		statsLabel.BackgroundTransparency = 1
		statsLabel.Font = Enum.Font.Arcade
		statsLabel.Text = "+" .. gear.luckBoost .. "% Luck"
		statsLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		statsLabel.TextSize = 14
		statsLabel.TextXAlignment = Enum.TextXAlignment.Left
		statsLabel.Parent = gearFrame

		gearFrame.Parent = gearContainer
	end

	-- Update scroll size if it's a scrolling frame
	if gearContainer:IsA("ScrollingFrame") then
		gearContainer.CanvasSize = UDim2.new(0, 0, 0, #gearData * 70 + 20)
	end
end

-- Function to find the IconCreator module and get access to its functionality
local function getIconCreator()
	-- Look in common script locations
	local locations = {
		ReplicatedStorage,
		game:GetService("ServerScriptService"),
		game:GetService("StarterPlayer").StarterPlayerScripts,
		ReplicatedStorage:FindFirstChild("Modules")
	}

	for _, location in ipairs(locations) do
		local iconCreator = location:FindFirstChild("IconCreator")
		if iconCreator then
			local success, module = pcall(require, iconCreator)
			if success and module then
				print("Found and loaded IconCreator module")
				return module
			end
		end
	end

	-- If we couldn't find it as a module, look for it as a script
	for _, obj in ipairs(game:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") then
			if obj.Name == "IconCreator" then
				print("Found IconCreator script at:", obj:GetFullName())
				-- Can't directly access its functions, but we can note where it is
				return {
					path = obj:GetFullName(),
					instance = obj
				}
			end
		end
	end

	warn("Could not find IconCreator module or script")
	return nil
end

-- Connect to IconCreator or inventory updates
local function connectToIconSystem()
	local IconCreator = getIconCreator()

	-- If we can directly call IconCreator functions
	if IconCreator and type(IconCreator) == "table" and IconCreator.CreateGearIcon then
		print("Using IconCreator.CreateGearIcon function directly")

		-- Patch or extend the CreateGearIcon function to ensure it shows our gears
		local originalCreateGearIcon = IconCreator.CreateGearIcon
		IconCreator.CreateGearIcon = function(...)
			-- Call original first
			local result = originalCreateGearIcon(...)

			-- Then make sure our gears are displayed
			task.spawn(function()
				task.wait(0.5) -- Wait for original to finish
				refreshGearDisplay()
			end)

			return result
		end
	else
		-- We need to hook into the inventory system more generally
		print("Using inventory visibility events to trigger gear display")

		local InventoryGui = PlayerGui:WaitForChild("InventoryGui", 30)
		if InventoryGui then
			-- ? FIXED: Use proper method to check for property changes
			local function monitorInventoryVisibility()
				task.spawn(function()
					local lastVisible = false
					while task.wait(0.5) do
						local success, currentVisible = pcall(function()
							return InventoryGui.Visible
						end)

						if success and currentVisible ~= lastVisible then
							if currentVisible then
								print("Inventory became visible")
								task.wait(0.5) -- Give time for the IconCreator to run first
								requestGearRefresh()
							end
							lastVisible = currentVisible
						elseif not success then
							-- If we can't access Visible property, use alternative monitoring
							-- Check for child count changes or other indicators
							local childCount = #InventoryGui:GetChildren()
							if childCount > 0 and not lastVisible then
								print("Inventory appears to be active (children detected)")
								requestGearRefresh()
								lastVisible = true
							elseif childCount == 0 and lastVisible then
								lastVisible = false
							end
						end
					end
				end)
			end

			monitorInventoryVisibility()

			-- Also look for tab changes
			for _, obj in pairs(InventoryGui:GetDescendants()) do
				if obj:IsA("TextButton") and (obj.Text == "Gears" or obj.Name:find("Gear")) then
					obj.MouseButton1Click:Connect(function()
						task.wait(0.1)
						requestGearRefresh()
					end)
					print("Connected to gear tab button:", obj:GetFullName())
				end
			end
		end
	end

	-- Listen for gear updates
	local OpenGearMerchantGUI = ReplicatedStorage:WaitForChild("OpenGearMerchantGUI")
	OpenGearMerchantGUI.OnClientEvent:Connect(function(action)
		if action == "updateInventory" then
			task.wait(0.5) -- Wait for data to update
			requestGearRefresh()
		end
	end)
end

-- Create a simple debug function that checks if gears are properly displaying
local function debugGearDisplay()
	task.spawn(function()
		while task.wait(5) do
			local gears = GetFormattedGearInventory:InvokeServer()

			if #gears > 0 then
				local InventoryGui = PlayerGui:FindFirstChild("InventoryGui")
				if InventoryGui then
					-- ? FIXED: Safe check for visibility
					local success, isVisible = pcall(function()
						return InventoryGui.Visible
					end)

					if success and isVisible then
						-- Check if "No gears found" is showing when it shouldn't be
						local noGearsLabel = nil
						for _, obj in pairs(InventoryGui:GetDescendants()) do
							if obj:IsA("TextLabel") and obj.Text:find("No gears found") then
								noGearsLabel = obj
								break
							end
						end

						if noGearsLabel then
							print("DEBUG: Found 'No gears found' message but player has " .. #gears .. " gears.")
							requestGearRefresh()
						end
					end
				end
			end
		end
	end)
end

-- Initial connection after a delay
task.wait(3) -- Give time for other scripts to load
connectToIconSystem()
task.wait(1)
requestGearRefresh()
debugGearDisplay()

-- Create global function for manually refreshing
_G.RefreshGearDisplay = requestGearRefresh

print("Gear Icon Integration loaded - connecting with IconCreator system")