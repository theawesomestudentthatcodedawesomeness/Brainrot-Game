-- ServerScriptService - SafetyNetSystem.lua
-- Handles player teleportation back to spawn when they touch the safety net
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")

-- Create RemoteEvents for client communication
local SafetyNetRemotes = ReplicatedStorage:FindFirstChild("SafetyNetRemotes")
if not SafetyNetRemotes then
	SafetyNetRemotes = Instance.new("Folder")
	SafetyNetRemotes.Name = "SafetyNetRemotes"
	SafetyNetRemotes.Parent = ReplicatedStorage
end

local ShowBlackScreenEvent = SafetyNetRemotes:FindFirstChild("ShowBlackScreen")
if not ShowBlackScreenEvent then
	ShowBlackScreenEvent = Instance.new("RemoteEvent")
	ShowBlackScreenEvent.Name = "ShowBlackScreen"
	ShowBlackScreenEvent.Parent = SafetyNetRemotes
end

-- Find spawn location
local function getSpawnLocation()
	local spawnLocation = workspace:FindFirstChild("SpawnLocation")
	if spawnLocation then
		return spawnLocation.Position + Vector3.new(0, 5, 0)
	end

	-- Fallback to default spawn
	return Vector3.new(0, 10, 0)
end

-- Teleport player back to spawn
local function teleportToSpawn(player)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local spawnPos = getSpawnLocation()

	-- Show black screen first
	ShowBlackScreenEvent:FireClient(player, true)

	-- Small delay for screen effect
	wait(0.3)

	-- Teleport player
	humanoidRootPart.CFrame = CFrame.new(spawnPos)

	-- Remove velocity to prevent continued falling
	local bodyVelocity = humanoidRootPart:FindFirstChild("BodyVelocity")
	if bodyVelocity then bodyVelocity:Destroy() end

	local bodyAngularVelocity = humanoidRootPart:FindFirstChild("BodyAngularVelocity")
	if bodyAngularVelocity then bodyAngularVelocity:Destroy() end

	-- Reset velocity
	if humanoidRootPart.AssemblyLinearVelocity then
		humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	end

	-- Small delay then hide screen
	wait(0.5)
	ShowBlackScreenEvent:FireClient(player, false)

	print("??? " .. player.Name .. " was teleported back to spawn (out of bounds)")
end

-- Set up safety net collision detection
local function setupSafetyNet()
	local safetyNet = workspace:FindFirstChild("SafetyNet")
	if not safetyNet then
		warn("?? SafetyNet not found in workspace! Please create a part named 'SafetyNet'")
		return
	end

	-- Make sure it's properly configured
	safetyNet.CanCollide = false
	safetyNet.Transparency = 0.8
	safetyNet.Material = Enum.Material.ForceField

	-- Color it red so it's visible as danger zone
	if not safetyNet.BrickColor then
		safetyNet.BrickColor = BrickColor.new("Really red")
	end

	-- Connect touch event
	local debounce = {}

	safetyNet.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				-- Debounce to prevent multiple triggers
				if debounce[player.UserId] then return end
				debounce[player.UserId] = true

				-- Teleport player
				spawn(function()
					teleportToSpawn(player)
					wait(2) -- Cooldown
					debounce[player.UserId] = nil
				end)
			end
		end
	end)

	print("??? Safety net system initialized on: " .. safetyNet.Name)
end

-- Initialize when server starts
setupSafetyNet()

-- Re-setup if safety net is added later
workspace.ChildAdded:Connect(function(child)
	if child.Name == "SafetyNet" then
		wait(0.1)
		setupSafetyNet()
	end
end)

print("??? Safety Net System Ready!")