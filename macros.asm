;Macross.asm
;Macro definitions

 .macro INC16
 .if (\# > 1)
	.fail
 .endif
	INC \1
	BNE .exit\@
	INC \1 + 1
 .exit\@:
	.endm 
	
 .macro DEC16
 .if (\# > 1)
	.fail
 .endif
	DEC \1
	LDA \1
	CMP #$FF
	BNE .exit\@
	DEC \1 + 1
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
 
;Does RTS trick to perform an indirect JSR to table address
;JSI(TableAddr, A(Index))
 .macro JSI
  .if (\# != 1)
	.fail
  .endif
  
	JMP .exit\@
	
;****** Indirect JSR Loader ******
 .Indirect_JSR_l\@:
	;LDA Index
	LDA \1 + 1, y ;High byte popped last, pushed first.
	PHA
	LDA \1, y
	PHA ;Pushes Subroutine address into stack
	RTS ;Jumps to target subroutine, returns to "JSR" callee
 .Indirect_JSR_h\@: ;Index is > 128, compensate overflow when multiplying by 2.
	;LDA Index
	LDA \1 + $100 + 1, y
	PHA
	LDA \1 + $100, y
	PHA 
	RTS 
;**********************************	
	
 .exit\@:
	ASL A
	TAY
	BCS .sec\@
	JSR .Indirect_JSR_l\@
	JMP .end\@
 .sec\@:
	JSR .Indirect_JSR_h\@
 .end\@:
	.endm
 
;Ticks timer up to 255, doesn't overflow
;JSI(TimerAddr)
 .macro TCK
	INC \1
	BEQ .overflow\@
	JMP .end\@
 .overflow\@:
	DEC \1
 .end\@:
	.endm
	
;Decreases value by 1, wraps around if result is less than 0.
;DECWRAP(Target, WrapTo)
 .macro DECWRAP
	LDA \1
	BEQ .wrap\@
	DEC \1
	JMP .end\@
 .wrap\@:
	LDA \2
	STA \1
 .end\@:
	.endm
	
 .macro INCWRAP
	INC \1
	LDA \1
	CMP \2
	BCS .wrap\@
	JMP .end\@
 .wrap\@:
	LDA #0
	STA \1
 .end\@:
	.endm
	
 .macro ADD16
	CLC
	ADC \1
	STA \1
	LDA #0
	ADC \1 + 1
	STA \1 + 1
	.endm
	