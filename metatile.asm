;metatile.asm

TILE_BORDER = 31
TILE_EMPTY = 0
TILE_SOLIDIFIER = 1
TILE_TARGET = 2

TILE_RUBBLE = 3
TILE_DAMAGEDBRICK = 4
TILE_BRICK = 5

TILE_GLASSSHARDS = 6
TILE_BROKENGLASSWARE = 7
TILE_GLASSWARE = 8

TILE_BROKENGLASSPANEL = 9
TILE_GLASSPANEL = 10

TILE_METALSHARDS = 11
TILE_DAMAGEDMETALBRICK = 12
TILE_METALBRICK = 13

TILE_INVALID = 14

_Z = TILE_BORDER
_E = TILE_EMPTY
_B = TILE_BRICK
_S = TILE_SOLIDIFIER
_T = TILE_TARGET
_G = TILE_GLASSWARE
_P = TILE_GLASSPANEL
_M = TILE_METALBRICK

;31 = invincible
;0 = break without reflecting
;1 = break and reflect
;2-30 = reflect only
Metatile_Durability:
	.db %11100000
	.db %11100000
	.db %11100000
	
	.db %11100000
	.db %00000000
	.db %00000000
	
	.db %11100000
	.db %11100000
	.db %00000000
	
	.db %11100000
	.db %00000000

	.db %11100000
	.db %01000000
	.db %01100000
	
;64 metatiles MAX (8-bit indexed access limitation)
Metatile_Table:
Tile_Empty:
	.db $20, $20, $20, $20
Tile_Solidifier:
	.db $0B, $0B, $0C, $0C
Tile_Target:
	.db $15, $16, $17, $18
	
Tile_Rubble:
	.db $0D, $0D, $0D, $0D
Tile_DamagedBrick:
	.db $01, $7C, $7C, $01
Tile_Brick:
	.db $01, $01, $01, $01
	
Tile_GlassShards:
	.db $5B, $5C, $5F, $6C
Tile_BrokenGlassware:
	.db $5B, $5C, $1F, $0F
Tile_Glassware:
	.db $1D, $1E, $1F, $0F
	
Tile_BrokenGlasspanel:
	.db $5B, $5C, $6F, $7F
Tile_Glasspanel:
	.db $6D, $6E, $6F, $7F

Tile_MetalShards
	.db $87, $88, $89, $8A
Tile_DamagedMetalBrick:
	.db $8B, $8C, $8D, $8E
Tile_MetalBrick
	.db $83, $84, $85, $86
