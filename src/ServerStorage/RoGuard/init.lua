
local HttpService = game:GetService("HttpService")
local Players = game:GetService('Players')
local RunService = game:GetService("RunService")

local MaidClassModule = require(script.Maid)

local AntiCheatBackendURL = "http://127.0.0.1:5000"
local AntiCheatAPIKey = "123123123"

export type RequestResponse = {
	Success : boolean,
	StatusCode : number,
	StatusMessage : string,
	Headers : {},
	Body : string?,
}

export type UniqueCharacter = {
	UUID : string,
	ServerInfoUUID : string,
	UserId : number,
	Timestamp : number,
	-- FrameLogs : list[*Character Frame Log*.UUID]
	Tags : { [string] : any },
}

export type LiveUniqueCharacter = {
	UUID : string,
	humanoid : Humanoid,
	character : Model,
	player : Player,
}

export type CharacterFrame = {
	UUID : string,
	UniqueCharacterUUID : string,
	Timestamp : number,
	BoundsCFrame : {Vector3},
	BoundsSize : Vector3,
	BasePartCFrames : { [string] : {Vector3} },
	HumanoidProperties : { [string]  : string | Enum },
	Tags : { [string] : any },
	-- Character Events : list[*Character Event Item*]
	-- Custom Events : list[*Custom Event Item*]
}

export type StandardCharacterEvent = {

}

export type CustomCharacterEvent = {

}

local TrackedHumanoidProperties = {
	-- bools
	'AutoRotate', 'Jump', 'PlatformStand', 'Sit',
	-- numbers
	'WalkSpeed', 'Health', 'MaxHealth', 'JumpHeight',
	-- enums
	'FloorMaterial', 'RigType',
}

local function DeepCopy( item : any, ref : {}? ) : any
	if ref == nil then
		ref = {}
	end
	if typeof(item) == "table" then
		if ref[item] then
			return ref[item]
		end
		for key, value in item do
			ref[key]= DeepCopy(key, ref)
			ref[value] = DeepCopy(value, ref)
			item[ ref[key] ] = ref[value]
		end
	end
	return item
end

local function RequestAsync( path : string, method : "POST" | "GET", body : {}, headers : {}? ) : RequestResponse
	local DEFAULT_HEADERS = { ['Content-Type'] = 'application/json' }
	for k, v in headers do
		DEFAULT_HEADERS[k] = v
	end
	return HttpService:RequestAsync({
		Url = AntiCheatBackendURL .. path,
		Method = method,
		Headers = DEFAULT_HEADERS,
		Body = body and HttpService:JSONEncode(body) or nil,
	})
end

local function RequestAPI( path : string, method : "POST" | "GET", body : {}? ) : RequestResponse
	local HEADERS = { ['X-API-KEY'] = AntiCheatAPIKey }
	return RequestAsync( path, method, body, HEADERS )
end

local ServerInfo = { PlaceId = game.PlaceId, PlaceVersion = game.PlaceVersion, JobId = game.JobId, }

local States = {}

-- // Module // --
local Module = {}

function Module.IsBackendAvailable( ) : boolean
	if States.NextHealthCheck and time() < States.NextHealthCheck then
		return States.Health
	end
	States.NextHealthCheck = time() + 10
	local Response = RequestAPI('/health', 'GET', nil)
	States.Health = Response.Success
	return States.Health
end

function Module.RegisterPlayers( players : {Player} ) : boolean
	local userIds = {}
	for _, player in players do
		table.insert(userIds, player.UserId)
	end
	local ServerData = DeepCopy( ServerInfo, nil )
	ServerData.TrackedIds = userIds
	local Response = RequestAPI('/register-players-in-server', 'POST', ServerData)
	return Response.Success
end

function Module.RegisterServer() : boolean
	local ServerData = DeepCopy( ServerInfo, nil )
	local Response = RequestAPI('/register-server-instance', 'POST', ServerData)
	return Response.Success
end

function Module.CreateStandardCharacteEvent( ) : StandardCharacterEvent

end

function Module.CreateCustomCharacteEvent( ) : CustomCharacterEvent

end

function Module.RegisterCharacter( character : Model, player : Player ) : LiveUniqueCharacter?
	-- States.ActiveCharacters : { LiveUniqueCharacter }
	-- States.CharacterUpdateQueue = {  }
	-- States.CharacterEventQueue = {}

	local humanoid : Humanoid = character:WaitForChild('Humanoid', 2)
	if not humanoid then
		return
	end

	local uniqueUUID : string = HttpService:GenerateGUID(false) .. HttpService:GenerateGUID(false)
	local uniqueCharacter : LiveUniqueCharacter = { UUID=uniqueUUID, humanoid=humanoid, character=character, player=player, }

	table.insert(States.ActiveCharacters, uniqueCharacter)

	local Maid = MaidClassModule.New()

	Maid:Give(humanoid.Died:Connect(function()
		Maid:Cleanup()
	end))

	Maid:Give(character.Destroying:Connect(function()
		Maid:Cleanup()
	end))

	return uniqueCharacter
end

function Module.CreateCharacterFrame( uniqueCharacter : LiveUniqueCharacter ) : CharacterFrame?
	if uniqueCharacter.humanoid.Health <= 0 then
		return
	end

	local boundsCFrame, boundsSize = uniqueCharacter.character:GetBoundingBox()

	local bodyCFrames = {}
	for _, basePart in uniqueCharacter.character:GetChildren() do
		if basePart:IsA('BasePart') then
			local cframe : CFrame = basePart.CFrame
			bodyCFrames[basePart.Name] = {cframe.Position, cframe.LookVector, cframe.UpVector}
		end
	end

	local humanoidProperties = {}
	for _, propName in TrackedHumanoidProperties do
		-- serialize vlaue and store
		local value = uniqueCharacter.humanoid[propName]
		if typeof(value) == 'EnumItem' then
			value = tostring(value)
		end
		humanoidProperties[propName] = value
	end

	local customTags = { }

	local CharacterFrame : CharacterFrame = {
		UUID = HttpService:GenerateGUID(false)..HttpService:GenerateGUID(false),
		UniqueCharacterUUID = uniqueCharacter.UUID,
		Timestamp = time(),
		BoundsCFrame = {boundsCFrame.Position, boundsCFrame.LookVector, boundsCFrame.UpVector},
		BoundsSize = boundsSize,
		BasePartCFrames = bodyCFrames,
		HumanoidProperties = humanoidProperties,
		Tags = customTags,
	}

	return CharacterFrame
end

function Module.StartSystemLoop()

	-- loop until backend is available
	while not Module.IsBackendAvailable() do
		warn('Anti-Cheat backend is not available. Waiting for it to be available.')
		task.wait(10)
	end

	-- attempt to register server
	if not Module.RegisterServer() then
		error('Failed to register server in backend. Cannot continue starting up anticheat.')
	end

	-- register all the players
	Module.RegisterPlayers(Players:GetPlayers())
	Players.PlayerAdded:Connect(function(LocalPlayer : Player)
		Module.RegisterPlayers({LocalPlayer})
	end)

	-- handle player characters
	States.CharacterUpdateQueue = {}
	States.CharacterEventQueue = {}
	States.ActiveCharacters = {}

	for _, LocalPlayer in Players:GetPlayers() do
		if LocalPlayer.Character then
			Module.RegisterCharacter( LocalPlayer.Character, LocalPlayer )
		end
		LocalPlayer.CharacterAdded:Connect(function(character)
			Module.RegisterCharacter( character, LocalPlayer )
		end)
	end

	-- loop for character values
	RunService.Heartbeat:Connect(function(deltaTime)
		local now : number = time()
		for _, item in States.ActiveCharacters do
			local uniqueCharacter : LiveUniqueCharacter = table.unpack(item)
			local frame = Module.CreateCharacterFrame( uniqueCharacter )
			if not frame then
				continue
			end
			table.insert( States.CharacterUpdateQueue, frame )
		end
	end)

end

function Module.Init(_)

end

function Module.Start()

	task.spawn(Module.StartSystemLoop)
	game:BindToClose(Module.OnSystemStop)

end

return Module
