-- ServerScriptService > LuckPotionSystem with Arrow Navigation (DEBUG VERSION)
print("?? LuckPotionSystem.lua is loading...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Create RemoteEvents if they don't exist
local potionPickedUpEvent = ReplicatedStorage:FindFirstChild("PotionPickedUpEvent")
if not potionPickedUpEvent then
	potionPickedUpEvent = Instance.new("RemoteEvent")
	potionPickedUpEvent.Name = "PotionPickedUpEvent"
	potionPickedUpEvent.Parent = ReplicatedStorage
end

local potionLuckUpdateEvent = ReplicatedStorage:FindFirstChild("PotionLuckUpdateEvent")
if not potionLuckUpdateEvent then
	potionLuckUpdateEvent = Instance.new("RemoteEvent")
	potionLuckUpdateEvent.Name = "PotionLuckUpdateEvent"
	potionLuckUpdateEvent.Parent = ReplicatedStorage
end

local potionHoldEvent = ReplicatedStorage:FindFirstChild("PotionHoldEvent")
if not potionHoldEvent then
	potionHoldEvent = Instance.new("RemoteEvent")
	potionHoldEvent.Name = "PotionHoldEvent"
	potionHoldEvent.Parent = ReplicatedStorage
end

-- NEW: Potion spawn notification and arrow guidance for Matteoooo's VIP
local PotionSpawnNotification = ReplicatedStorage:FindFirstChild("PotionSpawnNotification")
if not PotionSpawnNotification then
	PotionSpawnNotification = Instance.new("RemoteEvent")
	PotionSpawnNotification.Name = "PotionSpawnNotification"
	PotionSpawnNotification.Parent = ReplicatedStorage
end

local PotionArrowGuide = ReplicatedStorage:FindFirstChild("PotionArrowGuide")
if not PotionArrowGuide then
	PotionArrowGuide = Instance.new("RemoteEvent")
	PotionArrowGuide.Name = "PotionArrowGuide"
	PotionArrowGuide.Parent = ReplicatedStorage
end

print("?? ? RemoteEvents created successfully")

-- Potion spawn locations (your existing locations)
local POTION_SPAWN_LOCATIONS = {
	Vector3.new(155.936, 96.484, 139.402), --1
	Vector3.new(295.313, 96.484, 315.488), --2
	Vector3.new(453.037, 95.25, 107.278), --3
	Vector3.new(447.48, 95.518, -5.222), --4
	Vector3.new(199.596, 116.38, -35.937), --5
	Vector3.new(362.085, 190.342, 532.851), --6
	Vector3.new(334.098, 96.58, 539.604), --7
	Vector3.new(411.522, 126.192, 612.688), --8
	Vector3.new(532.718, 198.321, 552.231), --9
	Vector3.new(430.545, 223.377, 593.353), --10
}

-- Settings (your existing settings)
local POTION_RESPAWN_TIME_MIN = 100 -- 5 minutes minimum
local POTION_RESPAWN_TIME_MAX = 600 -- 15 minutes maximum
local POTION_LUCK_BOOST = 35
local POTION_DURATION = 60
local FLOAT_HEIGHT = 3
local HOLD_TIME = 2
local MAX_POTIONS_AT_ONCE = 1
local SPAWN_CHANCE = 0.3
local ARROW_DURATION = 12 -- NEW: Arrow guidance duration

print("?? ?? Settings loaded - Max potions: " .. MAX_POTIONS_AT_ONCE)

-- Track active potions and player buffs
local activePotions = {}
local playerBuffs = {}
local spawnTimers = {}
local activePotionCount = 0

-- NEW: Function to notify and guide Matteoooo's VIP players about potion spawns
local function notifyAndGuideVIPPlayers(position, potionName)
	print("?? ?? Notifying and guiding VIP players to potion at: " .. tostring(position))

	-- Get all Matteoooo's VIP players
	local vipPlayers = {}

	-- Use the global function from gamepass system if available
	if _G.HasPotionNotifications then
		for _, player in pairs(Players:GetPlayers()) do
			if _G.HasPotionNotifications(player) then
				table.insert(vipPlayers, player)
				print("?? ?? Found VIP player: " .. player.Name)
			end
		end
	else
		-- Fallback: Check manually (for testing)
		for _, player in pairs(Players:GetPlayers()) do
			if _G.CheckPlayerGamepassOwnership and _G.CheckPlayerGamepassOwnership(player, 1376797718) then
				table.insert(vipPlayers, player)
				print("?? ?? Found VIP player (fallback): " .. player.Name)
			end
		end
	end

	if #vipPlayers > 0 then
		print("?? ?? Sending notifications and arrows to " .. #vipPlayers .. " VIP players")

		for _, player in pairs(vipPlayers) do
			-- Send spawn notification
			PotionSpawnNotification:FireClient(player, position)

			-- Send arrow guidance data
			PotionArrowGuide:FireClient(player, {
				targetPosition = position,
				potionName = potionName,
				duration = ARROW_DURATION
			})
		end
	else
		print("?? ?? No VIP players found to notify")
	end
end

-- SIMPLIFIED: More reliable ground detection (your existing function)
local function findGroundLevel(position)
	print("?? ?? GROUND DETECTION for position: " .. tostring(position))
	local testY = position.Y
	print("?? ?? Using original Y position: " .. testY)
	return testY
end

-- ENHANCED: Function to create a luck potion with VIP guidance
local function createLuckPotion(position, locationIndex, forceSpawn)
	print("?? ==========================================")
	print("?? ?? ATTEMPTING TO CREATE POTION at location " .. locationIndex)
	print("?? ?? Position: " .. tostring(position))
	print("?? ?? Force spawn: " .. tostring(forceSpawn or false))

	-- Skip capacity check if force spawning
	if not forceSpawn then
		if activePotionCount >= MAX_POTIONS_AT_ONCE then
			print("?? ?? Max potions reached (" .. MAX_POTIONS_AT_ONCE .. "), skipping spawn at location " .. locationIndex)
			local respawnDelay = math.random(60, 300)
			spawnTimers[locationIndex] = spawn(function()
				wait(respawnDelay)
				if POTION_SPAWN_LOCATIONS[locationIndex] then
					createLuckPotion(POTION_SPAWN_LOCATIONS[locationIndex], locationIndex)
				end
				spawnTimers[locationIndex] = nil
			end)
			return nil
		end

		-- Skip chance check if force spawning
		if math.random() > SPAWN_CHANCE then
			print("?? ?? Spawn chance failed for location " .. locationIndex .. " (30% chance)")
			local respawnDelay = math.random(POTION_RESPAWN_TIME_MIN, POTION_RESPAWN_TIME_MAX)
			spawnTimers[locationIndex] = spawn(function()
				wait(respawnDelay)
				if POTION_SPAWN_LOCATIONS[locationIndex] then
					createLuckPotion(POTION_SPAWN_LOCATIONS[locationIndex], locationIndex)
				end
				spawnTimers[locationIndex] = nil
			end)
			return nil
		end
	else
		print("?? ?? FORCE SPAWN: Skipping capacity and chance checks")
	end

	local potionModel = ReplicatedStorage:FindFirstChild("Luck_Potion")
	if not potionModel then
		warn("?? ? ERROR: Luck_Potion model not found in ReplicatedStorage!")
		print("?? ?? Available models in ReplicatedStorage:")
		for _, child in pairs(ReplicatedStorage:GetChildren()) do
			print("??   - " .. child.Name .. " (" .. child.ClassName .. ")")
		end
		return nil
	end

	print("?? ? Found Luck_Potion model in ReplicatedStorage")

	local newPotion = potionModel:Clone()
	local potionName = "LuckPotion_" .. locationIndex .. "_" .. tick()
	newPotion.Name = potionName

	-- SIMPLIFIED: Use exact position (no raycast complications)
	local adjustedPosition = Vector3.new(position.X, position.Y + FLOAT_HEIGHT, position.Z)

	print("?? ?? Original position: " .. position.X .. ", " .. position.Y .. ", " .. position.Z)
	print("?? ?? Adjusted position: " .. adjustedPosition.X .. ", " .. adjustedPosition.Y .. ", " .. adjustedPosition.Z)

	-- Get original position
	local originalPosition
	if potionModel.PrimaryPart then
		originalPosition = potionModel.PrimaryPart.Position
		print("?? ?? Using PrimaryPart position: " .. tostring(originalPosition))
	else
		local mainPart = potionModel:FindFirstChildOfClass("BasePart")
		if mainPart then
			originalPosition = mainPart.Position
			print("?? ?? Using first BasePart position: " .. tostring(originalPosition))
		else
			warn("?? ? ERROR: No BasePart found in Luck_Potion model!")
			print("?? ?? Children in model:")
			for _, child in pairs(potionModel:GetChildren()) do
				print("??   - " .. child.Name .. " (" .. child.ClassName .. ")")
			end
			return nil
		end
	end

	-- Calculate offset and move all parts
	local offset = adjustedPosition - originalPosition
	local baseCFrames = {}
	local partCount = 0

	print("?? ?? Moving parts with offset: " .. tostring(offset))

	for _, part in pairs(newPotion:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CFrame = part.CFrame + offset
			part.CanCollide = false
			part.Anchored = true
			baseCFrames[part] = part.CFrame
			partCount = partCount + 1
			print("??   ?? Moved part: " .. part.Name .. " to " .. tostring(part.Position))
		end
	end

	print("?? ? Moved " .. partCount .. " parts")

	-- Add proper green glow
	local function addGreenGlow()
		local glowCount = 0
		for _, part in pairs(newPotion:GetDescendants()) do
			if part:IsA("BasePart") then
				-- Create green PointLight
				local greenLight = Instance.new("PointLight")
				greenLight.Name = "GreenGlow"
				greenLight.Color = Color3.fromRGB(0, 255, 0)
				greenLight.Brightness = 1
				greenLight.Range = 8
				greenLight.Parent = part
				glowCount = glowCount + 1
			end
		end
		print("?? ?? Added green glow to " .. glowCount .. " parts")
	end
	addGreenGlow()

	-- Add floating animation
	local floatConnection
	local startTime = tick()

	floatConnection = RunService.Heartbeat:Connect(function()
		if newPotion and newPotion.Parent then
			local time = tick() - startTime
			local floatOffset = math.sin(time * 2) * 0.8

			for part, baseCFrame in pairs(baseCFrames) do
				if part and part.Parent then
					local newPos = baseCFrame.Position + Vector3.new(0, floatOffset, 0)
					part.CFrame = CFrame.new(newPos, baseCFrame.LookVector)
				end
			end
		else
			floatConnection:Disconnect()
		end
	end)

	-- Store potion reference
	activePotions[newPotion] = {
		position = adjustedPosition,
		locationIndex = locationIndex,
		floatConnection = floatConnection,
		baseCFrames = baseCFrames
	}

	print("?? ?? Parenting potion to workspace...")
	newPotion.Parent = workspace
	activePotionCount = activePotionCount + 1

	-- NEW: Notify and guide Matteoooo's VIP players with arrows
	notifyAndGuideVIPPlayers(adjustedPosition, potionName)

	print("?? ? SUCCESS! RARE Luck potion spawned at location " .. locationIndex .. " (" .. activePotionCount .. "/" .. MAX_POTIONS_AT_ONCE .. " active)")
	print("?? ?? Final position: (" .. adjustedPosition.X .. ", " .. adjustedPosition.Y .. ", " .. adjustedPosition.Z .. ")")
	print("?? ??? Potion name: " .. newPotion.Name)
	print("?? ?? Potion parent: " .. tostring(newPotion.Parent))
	print("?? ?? VIP players notified with arrow guidance!")
	print("?? ==========================================")

	return newPotion
end

-- Function to handle potion pickup (your existing function)
local function pickupPotion(player, potion)
	local potionData = activePotions[potion]
	if not potionData then return end

	if playerBuffs[player.UserId] and tick() < playerBuffs[player.UserId].endTime then
		playerBuffs[player.UserId].endTime = tick() + POTION_DURATION
		potionPickedUpEvent:FireClient(player, POTION_LUCK_BOOST, POTION_DURATION)
		print("?? " .. player.Name .. "'s luck potion duration extended!")
	else
		playerBuffs[player.UserId] = {
			luckBoost = POTION_LUCK_BOOST,
			endTime = tick() + POTION_DURATION
		}

		potionPickedUpEvent:FireClient(player, POTION_LUCK_BOOST, POTION_DURATION)
		potionLuckUpdateEvent:FireClient(player, POTION_LUCK_BOOST)

		print("?? " .. player.Name .. " picked up a RARE luck potion! +" .. POTION_LUCK_BOOST .. "% luck for " .. POTION_DURATION .. "s")
	end

	if potionData.floatConnection then
		potionData.floatConnection:Disconnect()
	end
	activePotions[potion] = nil
	activePotionCount = activePotionCount - 1

	if potion and potion.Parent then
		potion:Destroy()
	end

	local locationIndex = potionData.locationIndex
	local respawnDelay = math.random(POTION_RESPAWN_TIME_MIN, POTION_RESPAWN_TIME_MAX)

	spawnTimers[locationIndex] = spawn(function()
		print("?? Potion at location " .. locationIndex .. " will attempt respawn in " .. math.floor(respawnDelay/60) .. " minutes (" .. activePotionCount .. "/" .. MAX_POTIONS_AT_ONCE .. " active)")
		wait(respawnDelay)
		if POTION_SPAWN_LOCATIONS[locationIndex] then
			createLuckPotion(POTION_SPAWN_LOCATIONS[locationIndex], locationIndex)
		end
		spawnTimers[locationIndex] = nil
	end)
end

-- Handle hold event from client (your existing function)
potionHoldEvent.OnServerEvent:Connect(function(player, potion)
	if potion and potion.Parent and activePotions[potion] then
		print("?? Received pickup request from " .. player.Name)
		pickupPotion(player, potion)
	end
end)

-- Function to update player luck buffs (your existing function)
local function updatePlayerBuffs()
	local currentTime = tick()

	for playerId, buffData in pairs(playerBuffs) do
		if currentTime >= buffData.endTime then
			local player = Players:GetPlayerByUserId(playerId)
			if player then
				potionLuckUpdateEvent:FireClient(player, 0)
				print("?? " .. player.Name .. "'s luck potion expired")
			end
			playerBuffs[playerId] = nil
		end
	end
end

-- Function to get player's current potion luck boost (your existing function)
local function getPlayerPotionLuck(player)
	local buffData = playerBuffs[player.UserId]
	if buffData and tick() < buffData.endTime then
		return buffData.luckBoost
	end
	return 0
end

-- ADMIN FUNCTIONS for testing (your existing functions)
local function forceSpawnAllPotions()
	print("?? ?? ADMIN: Force spawning ALL potions...")
	local spawnedCount = 0

	for i, position in ipairs(POTION_SPAWN_LOCATIONS) do
		local potion = createLuckPotion(position, i, true) -- Force spawn = true
		if potion then
			spawnedCount = spawnedCount + 1
		end
	end

	print("?? ? ADMIN: Force spawned " .. spawnedCount .. "/" .. #POTION_SPAWN_LOCATIONS .. " potions")
	return spawnedCount
end

local function clearAllPotions()
	print("?? ??? ADMIN: Clearing all potions...")
	local clearedCount = 0

	-- Clear from active potions tracking
	for potion, data in pairs(activePotions) do
		if data.floatConnection then
			data.floatConnection:Disconnect()
		end
		if potion and potion.Parent then
			potion:Destroy()
			clearedCount = clearedCount + 1
		end
	end
	activePotions = {}

	-- Clear any remaining potions in workspace
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name and obj.Name:find("LuckPotion_") then
			obj:Destroy()
			clearedCount = clearedCount + 1
		end
	end

	activePotionCount = 0
	print("?? ? ADMIN: Cleared " .. clearedCount .. " potions")
	return clearedCount
end

local function listAllPotions()
	print("?? ?? ADMIN: Listing all active potions...")
	print("?? Active potion count: " .. activePotionCount)
	print("?? Tracked potions: " .. #activePotions)

	local workspacePotions = 0
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name and obj.Name:find("LuckPotion_") then
			workspacePotions = workspacePotions + 1
			print("??   - " .. obj.Name .. " at " .. tostring(obj:FindFirstChildOfClass("BasePart") and obj:FindFirstChildOfClass("BasePart").Position or "unknown position"))
		end
	end
	print("?? Potions in workspace: " .. workspacePotions)

	return workspacePotions
end

local function spawnTestPotion(player)
	if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return false, "Player or character not found"
	end

	local playerPosition = player.Character.HumanoidRootPart.Position
	local testPosition = playerPosition + Vector3.new(5, 0, 5) -- 5 studs away

	print("?? ?? ADMIN: Spawning test potion near " .. player.Name .. " at " .. tostring(testPosition))

	local potion = createLuckPotion(testPosition, 999, true) -- Force spawn with location ID 999
	if potion then
		return true, "Test potion spawned near you with arrow guidance"
	else
		return false, "Failed to spawn test potion"
	end
end

-- Staggered and rare initial spawns (your existing spawn logic)
spawn(function()
	print("?? ?? Starting RARE potion spawn system with ARROW GUIDANCE...")
	print("?? Max potions at once: " .. MAX_POTIONS_AT_ONCE)
	print("?? Spawn chance: " .. (SPAWN_CHANCE * 100) .. "%")
	print("?? Respawn time: " .. math.floor(POTION_RESPAWN_TIME_MIN/60) .. "-" .. math.floor(POTION_RESPAWN_TIME_MAX/60) .. " minutes")
	print("?? Arrow guidance duration: " .. ARROW_DURATION .. " seconds")
	print("?? ADMIN TESTING MODE: Use admin commands to test potions")
	print("?? VIP arrow guidance enabled for Matteoooo's VIP players!")

	-- DON'T auto-spawn potions for testing
	-- Uncomment this section when testing is complete:
	--[[
	local shuffledLocations = {}
	for i, pos in ipairs(POTION_SPAWN_LOCATIONS) do
		table.insert(shuffledLocations, {pos = pos, index = i})
	end

	for i = #shuffledLocations, 2, -1 do
		local j = math.random(i)
		shuffledLocations[i], shuffledLocations[j] = shuffledLocations[j], shuffledLocations[i]
	end

	for i, locationData in ipairs(shuffledLocations) do
		spawn(function()
			local initialDelay = math.random(60, 300) * i
			print("?? Location " .. locationData.index .. " scheduled for first attempt in " .. math.floor(initialDelay/60) .. " minutes")
			wait(initialDelay)
			createLuckPotion(locationData.pos, locationData.index)
		end)
	end
	]]--
end)

-- Update buffs every second (your existing function)
spawn(function()
	while true do
		wait(1)
		updatePlayerBuffs()
	end
end)

-- Handle player leaving (your existing function)
Players.PlayerRemoving:Connect(function(player)
	playerBuffs[player.UserId] = nil
end)

-- ADMIN CHAT COMMANDS (updated for your username)
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "juliovetta16" then -- Your current username
			if message == "!spawnpotions" then
				print("?? ?? ADMIN COMMAND: /spawnpotions")
				local count = forceSpawnAllPotions()
				print("?? ? RESULT: Spawned " .. count .. " potions with arrow guidance")

			elseif message == "!clearpotions" then
				print("?? ??? ADMIN COMMAND: /clearpotions")
				local count = clearAllPotions()
				print("?? ? RESULT: Cleared " .. count .. " potions")

			elseif message == "!listpotions" then
				print("?? ?? ADMIN COMMAND: /listpotions")
				listAllPotions()

			elseif message == "!testpotion" then
				print("?? ?? ADMIN COMMAND: /testpotion")
				local success, result = spawnTestPotion(player)
				print("?? ? RESULT: " .. result)

			elseif message == "!potionhelp" then
				print("?? ?? ADMIN COMMANDS:")
				print("??   !spawnpotions - Force spawn all potions with arrows")
				print("??   !clearpotions - Clear all potions")
				print("??   !listpotions - List all active potions")
				print("??   !testpotion - Spawn test potion with arrow guidance")
				print("??   !potionhelp - Show this help")
			end
		end
	end)
end)

-- CRITICAL: Set global functions for admin system
_G.ForceSpawnAllPotions = forceSpawnAllPotions
_G.CreateLuckPotion = function(position, locationIndex)
	return createLuckPotion(position, locationIndex, true)
end
_G.ResetPotionCount = function()
	activePotionCount = 0
end
_G.getPlayerPotionLuck = getPlayerPotionLuck

print("?? ? LuckPotionSystem.lua fully loaded - _G.ForceSpawnAllPotions available:", _G.ForceSpawnAllPotions ~= nil)
print("?? ?? RARE Luck Potion System with ARROW GUIDANCE loaded!")
print("?? ?? Spawn locations: " .. #POTION_SPAWN_LOCATIONS)
print("?? ?? Max active potions: " .. MAX_POTIONS_AT_ONCE)
print("?? ?? Arrow guidance: ENABLED (" .. ARROW_DURATION .. " seconds)")
print("?? ?? VIP notifications: ENABLED")
print("?? ????? ADMIN COMMANDS for juliovetta16:")
print("??   /spawnpotions, /clearpotions, /listpotions, /testpotion, /potionhelp")