;gamestate.asm

STATE_PAUSE	= 0
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


GameState_Table:
	.dw 0 ;pause
	.dw Title_Loop - 1 ;titlescr.asm
	.dw 0 ;hiscore
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
	.dw 0 ;pause
	.dw Title_Init - 1 ;titlescr.asm
	.dw 0 ;hiscore
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
	CMP GAME_OLDSTATE
	BEQ .continue
	
.new
	JSR PPU_Queue1_Reset ;Clears PPU job queue
	JSR ObjectList_Init ;Clears metasprite list
	
	LDA GAME_STATE
	JSI GameStateInit_Table
	
	LDA GAME_STATE

.continue
	STA GAME_OLDSTATE
	JSI GameState_Table
	
	RTS
	
.error
	RTS
	