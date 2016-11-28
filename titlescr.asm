;Titlescreen.asm
;Title screen game loop and related functions.
	
INTRO_MAXBULLETS = 8
INTRO_MAXCHARS = 2
INTRO_SPAWNTIME = 25 ;1/2s NTSC
	
Intro_SpawnBullets:
	LDA INTRO_BULLETQ
	CMP #INTRO_MAXBULLETS
	BCC .checkTimer
	RTS
.checkTimer
	LDA INTRO_SPAWN_TMR
	CMP #INTRO_SPAWNTIME
	BCC .end
	
	JSR RNG_Next
	TAX
	JSR RNG_Next
	TAY
	LDA #4
	JSR ObjectList_Insert ;Intro_Ball
	
	CMP #$FF
	BEQ .end ;Did not spawn, don't reset the timer
	
	LDA #0
	STA INTRO_SPAWN_TMR
	INC INTRO_BULLETQ
.end;
	RTS
	
Intro_SpawnChars:
	LDA INTRO_CHARQ
	CMP #INTRO_MAXCHARS
	BCC .checkTimer
	RTS
.checkTimer
	LDA INTRO_SPAWN_TMR + 1
	CMP #INTRO_SPAWNTIME * 2
	BCC .end
	
	LDA #2
	JSR ObjectList_Insert ;Main Character
	
	CMP #$FF
	BEQ .end ;Did not spawn, don't reset the timer
	
	LDA #0
	STA INTRO_SPAWN_TMR + 1
	INC INTRO_CHARQ
.end
	RTS
	
TitleInit:
	LDA #0
	STA INTRO_BULLETQ
	STA INTRO_CHARQ
	STA INTRO_TIMER

	
	LDA #LOW(bg_Title_Screen)
	STA CPUADDR_NAM
	LDA #HIGH(bg_Title_Screen)
	STA CPUADDR_NAM + 1
	LDA #$20
	STA PPUADDR_NAM
	LDA #$00
	STA PPUADDR_NAM + 1
	
	LDA #1
	STA PPU_DRAW ;Schedule "Text1" to be drawn next NMI
	
	RTS

TitleLoop:
	TCK INTRO_SPAWN_TMR
	TCK INTRO_SPAWN_TMR + 1
	
	JSR Intro_SpawnBullets
	JSR Intro_SpawnChars
	
	RTS
	