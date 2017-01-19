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
	
	LDX #16
	LDY #48
	LDA #5
	JSR ObjectList_Insert
	STX DEBUG_CURSORID
	LDA #0
	STA DEBUG_CURSORX
	STA DEBUG_CURSORY
	RTS
	
Debug_MapEdit:
	JSR State_Interpreter

	LDA DEBUG_CURSORX
	STA DEBUG_OLDCURX
	LDA DEBUG_CURSORY
	STA DEBUG_OLDCURY
	
.LeftRight
	LDA CTRLPORT_1
	AND #CTRL_LEFT
	BEQ .right
	LDA OLDCTRL_1
	AND #CTRL_LEFT
	BNE .UpDown
	DEC DEBUG_CURSORX
	LDA DEBUG_CURSORX
	CMP #$FF
	BNE .UpDown
	INC DEBUG_CURSORX ;set cursor X to zero
	JMP .UpDown
.right
	LDA CTRLPORT_1
	AND #CTRL_RIGHT
	BEQ .UpDown
	LDA OLDCTRL_1
	AND #CTRL_RIGHT
	BNE .UpDown
	INC DEBUG_CURSORX
	LDA DEBUG_CURSORX
	CMP #14
	BCC .UpDown
	DEC DEBUG_CURSORX ;set cursor X to 13
.UpDown
	LDA CTRLPORT_1
	AND #CTRL_UP
	BEQ .down
	LDA OLDCTRL_1
	AND #CTRL_UP
	BNE .down
	DEC DEBUG_CURSORY
	LDA DEBUG_CURSORY
	CMP #$FF
	BNE .endCtrl
	INC DEBUG_CURSORY ;set cursor X to zero
	JMP .endCtrl
.down
	LDA CTRLPORT_1
	AND #CTRL_DOWN
	BEQ .endCtrl
	LDA OLDCTRL_1
	AND #CTRL_DOWN
	BNE .endCtrl
	INC DEBUG_CURSORY
	LDA DEBUG_CURSORY
	CMP #11
	BCC .endCtrl
	DEC DEBUG_CURSORY ;set cursor X to 10
.endCtrl

	LDA DEBUG_CURSORX
	CMP DEBUG_OLDCURX
	BEQ .updateX
	
.drawXPos
	JSR ConvertToDecimal
	LDA <TEMP_BYTE
	STA DEBUG_DECIMALX
	LDA <TEMP_BYTE + 1
	STA DEBUG_DECIMALX + 1
	LDA <TEMP_BYTE + 2
	STA DEBUG_DECIMALX + 2
	
	LDA #LOW(DEBUG_DECIMALX)
	STA <CALL_ARGS + 2
	LDA #HIGH(DEBUG_DECIMALX)
	STA <CALL_ARGS + 3
	LDY #$23
	STY <CALL_ARGS + 1
	LDX #$8C
	STX <CALL_ARGS
	JSR PPU_DrawNumber ;Draws X position on screen next frame
	
.updateX
	LDX DEBUG_CURSORID
	LDA DEBUG_CURSORX
	CLC
	ADC #1 ;Playfield is 1 metatile away from border
	ASL A
	ASL A
	ASL A
	ASL A ;times 16
	
	STA OBJ_XPOS, x
	
	LDA DEBUG_CURSORY
	CMP DEBUG_OLDCURY
	BEQ .updateY
	
.drawYPos
	JSR ConvertToDecimal
	LDA <TEMP_BYTE
	STA DEBUG_DECIMALY
	LDA <TEMP_BYTE + 1
	STA DEBUG_DECIMALY + 1
	LDA <TEMP_BYTE + 2
	STA DEBUG_DECIMALY + 2
	
	LDA #LOW(DEBUG_DECIMALY)
	STA <CALL_ARGS + 2
	LDA #HIGH(DEBUG_DECIMALY)
	STA <CALL_ARGS + 3
	LDY #$23
	STY <CALL_ARGS + 1
	LDX #$8F
	STX <CALL_ARGS
	JSR PPU_DrawNumber ;Draws X position on screen next frame
	
.updateY
	LDX DEBUG_CURSORID
	LDA DEBUG_CURSORY
	CLC
	ADC #2 ;Playfield is 3 metatiles away from top
	ASL A
	ASL A
	ASL A
	ASL A ;times 16
	
	STA OBJ_YPOS, x
	

	
	RTS
	

	