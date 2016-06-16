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
 .org $100
STACK			.ds 256
 
 .org $200
OAM_COPY		.ds 256
 
 .org $300
CPU_NEXTFRAME	.ds 1
NEXTFRAME_YES 	= 0
NEXTFRAME_NO	= 1
 
PPUADDR_NAM		.ds 2
PPUADDR_ATT		.ds 2

PPUCOUNT_NAM	.ds 1
PPUCOUNT_ATT	.ds 1

OFFSET_ATT		.ds 1

 .org $400
METASPR_MAX		= 24
METASPR_OAMADDR = $0220
LIST_EMPTY	= $FF

METASPR_NUM		.ds 1 ;Number of active metasprites
METASPR_LEN		.ds 1 ;Temp var during metasprite update

METASPR_INDEX	.ds METASPR_MAX ;Linked list of sprite objects
METASPR_NEXT	.ds METASPR_MAX ;and pointer to next sprite.

METASPR_FREE	.ds 1 ;first free slot
METASPR_FIRST	.ds 1 ;first occupied slot
METASPR_LAST	.ds 1 ;last occupied slot
METASPR_X		.ds METASPR_MAX
METASPR_Y		.ds METASPR_MAX

 .org $500
CTRLPORT_1		.ds 1
CTRLPORT_2		.ds 1

TEMP			.ds 1

BALL_MAX		= 1
BALL_SPEEDX		.ds BALL_MAX
BALL_SPEEDY		.ds BALL_MAX 
BALL_METASPR	.ds BALL_MAX

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
	
	
	LDX #0
.initMetasprite:
	LDA #$FF
	STA METASPR_INDEX, x
	INX
	CPX #METASPR_MAX
	BNE .initMetasprite
	
	LDX #0
.initMetasprPointers:
	TXA
	CLC
	ADC #1
	STA METASPR_NEXT, x
	INX
	CPX #METASPR_MAX
	BNE .initMetasprPointers
	
	LDA #$FF
	STA METASPR_NEXT + (METASPR_MAX - 1)
	
	LDA #0
	STA METASPR_FREE
	LDA #$FF
	STA METASPR_FIRST
	STA METASPR_LAST
	
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
	
	LDX #1
	JSR Metasprite_Add
	LDX #1
	JSR Metasprite_Add
	LDX #1
	JSR Metasprite_Add
	LDX #1
	JSR Metasprite_Add
	LDX #1
	JSR Metasprite_Add
	LDX #1
	JSR Metasprite_Add
	LDX #1
	JSR Metasprite_Add
	LDX #0
	JSR Metasprite_Remove
	LDX #1
	JSR Metasprite_Remove
	LDX #2
	JSR Metasprite_Remove
	LDX #1
	JSR Metasprite_Add
	LDX #1
	JSR Metasprite_Add
	LDX #1
	JSR Metasprite_Add
	LDX #1
	JSR Metasprite_Add
	LDX #0
	JSR Metasprite_Remove
	
	;LDA #5
	;STA METASPR_NUM
	
	LDA #2
	STA METASPR_INDEX
	LDA #128
	STA METASPR_X
	LDA #39
	STA METASPR_Y
	
	LDA #5
	STA METASPR_INDEX + 1
	LDA #120
	STA METASPR_X + 1
	LDA #31
	STA METASPR_Y + 1
	
	LDA #1
	STA METASPR_INDEX + 2
	LDA #128
	STA METASPR_X + 2
	LDA #191
	STA METASPR_Y + 2
	
	LDA #3
	STA METASPR_INDEX + 3
	LDA #120
	STA METASPR_X + 3
	LDA #199
	STA METASPR_Y + 3
	
	LDA #0
	STA METASPR_INDEX + 4
	LDA #128
	STA METASPR_X + 4
	STA METASPR_Y + 4
	
	LDA #4
	STA BALL_METASPR
	LDA #1
	STA BALL_SPEEDX
	STA BALL_SPEEDY
	
	
MainLoop:
	LDA #NEXTFRAME_NO
	STA CPU_NEXTFRAME
	INC $666
	LDA $666
	AND #%01111111
	BNE .c
	LDX CTRLPORT_1
	CPX #$80
	BEQ .d
	CPX #$40
	BNE .c
	JSR Metasprite_Add
	LDA #0
	STA $667
	JMP .c
.d
	LDX $667
	JSR Metasprite_Remove
	INC $667
.c
	JSR Ctrl_Read
	;JSR Ball_Update
	JSR MetaSpr_Update
	JSR DrawScanline
	
.waitPPU
	LDA CPU_NEXTFRAME
	CMP #NEXTFRAME_YES
	BNE .waitPPU
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
	.db 0, $10, $83, -12
	.db 0, $11, $83, -04
	.db 0, $12, $83, 04
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
	.db 0, $13, $03, -8
	.db 0, $15, $03, 00
Chara_Down_Blink:
	.db 2 * 4
	.db 0, $13, $03, -8
	.db 0, $19, $43, 00
Chara_Hit_1:
	.db 2 * 4
	.db 0, $16, $02, -8
	.db 0, $17, $02, 00
Chara_Hit_2:
	.db 2 * 4
	.db 0, $17, $42, -8
	.db 0, $16, $42, 00
Projectile_Default:
	.db 1 * 4
	.db -4, $06, $02, -4
	
	
Metasprite_Table:
	.dw Projectile_Default
	.dw Umbrella_Up
	.dw Umbrella_Down
	.dw Chara_Up
	.dw Chara_Up_Blink
	.dw Chara_Down
	.dw Chara_Down_Blink
	.dw Chara_Hit_1
	.dw Chara_Hit_2
	
	;Input: X = metasprite ID.
	;Output: X = index of insertion in metasprite list.
Metasprite_Add:
	LDY METASPR_FREE ;Loads ID of first free slot
	CPY #$FF
	BEQ .fail ;if 255 then list is full
	
	TXA
	STA METASPR_INDEX, y ;Store metasprite ID in list
	
	;TODO: if full, METASPR_FREE = 255
	LDA METASPR_NEXT, y ;Loads pointer to next empty slot
	STA METASPR_FREE
	
	LDX METASPR_FIRST
	CPX #$FF		
	BEQ .firstInsertion
	
.notFirstInsertion:
	LDA METASPR_LAST
	TAX ;Saves pointer to last object in reg. X
	STY METASPR_LAST ;New object is tail
	TYA
	STA METASPR_NEXT, x ;Old tail now points to new tail
	LDA #$FF
	STA METASPR_NEXT, y ;and new points to nothing.
	JMP .success
	
.firstInsertion
	STY METASPR_FIRST ;If it is first insertion, object is head
	STY METASPR_LAST  ;New object is also the list's tail
	LDA #$FF
	STA METASPR_NEXT, y ;and points to nothing.
	
.success:
	TYA
	TAX
	RTS
	
.fail
	LDX #$FF
	RTS
	
	;This is a mess but it's guaranteed to work
	;I know where this needs cleaning, I'm just too lazy.
	;X - index
Metasprite_Remove:
	LDY METASPR_FIRST
	CPY #$FF
	BEQ .failure ;If list is empty then quit.
	
	STX TEMP
	
	LDA METASPR_FIRST
	CMP TEMP
	BEQ .isFirst ;Is the object to be removed first?
	
.findPrevious:
	TAY
	LDA METASPR_NEXT, y
	;TAY
	CMP #$FF
	BEQ .failure ;if next equals $FF then we reached end of list, failure
	CMP TEMP
	BNE .findPrevious

	;y is the object previous to the object to be deleted in the list
.found
	LDA METASPR_NEXT, x ;Gets next from object to be removed
	STA METASPR_NEXT, y ;previous->next = object->next
	CMP #$FF
	BNE .delete
	LDA METASPR_NEXT, y
	STA METASPR_LAST ;If previous->next = NULL then last = NULL
	JMP .delete
	
.isFirst:
	LDA METASPR_NEXT, y
	STA METASPR_FIRST	;First now points to object next to removed one
	CMP #$FF
	BNE .delete
	STA METASPR_LAST	;If first equals null then list is empty, so last = null

.delete:
	LDA METASPR_FREE
	STA METASPR_NEXT, x ;Deleted object points to first free slot
	STX METASPR_FREE	;Deleted object now first free object slot
	LDA #$FF
	STA METASPR_INDEX, x
	
	RTS ;SUCCESS!!!]
	
.failure:
	RTS
	
	
	
;	if List is empty quit
;	load First
;	if first equals target
;	{
;		first equals target->next
;		if first equals null then Last equals null
;		Free equals target / target->next equals Free
;		end
;	}
;	if first not equal target
;	{
;		while obj->next not null
;		{
;			if obj->next equals target then leave
;			if obj->next equals null then end
;		}
;		obj->next equals target->next
;		if obj->next equals null then Last equals obj
;		Free equals target / target->next equals Free
;		end
;	}
	
MetaSpr_Update:
	LDA #LOW(METASPR_OAMADDR)
	STA OAM_ADDR
	LDA #HIGH(METASPR_OAMADDR)
	STA OAM_ADDR + 1
	
;X is current metasprite
;Y is an indexer to read a metasprite address and to read its contents
	LDX METASPR_FIRST
	;LDX #0
.forEach: ;For each metasprite in METASPR_INDEX (0 to METASPR_NUM)
	CPX #$FF
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
	
	LDA METASPR_NEXT, x
	TAX
	JMP .forEach
.forEachEnd:
	;Todo: fill unused metasprite OAM with $FE
	RTS

 .bank 2
 .org $C000
 ;ldx ball_index
Ball_Update:
	LDA BALL_METASPR, x
	TAY
	LDA BALL_SPEEDX, x
	CLC
	ADC METASPR_X, y
	STA METASPR_X, y
	
	LDA BALL_SPEEDY, x
	CLC
	ADC METASPR_Y, y
	STA METASPR_Y, y
	
	RTS
 
 
 
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
	LDA #0
	STA $2005
	STA $2005 ;set scroll to (0,0)
	
	LDA #NEXTFRAME_YES
	STA CPU_NEXTFRAME
	
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
