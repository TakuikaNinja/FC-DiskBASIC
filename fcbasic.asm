; ==================================================================================================================================
; ----------------------------------------------------------------------------------------------------------------------------------
; Ikki FDS Port Disk Layout
; ----------------------------------------------------------------------------------------------------------------------------------
; Disk Structure
	.org $0000
	INES_HDR = $10 ; size of iNES header
	FILE equ "fcbasic.nes"
	
; ----------------------------------------------------------------------------------------------------------------------------------
; Disk definitions taken from SMB2J's disassembly
	DiskInfoBlock     = 1
	FileAmountBlock   = 2
	FileHeaderBlock   = 3
	FileDataBlock     = 4
	PRG = 0
	CHR = 1
	VRAM = 2
	FILE_COUNT = 3

; ----------------------------------------------------------------------------------------------------------------------------------
; Disk info + file amount blocks
	.db DiskInfoBlock
	.db "*NINTENDO-HVC*"
	.dsb 41
	
	.db FileAmountBlock
	.db FILE_COUNT

; ----------------------------------------------------------------------------------------------------------------------------------
; kyodaku file
	.db FileHeaderBlock
	.db $00, $00
	.db "KYODAKU-"
	.dw $2800
	.dw $00e0
	.db VRAM

	.db FileDataBlock
	.incbin "kyodaku.bin"

; ----------------------------------------------------------------------------------------------------------------------------------
; CHR
	.db FileHeaderBlock
	.db $01, $00
	.db "CHR",0,0,0,0,0
	.dw $0000
	.dw chr_length
	.db CHR
	
	.db FileDataBlock
	chr_length = $2000
	.incbin FILE, INES_HDR + $8000, chr_length

; ----------------------------------------------------------------------------------------------------------------------------------
; PRG
	.db FileHeaderBlock
	.db $02, $00
	.db "PRG",0,0,0,0,0
	.dw $8000
	.dw prg_length
	.db PRG
	
	.db FileDataBlock
	prg_length = $6000 ; exclude area that would conflict with the FDS BIOS
	.incbin FILE, INES_HDR, prg_length
	
	.pad 65500, $ff

