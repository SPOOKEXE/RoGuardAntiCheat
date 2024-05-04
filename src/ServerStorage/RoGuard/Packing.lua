
export type CharacterFrame = {
	UCUUID : string,
	Timestamp : number,
	BoundsCFrame : CFrame,
	BoundsSize : Vector3,
	BPCF : { [string] : CFrame },
	BPVel : { [string] : Vector3 },
	Tags : { [string] : any },
	-- Character Events : list[*Character Event Item*]
	-- Custom Events : list[*Custom Event Item*]
}

local Module = {}

function Module.PackCharacterFrame( frame : CharacterFrame )

	local b = buffer.fromstring("asdas")
	print(buffer.tostring(b))

end

return Module
