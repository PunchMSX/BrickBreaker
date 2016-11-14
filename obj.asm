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
	JSR AnimTimer_Tick
	LDY #0 ;Animation index #. (0 = _AN_Chara_Idle_Up)
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
	BCS .indexOverflow ;Index * 2 is be greater than 255
	
.indexOk ;Entry 0 to 127 chosen
	;Store pointer to animation data in Zero Page
	LDA Animation_Table, y
	STA <AnimPtr
	LDA Animation_Table + 1, y
	STA <AnimPtr + 1
	JMP .loadFrameQ
	
.indexOverflow ;Entry 128 to 255 chosen; add $100 to compensate overflow
	LDA Animation_Table + $100, y
	STA <AnimPtr
	LDA Animation_Table + $100 + 1, y
	STA <AnimPtr + 1
	
.loadFrameQ
	LDY #0
	;Load animation data from pointer
	LDA [AnimPtr], y
	STA <FrameQ ;# of metasprite frames

	INC16 AnimPtr
;Decides if current frame is maintained or there's a transition to next one
;OBJ_ANIMFRAME *MUST* start at 0 and only this subroutine can manipulate it,
;   because frame # wraparound ( > FrameQ) is only checked when transitioning!
	LDY OBJ_ANIMFRAME, x
.getCurFrame
	LDA [AnimPtr], y
	CMP OBJ_ANIMTIMER, x ;Is Timer limit >= Timer?
	BCC .transition ;Timer exceeds or is equal to limit, set next frame.
	BEQ .transition
	JMP .updateMetasprite ;Timer doesn't exceed limit, keep current frame #.
	
.transition:
	INY
	CPY <FrameQ
	BCC .transition2 ;No overflow
	LDY #0 ;Overflow = wraparound to zero
.transition2
	TYA
	STA OBJ_ANIMFRAME, x ;Store updated frame #.
	
	LDA #0
	STA OBJ_ANIMTIMER, x ;Clear timer.

.updateMetasprite:
	TYA ;Y = frame #.
	CLC
	ADC <FrameQ
	TAY
	LDA [AnimPtr], y ;Metasprite id for the current anim. frame
	STA OBJ_METASPRITE, x ;Error in timer or animation table entry
	RTS
	
;X = Object Slot #
;Timer stops at 255 (no overflow)
AnimTimer_Tick:
	INC OBJ_ANIMTIMER, x
	BEQ .overflow
	RTS
.overflow
	DEC OBJ_ANIMTIMER, x
	RTS
