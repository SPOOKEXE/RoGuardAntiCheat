
## BACKEND-INFORMATION (account specific)

User Data:
- AccountUUID : string
- Roblox UserIds : { number }
- Roblox Groups : { number }
- Registered Games : dict[str, *Registered Game Data*.UUID]

Registered Game Data:
- UUID : string
- Place Id : number
- Creator Id : number
- Creator Type : string
- *UNIQUE_SALT_KEY* : string = "".join([uuid4().hex for _ in range(2)])
- Timestamp : number

## ANTI-CHEAT INFORMATION (non-account specific)

Player Information:
- (PRIMARY) UserId : number
- Unique User Names
- Unique Display Names
- Associated Games : list[*Game Information*.PlaceId]
- Cheated Games : list[*Game Information*.PlaceId]

Game Information:
- (PRIMARY) UUID : string
- Game Name : string
- PlaceId : number
- CreatorId : number
- CreatorType : string
- RegisteredTimestamp : number
- Every Tracked Players : list[*Player Information*.UserId]
- Detected Cheats : list[{ *Player Information*.UserId, Timestamp }]

Game Server Information:
- (PRIMARY) UUID : string
- *Game Information*.UUID : string
- JobId : string
- Server Version : number
- Timestamp : number
- Duration : number
- Tracked Players Ids : list[*Player Information*.UserId]

Unique Character Information:
- (PRIMARY) UUID : string
- *Game Server Information*.UUID : string
- UserId : number
- Timestamp : number
- FrameLogs : list[*Character Frame Log*.UUID]
- Tags : dict[str, Any]

Character Frame Log:
- (PRIMARY) UUID : string
- *Unique Character Information*.UUID : string
- Timestamp : number
- BoundsPosition : *Positional Data*
- BoundsSize
- BasePartCFrames : dict[str, *Positional Data*] -- Character.Head, Character.Torso, Character.Accessory.Handle, etc
- Humanoid Properties dict[str, Value / Full Enum Path]
- Character Events : list[*Character Event Item*]
- Custom Events : list[*Custom Event Item*]
- Tags : dict[str, Any]

Positional Data:
- Position
- Stepped Horziontal Angle
- Stepped Vertical Angle

Character Event Item:
- Event Type (Descendant Added/Removed, Humanoid Property Changed, Fire Bullet, Grapple Wall, Teleported, etc)
- Timestamp : number
- Duration : number
- Parameters : list[any]

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

Deffered and Immediate Database Logging:
- FPS Games should send log data when the rounds end.
- Other games can queue the data and send during a set interval.

Other Information:
- JSON Encode the data and compress with zlib before sending over wire.

Authentication:
- API Header Cookie is the following:
i. sha256(CREATOR_ID .. UNIQUE_SALT_KEY) where UNIQUE_SALT_KEY is given to the user when they register the game.
ii. If mismatch, ignore the data.
iii. Have a test to check whether the it will be registered as valid.

Database:
- shared into multiple tables:
	i. registered users (backend)
	ii. registered games (backend)
	iii. roblox players (A.C.)
	iv. roblox places (A.C.)
	v. registered servers (A.C.)
	vi. players in servers (A.C.)
	vii. spawned character (A.C.)
	iix. character logging frames (A.C.)

## Testing Game

Give a widget that allows for users to:
- enable fly
- enable no-clip
- enable teleporting
- enable ESP
- enable "event/tag" tracker (so you know if they're simulating commands or cheating)
