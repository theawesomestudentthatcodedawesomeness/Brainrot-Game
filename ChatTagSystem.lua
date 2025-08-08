-- Chat Tag System for Gamepass Users (Studio-Compatible)
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("?? CHAT TAG SYSTEM LOADING...")

-- Wait for gamepass system to load
local GamepassRemotes = ReplicatedStorage:WaitForChild("GamepassRemotes", 10)

-- Create our own chat tag system since ChatServiceRunner doesn't exist in Studio
local ChatTagRemotes = ReplicatedStorage:FindFirstChild("ChatTagRemotes")
if not ChatTagRemotes then
	ChatTagRemotes = Instance.new("Folder")
	ChatTagRemotes.Name = "ChatTagRemotes"
	ChatTagRemotes.Parent = ReplicatedStorage
end

local UpdateChatTag = ChatTagRemotes:FindFirstChild("UpdateChatTag")
if not UpdateChatTag then
	UpdateChatTag = Instance.new("RemoteEvent")
	UpdateChatTag.Name = "UpdateChatTag"
	UpdateChatTag.Parent = ChatTagRemotes
end

-- Function to get player's chat tags (multiple tags supported)
local function getPlayerChatTags(player)
	local tags = {}

	if _G.CheckPlayerGamepassOwnership then
		-- Check Matteoooo's VIP first (highest priority)
		if _G.CheckPlayerGamepassOwnership(player, 1376797718) then
			table.insert(tags, {
				TagText = "[Matteoooooo]",
				TagColor = Color3.fromRGB(255, 215, 0) -- Gold
			})
		end

		-- Check regular VIP
		if _G.CheckPlayerGamepassOwnership(player, 1378491109) then
			table.insert(tags, {
				TagText = "[VIP]", 
				TagColor = Color3.fromRGB(0, 162, 255) -- Blue
			})
		end
	end

	return tags
end

-- Function to setup chat tags for a player
local function setupPlayerChatTags(player)
	spawn(function()
		-- Wait a bit for gamepass system to load player data
		wait(3)

		local chatTags = getPlayerChatTags(player)
		if #chatTags > 0 then
			print("?? Setting up chat tags for " .. player.Name .. ": " .. #chatTags .. " tags")

			-- Try to use ChatService if it exists (not in Studio)
			local success = false
			if not RunService:IsStudio() then
				local chatServiceRunner = game:GetService("ServerScriptService"):FindFirstChild("ChatServiceRunner")
				if chatServiceRunner then
					local ChatService = require(chatServiceRunner:WaitForChild("ChatService"))

					local speakerSuccess, speakerObj = pcall(function()
						return ChatService:GetSpeaker(player.Name)
					end)

					if speakerSuccess and speakerObj then
						speakerObj:SetExtraData("Tags", chatTags)
						success = true
						print("? Applied chat tags via ChatService to " .. player.Name)
					end
				end
			end

			-- Fallback: Use our custom system
			if not success then
				print("?? Using custom chat tag system for " .. player.Name)
				UpdateChatTag:FireClient(player, chatTags)
			end
		else
			print("?? No chat tags for " .. player.Name)
		end
	end)
end

-- Setup chat tags when players join
Players.PlayerAdded:Connect(function(player)
	print("?? Player added: " .. player.Name)
	-- Wait for ChatService to be ready
	spawn(function()
		wait(2)
		setupPlayerChatTags(player)
	end)
end)

-- Listen for gamepass updates
local UpdateGamepassUI = ReplicatedStorage:FindFirstChild("UpdateGamepassUI")
if UpdateGamepassUI then
	UpdateGamepassUI.OnServerEvent:Connect(function(player)
		-- Refresh chat tags when gamepasses are updated
		print("?? Refreshing chat tags for " .. player.Name)
		setupPlayerChatTags(player)
	end)
end

-- Setup for existing players
for _, player in pairs(Players:GetPlayers()) do
	setupPlayerChatTags(player)
end

-- Global function for manual refresh
_G.RefreshPlayerChatTags = function(player)
	setupPlayerChatTags(player)
end

print("? CHAT TAG SYSTEM LOADED!")