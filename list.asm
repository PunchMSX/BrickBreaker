;**List.asm***
;Testing bed for object manager

	.inesmap 0 ;no mapper
	.inesmir 0 ;Vertical
	.ineschr 1 ;8kb Character ROM
	.inesprg 2 ;32kb Program ROM
	
 .ZP
RESERVED_RLE	.ds  16

TEMP_PTR		.ds 6 ;Three pointers to be used at will by any subroutine
TEMP_BYTE		.ds 6

 .BSS
 .org $200
OAM_COPY	.ds 256
OAM_SPROFFSET = 4 * 4
 
 .org $300
CPU_NEXTFRAME	.ds 1
NEXTFRAME_YES 	= 0
NEXTFRAME_NO	= 1

CTRLPORT_1 .ds 1
CTRLPORT_2 .ds 1

;NMI Background Drawing
PPUCOUNT_NAM .ds 1 ;Number of sections to be drawn
PPUCOUNT_ATR .ds 1 

PPUADDR_NAM .ds 2 ;Address in PPU memory for the Background/Attributes
PPUADDR_ATR .ds 2

CPUADDR_NAM .ds 2 ;Address in PPU memory for the Background/Attributes
CPUADDR_ATR .ds 2

PPU_DRAW .ds 1

 .org $400
OBJ_MAX = 16

OBJ_LIST		.ds OBJ_MAX
OBJ_XPOS		.ds OBJ_MAX
OBJ_YPOS		.ds OBJ_MAX
OBJ_ANIMTIMER	.ds OBJ_MAX
OBJ_METASPRITE	.ds OBJ_MAX
OBJ_INTSTATE1	.ds OBJ_MAX
OBJ_INTSTATE2	.ds OBJ_MAX
OBJ_INTSTATE3	.ds OBJ_MAX


 .code
 .bank 0
 .org $8000


 .bank 1
 .org $A000
	.include "macros.asm"
	.include "lib/rle.asm"
	.include "obj.asm"
	
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
	LDX #23 * 1; Second number = no. of lines
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
	
;**** Temporary test instructions ****
	LDA #LOW(Text_1)
	STA CPUADDR_NAM
	LDA #HIGH(Text_1)
	STA CPUADDR_NAM + 1
	LDA #$20
	STA PPUADDR_NAM
	LDA #$A2
	STA PPUADDR_NAM + 1
	
	LDA #1
	STA PPU_DRAW ;Schedule "Text1" to be drawn next NMI
	
	JSR ObjectList_Init	;Run this only once
	
	LDX #100
	LDY #200
	LDA #0
	JSR ObjectList_Insert ;Main Character
	
	LDX #130
	LDY #180
	LDA #0
	JSR ObjectList_Insert ;Main Character
	
	LDX #160
	LDY #190
	LDA #0
	JSR ObjectList_Insert ;Main Character
	
	LDX #128
	LDY #128
	LDA #1
	JSR ObjectList_Insert ;Ball
	
	LDX #100
	LDY #164
	LDA #1
	JSR ObjectList_Insert ;Ball
	
	LDX #164
	LDY #100
	LDA #1
	JSR ObjectList_Insert ;Ball
	
	LDX #50
	LDY #50
	LDA #1
	JSR ObjectList_Insert ;Ball
	
	LDX #28
	LDY #128
	LDA #1
	JSR ObjectList_Insert ;Ball
	
	LDX #00
	LDY #164
	LDA #1
	JSR ObjectList_Insert ;Ball
	
	LDX #64
	LDY #100
	LDA #1
	JSR ObjectList_Insert ;Ball
	
	LDX #150
	LDY #50
	LDA #1
	JSR ObjectList_Insert ;Ball
	
	LDX #140
	LDY #128
	LDA #1
	JSR ObjectList_Insert ;Ball
	
	LDX #160
	LDY #164
	LDA #1
	JSR ObjectList_Insert ;Ball
	
	LDX #180
	LDY #100
	LDA #1
	JSR ObjectList_Insert ;Ball
	
	LDX #0
	LDY #0
	LDA #1
	JSR ObjectList_Insert ;Ball
	
	LDX #23
	LDY #55
	LDA #0
	JSR ObjectList_Insert ;Ball
	
	LDX #16
	LDY #16
	LDA #1
	JSR ObjectList_Insert ;Ball
	
	
;*********************************************
	
Mainloop:
	LDA #NEXTFRAME_NO
	STA CPU_NEXTFRAME
	JSR Ctrl_Read
	JSR ObjectList_UpdateAll
	JSR ObjectList_OAMUpload
	JSR DrawScanline
.waitPPU
	LDA CPU_NEXTFRAME
	CMP #NEXTFRAME_NO
	BEQ .waitPPU
	JMP Mainloop
	
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
	STA $4014 ;Copy OAM Table
	
	LDA PPU_DRAW
	BEQ .cleanup
	
	LDA #24
	STA RLE_MAX
	
	LDA $2002
	LDA PPUADDR_NAM
	STA $2006
	LDA PPUADDR_NAM + 1
	STA $2006
	
	LDX CPUADDR_NAM      ;lo
	LDY CPUADDR_NAM + 1  ;hi
	JSR unrle_partial_resume
	
	LDA RLE_STAT
	CMP #RLE_READY
	BNE .updatePPUaddress
	LDA #0
	STA PPU_DRAW ;Drawing finished.
	
.updatePPUaddress
	LDA PPUADDR_NAM + 1
	CLC
	ADC #24
	STA PPUADDR_NAM + 1
	BCC .cleanup
	INC PPUADDR_NAM
	
.cleanup:
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
	
 .bank 3
 .org $E000
	.include "anim.txt"
 
;Sets all object entries as $FF, run this once
ObjectList_Init:
	LDA #$FF
	LDX #OBJ_MAX
.loop:
	DEX
	STA OBJ_LIST, x
	STA OBJ_XPOS, x
	STA OBJ_YPOS, x
	STA OBJ_ANIMTIMER, x
	STA OBJ_METASPRITE, x
	BNE .loop
 
	RTS
	
; A = object ID
; X, Y = Position coords
ObjectList_Insert:
	PHA	;Save object ID for later
	TXA
	PHA	;Save X coord for later
	
	LDX #0
.findSlot
	LDA OBJ_LIST, x
	CMP #$FF
	BEQ .found
	INX
	CPX #OBJ_MAX
	BNE .findSlot
	JMP .notFound ;No free slot for insertion, exit
	
.found
	TYA
	STA OBJ_YPOS, x ;Store Y coord to free register
	PLA
	STA OBJ_XPOS, x ;X coord
	PLA
	STA OBJ_LIST, x ;Object ID
	LDA #0
	STA OBJ_ANIMTIMER, x ;Clears animation timer
	STA OBJ_METASPRITE, x
	TXA
	RTS ;End!
	
.notFound
	PLA
	PLA
	LDX #$FF
	RTS
	
ObjectList_UpdateAll:
LogicPtr = TEMP_PTR
	LDX #0
.loop
	LDA OBJ_LIST, x
	CMP #$FF
	BNE .found
	INX
	CPX #OBJ_MAX
	BNE .loop
	JMP .out
.found
	PHX ;Preserves X (just in case)
	JSR .ObjectList_JSR ;Reminder, AI routines NEED slot # at X.
	PLX
	INX
	CPX #OBJ_MAX
	BNE .loop
	JMP .out
.out
	RTS
	
.ObjectList_JSR:
	LDA OBJ_LIST, x
	ASL A
	TAY
	LDA ObjectLogic_Table + 1, y ;High byte popped last, pushed first.
	PHA
	LDA ObjectLogic_Table, y
	PHA ;Pushes Subroutine address into stack
	RTS ;Jumps to target subroutine, returns to "JSR" callee
	
;Updates OAM Copy with the metasprites. 
;No metasprite can have 0 bytes! (Use metasprite id # 255 to skip object)
ObjectList_OAMUpload:
Metasprite_Ptr = TEMP_PTR
OAM_Offset = TEMP_BYTE
OAM_Limit = TEMP_BYTE + 1
Metasprite_X = TEMP_BYTE + 2
Metasprite_Y = TEMP_BYTE + 3

	LDA #OAM_SPROFFSET
	STA OAM_Offset ;Pointer to where OAM writes start

	LDX #$FF
.forEachObject
	INX
	CPX #OBJ_MAX
	BEQ .forend
	LDA OBJ_LIST, x
	CMP #$FF
	BNE .found
	JMP .forEachObject
.forend

	LDX OAM_Offset
	BEQ .end ;No unused sprites in OAM
	LDA #$FE
.updateUnused
	STA OAM_COPY, x
	INX
	BNE .updateUnused
.end
	RTS
	
.found
	PHX ;Preserves slot # just in case
	LDA OBJ_METASPRITE, x
	CMP #$FF
	BEQ .foundEnd
	ASL A ;2-byte table index
	TAY
	BCS .second ;Slot 128 to 255 = index Y overflows
	
.first ;Entry 0 to 127 chosen
	;Load pointer to object's metasprite
	LDA Metasprite_Table, y
	STA Metasprite_Ptr
	LDA Metasprite_Table + 1, y
	STA Metasprite_Ptr + 1
	JMP .copyData
.second ;Entry 128 to 255 chosen; add $100 to compensate overflow
	LDA Metasprite_Table + $100, y
	STA Metasprite_Ptr
	LDA Metasprite_Table + $100 + 1, y
	STA Metasprite_Ptr + 1
	JMP .copyData
	
.copyData:
	LDY #0
	LDA OAM_Offset
	CLC
	ADC [Metasprite_Ptr], y ;Retrieves number of bytes used by Metasprite
	BCC .hasSpace ;No overflow, has enough space in OAM to copy sprites
	BEQ .hasSpace ;Overflows but last byte is $00 - 1 = $FF, so copying is OK.
	JMP .TooManySprites ;Not enough space, OAM overflow. Stop subroutine early
	
.hasSpace:
	STA OAM_Limit ;Will copy data until OAM_Offset == OAM_Limit
	
	;Hold the metasprite's X,Y coords in a temp variable to free reg. X
	;(making reads to OBJ_XYPOS uneeded we can discard the slot # -- preserved on stack)
	LDA OBJ_XPOS, x
	STA Metasprite_X
	LDA OBJ_YPOS, x
	STA Metasprite_Y
	
	LDX OAM_Offset
	INY
.copyDataLoop:
	;Y Position
	LDA [Metasprite_Ptr], y
	CLC
	ADC Metasprite_Y
	STA OAM_COPY, x
	INY
	INX
	;Sprite ID
	LDA [Metasprite_Ptr], y
	STA OAM_COPY, x
	INY
	INX
	;Attribute Byte
	LDA [Metasprite_Ptr], y
	STA OAM_COPY, x
	INY
	INX
	;X Position
	LDA [Metasprite_Ptr], y
	CLC
	ADC Metasprite_X
	STA OAM_COPY, x
	INY
	INX
	
	CPX OAM_Limit
	BNE .copyDataLoop
	
.foundEnd
	LDA OAM_Limit
	STA OAM_Offset ;Updates offset to avoid overwriting.
	PLX ;Guarantees slot # in X is unchanged, continue loop.
	JMP .forEachObject
	
;Error: not enough space in OAM for all metasprites.
.TooManySprites
	PLX ;Don't forget to pop X from stack to avoid problems in the RTS.
	RTS ;Stops loop since there's no room for the remaining objects.
	
Main_Palette:
	.incbin "art/bg.pal"
	.incbin "art/sprite.pal"
	
Text_1:
	.db 1
	.db "OBJECT MANAGER TEST PROGRAM"
	.db 1, 0
Text_2:
	.db 1
	.db "  A TO INSERT  B TO REMOVE"
	.db 1, 0	
Text_3:
	.db 1
	.db "   START"
	.db $14
	.db "SELECT TO CHANGE"
	.db 1, 0	
	
 .org $FFFA
	 .dw NMI
	 .dw RESET
	 .dw 0
 
;CHR
 .bank 4
 .org $0000
	.incbin "art/chardata.chr"