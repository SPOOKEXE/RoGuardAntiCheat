
from fastapi import FastAPI

import asyncio

# management for backend
async def create_account( ) -> None:
	raise NotImplementedError

async def delete_account( ) -> None:
	raise NotImplementedError

async def get_account_info( ) -> None:
	raise NotImplementedError

async def get_account_places( ) -> None:
	raise NotImplementedError

async def append_place_to_account( ) -> None:
	raise NotImplementedError

async def remove_place_from_account( ) -> None:
	raise NotImplementedError

async def queue_place_for_deletion( ) -> None:
	raise NotImplementedError

async def queue_user_for_deletion( ) -> None:
	raise NotImplementedError

# 'my account for managing my places'
async def get_my_info( ) -> None:
	raise NotImplementedError

async def add_user_to_place( ) -> None:
	raise NotImplementedError

async def remove_user_from_place( ) -> None:
	raise NotImplementedError

async def add_place( ) -> None:
	raise NotImplementedError

async def remove_place( ) -> None:
	raise NotImplementedError

async def query_database( ) -> None:
	raise NotImplementedError

# anti-cheat module
async def health( ) -> None:
	'''Check if the database is available.'''
	raise NotImplementedError

async def register_server_instance( ) -> None:
	'''State this server has started.'''
	raise NotImplementedError

async def deregister_server_instance( ) -> None:
	'''State this server has closed.'''
	raise NotImplementedError

async def register_players( ) -> None:
	'''State the user has joined the game.'''
	raise NotImplementedError

async def deregister_players( ) -> None:
	'''State the user has left the gamea.'''
	raise NotImplementedError

async def query_userid_cheating_score( ) -> None:
	'''Query the user id to check if its estimated they have been cheating or not in the last 10 minutes.'''
	raise NotImplementedError

async def query_userid_ratings( ) -> None:
	'''
	Get the ratings for the user
	- what other games they've cheated in
	- the likeliness they are often cheating
	'''
	raise NotImplementedError
