;metatile.asm

TILE_BORDER = 255
TILE_EMPTY = 0
TILE_RUBBLE = 1
TILE_BRICK = 2

;64 metatiles MAX (8-bit indexed access limitation)
Metatile_Table:
Tile_Empty:
	.db $20, $20, $20, $20
Tile_Rubble:
	.db $0D, $0D, $0D, $0D
Tile_Brick:
	.db $01, $01, $01, $01
	
	
	
