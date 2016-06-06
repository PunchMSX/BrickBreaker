;RLE decompressor by Shiru (NESASM version)
;uses 4 bytes in zero page
;decompress data from an address in X/Y to PPU_DATA

RLE_LOW		equ $00
RLE_HIGH	equ RLE_LOW+1
RLE_TAG		equ RLE_HIGH+1
RLE_BYTE	equ RLE_TAG+1

;0 - ready
;1 - partial sequential write
;2 - clean pause
RLE_STAT	equ RLE_BYTE+1
RLE_COUNT	equ RLE_STAT+1
RLE_STORE	equ RLE_COUNT+1
RLE_MAX		equ RLE_STORE+1

PPU_DATA = $2007
RLE_MAXWRITES = 6

RLE_READY = 0
RLE_UNCLEAN = 1
RLE_CLEAN = 2


unrle_partial_resume:
	LDA RLE_STAT
	BEQ unrle_partial
	
	LDA RLE_MAX
	STA RLE_COUNT
	LDY #0
	
	LDA RLE_STAT
	CMP #RLE_UNCLEAN
	BNE unrle_resume_2
	
	LDX RLE_STORE
	LDA RLE_BYTE
	JMP unrle_resume_1
;*********************************************
unrle_partial:
	LDA RLE_MAX
	STA RLE_COUNT
	
	stx RLE_LOW
	sty RLE_HIGH ;Pointer to compressed data
	ldy #0
	jsr rle_byte
	sta RLE_TAG ;First byte is control tag
	
unrle_resume_2:
.readByte ; 1
	jsr rle_byte
	DEC RLE_COUNT ;;Decrease write count by one.
	cmp RLE_TAG   ;Is next byte = control tag?
	beq .repeatByte
    sta PPU_DATA
	sta RLE_BYTE  ;Store read byte in RAM
	
	LDA RLE_COUNT
	BEQ unrle_cleanHalt
	JMP .readByte ;Read next byte
	
.repeatByte ; 2
	jsr rle_byte ;Read byte next to control tag
	cmp #0
	beq unrle_endOfFile ;If repeat length = 0, eof
	
	tax
	lda RLE_BYTE  ;Last non-control byte
	
	INC RLE_COUNT ;Compensation for subtraction done at (1)
unrle_resume_1:
.repeatByteLoop ; 3
	sta PPU_DATA
	DEC RLE_COUNT
	BEQ unrle_uncleanHalt ;Quits loop earlier if remaining writes equals zero
	dex
	bne .repeatByteLoop
	beq unrle_resume_2
	
unrle_endOfFile ;4
	LDA #RLE_READY
	STA RLE_STAT
	rts
	
unrle_cleanHalt ;Exits without the need of saving any register values
	LDA #RLE_CLEAN
	STA RLE_STAT
	RTS
	
unrle_uncleanHalt ;Exits in a way that makes resuming the repeat loop possible
	DEX	;Decreases loop counter to compensate for early exit
	BEQ unrle_cleanHalt ;if X equals zero after decrease, loop does not need to resume
	STX RLE_STORE
	LDA #RLE_UNCLEAN
	STA RLE_STAT
	RTS


unrle
	stx RLE_LOW
	sty RLE_HIGH
	ldy #0
	jsr rle_byte
	sta RLE_TAG
.1
	jsr rle_byte
	cmp RLE_TAG
	beq .2
	sta PPU_DATA
	sta RLE_BYTE
	bne .1
.2
	jsr rle_byte
	cmp #0
	beq .4
	tax
	lda RLE_BYTE
.3
	sta PPU_DATA
	dex
	bne .3
	beq .1
.4
	rts

rle_byte
	lda [RLE_LOW],y
	inc RLE_LOW
	bne .1
	inc RLE_HIGH
.1
	rts