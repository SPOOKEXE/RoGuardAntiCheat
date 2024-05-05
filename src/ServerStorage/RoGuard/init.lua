
local PackingModule = require(script.Packing)

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module.Start()

	local frame = PackingModule.BitPackCharacterFrame({
		UCUUID = 'totally_unique',
		Timestamp = 12342354234,
		BoundsCFrame = CFrame.new( Vector3.new(3,4,3), Vector3.new(4,3,4) ),
		BoundsSize = Vector3.new(2, 3, 2),
		BodyPartData = { HumanoidRootPart = {CFrame = CFrame.new(3,3,3), Velocity = Vector3.new(0,1,0)} },
		Tags = {},
	})

	print(frame)

end

function Module.Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
