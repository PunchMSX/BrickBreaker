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
	.db OPC_DrawSquare, $40, 32, 30
	.dw $2000
	
	.db OPC_Delay, 50

	.db OPC_DrawRLE
	.dw $2000, bg_Title_Screen
	
	.db OPC_Delay, 100
	
	.db OPC_Delay, 250
	.db OPC_Delay, 200

	.db OPC_Halt
	
Hiscore_StateMachine:
	.db OPC_DrawSquare, $40, 32, 30
	.dw $2000

	.db OPC_DrawRLE
	.dw $2000, bg_HighScore
	
	.db OPC_DrawNumber100
	.dw $2111, GAME_HISCORES
	
	.db OPC_DrawNumber100
	.dw $2113, GAME_HISCORES + 1
	
	.db OPC_DrawRLE
	.dw $2115, Text_00
	
	.db OPC_DrawNumber100
	.dw $2191, GAME_HISCORES + 2
	
	.db OPC_DrawNumber100
	.dw $2193, GAME_HISCORES + 3
	
	.db OPC_DrawRLE
	.dw $2195, Text_00
	
	.db OPC_DrawNumber100
	.dw $2211, GAME_HISCORES + 4
	
	.db OPC_DrawNumber100
	.dw $2213, GAME_HISCORES + 5
	
	.db OPC_DrawRLE
	.dw $2215, Text_00
	
	.db OPC_DrawNumber100
	.dw $2291, GAME_HISCORES + 6
	
	.db OPC_DrawNumber100
	.dw $2293, GAME_HISCORES + 7
	
	.db OPC_DrawRLE
	.dw $2295, Text_00
	
	.db OPC_DrawNumber100
	.dw $2311, GAME_HISCORES + 8
	
	.db OPC_DrawNumber100
	.dw $2313, GAME_HISCORES + 9
	
	.db OPC_DrawRLE
	.dw $2315, Text_00
	
	.db OPC_Delay, 250
	.db OPC_Delay, 200
	
	.db OPC_RAMWrite
	.dw INTRO_SHOWSCORE
	.db TRUE
	
	.db OPC_Halt
	

State_HighScore:
	JSR State_Interpreter
	
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
	
	
State_HiScore_Init:
	LDX #LOW(Hiscore_StateMachine)
	LDY #HIGH(Hiscore_StateMachine)
	JSR State_Interpreter_Init
	
	RTS
	
;******************************************************************
HiScores_Init: ;default values for the high score table
	LDA #02
	STA GAME_HISCORES
	STA GAME_HISCORES + 2
	LDA #50
	STA GAME_HISCORES + 1
	LDA #22
	STA GAME_HISCORES + 3
	
	LDA #01
	STA GAME_HISCORES + 4
	STA GAME_HISCORES + 6
	LDA #49
	STA GAME_HISCORES + 5
	LDA #14
	STA GAME_HISCORES + 7
	
	LDA #00
	STA GAME_HISCORES + 8
	LDA #75
	STA GAME_HISCORES + 9
	
	LDA #$41
	STA GAME_INITIALS
	STA GAME_INITIALS + 1
	STA GAME_INITIALS + 2 ;1st = AAA
	
	STA GAME_INITIALS + 3
	LDA #$4C
	STA GAME_INITIALS + 4
	LDA #$46
	STA GAME_INITIALS + 5 ;2nd = ALF
	
	LDA #$4D
	STA GAME_INITIALS + 6
	LDA #$49
	STA GAME_INITIALS + 7
	LDA #$54
	STA GAME_INITIALS + 8 ;3rd = MIT
	
	LDA #$43
	STA GAME_INITIALS + 9
	LDA #$41
	STA GAME_INITIALS + 10
	LDA #$50
	STA GAME_INITIALS + 11 ;4th = CAP
	
	LDA #$53
	STA GAME_INITIALS + 12
	LDA #$4E
	STA GAME_INITIALS + 13
	LDA #$4B
	STA GAME_INITIALS + 14 ;5th = SNK
	
	RTS
	
	
	
Title_Init:
	LDA #0
	STA INTRO_BULLETQ
	STA INTRO_CHARQ
	STA INTRO_TIMER
	STA INTRO_SHOWSCORE

	LDX #LOW(Intro_StateMachine)
	LDY #HIGH(Intro_StateMachine)
	JSR State_Interpreter_Init
	
	JSR CollisionMap_TitleBorder

	RTS

Title_Loop:
	LDA INTRO_SHOWSCORE
	CMP #FALSE
	BEQ .cont
	
	LDA #STATE_HISCORE
	JSR GameState_Change
	
.cont
	TCK INTRO_SPAWN_TMR
	TCK INTRO_SPAWN_TMR + 1
	
	JSR Intro_SpawnBullets
	JSR Intro_SpawnChars
	
	JSR State_Interpreter
	
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