
OBJ1_PTR = TEMP_PTR
OBJ2_PTR = TEMP_PTR + 2
Obj1Id = TEMP_BYTE + 3
Obj2Id = TEMP_BYTE + 4
Obj1Box = TEMP_BYTE + 5
Obj2Box = TEMP_BYTE + 6
TempPos = TEMP_BYTE + 7
ColGroup = TEMP_BYTE + 8

OVERLAP_TRUE = 1
OVERLAP_FALSE = 0

Overlap_Test_All:
	LDY #255
	TYA
	STA OBJ_COLLISION, x
.loop:
	INY
	CPY #OBJ_MAX
	BEQ .end
	LDA OBJ_LIST, y
	CMP #$FF
	BNE .found
	JMP .loop
.found
	JSR Overlap_Test_1Box
	CMP #OVERLAP_FALSE
	BEQ .loop
	
	TYA
	STA OBJ_COLLISION, x
.end
	RTS
	
;X - object to test
;Y - group ID to test against
Overlap_Test_Group:
	STY <ColGroup
	LDY #255
	TYA
	STA OBJ_COLLISION, x
.loop:
	INY
	CPY #OBJ_MAX
	BEQ .end
	LDA OBJ_LIST, y
	CMP #$FF
	BNE .found
	JMP .loop
.found
	CMP <ColGroup
	BNE .loop
	JSR Overlap_Test_1Box
	CMP #OVERLAP_FALSE
	BEQ .loop
	
	TYA
	STA OBJ_COLLISION, x
.end
	RTS

;Same as overlap test but only the first box of each object is tested.
;Preserves X, Y. Outputs A.
;Make sure objects' metasprites are VALID!
Overlap_Test_1Box:
	TXA
	STA <Obj1Id
	TYA
	STA <Obj2Id
	
	CMP <Obj1Id
	BNE .cont
	JMP .noOverlap ;If both objects are the same, report no collision.
	
.cont
	;Gets pointers to collision data
	LDA OBJ_METASPRITE, x
	ASL A
	ASL A
	STA <Obj1Box
	
	LDA OBJ_METASPRITE, y
	ASL A
	ASL A
	STA <Obj2Box
	
	
;Must pass all 4 tests to be overlapping.
.Test1: ;Obj2.y2 > Obj1.y1
	CLC
	LDY <Obj1Box
	LDX <Obj1Id
	LDA MS_Collision_Table + 2, y
	ADC OBJ_YPOS, x
	STA <TempPos
	
	CLC
	LDY <Obj2Box
	LDX <Obj2Id
	LDA MS_Collision_Table + 3, y
	ADC OBJ_YPOS, x
	CMP <TempPos
	
	
	BCS .Test2 ;Test true, move to next one.
	JMP .noOverlap
	
.Test2: ;Obj1.y2 > Obj2.y1
	CLC
	LDY <Obj2Box
	LDX <Obj2Id
	LDA MS_Collision_Table + 2, y
	ADC OBJ_YPOS, x
	STA <TempPos
	
	CLC
	LDY <Obj1Box
	LDX <Obj1Id
	LDA MS_Collision_Table + 3, y
	ADC OBJ_YPOS, x
	CMP <TempPos
	
	BCS .Test3 ;Test true, move to next one.
	JMP .noOverlap
	
.Test3: ;Obj2.x2 > Obj1.x1
	CLC
	LDY <Obj1Box
	LDX <Obj1Id
	LDA MS_Collision_Table, y
	ADC OBJ_XPOS, x
	STA <TempPos
	
	CLC
	LDY <Obj2Box
	LDX <Obj2Id
	LDA MS_Collision_Table + 1, y
	ADC OBJ_XPOS, x
	CMP <TempPos
	
	BCS .Test4 ;Test true, move to next one.
	JMP .noOverlap
	
.Test4: ;Obj1.x2 > Obj2.x1
	CLC
	LDY <Obj2Box
	LDX <Obj2Id
	LDA MS_Collision_Table, y
	ADC OBJ_XPOS, x
	STA <TempPos
	
	CLC
	LDY <Obj1Box
	LDX <Obj1Id
	LDA MS_Collision_Table + 1, y
	ADC OBJ_XPOS, x
	CMP <TempPos
	
	BCS .Overlap ;All tests false, box1 overlaps with box2
	
.noOverlap:
	LDA #OVERLAP_FALSE
	LDX <Obj1Id
	LDY <Obj2Id
	RTS
	
.Overlap:
	LDA #OVERLAP_TRUE
	LDX <Obj1Id
	LDY <Obj2Id
	RTS
	
_BGCol_Results = TEMP_BYTE
_ObjId = TEMP_BYTE + 1
_BoxOffset = TEMP_BYTE + 2
_x1 = TEMP_BYTE + 3
_y1 = TEMP_BYTE + 4
_x2 = TEMP_BYTE + 5
_y2 = TEMP_BYTE + 6
_MapOffset = TEMP_BYTE + 7

;Output: Collision results
Overlap_Background_Small:
	PHX
	
	TXA
	STA <_ObjId
	
	LDA #0
	STA <_BGCol_Results ;output value
	
	LDA OBJ_METASPRITE, x
	ASL A
	ASL A ;Each field in the collision table has size 4
	STA <_BoxOffset
	
.x1:
	TAY ;Metasprite/Colbox id
	LDA OBJ_XPOS, x
	CLC
	ADC MS_Collision_Table, y
	
	;We need to know how many pixels of the bounding box are inside the tile
	;We do that by getting the modulo of the position divided by 16.
	;This is the same as ANDing the first four bits of the position.
	PHA
	AND #%00001111
	STA COLLISION_OVERLAP 
	LDA #16
	SEC
	SBC COLLISION_OVERLAP
	STA COLLISION_OVERLAP
	PLA
	
	LSR A
	LSR A
	LSR A
	LSR A ;Divide by 16
	STA <_x1 ;x1 in the collision map
.x2
	LDA OBJ_XPOS, x
	CLC
	ADC MS_Collision_Table + 1, y
	
	PHA
	AND #%00001111
	STA COLLISION_OVERLAP + 1
	PLA
	
	LSR A
	LSR A
	LSR A
	LSR A ;Divide by 16
	STA <_x2 ;x1 in the collision map
	
.y1:
	LDA OBJ_YPOS, x
	CLC
	ADC MS_Collision_Table + 2, y
	
	;We do the same for the Y axis overlap.
	PHA
	AND #%00001111
	STA COLLISION_OVERLAP + 2
	LDA #16
	SEC
	SBC COLLISION_OVERLAP + 2
	STA COLLISION_OVERLAP + 2
	PLA
	
	LSR A
	LSR A
	LSR A
	LSR A
	STA <_y1 ;y1 in the collision map
	
.y2:
	LDA OBJ_YPOS, x
	CLC
	ADC MS_Collision_Table + 3, y

	PHA
	AND #%00001111
	STA COLLISION_OVERLAP  + 3
	PLA
	
	LSR A
	LSR A
	LSR A
	LSR A
	STA <_y2 ;y1 in the collision map
	
.topLeft:
	;LDA MUL14_Table, y ;Simulate y1 * 14
	LDY <_y1
	LDA MUL16_Table, y ;Simulate y1 * 16
	PHA
	CLC
	ADC <_x1
	STA COLLISION_OFFSET ;Tile where top left of bounding box sits
	;Compensate for Y axis underflow 
	CMP #COLMAP_SIZE
	BCC .topRight
	CLC
	ADC #COLMAP_SIZE - 256
	STA COLLISION_OFFSET
	
.topRight
	PLA
	CLC
	ADC <_x2
	STA COLLISION_OFFSET + 1
	;Compensate for Y axis underflow 
	CMP #COLMAP_SIZE
	BCC .bottomLeft
	CLC
	ADC #COLMAP_SIZE - 256
	STA COLLISION_OFFSET + 1
	
.bottomLeft:
	LDY <_y2
	LDA MUL16_Table, y
	;LDA MUL14_Table, y
	PHA
	CLC
	ADC <_x1
	STA COLLISION_OFFSET + 2
	;Compensate for Y axis overflow 
	CMP #COLMAP_SIZE
	BCC .bottomRight
	SEC
	SBC #COLMAP_SIZE
	STA COLLISION_OFFSET + 2
	
.bottomRight
	PLA
	CLC
	ADC <_x2
	STA COLLISION_OFFSET + 3

	;Compensate for Y axis overflow 
	;(if the box is top half on bottom, bottom half on top, index will be larger than the collision map size)
	CMP #COLMAP_SIZE
	BCC .end
	SEC
	SBC #COLMAP_SIZE
	STA COLLISION_OFFSET + 3
	
.end
	PLX
	RTS

;Writes unbreakable tiles around the playfield
CollisionMap_DefaultBorder:
	LDA #TILE_BORDER
	LDX #0
.loop1
	STA COLLISION_MAP, x
	INX
	CPX #32
	BNE .loop1
	
	
	LDA #HIGH(COLLISION_MAP + 32)
	STA <TEMP_BYTE + 1
	LDA #LOW(COLLISION_MAP + 32)
	STA <TEMP_BYTE
	

	LDX #0
.loop2
	LDA #TILE_BORDER
	LDY #0
	STA [TEMP_BYTE], y
	LDY #15
	STA [TEMP_BYTE], y

	LDA #16
	CLC
	ADC <TEMP_BYTE
	STA <TEMP_BYTE
	LDA <TEMP_BYTE + 1
	ADC #0
	STA <TEMP_BYTE + 1
	
	INX
	CPX #11
	BNE .loop2
	
	LDX #0
	LDA #TILE_BORDER
.loop3
	STA COLLISION_MAP + ( 16 * 13 ), x
	INX
	CPX #32
	BNE .loop3
	
	RTS
	
;Uploads the top half of the playfield collision map.
;Call_Args (2bytes) = collision data address
CollisionMap_UploadTop:	
	LDY #0
	LDX #0
.loop
	LDA [CALL_ARGS], y
	STA COLLISION_MAP + 48 + 1, x
	
	INX
	CPX #$3E
	BCS .end
	
	INY
	CPY #14
	BCC .loop ;All bytes written
	
	INX
	INX
	
	LDA <CALL_ARGS
	CLC
	ADC #14
	STA <CALL_ARGS
	LDA <CALL_ARGS + 1
	ADC #0
	STA <CALL_ARGS + 1
	
	LDY #0
	jMP .loop
	
.end
	RTS
	
MUL16_Table:
	.db 0
	.db 16
	.db 16 * 2
	.db 16 * 3
	.db 16 * 4
	.db 16 * 5
	.db 16 * 6
	.db 16 * 7
	.db 16 * 8
	.db 16 * 9
	.db 16 * 10
	.db 16 * 11
	.db 16 * 12
	.db 16 * 13
	.db 16 * 14
	.db 16 * 15

