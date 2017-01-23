;gamestate.asm

STATE_TITLE = 1
STATE_HISCORE = 2
STATE_GAME = 3
STATE_PUZZLEGAME = 4
STATE_GAMEOVER = 5
STATE_ENDING_WIN = 6
STATE_ENDING_LOSE = 7
STATE_FALSEENDING = 8
STATE_CREDITS = 9
STATE_DEBUG_MAP = 10
STATE_DEBUG_COLLISION = 11
STATE_ERROR = 12
	
GameState_Change:
	LDX GAME_STATE
	STX GAME_OLDSTATE
	STA GAME_STATE
	LDA #TRUE
	STA GAME_TRANSITION
	RTS

GameState_Table:
	.dw 0
	.dw Title_Loop - 1 ;titlescr.asm
	.dw State_HighScore - 1 ;titlescr.asm
	.dw State_Match - 1
	.dw 0 ;puzzlegame
	.dw 0 ;gameover
	.dw 0 ;ending_win
	.dw 0 ;ending_lose
	.dw 0 ;falseendnig
	.dw 0 ;credits
	.dw Debug_MapEdit - 1 ;debug.asm
	.dw 0 ;debug collision
	.dw 0 ;error handler	
	
GameStateInit_Table:
	.dw 0
	.dw Title_Init - 1 ;titlescr.asm
	.dw State_HiScore_Init - 1 ;titlescr.asm
	.dw State_Match_Init - 1
	.dw 0 ;puzzlegame
	.dw 0 ;gameover
	.dw 0 ;ending_win
	.dw 0 ;ending_lose
	.dw 0 ;falseendnig
	.dw 0 ;credits
	.dw Debug_MapEdit_Init - 1 ;debug.asm
	.dw 0 ;debug collision
	.dw 0 ;error handler
	
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
 
Match_StateMachine:
	.db OPC_DrawSquare, $40, 32, 30
	.dw $2000
	
	.db OPC_Delay, 60
	
	.db OPC_DrawRLE
	.dw $2000, bg_Playfield
	
	.db OPC_Delay, 60
	
	.db OPC_DrawString
	.dw $20EE, Match_Text_Name
	
	.db OPC_DrawString
	.dw $20F4, Match_Char0Name
	
	.db OPC_DrawString
	.dw $2143, Match_Char0Bio
	
	.db OPC_DrawString
	.dw $210C, Match_Char0Record
	
	.db OPC_DrawMetatileRow
	.dw $20C2, COLLISION_MAP + 49
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2102, COLLISION_MAP + 49 + 16
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2142, COLLISION_MAP + 49 + 32
	.db 14
	
	.db OPC_DrawMetatileRow
	.dw $2182, COLLISION_MAP + 49 + 48
	.db 14
	
	.db OPC_DrawString
	.dw $20C2, Match_Instructions1
	
	.db OPC_Halt
	
State_Match_Init:
	LDX #LOW(Match_StateMachine)
	LDY #HIGH(Match_StateMachine)
	JSR State_Interpreter_Init
	LDA #LOW(Match_Char0Map)
	STA <CALL_ARGS
	LDA #HIGH(Match_Char0Map)
	STA <CALL_ARGS + 1
	JSR CollisionMap_UploadTop
	RTS
	
State_Match:
	JSR State_Interpreter
	RTS
	
	
	