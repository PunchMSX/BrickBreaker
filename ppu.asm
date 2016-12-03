;PPU.asm

;A = value to be written
;X = # of sequential writes.
PPU_WriteByteSeq:
.loop
	STA $2007
	DEX
	BNE .loop
	
	RTS
	