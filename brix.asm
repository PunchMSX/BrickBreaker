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

RNG_SEED		.ds 1

TEMP_PTR		.ds 12 ;Three pointers to be used at will by any subroutine
TEMP_BYTE		.ds 12

 .BSS
 .org $200
OAM_COPY	.ds 256
OAM_SPROFFSET = 4 * 4
 
 .org $300
CPU_NEXTFRAME	.ds 1
PPU_NEXTFRAME	.ds 1
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
	;List of objects. Value = object type (each type has own update subroutine)
OBJ_XPOS		.ds OBJ_MAX
OBJ_YPOS		.ds OBJ_MAX
	;Position of center of object on screen
OBJ_ANIMATION	.ds OBJ_MAX
	;Animation ID #
OBJ_ANIMTIMER	.ds OBJ_MAX
	;Frame timer (0-255). Timer limit is defined by animation table.
OBJ_ANIMFRAME	.ds OBJ_MAX
	;Current animation frame. Don't manually write values other than 0.
OBJ_METASPRITE	.ds OBJ_MAX
	;Object's metasprite index #. 255 = no draw
OBJ_COLLISION	.ds OBJ_MAX
	;Collided with who? 255 = no collision
OBJ_INTSTATE1	.ds OBJ_MAX
OBJ_INTSTATE2	.ds OBJ_MAX
OBJ_INTSTATE3	.ds OBJ_MAX

 .org $500
STATE_PAUSE	= 0
STATE_TITLE = 1
STATE_HISCORE = 2
STATE_GAME = 3
STATE_PUZZLEGAME = 4
STATE_GAMEOVER = 5
STATE_ENDING_WIN = 6
STATE_ENDING_LOSE = 7
STATE_FALSEENDING = 8
STATE_CREDITS = 9

GAME_STATE		.ds 1
GAME_SUBSTATE 	.ds 1

INTRO_BULLETQ 	.ds 1
INTRO_CHARQ		.ds 1
INTRO_TIMER		.ds 1
INTRO_SPAWN_TMR .ds 2 ;Will only spawn objects in intro in frame intervals.


 .code
 .bank 0
 .org $8000
	.include "macros.asm"
	.include "lib/rle.asm"
	
	.include "obj.asm"
	.include "anim.asm"
	.include "anim.txt"
	
	.include "collision.asm"
	.include "collision.txt"
	
	.include "titlescr.asm"

 .bank 1
 .org $A000
	
RNG_Next:
	LDA <RNG_SEED
	BEQ .zero
	ASL A
	BEQ .end ;$80
	BCC .end
.zero
	EOR #$5F
.end
	STA <RNG_SEED
	RTS
	
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
	
	JSR ObjectList_Init	;Run this only once
	
	JSR TitleInit
	
;*********************************************
	
Mainloop:
	LDA #NEXTFRAME_NO
	STA CPU_NEXTFRAME
	
		JSR Ctrl_Read
		
		JSR TitleLoop
		
		JSR ObjectList_UpdateAll
		JSR ObjectList_OAMUpload
		JSR DrawScanline
	
	LDA #NEXTFRAME_YES
	STA CPU_NEXTFRAME
.waitPPU
	LDA PPU_NEXTFRAME
	CMP #NEXTFRAME_NO
	BEQ .waitPPU
	LDA #NEXTFRAME_NO
	STA PPU_NEXTFRAME
	JMP Mainloop
	
NMI:
	PHA
	TXA
	PHA
	TYA
	PHA
	PHP;Save Processor Status
	
	LDA CPU_NEXTFRAME
	CMP #NEXTFRAME_NO
	BEQ .cleanup
	
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
	STA PPU_NEXTFRAME
	
	PLP
	PLA
	TAY
	PLA
	TAX
	PLA	;Restore Processor Status
	RTI
	
 .bank 3
 .org $E000

Main_Palette:
	.incbin "art/bg.pal"
	.incbin "art/sprite.pal"
	
Text_1:
	.db 1
	.db " PROGRAMMED BY ALEFF CORREA"
	.db 1, 0
bg_Title_Screen:
	.incbin "art/title.rle"
	
 .org $FFFA
	 .dw NMI
	 .dw RESET
	 .dw 0
 
;CHR
 .bank 4
 .org $0000
	.incbin "art/chardata.chr"