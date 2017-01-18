;PPU.asm

PPU_INVALID = 255
PPU_IDLE = 0
PPU_RLE = 1
PPU_SQREPEAT = 2

PPU_Command_Table:
	.dw _PPU_Idle - 1
	.dw _PPU_RLE - 1
	.dw _PPU_SqRepeat - 1

PPU_QueueInterpreter:
	LDA PPU_STEP
	CMP #TRUE
	BNE .continue
	
.Step:
	JSR PPU_Queue2_Retrieve ;Gets next command
	CMP #PPU_INVALID
	BNE .gotCommand
	LDA #PPU_IDLE ;If the queue is empty, next command is IDLE
.gotCommand
	STA PPU_COMMAND
	LDA #FALSE
	STA PPU_STEP
	LDA #0
	STA PPU_QR1
.continue
	LDA PPU_COMMAND
	JSI PPU_Command_Table
	
	RTS

	
PPU_AllowStep:
	LDA #TRUE
	STA PPU_STEP
	RTS
	
_PPU_Idle:
	JSR PPU_AllowStep
	RTS
	
	
PPU_WriteLine:
	LDA $2002
	
	LDA PPUADDR_NAM + 1
	STA $2006
	LDA PPUADDR_NAM
	STA $2006
	
.loop
	STA $2007
	DEX
	BNE .loop
	
	RTS

_PPU_SqRepeat:;(Tile #, Width, Height, PPUAddr)
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
	LDA #PPU_QUEUE2_MAX - 1
	STA <PPU_QP2B
	STA <PPU_QP2F
	LDA #TRUE
	STA PPU_Q1EMPTY
	STA PPU_Q2EMPTY
	STA PPU_STEP
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
	RTS
	
.QueueOverflow:
	PLA
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
	
;Output: A = 1st value on queue
;Queue front pointer is increased with wraparound (item is 'removed')
PPU_Queue2_Retrieve:
	LDY <PPU_QP2F
	CPY <PPU_QP2B
	BNE .noUnderflow
	
	LDA PPU_Q2EMPTY
	CMP #TRUE
	BEQ .QueueUnderflow ;Queue empty = nothing to retrieve.
	
.noUnderflow
	LDA PPU_QUEUE2, y
	PHA
	DECWRAP <PPU_QP2F, #PPU_QUEUE2_MAX - 1
	LDY <PPU_QP2F
	CPY <PPU_QP2B
	BNE .Output
	
	LDA #TRUE
	STA PPU_Q2EMPTY ;If we removed the last item in the queue, set to empty
	
.Output
	PLA
	RTS
	
.QueueUnderflow:
	LDA #PPU_INVALID
	RTS
	
;A = value to be pushed to soft. queue 1
PPU_Queue2_Insert:
	PHA
	LDY <PPU_QP2B
	CPY <PPU_QP2F ;Is the queue full?
	BNE .noOverflow
	
	LDA PPU_Q2EMPTY
	CMP #TRUE
	BNE .QueueOverflow ;Queue full, overflow.
	
	LDA #FALSE
	STA PPU_Q2EMPTY ;It was empty but not anymore since we're proceeding with the write.
	
.noOverflow
	PLA
	STA PPU_QUEUE2, y
	DECWRAP <PPU_QP2B, #PPU_QUEUE2_MAX - 1
	RTS
	
.QueueOverflow:
	PLA
	RTS
	
;A = value to be written
;X = # of sequential writes.
PPU_WriteByteSeq:
.loop
	STA $2007
	DEX
	BNE .loop
	
	RTS
	