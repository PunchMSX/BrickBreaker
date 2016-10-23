;Macross.asm
;Macro definitions

;Destroys A registre
 .macro INC16
 .if (\# > 1)
	.fail
 .endif
	INC \1
	BNE .exit\@
	INC \1 + 1
 .exit\@:
	.endm 
	
 .macro NEG
	EOR #$FF
    CLC
	ADC #1
	.endm
	
 .macro PHX
	TXA
	PHA
	.endm
	
 .macro PLX
	PLA
	TAX
	.endm
