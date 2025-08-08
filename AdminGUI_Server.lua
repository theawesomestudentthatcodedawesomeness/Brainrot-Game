-- Place in ServerScriptService
-- AdminGUI_Server.lua - Simple working version

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("?? ADMIN GUI SERVER LOADING...")

-- Admin configuration (same as AdminCommandModule)
local ADMINS = {
	[377361486] = {name = "Admin1", level = 3},
	[7180677868] = {name = "Admin2", level = 2}, 
	[168722593] = {name = "Admin3", level = 6},
	[299245694] = {name = "Admin4", level = 1},
	[1710943863] = {name = "i0nii_Chann", level = 50},
}

-- Helper functions
local function isAdmin(userId)
	return ADMINS[userId] ~= nil
end

local function getAdminLevel(userId)
	local admin = ADMINS[userId]
	return admin and admin.level or 0
end

local function canUseGUI(userId)
	return getAdminLevel(userId) >= 5
end

-- Wait for RemoteEvents from AdminCommandModule
local AdminGUIRemotes = ReplicatedStorage:WaitForChild("AdminGUIRemotes", 10)
if not AdminGUIRemotes then
	warn("?? ? AdminGUIRemotes not found!")
	return
end

local OpenAdminGUI = AdminGUIRemotes:WaitForChild("OpenAdminGUI", 5)

if not OpenAdminGUI then
	warn("?? ? OpenAdminGUI not found!")
	return
end

print("?? ? Admin GUI Server loaded!")

-- Send GUI to admin players when they join
Players.PlayerAdded:Connect(function(player)
	print("?? Player joined: " .. player.Name .. " (ID: " .. player.UserId .. ")")

	if isAdmin(player.UserId) then
		local adminLevel = getAdminLevel(player.UserId)
		print("?? ? Admin detected: " .. player.Name .. " (Level " .. adminLevel .. ")")

		if canUseGUI(player.UserId) then
			wait(3) -- Wait for client to load
			OpenAdminGUI:FireClient(player)
			print("?? ?? Sent admin GUI to " .. player.Name)
		end
	end
end)

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
	if isAdmin(player.UserId) and canUseGUI(player.UserId) then
		print("?? Setting up existing admin: " .. player.Name)
		spawn(function()
			wait(1)
			OpenAdminGUI:FireClient(player)
			print("?? ?? Sent admin GUI to existing player: " .. player.Name)
		end)
	end
end

print("?? ? ADMIN GUI SERVER READY!")