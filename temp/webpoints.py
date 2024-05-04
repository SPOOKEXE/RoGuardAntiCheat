
import uvicorn
import asyncio
import time

from typing import Any, Literal, Union
from fastapi import Depends, FastAPI, Body, HTTPException, Header, Request, Security
from fastapi.security import api_key
from guilds import InternalGuildsAPI, DEFAULT_GUILD_AUDIT_LOG_LIMIT, DEFAULT_GUILD_CHAT_MESSAGE_LIMIT

APP_API_KEY : str = None

async def set_api_key( value : str ) -> None:
	global APP_API_KEY
	APP_API_KEY = value

async def host_fastapp(
	app : FastAPI,
	host : str,
	port : int
) -> None:
	print(f"Hosting App: {app.title}")
	await uvicorn.Server(uvicorn.Config(app, host=host, port=port, log_level='debug')).serve()

async def validate_api_key(
	key : Union[str, None] = Security(api_key.APIKeyHeader(name="X-API-KEY"))
) -> None:
	if APP_API_KEY is not None and key != APP_API_KEY:
		raise HTTPException(status_code=401, detail="Unauthorized")
	return None

guilds_api = FastAPI( title="Guilds API", description="Tutorial Series Guilds API", version="1.0.0" )

@guilds_api.middleware("http")
async def process_time_adder( request : Request, call_next ) -> Any:
	start_time = time.time()
	response = await call_next(request)
	process_time = time.time() - start_time
	response.headers["X-Process-Time"] = str(process_time)
	return response

@guilds_api.get('/')
async def root( ) -> dict:
	return {'message' : 'No path'}

@guilds_api.get('/health')
async def health( ) -> dict:
	return {"message": "OK"}

@guilds_api.post('/is-rank-permissions-valid', summary='IsRankPermissionsValid', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def IsRankPermissionsValid(
	permissions : dict = Body(None, embed=True)
) -> bool:
	return await InternalGuildsAPI.IsRankPermissionsValid(permissions)

@guilds_api.post('/is-guild-name-available', summary='IsGuildNameAvailable', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def IsGuildNameAvailable(
	name : str = Body(None, embed=True)
) -> bool:
	return await InternalGuildsAPI.IsGuildNameAvailable(name)

@guilds_api.post('/get-guild-info-from-guild-id', summary='GetGuildInfoFromGuildId', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def GetGuildInfoFromGuildId(
	guild_id : int = Body(-1, embed=True)
) -> Union[dict, None]:
	return await InternalGuildsAPI.GetGuildInfoFromGuildId(guild_id)

@guilds_api.post('/get-guild-info-from-user-id', summary='GetGuildInfoFromGuildId', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def GetGuildInfoFromUserId(
	user_id : int = Body(-1, embed=True)
) -> Union[dict, None]:
	return await InternalGuildsAPI.GetGuildInfoFromUserId(user_id)

@guilds_api.post('/update-guild-display-info', summary='UpdateGuildDisplayInfo', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def UpdateGuildDisplayInfo(
	guild_id : int = Body(-1, embed=True),
	description : str = Body(None, embed=True),
	accessibility : int = Body(-1, embed=True),
	emblem : int = Body(-1, embed=True)
) -> Union[dict, None]:
	return await InternalGuildsAPI.UpdateGuildDisplayInfo(guild_id, description, accessibility, emblem)

@guilds_api.post('/get-user-rank-in-guild', summary='GetUserRankInGuild', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def GetUserRankInGuild(
	guild_id : int = Body(-1, embed=True),
	user_id : int = Body(-1, embed=True)
) -> Union[dict, None]:
	return await InternalGuildsAPI.GetUserRankInGuild(guild_id, user_id)

@guilds_api.post('/get-guild-rank-by-id', summary='GetGuildRankById', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def GetGuildRankById(
	rank_id : int = Body(-1, embed=True)
) -> Union[dict, None]:
	return await InternalGuildsAPI.GetGuildRankById(rank_id)

@guilds_api.post('/add-user-id-to-guild', summary='AddUserIdToGuild', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def AddUserIdToGuild(
	guild_id : int = Body(-1, embed=True),
	user_id : int = Body(-1, embed=True)
) -> Union[dict, None]:
	return await InternalGuildsAPI.AddUserIdToGuild(guild_id, user_id)

@guilds_api.post('/set-user-id-rank-in-guild', summary='SetUserIdRankInGuild', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def SetUserIdRankInGuild(
	guild_id : int = Body(-1, embed=True),
	user_id : int = Body(-1, embed=True),
	rank_id : int = Body(-1, embed=True)
) -> bool:
	return await InternalGuildsAPI.SetUserIdRankInGuild(guild_id, user_id, rank_id)

@guilds_api.post('/change-guild-rank-permissions', summary='ChangeGuildRankPermissions', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def ChangeGuildRankPermissions(
	guild_id : int = Body(-1, embed=True),
	rank_id : int = Body(-1, embed=True),
	permissions : dict = Body(None, embed=True)
) -> bool:
	return await InternalGuildsAPI.ChangeGuildRankPermissions(guild_id, rank_id, permissions)

@guilds_api.post('/create-rank-in-guild', summary='CreateRankInGuild', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def CreateRankInGuild(
	guild_id : int = Body(-1, embed=True),
	name : str = Body(None, embed=True),
	protected : bool = Body(False, embed=True)
) -> Union[dict, None]:
	return await InternalGuildsAPI.CreateRankInGuild(guild_id, name, protected=protected)

@guilds_api.post('/remove-rank-in-guild', summary='RemoveRankInGuild', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def RemoveRankInGuild(
	guild_id : int = Body(-1, embed=True),
	rank_id : int = Body(-1, embed=True)
) -> bool:
	return await InternalGuildsAPI.RemoveRankInGuild(guild_id, rank_id)

@guilds_api.post('/set-default-rank-in-guild', summary='SetDefaultRankInGuild', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def SetDefaultRankInGuild(
	guild_id : int = Body(-1, embed=True),
	rank_id : int = Body(-1, embed=True)
) -> bool:
	return await InternalGuildsAPI.SetDefaultRankInGuild(guild_id, rank_id)

@guilds_api.post('/kick-user-id-from-guild', summary='KickUserIdFromGuild', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def KickUserIdFromGuild(
	guild_id : int = Body(-1, embed=True),
	user_id : int = Body(-1, embed=True),
) -> bool:
	return await InternalGuildsAPI.KickUserIdFromGuild(guild_id, user_id)

@guilds_api.post('/delete-guild', summary='DeleteGuild', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def DeleteGuild(
	guild_id : int = Body(-1, embed=True),
) -> bool:
	return await InternalGuildsAPI.DeleteGuild(guild_id)

@guilds_api.post('/is-user-in-guild-of-id', summary='IsUserInGuildOfId', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def IsUserInGuild(
	guild_id : int = Body(-1, embed=True),
	user_id : int = Body(-1, embed=True),
) -> bool:
	return await InternalGuildsAPI.IsUserInGuild(guild_id, user_id)

@guilds_api.post('/transfer-guild-ownership', summary='TransferGuildOwnership', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def TransferGuildOwnership(
	guild_id : int = Body(-1, embed=True),
	user_id : int = Body(-1, embed=True)
) -> bool:
	return await InternalGuildsAPI.TransferGuildOwnership(guild_id, user_id)

@guilds_api.post('/get-guild-banned-user-ids', summary='GetGuildBannedUserIds', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def GetGuildBannedUserIds(
	guild_id : int = Body(-1, embed=True),
) -> list[int]:
	return await InternalGuildsAPI.GetGuildBannedUserIds(guild_id)

@guilds_api.post('/ban-user-id-from-guild', summary='BanUserIdFromGuild', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def BanUserIdFromGuild(
	guild_id : int = Body(-1, embed=True),
	user_id : int = Body(-1, embed=True)
) -> bool:
	return await InternalGuildsAPI.BanUserIdFromGuild(guild_id, user_id)

@guilds_api.post('/unban-user-id-from-guild', summary='UnbanUserIdFromGuild', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def UnbanUserIdFromGuild(
	guild_id : int = Body(-1, embed=True),
	user_id : int = Body(-1, embed=True)
) -> bool:
	return await InternalGuildsAPI.UnbanUserIdFromGuild(guild_id, user_id)

@guilds_api.post('/get-guild-chat-message-from-id', summary='GetGuildChatMessageFromId', tags=['guild-chat'], dependencies=[Depends(validate_api_key)])
async def GetGuildChatMessageFromId(
	message_id : int = Body(-1, embed=True)
) -> Union[dict, None]:
	return await InternalGuildsAPI.GetGuildChatMessageFromId(message_id)

@guilds_api.post('/create-guild-chat-message', summary='CreateGuildChatMessage', tags=['guild-chat'], dependencies=[Depends(validate_api_key)])
async def CreateGuildChatMessage(
	guild_id : int = Body(-1, embed=True),
	user_id : int = Body(-1, embed=True),
	message : str = Body(None, embed=True)
) -> Union[dict, None]:
	return await InternalGuildsAPI.CreateGuildChatMessage(guild_id, user_id, message)

@guilds_api.post('/remove-guild-chat-message', summary='RemoveGuildChatMessage', tags=['guild-chat'], dependencies=[Depends(validate_api_key)])
async def RemoveGuildChatMessage(
	message_id : int = Body(-1, embed=True)
) -> bool:
	return await InternalGuildsAPI.RemoveGuildChatMessage(message_id)

@guilds_api.post('/get-guild-chat-messages', summary='GetGuildChatMessages', tags=['guild-chat'], dependencies=[Depends(validate_api_key)])
async def GetGuildChatMessages(
	guild_id : int = Body(-1, embed=True),
	offset : int = Body(0, embed=True),
	limit : int = Body(DEFAULT_GUILD_CHAT_MESSAGE_LIMIT, embed=True),
	include_deleted : bool = Body(False, embed=True)
) -> list[dict]:
	return await InternalGuildsAPI.GetGuildChatMessages(guild_id, offset=offset, limit=limit, include_deleted=include_deleted)

@guilds_api.post('/create-guild-audit-log', summary='CreateGuildAuditLog', tags=['guild-audit-log'], dependencies=[Depends(validate_api_key)])
async def CreateGuildAuditLog(
	guild_id : int = Body(-1, embed=True),
	user_id : int = Body(-1, embed=True),
	action : int = Body(None, embed=True),
	args : list = Body(list(), embed=True),
) -> Union[dict, None]:
	return await InternalGuildsAPI.CreateGuildAuditLog(guild_id, user_id, action, args)

@guilds_api.post('/get-guild-audit-logs', summary='GetGuildAuditLogs', tags=['guild-audit-log'], dependencies=[Depends(validate_api_key)])
async def GetGuildAuditLogs(
	guild_id : int = Body(-1, embed=True),
	offset : int = Body(0, embed=True),
	limit : int = Body(DEFAULT_GUILD_AUDIT_LOG_LIMIT, embed=True)
) -> list[dict]:
	return await InternalGuildsAPI.GetGuildAuditLogs(guild_id, offset=offset, limit=limit)

@guilds_api.post('/get-full-guild-info-from-guild-id', summary='GetFullGuildInfoFromGuildId', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def GetFullGuildInfoFromGuildId(
	guild_id : int = Body(-1, embed=True)
) -> Union[dict, None]:
	return await InternalGuildsAPI.GetFullGuildInfoFromGuildId(guild_id)

@guilds_api.post('/get-full-guild-info-from-user-id', summary='GetFullGuildInfoFromUserId', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def GetFullGuildInfoFromUserId(
	user_id : int = Body(-1, embed=True),
) -> Union[dict, None]:
	return await InternalGuildsAPI.GetFullGuildInfoFromUserId(user_id)

@guilds_api.post('/get-guild-ranks', summary='GetGuildRanks', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def GetGuildRanks(
	guild_id : int = Body(-1, embed=True),
) -> list[dict]:
	return await InternalGuildsAPI.GetGuildRanks(guild_id)

@guilds_api.post('/get-guild-members', summary='GetGuildMembers', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def GetGuildMembers(
	guild_id : int = Body(-1, embed=True),
) -> list[dict]:
	return await InternalGuildsAPI.GetGuildMembers(guild_id)

@guilds_api.post('/get-created-guilds', summary='GetCreatedGuilds', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def GetCreatedGuilds(
	offset : int = Body(-1, embed=True),
	limit : int = Body(DEFAULT_GUILD_CHAT_MESSAGE_LIMIT, embed=True)
) -> list[dict]:
	return await InternalGuildsAPI.GetCreatedGuilds(offset=offset, limit=limit)

@guilds_api.post('/does-guild-have-rank-of-id', summary='DoesGuildHaveRankOfId', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def DoesGuildHaveRankOfId(
	guild_id : int = Body(-1, embed=True),
	rank_id : int = Body(-1, embed=True)
) -> bool:
	return await InternalGuildsAPI.DoesGuildHaveRankOfId(guild_id, rank_id)

@guilds_api.post('/get-created-guilds-full', summary='GetCreatedGuildsFull', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def GetCreatedGuildsFull(
	offset : int = Body(0, embed=True),
	limit : int = Body(DEFAULT_GUILD_CHAT_MESSAGE_LIMIT, embed=True)
) -> list[dict]:
	return await InternalGuildsAPI.GetCreatedGuildsFull(offset=offset, limit=limit)

@guilds_api.post('/create-guild', summary='CreateGuild', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def CreateGuild(
	user_id : int = Body(-1, embed=True),
	name : str = Body(None, embed=True),
	description : str = Body(None, embed=True),
	emblem : int = Body(-1, embed=True)
) -> Union[dict, None]:
	return await InternalGuildsAPI.CreateGuild(user_id, name, description, emblem)

@guilds_api.post('/increment-online-count', summary='IncrementOnlineCount', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def IncrementOnlineCount(
	guild_id : int = Body(-1, embed=True),
	value : Literal[-1, 1] = Body(0, embed=True),
) -> bool:
	return await InternalGuildsAPI.IncrementOnlineCount(guild_id, value)

@guilds_api.post('/change-guild-rank-name', summary='ChangeGuildRankName', tags=['guild-core'], dependencies=[Depends(validate_api_key)])
async def ChangeGuildRankName(
	guild_id : int = Body(-1, embed=True),
	rank_id : int = Body(-1, embed=True),
	name : str = Body(None, embed=True),
) -> bool:
	return await InternalGuildsAPI.ChangeGuildRankName(guild_id, rank_id, name)

async def main( host : str = '0.0.0.0', port : int = 5100, api_key : str = None ) -> None:
	print(f'Setting API_Key to "{api_key}"')
	await set_api_key(api_key)
	await InternalGuildsAPI.initialize()
	await host_fastapp(guilds_api, host, port)
