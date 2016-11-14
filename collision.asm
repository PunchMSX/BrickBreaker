
Overlap_Test_All:
	LDY #255
	TYA
	STA OBJ_COLLISION, x
.loop:
	INY
	CPY #OBJ_MAX
	BEQ .end
	LDA OBJ_LIST, x
	CMP #$FF
	BNE .found
	JMP .loop
.found
	PHX
	PHY
	JSR Overlap_Test
	PLY
	PLX
	LDA Overlap1
	CMP #$FF
	BEQ .loop
	TYA
	STA OBJ_COLLISION, x
.end
	RTS

;X = main object
;Y = secondary object
;Tests overlap between two metasprites' Axis Aligned bounding boxes
Overlap_Test:


OBJ1_PTR = TEMP_PTR
OBJ2_PTR = TEMP_PTR + 2
Obj1Q = TEMP_BYTE
Obj2Q = TEMP_BYTE + 1
Overlap1 = TEMP_BYTE + 2
Overlap2 = TEMP_BYTE + 3
Obj1Id = TEMP_BYTE + 4
Obj2Id = TEMP_BYTE + 5
Obj2Box = TEMP_BYTE + 6;4 bytes

	TXA
	STA Obj1Id
	TYA
	STA Obj2Id
	
	;Gets table pointers for both objects' collision data
	PHY ;Conserves Y
	LDA OBJ_METASPRITE, x
	TZP16 OBJ1_PTR, MS_Collision_Table
	PLY ;Restores destroyed Y reg
	LDA OBJ_METASPRITE, y
	TZP16 OBJ2_PTR, MS_Collision_Table
	
	
	;Gets # of boxes (times 4) for Metasprite 1
	LDY #0
	LDA [OBJ1_PTR], y
	STA Obj1Q
	LDA [OBJ2_PTR], y
	STA Obj2Q
	
	;Increments pointers by 1, now pointing to first entries
	INC16 OBJ1_PTR
	INC16 OBJ2_PTR
	
	LDX #0
	LDY #0 ;Obj2 Box index
.forEachBoxPair
	;Copies Obj2's box local position
	PHX ;Saves Obj1's box table index.
	LDX Obj2Id
	
	LDA [OBJ2_PTR], y
	CLC
	ADC OBJ_XPOS, x
	STA <Obj2Box ;Obj2.x1 + Obj2.Posx
	INY
	
	LDA [OBJ2_PTR], y
	CLC
	ADC OBJ_XPOS, x
	STA <Obj2Box + 1 ;Obj2.x2 + Obj2.Posx
	INY
	
	LDA [OBJ2_PTR], y
	CLC
	ADC OBJ_YPOS, x
	STA <Obj2Box + 2 ;Obj2.y1 + Obj2.Posy
	INY
	
	LDA [OBJ2_PTR], y
	CLC
	ADC OBJ_YPOS, x
	STA <Obj2Box + 3 ;Obj2.y2 + Obj2.Posy
	INY
	
	;Compares Obj1's box with Obj2's.
	;Runs four tests. Overlap is true if all four are false.
	;If one of the tests are true, overlap is false. Evaluate next boxes.
	
	PLX ;Restores Obj1's box table index.
	
	PHY ;Saves Obj2's box table index. Restore after all tests are done.
	PHX ;Same deal
	
	;Y now becomes Obj1's box table index.
	TXA
	TAY
	;X = Obj1 Index
	LDX Obj1Id
.test1 ;Obj.x1 > Obj.x2
	LDA [OBJ1_PTR], y
	CLC
	ADC OBJ_XPOS, x ;Obj1.x1 + Obj1.Posx
	
	CMP Obj2Box + 1 ;Obj1.x1 > Obj2.x2?
		BCC .test2 ;False, go to next test.
		JMP .noOverlap ;True, overlap impossible.
		
.test2 ;Obj1.x2 < Obj2.x1
	INY
	LDA [OBJ1_PTR], y
	CLC
	ADC OBJ_XPOS, x ;Obj1.x2 + Obj1.Posx
	
	CMP Obj2Box ;Obj1.x2 < Obj2.x1?
		BCS .test3 ;False.
		JMP .noOverlap ;True.
		
.test3 ;Obj1.y1 > Obj2.y2
	INY
	LDA [OBJ1_PTR], y
	CLC
	ADC OBJ_YPOS, x ;Obj1.y1 + Obj1.Posy
	
	CMP Obj2Box + 3 ;Obj1.y1 > Obj2.y2?
		BCC .test4 ;False.
		JMP .noOverlap ;True.
		
.test4 ;Obj1.y2 < Obj2.y1
	INY
	LDA [OBJ1_PTR], y
	CLC
	ADC OBJ_YPOS, x ;Obj1.x2 + Obj1.Posx
	
	CMP Obj2Box + 2 ;Obj1.y2 < Obj2.y1?
		BCS .Overlap ;False.
		JMP .noOverlap ;True.
		
;All tests false, collision detected!
.Overlap:
	PLX ;Restores Obj1 box table index.
	PLY ;Restores Obj2 box table index.
	
	TXA
	LSR A
	LSR A
	TAX ;Get Obj1 box number
	
	TYA
	LSR A
	LSR A
	TAY
	DEY ;Get Obj2 box number
	
	STX Overlap1
	STY Overlap2
	
	RTS ;Only the first pair of boxes is returned. No further checks follow.
	
;No overlap, go to next Obj2 box.
.noOverlap:
	PLX ;Restores Obj1 box table index. Points to same Obj1 box.
	PLY ;Restores Obj2 box table index. Points to next Obj2 box due to increments.
	
	CPY Obj2Q ;Have we checked against all boxes Obj2 has?
		;No, test next box.
		BCC .nextbox
		
		;Yes, check next Obj1 box against all Obj2 boxes.
		TXA
		CLC
		ADC #4 ;Points to next box in Obj1.
		TAX
		
		CMP Obj1Q ;Have we checked EVERY BOX in Obj1?
			;No. Go ahead with checks.
			BCC .nextbox
			
			;Yes. No collision found between Obj1 and Obj2.
			LDX #255
			LDY #255
			STX Overlap1
			STY Overlap2 ;255 = no overlap
			
			RTS ;End
	
.nextbox
	JMP .forEachBoxPair
	