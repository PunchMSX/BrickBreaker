;State.asm
;Defines a state machine interpreter
;used mostly for non-interactive parts of the game and
;PPU draw scheduling

State_Table:
	.dw _OPC_Halt - 1
	.dw _OPC_Error - 1
	.dw _OPC_Delay - 1
	.dw _OPC_ScheduleDraw - 1
	.dw _OPC_DrawRLE - 1
	.dw _OPC_DrawRepeatTiles - 1
	
;1-byte ops that represent a function call 
;(I don't remember what OPC stands for :P)
OPC_Halt = 0
OPC_Error = 1
OPC_Delay = 2
OPC_ScheduleDraw = 3
OPC_DrawRLE = 4
OPC_DrawRepeatTiles = 5
	
OPC_Invalid = OPC_DrawRepeatTiles + 1

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
	
	LPC ;Steps and loads argument into A
	STA <INT_R3
	
	INY
	STY <INT_R1
	
.tick
	TCK <INT_R2
	LDA <INT_R2
	CMP <INT_R3
	BCC .exit
	JSR Interpreter_AllowStep
.exit
	RTS

;Pushes a CPU and a PPU Address into the stack.
;Args =  4 bytes (Addresses = Lo/Hi)
_OPC_ScheduleDraw:
	LDX #4
	JSR Interpreter_PushArgs
	
	JSR Interpreter_AllowStep
	RTS
	
;Set a PPU RLE write to be done during VBlank (NMI interrupt)
;Arguments: 0
_OPC_DrawRLE:
RLE_MAXBYTES = 24
	LDA <INT_R1
	BNE .waitNMI
.1stTimeSetup
	LDA #RLE_MAXBYTES
	STA RLE_MAX
	
	JSR Interpreter_Pop
	STA PPUADDR_NAM ;PPUADDR = Hi/Lo
	JSR Interpreter_Pop
	STA PPUADDR_NAM + 1
	
	JSR Interpreter_Pop
	STA CPUADDR_NAM + 1 ;CPUADDR = Lo/Hi
	JSR Interpreter_Pop
	STA CPUADDR_NAM
	
	INC <INT_R1
	LDA #PPU_RLEDRAW
	STA PPU_DRAW
	
.waitNMI
	LDA PPU_DRAW
	CMP #PPU_NODRAW
	BNE .end
	
	JSR Interpreter_AllowStep
.end
	RTS
	
;Set a PPU RLE write to be done during VBlank (NMI interrupt)
;Arguments: 5 bytes (Tile #, Length, IsHorizontal, PPUAddr)
_OPC_DrawRepeatTiles:
	LDA <INT_R1
	BNE .waitNMI
.1stTimeSetup:
	LPC
	STA <INT_R2 ;Tile #
	LPC
	STA <INT_R3 ;Length
	
	LPC
	STA <INT_R4 ;IsHoriz
	
	LPC
	STA <INT_16R1
	LPC
	STA <INT_16R1 + 1 ;Pointer to PPU

	INC <INT_R1
	
.waitNMI
	LDA PPU_DRAW
	CMP #PPU_NODRAW
	BNE .end
	
	LDA <INT_R3
	CMP #0
	BNE .write
	;If R3 (length) = 0, no more stuff to write, step to next opcode.
	JSR Interpreter_AllowStep
	RTS
	
.write
	;Ready to draw new tiles, draw remaining
	LDA <INT_R4
	STA PPU_HORIZ
	
	LDA <INT_16R1 + 1
	STA PPUADDR_NAM
	LDA <INT_16R1
	STA PPUADDR_NAM + 1
	
	LDA <INT_R3
	CMP #RLE_MAXBYTES
	BCS .WriteMax
	JMP .WriteRemaining
	
.WriteMax ;Writes a run of bytes.
	LDA #RLE_MAXBYTES
	STA PPU_LENGTH
	LDA <INT_R2
	STA PPU_BYTE
	
	LDA #PPU_BYTEDRAW
	STA PPU_DRAW
	
	CLC
	LDA #RLE_MAXBYTES
	ADC <INT_16R1
	STA <INT_16R1
	BCC .addEnd
	INC <INT_16R1 + 1 ;Increases PPU address by # of bytes written
.addEnd

	SEC
	LDA <INT_R3
	SBC #RLE_MAXBYTES
	STA <INT_R3 ;Also subtracts length so we can keep track of how many bytes are left.
	JMP .end
	
.WriteRemaining ;Last writing run
	LDA <INT_R3
	STA PPU_LENGTH
	LDA <INT_R2
	STA PPU_BYTE
	
	LDA #PPU_BYTEDRAW
	STA PPU_DRAW
	
	LDA #0
	STA <INT_R3
.end
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
	