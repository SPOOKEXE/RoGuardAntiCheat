
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

local function PadBinaryString( item : string, bits : number ) : string
	for _ = 1, math.max(bits - #item, 0) do
		item = '0'..item
	end
	return item
end

local function ConvertToBinary(decimal : number) : string
	local function check(number)
		local safe = math.floor(number)
		if number == safe then
			return 0
		else
			return 1
		end
	end
	local binary = ""
	while math.floor(decimal) > 0 do
		local num = decimal / 2
		decimal = math.floor(num)
		binary ..= check(num)
	end
	if math.floor(decimal) == 0 then
		binary = string.reverse(binary)
	end
	return binary
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

local function ArrayJoin(sep : string, array : {any}) : string
	local value = tostring(array[1])
	for i, item in array do
		if i == 1 then
			continue
		end
		value ..= sep..tostring(item)
	end
	return value
end

local function EncodeBounds( boundsCFrame : CFrame, boundsSize : Vector3 ) : buffer
	local cframeBytes : {number}, _ : number = CFrameTo10Bytes( boundsCFrame )
	local sizeBytes : {number}, _ : number = Vector3To24Bytes( boundsSize )
	local totalBits : number = (#cframeBytes * 8) + (#sizeBytes * 8)
	-- print(totalBits, cframeBytes, sizeBytes)
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
	-- print(totalBits, cframeBytes, velocityBytes)
	local boundsBuffer = buffer.create( totalBits )
	for index, value in cframeBytes do
		buffer.writei8(boundsBuffer, index, value)
	end
	for index, value in velocityBytes do
		buffer.writei8(boundsBuffer, index + #cframeBytes, value)
	end
	return boundsBuffer
end

local Module = {}

function Module.BitPackCharacterFrame( frame : CharacterFrame ) : CharacterFramePacked
	-- Bounds CFrame & Size
	local boundsBuffer = EncodeBounds( frame.BoundsCFrame, frame.BoundsSize )
	-- BodyPart CFrames / Velocities
	local encodedBPData : { [string] : string } = {}
	for partName, partData in frame.BodyPartData do
		local bpBuffer = EncodeBodyPartData( partData )
		encodedBPData[partName] = buffer.tostring(bpBuffer)
	end
	return {
		UCUUID = frame.UCUUID,
		Timestamp = frame.Timestamp,
		Bounds = buffer.tostring(boundsBuffer),
		BodyPartData = encodedBPData,
		Tags = frame.Tags,
	}
end

return Module
