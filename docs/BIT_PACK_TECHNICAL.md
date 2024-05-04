
## Original Stats

Bounds Position = 6x 64bit = 384 bits per
Bounds Size = 3x 64bit = 192 bits per
Positional/Velocity Data = 6x64bit + 3x64bit = 384 + 192 bits per = 576 bits per pair
= 748 bits + (384 per positional)

## Bit Pack Stats

Bounds CFrame:
- X (-2048>2048, 1 sign 12 data bits = 13 bits)
- Y (-2048>2048, 1 sign 12 data bits = 13 bits)
- Z (-2048>2048, 1 sign 12 data bits = 13 bits)
- Roll (0 - ~6300, unsigned 13 bits)
- Yaw (0 - ~6300, unsigned 13 bits)
- Pitch (0 - ~6300, unsigned 13 bits)
= 78 bits per bounds size - 80 bits total, 2 spare

Bounds Size:
- X (bounds -128>128, 1 sign 7 data bits = 8 bits)
- Y (bounds -128>128, 1 sign 7 data bits = 8 bits)
- Z (bounds -128>128, 1 sign 7 data bits = 8 bits)
= 24 bits per bounds size

**= 78 + 24 = 104 bits for bounds cframe and size**

Velocity Vectors:
- X (bounds -128>128, 1 sign 7 data bits = 8 bits)
- Y (bounds -128>128, 1 sign 7 data bits = 8 bits)
- Z (bounds -128>128, 1 sign 7 data bits = 8 bits)
= 24 bits per velocity value

Positional Data:
- X (-2048>2048, 1 sign 12 data bits = 13 bits)
- Y (-2048>2048, 1 sign 12 data bits = 13 bits)
- Z (-2048>2048, 1 sign 12 data bits = 13 bits)
- Roll (0 - ~6300, unsigned 13 bits)
- Yaw (0 - ~6300, unsigned 13 bits)
- Pitch (0 - ~6300, unsigned 13 bits)
= 78 bits per bounds size - 80 bits total, 2 spare

**= 24 + 78 = 104 bits per body part**

## Special Encoding of Data using a map?

{"BPVel":{"RightUpperArm":"V3|0|-38.6|0","Head":"V3|0|-38.6|0","UpperTorso":"V3|0|-38.6|0","HumanoidRootPart":"V3|0|-38.6|0","LeftUpperArm":"V3|0|-38.6|0","RightFoot":"V3|0|-38.6|0","LeftHand":"V3|0|-38.6|0","RightHand":"V3|0|-38.6|0","LowerTorso":"V3|0|-38.6|0","LeftFoot":"V3|0|-38.6|0","LeftUpperLeg":"V3|0|-38.6|0","RightUpperLeg":"V3|0|-38.6|0"},"BoundsCFrame":"CF|-0|-0|-0|-3.142|0","UUID":"171476638662","Tags":[],"BoundsSize":"V3|3.8|5.6|2","Timestamp":1714766386.617,"UCUUID":"totally_unique","BPCF":{"RightUpperArm":"CF|1.1|1.1|1.1|-3.142|0","Head":"CF|0|0|0|-3.142|0","UpperTorso":"CF|0|0|0|-3.142|0","HumanoidRootPart":"CF|0|0|0|-3.142|0","LeftUpperArm":"CF|-1.1|-1.1|-1.1|-3.142|0","RightFoot":"CF|0.4|0.4|0.4|-3.142|0","LeftHand":"CF|-1.5|-1.5|-1.5|-3.142|0","RightHand":"CF|1.5|1.5|1.5|-3.142|0","LowerTorso":"CF|0|0|0|-3.142|0","LeftFoot":"CF|-0.4|-0.4|-0.4|-3.142|0","LeftUpperLeg":"CF|-0.4|-0.4|-0.4|-3.142|0","RightUpperLeg":"CF|0.4|0.4|0.4|-3.142|0"}}

CHARACTERS = { A-Za-z0-9{}:|-.",[]  } = ~70 unique
2 ^ 7bits = 128 possible, covers all cases
- every character is 7 bits, so shift by 7 for each value.
