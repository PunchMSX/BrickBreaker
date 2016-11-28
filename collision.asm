
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
