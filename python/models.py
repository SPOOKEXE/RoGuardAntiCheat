
from pydantic import BaseModel

class HumanoidData(BaseModel):
	pass

class CharacterData(BaseModel):
	pass

class CharacterPhysics(BaseModel):
	pass

class CharacterLog(BaseModel):
	pass

class ActionData(BaseModel):
	pass

class WhitelistTeleportAction(ActionData):
	pass

class BlacklistTeleportAction(ActionData):
	pass

class WhitelistNoClipAction(ActionData):
	pass

class BlacklistNoClipAction(ActionData):
	pass

class WhitelistFastSpeedAction(ActionData):
	pass

class BlacklistFastSpeedAction(ActionData):
	pass

class WhitelistRemoteMiddlewareAction(ActionData):
	pass

class BlacklistRemoteMiddlewareAction(ActionData):
	pass

class EventData(ActionData):
	pass

class CharacterPropertiesUpdateEvent(EventData):
	pass

class HumanoidPropertiesUpdateEvent(EventData):
	pass

class CharacterSpawnEvent(EventData):
	pass

class CharacterDeathEvent(EventData):
	pass

class ServerStartupEvent(EventData):
	pass

class ServerShutdownEvent(EventData):
	pass
