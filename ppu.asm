;PPU.asm

PPU_INVALID = 255
PPU_IDLE = 0
PPU_RLE = 1
PPU_SQREPEAT = 2
PPU_METATILE = 3
PPU_NUMBER_8 = 4

PPU_Command_Table:
	.dw _PPU_Idle - 1
	.dw _PPU_RLE - 1
	.dw _PPU_SqRepeat - 1
	.dw _PPU_DrawMetatile - 1
	.dw _PPU_Draw8bitNumber - 1
	
PPU_MAXWRITES = 16 ;Maximum # of bytes to be written during VBlank, conservative guess.

PPU_QueueInterpreter:
	LDA #0
	STA PPU_NUMWRITES ;Reset # of writes for the new vblank
	
	LDA PPU_STEP
	CMP #FALSE
	BEQ .continue
	
.Step:
	JSR PPU_Queue1_Retrieve ;Gets next command
	CMP #PPU_INVALID
	BNE .gotCommand
	
	LDA #PPU_IDLE ;If the queue is empty, next command is IDLE
	STA PPU_COMMAND
	LDA #TRUE
	STA PPU_STEP
	JMP .continue
	
.gotCommand
	STA PPU_COMMAND
	LDA #FALSE
	STA PPU_STEP
	LDA #0
	STA PPU_QR1
.continue
	LDA PPU_COMMAND
	JSI PPU_Command_Table
	
	LDA PPU_STEP
	CMP #STEP_NOW ;Any command can issue an immediate step in the interpreter.
				  ;To check if there were too many writes for the current vblank,
				  ;functions have to store the # of writes in PPU_NUMWRITES.
				  ;If a function can have an arbitrary amount of bytes to write,
				  ;it should check if NUMWRITES = 0, RTS and do it next frame otherwise.
				  ;If the function writes a fixed, small amount of bytes, then
				  ;it should check if NUMWRITES is greater than a fixed limit of writes.
				  ;This allows for many small writes in a single vBlank without spilling over.
	BEQ .Step
	RTS

	
PPU_AllowStep:
	LDA #TRUE
	STA PPU_STEP
	RTS
	
;Inserts a metatile draw command into the queue
;Input: A = metatile #; X, Y = 16x16 grid position
PPU_DrawMetatile:
	JSR PPU_Queue1_Capacity
	CMP #4
	BCC .fail ;Needs at least two slots to work
	
	PHA
	LDA #PPU_METATILE
	JSR PPU_Queue1_Insert
	PLA
	JSR PPU_Queue1_Insert
	LDA <CALL_ARGS 
	JSR PPU_Queue1_Insert
	LDA <CALL_ARGS + 1
	JSR PPU_Queue1_Insert
	
.fail
	RTS
	
;Inserts a metatile draw command into the queue
;Input: X, Y = PPU Address, CALL_ARGS x2 = 3bit Decimal address
PPU_DrawNumber:
	JSR PPU_Queue1_Capacity
	CMP #5
	BCC .fail ;Needs at least two slots to work
	
	LDA #PPU_NUMBER_8
	JSR PPU_Queue1_Insert
	LDA <CALL_ARGS 
	JSR PPU_Queue1_Insert
	LDA <CALL_ARGS + 1
	JSR PPU_Queue1_Insert
	LDA <CALL_ARGS + 2
	JSR PPU_Queue1_Insert
	LDA <CALL_ARGS + 3
	JSR PPU_Queue1_Insert
	
.fail ;No space to store order, abort
	RTS
	
_PPU_Idle:
	JSR PPU_AllowStep
	RTS
	
;Draws a 8 bit number in decimal form
;(3 byte decimal address, PPU Address)
_PPU_Draw8bitNumber:
	LDA PPU_NUMWRITES
	CMP #PPU_MAXWRITES - 8
	BCC .start
	RTS	;Too many writes, wait for next frame.
.start
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR3
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR4
	
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR1
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR2 
	
	LDA $2002
	LDA <PPU_QR4
	STA $2006
	LDA <PPU_QR3
	STA $2006

	LDY #0
	LDX #0
.draw
	LDA [PPU_QR1], y
	CLC
	ADC #$30
	CMP #$30
	BNE .write
	CPX #0
	BNE .write
	LDA #$40
.write
	CMP #$40
	BEQ .writeok
	INX
	
.writeok
	STA $2007
	INY
	CPY #3
	BCC .draw
	
	
.exit
	LDA #8
	CLC
	ADC PPU_NUMWRITES
	STA PPU_NUMWRITES
	LDA #STEP_NOW
	STA PPU_STEP
	
	RTS



;This is made to be scheduled at runtime, not with the state interpreter
;in state.asm since it doesn't support multiple instructions per frame.	
;(Tile #, X, Y) - screen has 16x15 metatiles
_PPU_DrawMetatile:
	LDA PPU_NUMWRITES
	CMP #PPU_MAXWRITES - 3
	BCC .start
	RTS	;Too many writes, wait for next frame.
.start
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR1
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR2
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR3
	LDA #0
	STA <PPU_QR4
.calcAddr ;PPUADDR = (y*16)*4 + x*2
	LDY <PPU_QR3
	LDA MUL16_Table, y; y * 16
	ASL A
	ROL <PPU_QR4
	ASL A
	ROL <PPU_QR4 ;y * 16 * 2 (PPU_QR4 is y's high byte)
	STA <PPU_QR3
	
	LDA <PPU_QR2
	ASL A
	CLC
	ADC <PPU_QR3
	STA <PPU_QR3 ;pos = (y * 16) + x * 2
	LDA #$20
	STA <PPU_QR4
	
.write:
	LDA $2002
	LDA <PPU_QR4
	STA $2006
	LDA <PPU_QR3
	STA $2006
	
	LDA <PPU_QR1
	ASL A
	ASL A ;*4
	TAX

	LDA Metatile_Table, x
	STA $2007
	LDA Metatile_Table + 1 , x
	STA $2007
	
	LDA $2002
	
	LDA <PPU_QR3
	CLC
	ADC #$20
	PHA			;Add $20 to address = jump one line.
	
	LDA <PPU_QR4
	CLC
	ADC #0		;Will add 1 if previous add overflowed.
	STA $2007
	PLA
	STA $2007
	
	LDA Metatile_Table + 2, x
	STA $2007
	LDA Metatile_Table + 3 , x
	STA $2007
	
.exit
	LDA #4
	CLC
	ADC PPU_NUMWRITES
	STA PPU_NUMWRITES
	LDA #STEP_NOW
	STA PPU_STEP
	
	RTS
	

_PPU_SqRepeat:;(Tile #, Width, Height, PPUAddr)
	LDA PPU_NUMWRITES
	BEQ .start
	RTS ;Quit if there were writes before this command, execute next vblank.
.start
	LDA <PPU_QR1
	BNE .cont
.1stSetup
	JSR PPU_Queue1_Retrieve
	STA PPU_BYTE
	JSR PPU_Queue1_Retrieve
	STA PPU_LENGTH
	JSR PPU_Queue1_Retrieve
	STA PPU_LENGTH + 1
	JSR PPU_Queue1_Retrieve
	STA PPUADDR_NAM
	JSR PPU_Queue1_Retrieve
	STA PPUADDR_NAM + 1
	
	LDA #0
	STA <PPU_QR2 ;# of current column NNNN
	LDA #0
	STA <PPU_QR3 ;# of current line YYYYY

	
	INC <PPU_QR1

.cont
	LDA #SQREPEAT_MAXBYTES
	STA <PPU_QR4

	LDX <PPU_QR2
	
.ready
	TXA
	CLC
	ADC PPUADDR_NAM
	STA <PPU_QR5 ;We'll use the base ppu address plus the X reg backup
				 ;(aka how many bytes we wrote last time without updating PPUADDR)
				 ;this isn't added after each run because this confuses
				 ;our method of adding a fixed offset to PPUADDR to go to the
				 ;next line.
	
	LDA $2002
	
	LDA PPUADDR_NAM + 1
	ADC #0		;This increases by 1 if X + PPUADDR(Low) > 255
	STA $2006
	
	LDA <PPU_QR5
	STA $2006
	
	LDA PPU_BYTE
	
.line
	LDY <PPU_QR4
	BEQ .max ;Stop if there are too many writes
	STA $2007
	INX
	DEC <PPU_QR4
	
	CPX PPU_LENGTH
	BCC .line
	
	INC <PPU_QR3
	LDA <PPU_QR3
	CMP PPU_LENGTH + 1
	BCS .end ;All lines drawn
	
	;Change PPU ptr to beggining of next line
	CLC
	LDA #$20
	ADC PPUADDR_NAM
	STA PPUADDR_NAM
	LDA #0
	ADC PPUADDR_NAM + 1
	STA PPUADDR_NAM + 1
	
	LDX #0 ;Resets column counter
	JMP .ready
	
.max
	STX <PPU_QR2 ;Stores progress for later
	;TXA
	;CLC
	;ADC PPUADDR_NAM
	;STA PPUADDR_NAM
	;LDA #0
	;ADC PPUADDR_NAM + 1
	;STA PPUADDR_NAM + 1
	
	RTS
	
.end
	LDA #TRUE
	STA PPU_STEP
	RTS
	
	
	
_PPU_RLE:
	LDA PPU_NUMWRITES
	BEQ .start
	RTS ;Quit if there were writes before this command, execute next vblank.
.start
	LDA <PPU_QR1
	BNE .cont
.1stSetup
	JSR PPU_Queue1_Retrieve
	STA PPUADDR_NAM
	JSR PPU_Queue1_Retrieve
	STA PPUADDR_NAM + 1
	JSR PPU_Queue1_Retrieve
	STA CPUADDR_NAM
	JSR PPU_Queue1_Retrieve
	STA CPUADDR_NAM + 1
	
	INC <PPU_QR1
.cont
	LDA $2002
	
	LDA PPUADDR_NAM + 1
	STA $2006
	LDA PPUADDR_NAM
	STA $2006
	
	LDA #RLE_MAXBYTES
	STA RLE_MAX
	
	LDA CPUADDR_NAM
	TAX
	LDA CPUADDR_NAM + 1
	TAY
	
	JSR unrle_partial_resume
	
	LDA RLE_STAT
	CMP #RLE_READY
	BNE .updateAddress
	
	JSR PPU_AllowStep ;Drawing finished
	JMP .exit
	
.updateAddress:
	LDA PPUADDR_NAM
	CLC
	ADC RLE_MAX
	STA PPUADDR_NAM
	BCC .exit
	INC PPUADDR_NAM + 1

.exit:
	RTS

PPU_InitQueues:
	LDA #PPU_QUEUE1_MAX - 1
	STA <PPU_QP1B
	STA <PPU_QP1F
	LDA #TRUE
	STA PPU_Q1EMPTY
	STA PPU_Q2EMPTY
	STA PPU_STEP
	RTS
	
PPU_Queue1_Capacity:
	LDX #0
	STX PPU_Q1CAP
	LDX <PPU_QP1B
	
	LDA <PPU_QP1F
	CMP <PPU_QP1B
	BEQ .emptyorfull
	BCC .noWrap ;To reach front from back a wraparound is needed if back < front.
	
	LDX <PPU_QP1B
	INX	;Number of free bytes in left part of queue
	STX PPU_Q1CAP
	LDX #PPU_QUEUE1_MAX - 1
	
.noWrap
	TXA
	SEC
	SBC <PPU_QP1F
	CLC
	ADC PPU_Q1CAP
	STA PPU_Q1CAP
	RTS
	
.emptyorfull
	LDA PPU_Q1EMPTY
	CMP #TRUE
	BEQ .empty
.full
	LDA #0
	STA PPU_Q1CAP
	RTS
.empty
	LDA #PPU_QUEUE1_MAX
	STA PPU_Q1CAP
	RTS
	
;A = value to be pushed to soft. queue 1
PPU_Queue1_Insert:
	PHA
	LDY <PPU_QP1B
	CPY <PPU_QP1F ;Is the queue full?
	BNE .noOverflow
	
	LDA PPU_Q1EMPTY
	CMP #TRUE
	BNE .QueueOverflow ;Queue full, overflow.
	
	LDA #FALSE
	STA PPU_Q1EMPTY ;It was empty but not anymore since we're proceeding with the write.
	
.noOverflow
	PLA
	STA PPU_QUEUE1, y
	DECWRAP <PPU_QP1B, #PPU_QUEUE1_MAX - 1
	LDA #0
	RTS
	
.QueueOverflow:
	PLA
	LDA #PPU_INVALID
	RTS
	
;Output: A = value on top of queue
;Queue front pointer is increased with wraparound (item is 'removed')
PPU_Queue1_Retrieve:
	LDY <PPU_QP1F
	CPY <PPU_QP1B
	BNE .noUnderflow
	
	LDA PPU_Q1EMPTY
	CMP #TRUE
	BEQ .QueueUnderflow ;Queue empty = nothing to retrieve.
	
.noUnderflow
	LDA PPU_QUEUE1, y
	PHA
		LDA #0
		STA PPU_QUEUE1, y
	DECWRAP <PPU_QP1F, #PPU_QUEUE1_MAX - 1
	LDY <PPU_QP1F
	CPY <PPU_QP1B
	BNE .Output
	
	LDA #TRUE
	STA PPU_Q1EMPTY ;If we removed the last item in the queue, set to empty
	
.Output
	PLA
	RTS
	
.QueueUnderflow:
	LDA #PPU_INVALID
	RTS
	


	