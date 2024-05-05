
type BodyPartData = {CFrame : CFrame, Velocity : Vector3}

export type CharacterFrame = {
	UCUUID : string,
	Timestamp : number,
	BoundsCFrame : CFrame,
	BoundsSize : Vector3,
	BodyPartData : { [string] : BodyPartData },
	Tags : { [string] : any },
}

export type PackedCharacterFrame = {
	UCUUID : string,
	Timestamp : number,
	Bounds : { number },
	BodyParts : { number },
	Tags : { [string] : any },
}

local BitModule = require(script.Parent.BitModule)

local function SplitToChunks(s : string, chunkSize : number) : {string}
	local t = {}
	while #s > chunkSize do
		t[#t + 1] = s:sub(1, chunkSize)
		s = s:sub(chunkSize + 1)
	end
	t[#t + 1] = s
	return t
end


local function RoundNumber( value : number, places ) : number
	return tonumber(string.format("%."..(places or 0).."f", value)) or 0
end

local function EncodedCFrame( cf : CFrame ) : {number}
	-- X, Y, Z, LookXYZ, RightXYZ, UpXYZ (0-4096)
	local aX,aY,aZ = cf:ToEulerAnglesXYZ()
	local x = RoundNumber(cf.X, 1) * math.pow(10, 1)
	local y = RoundNumber(cf.Y, 1) * math.pow(10, 1)
	local z = RoundNumber(cf.Z, 1) * math.pow(10, 1)
	-- X, Y, Z, yaw, roll, pitch (0 -> ~6140 when rounded)
	aX = RoundNumber(aX, 3) * math.pow(10, 3)
	aY = RoundNumber(aY, 3) * math.pow(10, 3)
	aZ = RoundNumber(aZ, 3) * math.pow(10, 3)
	return {x,y,z,aX,aY,aZ}
end

local function EncodeVector3( vec3 : Vector3 ) : {number}
	-- bit32.band( frame.BoundsCFrame.Position.X, (2^12)-1 )
	local x, y, z = vec3.X, vec3.Y, vec3.Z
	x = RoundNumber(x, 1) * math.pow(10, 1)
	y = RoundNumber(y, 1) * math.pow(10, 1)
	z = RoundNumber(z, 1) * math.pow(10, 1)
	return {x,y,z} -- returns whole numbers with decimal to the left 1
end

local function EncodeBounds( boundsCFrame : CFrame, boundsSize : Vector3 ) : { number }

	local cframeValues : {number} = EncodedCFrame(boundsCFrame)
	print(cframeValues)

	-- take the n-bits out of the numbers and put them into a new number 0 (use bit32.extract + bit32.lshift)

	local sizeValues : {number} = EncodeVector3(boundsSize)
	print(sizeValues)

	-- take the n-bits out of the numbers and put them into a new number 0 (use bit32.extract + bit32.lshift)

end

local function EncodeBodyParts( bodyPartDict : { [string] : BodyPartData } ) : { number }

end

-- // Module // --
local Module = {}

function Module.BitPackCharacterFrame( frame : CharacterFrame ) : PackedCharacterFrame
	local encodedBounds : { number } = EncodeBounds( frame.BoundsCFrame, frame.BoundsSize )
	local encodedBodyParts : { number } = EncodeBodyParts( frame.BodyPartData )
	return {
		UCUUID = frame.UCUUID,
		Timestamp = frame.Timestamp,
		Tags = frame.Tags,

		Bounds = encodedBounds,
		BodyParts = encodedBodyParts,
	}
end

return Module

