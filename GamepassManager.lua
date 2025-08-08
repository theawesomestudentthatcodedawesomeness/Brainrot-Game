-- ServerScriptService > GamepassManager
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("?? Loading Enhanced Gamepass Manager...")

-- Create remotes folder if it doesn't exist
local GamepassRemotes = ReplicatedStorage:FindFirstChild("GamepassRemotes")
if not GamepassRemotes then
	GamepassRemotes = Instance.new("Folder")
	GamepassRemotes.Name = "GamepassRemotes"
	GamepassRemotes.Parent = ReplicatedStorage
end

-- Create remote functions
local CheckGamepassOwnership = GamepassRemotes:FindFirstChild("CheckGamepassOwnership")
if not CheckGamepassOwnership then
	CheckGamepassOwnership = Instance.new("RemoteFunction")
	CheckGamepassOwnership.Name = "CheckGamepassOwnership"
	CheckGamepassOwnership.Parent = GamepassRemotes
end

local GetOwnedGamepasses = GamepassRemotes:FindFirstChild("GetOwnedGamepasses")
if not GetOwnedGamepasses then
	GetOwnedGamepasses = Instance.new("RemoteFunction")
	GetOwnedGamepasses.Name = "GetOwnedGamepasses"
	GetOwnedGamepasses.Parent = GamepassRemotes
end

-- Create remote events
local UpdateGamepassUI = GamepassRemotes:FindFirstChild("UpdateGamepassUI")
if not UpdateGamepassUI then
	UpdateGamepassUI = Instance.new("RemoteEvent")
	UpdateGamepassUI.Name = "UpdateGamepassUI"
	UpdateGamepassUI.Parent = GamepassRemotes
end

-- Gamepass ownership cache with retry system
local playerGamepassCache = {}
local playerLoadStatus = {}

-- Gamepass IDs to track
local TRACKED_GAMEPASSES = {
	1376797718, -- Matteoooo's VIP
	1378491109, -- VIP
	1374214026, -- Starter Pack
	1374405825  -- Quick Roll
}

-- Enhanced function to check and cache gamepass ownership
local function updatePlayerGamepassCache(player, forceRefresh)
	if not player or not player.Parent then return end

	local userId = player.UserId

	if not playerGamepassCache[userId] then
		playerGamepassCache[userId] = {}
	end

	if not forceRefresh and playerLoadStatus[userId] and playerLoadStatus[userId].loaded then
		-- Already loaded, just fire update event
		UpdateGamepassUI:FireClient(player)
		return
	end

	playerLoadStatus[userId] = {loaded = false, loading = true}

	print("?? Checking gamepass ownership for " .. player.Name .. "...")

	local checkCount = 0
	local totalChecks = #TRACKED_GAMEPASSES

	for _, gamepassId in ipairs(TRACKED_GAMEPASSES) do
		spawn(function()
			local maxRetries = 3
			local retryDelay = 1

			for attempt = 1, maxRetries do
				if not player or not player.Parent then return end

				local success, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(userId, gamepassId)
				end)

				if success then
					playerGamepassCache[userId][gamepassId] = owns

					if owns then
						print("? " .. player.Name .. " OWNS gamepass " .. gamepassId)
					else
						print("? " .. player.Name .. " does NOT own gamepass " .. gamepassId)
					end

					checkCount = checkCount + 1
					break
				else
					warn("?? Attempt " .. attempt .. "/" .. maxRetries .. " failed for gamepass " .. gamepassId .. " for " .. player.Name .. ": " .. tostring(owns))

					if attempt < maxRetries then
						wait(retryDelay)
						retryDelay = retryDelay * 2 -- Exponential backoff
					else
						-- Final attempt failed
						playerGamepassCache[userId][gamepassId] = false
						checkCount = checkCount + 1
						warn("? All attempts failed for gamepass " .. gamepassId .. " for " .. player.Name)
					end
				end
			end

			-- Check if all gamepasses have been processed
			if checkCount >= totalChecks then
				if not player or not player.Parent then return end

				playerLoadStatus[userId] = {loaded = true, loading = false}

				print("?? Gamepass ownership check completed for " .. player.Name)

				-- Notify client of updated gamepass data
				UpdateGamepassUI:FireClient(player)

				-- Also fire the global update event if it exists
				local globalUpdateEvent = ReplicatedStorage:FindFirstChild("UpdateGamepassUI")
				if globalUpdateEvent and globalUpdateEvent ~= UpdateGamepassUI then
					globalUpdateEvent:FireClient(player)
				end

				-- Apply gamepass benefits
				if _G.RefreshPlayerGamepassLuck then
					spawn(function()
						wait(0.5)
						_G.RefreshPlayerGamepassLuck(player)
					end)
				end
			end
		end)
	end
end

-- Remote function handlers with better error handling
CheckGamepassOwnership.OnServerInvoke = function(player, gamepassId)
	if not player or not gamepassId then
		warn("Invalid parameters for CheckGamepassOwnership")
		return false
	end

	local userId = player.UserId

	-- If not cached yet, trigger cache update and wait
	if not playerGamepassCache[userId] or not playerLoadStatus[userId] or not playerLoadStatus[userId].loaded then
		print("?? Gamepass data not ready for " .. player.Name .. ", triggering update...")
		updatePlayerGamepassCache(player, false)

		-- Wait for data to load (with timeout)
		local timeout = 10
		local elapsed = 0
		while elapsed < timeout and (not playerLoadStatus[userId] or not playerLoadStatus[userId].loaded) do
			wait(0.1)
			elapsed = elapsed + 0.1
		end

		if elapsed >= timeout then
			warn("? Timeout waiting for gamepass data for " .. player.Name)
			return false
		end
	end

	local owns = playerGamepassCache[userId][gamepassId]
	print("?? " .. player.Name .. " checking gamepass " .. gamepassId .. ": " .. tostring(owns))
	return owns or false
end

GetOwnedGamepasses.OnServerInvoke = function(player)
	if not player then return {} end

	local userId = player.UserId

	if not playerGamepassCache[userId] then
		updatePlayerGamepassCache(player, false)
		return {}
	end

	return playerGamepassCache[userId] or {}
end

-- Player events
Players.PlayerAdded:Connect(function(player)
	print("?? " .. player.Name .. " joined - setting up gamepass data...")

	-- Wait for player to fully load
	spawn(function()
		wait(3) -- Give extra time for everything to load
		updatePlayerGamepassCache(player, false)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	playerGamepassCache[userId] = nil
	playerLoadStatus[userId] = nil
	print("?? " .. player.Name .. " left - cleaned up gamepass data")
end)

-- Listen for gamepass purchases
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if wasPurchased then
		print("?? " .. player.Name .. " purchased gamepass " .. gamepassId .. "!")

		local userId = player.UserId

		-- Update cache immediately
		if not playerGamepassCache[userId] then
			playerGamepassCache[userId] = {}
		end
		playerGamepassCache[userId][gamepassId] = true

		-- Notify client immediately
		UpdateGamepassUI:FireClient(player)

		-- Also trigger a full refresh after a short delay
		spawn(function()
			wait(2)
			updatePlayerGamepassCache(player, true)
		end)

		-- Apply gamepass benefits
		if _G.RefreshPlayerGamepassLuck then
			spawn(function()
				wait(1)
				_G.RefreshPlayerGamepassLuck(player)
			end)
		end
	end
end)

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
	spawn(function()
		print("?? Setting up gamepass data for existing player: " .. player.Name)
		wait(1)
		updatePlayerGamepassCache(player, false)
	end)
end

-- Global function for manual refresh
_G.RefreshAllPlayerGamepasses = function()
	print("?? Manually refreshing all player gamepass data...")
	for _, player in pairs(Players:GetPlayers()) do
		spawn(function()
			updatePlayerGamepassCache(player, true)
		end)
	end
end

print("? Enhanced Gamepass Manager loaded successfully!")
print("?? Tracking " .. #TRACKED_GAMEPASSES .. " gamepasses")
print("?? " .. #Players:GetPlayers() .. " players online")