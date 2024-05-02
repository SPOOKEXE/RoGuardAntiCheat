
## BACKEND-INFORMATION (account specific)

User Data:
- UserId : number
- RegisteredGames : dict[str, *RegisteredGameData*]

RegisteredGameData:
- Game Name : string
- PlaceId : number
- UniverseId : number
- Timestamp : number
- *UniqueSaltKey* : string

## ANTI-CHEAT INFORMATION (non-account specific)

Player Information:
- (PRIMARY) UserId : number
- Unique User Names
- Unique Display Names
- Related Game UUIDs : list[*Game Information*.UUID]

Game Information:
- (PRIMARY) UUID : string
- Game Name : string
- PlaceId : number
- UniverseId : number
- CreatorId : number
- CreatorType : string
- CreatedTimestamp : number

Gamme Server Information:
- (PRIMARY) UUID : string
- *Game UUID* : string
- JobId : string
- Timestamp : number
- Duration : number
- Tracked Players Ids : list[*Player Information*.UserId]

Character Information:
- (PRIMARY) UUID : string
- UserId : number
- Timestamp : number
- CharacterTracker : list[*Character Data*.UUID]

Character Data:
- (PRIMARY) UUID : string
- Timestamp : number
- BoundsPosition : *Positional Data*
- BoundsSize (u16, 2^14 = 16,384, 1 bit sign, 1 bit 'out of bounds' flag.)
- BasePartCFrames : dict[str, *Positional Data*] -- Character.Head, Character.Torso, Character.Accessory.Handle, etc
- Humanoid Properties dict[str, Value / Full Enum Path]
- Character Events : list[*Character Event Item*]
- Custom Events : list[*Custom Event Item*]

Positional Data:
- Position                 (u16, 2^14 = 16,384, 1 bit sign, 1 bit 'out of bounds' flag.)
- Stepped Horziontal Angle (u8, 2 bits each quad deep)
- Stepped Vertical Angle   (u8, 2 bits each quad deep)

Character Event Item:
- Event Type (Descendant Added, Descendant Removed, Humanoid Property Changed, BasePart Property Changed)
- Timestamp : number
- Duration

Custom Event Item:
- Event Type (Fire Bullet, Grapple Wall, Teleported, etc)
- Timestamp : number
- Duration : number

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
i. sha256(PLACE_ID .. OWNER_ID .. UNIQUE_SALT_KEY) where UNIQUE_SALT_KEY is given to the user when they register the game.
ii. If mismatch, ignore the data.
iii. Have a test to check whether the it will be registered as valid.
