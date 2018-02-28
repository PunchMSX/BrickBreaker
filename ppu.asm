;PPU.asm
;Functions without an underline prefix (ie. "PPU_DrawString")
;are meant to be called from outside (using CALL_ARGS to send parameters)
;to make it easy to schedule execution of a command by the PPU State machine.
;They don't necessarily need to be executed by the Script state machine (state.asm).

;Functions with an underline prefix (ie. "_PPU_DrawString")
;are internal to the state machine, they execute the commands themselves
;during VBlank time.

PPU_INVALID = 255
PPU_IDLE = 0
PPU_RLE = 1
PPU_SQREPEAT = 2
PPU_METATILE = 3
PPU_NUMBER_8 = 4
PPU_NUMBER_100 = 5
PPU_DRAWSTRING = 6
PPU_METATILEROW = 7
PPU_NUMBER_100_LARGE = 8
PPU_VIDEO_OFF = 9
PPU_VIDEO_ON = 10
PPU_RLE_BURST = 11

PPU_Command_Table:
	.dw _PPU_Idle - 1
	.dw _PPU_RLE - 1
	.dw _PPU_SqRepeat - 1
	.dw _PPU_DrawMetatile - 1
	.dw _PPU_Draw8bitNumber - 1
	.dw _PPU_DrawBase100Number - 1
	.dw _PPU_DrawString - 1
	.dw _PPU_DrawMetatileRow - 1
	.dw _PPU_DrawLargeBase100Number - 1
	.dw _PPU_VideoOFF - 1
	.dw _PPU_VideoON - 1
	.dw _PPU_RLE_BURST - 1
	
PPU_MAXWRITES = 8 ;Maximum # of bytes to be written during VBlank, conservative guess.
RLE_MAXBYTES = 20
SQREPEAT_MAXBYTES = 16
STRING_MAXBYTES = 16
METATILE_MAXBYTES = 16

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
	
	LDA #PPU_METATILE
	JSR PPU_Queue1_Insert
	LDA <CALL_ARGS 
	JSR PPU_Queue1_Insert
	LDA <CALL_ARGS + 1
	JSR PPU_Queue1_Insert
	LDA <CALL_ARGS + 2
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
;Draws a 0 terminated string.
;(2 byte PPU address, 2 byte String address)	
PPU_DrawString:
	JSR PPU_Queue1_Capacity
	CMP #5
	BCC .fail ;Needs at least two slots to work
	
	LDA #PPU_DRAWSTRING
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
	
;Draws a 8 bit number in decimal form
;(2 byte PPU address, 2 bytes # to be drawn)
PPU_DrawLargeBase100:
	JSR PPU_Queue1_Capacity
	CMP #5
	BCC .fail ;Needs at least two slots to work
	
	LDA #PPU_NUMBER_100_LARGE
	JSR PPU_Queue1_Insert
	LDA <CALL_ARGS 
	JSR PPU_Queue1_Insert
	LDA <CALL_ARGS + 1
	JSR PPU_Queue1_Insert
	
	LDY #0
	LDA [CALL_ARGS + 2], y
	JSR Base100ToDecimal
	
	LDA <TEMP_BYTE
	JSR PPU_Queue1_Insert
	LDA <TEMP_BYTE + 1
	JSR PPU_Queue1_Insert
	
	
.fail ;No space to store order, abort
	RTS
	
_PPU_Idle:
	JSR PPU_AllowStep
	RTS
	
;Orders PPU to turn video off at the end of this frame onwards.
;No parameters on stack
_PPU_VideoOFF:
	LDA #PPU_DISPLAY_OFF
	STA PPU_DISPLAY
	
	JSR PPU_AllowStep
	RTS
	
;Orders PPU to turn video on at the end of this frame onwards.
;No parameters on stack
_PPU_VideoON:
	LDA #PPU_DISPLAY_ON
	STA PPU_DISPLAY
	
	JSR PPU_AllowStep
	RTS
	
;Draws a row of metatiles.
;PPU Address, Metatile address, Row Size (5 bytes total)
_PPU_DrawMetatileRow:
	LDA PPU_NUMWRITES
	BEQ .start
	RTS ;Quit if there were writes before this command, execute next vblank.
.start
	LDA <PPU_QR1
	BNE .cont
.1stSetup
	;PPU Address
	JSR PPU_Queue1_Retrieve
	STA PPUADDR_NAM
	JSR PPU_Queue1_Retrieve
	STA PPUADDR_NAM + 1
	
	;Metatile Address
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR2
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR3 
	
	;Row size
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR1

	;Write progress
	LDA #0
	STA <PPU_QR5
	
	;INC <PPU_QR1
.cont
	LDA #METATILE_MAXBYTES / 4
	STA <PPU_QR4 ;# of metatiles to be written
	
	LDA $2002
	
	LDA <PPU_QR5
	ASL A
	CLC
	ADC PPUADDR_NAM
	PHA
	
	LDA PPUADDR_NAM + 1
	ADC #0
	STA $2006
	PLA
	STA $2006
	
	LDY <PPU_QR5 ;# of metatiles already copied
.loop1 ;writes 1st tile row
	;Load metatile data
	LDA [PPU_QR2], y
	AND #%00011111
	CMP #%00011111
	BEQ .exit
	ASL A
	ASL A
	TAX
	
	LDA Metatile_Table, x
	STA $2007
	LDA Metatile_Table + 1, x
	STA $2007
	
	INY
	CPY <PPU_QR1
	BEQ .loop1end
	
	DEC <PPU_QR4
	BNE .loop1
	
.loop1end
	LDA #METATILE_MAXBYTES / 4
	STA <PPU_QR4 ;# of metatiles to be written
	
	LDA #0
	STA <PPU_QR6
	
	LDA $2002
	
	LDA <PPU_QR5
	ASL A
	CLC
	ADC PPUADDR_NAM
	ROL <PPU_QR6 ;saves carry
	ADC #$20
	PHA
	
	LDA PPUADDR_NAM + 1
	ADC <PPU_QR6
	STA $2006
	
	PLA
	STA $2006
	
	LDY <PPU_QR5 ;# of metatiles already copied
.loop2 ;writes 2nd tile row
	;Load metatile data
	LDA [PPU_QR2], y
	AND #%00011111
	ASL A
	ASL A
	TAX
	
	LDA Metatile_Table + 2, x
	STA $2007
	LDA Metatile_Table + 3, x
	STA $2007
	
	INY
	CPY <PPU_QR1
	BEQ .exit
	DEC <PPU_QR4
	BNE .loop2
	
.pause
	STY <PPU_QR5
	RTS
	
.exit
	JSR PPU_AllowStep
	RTS
	
CHAR_NEWLINE = $26 ;& character denotes newline
CHAR_ENDSTR	= 0

;Draws a 0 terminated string.
;(2 byte PPU address, 2 byte String address)
_PPU_DrawString:
	LDA PPU_NUMWRITES
	BEQ .start
	RTS ;Quit if there were writes before this command, execute next vblank.
.start
	LDA <PPU_QR1
	BNE .cont
.1stSetup
	;PPU Address
	JSR PPU_Queue1_Retrieve
	STA PPUADDR_NAM
	JSR PPU_Queue1_Retrieve
	STA PPUADDR_NAM + 1
	
	;String Address
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR2
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR3 
	
	LDA #0
	STA <PPU_QR5 ;y index
	
	INC <PPU_QR1
	
.cont
	LDA #STRING_MAXBYTES
	STA <PPU_QR4
	
	LDY <PPU_QR5 ;# of bytes already written
	
.ready
	TYA
	CLC
	ADC PPUADDR_NAM
	PHA ;Stores the base address + how many bytes we've wrote last run
	
	LDA $2002
	
	LDA PPUADDR_NAM + 1
	ADC #0
	STA $2006
	
	PLA
	STA $2006
	
.write
	LDA [PPU_QR2], y
	
	BEQ .end
	CMP #CHAR_NEWLINE
	BEQ .newline
	
	STA $2007
	
	DEC <PPU_QR4
	BEQ .pause ;PPU_QR4 = 0 -> too many writes in one vblank
	
	INY
	BNE .write
	INC <PPU_QR3 ;If overflow, increase address by 256
	JMP .write
	
.newline
	;Update PPU base address
	LDA PPUADDR_NAM
	CLC
	ADC #$20
	STA PPUADDR_NAM
	LDA PPUADDR_NAM + 1
	ADC #0
	STA PPUADDR_NAM + 1
	
	;Update CPU base address and reset Y to zero.
	INY
	TYA
	CLC
	ADC <PPU_QR2
	STA <PPU_QR2 ;Updates address to point to
	LDA <PPU_QR3 ;next char in the string.
	ADC #0
	STA <PPU_QR3
	
	
	
	LDY #0
	JMP .ready
	
.pause
	INY
	BNE .pause2
	INC <PPU_QR3
.pause2
	STY <PPU_QR5 ;save # of writes for later
	
	RTS
	
.end
	JSR PPU_AllowStep
	RTS
	
;Draws a 8 bit number in decimal form
;(2 byte PPU address, 2 bytes # to be drawn)
_PPU_DrawLargeBase100Number
	LDA PPU_NUMWRITES
	CMP #PPU_MAXWRITES - 3
	BCC .start
	RTS	;Too many writes, wait for next frame.
.start
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR3
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR4
	
	LDA $2002
	LDA <PPU_QR4
	STA $2006
	LDA <PPU_QR3
	STA $2006
	
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR1
	CLC
	ADC #$60
	STA $2007
	
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR2
	CLC
	ADC #$60
	STA $2007
	
	LDA $2002
	LDA <PPU_QR3
	CLC
	ADC #$20
	PHA
	
	LDA <PPU_QR4
	ADC #0
	STA $2006
	PLA
	STA $2006
	
	LDA <PPU_QR1
	CLC
	ADC #$70
	STA $2007
	
	LDA <PPU_QR2
	CLC
	ADC #$70
	STA $2007
	
	JSR PPU_AllowStep
	RTS

;Draws a 8 bit number in decimal form
;(2 byte PPU address, 2 bytes # to be drawn)
_PPU_DrawBase100Number:
	LDA PPU_NUMWRITES
	CMP #PPU_MAXWRITES - 3
	BCC .start
	RTS	;Too many writes, wait for next frame.
.start
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR3
	JSR PPU_Queue1_Retrieve
	STA <PPU_QR4
	
	;JSR PPU_Queue1_Retrieve
	;STA <PPU_QR1
	;JSR PPU_Queue1_Retrieve
	;STA <PPU_QR2
	
	LDA $2002
	LDA <PPU_QR4
	STA $2006
	LDA <PPU_QR3
	STA $2006
	
	JSR PPU_Queue1_Retrieve
	CLC
	ADC #$30
	STA $2007
	
	JSR PPU_Queue1_Retrieve
	CLC
	ADC #$30
	STA $2007
	
	
	JSR PPU_AllowStep
	RTS
	
;Draws a 8 bit number in decimal form
;(3 byte decimal address, PPU Address)
_PPU_Draw8bitNumber:
	LDA PPU_NUMWRITES
	CMP #PPU_MAXWRITES - 4
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
	CMP #$30	;Check if zero, don't draw if precedes first nonzero.
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
	LDA #3
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
	CLC
	ADC <PPU_QR4
	STA <PPU_QR4
	
.write:
	LDA $2002
	LDA <PPU_QR4
	STA $2006
	LDA <PPU_QR3
	STA $2006
	
	LDA <PPU_QR1
	AND #%00011111
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
	ADC #0		;Will add 1 if previous add overflowed.
	STA $2006
	PLA
	STA $2006
	
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
	
;RUN THIS ONLY IF THE SCREEN IS OFF!
_PPU_RLE_BURST:
	LDA PPU_DISPLAY
	CMP #PPU_DISPLAY_OFF
	BNE .end ;EXIT if display wasn't turned off properly.
	
	LDA PPU_NUMWRITES
	BEQ .start
	RTS ;Quit if there were writes before this command, execute next vblank.
	
.start
	JSR PPU_Queue1_Retrieve
	STA PPUADDR_NAM
	JSR PPU_Queue1_Retrieve
	STA PPUADDR_NAM + 1
	JSR PPU_Queue1_Retrieve
	STA CPUADDR_NAM
	JSR PPU_Queue1_Retrieve
	STA CPUADDR_NAM + 1
	
	LDA $2002
	
	LDA PPUADDR_NAM + 1
	STA $2006
	LDA PPUADDR_NAM
	STA $2006
	
	LDA CPUADDR_NAM
	TAX
	LDA CPUADDR_NAM + 1
	TAY
	
	JSR unrle ;1 frame RLE full write, this will glitch if not in BURST mode.
	
.end
	JSR PPU_AllowStep ;Drawing finished
	RTS
	
_PPU_RLE:
	LDA PPU_NUMWRITES
	BEQ .start
	RTS ;Quit if there were writes before this command, execute next vblank.
.start
	LDA <PPU_QR1
	BNE .cont
.1stSetup
	LDA #RLE_READY
	STA RLE_STAT
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
	
PPU_Queue1_Reset:
	JSR PPU_InitQueues
	LDX #0
	LDA #0
.loop
	STA PPU_QUEUE1, x
	inx
	CPX #PPU_QUEUE1_MAX
	BNE .loop
	
	RTS
	

	