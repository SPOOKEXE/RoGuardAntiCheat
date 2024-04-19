--[[
	type HumanoidData = {
		UUID : string, -- each humanoid has a unique identifier
		WalkSpeed : number,
		Health : number,
		Died : boolean, -- can be ignored w/ flags
		JumpPower : number,
		JumpHeight : number,
		RigType : number, -- Enum.HumanoidRigType.R6/R15 0, 1 respectively
		HipHeight : number,
		MaxSlopeAngle : number,
		EvaluateStateMachine : boolean,
		BreakJointsOnDeath : boolean,
		UseJumpPower : boolean,
		Sit : boolean,
		Jump : boolean,
		AutoRotate : boolean,
	}

	type CharacterData = {
		Version : number, -- if any descendant changes in the character (size, humanoid values, etc) then this increments
		Position : Vector3,
		Direction : Vector3,
		BoundsSize : Vector3, -- bounding box size
		Scale : number,
	}

	type CharacterPhysicsData = {
		UnitVelocity : Vector3,
		Speed : number,
		Mass : number,
		Gravity : number,
	}

	type CharacterLog = {
		ServerJobId : string, -- game.JobId
		PlaceId : number, -- game.PlaceId
		GameName : string, -- game.Name
		UUID : string, -- each character has a unique identifier
		Timestamp : number, -- timestamp using tick()

		Character : CharacterData,
		Humanoid : HumanoidData,
	}
]]

export type HumanoidData = {

}

export type CharacterData = {

}

export type BaseLog = {
	custom : false,

}

export type CharacterLog = BaseLog & {

}

-- if you are creating custom events, inherit this type
export type CustomLog = BaseLog & {
	custom : true,

}

export type ActionData = {
	custom : false,

}

export type WhitelistTeleportAction = ActionData & {

}

export type BlacklistTeleportAction = ActionData & {

}

export type WhitelistNoClipAction = ActionData & {

}

export type BlacklistNoClipAction = ActionData & {

}

export type WhitelistFastSpeedAction = ActionData & {

}

export type BlacklistFastSpeedAction = ActionData & {

}

export type WhitelistRemoteMiddlewareAction = ActionData & {

}

export type BlacklistRemoteMiddlewareAction = ActionData & {

}

-- if you are creating custom actions, inherit this type
export type CustomActionData = ActionData & {
	custom : true,

}

export type EventData = {

}

export type CharacterPropertiesUpdateEvent = EventData & {

}

export type HumanoidPropertiesUpdateEvent = EventData & {

}

export type CharacterSpawnEvent = EventData & {

}

export type CharacterDeathEvent = EventData & {

}

-- if you are creating custom events, inherit this type
export type CustomEventData = EventData & {
	custom : true,

}

return true
