local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Remotes = ReplicatedStorage:WaitForChild("BrainrotSettingsRemotes")
local SettingsStore = DataStoreService:GetDataStore("BrainrotSettings_v1")
local defaultSettings = {
	AutoSave = 0,
	SkipBrainrots = 0,
	SkipCutscene = 0,
	SkipList = {},
	SaveList = {}
}

local playerSettings = {}

-- Debounce map for batched saves
local saveDebounce = {} -- [userId] = os.clock()
local saveQueued = {}   -- [userId] = true/false
local alreadySaved = {} -- [userId] = true/false
local DEBOUNCE_TIME = 30

-- Fetch from DataStore or default
local function loadSettings(userId)
	local data
	pcall(function()
		data = SettingsStore:GetAsync(userId)
	end)
	if type(data) == "table" then
		for k, v in pairs(defaultSettings) do
			if data[k] == nil then
				data[k] = v
			end
		end
		return data
	else
		return table.clone(defaultSettings)
	end
end

-- Save to DataStore (debounced, batched)
local function saveSettings(userId, immediate)
	local data = playerSettings[userId]
	if not data then return end
	if alreadySaved[userId] then return end -- prevent double-save
	local now = os.clock()
	if not immediate then
		if saveDebounce[userId] and now - saveDebounce[userId] < DEBOUNCE_TIME then
			saveQueued[userId] = true
			return
		end
	end
	saveDebounce[userId] = now
	saveQueued[userId] = false
	pcall(function()
		SettingsStore:SetAsync(userId, data)
	end)
	alreadySaved[userId] = true
end

-- Batch save for all queued players every 30 seconds
spawn(function()
	while true do
		wait(DEBOUNCE_TIME)
		for userId, queued in pairs(saveQueued) do
			if queued and not alreadySaved[userId] then
				saveSettings(userId, false)
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	alreadySaved[player.UserId] = false
	local settings = loadSettings(player.UserId)
	playerSettings[player.UserId] = settings
end)

Players.PlayerRemoving:Connect(function(player)
	if not alreadySaved[player.UserId] then
		saveSettings(player.UserId, true) -- Always force save on leave
	end
	playerSettings[player.UserId] = nil
	saveDebounce[player.UserId] = nil
	saveQueued[player.UserId] = nil
	alreadySaved[player.UserId] = true
end)

Remotes.RequestSettings.OnServerInvoke = function(player)
	return playerSettings[player.UserId] or table.clone(defaultSettings)
end

-- In BrainrotSettingsServer, add setting validation:
Remotes.UpdateSetting.OnServerEvent:Connect(function(player, key, value)
	local settings = playerSettings[player.UserId]
	if settings and defaultSettings[key] ~= nil then
		-- ADD VALIDATION:
		if key == "SkipBrainrots" and (type(value) ~= "number" or value < 0) then
			warn("Invalid skip value from", player.Name)
			return
		end

		settings[key] = value
		alreadySaved[player.UserId] = false
		saveSettings(player.UserId, false)
	end
end)