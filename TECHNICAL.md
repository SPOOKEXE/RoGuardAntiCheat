
Game Information:
- UUID : string
- Game Name : string
- PlaceId : number
- UniverseId : number
- Timestamp : number

Server Information:
- Game Information UUID : string
- JobId : string
- Timestamp : number
- Duration : number

Player Information:
- Unique User Names
- Unique Display Names
- User Ids
- *Character Information*

Character Information:
- UUID : string
- Timestamp : number
- Tracker : dict[str, Character Data]

Character Data:
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
