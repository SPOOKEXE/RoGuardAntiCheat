
from database import DatabaseAPI, BaseDatabase
from guilds import InternalGuildsAPI
from webpoints import set_api_key, main, guilds_api

if __name__ == '__main__':
	import sys, asyncio, os
	from typing import Union
	if os.path.isabs( sys.argv[0] ) is True:
		# ran using 'Run Python File' button
		api_key = 'guilds-api-key-10001010101'
	else:
		# ran through command prompt
		api_key : Union[str, None] = None if len(sys.argv) == 1 else sys.argv[1]
	asyncio.run(main(host='0.0.0.0', port=5100, api_key=api_key))
