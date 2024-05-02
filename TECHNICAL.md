
Game Information:
- UUID
- Game Name
- PlaceId
- UniverseId
- Timestamp

Server Information:
- Game Info UUID
- JobId
- Date
- Duration

Player Information:
- Unique User Names
- Unique Display Names
- User Ids
- Character Data

Character Information:
- UUID
- Timestamp
- Tracker : dict[str, Character Data]

Character Data:
- Timestamp
- BoundsCFrame
- BoundsSize (u16, 2^14 = 16,384, 1 bit sign, 1 bit 'out of bounds' flag.)
- BasePartCFrames : dict[str, CFrame Data] -- Character.Head, Character.Torso, Character.Accessory.Handle, etc
- Humanoid Properties
- Character Events : list[Character Event Item]
- Custom Events : list[Custom Event Item]

CFrame Data:
- Position                 (u16, 2^14 = 16,384, 1 bit sign, 1 bit 'out of bounds' flag.)
- Stepped Horziontal Angle (u8, 2 bits each quad deep)
- Stepped Vertical Angle   (u8, 2 bits each quad deep)

Character Event Item:
- Event Type (Descendant Added, Descendant Removed, Humanoid Property Changed)
- Timestamp
- Duration

Custom Event Item:
- Event Type (Fire Bullet, Grapple Wall, Teleported, etc)
- Timestamp
- Duration
