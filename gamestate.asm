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
	.dw 0 ;game
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
	.dw 0 ;game
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
