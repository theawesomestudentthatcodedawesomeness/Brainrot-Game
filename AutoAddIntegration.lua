local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for gear system to load
wait(2)

print("?? Loading Auto-Add Integration...")

-- Check if gear system is loaded
if not _G.HandleAutoAdd then
	warn("? Gear system not found! Make sure GearSystem script is running.")
	return
end

-- Hook into your existing brainrot/item systems
-- This is where you'd integrate with your existing item drop/roll systems

-- Example integration function that you can call from your existing systems
local function onItemReceived(player, itemName, amount)
	if not player or not itemName then return end

	-- Try to auto-add the item
	local handled = _G.HandleAutoAdd(player, itemName)

	if handled then
		print("? AUTO-ADD: Processed " .. itemName .. " for " .. player.Name)
	end
end

-- Example: Hook into common global functions that might exist in your game
local originalFunctions = {}

-- Try to hook into inventory functions
local inventoryFunctions = {
	"AddItemToInventory",
	"GiveItem",
	"AwardItem",
	"AddItem"
}

for _, funcName in pairs(inventoryFunctions) do
	if _G[funcName] then
		originalFunctions[funcName] = _G[funcName]

		_G[funcName] = function(playerOrUserId, itemName, amount, ...)
			local result = originalFunctions[funcName](playerOrUserId, itemName, amount, ...)

			-- Try to get player object
			local player = nil
			if type(playerOrUserId) == "number" then
				player = Players:GetPlayerByUserId(playerOrUserId)
			elseif typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
				player = playerOrUserId
			end

			-- Trigger auto-add
			if player and itemName then
				spawn(function()
					wait(0.1) -- Small delay to ensure inventory is updated
					onItemReceived(player, itemName, amount or 1)
				end)
			end

			return result
		end

		print("? Hooked into " .. funcName .. " for auto-add")
	end
end

-- Global function for manual triggering
_G.TriggerAutoAdd = onItemReceived

-- Periodic auto-processing (runs every few seconds to catch any missed items)
spawn(function()
	while true do
		wait(5) -- Check every 5 seconds

		for _, player in pairs(Players:GetPlayers()) do
			if player and player.Parent then
				spawn(function()
					pcall(function()
						if _G.ProcessExistingInventoryForAutoAdd then
							_G.ProcessExistingInventoryForAutoAdd(player)
						end
					end)
				end)
			end
		end
	end
end)

print("? Auto-Add Integration loaded!")
print("?? Available functions:")
print("   - _G.TriggerAutoAdd(player, itemName, amount)")
print("   - Automatic processing every 5 seconds")
print("   - Hooked into common inventory functions")