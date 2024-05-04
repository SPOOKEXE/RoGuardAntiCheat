
export type CharacterFrame = {
	UCUUID : string,
	Timestamp : number,
	BoundsCFrame : CFrame,
	BoundsSize : Vector3,
	BodyPartData : { [string] : {CFrame : CFrame, Velocity : Vector3} },
	Tags : { [string] : any },
	-- Character Events : list[*Character Event Item*]
	-- Custom Events : list[*Custom Event Item*]
}

export type CharacterFramePacked = {
	UCUUID : string,
	Timestamp : number,
	Bounds : string,
	BodyPartData : { [string] : string },
	Tags : { [string] : any }
}

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

local function BitPackToByteStream( bits : number, ... : number ) : (string, number)
	local binaryString = ''
	for _, value in {...} do
		binaryString ..= PadBinaryString(ConvertToBinary(value), bits)
	end
	local padLength = 8 - (#binaryString % 8)
	if padLength == 8 then padLength = 0 end
	binaryString ..= string.rep('0', padLength) -- pad 0s
	return binaryString, padLength
end

local function ByteStreamToNumbers( value : string ) : {number}
	local byteNumbers = SplitToChunks(value, 8)
	for index, item in byteNumbers do
		byteNumbers[index] = tonumber(item, 2)
	end
	return byteNumbers
end

local function EncodedCFrame( cf : CFrame ) : {number}
	-- X, Y, Z, LookXYZ, RightXYZ, UpXYZ
	local aX,aY,aZ = cf:ToEulerAnglesXYZ()
	local x = RoundNumber(cf.X, 1) * math.pow(10, 1)
	local y = RoundNumber(cf.Y, 1) * math.pow(10, 1)
	local z = RoundNumber(cf.Z, 1) * math.pow(10, 1)
	-- X, Y, Z, yaw, roll, pitch
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
	return {x,y,z}
end

local function Vector3To24Bytes( vec3 : Vector3 ) : ({number}, number)
	local encodedVector = EncodeVector3( vec3 )
	local x, y, z = unpack(encodedVector)
	local byteString, padLength = BitPackToByteStream( 8, x, y, z )
	-- print(padLength, byteString)
	local byteNumbers = ByteStreamToNumbers(byteString)
	-- print(byteNumbers)
	return byteNumbers, padLength
end

local function CFrameTo10Bytes( cf : CFrame ) : ({number}, number)
	local encodedCFrame = EncodedCFrame( cf )
	local x, y, z, aX, aY, aZ = unpack( encodedCFrame )
	-- x,y,z,aX,aY,aZ are 13 bits each = 78 bits = 80 bits = 10 bytes total
	-- AAAAAAAA-AAAAABBB-BBBBBBBB-BBCCCCCC-CCCCCCCD-DDDDDDDD-DDDDEEEE-EEEEEEEE-EFFFFFFF-FFFFFF00
	local byteString, padLength = BitPackToByteStream( 13, x, y, z, aX, aY, aZ )
	-- print(padLength, byteString)
	local byteNumbers = ByteStreamToNumbers(byteString)
	-- print(byteNumbers)
	return byteNumbers, padLength
end

local function MoveArrayTo( from : {any}, to : {any} )
	table.move(from, 1, #from, #to + 1, to)
end

local function EncodeBounds( boundsCFrame : CFrame, boundsSize : Vector3 ) : string
	local cframeBytes : {number}, _ : number = CFrameTo10Bytes( boundsCFrame )
	local sizeBytes : {number}, _ : number = Vector3To24Bytes( boundsSize )
	local totalBits : number = (#cframeBytes * 8) + (#sizeBytes * 8)
	-- print(totalBits, #cframeBytes, #sizeBytes)
	local boundsBuffer = buffer.create( totalBits )
	for index, value in cframeBytes do
		buffer.writei8(boundsBuffer, index, value)
	end
	for index, value in sizeBytes do
		buffer.writei8(boundsBuffer, index + #cframeBytes, value)
	end
	return boundsBuffer
end

local function EncodeBodyPartData( partData : { CFrame : CFrame, Velocity : Vector3 } ) : buffer
	local cframeBytes : {number}, _ : number = CFrameTo10Bytes( partData.CFrame )
	local velocityBytes : {number} , _ : number = Vector3To24Bytes( partData.Velocity )
	local totalBits : number = (#cframeBytes * 8) + (#velocityBytes * 8)
	-- print(totalBits, #cframeBytes, #velocityBytes)
	local boundsBuffer = buffer.create( totalBits )
	for index, value in cframeBytes do
		buffer.writei8(boundsBuffer, index, value)
	end
	for index, value in velocityBytes do
		buffer.writei8(boundsBuffer, index + #cframeBytes, value)
	end
	return boundsBuffer
end

local function SignedInt8ToHex(num : number) : string
	local binary : string = ConvertToBinary(num)
	binary = PadBinaryString(binary, 8)
	return string.gsub(binary, '(....)', function(group : string)
		return PadBinaryString( string.format("%02X", tonumber(group, 2) or 0), 2 )
	end)
end

local function EncodeBufferi8ToHex( buff : buffer ) : string
	local steps = buffer.len(buff) / 8
	local hexString = ''
	for index = 0, steps do
		local i8value : number = buffer.readi8(buff, index)
		-- print(i8value, ConvertToBinary(i8value))
		local i8hex = SignedInt8ToHex(i8value)
		hexString ..= i8hex
	end
	return hexString
end

local Module = {}

--[[
	local prepack = {
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
	}

	-- print(prepack)

	local encoded = HttpService:JSONEncode(SerializeDeepTableValues(DeepCopy(prepack, nil)))
	print(#encoded, encoded)

	local packed = HttpService:JSONEncode(Packing.BitPackCharacterFrame(prepack))
	print(#packed, packed)
]]

function Module.BitPackCharacterFrame( frame : CharacterFrame ) : CharacterFramePacked
	-- Bounds CFrame & Size
	local boundsBuffer = EncodeBounds( frame.BoundsCFrame, frame.BoundsSize )
	local boundsInt8HexString = EncodeBufferi8ToHex(boundsBuffer)
	-- BodyPart CFrames / Velocities
	local encodedBPData : { [string] : string } = {}
	for partName, partData in frame.BodyPartData do
		local bpBuffer = EncodeBodyPartData( partData )
		local int8Hex : string = EncodeBufferi8ToHex(bpBuffer)
		encodedBPData[partName] = int8Hex
	end
	return {
		UCUUID = frame.UCUUID,
		Timestamp = frame.Timestamp,
		Bounds = boundsInt8HexString,
		BodyPartData = encodedBPData,
		Tags = frame.Tags,
	}
end

return Module
