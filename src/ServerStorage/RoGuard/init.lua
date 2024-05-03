
--[[
	Your API key is account-specific so make sure you grab that from your registered account information.

	Allowed Value Types:
	- no instances / userdata are allowed in parameters. It will be null when sent as network traffic!

]]

--[[

	TODO:
	- convert cframes to Position XYZ + horizontal/vertical angles ( 12 values -> 5 values)

]]

local Configuration = {
	AntiCheatBackendURL = "http://127.0.0.1:5000",
	AntiCheatAPIKey = "123123123",

	-- character physics
	SNAPSHOT_FREQUENCY = 1 / 10, -- interval between character frame
	CHARACTER_SPAWN_REGISTER_DELAY = 1, -- wait for character to be ready

	-- database push
	UpdatesDeferred = false, -- deffered = only when 'Module.SendUpdatesToServer' is called
	DATABASE_PUSH_FREQUENCY = 2, -- increase if http limit is being hit (minimum 1 second)

	-- initial health check config
	HEALTH_MAX_RETRIES = 3,
	HEALTH_RETRY_INTERVAL = 5,

	-- debug tools
	EnableHumanoidPropertyTracking = true,
	EnableHumanoidEventTracking = true,
	EnableCharacterPhysicsTracking = false,
}

local HttpService = game:GetService("HttpService")
local Players = game:GetService('Players')
local RunService = game:GetService("RunService")

local MaidClassModule = require(script.Maid)
local zlibModule = require(script.zlib)

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

export type StandardCharacterEvent = {
	CharacterUUID : string,
	Event : number,
	Timestamp : number,
	Parameters : { any },
}

local TrackedBodyParts = {
	-- core body
	'Head',
	'HumanoidRootPart', 'Torso', 'UpperTorso', 'LowerTorso',
	-- arms
	'Left Arm', 'Right Arm',
	'LeftUpperArm', 'LeftHand', 'RightUpperArm', 'RightHand',
	-- legs
	'Left Leg', 'Right Leg',
	'LeftUpperLeg', 'RightUpperLeg', 'LeftFoot', 'RightFoot',
}

-- THIS IS SPECIFIC TO YOUR SITUATION - MAP HERE AND ON SERVER PROPERLY!
local SpecialCharacterEncodeMapping = {
	['HumanoidRootPart'] = '$a',
	-- R15
	['UpperTorso'] = '$b',
	['LowerTorso'] = '$c',
	['LeftUpperArm'] = '$d',
	['LeftUpperLeg'] = '$e',
	['LeftFoot'] = '$f',
	['RightUpperArm'] = '$g',
	['RightUpperLeg'] = '$h',
	['RightFoot'] = '$i',
	-- R6
	['Right Leg'] = '$j',
	['Left Leg'] = '$k',
	['Left Arm'] = '$l',
	['Right Arm'] = '$m',
	-- extra
	["BoundsCFrame"] = '$n',
	["BoundsSize"] = '$o',
	["Timestamp"] = '$p',
	["UCUUID"] = '$q',
}

local StandardCharacterEvents = { Spawn = 1, Death = 2, HumanoidPropertyChanged = 3, }

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

local function GenerateUUID()
	return tostring(math.round(tick() * 100))
end

local function RoundNumber( value, places ) : number
	return tonumber(string.format("%."..(places or 0).."f", value))
end

local function RoundArrayNumbers( array : {any}, places : number )
	for index, value in array do
		if typeof(value) == 'number' then
			-- https://devforum.roblox.com/t/rounding-to-1-decimal-point/673504
			array[index] = RoundNumber( value, places )
		end
	end
	return array
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

local function ConvertCFrameToXZYAnglePair( cf : CFrame ) : ( number, number, number, number, number )
	local lookVector = cf.LookVector
	local upVector = cf.UpVector
	-- get the horizontal plane angle
	local hAngle = math.atan2(Vector3.xAxis:Dot(lookVector), Vector3.zAxis:Dot(lookVector))
	-- get the vertical plane angle
	local vAngle = math.atan2(lookVector.Y, upVector.Y) + math.pi
	vAngle = (vAngle + math.pi) % (math.pi * 2)
	-- return the values
	local x, y, z = cf.Position.X, cf.Position.Y, cf.Position.Z
	return x,y,z,hAngle,vAngle
end

local function SerializeDeepTableValues( value : any ) : any
	if typeof(value) == 'Vector3' then
		local arrayForm = RoundArrayNumbers({'V3', value.X, value.Y, value.Z}, 1)
		return ArrayJoin("|", arrayForm)
	elseif typeof(value) == 'CFrame' then
		-- X, Y, Z, LookX, LookY, LookZ, RightX, RightY, RightZ, UpX, UpY, UpZ
		local x,y,z,hA,vA = ConvertCFrameToXZYAnglePair( value )
		x = RoundNumber(x, 1)
		y = RoundNumber(x, 1)
		z = RoundNumber(x, 1)
		hA = RoundNumber(hA, 3)
		vA = RoundNumber(vA, 3)
		local arrayForm = {'CF',x,y,z,hA,vA}
		return ArrayJoin("|", arrayForm)
	elseif typeof(value) == 'EnumItem' then
		local encoded = tostring(value)
		return string.sub(encoded, #'Enum.')
	elseif typeof(value) == 'number' then
		return RoundNumber(value, 3)
	elseif typeof(value) == 'string' then
		return value
	elseif typeof(value) == 'table' then
		for key, item in value do
			-- NOTE: assumes keys are NOT userdata/instance
			value[key] = SerializeDeepTableValues( item )
		end
		return value
	end
	warn(string.format('unsupported type in serializing: %s', typeof(value)))
	return value
end

local function ApplySpecialMappingToString( value : string ) : string
	for key, replace in SpecialCharacterEncodeMapping do
		value = string.gsub(value, key, replace)
	end
	return value
end

local function RequestAsync( path : string, method : "POST" | "GET", body : {}, headers : {}? ) : RequestResponse
	if RunService:IsStudio() and path ~= '/health' then
		return nil
	end

	local DEFAULT_HEADERS = { ['Content-Type'] = 'application/json' }
	for k, v in headers do
		DEFAULT_HEADERS[k] = v
	end

	if body then
		SerializeDeepTableValues(body) -- serialize CFrames, Vector3s, etc
		body = HttpService:JSONEncode(body)
		body = ApplySpecialMappingToString(body)
		body = zlibModule.Zlib.Compress(body, {level = 6})
	end

	local response = nil

	local success, value = pcall(function()
		response = HttpService:RequestAsync({
			Url = Configuration.AntiCheatBackendURL .. path,
			Method = method,
			Headers = DEFAULT_HEADERS,
			Body = body,
		})
	end)

	if not success then
		warn(value)
		return nil
	end

	return response
end

local function RequestAPI( path : string, method : "POST" | "GET", body : {}? ) : RequestResponse
	local HEADERS = { ['X-API-KEY'] = Configuration.AntiCheatAPIKey }
	return RequestAsync( path, method, body, HEADERS )
end

local ANTI_CHEAT_VERSION : number = 1
local ServerInfo = { ANTI_CHEAT_VERSION = ANTI_CHEAT_VERSION, PlaceId = game.PlaceId, PlaceVersion = game.PlaceVersion, JobId = game.JobId, }
local States = { GlobalMaid = MaidClassModule.New(), }

-- // Module // --
local Module = {}

Module.TrackedBodyParts = TrackedBodyParts

function Module.IsBackendAvailable() : boolean
	while States.BackendAvailableQueue do
		task.wait(1)
	end
	if States.NextHealthCheck and time() < States.NextHealthCheck then
		return States.Health
	end
	States.BackendAvailableQueue = true
	-- yield here
	local response = RequestAPI('/health', 'GET', nil)
	local retryNumber = 0
	local isAvailable = response and response.Success
	while not isAvailable and retryNumber < Configuration.HEALTH_MAX_RETRIES do
		local message = 'Anti-Cheat backend is not available. Waiting for it to be available. %s/%s'
		warn(string.format(message, retryNumber, Configuration.HEALTH_MAX_RETRIES))
		retryNumber += 1
		task.wait(Configuration.HEALTH_RETRY_INTERVAL)
		response = RequestAPI('/health', 'GET', nil)
		isAvailable = response and response.Success
	end
	States.NextHealthCheck = time() + 10
	States.Health = isAvailable or false
	States.BackendAvailableQueue = false
	return States.Health
end

function Module.RegisterPlayers( players : {Player} ) : boolean
	local userIds = {}
	for _, player in players do
		table.insert(userIds, player.UserId)
	end
	local ServerData = DeepCopy( ServerInfo, nil )
	ServerData.TrackedIds = userIds
	local Response = RequestAPI('/register-players', 'POST', ServerData)
	return Response and Response.Success
end

function Module.DeRegisterPlayers( players : {Player} ) : boolean
	local userIds = {}
	for _, player in players do
		table.insert(userIds, player.UserId)
	end
	local ServerData = DeepCopy( ServerInfo, nil )
	ServerData.TrackedIds = userIds
	local Response = RequestAPI('/deregister-players', 'POST', ServerData)
	return Response.Success
end

function Module.RegisterServer() : boolean
	local ServerData = DeepCopy( ServerInfo, nil )
	local Response = RequestAPI('/register-server-instance', 'POST', ServerData)
	return Response and Response.Success
end

function Module.DeRegisterServer() : boolean
	local ServerData = DeepCopy( ServerInfo, nil )
	local Response = RequestAPI('/deregister-server-instance', 'POST', ServerData)
	return Response and Response.Success
end

function Module.CreateCharacterEvent( event : number, uuid : string, ... : any? ) : StandardCharacterEvent
	return { Event = event, Timestamp = tick(), CharacterUUID = uuid, Parameters = {...}, }
end

function Module.SetDeferredState( enabled : boolean )
	States.DeferredUpdates = enabled
end

function Module.SendUpdatesToServer()
	States.SendUpdatesToServer = true
end

function Module.ClearCachedCharacterEvents()
	States.CharacterEventQueue = {}
end

function Module.ClearCachedCharacterUpdates()
	States.CharacterUpdateQueue = {}
end

function Module.RegisterCharacter( character : Model, player : Player ) : LiveUniqueCharacter?
	local humanoid : Humanoid = character:WaitForChild('Humanoid', 2)
	if not humanoid then
		return
	end

	task.wait(Configuration.CHARACTER_SPAWN_REGISTER_DELAY) -- wait for character to be ready

	local uniqueUUID : string = GenerateUUID()
	local uniqueCharacter : LiveUniqueCharacter = {
		UUID = uniqueUUID,
		humanoid = humanoid,
		character = character,
		player = player,
	}

	local reCharacterTags = {}
	ServerInfo = DeepCopy(ServerInfo)
	ServerInfo.Character = {UUID = uniqueUUID, UserId = player.UserId, Timestamp = tick(), Tags=reCharacterTags}
	task.spawn(RequestAPI, '/register-character', 'POST', ServerInfo)

	table.insert(States.ActiveCharacters, uniqueCharacter)
	Module.CreateCharacterEvent(StandardCharacterEvents.Spawn, uniqueUUID)

	local Maid = MaidClassModule.New()

	Maid:Give(humanoid.Died:Connect(function()
		Maid:Cleanup()
	end))

	Maid:Give(character.Destroying:Connect(function()
		Maid:Cleanup()
	end))

	Maid:Give(function()
		local index = table.find(States.ActiveCharacters, uniqueCharacter)
		while index do
			table.remove(States.ActiveCharacters, index)
			index = table.find(States.ActiveCharacters, uniqueCharacter)
		end
		if Configuration.EnableHumanoidEventTracking then
			Module.CreateCharacterEvent(StandardCharacterEvents.Death, uniqueUUID)
		end
		local deCharacterTags = {}
		ServerInfo = DeepCopy(ServerInfo)
		ServerInfo.Character = {UUID = uniqueUUID, UserId = player.UserId, Timestamp = tick(), Tags=deCharacterTags}
		task.spawn(RequestAPI, '/deregister-character', 'POST', ServerInfo)
	end)

	return uniqueCharacter
end

function Module.CreateCharacterFrame( uniqueCharacter : LiveUniqueCharacter ) : CharacterFrame?
	if uniqueCharacter.humanoid.Health <= 0 then
		return
	end

	local boundsCFrame, boundsSize = uniqueCharacter.character:GetBoundingBox()

	local bodyCFrames = {}
	local bodyVelocities = {}
	for _, basePart in uniqueCharacter.character:GetChildren() do
		if basePart:IsA('BasePart') and table.find(TrackedBodyParts, basePart.Name) then
			bodyCFrames[basePart.Name] = basePart.CFrame
			bodyVelocities[basePart.Name] = basePart.AssemblyLinearVelocity
		end
	end

	local customTags = { }

	local CharacterFrame : CharacterFrame = {
		UUID = GenerateUUID(),
		UCUUID = uniqueCharacter.UUID,
		Timestamp = tick(),
		BoundsCFrame = boundsCFrame,
		BoundsSize = boundsSize,
		BPCF = bodyCFrames,
		BPVel = bodyVelocities,
		Tags = customTags,
	}

	return CharacterFrame
end

-- DO NOT CALL UNLESS YOU KNOW WHAT YOU ARE DOING!
-- DATABASE IS RATE LIMITING TO 'TWO REQUESTS PER SECOND' BUT CALL ONCE PER SECOND
function Module._SendCachedToDatabase() : boolean
	-- pull the data
	local PhysicsData = States.CharacterUpdateQueue
	local RegisteredEvents = States.CharacterEventQueue
	States.CharacterUpdateQueue = {}
	States.CharacterEventQueue = {}
	-- send the data
	local UpdateQuery = DeepCopy(ServerInfo, nil)
	UpdateQuery.PhysicsData = PhysicsData
	UpdateQuery.RegisteredEvents = RegisteredEvents
	print(UpdateQuery)
	local Response = RequestAPI('/append-data', ServerInfo)
	return Response and Response.Success
end

function Module.StartSystemLoop()

	-- loop until backend is available
	local isAvailable = Module.IsBackendAvailable()

	if not isAvailable then
		error('Failed to connect to the anti-cheat database. Cannot continue starting up anticheat.')
	end

	-- attempt to register server
	if not Module.RegisterServer() then
		error('Failed to register server in backend. Cannot continue starting up anticheat.')
	end

	-- register all the players
	Module.RegisterPlayers(Players:GetPlayers())
	States.GlobalMaid:Give(Players.PlayerAdded:Connect(function(LocalPlayer : Player)
		Module.RegisterPlayers({LocalPlayer})
	end))

	States.GlobalMaid:Give(Players.PlayerRemoving:Connect(function(LocalPlayer : Player)
		Module.DeRegisterPlayers({LocalPlayer})
	end))

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
	local nextSnapshot = -1
	States.GlobalMaid:Give(RunService.Heartbeat:Connect(function(_)
		if not Configuration.EnableCharacterPhysicsTracking then
			return
		end
		if time() < nextSnapshot then
			return
		end
		nextSnapshot = time() + Configuration.SNAPSHOT_FREQUENCY
		for _, item in States.ActiveCharacters do
			local uniqueCharacter : LiveUniqueCharacter = table.unpack(item)
			local frame = Module.CreateCharacterFrame( uniqueCharacter )
			if not frame then
				continue
			end
			table.insert( States.CharacterUpdateQueue, frame )
		end
	end))

	-- send information to database
	task.spawn(function()
		while true do
			local interval = math.max( Configuration.DATABASE_PUSH_FREQUENCY, 1 )
			task.wait( interval )
			-- check if we're sending updates
			if not Configuration.SendUpdatesToServer then
				continue
			end
			-- check if deferred (other scripts tell us when to send data to database)
			if Configuration.UpdatesDeferred then
				Configuration.SendUpdatesToServer = false
			end
			-- send values to database
			Module._SendCachedToDatabase()
		end
	end)

	-- server closing hook
	game:BindToClose(function()
		States.GlobalMaid:Cleanup()
		Module._SendCachedToDatabase()
		Module.DeRegisterServer()
	end)

end

function Module.Init(_)

	-- Module.SetDeferredState( Configuration.UpdatesDeferred )

	task.delay(3, function()
		local player = Players:GetPlayers()[1]
		local character = player.Character
		local frames = {}
		for _ = 1, 100 do
			local frame = Module.CreateCharacterFrame({
				UUID = 'totally_unique',
				humanoid = character.Humanoid,
				character = character,
				player = player,
			})
			table.insert(frames, frame)
			task.wait(0.05)
		end
		frames = SerializeDeepTableValues(frames)
		frames = HttpService:JSONEncode(frames)
		print('encoded', #frames)
		frames = ApplySpecialMappingToString( frames )
		frames = zlibModule.Zlib.Compress(frames, {level = 6})
		print('compressed', #frames)
	end)

end

function Module.Start()

	task.spawn(Module.StartSystemLoop)

end

return Module
