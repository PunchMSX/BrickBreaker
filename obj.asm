OBJ_SPEEDX = OBJ_INTSTATE1
OBJ_SPEEDY = OBJ_INTSTATE2

BALL_SPEED = OBJ_INTSTATE1	
BALL_ANGLE = OBJ_INTSTATE2
BALL_FINEX = OBJ_INTSTATE3
BALL_FINEY = OBJ_INTSTATE4

BALL_SOLID = OBJ_INTSTATE7
BALL_SELFDESTRUCT = OBJ_INTSTATE8

PLAYER_UMBRELLAID = OBJ_INTSTATE5
UMB_PARENTID = OBJ_INTSTATE1

LAUNCHER_PARENTID = OBJ_INTSTATE3
LAUNCHER_ARROWID = OBJ_INTSTATE4
LAUNCHER_ANGLE = OBJ_INTSTATE5


OBJ_DEBUG_CHECKERED = 0
OBJ_DEBUG_CHECKERED_SMALL = 1

OBJ_INTRO_PLAYER = 2
OBJ_INTRO_PARACHUTE = 3
OBJ_INTRO_BALL = 4

OBJ_BALL = 5
OBJ_STATIC = 6

OBJ_PLAYER = 7
OBJ_UMBRELLA = 8

OBJ_BALL_LAUNCHER = 9



;Must load slot # into X first
;Address must be subtracted by 1 for indirect JSR
ObjectLogic_Table:
	.dw _OBJ_Debug_Checkered - 1
	.dw _OBJ_Debug_Checkered_Small - 1
	
	.dw _OBJ_Intro_Player - 1
	.dw _OBJ_Intro_Parachute - 1
	.dw _OBJ_Ball - 1
	
	.dw _OBJ_Ball - 1
	.dw _OBJ_Static - 1
	
	.dw _OBJ_Player - 1
	.dw _OBJ_Umbrella - 1
	
	.dw _OBJ_Ball_Launcher - 1
	
ObjectInit_Table:
	.dw _OBJ_Debug_Checkered_Init - 1
	.dw _OBJ_Debug_Checkered_Small_Init - 1
	
	.dw _OBJ_Intro_Player_Init - 1
	.dw _OBJ_Intro_Parachute_Init - 1
	.dw _OBJ_Ball_Init - 1
	
	.dw _OBJ_Ball_Init - 1
	.dw _OBJ_Static - 1
	
	.dw _OBJ_Player_Init - 1
	.dw _OBJ_Umbrella_Init - 1
	
	.dw _OBJ_Ball_Launcher_Init - 1
	
_OBJ_Ball_Launcher_Init:
	LDA #15
	STA OBJ_METASPRITE, x
		
	LDA #0
	STA LAUNCHER_ANGLE, x
	
	PHX
	LDA #OBJ_STATIC
	JSR ObjectList_Insert
	STA <TEMP_BYTE
	PLX
	LDA <TEMP_BYTE
	STA LAUNCHER_ARROWID, x
	
	CMP #$FF
	BEQ .selfdestruct
	RTS
	
.selfdestruct
	PLX
	JSR ObjectList_Remove
	RTS

_OBJ_Ball_Launcher:
	LDA LAUNCHER_PARENTID, x
	CMP #$FF
	BNE .sync
	JMP .selfdestruct
.sync
	TAY
	LDA OBJ_XPOS, y
	STA OBJ_XPOS, x

	LDA OBJ_YPOS, y
	SEC
	SBC #$4
	STA OBJ_YPOS, x
	
	LDA LAUNCHER_ARROWID, x
	CMP #$FF
	BNE .arrowsync
	JMP .selfdestruct
	
.arrowsync
	TAY
	LDA OBJ_XPOS, x
	STA OBJ_XPOS, y

	LDA OBJ_YPOS, x
	STA OBJ_YPOS, y
	
.releaseb
	LDA CTRLPORT_1
	AND #CTRL_A
	BNE .holdA
	LDA OLDCTRL_1
	AND #CTRL_A
	BEQ .hidearrow
	
	PHX
	
	LDA LAUNCHER_ARROWID, x
	TAX
	JSR ObjectList_Remove
	
	PLX
	
	LDA LAUNCHER_ANGLE, x
	PHA
	
	LDA #OBJ_BALL
	STA OBJ_LIST, x
	
	JSR _OBJ_Ball_Init
	LDA #2
	STA BALL_SPEED, x
	PLA
	BNE .rightangle
.leftangle
	LDA #ANGLE_225
	STA BALL_ANGLE, x
	RTS
.rightangle
	LDA #ANGLE_315
	STA BALL_ANGLE, x
	RTS
;***************

.holdA
	LDA CTRLPORT_1
	AND #CTRL_LEFT
	BEQ .rightAngle
	LDA #0
	STA LAUNCHER_ANGLE, x
	
.rightAngle
	LDA CTRLPORT_1
	AND #CTRL_RIGHT
	BEQ .updateArrow
	LDA #1
	STA LAUNCHER_ANGLE, x
	
.updateArrow
	LDA LAUNCHER_ARROWID, x
	TAY
	LDA #13
	CLC
	ADC LAUNCHER_ANGLE, x
	STA OBJ_METASPRITE, y
	
.exit
	RTS
	
.hidearrow
	LDA LAUNCHER_ARROWID, x
	TAY
	LDA #15
	STA OBJ_METASPRITE, y
	RTS
	
.selfdestruct
	JSR ObjectList_Remove
	RTS
	
	
;*************************************************************************
_OBJ_Player_Init:
	LDY #0
	JSR ChangeAnimation
.spawnUmbrella
	PHX

	LDA OBJ_XPOS, x
	CLC
	ADC #6
	PHA
	
	
	LDA OBJ_YPOS, x
	SEC
	SBC #8
	TAY
	PLX
	LDA #OBJ_UMBRELLA
	
	JSR ObjectList_Insert
	CMP #$FF
	BEQ .fail
	
	STA <TEMP_BYTE ;Umbreall id
	PLA
	STA <TEMP_BYTE + 1;Player id
	TAX
	LDA <TEMP_BYTE
	STA PLAYER_UMBRELLAID, x
	TAX
	LDA <TEMP_BYTE + 1
	STA UMB_PARENTID, x
	
	TAX ;We must return from the init routine with the X intact.
	RTS
	
.fail
	PLX
	JSR ObjectList_Remove
	RTS
	
_OBJ_Umbrella_Init:
	LDA #1
	STA OBJ_METASPRITE, x
	
	RTS
	
_OBJ_Player:
	JSR AnimTimer_Tick
	JSR AnimateObject
	
.checkCtrl
	LDA CTRLPORT_1
	AND #CTRL_LEFT
	BEQ .checkCtrlRight
	LDA CTRLPORT_1
	AND #CTRL_B
	BNE .boostLeft
	LDA OBJ_XPOS, x
	SEC
	SBC #2
	STA OBJ_XPOS, x
	CMP #16
	BCS .endCtrlCheck
	LDA #16
	STA OBJ_XPOS, x
	JMP .endCtrlCheck
	
.boostLeft
	LDA OBJ_XPOS, x
	SEC
	SBC #4
	STA OBJ_XPOS, x
	CMP #16
	BCS .endCtrlCheck
	LDA #16
	STA OBJ_XPOS, x
	JMP .endCtrlCheck
	
.checkCtrlRight
	LDA CTRLPORT_1
	AND #CTRL_RIGHT
	BEQ .endCtrlCheck
	LDA CTRLPORT_1
	AND #CTRL_B
	BNE .boostRight
	LDA OBJ_XPOS, x
	CLC
	ADC #2
	STA OBJ_XPOS, x
	CMP #256-24
	BCC .endCtrlCheck
	LDA #256-24
	STA OBJ_XPOS, x
	
.boostRight:
	LDA OBJ_XPOS, x
	CLC
	ADC #4
	STA OBJ_XPOS, x
	CMP #256-24
	BCC .endCtrlCheck
	LDA #256-24
	STA OBJ_XPOS, x
	
.endCtrlCheck
	RTS
	

	
;11 pixels each side = 22
Umbrella_HeightMap_Table:
	.db 4, 3, 2, 1, 1, 0, 0, 0, 0, 0, 0
	.db 0, 0, 0, 0, 0, 0, 1, 1, 2, 3, 4
	
Umbrella_Angle_Table:
	.db A_210, A_210, A_210, A_210, A_225, A_225, A_225, A_225, A_240, A_240, A_240
	.db A_300, A_300, A_300, A_315, A_315, A_315, A_315, A_330, A_330, A_330, A_330
	
Umbrella_Collision:
	LDY #255
	TYA
	STA OBJ_COLLISION, x
.loop:
	INY
	CPY #OBJ_MAX
	BNE .eval
	JMP .end
.eval
	LDA OBJ_LIST, y
	CMP #OBJ_BALL
	BEQ .found
	JMP .loop
.found
	JSR Overlap_Test_1Box
	CMP #OVERLAP_FALSE
	BEQ .loop
	
	TYA
	STA OBJ_COLLISION, x
	PHA
	
	;Proceed to collision only if ball is going downwards.
	LDA BALL_ANGLE, y
	CMP #ANGLE_210
	BCC .checkHeight
	
	;Going upwards (aka already reflected), ignore.
	PLA
	TAY
	JMP .loop
	
.checkHeight
	;Check ball height
	
	LDA OBJ_YPOS, y
	STA <TEMP_BYTE
	
	LDA OBJ_XPOS, y
	STA <TEMP_BYTE + 1
	
	LDA OBJ_METASPRITE, y
	ASL A
	ASL A
	TAY
	
	;Get lowest Y point in ball
	LDA MS_Collision_Table + 3, y
	CLC
	ADC <TEMP_BYTE
	STA <TEMP_BYTE
	
	;gets horizontal corners
	LDA MS_Collision_Table + 1, y
	CLC
	ADC <TEMP_BYTE + 1
	STA <TEMP_BYTE + 2
	
	LDA MS_Collision_Table + 0, y
	CLC
	ADC <TEMP_BYTE + 1
	STA <TEMP_BYTE + 1
	
	;Get how much (by pixels) the ball is inside the umbrella
	LDA <TEMP_BYTE ;Y position
	SEC
	SBC OBJ_YPOS, x
	STA <TEMP_BYTE ;Y Overlap
	
	;get the difference in X between sprites
	PLA
	TAY
	LDA OBJ_XPOS, y
	SEC
	SBC OBJ_XPOS, x
	
	;Decides whether to use the left or right corner pos. depending on the object's position
	BPL .rightside
	LDA <TEMP_BYTE + 2 ;x2
	SEC
	SBC OBJ_XPOS, x
	JMP .getindex
.rightside
	LDA <TEMP_BYTE + 1 ;x1
	SEC
	SBC OBJ_XPOS, x
	
.getindex
	CLC
	ADC #11 ;table begins in pixel position -11
	BPL .checkHeightTable ;if minus, outside collision box
	JMP .loop
	
.checkHeightTable
	STY <TEMP_BYTE + 3 ;ball obj id
	TAY ;Y = ball x pos irt umbrella
	LDA Umbrella_HeightMap_Table, y
	CMP <TEMP_BYTE ;ball Y pos
	BCS .returnloop ;smaller height, return to loop and investigate next
	
	;Load reflection angle from LUT
	LDA Umbrella_Angle_Table, y
	LDY <TEMP_BYTE + 3 ;ball id
	;Store "reflection" in the ball's angle intstate
	STA BALL_ANGLE, y
	
	RTS ;there might be more balls colliding but that's checked next frame only.
	
.returnloop
	LDY <TEMP_BYTE + 3
	JMP .loop
.end
	RTS
	
_OBJ_Umbrella:
	LDY UMB_PARENTID, x
	LDA OBJ_LIST, y
	CMP #$FF
	BNE .sync
	JSR ObjectList_Remove
	RTS
	
.sync
	;Sync with parent metasprite
	LDA OBJ_XPOS, y
	CLC
	ADC #6
	STA OBJ_XPOS, x
	
	LDA OBJ_YPOS, y
	SEC
	SBC #8
	STA OBJ_YPOS, x
	
.collisionDetection
	LDY #OBJ_BALL
	JSR Umbrella_Collision
	
.endcollision
	RTS
	
;This is made to be positioned and metasprite'd by any external subroutine
;	aka this can be any metasprite.	
_OBJ_Static:
	RTS
	
_OBJ_Ball_Init:
	LDA #0
	STA OBJ_METASPRITE, x
	LDA #TRUE
	STA BALL_SOLID, x ;Ball always solid for NESDev compo mini game.
	
.genAngle
	JSR RNG_Next
	AND #%00011111
	CMP #12
	BCS .genAngle
	STA BALL_ANGLE, x
.genSpeed
	JSR RNG_Next
	AND #%00000111
	BEQ .genSpeed
	CMP #7
	BCS .genSpeed
	STA BALL_SPEED, x
	JMP .end

.end
	RTS
	
Ball_MoveX:
	LDA ANGLE_SPEEDX
	BNE .nonzero
	;If zero, we don't have the sign information since
	;it's only stored in the non fraction part of the number.
	LDA BALL_ANGLE, x
	CMP #ANGLE_120
	BCC .pos
	CMP #ANGLE_300
	BCS .pos
	JMP .neg
.nonzero
	BMI .neg
.pos
	LDA BALL_FINEX, x
	CLC
	ADC ANGLE_SPEEDX + 1 ;Add fine (decimal) X
	STA BALL_FINEX, x
	
	;Do not clear carry so overflow carries over
	LDA OBJ_XPOS, x
	ADC ANGLE_SPEEDX
	STA OBJ_XPOS, x
	
	RTS
.neg
	LDA BALL_FINEX, x

	SEC
	SBC ANGLE_SPEEDX + 1
	STA BALL_FINEX, x
	PHP ;save carry
	
	LDA ANGLE_SPEEDX
	NEG
	STA <TEMP_BYTE
	PLP
	LDA OBJ_XPOS, x
	SBC <TEMP_BYTE
	STA OBJ_XPOS, x
	
	RTS
	
Ball_MoveY:
	LDA ANGLE_SPEEDY
	BNE .nonzero
	;If zero, we don't have the sign information since
	;it's only stored in the non fraction part of the number.
	LDA BALL_ANGLE, x
	CMP #ANGLE_210
	BCC .pos
	JMP .neg
.nonzero
	BMI .neg
.pos
	LDA BALL_FINEY, x
	CLC
	ADC ANGLE_SPEEDY + 1 ;Add fine (decimal) X
	STA BALL_FINEY, x
	
	;Do not clear carry so overflow carries over
	LDA OBJ_YPOS, x
	ADC ANGLE_SPEEDY
	STA OBJ_YPOS, x
	
	RTS
.neg
	LDA BALL_FINEY, x

	SEC
	SBC ANGLE_SPEEDY + 1
	STA BALL_FINEY, x
	PHP ;save carry
	
	LDA ANGLE_SPEEDY
	NEG
	STA <TEMP_BYTE
	PLP
	LDA OBJ_YPOS, x
	SBC <TEMP_BYTE
	STA OBJ_YPOS, x
	
	RTS
	
;Destroys Y.
;Reads from the vector angle table the appropriate amount of pixels to displace
;according to the angle and speed of the object.
Ball_GetAngleMovement:
	LDA BALL_ANGLE, x
	CMP #ANGLE_120
	BCC .q1
	CMP #ANGLE_210
	BCC .q2
	CMP #ANGLE_300
	BCC .q3
	JMP .q4
	
.q1 ;30, 45, 60 degrees
	ASL A
	ASL A
	ASL A
	ASL A ;Multiply by 16 to get offset to x/y values of the angle.
	
	CLC
	ADC BALL_SPEED, x ;index for reading X displacement value for the current speed and angle.
	SEC
	SBC #1
	
	TAY
	LDA Vector_Angle_Table, y
	STA ANGLE_SPEEDX     ;Coarse X
	LDA Vector_Angle_Table + 8, y
	STA ANGLE_SPEEDY ;Coarse Y
	
	LDA Vector_Fraction_Table, y
	STA ANGLE_SPEEDX + 1    ; Fine X
	LDA Vector_Fraction_Table + 8, y
	STA ANGLE_SPEEDY + 1; Fine Y
	
	
	RTS
	
.q2 ;120, 135, 150 degrees... invert table read order and negate X (length * -cos(Angle))
	SEC
	SBC #5 ;120, 135 and 150 have similar values to 60, 45, 30
	NEG    ;
	
	ASL A
	ASL A
	ASL A
	ASL A ;Multiply by 16 to get offset to x/y values of the angle.
	
	CLC
	ADC BALL_SPEED, x ;index for reading X displacement value for the current speed and angle.
	SEC
	SBC #1
	
	TAY
	LDA Vector_Angle_Table, y
	NEG
	STA ANGLE_SPEEDX     ;Coarse X
	LDA Vector_Angle_Table + 8, y
	STA ANGLE_SPEEDY ;Coarse Y
	
	LDA Vector_Fraction_Table, y
	STA ANGLE_SPEEDX + 1    ; Fine X
	LDA Vector_Fraction_Table + 8, y
	STA ANGLE_SPEEDY + 1; Fine Y
	
	RTS


.q3; 210, 225, 240 degrees... normal table order but negated X, Y
	SEC
	SBC #ANGLE_210
	
	ASL A
	ASL A
	ASL A
	ASL A ;Multiply by 16 to get offset to x/y values of the angle.
	
	CLC
	ADC BALL_SPEED, x ;index for reading X displacement value for the current speed and angle.
	SEC
	SBC #1
	
	TAY
	LDA Vector_Angle_Table, y
	NEG
	STA ANGLE_SPEEDX     ;Coarse X
	LDA Vector_Angle_Table + 8, y
	NEG
	STA ANGLE_SPEEDY ;Coarse Y
	
	LDA Vector_Fraction_Table, y
	STA ANGLE_SPEEDX + 1    ; Fine X
	LDA Vector_Fraction_Table + 8, y
	STA ANGLE_SPEEDY + 1; Fine Y
	
	RTS

.q4 ;300, 315, 300 degrees... flip table order, negate Y only
	SEC
	SBC #ANGLE_330 ;120, 135 and 150 have similar values to 60, 45, 30
	NEG    ;
	
	ASL A
	ASL A
	ASL A
	ASL A ;Multiply by 16 to get offset to x/y values of the angle.
	
	CLC
	ADC BALL_SPEED, x ;index for reading X displacement value for the current speed and angle.
	SEC
	SBC #1
	
	TAY
	LDA Vector_Angle_Table, y
	STA ANGLE_SPEEDX     ;Coarse X
	LDA Vector_Angle_Table + 8, y
	NEG
	STA ANGLE_SPEEDY ;Coarse Y
	
	LDA Vector_Fraction_Table, y
	STA ANGLE_SPEEDX + 1    ; Fine X
	LDA Vector_Fraction_Table + 8, y
	STA ANGLE_SPEEDY + 1; Fine Y
	
	RTS

	
_OBJ_Ball:
	LDA #FALSE
	STA BALL_SELFDESTRUCT
	
	LDA OBJ_XPOS, x
	STA OBJ_OLDX
	LDA OBJ_YPOS, x
	STA OBJ_OLDY ;Backup original X,Y position
	
	JSR Ball_GetAngleMovement

.LeftRight
	LDA #FALSE
	STA BALL_REFLECTED ;This will be a true/false switch so we don't reflect twice.
	LDA #$FF
	STA COLDAMAGE_PREVTILE
	
	;Determine the current direction in the X axis
	LDA BALL_ANGLE, x
	CMP #ANGLE_120
	BCC .right
	CMP #ANGLE_300
	BCS .right
	JMP .left
	
.right
	LDA #1
	STA OVERLAP_OFFSET
	JMP .lrcheck
.left
	LDA #0
	STA OVERLAP_OFFSET
	
.lrcheck
		JSR Ball_MoveX
		
		;Checks the top/bottom right points for collisions
		JSR Overlap_Background_Small
		
		LDA #0
		CLC
		ADC OVERLAP_OFFSET
		STA <CALL_ARGS ;Top Right/Left tile
		
		TAY
		LDA COLLISION_OFFSET, y
		TAY
		LDA COLLISION_MAP, y
		AND #%00011111
		JSR Ball_CollisionX ;Resolve collision between the obj and top right tile
		
		LDA #2
		CLC
		ADC OVERLAP_OFFSET
		STA <CALL_ARGS ;Bottom Right/Left tile
		
		TAY
		LDA COLLISION_OFFSET, y
		TAY
		LDA COLLISION_MAP, y
		AND #%00011111
		JSR Ball_CollisionX ;Resolve collision between the obj and bottom right tile
		
.UpDown
	;Determine the current direction in the X axis
	LDA #FALSE
	STA BALL_REFLECTED ;This will be a true/false switch so we don't reflect twice.
	LDA #$FF
	STA COLDAMAGE_PREVTILE
	
	;Determine the current direction in the X axis
	LDA BALL_ANGLE, x
	CMP #ANGLE_210
	BCS .up
.down	
	LDA #2
	STA OVERLAP_OFFSET
	JMP .udcheck
.up
	LDA #0
	STA OVERLAP_OFFSET
	
.udcheck
		JSR Ball_MoveY
		
		;Checks the top/bottom right points for collisions
		JSR Overlap_Background_Small
		
		LDA #0
		CLC
		ADC OVERLAP_OFFSET
		STA <CALL_ARGS ;Top/bottom left tile
		
		TAY
		LDA COLLISION_OFFSET, y
		TAY
		LDA COLLISION_MAP, y
		AND #%00011111
		JSR Ball_CollisionY ;Resolve collision between the obj and top right tile
		
		LDA #1
		CLC
		ADC OVERLAP_OFFSET
		STA <CALL_ARGS ;Bottom Right/Left tile
		
		TAY
		LDA COLLISION_OFFSET, y
		TAY
		LDA COLLISION_MAP, y
		AND #%00011111
		JSR Ball_CollisionY ;Resolve collision between the obj and bottom right tile
		
.selfDestruct
	LDA BALL_SELFDESTRUCT
	CMP #TRUE
	BNE .exit
	JSR ObjectList_Remove
	INC MATCH_P1BALLBUF
.exit
	RTS
	
;This TRASHES all <Call_Args and <TEMP_BYTE so be careful!
;A = collision map offset of the tile
;Subtracts 1 from higher three bytes in collision map (durability value)
;if durability = 0 then the tile is destroyed (replaced by another one with lower index #)
DamageTile:
	TAY
	
	CMP COLDAMAGE_PREVTILE ;Do this check to avoid damaging a tile twice per axis movement
	BNE .start
	RTS
.start	
	STA COLDAMAGE_PREVTILE

	LDA COLLISION_MAP, y
	AND #%11100000
	BEQ .destroy
	LDA COLLISION_MAP, y
	SEC
	SBC #%00100000
	STA COLLISION_MAP, y
	
	RTS ;No destruction, only damage, exit without writing
	
	
.destroy ;Downgrade tile to lower id # and reload durability
	LDA COLLISION_MAP, y
	SEC
	SBC #1
	AND #%00011111 ;The next tile that shows damage will have a lower index #.
	
	STY <TEMP_BYTE
	TAY
	ORA Metatile_Durability, y ;Apply default durability to our new "damaged" metatile.
	LDY <TEMP_BYTE
	STA COLLISION_MAP, y
	
.increasegoalcounter
	LDA COLLISION_MAP, y
	AND #%00011111
	CMP #TILE_RUBBLE
	BNE .schedule
	INC MATCH_P1SCOREBUF
	INC MATCH_BROKENBRIX
	
.schedule ;Send it to the queue to be drawn next vBlank.
	LDA COLLISION_MAP, y
	AND #%00011111
	STA <CALL_ARGS ;Metatile ID
	
	TYA
	AND #%00001111
	STA <CALL_ARGS + 1 ;X position (index % 16)
	
	TYA
	LSR A
	LSR A
	LSR A
	LSR A
	STA <CALL_ARGS + 2 ;Y position (index / 16)
	
	PHX
	;This is UNSAFE for X and will make the game hard crash since it overwrites the object id
	;in X with garbage, so that's why we back up that register.
	JSR PPU_DrawMetatile
	PLX

.end
	RTS
	

;Evaluates collision against a tile that the object overlaps.
;A = type of tile overlapped, X = obj id	
Ball_CollisionX:
	BNE .start
	RTS ;If zero, it's an empty tile, skip
	
.start
.border ;reflect only
	CMP #TILE_BORDER
	BNE .solid
	JSR Ball_ReflectX
	
	;Play sound effect.
	PHX
	LDA #1
	LDX #FT_SFX_CH0
	JSR FamiToneSfxPlay
	PLX
	
	RTS
;**************************************************	
.solid
	LDY BALL_SOLID, x
	CPY #TRUE
	BNE .nonSolid

	;Brick = Reflect and damage tile
	CMP #TILE_BRICK
	BEQ .brick
	CMP #TILE_DAMAGEDBRICK
	BEQ .brick
	JMP .nonSolid
.brick
	JSR Ball_ReflectX
	
	LDY <CALL_ARGS
	LDA COLLISION_OFFSET, y
	
	;Reminder that this destroys CALL_ARGS so we can't access the right byte in COL_OFFSET after this.
	JSR DamageTile
	
	;Play sound effect.
	PHX
	LDA #1
	LDX #FT_SFX_CH0
	JSR FamiToneSfxPlay
	PLX
	RTS
	
;***************************************************
;***************************************************
.nonSolid: ;Tiles below can be hit even if ball is non-solid
	
.solidifier	;pass through and become solid
	CMP #TILE_SOLIDIFIER
	BNE .target
	LDA #TRUE
	STA BALL_SOLID, x
	RTS
	
.target ;destroy self and increase score if all 4 corners are in
	LDY COLLISION_OFFSET
	LDA COLLISION_MAP, y
	AND #%00011111
	CMP #TILE_TARGET
	BNE .placeholder
	LDY COLLISION_OFFSET + 1
	LDA COLLISION_MAP, y
	AND #%00011111
	CMP #TILE_TARGET
	BNE .placeholder
	LDY COLLISION_OFFSET + 2
	LDA COLLISION_MAP, y
	AND #%00011111
	CMP #TILE_TARGET
	BNE .placeholder
	LDY COLLISION_OFFSET + 3
	LDA COLLISION_MAP, y
	AND #%00011111
	CMP #TILE_TARGET
	BNE .placeholder
	
	LDA #TRUE
	STA BALL_SELFDESTRUCT

	RTS
	
.placeholder ;next tile type to be created.
	RTS
	
;Evaluates collision against a tile that the object overlaps.
;A = type of tile overlapped, X = obj id	
;<Call_Args = COLLISION_OFFSET index (1-4)
Ball_CollisionY:
	BNE .start
	RTS ;If zero, it's an empty tile, skip

.start
.border ;reflect only
	CMP #TILE_BORDER
	BNE .solid
	JSR Ball_ReflectY
	
	;Play sound effect.
	PHX
	LDA #1
	LDX #FT_SFX_CH0
	JSR FamiToneSfxPlay
	PLX
	
	RTS
;**************************************************	
.solid
	LDY BALL_SOLID, x
	CPY #TRUE
	BNE .nonSolid
	
	;Brick = Reflect and damage tile
	CMP #TILE_BRICK
	BEQ .brick
	CMP #TILE_DAMAGEDBRICK
	BEQ .brick
	JMP .nonSolid
.brick
	JSR Ball_ReflectY
	
	LDY <CALL_ARGS
	LDA COLLISION_OFFSET, y

	;Reminder that this destroys CALL_ARGS so we can't access the right byte in COL_OFFSET after this.
	JSR DamageTile
	
	;Play sound effect.
	PHX
	LDA #1
	LDX #FT_SFX_CH0
	JSR FamiToneSfxPlay
	PLX
	
	RTS
	
;***************************************************
;***************************************************
.nonSolid: ;Tiles below can be hit even if ball is non-solid
.solidifier	;pass through and become solid
	CMP #TILE_SOLIDIFIER
	BNE .target
	LDA #TRUE
	STA BALL_SOLID, x
	RTS
	
.target ;destroy self and increase score if all 4 corners are in
	LDY COLLISION_OFFSET
	LDA COLLISION_MAP, y
	AND #%00011111
	CMP #TILE_TARGET
	BNE .placeholder
	LDY COLLISION_OFFSET + 1
	LDA COLLISION_MAP, y
	AND #%00011111
	CMP #TILE_TARGET
	BNE .placeholder
	LDY COLLISION_OFFSET + 2
	LDA COLLISION_MAP, y
	AND #%00011111
	CMP #TILE_TARGET
	BNE .placeholder
	LDY COLLISION_OFFSET + 3
	LDA COLLISION_MAP, y
	AND #%00011111
	CMP #TILE_TARGET
	BNE .placeholder
	
	LDA #TRUE
	STA BALL_SELFDESTRUCT
	
	RTS

	
.placeholder ;next tile type to be created.
	RTS
	
Ball_ReflectX:
;Reflection works as following:
; 1- find out how much is the object embedded in the solid tile (collision_overlap)
; 2- move the object back so it touches the solid tile (add/sub the position with the value from 1)
; 3- invert the speed in the axis being evaluated
; (reflecting in the same run requires more collision detection checks, dangerous infinite loops may occur?)

	;Check if overlap values are nonzero.
	;If nonzero, this already ran once in this frame.
	LDA BALL_REFLECTED
	BEQ .start
	RTS

.start
	LDA OBJ_XPOS, x
	CMP OBJ_OLDX
	BCS .lr
.rl
	CLC
	ADC COLLISION_OVERLAP
	STA OBJ_XPOS, x		;Restore previous position if collision happened
	
	LDA #0
	STA BALL_FINEY, x
	
	;Reflect
	LDA BALL_ANGLE, x
	JSR Angle_ReflectX
	STA BALL_ANGLE, x

	JMP .exit
.lr
	;Touch Wall
	SEC
	SBC COLLISION_OVERLAP + 1
	STA OBJ_XPOS, x
	DEC OBJ_XPOS, x
	
	;Reflect
	LDA BALL_ANGLE, x
	JSR Angle_ReflectX
	STA BALL_ANGLE, x
		
.exit
	LDA #1
	STA BALL_REFLECTED
	RTS
	
Ball_ReflectY:
;Reflection works as following:
; 1- find out how much is the object embedded in the solid tile (collision_overlap)
; 2- move the object back so it touches the solid tile (add/sub the position with the value from 1)
; 3- invert the speed in the axis being evaluated
; (reflecting in the same run requires more collision detection checks, dangerous infinite loops may occur?)

	;Check if overlap values are nonzero.
	;If nonzero, this already ran once in this frame.
	LDA BALL_REFLECTED
	BEQ .start
	RTS

.start
	LDA OBJ_YPOS, x
	CMP OBJ_OLDY
	BCS .ud
	CLC
	ADC COLLISION_OVERLAP + 2
	STA OBJ_YPOS, x		;Restore previous position if collision happened
	
	LDA #0
	STA BALL_FINEY, x
	
	;Reflect
	LDA BALL_ANGLE, x
	JSR Angle_ReflectY
	STA BALL_ANGLE, x
	
	JMP .exit
.ud
	SEC
	SBC COLLISION_OVERLAP + 3
	STA OBJ_YPOS, x
	DEC OBJ_YPOS, x
	
	;Reflect
	LDA BALL_ANGLE, x
	JSR Angle_ReflectY
	STA BALL_ANGLE, x
		
.exit
	LDA #1
	STA BALL_REFLECTED
	RTS
	
	
_OBJ_Debug_Checkered_Init:
	LDA #11
	STA OBJ_METASPRITE, x
	RTS
	
_OBJ_Debug_Checkered_Small_Init:
	LDA #12
	STA OBJ_METASPRITE, x
	RTS
	
_OBJ_Debug_Checkered:
	RTS
	
_OBJ_Debug_Checkered_Small:
	LDA OBJ_XPOS, x
	STA OBJ_INTSTATE1, x
	LDA OBJ_YPOS, x
	STA OBJ_INTSTATE2, x ;Backup original X,Y position
	LDA #0
	STA OBJ_INTSTATE3, x ;Direction

.LeftRight
	LDA CTRLPORT_1
	AND #CTRL_LEFT
	BEQ .right
	LDA OBJ_XPOS, x
	SEC
	SBC #1
	STA OBJ_XPOS, x
	JMP .HorizColdetLeft
	
.right
	LDA CTRLPORT_1
	AND #CTRL_RIGHT
	BEQ .UpDown

	LDA OBJ_XPOS, x
	CLC
	ADC #1
	STA OBJ_XPOS, x
	JMP .HorizColdetRight
	
.HorizColdetLeft
	JSR Overlap_Background_Small

	LDY COLLISION_OFFSET + 0
	LDA COLLISION_MAP, y
	BNE .col
	LDY COLLISION_OFFSET + 2
	LDA COLLISION_MAP, y
	BNE .col
	JMP .UpDown
	
.HorizColdetRight
	JSR Overlap_Background_Small

	LDY COLLISION_OFFSET + 1
	LDA COLLISION_MAP, y
	BNE .col
	LDY COLLISION_OFFSET + 3
	LDA COLLISION_MAP, y
	BNE .col
	JMP .UpDown

.col
	LDA OBJ_INTSTATE1, x ;Revert to previous position if collision is true
	STA OBJ_XPOS, x
	RTS
	
.UpDown
	
	RTS


_OBJ_Intro_Parachute_Init:
	LDA #10
	STA OBJ_METASPRITE, x
	RTS
	
_OBJ_Intro_Player_Init:
	PHX ;Saves itself for later
	
	LDA #0
	STA OBJ_YPOS, x
	STA OBJ_SPEEDX, x
	LDA #1
	STA OBJ_SPEEDY, x
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
	LDA OBJ_SPEEDX, x
	CLC
	ADC OBJ_XPOS, x
	STA OBJ_XPOS, x
.movev
	LDA OBJ_SPEEDY, x
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
	STA OBJ_SPEEDY, y ;Umbrella broken, parent falls faster.
	
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
	JSI ObjectInit_Table ;We're trusting the init routine to preserve X here.
	
.resetVars
	LDA #0
	STA OBJ_ANIMTIMER, x ;Clears animation timer
	STA OBJ_ANIMFRAME, x ;Sets current animation frame to 0.
	;STA OBJ_INTSTATE1, x
	;STA OBJ_INTSTATE2, x
	;STA OBJ_INTSTATE3, x
	;STA OBJ_INTSTATE4, x
	;STA OBJ_INTSTATE5, x
	;STA OBJ_INTSTATE6, x
	;STA OBJ_INTSTATE7, x
	;STA OBJ_INTSTATE8, x
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
		