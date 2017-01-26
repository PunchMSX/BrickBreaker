;********************************************************
;*** B    R    I    X      B    A    T    T    L    E ***
;********************************************************
;- C o p y r i g h t   2 0 1 6   A l e f f   C o r r e a -
;Project start: 05/06/2016   ||     Version ZERO

	.inesmap 0 ;no mapper
	.inesmir 0 ;Vertical
	.ineschr 1 ;8kb Character ROM
	.inesprg 2 ;32kb Program ROM
	
TRUE = 1
FALSE = 0

 .ZP
RESERVED_RLE	.ds  8

FAMITONE_RESERVED .ds 3

RNG_SEED		.ds 1

TEMP_PTR		.ds 12 ;Three pointers to be used at will by any subroutine
TEMP_BYTE		.ds 12


;Finite state machine interpreter (state.asm)
INTERPRETER_PC	.ds 2 ;Pointer to current instruction 
INTERPRETER_OPC	.ds 1 ;Last opcode loaded
INTERPRETER_STEP .ds 1 ;Toggle to run INTERPRETER_OPC or opcode pointed by the program counter

INTERPRETER_PPU	.ds 2 ;Pointer to PPU RAM
INTERPRETER_CPU	.ds 2 ;Pointer to CPU RAM

INT_SP1	.ds 1 ;Offset to top (next empty slot) of interpreter stack (32 bytes)

INTERPRETER_STACK = $0100
INTERPRETER_STACK_MAX = 16

INT_R1		.ds 1 ;Register #1 always gets set to 0 on each interpreter step
INT_R2		.ds 1
INT_R3		.ds 1
INT_R4		.ds 1
INT_16R1 	.ds 2 ;16 bit register


;PPU Software command/address stack (ppu.asm)
PPU_QP1F .ds 1 ;Offset to front of PPU command queue (16 bytes)
PPU_QP1B .ds 1 ;          back

PPU_QR1	.ds 1
PPU_QR2	.ds 1
PPU_QR3	.ds 1
PPU_QR4	.ds 1
PPU_QR5 .ds 1
PPU_QR6 .ds 1

PPU_QUEUE1 = INTERPRETER_STACK + INTERPRETER_STACK_MAX
PPU_QUEUE1_MAX = 80

CALL_ARGS .ds 6 ;Common RAM Space for CPU subroutines that require arguments.

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
OLDCTRL_1  .ds 1
OLDCTRL_2  .ds 1
CTRL_A =		%10000000
CTRL_B =		%01000000
CTRL_SELECT = 	%00100000
CTRL_START = 	%00010000
CTRL_UP	= 		%00001000
CTRL_DOWN = 	%00000100
CTRL_LEFT = 	%00000010
CTRL_RIGHT = 	%00000001

;NMI Background Drawing
PPUCOUNT_NAM .ds 1 ;Number of sections to be drawn
PPUCOUNT_ATR .ds 1 

PPUADDR_NAM .ds 2 ;Address in PPU memory for the Background/Attributes
PPUADDR_ATR .ds 2

CPUADDR_NAM .ds 2 ;Address in PPU memory for the Background/Attributes
CPUADDR_ATR .ds 2

PPU_DRAW 	.ds 1

PPU_COMMAND	.ds 1 ;Current command undergoing execution by the NMI thread.

PPU_LENGTH	.ds 2 ;No. of bytes to be written (not used by RLE)
PPU_BYTE	.ds 1 ;Byte to be copied over (repeated byte draw mode)

PPU_NUMWRITES .ds 1 ;# of bytes written to PPU in a given frame

PPU_STEP	.ds 1 ;Retrieve next drawing command? True/False
STEP_NOW = 2 ;Value used to read next command while in the same frame.

PPU_Q1EMPTY .ds 1 ;Used to distinguish a full from an empty queue
PPU_Q2EMPTY .ds 1 ;(both will have front = back)

PPU_Q1CAP	.ds 1 ;# of bytes free (call PPU_Queue_Capacity to update value.)
PPU_Q2CAP	.ds 1

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
OBJ_INTSTATE4	.ds OBJ_MAX
OBJ_INTSTATE5	.ds OBJ_MAX
OBJ_INTSTATE6	.ds OBJ_MAX
OBJ_INTSTATE7	.ds OBJ_MAX
OBJ_INTSTATE8	.ds OBJ_MAX

 .org $500
GAME_STATE		.ds 1
GAME_OLDSTATE 	.ds 1
GAME_TRANSITION	.ds 1

MATCH_LEVEL		.ds 1 ;Current match # (level id), 0 for first run.
MATCH_TIMER		.ds 1 ;Base 100 number representing the time left.
MATCH_FRAMES	.ds 1 ;frame timer, increase main timer when full.
MATCH_P1SCORE	.ds 1
MATCH_P2SCORE	.ds 1 ;The score (base 100) of each player on the field.
MATCH_TIMER_DEFAULT = 99

MATCH_P1BALLS	.ds 1 ;Number of balls player/enemy has to be launched.
MATCH_P2BALLS	.ds 1
MATCH_BALL_MAX = 3

MATCH_P1SCOREBUF .ds 1
MATCH_P2SCOREBUF .ds 1 ;A buffer which balls increment when they hit the goal.

MATCH_START		.ds 1 ;true/false - used to sync with state machine driven PPU writes before the match starts.

MATCH_P1SCORE_PPU = $204A
MATCH_P2SCORE_PPU = $2054
MATCH_TIMER_PPU   = $204F


INTRO_BULLETQ 	.ds 1
INTRO_CHARQ		.ds 1
INTRO_TIMER		.ds 1
INTRO_SPAWN_TMR .ds 2 ;Will only spawn objects in intro at frame intervals.
INTRO_SHOWSCORE	.ds 1

INSTRUCT_PLAYER .ds 1
INSTRUCT_ARROWS .ds 1 ;IDs for placeholder characters for the instruction screen(s?)
INSTRUCT_BALL	.ds 1

INSTRUCT_SYNC	.ds 1
INSTRUCT_AIM1 = 1
INSTRUCT_AIM2 = 2
INSTRUCT_AIM3 = 3
INSTRUCT_FIRE = 4
INSTRUCT_KILLBALL = 5
INSTRUCT_ITEMS = 6
INSTRUCT_END = 7

GAME_HISCORES	.ds 2 * 5 ;2 base-100 bytes per score
GAME_INITIALS	.ds 3 * 5 ;Three letters per score


DEBUG_CURSORID	.ds 1
DEBUG_CURSORX	.ds 1
DEBUG_CURSORY	.ds 1
DEBUG_OLDCURX	.ds 1
DEBUG_OLDCURY	.ds 1
DEBUG_DECIMALX	.ds 3
DEBUG_DECIMALY	.ds 3

  .org $600
COLLISION_MAP	 .ds 16 * 15 ;Full screen collision map
COLLISION_OFFSET .ds 4  ;
COLLISION_OVERLAP .ds 4 ; # pixels overlapping with a bg tile for X and Y axis
COLMAP_WIDTH = 16
COLMAP_HEIGHT = 15
COLMAP_SIZE = 16 * 15
COLMAP_EDITABLE_X1 = 1
COLMAP_EDITABLE_X2 = 15
COLMAP_EDITABLE_Y1 = 2
COLMAP_EDITABLE_Y2 = 13


 .code
 .bank 0
 .org $8000
	.include "macros.asm"
	.include "lib/rle.asm"
	
	.include "gamestate.asm"
	
	.include "obj.asm"
	.include "anim.asm"
	.include "anim.txt"
	
	.include "collision.asm"
	.include "collision.txt"
	
	.include "titlescr.asm"
	.include "debug.asm"
	.include "instructions.asm"
	
	.include "state.asm"
	
	.include "ppu.asm"
	.include "metatile.asm"

 .bank 1
 .org $A000
 
	.include "lib/famitone2.asm"
	.include "audio/sketchy/Boss.asm"
	
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
	LDA CTRLPORT_1
	STA OLDCTRL_1
	LDA CTRLPORT_2
	STA OLDCTRL_2
	
	LDY #$FF
.0
	INY
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
	
	;DPCM Playback corruption check
	TYA
	AND #%00000001
	BNE .compare

	LDA CTRLPORT_1
	STA <TEMP_BYTE
	LDA CTRLPORT_2
	STA <TEMP_BYTE + 1
	JMP .0
.compare
	LDA CTRLPORT_1
	CMP <TEMP_BYTE
	BNE .glitch
	LDA CTRLPORT_2
	CMP <TEMP_BYTE + 1
	BNE .glitch
	RTS
	
.glitch
	CPY #7
	BCS .readfail
	JMP .0
	
.readfail:
	LDA OLDCTRL_1
	STA CTRLPORT_1
	LDA OLDCTRL_2
	STA CTRLPORT_2
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
	
;Output: TEMP_BYTE (3) = decimal digits
;Input: A (number to be converted)
ConvertToDecimal:
	LDX #0
	STX <TEMP_BYTE
	STX <TEMP_BYTE + 1
	STX <TEMP_BYTE + 2
	
.get100
	CMP #100
	BCC .get10
	SBC #100
	INC <TEMP_BYTE
	JMP .get100
.get10
	CMP #10
	BCC .get1
	SBC #10
	INC <TEMP_BYTE + 1
	JMP .get10
.get1
	STA <TEMP_BYTE + 2
	RTS
	
;Output: TEMP_BYTE (2) = decimal digits
;Input: A (number to be converted from 0-99)
Base100ToDecimal:
	LDX #0
	STX <TEMP_BYTE
	STX <TEMP_BYTE + 1

	CMP #100
	BCC .get10
;Error, non base 100 number given as parameter
	LDA #$FF
	STA <TEMP_BYTE
	STA <TEMP_BYTE + 1
	RTS

.get10
	CMP #10
	BCC .get1
	SBC #10
	INC <TEMP_BYTE
	JMP .get10
.get1
	STA <TEMP_BYTE + 1
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
	
	LDA #10
	STA GAME_STATE
	LDA #255
	STA GAME_OLDSTATE
	
	JSR ObjectList_Init	;Run this only once
	JSR PPU_InitQueues
	JSR HiScores_Init
	
	LDA #TRUE
	STA GAME_TRANSITION
	
	LDA #1
	LDX #LOW(Boss_music_data)
	LDY #HIGH(Boss_music_data)
	JSR FamiToneInit
	LDA #0
	JSR FamiToneMusicPlay
	
;*********************************************
	
Mainloop:
	LDA #NEXTFRAME_NO
	STA CPU_NEXTFRAME
	
		JSR Ctrl_Read
		
		JSR GameStateManager
		
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
	
;**********************************************
	
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
	
	JSR PPU_QueueInterpreter
	
.cleanup:
	LDA #%00011110
	STA $2001 ;enable ppu rendering
	
	LDA #$88
	STA $2000
	
	LDA #0
	STA $2005
	STA $2005 ;set scroll to (0,0)
	
	LDA #NEXTFRAME_YES
	STA PPU_NEXTFRAME
	
	JSR FamiToneUpdate
	
	PLP
	PLA
	TAY
	PLA
	TAX
	PLA	;Restore Processor Status
	RTI
	
 .data
 .bank 2
 .org $C000
 ;DPCM samples goes here, aligned by 64 bytes.
 
 .incbin "audio/sketchy/Boss.dmc" 
	
 .code
 .bank 3
 .org $E000
	
Main_Palette:
	.incbin "art/bg.pal"
	.incbin "art/sprite.pal"
	
Text_ProgBy:
	.db 1
	.db "PROGRAMMED BY ALEFF CORREA"
	.db 1, 0
	
Text_PushRun:
	.db 1
	.db "PRESS START BUTTON"
	.db 1, 0
	
bg_Title_Screen:
	.incbin "art/title.rle"
bg_Playfield:
	.incbin "art/playfield.rle"
bg_HighScore:
	.incbin "art/hiscore.rle"
	
 .org $FFFA
	 .dw NMI
	 .dw RESET
	 .dw 0
 
;CHR
 .bank 4
 .org $0000
	.incbin "art/chardata.chr"
