; ==================================================================================================================================
; ----------------------------------------------------------------------------------------------------------------------------------
; Ikki FDS Port Disk Layout
; ----------------------------------------------------------------------------------------------------------------------------------
; Definitions
.enum
	INES_HDR = $10 ; size of iNES header
	PRG_SIZE = $6000 ; cut out data which would conflict with FDS BIOS
	
	DiskInfoBlock     = 1
	FileAmountBlock   = 2
	FileHeaderBlock   = 3
	FileDataBlock     = 4
	
	PRG = 0
	CHR = 1
	VRAM = 2
	FILE_COUNT = 4
	
	PPUCTRL = $2000
	NMI_FLAG = $0100
	IRQ_FLAG = $0101
	RST_FLAG = $0102
	RST_TYPE = $0103
	SND_CHN = $4015
	FDS_CTRL = $4025
.endenum

	.define FILE "Family BASIC (Japan) (Rev 2).nes"

; ----------------------------------------------------------------------------------------------------------------------------------
; Disk Structure
	.segment "SIDE1A"
	
; Disk info + file amount blocks
	.byte DiskInfoBlock
	.byte "*NINTENDO-HVC*"
	.byte "KOUJI" ; checked by save utility (these bytes are normally disk metadata)
	.byte 0,0,0,0,0
	.byte $0f ; boot read file code
	.byte $ff, $ff, $ff, $ff, $ff ; unknown
	.byte $61, $11, $27 ; manufacturing date (1986-11-27)
	.byte $49, $61, $00, $00, $02 ; country, region, unknown
	.byte $00, $5a, $00, $73, $00 ; unknown
	.byte $61, $11, $27 ; disk rewrite date (same as manufacturing date)
	.byte $FF, $FF, $FF, $FF, $FF ; unknown
	.byte $00, $00, $00, $00 ; other fields (not relevant here)
	
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
	.incbin "kyodaku.bin"

; ----------------------------------------------------------------------------------------------------------------------------------
; IPL-PRG (unused but counts towards file count)
	.segment "FILE1_HDR"
	.import __FILE1_DAT_RUN__
	.import __FILE1_DAT_SIZE__
	.byte FileHeaderBlock
	.byte $01, $01
	.byte "IPL-PRG "
	.word __FILE1_DAT_RUN__
	.word __FILE1_DAT_SIZE__
	.byte PRG
	
	.byte FileDataBlock
	.segment "FILE1_DAT"
	.include "ipl-prg.asm"

; ----------------------------------------------------------------------------------------------------------------------------------
; CHR
	.segment "FILE2_HDR"
	.import __FILE2_DAT_RUN__
	.import __FILE2_DAT_SIZE__
	.byte FileHeaderBlock
	.byte $02, $02
	.byte "CHR-ROM "
	.word __FILE2_DAT_RUN__
	.word __FILE2_DAT_SIZE__
	.byte CHR
	
	.byte FileDataBlock
	.segment "FILE2_DAT"
	.incbin FILE, INES_HDR + $8000, $2000

; ----------------------------------------------------------------------------------------------------------------------------------
; PRG
	.segment "FILE3_HDR"
	.import __FILE3_DAT_RUN__
	.import __FILE3_DAT_SIZE__
	.byte FileHeaderBlock
	.byte $03, $03
	.byte "PRG-ROM "
	.word __FILE3_DAT_RUN__
	.word __FILE3_DAT_SIZE__
	.byte PRG
	
	.byte FileDataBlock
	.segment "FILE3_DAT"
; Prepare original dump for patching
	.incbin FILE, INES_HDR, PRG_SIZE

; Macro for most patched byte (hi byte of program memory starting address)
	.macro pointer_stub_in segment
		.segment segment
		.byte $60
	.endmacro
	
; Apply 15 instances of said patch
; This expands the program memory to 8126 bytes!
	.repeat 15, I
		pointer_stub_in .concat("POINTER_", .string(I))
	.endrepeat
	
; Specific patches
	.segment "PATCH_0"
		jsr $9228 ; extra patches
		jsr $814b ; for disk saving
		jmp $80f0 ; replaces jsr $8131
	
	.segment "PATCH_1"
	.addr $b5af ; replaces operand of jmp $80ad
	
	.segment "PATCH_2"
		nop ; replaces cli
	
	.segment "PATCH_3"
	.byte $7f
	
	.segment "PATCH_4"
	.byte $80
	
	.segment "SAVE_PATCH_0"
	.byte $59 ; replaces operand of lda #$00
	
	.segment "BGTOOL_CMD"
	.byte "BGTOOL" ; new command to launch BG GRAPHIC, replaces SYSTEM command
	
	.segment "PATCH_5"
	.byte 'D' ; replaces version letter to make "V2.1D"
	
	.segment "RESET_PATCH_0"
		nop ; replaces jsr $cd94
		nop
		nop
	
	.segment "RESET_PATCH_1"
		sta PPUCTRL ; replace parts of the init code with FDS init code (also skips intro sequence)
		sta $10
		lda #$0f
		sta SND_CHN ; enable all APU channels except DMC
		lda #$ff
		sta NMI_FLAG ; select NMI #3
		sta IRQ_FLAG ; select disk game IRQ
		lda #$35
		sta RST_FLAG ; set flag so soft resets work
		lda #$53 ; soft reset
		sta RST_TYPE
		lda #$26 ; horizontal arrangement (vertical mirroring)
		sta FDS_CTRL
		jsr $c5a2 ; for save patch
		jmp $80ad
	
	.segment "SAVE_PATCH_1"
; $c5a1
	.byte $00 ; this is a variable
	
; self-modifying code incoming
		lda $c5a1
		cmp #$ea
		bne :+

		jsr $c5d7
:
		lda #$00
		sta $c5b5
		sta $c5b8
; $c5b4
:
		lda $6010 ; this address...
		sta a:$0010 ; and this address are modified
		inc $c5b5
		inc $c5b8
		lda $c5b8
		cmp #$10
		bne :-

		lda #$ea
		sta $c5a1
		lda #$60
		sta $c5b6
		lda #$00
		sta $c5b9
		rts

; $c5d7
		lda #$00
		sta $c5b6
		lda #$60
		sta $c5b9
		rts

; $c5e2
		rts ; probably makes a subroutine exit?

	.segment "VECTORS_PATCH"
; Note: IRQ handler is also bad in the original (rts x3)
; (At least you can rewrite it to use IRQs in machine code programs now)
		cli
	.byte $5c, $60, $00 ; ?
	.addr $00ed ; NMI vector?
	
	; Interrupt vectors
	.addr $00ed ; NMI #1
	.addr $00ed ; NMI #1
	.addr $00ed ; NMI #3, default
	.addr $c400 ; Reset
	.addr $dff0 ; IRQ (unused?)

