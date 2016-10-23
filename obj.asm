;Obj.asm
;Object logic

;Must load slot # into X first
;Address must be subtracted by 1 for indirect JSR
ObjectLogic_Table:
	.dw _OBJ_Player - 1
	.dw _OBJ_Ball - 1
	
_OBJ_Player:
.l
	LDA CTRLPORT_1
	AND #%00000010
	BEQ .r
	DEC OBJ_XPOS, x
.r
	LDA CTRLPORT_1
	AND #%00000001
	BEQ .animate
	INC OBJ_XPOS, x
	
.animate
	LDY #0
	JSR AnimateObject
	
	RTS
	
_OBJ_Ball:
SpeedX = OBJ_INTSTATE1
SpeedY = OBJ_INTSTATE2
	LDA SpeedX, x
	BNE .aa
	LDA #2
	STA SpeedX, x
.aa
	LDA SpeedY, x
	BNE .moveh
	LDA #2
	STA SpeedY, x
	
.moveh
	LDA SpeedX, x
	CLC
	ADC OBJ_XPOS, x
	STA OBJ_XPOS, x
.movev
	LDA SpeedY, x
	CLC
	ADC OBJ_YPOS, x
	STA OBJ_YPOS, x
	
.animate
	LDA #0
	STA OBJ_METASPRITE, x
	
	RTS
	
;X = Object Slot #
;Y = Animation id #
;This loads the correct Metasprite id for the current animation state.
AnimateObject:
FrameQ = TEMP_BYTE
AnimPtr = TEMP_PTR
	
	TYA
	ASL A
	TAY ;Each pointer in table has two bytes
	
	;Store pointer to animation data in Zero Page
	LDA Animation_Table, y
	STA <AnimPtr
	LDA Animation_Table + 1, y
	STA <AnimPtr + 1
	
	LDY #0
	;Load animation data from pointer
	LDA [AnimPtr], y
	STA <FrameQ ;# of metasprite frames

	INC16 AnimPtr
.getCurFrame
	LDA [AnimPtr], y
	CMP OBJ_ANIMTIMER, x
	BCS .got
	INY
	CPY <FrameQ
	BNE .getCurFrame
	LDA #$FF
	STA OBJ_METASPRITE, x ;Error in timer or animation table entry
	RTS
.got
	TYA
	CLC
	ADC <FrameQ
	TAY
	LDA [AnimPtr], y ;Metasprite id for the current anim. frame
	STA OBJ_METASPRITE, x ;Error in timer or animation table entry
	RTS
	