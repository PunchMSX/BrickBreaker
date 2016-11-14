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
	
 .macro PHY
	TYA
	PHA
	.endm
	
 .macro PLY
	PLA
	TAY
	.endm

;Copies address from table to zero page variable
;TZP16(<Target, TableAddr)
 .macro TZP16
 .if (\# != 2)
	.fail
 .endif
	ASL A ;2-byte table index
	TAY
	BCS .sec\@ ;Slot 128 to 255 = index Y overflows
	
 .fst\@: ;Entry 0 to 127 chosen
	LDA \2, y
	STA <\1
	LDA \2 + 1, y
	STA <\1 + 1
	JMP .exit\@
 .sec\@: ;Entry 128 to 255 chosen; add $100 to compensate overflow
	LDA \2 + $100, y ;Loads pointer from table
	STA <\1 ;Saves pointer on zero page
	LDA \2 + $100 + 1, y
	STA <\1 + 1
 .exit\@:
	.endm
 
 