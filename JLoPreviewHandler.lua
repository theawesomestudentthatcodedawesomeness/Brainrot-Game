-- ServerScriptService/JLoPreviewHandler.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotDefinitions = require(ReplicatedStorage:WaitForChild("BrainrotDefinitions"))

local ShowBrainrotOnJLoEvent = ReplicatedStorage:WaitForChild("ShowBrainrotOnJLoEvent")

ShowBrainrotOnJLoEvent.OnServerEvent:Connect(function(player, brainrotName, odds, color)
	local brainrot = BrainrotDefinitions.Lookup[brainrotName]
	if not brainrot then return end

	local jloModel = workspace:FindFirstChild("JLo")
	if not jloModel then return end

	-- ? Fire only to the requesting player
	ShowBrainrotOnJLoEvent:FireClient(player,
		jloModel, 
		brainrotName, 
		brainrot.odds, 
		brainrot.titleColor or Color3.fromRGB(255, 255, 255)
	)
end)

print("? JLo Preview Handler Ready!")