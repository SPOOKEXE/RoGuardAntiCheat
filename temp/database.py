
from __future__ import annotations
from typing import Union
from databases import Database
from databases.interfaces import Record

import os
import asyncio

FILE_DIRECTORY = os.path.dirname(os.path.realpath(__file__))

class BaseDatabase(Database):

	async def execute_constructors(
		self : BaseDatabase,
		constructors : list[str]
	) -> None:
		for constructor in constructors:
			await self.execute(constructor)

	async def start(
		self : BaseDatabase
	) -> None:
		print(f'Connecting to SQLite Database: {self.filename}')
		await self.connect()

	def __init__( self, filename : str, *args, **kwargs ) -> BaseDatabase:
		self.filename = filename
		super().__init__( "sqlite+aiosqlite:///" + filename, *args, **kwargs)

class DatabaseAPI:

	DATABASES_DIRECTORY = os.path.join(FILE_DIRECTORY, 'databases')
	_cache : dict[str, BaseDatabase] = {}

	@staticmethod
	async def get_database(
		name : str
	) -> Union[BaseDatabase, None]:
		if DatabaseAPI._cache.get(name) is not None:
			return DatabaseAPI._cache[name]

		filepath : str = os.path.join( DatabaseAPI.DATABASES_DIRECTORY, name + '.db' )
		if os.path.exists(filepath) is False: return None

		db = BaseDatabase(filepath)
		DatabaseAPI._cache[name] = db
		return db

	@staticmethod
	async def get_databases(
	) -> list[str]:
		os.makedirs(DatabaseAPI.DATABASES_DIRECTORY, exist_ok=True)
		return [ os.path.splitext(item)[0] for item in os.listdir(DatabaseAPI.DATABASES_DIRECTORY) ]

	@staticmethod
	async def register_database(
		name : str,
		constructors : Union[list[str], None]
	) -> None:
		os.makedirs(DatabaseAPI.DATABASES_DIRECTORY, exist_ok=True)
		database : bool = await DatabaseAPI.get_database(name)
		if database is not None:
			return
		filepath : str = os.path.join( DatabaseAPI.DATABASES_DIRECTORY, name + '.db' )
		database = BaseDatabase(filepath)
		await database.start()
		if constructors is not None:
			await database.execute_constructors(constructors)

	@staticmethod
	async def execute_one(
		name : str,
		query : str,
		data : Union[dict, None]
	) -> bool:
		database : BaseDatabase = await DatabaseAPI.get_database(name)
		if database is None: return False
		await database.execute(query, data)
		return True

	@staticmethod
	async def execute_many(
		name : str,
		query : str,
		values : Union[list[dict], None]
	) -> bool:
		database : BaseDatabase = await DatabaseAPI.get_database(name)
		if database is None: return False
		await database.execute_many(query, values)
		return True

	@staticmethod
	async def fetch_one(
		name : str,
		query : str,
		data : Union[dict, None]
	) -> Union[dict, None]:
		database : BaseDatabase = await DatabaseAPI.get_database(name)
		if database is None: return None
		record : Record = await database.fetch_one(query, data)
		if record is None: return None
		return dict(record)

	@staticmethod
	async def fetch_all(
		name : str,
		query : str,
		values : Union[list[dict], None]
	) -> Union[list, None]:
		database : BaseDatabase = await DatabaseAPI.get_database(name)
		if database is None: return None
		records : list[Record] = await database.fetch_all(query, values)
		return [ dict(record) for record in records if record is not None ]

	@staticmethod
	async def execute_and_return(
		name : str,
		query : str,
		data : Union[dict, None]
	) -> Union[dict, None]:
		database : BaseDatabase = await DatabaseAPI.get_database(name)
		if database is None: return None
		record = await database.fetch_one(query, data)
		return dict(record) if record is not None else None

async def test() -> None:
	pass

if __name__ == '__main__':
	asyncio.run(test())
