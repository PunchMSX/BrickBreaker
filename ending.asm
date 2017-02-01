;ending.asm

Text_Ending:
	.db "CONGRATULATIONS!!!&&"
	
	.db "YOU HAVE CONQUERED&"
	.db "    ALL STAGES!&&"
	
	.db "THANKS FOR PLAYING!&"
	.db "           -PUNCH&&&"
	
	.db " YOUR FINAL SCORE&"
	
	.db 0
	
	
Ending_StateMachine:
	.db OPC_DrawString
	.dw $21EB, Text_Welldone
	
	.db OPC_Delay, 250
	
	.db OPC_DrawSquare, $40, 28, 22
	.dw $2082
	
	.db OPC_Delay, 50
	
	.db OPC_RAMWrite
	.dw TIMEUP_GO
	.db 2
	
	.db OPC_DrawString
	.dw $2107, Text_Ending
	
	.db OPC_Delay, 250
	.db OPC_Delay, 250
	
	.db OPC_RAMWrite
	.dw TIMEUP_GO
	.db TRUE
	
	.db OPC_Halt

	
State_Ending_Init:
	LDA #FALSE
	STA TIMEUP_GO
	
	LDX #LOW(Ending_StateMachine)
	LDY #HIGH(Ending_StateMachine)
	JSR State_Interpreter_Init
	RTS
	
State_Ending:
	JSR State_Interpreter
	LDA TIMEUP_GO
	CMP #TRUE
	BEQ .transition
	CMP #FALSE
	BEQ .exit
	
	LDA #LOW(MATCH_P1SCORE)
	STA <CALL_ARGS + 2
	LDA #HIGH(MATCH_P1SCORE)
	STA <CALL_ARGS + 3
	
	LDA #LOW($224D)
	STA <CALL_ARGS
	LDA #HIGH($224D)
	STA <CALL_ARGS + 1
	
	JSR PPU_DrawLargeBase100
	
	
	LDA #LOW(MATCH_P1SCORE + 1)
	STA <CALL_ARGS + 2
	LDA #HIGH(MATCH_P1SCORE + 1)
	STA <CALL_ARGS + 3
	
	LDA #LOW($224F)
	STA <CALL_ARGS
	LDA #HIGH($224F)
	STA <CALL_ARGS + 1
	
	JSR PPU_DrawLargeBase100
	
	LDA #LOW(Zeroes)
	STA <CALL_ARGS + 2
	LDA #HIGH(Zeroes)
	STA <CALL_ARGS + 3
	
	LDA #LOW($2251)
	STA <CALL_ARGS
	LDA #HIGH($2251)
	STA <CALL_ARGS + 1
	
	JSR PPU_DrawLargeBase100
	
.exit
	RTS
	
	
.transition:
	LDA #0
	STA MATCH_LEVEL
	LDA #STATE_TITLE
	JSR GameState_Change
	RTS
