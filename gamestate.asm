;gamestate.asm

STATE_INSTRUCTIONS = 0
STATE_TITLE = 1
STATE_HISCORE = 2
STATE_GAME = 3
STATE_PUZZLEGAME = 4
STATE_GAMEOVER = 5
STATE_ENDING_WIN = 6
STATE_DEBUG = 7
STATE_ERROR = 8
	
GameState_Change:
	LDX GAME_STATE
	STX GAME_OLDSTATE
	STA GAME_STATE
	LDA #TRUE
	STA GAME_TRANSITION
	RTS

GameState_Table:
	.dw State_Instructions - 1 ;instructions.asm
	.dw Title_Loop - 1 ;titlescr.asm
	.dw State_HighScore - 1 ;titlescr.asm
	.dw State_Match - 1
	.dw 0 ;puzzlegame
	.dw 0 ;gameover
	.dw 0 ;ending_win
	.dw Debug_MapEdit - 1 ;debug.asm
	
GameStateInit_Table:
	.dw State_Instructions_Init - 1 ;instrutions.asm
	.dw Title_Init - 1 ;titlescr.asm
	.dw State_HiScore_Init - 1 ;titlescr.asm
	.dw State_Match_Init - 1
	.dw 0 ;puzzlegame
	.dw 0 ;gameover
	.dw 0 ;ending_win
	.dw Debug_MapEdit_Init - 1 ;debug.asm
	
GameStateManager:
	LDA GAME_STATE
	CMP #STATE_ERROR
	BCS .error	;if the state is invalid
	LDA GAME_TRANSITION
	CMP #TRUE
	BNE .continue
	
.new
	JSR PPU_Queue1_Reset ;Clears PPU job queue
	JSR ObjectList_Init ;Clears metasprite list
	
	LDA GAME_STATE
	JSI GameStateInit_Table
	
	LDA #FALSE
	STA GAME_TRANSITION

.continue
	LDA GAME_STATE
	JSI GameState_Table
	
	RTS
	
.error
	RTS

 .include "matchdata.txt"
 
Match0_StateMachine:
	.db OPC_RAMWrite
	.dw INSTRUCT_SYNC
	.db 0

	.db OPC_DrawSquare, $40, 32, 30
	.dw $2000
	
	.db OPC_Delay, 60
	
	.db OPC_DrawRLE
	.dw $2000, bg_Playfield
	
	.db OPC_Delay, 60
	
	.db OPC_DrawMetatileRow
	.dw $20C2, COLLISION_MAP + 49
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2102, COLLISION_MAP + 49 + 16 * 1
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2142, COLLISION_MAP + 49 + 16 * 2
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2182, COLLISION_MAP + 49 + 16 * 3
	.db 14
	
	.db OPC_Delay, 50
	
	.db OPC_DrawSquare, $20, 6, 2
	.dw $21CD
	
	.db OPC_DrawString
	.dw $21ED, Text_Start
	
	.db OPC_Delay, 25
	
	.db OPC_DrawSquare, $20, 6, 2
	.dw $21CD
	
	.db OPC_Delay, 25
	
	.db OPC_DrawSquare, $20, 6, 2
	.dw $21CD
	
	.db OPC_DrawString
	.dw $21ED, Text_Start
	
	.db OPC_Delay, 25
	
	.db OPC_DrawSquare, $20, 6, 2
	.dw $21CD
	
	.db OPC_Delay, 25
	
	.db OPC_DrawSquare, $20, 6, 2
	.dw $21CD
	
	.db OPC_DrawString
	.dw $21ED, Text_Start
	
	.db OPC_Delay, 25
	
	.db OPC_RAMWrite
	.dw MATCH_START
	.db TRUE
	
	.db OPC_DrawMetatileRow
	.dw $21C2, COLLISION_MAP + 49 + 16 * 4
	.db 14
	
	.db OPC_Halt
	
State_Match_Init:
	LDA MATCH_LEVEL
	BEQ .exit		;if level = 0, will play instruction screen then come back with level = 1

	LDX #LOW(Match0_StateMachine)
	LDY #HIGH(Match0_StateMachine)
	JSR State_Interpreter_Init
	
	;Gets the current enemy's field arrangement and uploads into collision map.
	LDA MATCH_LEVEL
	TZP16 CALL_ARGS, Match_EnemyMaps
	JSR CollisionMap_UploadTop
	
	;Resets score
	LDA #0
	STA MATCH_P1SCORE
	STA MATCH_P2SCORE
	;Resets Frame Timer
	STA MATCH_FRAMES
	LDA #MATCH_TIMER_DEFAULT
	STA MATCH_TIMER
	;Resets # of balls
	LDA #MATCH_BALL_MAX
	STA MATCH_P1BALLS
	STA MATCH_P2BALLS
	
	LDA #FALSE
	STA MATCH_START
.exit
	RTS
	
State_Match:
	LDA MATCH_LEVEL
	BNE .cont
	
	LDA #STATE_INSTRUCTIONS
	JSR GameState_Change
	RTS
	
.cont
	JSR State_Interpreter
	
	LDA MATCH_START
	CMP #FALSE
	BEQ .exit
	
.updateTimer
	TCK MATCH_FRAMES
	LDA MATCH_FRAMES
	CMP #50
	BCC .asdf
	DEC MATCH_TIMER
	JSR Match_UpdateTimer
.asdf
	
.exit
	RTS
	
	
Match_UpdateTimer
	LDA #0
	STA MATCH_FRAMES
	
	LDA #LOW(MATCH_TIMER)
	STA <CALL_ARGS + 2
	LDA #HIGH(MATCH_TIMER)
	STA <CALL_ARGS + 3
	
	LDA #LOW(MATCH_TIMER_PPU)
	STA <CALL_ARGS
	LDA #HIGH(MATCH_TIMER_PPU)
	STA <CALL_ARGS + 1
	
	JSR PPU_DrawLargeBase100
	
	RTS
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	