
from __future__ import annotations
from typing import Literal, Union
from database import DatabaseAPI

import asyncio
import time
import json

DEFAULT_GUILD_CHAT_MESSAGE_LIMIT : int = 50
DEFAULT_GUILD_AUDIT_LOG_LIMIT : int = 50
DEFAULT_GUILD_GET_ALL_LIMIT : int = 25

def get_time() -> int:
	return int(round(time.time()))

class InternalGuildsAPI:

	DATABASE_NAME : str = 'guilds'
	OUTPUT_DELETED_TO_FILE : bool = False

	@staticmethod
	async def initialize( ) -> None:
		constructors = [
			"CREATE TABLE IF NOT EXISTS master (guild_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT NOT NULL, accessibility INTEGER DEFAULT 0, emblem INTEGER NOT NULL, owner_id INTEGER NOT NULL, owner_rank_id INTEGER DEFAULT -1, default_rank_id INTEGER DEFAULT -1, total_members INTEGER DEFAULT 1, total_online INTEGER DEFAULT 0, creation INTEGER NOT NULL);",
			"CREATE TABLE IF NOT EXISTS members (user_id INTEGER PRIMARY KEY UNIQUE, guild_id INTEGER NOT NULL, rank_id INTEGER DEFAULT -1, timestamp INTEGER NOT NULL);",
			"CREATE TABLE IF NOT EXISTS ranks (rank_id INTEGER PRIMARY KEY AUTOINCREMENT, guild_id INTEGER NOT NULL, name TEXT NOT NULL, protected INTEGER NOT NULL, permissions TEXT NOT NULL);",
			"CREATE TABLE IF NOT EXISTS banned (id INTEGER PRIMARY KEY AUTOINCREMENT, guild_id INTEGER, banned_json TEXT)",
			"CREATE TABLE IF NOT EXISTS guild_chat (id INTEGER PRIMARY KEY AUTOINCREMENT, guild_id INTEGER, user_id INTEGER, message TEXT, timestamp INTEGER, deleted INTEGER)",
			"CREATE TABLE IF NOT EXISTS audit_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, guild_id INTEGER, user_id INTEGER, timestamp INTEGER, action INTEGER, args TEXT)"
		]
		await DatabaseAPI.register_database(InternalGuildsAPI.DATABASE_NAME, constructors)

	@staticmethod
	async def IsRankPermissionsValid(
		permissions : dict
	) -> bool:
		if isinstance(permissions, dict) is False: return False
		return True # TODO

	@staticmethod
	async def IsGuildNameAvailable(
		name : str
	) -> bool:
		query = 'SELECT guild_id FROM master WHERE name=:name COLLATE NOCASE'
		data = {'name' : name}
		value = await DatabaseAPI.fetch_one(InternalGuildsAPI.DATABASE_NAME, query, data)
		return value is None

	@staticmethod
	async def GetGuildInfoFromGuildId(
		guild_id : int
	) -> Union[dict, None]:
		query = 'SELECT * FROM master WHERE guild_id=:guild_id'
		data = {'guild_id' : guild_id}
		return await DatabaseAPI.fetch_one(InternalGuildsAPI.DATABASE_NAME, query, data)

	@staticmethod
	async def GetGuildInfoFromUserId(
		user_id : int
	) -> Union[dict, None]:
		query = 'SELECT guild_id FROM members WHERE user_id=:user_id'
		data = {'user_id' : user_id}
		value = await DatabaseAPI.fetch_one(InternalGuildsAPI.DATABASE_NAME, query, data)
		if value is None: return None
		gid : int = value['guild_id']
		return await InternalGuildsAPI.GetGuildInfoFromGuildId(gid)

	@staticmethod
	async def GetGuildMembers(
		guild_id : int
	) -> Union[list[dict], None]:
		query = 'SELECT * FROM members WHERE guild_id=:guild_id'
		data = {'guild_id' : guild_id}
		return await DatabaseAPI.fetch_all(InternalGuildsAPI.DATABASE_NAME, query, data)

	@staticmethod
	async def GetGuildRanks(
		guild_id : int
	) -> Union[list[dict], None]:
		query = 'SELECT rank_id, name, protected, permissions FROM ranks WHERE guild_id=:guild_id'
		data = {'guild_id' : guild_id}
		return await DatabaseAPI.fetch_all(InternalGuildsAPI.DATABASE_NAME, query, data)

	@staticmethod
	async def GetFullGuildInfoFromGuildId(
		guild_id : int
	) -> Union[dict, None]:
		data = await InternalGuildsAPI.GetGuildInfoFromGuildId(guild_id)
		if data is None: return None
		data["ranks"] = await InternalGuildsAPI.GetGuildRanks( guild_id )
		data["members"] = await InternalGuildsAPI.GetGuildMembers( guild_id )
		data["banned"] = await InternalGuildsAPI.GetGuildBannedUserIds( guild_id )
		return data

	@staticmethod
	async def GetFullGuildInfoFromUserId(
		user_id : int
	) -> Union[dict, None]:
		query = 'SELECT guild_id FROM members WHERE user_id=:user_id'
		data = {'user_id' : user_id}
		value = await DatabaseAPI.fetch_one(InternalGuildsAPI.DATABASE_NAME, query, data)
		if value is None: return None
		return await InternalGuildsAPI.GetFullGuildInfoFromGuildId( value['guild_id'] )

	@staticmethod
	async def UpdateGuildDisplayInfo(
		guild_id : int,
		description : str,
		accessibility : int,
		emblem : int
	) -> Union[dict, None]:
		guild_data = await InternalGuildsAPI.GetGuildInfoFromGuildId(guild_id)
		if guild_data is None: return None
		query = 'UPDATE master SET description=:description, emblem=:emblem, accessibility=:accessibility WHERE guild_id=:guild_id RETURNING *'
		data = { "guild_id" : guild_id, "description" : description, "emblem" : emblem, "accessibility" : accessibility }
		return await DatabaseAPI.execute_and_return(InternalGuildsAPI.DATABASE_NAME, query, data)

	@staticmethod
	async def GetUserRankInGuild(
		guild_id : int,
		user_id : int
	) -> Union[dict, None]:
		query = 'SELECT * FROM members WHERE user_id=:user_id AND guild_id=:guild_id'
		data = {'user_id' : user_id, 'guild_id' : guild_id}
		record = await DatabaseAPI.fetch_one(InternalGuildsAPI.DATABASE_NAME, query, data)
		return dict(record) if record is not None else None

	@staticmethod
	async def AddUserIdToGuild(
		guild_id : int,
		user_id : int
	) -> Union[dict, None]:
		rank_data = await InternalGuildsAPI.GetUserRankInGuild(guild_id, user_id)
		if rank_data is not None: return rank_data
		guild_data = await InternalGuildsAPI.GetGuildInfoFromGuildId(guild_id)
		if guild_data is None: return None
		# insert into memberz
		query : str = 'INSERT INTO members (user_id, guild_id, rank_id, timestamp) VALUES (:user_id, :guild_id, :rank_id, :timestamp) RETURNING *;'
		data = {"guild_id" : guild_id, "user_id" : user_id, "rank_id" : guild_data['default_rank_id'], 'timestamp' : get_time() }
		response = await DatabaseAPI.execute_and_return(InternalGuildsAPI.DATABASE_NAME, query, data)
		if response is None: return None
		await InternalGuildsAPI.IncrementGuildPlayerCount(guild_id, 1)
		return response

	@staticmethod
	async def SetUserIdRankInGuild(
		guild_id : int,
		user_id : int,
		rank_id : int
	) -> bool:
		rank_data = await InternalGuildsAPI.GetGuildRankById(rank_id)
		if rank_data is None: return False
		if rank_data['guild_id'] != guild_id: return False

		guild_data = await InternalGuildsAPI.GetGuildInfoFromGuildId(guild_id)
		if guild_data is None: return False
		if guild_data["owner_id"] == user_id: return False # owner can't change role

		query = "UPDATE members SET rank_id=:rank_id WHERE user_id=:user_id AND guild_id=:guild_id"
		data = {"guild_id" : guild_id, "user_id" : user_id, "rank_id" : rank_id }
		await DatabaseAPI.execute_one(InternalGuildsAPI.DATABASE_NAME, query, data)
		return True

	@staticmethod
	async def ChangeGuildRankPermissions(
		guild_id : int,
		rank_id : int,
		permissions : dict
	) -> bool:
		is_valid = await InternalGuildsAPI.IsRankPermissionsValid(permissions)
		if is_valid is False: return False

		guild_data = await InternalGuildsAPI.GetGuildInfoFromGuildId(guild_id)
		if guild_data is None: return False

		query = 'UPDATE ranks SET permissions=:permissions WHERE rank_id=:rank_id AND guild_id=:guild_id'
		data = { "guild_id" : guild_id, "rank_id" : rank_id, "permissions" : json.dumps(permissions, separators=(",", ":")) }
		await DatabaseAPI.execute_one(InternalGuildsAPI.DATABASE_NAME, query, data)
		return True

	@staticmethod
	async def CreateRankInGuild(
		guild_id : int,
		name : str,
		protected : bool = False
	) -> Union[dict, None]:
		query : str = 'INSERT INTO ranks (guild_id, name, protected, permissions) VALUES (:guild_id, :name, :protected, :permissions) RETURNING *;'
		data = {'guild_id' : guild_id, 'name' : name, 'permissions' : "{}", 'protected' : int(protected)}
		return await DatabaseAPI.execute_and_return(InternalGuildsAPI.DATABASE_NAME, query, data)

	@staticmethod
	async def DoesGuildHaveRankOfId(
		guild_id : int,
		rank_id : int
	) -> bool:
		query : str = 'SELECT rank_id FROM ranks WHERE guild_id=:guild_id AND rank_id=:rank_id'
		data = {'guild_id' : guild_id, 'rank_id' : rank_id}
		return await DatabaseAPI.fetch_one(InternalGuildsAPI.DATABASE_NAME, query, data) is not None

	@staticmethod
	async def RemoveRankInGuild(
		guild_id : int,
		rank_id : int
	) -> bool:
		rank_data = await InternalGuildsAPI.GetGuildRankById(rank_id)
		if rank_data is None: return False
		if rank_data["protected"] == 1: return False
		if rank_data["guild_id"] != guild_id: return False
		guild_data = await InternalGuildsAPI.GetGuildInfoFromGuildId(guild_id)
		if guild_data is None: return False
		# move players out of rank to the default rank
		default_id : int = guild_data["default_rank_id"]
		query = "UPDATE members SET rank_id=:default_id WHERE rank_id=:rank_id AND guild_id=:guild_id"
		data = {"guild_id" : guild_id, "rank_id" : rank_id, "default_id" : default_id}
		await DatabaseAPI.execute_one(InternalGuildsAPI.DATABASE_NAME, query, data)
		# delete rank
		query = "DELETE FROM ranks WHERE rank_id=:rank_id AND guild_id=:guild_id"
		data = {"guild_id" : guild_id, "rank_id" : rank_id}
		await DatabaseAPI.execute_one(InternalGuildsAPI.DATABASE_NAME, query, data)
		return True

	@staticmethod
	async def GetGuildRankById(
		rank_id : int
	) -> Union[dict, None]:
		query = 'SELECT * FROM ranks WHERE rank_id=:rank_id'
		data = {'rank_id' : rank_id}
		return await DatabaseAPI.fetch_one(InternalGuildsAPI.DATABASE_NAME, query, data)

	@staticmethod
	async def SetDefaultRankInGuild(
		guild_id : int,
		rank_id : int
	) -> bool:
		rank_data = await InternalGuildsAPI.GetGuildRankById( rank_id )
		if rank_data is None: return False
		if rank_data["guild_id"] != guild_id: return False

		guild_data = await InternalGuildsAPI.GetGuildInfoFromGuildId(guild_id)
		if guild_data is None: return False

		if rank_id == guild_data["default_rank_id"]: return True
		if rank_id == guild_data["owner_rank_id"]: return False

		query = "UPDATE master SET default_rank_id=:rank_id WHERE guild_id=:guild_id"
		data = {"guild_id" : guild_id, "rank_id" : rank_id}
		await DatabaseAPI.execute_one(InternalGuildsAPI.DATABASE_NAME, query, data)
		return True

	@staticmethod
	async def IncrementGuildPlayerCount(
		guild_id : int,
		amount : Literal[1, -1]
	) -> bool:
		query = 'SELECT total_members FROM master WHERE guild_id=:guild_id'
		data = {'guild_id' : guild_id}
		value = await DatabaseAPI.fetch_one( InternalGuildsAPI.DATABASE_NAME, query, data )
		if value is None: return False
		new_amount = value['total_members'] + amount
		query = 'UPDATE master SET total_members=:total_members WHERE guild_id=:guild_id'
		data = {'guild_id' : guild_id, 'total_members' : new_amount}
		await DatabaseAPI.execute_one( InternalGuildsAPI.DATABASE_NAME, query, data )
		return True

	@staticmethod
	async def KickUserIdFromGuild(
		guild_id : int,
		user_id : int
	) -> bool:
		# check if the user is in the guild
		user_guild = await InternalGuildsAPI.GetGuildInfoFromUserId(user_id)
		if user_guild is None: return False
		if user_guild['guild_id'] != guild_id: return False
		if user_guild['owner_id'] == user_id: return False # can't kick owner

		# remove from guild and decrement member count
		query = 'DELETE FROM members WHERE user_id=:user_id AND guild_id=:guild_id'
		data = {'user_id' : user_id, 'guild_id' : guild_id}
		await DatabaseAPI.execute_one( InternalGuildsAPI.DATABASE_NAME, query, data )
		await InternalGuildsAPI.IncrementGuildPlayerCount(guild_id, -1)
		return True

	@staticmethod
	async def DeleteGuild(
		guild_id : int
	) -> bool:
		if InternalGuildsAPI.OUTPUT_DELETED_TO_FILE is True:
			backup = await InternalGuildsAPI.GetFullGuildInfoFromGuildId(guild_id)
			if backup is None:
				return True
			with open(f'{guild_id}_backup.json', 'w') as file:
				file.write(json.dumps(backup, indent=4))

		queries = [
			'DELETE FROM master WHERE guild_id=:guild_id',
			'DELETE FROM members WHERE guild_id=:guild_id',
			'DELETE FROM ranks WHERE guild_id=:guild_id',
			'DELETE FROM banned WHERE guild_id=:guild_id',
			'DELETE FROM guild_chat WHERE guild_id=:guild_id',
			'DELETE FROM audit_logs WHERE guild_id=:guild_id',
		]
		data = {'guild_id' : guild_id}
		for query in queries:
			await DatabaseAPI.execute_one( InternalGuildsAPI.DATABASE_NAME, query, data )
		return True

	@staticmethod
	async def IsUserInGuild(
		guild_id : int,
		user_id : int
	) -> bool:
		query = 'SELECT rank_id FROM members WHERE user_id=:user_id AND guild_id=:guild_id'
		data = {'guild_id' : guild_id, 'user_id' : user_id}
		result = await DatabaseAPI.fetch_one(InternalGuildsAPI.DATABASE_NAME, query, data)
		return result is not None

	@staticmethod
	async def TransferGuildOwnership(
		guild_id : int,
		user_id : int
	) -> bool:
		in_guild = await InternalGuildsAPI.IsUserInGuild(guild_id, user_id)
		if in_guild is False: return False

		guild_data = await InternalGuildsAPI.GetGuildInfoFromGuildId( guild_id )
		if guild_data is None: return False
		if guild_data["owner_id"] == user_id: return True

		original_owner : int = guild_data["owner_id"]
		query = "UPDATE members SET rank_id=:rank_id WHERE user_id=:user_id AND guild_id=:guild_id"
		await DatabaseAPI.execute_many(InternalGuildsAPI.DATABASE_NAME, query, [
			{"guild_id" : guild_id, "user_id" : original_owner, "rank_id" : guild_data["default_rank_id"] },
			{"guild_id" : guild_id, "user_id" : user_id, "rank_id" : guild_data["owner_rank_id"] }
		])

		query = "UPDATE master SET owner_id=:owner_id WHERE guild_id=:guild_id"
		data = {"guild_id" : guild_id, "owner_id" : user_id}
		await DatabaseAPI.execute_one(InternalGuildsAPI.DATABASE_NAME, query, data)
		return True

	@staticmethod
	async def GetGuildBannedUserIds(
		guild_id : int
	) -> Union[list, None]:
		query = 'SELECT banned_json FROM banned WHERE guild_id=:guild_id'
		data = {'guild_id' : guild_id}
		value = await DatabaseAPI.fetch_one( InternalGuildsAPI.DATABASE_NAME, query, data )
		try:
			return json.loads(value['banned_json']) if value is not None else []
		except:
			return []

	@staticmethod
	async def BanUserIdFromGuild(
		guild_id : int,
		user_id : int
	) -> bool:
		query = 'SELECT banned_json FROM banned WHERE guild_id=:guild_id'
		data = {'guild_id' : guild_id}
		value = await DatabaseAPI.fetch_one( InternalGuildsAPI.DATABASE_NAME, query, data )
		if value is not None:
			try:
				values = json.loads(value)
			except:
				values = []
			if user_id in values:
				return True # already banned
			values.append(user_id)
			query : str = 'UPDATE banned SET banned_json=:banned_json WHERE guild_id=:guild_id'
		else:
			values = [user_id]
			query : str = 'INSERT INTO banned (guild_id, banned_json) VALUES (:guild_id, :banned_json)'
		data = {'guild_id' : guild_id, 'banned_json' : json.dumps(values, separators=(",", ":")) }
		await DatabaseAPI.execute_one( InternalGuildsAPI.DATABASE_NAME, query, data )
		return True

	@staticmethod
	async def UnbanUserIdFromGuild(
		guild_id : int,
		user_id : int
	) -> bool:
		query = 'SELECT banned_json FROM banned WHERE guild_id=:guild_id'
		data = {'guild_id' : guild_id}
		value = await DatabaseAPI.fetch_one( InternalGuildsAPI.DATABASE_NAME, query, data )
		if value is None:
			return True
		try:
			values = json.loads(value['banned_json'])
		except:
			values = []
		if user_id not in values:
			return True
		values.remove(user_id)
		query : str = 'UPDATE banned SET banned_json=:banned_json WHERE guild_id=:guild_id'
		data = {'guild_id' : guild_id, 'banned_json' : json.dumps(values, separators=(",", ":"))}
		await DatabaseAPI.execute_one( InternalGuildsAPI.DATABASE_NAME, query, data )
		return True

	@staticmethod
	async def GetGuildChatMessageFromId(
		message_id : int
	) -> Union[dict, None]:
		query : str = "SELECT id FROM guild_chat WHERE id=:id"
		data : dict = {"id" : message_id}
		record : dict = await DatabaseAPI.fetch_one( InternalGuildsAPI.DATABASE_NAME, query, data )
		return record if record is not None else None

	@staticmethod
	async def CreateGuildChatMessage(
		guild_id : int,
		user_id : int,
		message : str
	) -> Union[dict, None]:
		query : str = 'INSERT INTO guild_chat(guild_id, user_id, message, timestamp, deleted) VALUES (:guild_id, :user_id, :message, :timestamp, 0) RETURNING *'
		return await DatabaseAPI.execute_and_return(InternalGuildsAPI.DATABASE_NAME, query, {
			"guild_id" : guild_id,
			"user_id" : user_id,
			"message" : message,
			"timestamp" : get_time()
		})

	@staticmethod
	async def RemoveGuildChatMessage(
		message_id : int
	) -> bool:
		message_data : dict = await InternalGuildsAPI.GetGuildChatMessageFromId(message_id)
		if message_data is None: return False
		query : str = 'UPDATE guild_chat SET deleted=1 WHERE id=:message_id'
		data = {'message_id' : message_id}
		await DatabaseAPI.execute_one( InternalGuildsAPI.DATABASE_NAME, query, data)
		return True

	@staticmethod
	async def GetGuildChatMessages(
		guild_id : int,
		offset : int = 0,
		limit : int = DEFAULT_GUILD_CHAT_MESSAGE_LIMIT,
		include_deleted : bool = False
	) -> list[dict]:
		if include_deleted is True:
			query = f"SELECT id, user_id, message, timestamp, deleted FROM guild_chat WHERE guild_id=:guild_id LIMIT {limit} OFFSET {offset}"
		else:
			query = f"SELECT id, user_id, message, timestamp, deleted FROM guild_chat WHERE guild_id=:guild_id AND deleted=0 LIMIT {limit} OFFSET {offset}"
		data = {"guild_id" : guild_id}
		return await DatabaseAPI.fetch_all(InternalGuildsAPI.DATABASE_NAME, query, data)

	@staticmethod
	async def CreateGuildAuditLog(
		guild_id : int,
		user_id : int,
		action : int,
		args : list = list(),
	) -> Union[dict, None]:
		timestamp = get_time()
		query : str = 'INSERT INTO audit_logs(guild_id, user_id, timestamp, action, args) VALUES (:guild_id, :user_id, :timestamp, :action, :args) RETURNING *;'
		return await DatabaseAPI.execute_and_return(InternalGuildsAPI.DATABASE_NAME, query, {
			"guild_id" : guild_id,
			"user_id" : user_id,
			"timestamp" : timestamp,
			"action" : action,
			"args" : json.dumps(args, separators=(",", ":"))
		})

	@staticmethod
	async def GetGuildAuditLogs(
		guild_id : int,
		offset : int = 0,
		limit : int = DEFAULT_GUILD_AUDIT_LOG_LIMIT
	) -> list[dict]:
		query = f"SELECT user_id, timestamp, action, args FROM audit_logs WHERE guild_id=:guild_id LIMIT {limit} OFFSET {offset}"
		data = {"guild_id" : guild_id}
		return await DatabaseAPI.fetch_all(InternalGuildsAPI.DATABASE_NAME, query, data)

	@staticmethod
	async def GetCreatedGuilds(
		offset : int = 0,
		limit : int = DEFAULT_GUILD_GET_ALL_LIMIT
	) -> list[dict]:
		query = f'SELECT * FROM master LIMIT {limit} OFFSET {offset}'
		return await DatabaseAPI.fetch_all(InternalGuildsAPI.DATABASE_NAME, query, None)

	@staticmethod
	async def GetCreatedGuildsFull(
		offset : int = 0,
		limit : int = DEFAULT_GUILD_GET_ALL_LIMIT
	) -> list[dict]:
		query = f'SELECT guild_id FROM master LIMIT {limit} OFFSET {offset} '
		values = await DatabaseAPI.fetch_all(InternalGuildsAPI.DATABASE_NAME, query, None)
		if values is None: return []
		return [ await InternalGuildsAPI.GetFullGuildInfoFromGuildId( value['guild_id'] ) for value in values if value is not None ]

	@staticmethod
	async def CreateGuild(
		user_id : int,
		name : str,
		description : str,
		emblem : int
	) -> Union[dict, None]:
		info = await InternalGuildsAPI.GetGuildInfoFromUserId(user_id)
		if info is not None: return None

		is_name_available : bool = await InternalGuildsAPI.IsGuildNameAvailable(name)
		if is_name_available is False: return None

		# insert to master and get the data
		query = 'INSERT INTO master (name, description, emblem, owner_id, creation) VALUES (:name, :description, :emblem, :owner_id, :creation) RETURNING *;'
		guild_data = await DatabaseAPI.execute_and_return(InternalGuildsAPI.DATABASE_NAME, query, {
			'name' : name,
			'description' : description,
			'emblem' : emblem,
			'owner_id' : user_id,
			'creation' : get_time()
		})

		if guild_data is None: return None

		# insert default ranks and get their ids
		owner_rank : dict = await InternalGuildsAPI.CreateRankInGuild( guild_data['guild_id'], 'Owner', protected=True )
		member_rank : dict = await InternalGuildsAPI.CreateRankInGuild( guild_data['guild_id'], 'Member', protected=True )

		# insert to members
		query : str = 'INSERT INTO members (guild_id, user_id, rank_id, timestamp) VALUES (:guild_id, :user_id, :rank_id, :timestamp) RETURNING *;'
		await DatabaseAPI.execute_one(InternalGuildsAPI.DATABASE_NAME, query, {
			'guild_id' : guild_data['guild_id'],
			'user_id' : user_id,
			'rank_id' : owner_rank['rank_id'],
			'timestamp' : get_time()
		})

		# update guild info
		query : str = 'UPDATE master SET default_rank_id=:default_rank_id, owner_rank_id=:owner_rank_id WHERE guild_id=:guild_id'
		await DatabaseAPI.execute_one(InternalGuildsAPI.DATABASE_NAME, query, { 'guild_id' : guild_data['guild_id'], 'default_rank_id' : member_rank['rank_id'], 'owner_rank_id' : owner_rank['rank_id'] })

		# return all information
		return await InternalGuildsAPI.GetFullGuildInfoFromGuildId( guild_data['guild_id'] )

	@staticmethod
	async def IncrementOnlineCount(
		guild_id : int,
		value : Literal[1, -1]
	) -> bool:
		query = f'SELECT total_online FROM master WHERE guild_id=:guild_id'
		data = await DatabaseAPI.fetch_one(InternalGuildsAPI.DATABASE_NAME, query, {'guild_id' : guild_id})
		if data is None: return False
		new_count : int = max(data['total_online'] + value, 0)
		query : str = 'UPDATE master SET total_online=:total_online WHERE guild_id=:guild_id'
		await DatabaseAPI.execute_one(InternalGuildsAPI.DATABASE_NAME, query, { 'guild_id' : guild_id, 'total_online' : new_count })
		return True

	@staticmethod
	async def ChangeGuildRankName(
		guild_id : int,
		rank_id : int,
		name : str
	) -> bool:
		rank_data = await InternalGuildsAPI.GetGuildRankById(rank_id)
		if rank_data is None: return None
		if rank_data['guild_id'] != guild_id: return None
		query : str = 'UPDATE ranks SET name=:name WHERE rank_id=:rank_id guild_id=:guild_id'
		await DatabaseAPI.execute_one(InternalGuildsAPI.DATABASE_NAME, query, {'guild_id' : guild_id, 'rank_id' : rank_id, 'name' : name})
		return True

async def test() -> None:

	await InternalGuildsAPI.initialize()

	# data = await InternalGuildsAPI.GetFullGuildInfoFromUserId(123123123)
	# print(data)

	# data = await InternalGuildsAPI.CreateGuild(123123123, 'test guild', 'hello world!', 1)
	# print(data)

	# data = await InternalGuildsAPI.GetFullGuildInfoFromUserId(123123123)
	# print(data)

	# get all guilds and output
	# print( await InternalGuildsAPI.GetCreatedGuildsFull(offset=0, limit=9999) )

	# get all guilds and delete them all
	# items = await InternalGuildsAPI.GetCreatedGuildsFull(offset=0, limit=9999)
	# for guild in items:
	# 	await InternalGuildsAPI.DeleteGuild( guild['guild_id'] )

	pass

if __name__ == '__main__':
	asyncio.run(test())
