;Titlescreen.asm
;Title screen game loop and related functions.
	
INTRO_MAXBULLETS = 8
INTRO_MAXCHARS = 2
INTRO_SPAWNTIME = 25 ;1/2s NTSC
	
Intro_StateMachine:
	.db OPC_DrawRLE
	.dw $2000, bg_Title_Screen
	
	.db OPC_Delay, 100
	
	.db OPC_DrawRLE
	.dw $2043, Text_ProgBy
	
	.db OPC_DrawRLE
	.dw $236C, Text_PushRun
	
	.db OPC_Delay, 1
	.db OPC_Halt
	

	
Title_Init:
	LDA #0
	STA INTRO_BULLETQ
	STA INTRO_CHARQ
	STA INTRO_TIMER

	LDX #LOW(Intro_StateMachine)
	LDY #HIGH(Intro_StateMachine)
	JSR State_Interpreter_Init

	RTS

Title_Loop:
	TCK INTRO_SPAWN_TMR
	TCK INTRO_SPAWN_TMR + 1
	
	JSR Intro_SpawnBullets
	JSR Intro_SpawnChars
	
	JSR State_Interpreter
	
	RTS
	
;*****************************************************************
	
Intro_SpawnBullets:
	LDA INTRO_BULLETQ
	CMP #INTRO_MAXBULLETS
	BCC .checkTimer
	RTS
.checkTimer
	LDA INTRO_SPAWN_TMR
	CMP #INTRO_SPAWNTIME
	BCC .end
	
	JSR RNG_Next
	TAX
	JSR RNG_Next
	TAY
	LDA #OBJ_INTRO_BALL
	JSR ObjectList_Insert ;Intro_Ball
	
	CMP #$FF
	BEQ .end ;Did not spawn, don't reset the timer
	
	LDA #0
	STA INTRO_SPAWN_TMR
	INC INTRO_BULLETQ
.end;
	RTS
	
Intro_SpawnChars:
	LDA INTRO_CHARQ
	CMP #INTRO_MAXCHARS
	BCC .checkTimer
	RTS
.checkTimer
	LDA INTRO_SPAWN_TMR + 1
	CMP #INTRO_SPAWNTIME * 2
	BCC .end
	
	LDA #OBJ_INTRO_PLAYER
	JSR ObjectList_Insert ;Main Character
	
	CMP #$FF
	BEQ .end ;Did not spawn, don't reset the timer
	
	LDA #0
	STA INTRO_SPAWN_TMR + 1
	INC INTRO_CHARQ
.end
	RTS