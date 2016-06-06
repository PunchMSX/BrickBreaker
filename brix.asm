;********************************************************
;*** B    R    I    X      B    A    T    T    L    E ***
;********************************************************
;- C o p y r i g h t   2 0 1 6   A l e f f   C o r r e a -
;Project start: 05/06/2016   ||     Version ZERO
	
	.inesmap 0 ;no mapper
	.inesmir 0 ;Vertical
	.ineschr 1 ;8kb Character ROM
	.inesprg 2 ;32kb Program ROM

 .ZP
RESERVED_RLE	.ds  8


 .BSS
PPUADDR_NAM		.ds 2
PPUADDR_ATT		.ds 2

PPUCOUNT_NAM	.ds 2
PPUCOUNT_ATT	.ds 2

 
 .code
 
 .bank 0
 .org $8000
	.include "lib/rle.asm"
	
waitPPU:
	BIT $2002
	BPL waitPPU
	RTS
	
RESET:
	JSR waitPPU
	SEI ;Set Interrupt Flag (off)
	CLD ;Clear Decimal Mode Flag
	
	LDX #%01000000
	STX $4017 ;APU Frame Counter OFF
	
	LDX #255
	TXS ;Reset stack pointer
	
	LDX #0
	STX $2000
	STX $2001 ;PPU set to Burst mode
	
	STX $4010 ;Disable DPCM IRQ interrupt
	
	JSR waitPPU
.clearMem
	LDA #0
	STA <$00, x
	STA $100, x
	STA $300, x
	STA $400, x
	STA $500, x
	STA $600, x
	STA $700, x
	LDA #254
	STA $200, x ;OAM local copy
	
	INX
	BNE .clearMem
	
	JSR waitPPU
.loadPalette:
	LDA $2002
	LDA #$3F
	STA $2006
	LDA #$00
	STA $2006
	
	LDX #00
.loadPaletteLoop:
	LDA Main_Palette, x
	STA $2007
	INX
	CPX #32
	BNE .loadPaletteLoop
	
	LDA #%00011110
	STA $2001 ;enable ppu rendering
	
	LDA #$80
	STA $2000
	
	LDA #0
	STA $2005
	STA $2005 ;set scroll to (0,0)
	
	LDA #(32*30)/32
	STA PPUCOUNT_NAM
	LDA #$20
	STA PPUADDR_NAM
	LDA #$00
	STA PPUADDR_NAM + 1
MainLoop:
	JMP MainLoop
	

 .bank 1
 .org $A000
 
 .bank 2
 .org $C000
 
 .bank 3
 .org $E000

Main_Palette:
	.incbin "art/bg.pal"
	.incbin "art/sprite.pal"
	
BG_Playfield:
	.incbin "art/playfield.rle"
BG_Playfield_att:
	.incbin "art/playfield.atr"
	
NMI:
	LDA PPUCOUNT_NAM
	BEQ .exit
	DEC PPUCOUNT_NAM
	
	LDA #32
	STA RLE_MAX
	
	LDA $2002
	LDA PPUADDR_NAM
	STA $2006
	LDA PPUADDR_NAM + 1
	STA $2006
	LDX #LOW(BG_Playfield)
	LDY #HIGH(BG_Playfield)
	JSR unrle_partial_resume
	LDA PPUADDR_NAM + 1
	CLC
	ADC #32
	STA PPUADDR_NAM + 1
	BCC .exit
	INC PPUADDR_NAM
.exit
	LDA #0
	STA $2005
	STA $2005 ;set scroll to (0,0)
	rti
 
 .org $FFFA
	 .dw NMI
	 .dw RESET
	 .dw 0
 
;CHR
 .bank 4
 .org $0000
	.incbin "art/chardata.chr"
