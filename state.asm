;State.asm
;Defines a state machine interpreter
;used mostly for non-interactive parts of the game and
;PPU draw scheduling

State_Table:
	.dw _OPC_Halt - 1
	.dw _OPC_Error - 1
	.dw _OPC_Delay - 1
	.dw _OPC_DrawRLE - 1
	.dw _OPC_DrawSquare - 1
	.dw _OPC_DrawNumber100 - 1
	.dw _OPC_DrawString - 1
	.dw _OPC_DrawMetatileRow - 1
	.dw _OPC_RAMWrite - 1
	.dw _OPC_InsertMetasprite - 1
	.dw _OPC_ScreenOff - 1
	.dw _OPC_ScreenOn - 1
	.dw _OPC_DrawRLEBurst - 1
	
;1-byte ops that represent a function call 
;(I don't remember what OPC stands for :P)
OPC_Halt = 0
OPC_Error = 1
OPC_Delay = 2
OPC_DrawRLE = 3
OPC_DrawSquare = 4
OPC_DrawNumber100 = 5
OPC_DrawString = 6
OPC_DrawMetatileRow = 7
OPC_RAMWrite = 8
OPC_InsertMetasprite = 9
OPC_ScreenOff = 10
OPC_ScreenOn = 11
OPC_DrawRLEBurst = 12
OPC_Invalid = 13

;X, Y = Low/High address for first opcode to be interpreted.
State_Interpreter_Init:
	LDA #TRUE
	STA <INTERPRETER_STEP
	
	STX <INTERPRETER_PC
	STY <INTERPRETER_PC + 1
	DEC16 <INTERPRETER_PC ;Interpreter begins by stepping 1 byte forward
	
	LDA #OPC_Halt
	STA <INTERPRETER_OPC
	
	LDA #0
	STA <INTERPRETER_CPU
	STA <INTERPRETER_PPU
	STA <INT_SP1
	STA <INT_R1
	STA <INT_R2
	STA <INT_R3
	STA <INT_R4
	
	RTS
	
State_Interpreter:
	LDA <INTERPRETER_PC + 1
	CMP #$80
	BCC .Invalid_ProgCounter ;Outside ROM space, throw error immediately!
	
	LDA INTERPRETER_STEP
	CMP #TRUE
	BNE .run
	
.step
	INC16 <INTERPRETER_PC ;Moves program counter one byte forward
	
	LDY #0
	LDA [INTERPRETER_PC], y ;Loads opcode
	CMP #OPC_Invalid
	BCS .Invalid_Opcode ;Throws error if opcode doesn't exist.
	
	STA <INTERPRETER_OPC ;Stores loaded opcode
	LDA #FALSE
	STA <INTERPRETER_STEP ;Prevents PC from stepping until opcode subroutine is done.
	
	STY <INT_R1 ;Resets Reg #1 to 0
	
.run
	LDA <INTERPRETER_OPC
	JSI State_Table ;Indirect JSR to opcode's routine.
	
	RTS
	
.Invalid_ProgCounter
.Invalid_Opcode
	LDA #OPC_Error
	JSI State_Table
	RTS
	
;Steps PC by 1 and loads byte into A
;Intended to be used to load arguments.
;Trashes Y.
 .macro LPC
 .if (\# > 1)
	.fail
 .endif
	LDY #0
	INC <INTERPRETER_PC
	BNE .noOverflow\@
	INC <INTERPRETER_PC + 1
 .noOverflow\@:
	LDA [INTERPRETER_PC], y ;Loads argument byte
 .exit\@:
	.endm 
	
	
;Does nothing for now. Todo: halt and make game go to an error/debug state.
_OPC_Error:
	LDA #FALSE
	STA <INTERPRETER_STEP
	RTS
	
;Does nothing and prevents interpreter from moving forward.
;Arguments = 0 bytes.
_OPC_Halt:
	LDA #FALSE
	STA <INTERPRETER_STEP
	RTS
	
;Sends a command into the PPU Queue to turn it off.
;Arguments = 0 bytes.
_OPC_ScreenOff:
	JSR PPU_Queue1_Capacity
	CMP #1
	BCC .fail
	
	LDA #PPU_VIDEO_OFF
	JSR PPU_Queue1_Insert
	
	JSR Interpreter_AllowStep
	
.fail
	RTS
	
;Sends a command into the PPU Queue to turn it on.
;Arguments = 0 bytes.
_OPC_ScreenOn:
	JSR PPU_Queue1_Capacity
	CMP #1
	BCC .fail
	
	LDA #PPU_VIDEO_ON
	JSR PPU_Queue1_Insert
	
	JSR Interpreter_AllowStep
	
.fail
	RTS
	
;Waits for a number of frames before proceeding to next opcode.
;Arguments = 1 bytes (no. of frames)
;R1 = setup done 0 = no; 1 = yes
;R2 = timer
;R3 = timer limit
_OPC_Delay:
	LDA <INT_R1
	BNE .tick
.1stTimeSetup
	LDY #0
	STY <INT_R2 ;Resets timer
	
	INY
	STY <INT_R1
	
	LPC ;Steps and loads argument into A
	STA <INT_R3
	
.tick
	TCK <INT_R2
	LDA <INT_R2
	CMP <INT_R3
	BCC .exit
	JSR Interpreter_AllowStep
.exit
	RTS
	
;RAM Address to save index #, MSP #, X, Y
_OPC_InsertMetasprite:
	LPC
	STA <INT_R1
	LPC
	STA <INT_R2
	LPC
	PHA
	LPC
	TAX
	LPC
	TAY
	PLA
	
	JSR ObjectList_Insert
	LDY #0
	TXA
	STA [INT_R1], y
	
	JSR Interpreter_AllowStep
	RTS
	
;Writes value to RAM.	
;RAM Address, Value
_OPC_RAMWrite:
	LPC
	STA <INT_R1
	LPC
	STA <INT_R2
	LPC
	LDY #0
	STA [INT_R1], y
	
	JSR Interpreter_AllowStep
	RTS
	
;Schedules a metatile row draw.
;PPU Address, Metatile Address, Row Size
_OPC_DrawMetatileRow:
	JSR PPU_Queue1_Capacity
	CMP #6
	BCC .fail ;Needs at least 6 slots to work

	LDA #PPU_METATILEROW
	JSR PPU_Queue1_Insert
	
	LPC
	JSR PPU_Queue1_Insert
	LPC
	JSR PPU_Queue1_Insert
	LPC
	JSR PPU_Queue1_Insert
	LPC
	JSR PPU_Queue1_Insert
	
	LPC
	JSR PPU_Queue1_Insert
	
	JSR Interpreter_AllowStep
	
.fail
	RTS	
;Schedules a string draw.
;PPU address, String address (4bytes)
_OPC_DrawString:
	JSR PPU_Queue1_Capacity
	CMP #5
	BCC .fail ;Needs at least 5 slots to work

	LDA #PPU_DRAWSTRING
	JSR PPU_Queue1_Insert
	
	LPC
	JSR PPU_Queue1_Insert
	LPC
	JSR PPU_Queue1_Insert
	LPC
	JSR PPU_Queue1_Insert
	LPC
	JSR PPU_Queue1_Insert
	
	JSR Interpreter_AllowStep
	
.fail
	RTS
	
;PPU Address, Number Address (1byte)
_OPC_DrawNumber100:
	JSR PPU_Queue1_Capacity
	CMP #5
	BCC .fail ;Needs at least 5 slots to work
	
	LDA #PPU_NUMBER_100
	JSR PPU_Queue1_Insert
	
	;PPU address
	LPC
	JSR PPU_Queue1_Insert
	LPC
	JSR PPU_Queue1_Insert
	
	LPC
	STA <INT_R1
	LPC
	STA <INT_R2
	
	LDY #0
	LDA [INT_R1], y
	JSR Base100ToDecimal
	
	LDA <TEMP_BYTE
	JSR PPU_Queue1_Insert
	LDA <TEMP_BYTE + 1
	JSR PPU_Queue1_Insert
	
	
	JSR Interpreter_AllowStep
	
.fail
	RTS
	
;Set a PPU RLE write to be done during VBlank (NMI interrupt)
;Arguments: 4 bytes (PPU Target, CPU source)
_OPC_DrawRLE:
	JSR PPU_Queue1_Capacity
	CMP #5
	BCC .fail ;Needs at least 4 slots to work
	
	;PPU Interrupt command
	LDA #PPU_RLE
	JSR PPU_Queue1_Insert
	
	LPC
	JSR PPU_Queue1_Insert
	LPC
	JSR PPU_Queue1_Insert
	
	;CPU address
	LPC
	JSR PPU_Queue1_Insert
	LPC
	JSR PPU_Queue1_Insert
	
	JSR Interpreter_AllowStep
	
.fail ;If PPU queue lacks space for our command, try again next frame
	RTS
	
;ACTIVATE ONLY AFTER RUNNING OPC_ScreenOff!!!!!!
;Set a PPU RLE write to be done in a single frame, during PPU BURST.
;Arguments: 4 bytes (PPU Target, CPU source)
_OPC_DrawRLEBurst:
	JSR PPU_Queue1_Capacity
	CMP #5
	BCC .fail ;Needs at least 4 slots to work
	
	;PPU Interrupt command
	LDA #PPU_RLE_BURST
	JSR PPU_Queue1_Insert
	
	LPC
	JSR PPU_Queue1_Insert
	LPC
	JSR PPU_Queue1_Insert
	
	;CPU address
	LPC
	JSR PPU_Queue1_Insert
	LPC
	JSR PPU_Queue1_Insert
	
	JSR Interpreter_AllowStep
	
.fail ;If PPU queue lacks space for our command, try again next frame
	RTS


	
;Set a PPU RLE write to be done during VBlank (NMI interrupt)
;Arguments: 5 bytes (Tile #, Width, Height, PPUAddr)
_OPC_DrawSquare:
	JSR PPU_Queue1_Capacity
	CMP #6
	BCC .fail ;Needs at least two slots to work
	
	LDA #PPU_SQREPEAT
	JSR PPU_Queue1_Insert
	
	LPC
	JSR PPU_Queue1_Insert ;Tile #
	LPC
	JSR PPU_Queue1_Insert ;Length
	LPC
	JSR PPU_Queue1_Insert ;Height
	
	LPC
	JSR PPU_Queue1_Insert
	LPC
	JSR PPU_Queue1_Insert ;Pointer to PPU
	
	JSR Interpreter_AllowStep
	
.fail ;If PPU queue lacks space for our command, try again next frame
	RTS
	
Interpreter_AllowStep:
	LDA #TRUE
	STA <INTERPRETER_STEP
	RTS
	
;Pushes arguments starting at PC + 1 into stack
;X = # of args following opcode
Interpreter_PushArgs:
	STX <INT_R1
	LDX #0
	LDY #0
.loop
	LPC
	JSR Interpreter_Push
	INX
	CPX <INT_R1
	BNE .loop
	
	RTS
	
;A = value to be pushed to soft. stack 1
Interpreter_Push:
	LDY <INT_SP1
	CPY #INTERPRETER_STACK_MAX ;Is the stack full? (ie have we crossed the STACK_MAX - 1?)
	BCS .StackOverflow
	
	STA INTERPRETER_STACK, y
	INC <INT_SP1
	RTS
	
.StackOverflow:
	RTS
	
;Output: A = value on top of stack
;Stack pointer is decreased (the top is "removed")
Interpreter_Pop:
	LDY <INT_SP1
	BEQ .StackUnderflow ;Stack empty (ie next empty position = 0)
	
	DEC <INT_SP1
	DEY
	LDA INTERPRETER_STACK, y
	
.StackUnderflow:
	RTS
	
;Output: A = value on top of stack
;No changes to the stack are done.
Interpreter_Peek:
	LDY <INT_SP1
	BEQ .StackUnderflow ;Stack empty, no value to peek at.
	
	DEY
	LDA INTERPRETER_STACK, y ;Loads top of stack into A
	
.StackUnderflow:
	RTS
	