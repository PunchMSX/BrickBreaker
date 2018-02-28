;Titlescreen.asm
;Title screen game loop and related functions.
	
INTRO_MAXBULLETS = 8
INTRO_MAXCHARS = 2
INTRO_SPAWNTIME = 25 ;1/2s NTSC
	
Text_00:
	.db 1
	.db "00"
	.db 1, 0
	
Intro_StateMachine:
	.db OPC_ScreenOff

	.db OPC_DrawRLEBurst
	.dw $2000, bg_Title_Screen
	
	.db OPC_ScreenOn
	
	.db OPC_Delay, 30
	
	.db OPC_RAMWrite
	.dw TITLE_START
	.db TRUE
	
	.db OPC_Delay, 250
	.db OPC_Delay, 200

	.db OPC_Halt
	
	
Title_Init:
	LDA #0
	STA INTRO_BULLETQ
	STA INTRO_CHARQ
	STA INTRO_TIMER
	
	LDA #FALSE
	STA TITLE_START

	LDA #0
	LDX #LOW(Intro_StateMachine)
	LDY #HIGH(Intro_StateMachine)
	JSR State_Interpreter_Init
	
	JSR CollisionMap_TitleBorder

	RTS

Title_Loop:
	JSR State_Interpreter

	;Waits for our title screen to be drawn.
	LDA TITLE_START
	CMP #TRUE
	BEQ .cont
	
	RTS
	
.cont
	TCK INTRO_SPAWN_TMR
	TCK INTRO_SPAWN_TMR + 1
	
	JSR Intro_SpawnBullets
	JSR Intro_SpawnChars
	
.StartButton
	LDA CTRLPORT_1
	AND #CTRL_START
	BEQ .end
	LDA OLDCTRL_1
	AND #CTRL_START
	BNE .end
	
	LDA #STATE_GAME
	JSR GameState_Change
.end
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
	
	LDX #$80
	LDY #$80
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