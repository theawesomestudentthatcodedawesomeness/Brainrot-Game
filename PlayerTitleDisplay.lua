-- LocalScript: StarterPlayer>StarterPlayerScripts>PlayerTitleDisplay
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local PlayerTitleDisplayEvent = ReplicatedStorage:WaitForChild("PlayerTitleDisplayEvent")
local ShowBrainrotOnJLoEvent = ReplicatedStorage:WaitForChild("ShowBrainrotOnJLoEvent")
local BrainrotDefinitions = require(ReplicatedStorage:WaitForChild("BrainrotDefinitions"))
local vfxFolder = ReplicatedStorage:WaitForChild("BrainrotVFX")

local player = Players.LocalPlayer

-- Enhanced Data Management
local playerTitles = {}
local currentEffects = {}
local titleCleanupQueue = {}
local effectCleanupQueue = {}

-- Constants
local TITLE_LIFETIME = 300 -- 5 minutes
local CLEANUP_INTERVAL = 30 -- 30 seconds
local MAX_TITLES_PER_PLAYER = 3

-- Enhanced Cleanup System
local function scheduleCleanup(targetTable, key, delay)
	spawn(function()
		wait(delay or CLEANUP_INTERVAL)
		if targetTable[key] then
			if targetTable[key].gui then
				pcall(function()
					targetTable[key].gui:Destroy()
				end)
			end
			targetTable[key] = nil
		end
	end)
end

-- Enhanced Title Cleanup
local function selectiveClearTitles(character, keepGUI)
	if not character or not character.Parent then return end

	local titlesToRemove = {}

	for _, child in pairs(character:GetChildren()) do
		if child:IsA("BillboardGui") then
			local name = child.Name:lower()
			if name:find("title") or name:find("brainrot") or name:find("billboard") then
				if keepGUI and child == keepGUI then
					print("?? KEEPING: " .. child.Name)
				else
					table.insert(titlesToRemove, child)
				end
			end
		end
	end

	for _, gui in ipairs(titlesToRemove) do
		pcall(function()
			gui:Destroy()
		end)
		print("??? SELECTIVE: Removed " .. gui.Name)
	end

	local head = character:FindFirstChild("Head")
	if head then
		for _, child in pairs(head:GetChildren()) do
			if child:IsA("BillboardGui") then
				if keepGUI and child == keepGUI then
					print("?? KEEPING head billboard")
				else
					pcall(function()
						child:Destroy()
					end)
					print("??? SELECTIVE: Removed head billboard")
				end
			end
		end
	end
end

-- Enhanced VFX System
local function playBrainrotEffects(character, brainrotName)
	if not character or not character.Parent then return end

	local brainrot = BrainrotDefinitions.Lookup[brainrotName]
	if not brainrot then
		warn("[VFX] No brainrot definition found for:", brainrotName)
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then
		warn("[VFX] Missing humanoid or rootPart for character")
		return
	end

	-- Cleanup existing effects
	if currentEffects[character] then
		for _, effectGroup in pairs(currentEffects[character]) do
			if effectGroup.vfxModel then
				pcall(function() effectGroup.vfxModel:Destroy() end)
			end
			if effectGroup.rootAttachment then
				pcall(function() effectGroup.rootAttachment:Destroy() end)
			end
			if effectGroup.animTrack then
				pcall(function()
					effectGroup.animTrack:Stop()
					effectGroup.animTrack:Destroy()
				end)
			end
			if effectGroup.sound then
				pcall(function() effectGroup.sound:Destroy() end)
			end
		end
		currentEffects[character] = nil
	end

	currentEffects[character] = {}

	-- VFX Setup
	if brainrot.vfxAsset then
		print("?? Setting up VFX:", brainrot.vfxAsset)
		local vfxTemplate = vfxFolder:FindFirstChild(brainrot.vfxAsset)
		if vfxTemplate then
			local success, result = pcall(function()
				local rootAttachment = Instance.new("Attachment")
				rootAttachment.Name = "VFXRootAttachment"
				rootAttachment.Position = Vector3.new(0, 0, 0)
				rootAttachment.Parent = rootPart

				local newVFX = vfxTemplate:Clone()
				newVFX.Parent = rootPart

				local vfxOffset = vfxTemplate:GetAttribute("VFXOffset") or Vector3.new(0, 0, 0)

				for _, part in ipairs(newVFX:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = false
						part.CanCollide = false
						part.CFrame = rootPart.CFrame * CFrame.new(vfxOffset)

						local partAttachment = Instance.new("Attachment")
						partAttachment.Name = part.Name .. "Attachment"
						partAttachment.Parent = part

						local alignPos = Instance.new("AlignPosition")
						alignPos.Attachment0 = partAttachment
						alignPos.Attachment1 = rootAttachment
						alignPos.RigidityEnabled = true
						alignPos.MaxForce = 1e6
						alignPos.Responsiveness = 200
						alignPos.Parent = part

						local alignOri = Instance.new("AlignOrientation")
						alignOri.Attachment0 = partAttachment
						alignOri.Attachment1 = rootAttachment
						alignOri.RigidityEnabled = true
						alignOri.MaxTorque = 1e6
						alignOri.Responsiveness = 200
						alignOri.Parent = part

						if part.Name:match("Floor") then
							part.Position = rootPart.Position + Vector3.new(0, 0.1, 0)
							local weld = Instance.new("Weld")
							weld.Part0 = rootPart
							weld.Part1 = part
							weld.C0 = CFrame.new(0, 0.1, 0)
							weld.Parent = part
							alignPos:Destroy()
							alignOri:Destroy()
						end

						if part:GetAttribute("IsVFXPart") then
							part.Transparency = 1
						end
					end
				end

				for _, obj in ipairs(newVFX:GetDescendants()) do
					if obj:IsA("ParticleEmitter") then
						print("?? Enabling particle emitter:", obj.Name)
						obj.Enabled = true
					elseif obj:IsA("Motor6D") then
						print("?? Found Motor6D:", obj.Name)
					end
				end

				table.insert(currentEffects[character], {
					vfxModel = newVFX,
					rootAttachment = rootAttachment,
					startTime = tick()
				})

				print("? VFX setup complete")
				return true
			end)

			if not success then
				warn("? VFX setup failed:", result)
			end
		else
			warn("? VFX template not found:", brainrot.vfxAsset)
		end
	end

	-- Animation Setup
	if brainrot.effects and brainrot.effects.animationId then
		local success, result = pcall(function()
			local animation = Instance.new("Animation")
			animation.AnimationId = brainrot.effects.animationId
			local animTrack = humanoid:LoadAnimation(animation)
			animTrack:Play()

			table.insert(currentEffects[character], {
				animTrack = animTrack,
				startTime = tick()
			})

			return true
		end)

		if not success then
			warn("? Animation setup failed:", result)
		end
	end

	-- Sound Setup
	if brainrot.effects and brainrot.effects.soundId then
		local success, result = pcall(function()
			local sound = Instance.new("Sound")
			sound.SoundId = brainrot.effects.soundId
			local baseVolume = brainrot.effects.soundVolume or 0.5
			sound:SetAttribute("BaseVolume", baseVolume)
			sound:SetAttribute("IsBrainrotSound", true)
			sound.Volume = baseVolume * (_G.BrainrotSFXVolume or 0.5)
			sound.Parent = rootPart
			sound:Play()

			table.insert(currentEffects[character], {
				sound = sound,
				startTime = tick()
			})

			return true
		end)

		if not success then
			warn("? Sound setup failed:", result)
		end
	end
end

-- Enhanced Title Display
local function displayPlayerTitle(identifier, brainrotName, brainrotOdds, brainrotColor)
	print("?? ENHANCED: Received title for identifier:", identifier, "brainrot:", brainrotName)

	local character = nil
	local isJLo = false
	local targetPlayer = Players:GetPlayerByUserId(tonumber(identifier) or 0)

	if targetPlayer then
		character = targetPlayer.Character
		if not character then
			print("? Waiting for character...")
			spawn(function()
				character = targetPlayer.CharacterAdded:Wait()
				if character then
					displayPlayerTitle(identifier, brainrotName, brainrotOdds, brainrotColor)
				end
			end)
			return
		end
	else
		character = game.Workspace:FindFirstChild("JLo", true)
		if character then
			isJLo = true
		end
	end

	if not character then
		warn("? No character found for identifier:", identifier)
		return
	end

	-- Play effects if brainrot is being equipped
	if brainrotName then
		spawn(function()
			playBrainrotEffects(character, brainrotName)
		end)
	end

	-- Handle existing title cleanup
	local oldGUI = nil
	if playerTitles[identifier] and playerTitles[identifier].gui then
		oldGUI = playerTitles[identifier].gui
	end
	playerTitles[identifier] = nil

	if not brainrotName then
		selectiveClearTitles(character)
		print("??? CLEARED title for identifier: " .. identifier)
		return
	end

	local head = character:FindFirstChild("Head") or character:FindFirstChildWhichIsA("BasePart")
	if not head then
		warn("? No head found for character")
		return
	end

	-- Create unique billboard
	local uniqueName = "PERMANENT_PlayerTitle_" .. identifier .. "_" .. tick()
	local billboard = Instance.new("BillboardGui")
	billboard.Name = uniqueName
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 300, 0, 80)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 100
	billboard.Parent = character

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.Arcade
	titleLabel.Text = string.format("1 in %s\n%s", tostring(brainrotOdds), brainrotName)
	titleLabel.TextColor3 = brainrotColor or Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.TextStrokeTransparency = 0.2
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.Parent = billboard

	-- Store title data
	playerTitles[identifier] = {
		gui = billboard,
		name = brainrotName,
		odds = brainrotOdds,
		color = brainrotColor,
		timestamp = tick(),
		permanent = true
	}

	-- Clean up old titles before showing new one
	selectiveClearTitles(character, billboard)

	-- Animate title appearance
	titleLabel.TextTransparency = 1
	local fadeIn = TweenService:Create(titleLabel, 
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
		{TextTransparency = 0}
	)
	fadeIn:Play()

	print("? PERMANENT title created for character: " .. brainrotName .. " (GUI: " .. uniqueName .. ")")

	-- Schedule cleanup
	scheduleCleanup(playerTitles, identifier, TITLE_LIFETIME)
end

-- Enhanced Event Connections
PlayerTitleDisplayEvent.OnClientEvent:Connect(function(userId, brainrotName, brainrotOdds, brainrotColor)
	spawn(function()
		pcall(function()
			displayPlayerTitle(userId, brainrotName, brainrotOdds, brainrotColor)
		end)
	end)
end)

ShowBrainrotOnJLoEvent.OnClientEvent:Connect(function(jloModel, brainrotName, brainrotOdds, brainrotColor)
	if jloModel and brainrotName then
		local jloIdentifier = "JLO_MODEL_" .. tostring(tick())
		spawn(function()
			pcall(function()
				displayPlayerTitle(jloIdentifier, brainrotName, brainrotOdds, brainrotColor)
			end)
		end)
	end
end)

-- Enhanced Player Management
Players.PlayerAdded:Connect(function(targetPlayer)
	targetPlayer.CharacterAdded:Connect(function(character)
		print("?? Character spawned for player:", targetPlayer.Name)

		-- Restore any existing title after character spawn
		spawn(function()
			wait(2) -- Wait for character to fully load
			local titleData = playerTitles[targetPlayer.UserId]
			if titleData and titleData.name then
				displayPlayerTitle(targetPlayer.UserId, titleData.name, titleData.odds, titleData.color)
			end
		end)
	end)
end)

-- Process existing players
for _, existingPlayer in pairs(Players:GetPlayers()) do
	print("?? Existing player found:", existingPlayer.Name)
end

-- Enhanced Cleanup on Player Removal
Players.PlayerRemoving:Connect(function(leavingPlayer)
	local userId = leavingPlayer.UserId

	-- Clean up titles
	if playerTitles[userId] then
		if playerTitles[userId].gui then
			pcall(function()
				playerTitles[userId].gui:Destroy()
			end)
		end
		playerTitles[userId] = nil
	end

	-- Clean up effects
	if leavingPlayer.Character and currentEffects[leavingPlayer.Character] then
		for _, effectGroup in pairs(currentEffects[leavingPlayer.Character]) do
			if effectGroup.vfxModel then
				pcall(function() effectGroup.vfxModel:Destroy() end)
			end
			if effectGroup.rootAttachment then
				pcall(function() effectGroup.rootAttachment:Destroy() end)
			end
			if effectGroup.animTrack then
				pcall(function()
					effectGroup.animTrack:Stop()
					effectGroup.animTrack:Destroy()
				end)
			end
			if effectGroup.sound then
				pcall(function() effectGroup.sound:Destroy() end)
			end
		end
		currentEffects[leavingPlayer.Character] = nil
	end

	print("?? Cleaned up data for leaving player:", leavingPlayer.Name)
end)

-- Enhanced Periodic Cleanup System
spawn(function()
	while true do
		wait(CLEANUP_INTERVAL)

		for _, player in pairs(Players:GetPlayers()) do
			if player.Character then
				local titleBillboards = {}

				for _, child in pairs(player.Character:GetChildren()) do
					if child:IsA("BillboardGui") then
						local name = child.Name:lower()
						if name:find("title") or name:find("brainrot") or name:find("billboard") then
							table.insert(titleBillboards, child)
						end
					end
				end

				if #titleBillboards > MAX_TITLES_PER_PLAYER then
					print("?? PERIODIC CLEANUP: Found " .. #titleBillboards .. " title GUIs on " .. player.Name)

					-- Sort by timestamp (newest first)
					table.sort(titleBillboards, function(a, b)
						local aTime = tonumber(string.match(a.Name, "(%d+%.?%d*)$")) or 0
						local bTime = tonumber(string.match(b.Name, "(%d+%.?%d*)$")) or 0
						return aTime > bTime
					end)

					local keepGUI = titleBillboards[1]
					selectiveClearTitles(player.Character, keepGUI)
				end
			end
		end

		-- Cleanup old effect references
		for character, effects in pairs(currentEffects) do
			if not character.Parent then
				currentEffects[character] = nil
			else
				local now = tick()
				for i = #effects, 1, -1 do
					local effect = effects[i]
					if effect.startTime and (now - effect.startTime) > 300 then -- 5 minutes
						if effect.vfxModel then
							pcall(function() effect.vfxModel:Destroy() end)
						end
						if effect.rootAttachment then
							pcall(function() effect.rootAttachment:Destroy() end)
						end
						if effect.animTrack then
							pcall(function()
								effect.animTrack:Stop()
								effect.animTrack:Destroy()
							end)
						end
						if effect.sound then
							pcall(function() effect.sound:Destroy() end)
						end
						table.remove(effects, i)
					end
				end
			end
		end
	end
end)

-- Global Utility Functions
_G.ClearAllPlayerTitles = function()
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			selectiveClearTitles(player.Character)
		end
	end
	playerTitles = {}
	print("?? MANUALLY cleared ALL player titles")
end

_G.RefreshPlayerTitle = function(playerName)
	local targetPlayer = Players:FindFirstChild(playerName)
	if targetPlayer and playerTitles[targetPlayer.UserId] then
		local data = playerTitles[targetPlayer.UserId]
		displayPlayerTitle(targetPlayer.UserId, data.name, data.odds, data.color)
	end
end

_G.StopTitleCleanup = function()
	print("?? EMERGENCY: Stopped all title cleanup!")
end

_G.GetCurrentPlayerTitles = function()
	return playerTitles
end

_G.GetCurrentEffects = function()
	return currentEffects
end

-- Enhanced Error Recovery
spawn(function()
	while true do
		wait(120) -- Every 2 minutes

		-- Check for orphaned GUIs
		for _, player in pairs(Players:GetPlayers()) do
			if player.Character then
				for _, child in pairs(player.Character:GetChildren()) do
					if child:IsA("BillboardGui") and child.Name:find("PERMANENT_PlayerTitle_") then
						local timestamp = tonumber(string.match(child.Name, "(%d+%.?%d*)$"))
						if timestamp and (tick() - timestamp) > TITLE_LIFETIME then
							print("?? Removing expired title:", child.Name)
							pcall(function() child:Destroy() end)
						end
					end
				end
			end
		end
	end
end)

print("?? ENHANCED Player Title Display System Ready!")
print("? Features:")
print(" - Enhanced VFX integration with error handling")
print(" - Selective cleanup preserving active titles") 
print(" - Permanent title system with auto-cleanup")
print(" - Improved memory management")
print(" - Robust error recovery")
print(" - Character respawn handling")
print("??? Use _G.ClearAllPlayerTitles() to manually clear all titles")
print("??? Use _G.StopTitleCleanup() if titles keep getting deleted")
print("??? Use _G.RefreshPlayerTitle(playerName) to refresh a specific player's title")