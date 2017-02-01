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
	
	.db OPC_DrawSquare, $40, 28, 22
	.dw $2082
	
	.db OPC_Delay, 50
	
	.db OPC_RAMWrite
	.dw TIMEUP_GO
	.db 2
	
	.db OPC_DrawString
	.dw $21C5, Text_Continue
	
	.db OPC_Delay, 15
	
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
	CMP #FALSE
	BEQ .exit
	
;Draw number of "lives" (credits)
	LDA #LOW(MATCH_P1LIFE)
	STA <CALL_ARGS + 2
	LDA #HIGH(MATCH_P1LIFE)
	STA <CALL_ARGS + 3
	
	LDA #LOW($222E)
	STA <CALL_ARGS
	LDA #HIGH($222E)
	STA <CALL_ARGS + 1
	
	JSR PPU_DrawLargeBase100
	
.exit
	RTS
	
.transition	
	LDA MATCH_P1LIFE
	BEQ .gover
	LDA CTRLPORT_1
	AND #CTRL_START
	BNE .continue
	LDA CTRLPORT_1
	AND #CTRL_SELECT
	BNE .gover
	RTS
	
.continue
	DEC MATCH_P1LIFE
	LDA #MATCH_BALLS_DEFAULT
	STA MATCH_P1BALL
	LDA #0
	STA MATCH_P1SCORE
	STA MATCH_P1SCORE + 1
	
	LDA #FALSE
	STA MATCH_REENTRANT
	LDA #STATE_GAME
	JSR GameState_Change
	RTS
	
.gover
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
	INC MATCH_P1BALL
	LDA #STATE_GAME
	JSR GameState_Change
	RTS
