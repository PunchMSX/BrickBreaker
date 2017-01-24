;metatile.asm

TILE_BORDER = 255
TILE_EMPTY = 0
TILE_RUBBLE = 1
TILE_BRICK = 2
TILE_SOLIDIFIER = 3
TILE_TARGET = 4

;64 metatiles MAX (8-bit indexed access limitation)
Metatile_Table:
Tile_Empty:
	.db $20, $20, $20, $20
Tile_Rubble:
	.db $0D, $0D, $0D, $0D
Tile_Brick:
	.db $01, $01, $01, $01
Tile_Solidifier:
	.db $0B, $0B, $0C, $0C
Tile_Target:
	.db $15, $16, $17, $18
	
	
	
