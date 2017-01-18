;metatile.asm

Metatile_Table:
	.dw Tile_Empty
	.dw Tile_Rubble
	.dw Tile_Brick
	
Tile_Empty:
	.db $20, $20, $20, $20
Tile_Rubble:
	.db $0D, $0D, $0D, $0D
Tile_Brick:
	.db $01, $01, $01, $01
	
	
	
