
local Module = {}

-- Misc

function Module.NumberToBinary( value : number, places : number ) : string
	local function check(number)
		local safe = math.floor(number)
		if number == safe then
			return 0
		else
			return 1
		end
	end
	local binary = ""
	while math.floor(value) > 0 do
		local num = value / 2
		value = math.floor(num)
		binary ..= check(num)
	end
	if math.floor(value) == 0 then
		binary = string.reverse(binary)
	end
	return binary
end

function Module.PadBinaryStringLeft( value : string, bits : number ) : string
	return string.rep('0', math.max(bits - #value, 0))..value
end

function Module.PadBinaryStringRight( value : string, bits : number ) : string
	return value..string.rep('0', math.max(bits - #value, 0))
end

function Module.NumberToHex(value : number) : string
	return string.format("%X", value)
end

function Module.HexToNumber(value : string) : number
	return tonumber(value, 16) or -1
end

-- Int8

function Module.PackInt8IntoInt16(a : number, b : number) : number
	return
		bit32.lshift(a, 8) +
		b
end

function Module.PackInt8IntoInt32(a : number, b : number, c : number, d : number) : number
	return
		bit32.lshift(a, 24) +
		bit32.lshift(b, 16) +
		bit32.lshift(c, 8) +
		d
end

function Module.PackInt8IntoInt64(a : number, b : number, c : number, d : number, e : number, f : number, g : number, h : number) : number
	return
		bit32.lshift(a, 56) +
		bit32.lshift(b, 48) +
		bit32.lshift(c, 40) +
		bit32.lshift(d, 32) +
		bit32.lshift(e, 24) +
		bit32.lshift(f, 16) +
		bit32.lshift(g, 8) +
		h
end

-- Int16
function Module.PackInt16ToInt32(a : number, b : number) : number
	return
		bit32.lshift(a, 16) +
		b
end

function Module.PackInt16ToInt64(a : number, b : number, c : number, d : number) : number
	return
		bit32.lshift(a, 48) +
		bit32.lshift(b, 32) +
		bit32.lshift(c, 16) +
		d
end

function Module.UnpackInt16ToInt8(value : number) : (number, number)
	return
		bit32.extract(value, 08, 8),
		bit32.extract(value, 00, 8)
end

-- Int32

function Module.PackInt32ToInt64(a : number, b : number) : number
	return
		bit32.lshift(a, 32) +
		b
end

function Module.UnpackInt32ToInt16(value : number) : (number, number)
	return
		bit32.extract(value, 16, 16),
		bit32.extract(value, 00, 16)
end

function Module.UnpackInt32ToInt8(value : number) : (number, number, number, number)
	return
		bit32.extract(value, 24, 8),
		bit32.extract(value, 16, 8),
		bit32.extract(value, 08, 8),
		bit32.extract(value, 00, 8)
end

-- Int64

function Module.UnpackInt64ToInt32(value : number) : (number, number)
	return
		bit32.extract(value, 32, 32),
		bit32.extract(value, 0, 32)
end

function Module.UnpackInt64ToInt16(value : number) : (number, number, number, number)
	return
		bit32.extract(value, 48, 16),
		bit32.extract(value, 32, 16),
		bit32.extract(value, 16, 16),
		bit32.extract(value, 00, 16)
end

function Module.UnpackInt64ToInt8(value : number) : (number, number, number, number, number, number, number, number)
	return
		bit32.extract(value, 56, 8),
		bit32.extract(value, 48, 8),
		bit32.extract(value, 40, 8),
		bit32.extract(value, 32, 8),
		bit32.extract(value, 24, 8),
		bit32.extract(value, 16, 8),
		bit32.extract(value, 08, 8),
		bit32.extract(value, 00, 8)
end

return Module
