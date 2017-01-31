;gamestate.asm

STATE_INSTRUCTIONS = 0
STATE_TITLE = 1
STATE_HISCORE = 2
STATE_GAME = 3
STATE_TIMEUP = 4
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
	.dw 0 ;timeup
	.dw 0 ;gameover
	.dw 0 ;ending_win
	.dw Debug_MapEdit - 1 ;debug.asm
	
GameStateInit_Table:
	.dw State_Instructions_Init - 1 ;instrutions.asm
	.dw Title_Init - 1 ;titlescr.asm
	.dw State_HiScore_Init - 1 ;titlescr.asm
	.dw State_Match_Init - 1
	.dw 0 ;timeup
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
	.dw $2082, COLLISION_MAP + 33
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2082 + 64 * 1, COLLISION_MAP + 33 + 16 * 1
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2082 + 64 * 2, COLLISION_MAP + 33 + 16 * 2
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2082 + 64 * 3, COLLISION_MAP + 33 + 16 * 3
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2082 + 64 * 4, COLLISION_MAP + 33 + 16 * 4
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2082 + 64 * 5, COLLISION_MAP + 33 + 16 * 5
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2082 + 64 * 6, COLLISION_MAP + 33 + 16 * 6
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2082 + 64 * 7, COLLISION_MAP + 33 + 16 * 7
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2082 + 64 * 8, COLLISION_MAP + 33 + 16 * 8
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2082 + 64 * 9, COLLISION_MAP + 33 + 16 * 9
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2082 + 64 * 10, COLLISION_MAP + 33 + 16 * 10
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
	.db 2
	
	.db OPC_DrawMetatileRow
	.dw $21C2, COLLISION_MAP + 33 + 16 * 5
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
	JSR CollisionMap_UploadMap
	
	LDA #0
	;Resets Frame Timer
	STA MATCH_FRAMES
	LDA #MATCH_TIMER_DEFAULT
	STA MATCH_TIMER
	
	LDA #$FF
	STA MATCH_BALLID
	
	LDA #FALSE
	STA MATCH_START
.exit
	RTS
	
State_Match:
	LDA MATCH_LEVEL
	BNE .cont
	LDA #MATCH_LIVES_DEFAULT
	STA MATCH_P1LIFE
	LDA #0
	STA MATCH_P1SCORE
	STA MATCH_P1SCORE + 1
	
	LDA #STATE_INSTRUCTIONS
	JSR GameState_Change
	RTS
	
.cont
	JSR State_Interpreter
	
	LDA MATCH_START
	CMP #FALSE
	BEQ .exit
	CMP #TRUE
	BEQ Match_Play
	
	CMP #2
	BEQ Match_Play_Init
	
.exit
	RTS
	
Match_Play_Init:
	LDA #TRUE
	STA MATCH_START
	LDX #$78
	LDY #$C2
	LDA #OBJ_PLAYER
	JSR ObjectList_Insert
	STA MATCH_PLAYERID
	
	PHA
	
	LDA #OBJ_BALL_LAUNCHER
	JSR ObjectList_Insert
	STA MATCH_BALLID
	TAX
	
	PLA
	TAY
	LDA PLAYER_UMBRELLAID, y
	STA LAUNCHER_PARENTID, x
	
	;Draw level # on screen
	LDA #LOW(MATCH_LEVEL)
	STA <CALL_ARGS + 2
	LDA #HIGH(MATCH_LEVEL)
	STA <CALL_ARGS + 3
	
	LDA #LOW(MATCH_LEVEL_PPU)
	STA <CALL_ARGS
	LDA #HIGH(MATCH_LEVEL_PPU)
	STA <CALL_ARGS + 1
	
	JSR PPU_DrawLargeBase100
	
	;Draw timer on screen, too.
	JSR Match_UpdateTimer
	
	LDA #0
	JSR FamiToneMusicPlay
	
	RTS
	
Match_Play:
	JSR Match_MonitorBall
	
.updateTimer
	LDA MATCH_FRAMES
	TCK MATCH_FRAMES
	LDA MATCH_FRAMES
	CMP #50
	BCC .asdf
	DEC MATCH_TIMER
	BEQ .timeup
	JSR Match_UpdateTimer
.asdf
	JMP .exit

.timeup
	INC MATCH_TIMER
.exit
	RTS
	
	
Match_UpdateScore:
	
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
	
Match_MonitorBall:
	LDY MATCH_BALLID
	LDA OBJ_LIST, y
	CMP #$FF
	BEQ .replace
	RTS

.replace
		BIT $6669
	LDY MATCH_PLAYERID
	LDA PLAYER_UMBRELLAID, y
	PHA
	TAY
	
	LDA OBJ_XPOS, y
	TAX
	LDA OBJ_YPOS, y
	TAY
	LDA #OBJ_BALL_LAUNCHER
	JSR ObjectList_Insert
	STA MATCH_BALLID
	TAX
	PLA
	STA LAUNCHER_PARENTID, x
	RTS
	
Match_ScanForTiles:
	LDX #0
	LDY #0
.loop
	LDA COLLISION_MAP, x
	AND #%00011111
	BEQ .continue
	CMP #TILE_BRICK
	BEQ .found
	CMP #TILE_DAMAGEDBRICK
	BEQ .found

.continue
	INX
	CPX #240
	BCS .notfound
	JMP .loop
.notfound
	LDA #FALSE
	RTS
.found
	LDA #TRUE
	RTS
	