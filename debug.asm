;debug.asm

Char_STAR = $12

Debug_RLEText0:
	.db 1
	.db $20, Char_STAR
	.db " DEBUG MAP EDIT SCREEN "
	.db Char_STAR, $20
	.db 1, 0
Debug_RLEText1:
	.db 1
	.db "START "
	.db Char_STAR
	.db " COLLISION TEST"
	.db 1, 0
Debug_RLEText2:
	.db 1
	.db  "A "
	.db Char_STAR 
	.db " REM"
	.db 1, 0
Debug_RLEText3:
	.db 1
	.db  "B "
	.db Char_STAR 
	.db " INS"
	.db 1, 0

Debug_StateMachine0:
	.db OPC_DrawSquare, $0D, 32, 30
	.dw $2000
	
	.db OPC_Delay, 60
	
	.db OPC_DrawRLE
	.dw $2000, bg_Playfield
	
	.db OPC_DrawSquare, $20, 28, 3
	.dw $2342
	
	.db OPC_DrawRLE
	.dw $2343, Debug_RLEText0
	
	.db OPC_DrawRLE
	.dw $2365, Debug_RLEText1
	
	.db OPC_DrawRLE
	.dw $2385, Debug_RLEText2
	
	.db OPC_DrawRLE
	.dw $2393, Debug_RLEText3
	
	.db OPC_Halt
	
Debug_MapEdit_Init:
	LDX #LOW(Debug_StateMachine0)
	LDY #HIGH(Debug_StateMachine0)
	JSR State_Interpreter_Init
	RTS
	
Debug_MapEdit:

	JSR State_Interpreter

	RTS
	