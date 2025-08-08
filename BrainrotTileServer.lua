--[[
Handles equipped brainrot visual titles and JLo billboard titles for all players.
Uses RemoteEvents as shown in your ReplicatedStorage hierarchy (see Image 4).

- EquipBrainrotVisual: Used for player brainrot titles.
- ShowBrainrotOnJLoEvent: Used for the JLo dummy's title.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- RemoteEvents
local EquipBrainrotVisual = ReplicatedStorage:WaitForChild("EquipBrainrotVisual")
local ShowBrainrotOnJLoEvent = ReplicatedStorage:WaitForChild("ShowBrainrotOnJLoEvent")

-- Tracks each player's equipped brainrot (extend as needed)
local equippedBrainrots = {}

-- When a player equips a brainrot, broadcast to all and store info
-- Expects: player, brainrotName, brainrotOdds, brainrotColor
EquipBrainrotVisual.OnServerEvent:Connect(function(player, brainrotName, brainrotOdds, brainrotColor)
	equippedBrainrots[player.UserId] = {
		name = brainrotName,
		odds = brainrotOdds,
		color = brainrotColor,
	}
	-- Broadcast to all clients
	EquipBrainrotVisual:FireAllClients(player.UserId, brainrotName, brainrotOdds, brainrotColor)
end)

-- When a player first joins, tell them about other players' equipped brainrots
Players.PlayerAdded:Connect(function(joiningPlayer)
	for userId, data in pairs(equippedBrainrots) do
		-- Don't send their own title (optional)
		if joiningPlayer.UserId ~= userId then
			EquipBrainrotVisual:FireClient(joiningPlayer, userId, data.name, data.odds, data.color)
		end
	end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
	equippedBrainrots[leavingPlayer.UserId] = nil
end)