;Titlescreen.asm
;Title screen game loop and related functions.
	
INTRO_MAXBULLETS = 8
INTRO_MAXCHARS = 2
INTRO_SPAWNTIME = 25 ;1/2s NTSC
	
Intro_StateMachine:
	.db OPC_ScheduleDraw
	.dw bg_Title_Screen, $2000
	.db OPC_DrawRLE
	
	.db OPC_Delay, 50
	
	.db OPC_ScheduleDraw
	.dw Text_ProgBy, $2043
	.db OPC_ScheduleDraw
	.dw Text_PushRun, $236C
	.db OPC_DrawRLE
	.db OPC_DrawRLE
	
	.db OPC_Delay, 1
	
	.db OPC_DrawRepeatTiles, $0E, 4, TRUE
	.dw $2210
	.db OPC_DrawRepeatTiles, $0E, 4, TRUE
	.dw $2211
	
	.db OPC_DrawRepeatTiles, $0E, 6, TRUE
	.dw $21D2
	.db OPC_DrawRepeatTiles, $0E, 6, TRUE
	.dw $21D3
	
	.db OPC_DrawRepeatTiles, $0E, 4, FALSE
	.dw $21CE
	.db OPC_DrawRepeatTiles, $0E, 4, FALSE
	.dw $21EE
	
	.db OPC_DrawRepeatTiles, $0E, 6, TRUE
	.dw $220E
	.db OPC_DrawRepeatTiles, $0E, 6, TRUE
	.dw $220F
	
	.db OPC_DrawRepeatTiles, $0E, 6, FALSE
	.dw $2290
	.db OPC_DrawRepeatTiles, $0E, 6, FALSE
	.dw $22B0
	
	.db OPC_DrawRepeatTiles, $0E, 8, TRUE
	.dw $2194
	.db OPC_DrawRepeatTiles, $0E, 8, TRUE
	.dw $2195
	
	
	.db OPC_Halt
	
TitleInit:
	LDA #0
	STA INTRO_BULLETQ
	STA INTRO_CHARQ
	STA INTRO_TIMER

	LDX #LOW(Intro_StateMachine)
	LDY #HIGH(Intro_StateMachine)
	JSR State_Interpreter_Init

	RTS

TitleLoop:
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
	LDA #4
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
	
	LDA #2
	JSR ObjectList_Insert ;Main Character
	
	CMP #$FF
	BEQ .end ;Did not spawn, don't reset the timer
	
	LDA #0
	STA INTRO_SPAWN_TMR + 1
	INC INTRO_CHARQ
.end
	RTS