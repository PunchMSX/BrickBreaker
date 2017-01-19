SpeedX = OBJ_INTSTATE1
SpeedY = OBJ_INTSTATE2	

;Must load slot # into X first
;Address must be subtracted by 1 for indirect JSR
ObjectLogic_Table:
	.dw _OBJ_Player - 1
	.dw _OBJ_Ball - 1
	.dw _OBJ_Intro_Player - 1
	.dw _OBJ_Intro_Parachute - 1
	.dw _OBJ_Intro_Ball - 1
	.dw _OBJ_Debug_Checkered - 1
	
ObjectInit_Table:
	.dw _OBJ_Player_Init - 1
	.dw _OBJ_Ball_Init - 1
	.dw _OBJ_Intro_Player_Init - 1
	.dw _OBJ_Intro_Parachute_Init - 1
	.dw _OBJ_Intro_Ball_Init - 1
	.dw _OBJ_Debug_Checkered_Init - 1
	
_OBJ_Debug_Checkered_Init:
	LDA #11
	STA OBJ_METASPRITE, x
	RTS
	
_OBJ_Debug_Checkered:
	RTS


_OBJ_Intro_Parachute_Init:
	LDA #10
	STA OBJ_METASPRITE, x
	RTS
	
_OBJ_Intro_Player_Init:
	PHX ;Saves itself for later
	
	LDA #0
	STA OBJ_YPOS, x
	STA SpeedX, x
	LDA #1
	STA SpeedY, x
	LDY #0
	JSR ChangeAnimation
	
.randX
	JSR RNG_Next
	CMP #256-32
	BCS .randX
	CMP #33
	BCC .randX
	STA OBJ_XPOS, x
	
	CLC
	ADC #6
	TAX
	LDY #$F8
	LDA #3 ;Umbrella with handle object
	JSR ObjectList_Insert ;Creates an umbrella object that will be controlled by this object
	CMP #$FF
	BEQ .fail
	
	PLA ;Recovers our X index into A
	STA OBJ_INTSTATE1, x ;Stores our ID into our created object so it can remain attached to us
	RTS
	
.fail ;Not enough space to have the umbrella spawned
	PLX
	JSR ObjectList_Remove ;Despawns itself.
	RTS
	
_OBJ_Intro_Player:
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
	JSR AnimTimer_Tick
	JSR AnimateObject
	
.selfdestruct
	LDA OBJ_YPOS, x
	CMP #$F8
	BCC .end
	;Sprite got into the no-display area between $F8~$FF, remove itself.
	JSR ObjectList_Remove
	DEC INTRO_CHARQ
.end
	RTS
	
_OBJ_Intro_Parachute:
	LDA OBJ_INTSTATE1, x ;Loads parent id
	TAY
	LDA OBJ_LIST, y
	CMP #$FF
	BEQ .destroy ;Check to see if parent is still alive
	
	LDA OBJ_XPOS, y
	CLC
	ADC #6
	STA OBJ_XPOS, x
	
	LDA OBJ_YPOS, y
	SEC
	SBC #8
	STA OBJ_YPOS, x ;Updates position to be "attached" to parent object
	
.collision
	LDA OBJ_COLLISION, x
	CMP #$FF
	BNE .end ;Was hit already, skip
	
	LDY #4; Object = Intro_Ball
	JSR Overlap_Test_Group
	LDA OBJ_COLLISION, x
	CMP #$FF
	BEQ .end ;Wasn't hit, skip
	
	LDA OBJ_INTSTATE1, x ;Loads parent id
	TAY
	LDA #3
	STA SpeedY, y ;Umbrella broken, parent falls faster.
	
	LDA #9
	STA OBJ_METASPRITE, x ;Change metasprite to broken umbrella
	
	PHX
	TYA
	TAX
	LDY #1
	JSR ChangeAnimation ;Changes parent animation to Chara_Hit
	PLX
	
.end
	RTS
	
.destroy: ;If parent doesn't exist, destroy self
	JSR ObjectList_Remove
	RTS
	
	
_OBJ_Player_Init:
	RTS
_OBJ_Player:
.l
	LDA CTRLPORT_1
	AND #%00000010
	BEQ .r
	DEC OBJ_XPOS, x
.r
	LDA CTRLPORT_1
	AND #%00000001
	BEQ .u
	INC OBJ_XPOS, x
.u
	LDA CTRLPORT_1
	AND #%00000100
	BEQ .d
	DEC OBJ_YPOS, x
.d
	LDA CTRLPORT_1
	AND #%00001000
	BEQ .coldet
	INC OBJ_YPOS, x
	
.coldet
	JSR Overlap_Test_All
	LDA OBJ_COLLISION, x
	CMP #$FF
	BEQ .animate
	
	LDY #1
	JSR ChangeAnimation
.animate
	JSR AnimTimer_Tick
	JSR AnimateObject
	
	RTS
	
_OBJ_Ball_Init:
.gen
	JSR RNG_Next
	AND #%00000110
	SEC
	SBC #4
	STA SpeedX, x
	
	JSR RNG_Next
	SEC
	SBC #4
	AND #%00000110
	STA SpeedY, x
	
	BNE .end
	LDA SpeedX, x
	BEQ .gen ;If both speed values are 0, retry.
.end
	RTS

_OBJ_Ball:
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
	
.coldet
	LDA #255
	STA OBJ_COLLISION, x
	RTS
	
_OBJ_Intro_Ball_Init:
.gen
	JSR RNG_Next
	AND #%00000110
	SEC
	SBC #4
	STA SpeedX, x
	
	JSR RNG_Next
	SEC
	SBC #4
	AND #%00000110
	STA SpeedY, x
	
	BNE .end
	LDA SpeedX, x
	BEQ .gen ;If both speed values are 0, retry.
.end
	RTS

_OBJ_Intro_Ball:
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
	
.coldet
	LDA #255
	STA OBJ_COLLISION, x
	RTS
	
;Sets all object entries as $FF, run this once
ObjectList_Init:
	LDA #$FF
	LDX #OBJ_MAX
.loop:
	DEX
	STA OBJ_LIST, x
	STA OBJ_XPOS, x
	STA OBJ_YPOS, x
	STA OBJ_ANIMATION, x
	STA OBJ_ANIMTIMER, x
	STA OBJ_ANIMFRAME, x
	STA OBJ_METASPRITE, x
	STA OBJ_COLLISION, x
	BNE .loop
 
	RTS
	
;X = object to be removed
ObjectList_Remove:
	LDA #$FF
	STA OBJ_LIST, x
	STA OBJ_XPOS, x
	STA OBJ_YPOS, x
	STA OBJ_ANIMATION, x
	STA OBJ_ANIMTIMER, x
	STA OBJ_ANIMFRAME, x
	STA OBJ_METASPRITE, x
	STA OBJ_COLLISION, x
	LDA #0
	STA OBJ_INTSTATE1, x
	STA OBJ_INTSTATE2, x
	STA OBJ_INTSTATE3, x
	RTS
	
; A = object ID
; X, Y = Position coords
ObjectList_Insert:
	PHA	;Save object ID for later
	TXA
	PHA	;Save X coord for later
	
	LDX #0
.findSlot
	LDA OBJ_LIST, x
	CMP #$FF
	BEQ .found
	INX
	CPX #OBJ_MAX
	BNE .findSlot
	JMP .notFound ;No free slot for insertion, exit
	
.found
	TYA
	STA OBJ_YPOS, x ;Store Y coord to free register
	PLA
	STA OBJ_XPOS, x ;X coord
	PLA
	STA OBJ_LIST, x ;Object ID
	
	;A is loaded with the object's type (ID)
	JSI ObjectInit_Table ;We're trusting in the init routine to preserve X here.
	
.resetVars
	LDA #0
	STA OBJ_ANIMTIMER, x ;Clears animation timer
	STA OBJ_ANIMFRAME, x ;Sets current animation frame to 0.
	;STA OBJ_METASPRITE, x
	TXA
	RTS ;End!
	
.notFound
	PLA
	PLA
	LDX #$FF
	RTS
	
ObjectList_UpdateAll:
LogicPtr = TEMP_PTR
	LDX #0
.loop
	LDA OBJ_LIST, x
	CMP #$FF
	BNE .found
	INX
	CPX #OBJ_MAX
	BNE .loop
	JMP .out
.found
	TAY 
	PHX ;X is SACRED and will be preserved in Object routines but we'll save it just in case
	TYA ;PHX macro junks A. We just save it for the indirect jump.
	;this macro performs an indirect jump to an address in a table, indexed by A.
	JSI ObjectLogic_Table ;Reminder, Object routines NEED slot # at X so they can know who they are.
	PLX
	INX
	CPX #OBJ_MAX
	BNE .loop
	JMP .out
.out
	RTS
	
;Updates OAM Copy with the metasprites. 
;No metasprite can have 0 bytes! (Use metasprite id # 255 to skip object)
ObjectList_OAMUpload:

Metasprite_Ptr = TEMP_PTR
OAM_Offset = TEMP_BYTE
OAM_Limit = TEMP_BYTE + 1
Metasprite_X = TEMP_BYTE + 2
Metasprite_Y = TEMP_BYTE + 3

	LDA #OAM_SPROFFSET
	STA OAM_Offset ;Pointer to where OAM writes start

	LDX #$FF
.forEachObject
	INX
	CPX #OBJ_MAX
	BEQ .forend
	LDA OBJ_LIST, x
	CMP #$FF
	BNE .found
	JMP .forEachObject
.forend

	LDX OAM_Offset
	BEQ .end ;No unused sprites in OAM
	LDA #$FE
.updateUnused
	STA OAM_COPY, x
	INX
	BNE .updateUnused
.end
	RTS
	
.found
	PHX ;Preserves slot # just in case
	LDA OBJ_METASPRITE, x
	CMP #$FF
	BEQ .foundEnd
	
	;Copies address from table to pointer
	TZP16 Metasprite_Ptr, Metasprite_Table

	
.copyData:
	LDY #0
	LDA OAM_Offset
	CLC
	ADC [Metasprite_Ptr], y ;Retrieves number of bytes used by Metasprite
	BCC .hasSpace ;No overflow, has enough space in OAM to copy sprites
	BEQ .hasSpace ;Overflows but last byte is $00 - 1 = $FF, so copying is OK.
	JMP .TooManySprites ;Not enough space, OAM overflow. Stop subroutine early
	
.hasSpace:
	STA OAM_Limit ;Will copy data until OAM_Offset == OAM_Limit
	
	;Hold the metasprite's X,Y coords in a temp variable to free reg. X
	;(making reads to OBJ_XYPOS uneeded we can discard the slot # -- preserved on stack)
	LDA OBJ_XPOS, x
	STA Metasprite_X
	LDA OBJ_YPOS, x
	STA Metasprite_Y
	
	LDX OAM_Offset
	INY
.copyDataLoop:
	;Y Position
	LDA [Metasprite_Ptr], y
	CLC
	ADC Metasprite_Y
	STA OAM_COPY, x
	DEC OAM_COPY, x ;PPU draws sprite off by +1 px in Y.
	INY
	INX
	;Sprite ID
	LDA [Metasprite_Ptr], y
	STA OAM_COPY, x
	INY
	INX
	;Attribute Byte
	LDA [Metasprite_Ptr], y
	STA OAM_COPY, x
	INY
	INX
	;X Position
	LDA [Metasprite_Ptr], y
	CLC
	ADC Metasprite_X
	STA OAM_COPY, x
	INY
	INX
	
	CPX OAM_Limit
	BNE .copyDataLoop
	
.foundEnd
	LDA OAM_Limit
	STA OAM_Offset ;Updates offset to avoid overwriting.
	PLX ;Guarantees slot # in X is unchanged, continue loop.
	JMP .forEachObject
	
;Error: not enough space in OAM for all metasprites.
.TooManySprites
	PLX ;Don't forget to pop X from stack to avoid problems in the RTS.
	RTS ;Stops loop since there's no room for the remaining objects.
		