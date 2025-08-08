-- Place this LocalScript in StarterPlayerScripts or StarterGui

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local SOUND_NAME = "BackgroundAmbience" -- or "BackgroundNoise"

-- Wait for the sound in ReplicatedStorage
local bgSoundTemplate = ReplicatedStorage:WaitForChild(SOUND_NAME)

-- Only one per player!
if not workspace:FindFirstChild(SOUND_NAME .. "_Local_" .. player.Name) then
	local bgSound = bgSoundTemplate:Clone()
	bgSound.Name = SOUND_NAME .. "_Local_" .. player.Name
	bgSound.Looped = true
	bgSound.Volume = 0.1 -- << Set your desired volume here (0 = silent, 1 = max)
	bgSound.Parent = workspace -- or player.PlayerGui if you prefer
	bgSound:Play()
end