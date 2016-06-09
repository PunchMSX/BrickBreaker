;********************************************************
;*** B    R    I    X      B    A    T    T    L    E ***
;********************************************************
;- C o p y r i g h t   2 0 1 6   A l e f f   C o r r e a -
;Project start: 05/06/2016   ||     Version ZERO
	
	.inesmap 0 ;no mapper
	.inesmir 0 ;Vertical
	.ineschr 1 ;8kb Character ROM
	.inesprg 2 ;32kb Program ROM

 .ZP
RESERVED_RLE	.ds  8

METASPR_ADDR	.ds 2
OAM_ADDR		.ds 2

 .BSS
 
 .org $300
PPUADDR_NAM		.ds 2
PPUADDR_ATT		.ds 2

PPUCOUNT_NAM	.ds 1
PPUCOUNT_ATT	.ds 1

OFFSET_ATT		.ds 1

 .org $400
METASPR_MAX		= 8
METASPR_OAMADDR = $0280
METASPR_NUM		.ds 1 ;Number of active metasprites
METASPR_LEN		.ds 1 ;Temp var during metasprite update
METASPR_INDEX	.ds METASPR_MAX
METASPR_X		.ds METASPR_MAX
METASPR_Y		.ds METASPR_MAX


 .org $500
CTRLPORT_1		.ds 1
CTRLPORT_2		.ds 1

 
 .code
 
 .bank 0
 .org $8000
	.include "lib/rle.asm"

Ctrl_Read:
	LDA #1
	STA $4016
	LDA #0
	STA $4016
	
	LDX #8
.1
	LDA $4016
	ROR A
	ROL CTRLPORT_1
	DEX
	BNE .1

	LDX #8
.2
	LDA $4017
	ROR A
	ROL CTRLPORT_2
	DEX
	BNE .2
	
	RTS
	
DrawScanline: ;Good old CPU processing time indicator 
	LDA #%00011111  ;Switches gfx to monochrome mode
	STA $2001
	LDX #23 * 5; Second number = no. of lines
.1 ;Loop enough cycles to "draw" the scanlines
	DEX
	BNE .1
	
	LDA #%00011110 ;restore $2001 reg settings
	STA $2001
	RTS
	
waitPPU:
	BIT $2002
	BPL waitPPU
	RTS
	
RESET:
	JSR waitPPU
	SEI ;Set Interrupt Flag (off)
	CLD ;Clear Decimal Mode Flag
	
	LDX #%01000000
	STX $4017 ;APU Frame Counter OFF
	
	LDX #255
	TXS ;Reset stack pointer
	
	LDX #0
	STX $2000
	STX $2001 ;PPU set to Burst mode
	
	STX $4010 ;Disable DPCM IRQ interrupt
	
	JSR waitPPU
.clearMem
	LDA #0
	STA <$00, x
	STA $100, x
	STA $300, x
	STA $400, x
	STA $500, x
	STA $600, x
	STA $700, x
	LDA #254
	STA $200, x ;OAM local copy
	
	INX
	BNE .clearMem
	
	JSR waitPPU
.loadPalette:
	LDA $2002
	LDA #$3F
	STA $2006
	LDA #$00
	STA $2006
	
	LDX #00
.loadPaletteLoop:
	LDA Main_Palette, x
	STA $2007
	INX
	CPX #32
	BNE .loadPaletteLoop
	
	LDA #%00011110
	STA $2001 ;enable ppu rendering
	
	LDA #$88
	STA $2000
	
	LDA #0
	STA $2005
	STA $2005 ;set scroll to (0,0)
	
	LDA #(32*30)/24
	STA PPUCOUNT_NAM
	LDA #$20
	STA PPUADDR_NAM
	LDA #$00
	STA PPUADDR_NAM + 1
	
	LDA #(64/8)
	STA PPUCOUNT_ATT
	LDA #$23
	STA PPUADDR_ATT
	LDA #$C0
	STA PPUADDR_ATT + 1
	
	LDA #2
	STA METASPR_NUM
	LDA #1
	STA METASPR_INDEX
	LDA #120
	STA METASPR_X
	STA METASPR_Y
	
	LDA #4
	STA METASPR_INDEX + 1
	LDA #112
	STA METASPR_X + 1
	STA METASPR_Y + 1
MainLoop:
	JSR MetaSpr_Update
	;JSR DrawScanline
	JMP MainLoop
	

 .bank 1
 .org $A000
Umbrella_Up:
	.db 3 * 4
	.db 0, $10, $02, -12
	.db 0, $11, $02, -04
	.db 0, $12, $02, 04
Umbrella_Down:
	.db 3 * 4
	.db 0, $10, $82, -12
	.db 0, $11, $82, -04
	.db 0, $12, $82, 04
Chara_Up:
	.db 2 * 4
	.db 0, $13, $02, -8
	.db 0, $14, $02, 00
Chara_Up_Blink:
	.db 2 * 4
	.db 0, $13, $02, -8
	.db 0, $1a, $02, 00
Chara_Down:
	.db 2 * 4
	.db 0, $13, $02, -8
	.db 0, $15, $02, 00
Chara_Down_Blink:
	.db 2 * 4
	.db 0, $13, $02, -8
	.db 0, $19, $42, 00
Chara_Hit_1:
	.db 2 * 4
	.db 0, $16, $02, -8
	.db 0, $17, $02, 00
Chara_Hit_2:
	.db 2 * 4
	.db 0, $17, $42, -8
	.db 0, $16, $42, 00
	
	
Metasprite_Table:
	.dw Umbrella_Up
	.dw Umbrella_Down
	.dw Chara_Up
	.dw Chara_Up_Blink
	.dw Chara_Down
	.dw Chara_Down_Blink
	.dw Chara_Hit_1
	.dw Chara_Hit_2

MetaSpr_Update:
	LDA #LOW(METASPR_OAMADDR)
	STA OAM_ADDR
	LDA #HIGH(METASPR_OAMADDR)
	STA OAM_ADDR + 1
	
;X is current metasprite
;Y is an indexer to read a metasprite address and to read its contents
	LDX #0
.forEach: ;For each metasprite in METASPR_INDEX (0 to METASPR_NUM)
	CPX METASPR_NUM
	BEQ .forEachEnd
	LDA METASPR_INDEX, x
	ASL A
	TAY
	LDA Metasprite_Table, y
	STA METASPR_ADDR
	LDA Metasprite_Table + 1, y
	STA METASPR_ADDR + 1
	
	
;***** Reading metasprite data ****
	LDY #0
	LDA [METASPR_ADDR], y
	STA METASPR_LEN
	INC METASPR_ADDR
	BNE .innerLoop
	INC METASPR_ADDR + 1
.innerLoop
	;Y Position
	LDA [METASPR_ADDR], y
	CLC
	ADC METASPR_Y, x
	STA [OAM_ADDR], y	
	INY 
	;Tile ID
	LDA [METASPR_ADDR], y
	STA [OAM_ADDR], y
	INY
	;Attribute Byte
	LDA [METASPR_ADDR], y
	STA [OAM_ADDR], y
	INY
	;X Position
	LDA [METASPR_ADDR], y
	CLC
	ADC METASPR_X, x
	STA [OAM_ADDR], y
	INY
	
	CPY METASPR_LEN
	BNE .innerLoop
;*********************************
	LDA METASPR_LEN
	CLC
	ADC OAM_ADDR
	STA OAM_ADDR ;no overflow check
	
	INX
	JMP .forEach
.forEachEnd:
	;Todo: fill unused metasprite OAM with $FE
	RTS

 .bank 2
 .org $C000
 
 .bank 3
 .org $E000

Main_Palette:
	.incbin "art/bg.pal"
	.incbin "art/sprite.pal"
	
BG_Playfield:
	.incbin "art/playfield.rle"
BG_Playfield_Att:
	.incbin "art/playfield.atr"
	
NMI:
	PHA
	TXA
	PHA
	TYA
	PHA
	PHP;Save Processor Status

	LDA #0
	STA $2003
	LDA #2
	STA $4014
	
	LDA PPUCOUNT_NAM
	BEQ .exit
	DEC PPUCOUNT_NAM
	
	LDA #24
	STA RLE_MAX
	
	LDA $2002
	LDA PPUADDR_NAM
	STA $2006
	LDA PPUADDR_NAM + 1
	STA $2006
	LDX #LOW(BG_Playfield)
	LDY #HIGH(BG_Playfield)
	JSR unrle_partial_resume
	LDA PPUADDR_NAM + 1
	CLC
	ADC #24
	STA PPUADDR_NAM + 1
	BCC .exit
	INC PPUADDR_NAM
.exit
	LDA PPUCOUNT_ATT
	BEQ .exit2
	DEC PPUCOUNT_ATT
	
	LDA $2002
	LDA PPUADDR_ATT
	STA $2006
	LDA PPUADDR_ATT + 1
	STA $2006
	LDX OFFSET_ATT
	LDY #0
.loop1
	LDA BG_Playfield_Att, x
	STA $2007
	INX
	INY
	CPY #8
	BNE .loop1
	
	
	LDA OFFSET_ATT
	CLC
	ADC #8
	STA OFFSET_ATT
	
	LDA PPUADDR_ATT + 1
	CLC
	ADC #8
	STA PPUADDR_ATT + 1
	BCC .exit2
	INC PPUADDR_ATT
	
	
.exit2
	JSR Ctrl_Read
	LDA #0
	STA $2005
	STA $2005 ;set scroll to (0,0)
	
Letswastetiem:
	LDX #0
	LDY #2
.1
	DEX
	BNE .1
	DEY
	BNE .1
	
	JSR DrawScanline
	
	PLP
	PLA
	TAY
	PLA
	TAX
	PLA	;Restore Processor Status
	RTI
 
 .org $FFFA
	 .dw NMI
	 .dw RESET
	 .dw 0
 
;CHR
 .bank 4
 .org $0000
	.incbin "art/chardata.chr"
