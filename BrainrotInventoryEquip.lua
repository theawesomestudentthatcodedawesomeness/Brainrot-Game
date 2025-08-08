-- StarterPlayerScripts/BrainrotInventoryEquip.lua
-- FIXED: Better detection for "Equip as Title" buttons

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remotes
local EquipBrainrotVisual = ReplicatedStorage:WaitForChild("EquipBrainrotVisual")
local BrainrotDefinitions = require(ReplicatedStorage:WaitForChild("BrainrotDefinitions"))

-- Global function for inventory GUIs to call
_G.EquipBrainrotTitle = function(brainrotName)
	local def = BrainrotDefinitions.Lookup[brainrotName]
	if not def then
		warn("? Brainrot not found in definitions: " .. tostring(brainrotName))
		return
	end

	local titleColor = def.titleColor or def.color or Color3.fromRGB(255, 255, 255)

	print("?? Equipping brainrot for player:", brainrotName)
	EquipBrainrotVisual:FireServer(brainrotName, def.odds, titleColor)
end

-- Enhanced button detection
local function connectInventoryButtons()
	-- Look for common inventory GUI names
	local possibleInventoryGUIs = {
		"InventoryGui", "Inventory", "BrainrotInventory", "BrainrotStorage",
		"MainGui", "PlayerGui", "Collection", "StorageGui"
	}

	for _, guiName in pairs(possibleInventoryGUIs) do
		local gui = playerGui:FindFirstChild(guiName)
		if gui then
			print("?? Found GUI:", guiName)

			-- Recursively find equip buttons
			local function findEquipButtons(parent)
				for _, child in pairs(parent:GetChildren()) do
					if child:IsA("TextButton") or child:IsA("ImageButton") then
						local childName = child.Name:lower()
						local childText = child.Text:lower()

						-- Check for various equip button patterns
						if string.find(childName, "equip") or 
							string.find(childText, "equip") or
							childName == "equipastitle" or
							childText == "equip as title" then

							-- If not already connected
							if not child:GetAttribute("BrainrotEquipConnected") then
								child:SetAttribute("BrainrotEquipConnected", true)

								child.MouseButton1Click:Connect(function()
									print("?? Equip button clicked:", child.Name)

									-- Try multiple ways to find the brainrot name
									local brainrotName = child:GetAttribute("BrainrotName") or
										child.Parent:GetAttribute("BrainrotName") or
										child.Parent.Name

									-- Check parent's parent for item frames
									if not brainrotName or brainrotName == "" then
										local itemFrame = child.Parent
										if itemFrame and itemFrame.Parent then
											for _, sibling in pairs(itemFrame:GetChildren()) do
												if sibling:IsA("TextLabel") and sibling.Name:find("Name") then
													brainrotName = sibling.Text
													break
												end
											end
										end
									end

									if brainrotName and brainrotName ~= "" then
										_G.EquipBrainrotTitle(brainrotName)
										print("? Equipped via button:", brainrotName)
									else
										warn("? No brainrot name found for equip button")
										print("Button name:", child.Name)
										print("Button text:", child.Text)
										print("Parent name:", child.Parent.Name)
									end
								end)

								print("?? Connected equip button:", child.Name, "->", child.Text)
							end
						end
					end

					-- Recursive search
					if child:IsA("GuiObject") then
						findEquipButtons(child)
					end
				end
			end

			findEquipButtons(gui)
		end
	end
end

-- Connect existing GUIs
spawn(function()
	wait(2) -- Give GUIs time to load
	connectInventoryButtons()
end)

-- Monitor for new GUIs
playerGui.ChildAdded:Connect(function(newGui)
	wait(1) -- Give time for GUI to fully load
	connectInventoryButtons()
end)

-- Also check periodically in case we miss something
spawn(function()
	while true do
		wait(5)
		connectInventoryButtons()
	end
end)

print("?? Enhanced Brainrot Inventory Equip Helper Ready!")