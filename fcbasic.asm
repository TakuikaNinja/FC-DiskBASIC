; ==================================================================================================================================
; ----------------------------------------------------------------------------------------------------------------------------------
; Disk BASIC Layout
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
	FILE_COUNT = 3
	
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
	.incbin "kyodaku.bin"

; ----------------------------------------------------------------------------------------------------------------------------------
; CHR
	.segment "FILE1_HDR"
	.import __FILE1_DAT_RUN__
	.import __FILE1_DAT_SIZE__
	.byte FileHeaderBlock
	.byte $01, $00
	.byte "CHR",0,0,0,0,0
	.word __FILE1_DAT_RUN__
	.word __FILE1_DAT_SIZE__
	.byte CHR
	
	.byte FileDataBlock
	.segment "FILE1_DAT"
	.incbin FILE, INES_HDR + $8000, $2000

; ----------------------------------------------------------------------------------------------------------------------------------
; PRG
	.segment "FILE2_HDR"
	.import __FILE2_DAT_RUN__
	.import __FILE2_DAT_SIZE__
	.byte FileHeaderBlock
	.byte $02, $00
	.byte "PRG",0,0,0,0,0
	.word __FILE2_DAT_RUN__
	.word __FILE2_DAT_SIZE__
	.byte PRG
	
	.byte FileDataBlock
	.segment "FILE2_DAT"
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
		jmp $80f0 ; replaces jsr $8131
	
	.segment "PATCH_1"
	.addr $b5af ; replaces operand of jmp $80ad
	
	.segment "PATCH_2"
		nop ; replaces cli
	
	.segment "PATCH_3"
	.byte $7f
	
	.segment "PATCH_4"
	.byte $80
	
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
		jmp $80ad
	
	.segment "VECTORS_PATCH"
; Note: IRQ handler is also bad in the original, which has been duplicated here
; (At least you can rewrite it to use IRQs in machine code programs now)
		cli
	.byte $5c, $60, $00 ; ?
	.addr $00ed ; NMI vector?
	
	; Interrupt vectors
	.addr $00ed ; NMI #1
	.addr $00ed ; NMI #2
	.addr $00ed ; NMI #3, default
	.addr $c400 ; Reset
	.addr $dff0 ; IRQ (unused?)

