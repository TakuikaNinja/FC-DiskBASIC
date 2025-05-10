; Disk BASIC IPL-PRG
; inserted by FCBASSAV (tape to disk transfer program) from ファミコン改造マニュアル Vol. 3
; this code is loaded during the first boot but is never executed before being overwritten

; disassembled using https://www.masswerk.at/6502/disassembler.html
; and manually cleaned up + corrected for use with ca65

.enum
	PPUADDR = $2006
	DisPFObj = $e161
	EnPF = $e185
	VRAMStructWrite = $e7bb
	SetScroll = $eaea
.endenum

l0300:    
		lda #<l0300
		sta $dffc ; reset vector low byte (typo'd as $dffd in Vol. 3)
		lda #>l0300
		sta $dffd ; reset vector high byte
		lda #$26
		sta FDS_CTRL ; set nametable arrangement
		lda #$00
		sta $5000 ; probably mapped to a custom hardware interface?
		jmp l0300 ; infinite loop

; unknown code
		nop
		jsr DisPFObj
		jsr VRAMStructWrite
     .addr $64e7
		jsr SetScroll
		jsr EnPF
		lda #$00
		sta $30
		jsr $60fd
		jsr DisPFObj
		jsr $64ff
		lda $30
		sta PPUADDR
		lda #$00
		sta PPUADDR
		ldx #$00
	.byte $bd ; lda abs,X opcode?

