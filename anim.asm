;Anim.asm
;Animation for object metasprites
	
;X = Object Slot #
;Y = new Animation id #
;Call this to change the animation id without causing bugs.
ChangeAnimation:
	LDA #0
	STA OBJ_ANIMTIMER, x
	STA OBJ_ANIMFRAME, x
	
	TYA
	STA OBJ_ANIMATION, x
	
	RTS
	
;X = Object Slot #
;This loads the correct Metasprite id for the current animation state.
AnimateObject:
FrameQ = TEMP_BYTE
AnimPtr = TEMP_PTR
	LDA OBJ_ANIMATION, x
	CMP #$FF
	BNE .start
	STA OBJ_METASPRITE, x ;Invalid (255) animation #, metasprite = 255
	RTS
.start
	;Loads Animation pointer A from table into AnimPtr
	TZP16 AnimPtr, Animation_Table
	
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
	