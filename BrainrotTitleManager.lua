-- ServerScriptService/BrainrotTitleManager.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get or create our remote events
local function getOrCreateRemoteEvent(name)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then return existing end

	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = ReplicatedStorage
	return event
end

local ShowBrainrotOnJLoEvent = getOrCreateRemoteEvent("ShowBrainrotOnJLoEvent")
local PlayerTitleDisplayEvent = getOrCreateRemoteEvent("PlayerTitleDisplayEvent")
local BrainrotDefinitions = require(ReplicatedStorage:WaitForChild("BrainrotDefinitions"))

-- Active titles tracking
local activeBrainrots = {} -- [userId] = {name = "", odds = 0, color = Color3, timestamp = 0}
local jloCurrentBrainrot = nil

-- Utility functions
local function getPlayerByUserId(userId)
	return Players:GetPlayerByUserId(userId)
end

local function getBrainrotData(brainrotName)
	local brainrot = BrainrotDefinitions.Lookup[brainrotName]
	if not brainrot then return nil end

	return {
		name = brainrotName,
		odds = brainrot.odds,
		color = brainrot.titleColor or Color3.fromRGB(255, 255, 255),
		effects = brainrot.effects,
		vfxAsset = brainrot.vfxAsset
	}
end

-- Core title management functions
local function clearPlayerTitle(userId)
	if not activeBrainrots[userId] then return end

	local player = getPlayerByUserId(userId)
	if player then
		PlayerTitleDisplayEvent:FireAllClients(userId, nil, nil, nil)
	end

	activeBrainrots[userId] = nil
end

local function applyBrainrotToPlayer(userId, brainrotName)
	if not userId or not brainrotName then return end

	local brainrotData = getBrainrotData(brainrotName)
	if not brainrotData then
		warn("Invalid brainrot:", brainrotName)
		return
	end

	-- Update tracking
	activeBrainrots[userId] = {
		name = brainrotName,
		odds = brainrotData.odds,
		color = brainrotData.color,
		timestamp = tick()
	}

	-- Notify all clients
	PlayerTitleDisplayEvent:FireAllClients(
		userId,
		brainrotName,
		brainrotData.odds,
		brainrotData.color
	)

	print("? Applied brainrot to userId:", userId, "->", brainrotName)
end

local function clearJLoTitle()
	if not jloCurrentBrainrot then return end

	local jlo = workspace:FindFirstChild("JLo")
	if jlo then
		ShowBrainrotOnJLoEvent:FireAllClients(jlo, nil, nil, nil)
	end

	jloCurrentBrainrot = nil
end

local function applyBrainrotToJLo(brainrotName)
	if not brainrotName then return end

	local brainrotData = getBrainrotData(brainrotName)
	if not brainrotData then
		warn("Invalid brainrot for JLo:", brainrotName)
		return
	end

	local jlo = workspace:FindFirstChild("JLo")
	if not jlo then
		warn("JLo model not found")
		return
	end

	-- Update tracking
	jloCurrentBrainrot = {
		name = brainrotName,
		odds = brainrotData.odds,
		color = brainrotData.color,
		timestamp = tick()
	}

	-- Notify all clients
	ShowBrainrotOnJLoEvent:FireAllClients(
		jlo,
		brainrotName,
		brainrotData.odds,
		brainrotData.color
	)

	print("? Applied brainrot to JLo:", brainrotName)
end

-- Event Handlers
ShowBrainrotOnJLoEvent.OnServerEvent:Connect(function(player, brainrotName)
	if not player:GetAttribute("CanModifyJLo") then return end
	applyBrainrotToJLo(brainrotName)
end)

PlayerTitleDisplayEvent.OnServerEvent:Connect(function(player, targetUserId, brainrotName)
	if not player:GetAttribute("CanModifyTitles") then return end

	if brainrotName then
		applyBrainrotToPlayer(targetUserId, brainrotName)
	else
		clearPlayerTitle(targetUserId)
	end
end)

-- Player Management
Players.PlayerRemoving:Connect(function(player)
	clearPlayerTitle(player.UserId)
end)

Players.PlayerAdded:Connect(function(player)
	-- Restore title if player had one
	if activeBrainrots[player.UserId] then
		local data = activeBrainrots[player.UserId]
		applyBrainrotToPlayer(player.UserId, data.name)
	end
end)

print("? Brainrot Title Manager Ready!")