
local Packing = require(script.Packing)

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module.Start()

	local packed = Packing.BitPackCharacterFrame({
		UCUUID = 'totally_unique',
		Timestamp = 1,
		BoundsCFrame = CFrame.new(Vector3.new(5, 5, 5), Vector3.new(3, 3, 3)),
		BoundsSize = Vector3.new(3, 3, 3),
		BodyPartData = {
			HumanoidRootPart = {
				CFrame = CFrame.new( Vector3.new(3,3,3), Vector3.new(6,6,6) ),
				Velocity = Vector3.new(0, 3, 0),
			},
		},
		Tags = {},
	})

	print(packed)

end

function Module.Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
