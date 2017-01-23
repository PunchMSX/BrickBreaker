;instructions.asm
 
Instruction0_StateMachine:
	.db OPC_RAMWrite
	.dw INSTRUCT_SYNC
	.db 0

	.db OPC_DrawSquare, $40, 32, 30
	.dw $2000
	
	.db OPC_Delay, 60
	
	.db OPC_DrawRLE
	.dw $2000, bg_Playfield
	
	.db OPC_Delay, 60
	
	.db OPC_RAMWrite
	.dw INSTRUCT_SYNC
	.db INSTRUCT_AIM1
	
	.db OPC_DrawString
	.dw $220A, Match_Instructions1
	
	.db OPC_Delay, 150
	
	.db OPC_DrawString
	.dw $22AE, Match_Instructions2
	
	.db OPC_RAMWrite
	.dw INSTRUCT_SYNC
	.db INSTRUCT_AIM2
	
	.db OPC_Delay, 250
	
	.db OPC_DrawString
	.dw $22A7, Match_Instructions3
	
	.db OPC_RAMWrite
	.dw INSTRUCT_SYNC
	.db INSTRUCT_AIM3
	
	.db OPC_Delay, 150
	
	.db OPC_DrawSquare, $20, 28, 1
	.dw $22A2
	
	.db OPC_DrawString
	.dw $22A7, Match_Instructions4
	
	.db OPC_Delay, 150
	
	.db OPC_DrawSquare, $20, 28, 1
	.dw $22A2
	
	.db OPC_RAMWrite
	.dw INSTRUCT_SYNC
	.db INSTRUCT_FIRE
	
	.db OPC_Delay, 15
	
	.db OPC_RAMWrite
	.dw INSTRUCT_SYNC
	.db INSTRUCT_KILLBALL
	
	.db OPC_Delay, 135
	
	.db OPC_DrawString
	.dw $22C5, Match_Instructions5
	
	.db OPC_Delay, 150
	
	.db OPC_RAMWrite
	.dw INSTRUCT_SYNC
	.db INSTRUCT_END
	
	.db OPC_Halt
	
State_Instructions_Init:
	LDX #LOW(Instruction0_StateMachine)
	LDY #HIGH(Instruction0_StateMachine)
	JSR State_Interpreter_Init
	JSR CollisionMap_DefaultBorder
	RTS
	
State_Instructions:
	JSR State_Interpreter
	LDA INSTRUCT_SYNC
	CMP #INSTRUCT_AIM1
	BEQ .INSERT1
	CMP #INSTRUCT_AIM2
	BEQ .INSERT2
	CMP #INSTRUCT_AIM3
	BEQ .INSERT3
	CMP #INSTRUCT_FIRE
	BEQ .INSERT4
	CMP #INSTRUCT_KILLBALL
	BNE .exit
	JMP .INSERT5
.exit
	RTS
	
.INSERT1
	LDX #$70
	LDY #$C8
	LDA #OBJ_STATIC
	JSR ObjectList_Insert
	LDA #3
	STA OBJ_METASPRITE, x
	
	
	LDX #$78
	LDY #$BC
	LDA #OBJ_STATIC
	JSR ObjectList_Insert
	LDA #15
	STA OBJ_METASPRITE, x
	STX INSTRUCT_BALL
	
	LDX #$78
	LDY #$C0
	LDA #OBJ_STATIC
	JSR ObjectList_Insert
	LDA #10
	STA OBJ_METASPRITE, x
	
	LDA #0
	STA INSTRUCT_SYNC
	
	RTS
	
.INSERT2
	LDX #$78
	LDY #$BC
	LDA #OBJ_STATIC
	JSR ObjectList_Insert
	LDA #13
	STA OBJ_METASPRITE, x
	STX INSTRUCT_ARROWS
	
	LDA #0
	STA INSTRUCT_SYNC
	RTS
	
	
.INSERT3
	LDX INSTRUCT_ARROWS
	LDA #16
	STA OBJ_METASPRITE, x
	
	LDA #0
	STA INSTRUCT_SYNC
	RTS
	
.INSERT4
	LDX INSTRUCT_BALL
	JSR ObjectList_Remove
	LDX INSTRUCT_ARROWS
	JSR ObjectList_Remove
	
	LDX #$78
	LDY #$BC
	LDA #OBJ_BALL
	JSR ObjectList_Insert
	STX INSTRUCT_BALL
	LDA #-1
	STA SpeedX, x
	LDA #-1
	STA SpeedY, x
	
	LDX #96
	LDY #$C0
	LDA #OBJ_STATIC
	JSR ObjectList_Insert
	LDA #14
	STA OBJ_METASPRITE, x
	
	LDA #0
	STA INSTRUCT_SYNC
	
	RTS
	
.INSERT5
	LDX INSTRUCT_BALL
	JSR ObjectList_Remove
	
	LDA #0
	STA INSTRUCT_SYNC
	
	RTS
	
	