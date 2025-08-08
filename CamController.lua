task.wait()

local RS = game:GetService("ReplicatedStorage")

-- ? FIXED: Try multiple possible locations for Modules
local Modules = RS:FindFirstChild("Modules") or 
	RS:FindFirstChild("ReplicatedModules") or
	RS:FindFirstChild("Shared") or
	RS:FindFirstChild("ModuleScripts")

if not Modules then
	-- Try looking in ServerStorage or other common locations
	local ServerStorage = game:GetService("ServerStorage")
	Modules = ServerStorage:FindFirstChild("Modules")
end

if not Modules then
	warn("Modules folder not found in any common locations - disabling camera shake")
	print("Searched locations: ReplicatedStorage.Modules, ReplicatedStorage.ReplicatedModules, ReplicatedStorage.Shared, ServerStorage.Modules")
	return
end

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local healthhumanoid = humanoid.Health

local camera = workspace.CurrentCamera

-- ? FIXED: Try multiple possible names for CameraShaker
local CameraShaker = nil
local possibleNames = {"CameraShaker", "CamShaker", "Shake", "CameraShake"}

for _, name in ipairs(possibleNames) do
	local module = Modules:FindFirstChild(name)
	if module then
		local success, loadedModule = pcall(require, module)
		if success and loadedModule then
			CameraShaker = loadedModule
			print("Successfully loaded camera shaker module:", name)
			break
		else
			warn("Failed to require module " .. name .. ":", tostring(loadedModule))
		end
	end
end

if not CameraShaker then
	warn("CameraShaker module not found - tried names:", table.concat(possibleNames, ", "))
	return
end

-- ? FIXED: Safe CameraShaker initialization with multiple fallbacks
local camShake = nil

-- Try different possible constructor patterns
local constructors = {
	function() return CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
			camera.CFrame = camera.CFrame * shakeCFrame
		end) end,
	function() return CameraShaker:new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
			camera.CFrame = camera.CFrame * shakeCFrame
		end) end,
	function() return CameraShaker.New(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
			camera.CFrame = camera.CFrame * shakeCFrame
		end) end
}

for i, constructor in ipairs(constructors) do
	local success, shaker = pcall(constructor)
	if success and shaker then
		camShake = shaker
		print("Successfully created CameraShaker with constructor pattern", i)
		break
	end
end

if not camShake then
	warn("Failed to create CameraShaker instance with any known pattern")
	return
end

-- ? FIXED: Safe start call with error handling
if camShake.Start then
	local startSuccess = pcall(function()
		camShake:Start()
	end)
	if startSuccess then
		print("CameraShaker started successfully")
	else
		warn("Failed to start CameraShaker")
		return
	end
elseif camShake.start then
	local startSuccess = pcall(function()
		camShake:start()
	end)
	if startSuccess then
		print("CameraShaker started successfully (lowercase)")
	else
		warn("Failed to start CameraShaker (lowercase)")
		return
	end
else
	warn("CameraShaker start method not found")
	return
end

-- ? FIXED: Safe health connection with proper validation
if humanoid then
	humanoid.HealthChanged:Connect(function(health)
		if healthhumanoid > health then
			-- Try multiple possible shake methods and preset locations
			local shakeSuccess = false

			-- Try different shake method names and preset locations
			if camShake.Shake and CameraShaker.Presets and CameraShaker.Presets.Bump then
				shakeSuccess = pcall(function()
					camShake:Shake(CameraShaker.Presets.Bump)
				end)
			elseif camShake.shake and CameraShaker.Presets and CameraShaker.Presets.Bump then
				shakeSuccess = pcall(function()
					camShake:shake(CameraShaker.Presets.Bump)
				end)
			elseif camShake.Shake and CameraShaker.presets and CameraShaker.presets.bump then
				shakeSuccess = pcall(function()
					camShake:Shake(CameraShaker.presets.bump)
				end)
			elseif camShake.Shake then
				-- Try with a basic shake without presets
				shakeSuccess = pcall(function()
					camShake:Shake({
						Magnitude = 1,
						Roughness = 1,
						FadeInTime = 0.1,
						FadeOutTime = 0.1,
						PositionInfluence = Vector3.new(0.15, 0.15, 0.15),
						RotationInfluence = Vector3.new(1, 1, 1)
					})
				end)
			end

			if not shakeSuccess then
				-- Last resort - try manual camera shake
				pcall(function()
					local originalCFrame = camera.CFrame
					camera.CFrame = originalCFrame * CFrame.new(
						math.random(-100, 100) / 1000,
						math.random(-100, 100) / 1000,
						math.random(-100, 100) / 1000
					)
					task.wait(0.1)
					camera.CFrame = originalCFrame
				end)
			end
		end
		healthhumanoid = health
	end)
	print("Health change connection established")
else
	warn("Humanoid not found, cannot connect health events")
end

print("CamController initialized with comprehensive error handling and fallbacks")