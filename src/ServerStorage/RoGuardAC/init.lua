local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService('CollectionService')

local MaidClassModule = require(script.Maid)
local Typings = require(script.Typings)

local INTERNAL_CONFIG = {

	CollectionTagName = 'ACC',

}

-- // Internal // --
local Internal = {}

function Internal.IsCharacterAlive( Character : Instance ) : boolean
	local Humanoid = Character and Character:FindFirstChildWhichIsA('Humanoid')
	return Humanoid and Humanoid.Health > 0
end

function Internal.CreateDeathEvent( Character : Instance )


end

-- // Module // --
local Module = { Internal = Internal, }

--[[
	Module.CharacterIdentifiers = {}
	Module.HumanoidIdentifiers = {}
	Module.HumanoidMaids = {}
]]



function Module.RegisterCharacter( Character )

	CollectionService:AddTag(Character, INTERNAL_CONFIG.CollectionTagName)

end

function Module.StepPhysics(dt : number)

	for _, Character in CollectionService:GetTagged(INTERNAL_CONFIG.CollectionTagName) do

		if not Module.IsCharacterAlive( Character ) then
			CollectionService:RemoveTag( Character, INTERNAL_CONFIG.CollectionTagName )
			Internal.CreateDeathEvent( Character )
			continue
		end

	end

end

function Module.AutomaticMode()
	if Module.AutomaticEnabled then
		return
	end
	Module.AutomaticEnabled = true

	local function OnPlayerAdded( LocalPlayer : Player )
		print(LocalPlayer.Name, 'has joined the game.')
		if LocalPlayer.Character then
			Module.RegisterCharacter( LocalPlayer.Character )
		end
		LocalPlayer.CharacterAdded:Connect(Module.RegisterCharacter)
	end

	local function OnPlayerRemoving( LocalPlayer : Player )
		print(LocalPlayer.Name, 'has left the game.')
	end

	for _, LocalPlayer in Players:GetPlayers() do
		task.spawn(OnPlayerAdded, LocalPlayer)
	end
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)
	RunService.Heartbeat:Connect(Module.StepPhysics)
end

function Module.Init()

end

function Module.Start()

	task.spawn(Module.AutomaticMode)

end

return Module
