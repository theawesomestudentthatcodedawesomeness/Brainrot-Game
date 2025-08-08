-- Plays a brainrot animation on the player's character using an Animation asset ID
-- Usage: call playBrainrotAnimation(assetId) where assetId is the animation's numeric asset ID

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Call this function with your asset ID to play the animation on your character
function playBrainrotAnimation(assetId)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Optional: Stop previous brainrot animation tracks for cleanliness
	for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
		if track.Name == "BrainrotAnimationTrack" then
			track:Stop()
		end
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. tostring(assetId)
	local animTrack = humanoid:LoadAnimation(animation)
	animTrack.Name = "BrainrotAnimationTrack"
	animTrack:Play()
end

-- Example usage:
-- playBrainrotAnimation(1234567890) -- Replace 1234567890 with your Animation asset ID