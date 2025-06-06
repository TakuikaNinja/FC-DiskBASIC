; Disk BASIC save utility from ファミコン改造マニュアル Vol. 3
; disassembled using https://www.masswerk.at/6502/disassembler.html
; and manually cleaned up for use with ca65

; ==================================================================================================================================
; ----------------------------------------------------------------------------------------------------------------------------------
; Disk Layout
; ----------------------------------------------------------------------------------------------------------------------------------
; Build-time constants
.ifndef OLD_DISKSYS
	OLD_DISKSYS = 0
.endif

; Definitions
.enum
	DiskInfoBlock	= 1
	FileAmountBlock   = 2
	FileHeaderBlock   = 3
	FileDataBlock	= 4
	
	PRG = 0
	CHR = 1
	VRAM = 2
	FILE_COUNT = 2
	
	FDS_DRIVE_STATUS = $4032
	
	DisPFObj = $e161
	EnPF = $e185
	VINTWait = $e1b2
	WriteFile = $e239
	VRAMStructWrite = $e7bb
	SetScroll = $eaea
	
	FDS_RESET = $FFFC ; BIOS reset handler vector
	
	 ; BIOS routine to print disk error codes
	 ; location differs between BIOS revisions, 
	 ; original listing uses $f179
	.if OLD_DISKSYS = 1
		PrintError = $f16c ; 01 revision
	.else
		PrintError = $f179 ; 01A, 02 revisions
	.endif
.endenum

; ----------------------------------------------------------------------------------------------------------------------------------
; Disk Structure
	.segment "SIDE1A"
	
; Disk info + file amount blocks
	.byte DiskInfoBlock
	.byte "*NINTENDO-HVC*"
	.res 41, 0
	
	.byte FileAmountBlock
	.byte FILE_COUNT

; ----------------------------------------------------------------------------------------------------------------------------------
; kyodaku file (license screen)
	.segment "FILE0_HDR"
	.import __FILE0_DAT_RUN__
	.import __FILE0_DAT_SIZE__
	.byte FileHeaderBlock
	.byte $00, $00
	.byte "KYODAKU-"
	.word __FILE0_DAT_RUN__
	.word __FILE0_DAT_SIZE__
	.byte VRAM

	.byte FileDataBlock
	.segment "FILE0_DAT"
	.incbin "../kyodaku.bin" ; reuse file in parent directory

; ----------------------------------------------------------------------------------------------------------------------------------
; PRG
	.segment "FILE1_HDR"
	.import __FILE1_DAT_RUN__
	.import __FILE1_DAT_SIZE__
	.byte FileHeaderBlock
	.byte $01, $00
	.byte "KUMA-03W"
	.word __FILE1_DAT_RUN__
	.word __FILE1_DAT_SIZE__
	.byte PRG
	
	.byte FileDataBlock
	.segment "FILE1_DAT"

; entrypoint at $dc00
ldc00:
		jmp ldce6

ldc03:
		jsr VINTWait
		jsr VRAMStructWrite
	.addr ldc51 ; "PLEASE EJECT DISK"
		jsr SetScroll
		jsr EnPF

ldc11:
		lda FDS_DRIVE_STATUS ; wait until disk is ejected
		and #$01
		beq ldc11

		jsr VINTWait
		jsr VRAMStructWrite
	.addr ldc69 ; "PLEASE BA DISK CARD"
		jsr SetScroll
		jsr EnPF

ldc26:
		lda FDS_DRIVE_STATUS ; wait until disk is inserted
		and #$01
		bne ldc26
		
		nop
		nop
		jmp ldcd5

ldc32:
		lda #$04 ; file 4
		jsr WriteFile
	.addr ldc99 ; disk ID struct
	.addr ldcc3 ; save file header
		bne ldc40 ; branch on error
		
		; soft-reset on success
		; the original listing hardcoded a jmp $ee24 here, 
		; but that only works on 01A & 02 BIOS revisions
		; ($ee17 in 01 revision)
		jmp (FDS_RESET)

ldc40:
		sta $23 ; save error code
		jsr VINTWait
		jsr PrintError ; print error code in $23
		jsr SetScroll
		jsr EnPF
		jmp ldc11 ; try again from the start

; VRAM struct data
; text is encoded using the BIOS font (i.e. SMB1/Zelda encoding)
ldc51:
	.dbyt $21a6 ; starting PPU address (big endian)
	.byte $14 ; length
	.byte $19, $15, $0e, $0a, $1c, $0e, $24 ; "PLEASE "
	.byte $0e, $13, $0e, $0c, $1d, $24 ; "EJECT "
	.byte $0d, $12, $1c, $14, $24, $24, $24 ; "DISK   "
	.byte $ff ; terminator

ldc69:
	.dbyt $21a6 ; starting PPU address (big endian)
	.byte $14 ; length
	.byte $19, $15, $0e, $0a, $1c, $0e, $24 ; "PLEASE "
	.byte $0b, $0a, $24, $0d, $12, $1c, $14, $24 ; "BA DISK "
	.byte $0c, $0a, $1b, $0d, $24 ; "CARD "
	.byte $ff ; terminator

ldc81:
	.dbyt $21a6 ; starting PPU address (big endian)
	.byte $14 ; length
	.byte $17, $18, $20, $24 ; "NOW"
	.byte $1c, $0a, $1f, $0e, $12, $17, $10, $26, $26, $26 ; "SAVEING..." [sic]
	.byte $24, $24, $24, $24, $24, $24 ; "	"
	.byte $ff ; terminator

; disk ID struct (10 bytes) - these are checked against bytes in the disk info block
ldc99:
	.byte "KOUJI" ; (these bytes are normally disk metadata)
	.byte 0,0,0,0,0 ; (BIOS only checks up to here)

; rest of the disk info block (never checked by the BIOS)
; could be a holdover from FCBASSAV (tape to disk transfer program)
	.byte $0f ; boot read file code
	.byte $ff, $ff, $ff, $ff, $ff ; unknown
	.byte $61, $11, $27 ; manufacturing date (1986-11-27)
	.byte $49, $61, $00, $00, $02 ; country, region, unknown
	.byte $00, $5a, $00, $73, $00 ; unknown
	.byte $61, $11, $27 ; disk rewrite date (same as manufacturing date)
	.byte $FF, $FF, $FF, $FF, $FF ; unknown
	.byte $00, $00, $00, $00 ; other fields (not relevant here)
	.byte $01 ; ?

; save file header
; this saves the $6000-$7fff area (used for BASIC program memory) to disk
ldcc3:
	.byte $03 ; file ID
	.byte "BAS-PRG " ; file name
	.addr $6000 ; load address
	.addr $2000 ; file data size
	.byte $00 ; file type (PRG)
; these fields are read in order to fetch the data, but are not saved to disk
	.addr $6000 ; source address
	.byte $00 ; source address type (RAM)

	.byte $00 ; (the source address type field above was likely incorrectly treated as 16 bits here)

ldcd5:
		jsr VINTWait
		jsr VRAMStructWrite
	.addr ldc81 ; "NOW SAVEING..." [sic]
		jsr SetScroll
		jsr EnPF
		jmp ldc32

ldce6:
		jsr DisPFObj
		ldx #$ff
		txs
		jmp ldc03

; padding until $dff0
.res $0301, 0

; default NMI/IRQ handler (unused)
ldff0:
		rti

; padding, which happens to also occupy NMI #1...
.res 7, $ea

; interrupt vectors
	.addr ldff0 ; NMI #2
	.addr ldff0 ; NMI #3, default
	.addr ldc00 ; Reset
	.addr ldff0 ; IRQ

