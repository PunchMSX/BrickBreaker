;timeup.asm

Timeup_StateMachine:
	.db OPC_DrawString
	.dw $21ED, Text_Timeup
	
	.db OPC_Delay, 250
	
	.db OPC_RAMWrite
	.dw TIMEUP_GO
	.db TRUE
	
	
	.db OPC_Halt
	
Gameover_StateMachine:
	.db OPC_DrawString
	.dw $21EB, Text_Gameover
	
	.db OPC_Delay, 250
	
	.db OPC_RAMWrite
	.dw TIMEUP_GO
	.db TRUE
	
	
	.db OPC_Halt

	
State_Timeup_Init:
	LDA #FALSE
	STA TIMEUP_GO
	
	LDX #LOW(Timeup_StateMachine)
	LDY #HIGH(Timeup_StateMachine)
	JSR State_Interpreter_Init
	RTS
	
State_Timeup:
	JSR State_Interpreter
	LDA TIMEUP_GO
	CMP #TRUE
	BEQ .transition
	RTS
	
.transition
	DEC MATCH_P1BALL
	BEQ .gameover
	LDA #TRUE
	STA MATCH_REENTRANT
	LDA #STATE_GAME
	JSR GameState_Change
	RTS
	
.gameover
	LDA #FALSE
	STA MATCH_REENTRANT
	LDA #STATE_GAMEOVER
	JSR GameState_Change
	RTS

	
State_Gameover_Init:
	LDA #FALSE
	STA TIMEUP_GO
	
	LDX #LOW(Gameover_StateMachine)
	LDY #HIGH(Gameover_StateMachine)
	JSR State_Interpreter_Init
	RTS
	
State_Gameover:
	JSR State_Interpreter
	LDA TIMEUP_GO
	CMP #TRUE
	BEQ .transition
	RTS
	
.transition
	LDA #0
	STA MATCH_LEVEL
	LDA #STATE_TITLE
	JSR GameState_Change
	RTS
	
	
Win_StateMachine:
	.db OPC_DrawSquare, $40, 28, 22
	.dw $2082
	
	.db OPC_Delay, 50
	
	.db OPC_DrawString
	.dw $21EB, Text_Welldone
	
	.db OPC_Delay, 250
	
	.db OPC_RAMWrite
	.dw TIMEUP_GO
	.db TRUE
	
	.db OPC_Halt

	
State_Win_Init:
	LDA #FALSE
	STA TIMEUP_GO
	
	LDX #LOW(Win_StateMachine)
	LDY #HIGH(Win_StateMachine)
	JSR State_Interpreter_Init
	RTS
	
State_Win:
	JSR State_Interpreter
	LDA TIMEUP_GO
	CMP #TRUE
	BEQ .transition
	RTS
	
.transition
	LDA #STATE_GAME
	JSR GameState_Change
	RTS
