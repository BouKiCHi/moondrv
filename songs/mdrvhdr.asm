; MDRV file header ver 0005 by BKC
; 2007/04/21 first version
; 2007/05/15 second version
; 2007/05/22 third version
; 2015/03/02 Added PCMFILE definition.
; 2016/02/04 Improved packed PCM definition. 

	.include "define.inc"

DATA_BANK .equ 0

	.bank 0
	.org  $8000
	.code

	ds    $80     ; fill the header with zero

	.org  $8000

	db    "MDRV"
	dw    $0004   ; version
	db    $00     ; num of used channels ( 0 = auto )

	db    SOUND_GENERATOR  ; device flags

	dw    $0000   ; adr title string ( terminated with zero )
	dw    $0000   ; adr artist string ( terminated with zero )
	dw    $0000   ; adr comment string ( terminated with zero )
	db    SOUND_USERPCM   ; User PCM flag
	db    $00   ; reserved

	dw    sound_data_table   ; adr track table
	dw    sound_data_bank    ; adr track bank table

	dw    loop_point_table   ; adr loop table
	dw    loop_point_bank    ; adr loop bank table

	dw    softenve_table     ; adr venv table
	dw    softenve_lp_table  ; adr venv lp table

	dw    pitchenve_table    ; adr penv table
	dw    pitchenve_lp_table ; adr penv lp table

	dw    arpeggio_table     ; adr nenv table
	dw    arpeggio_lp_table  ; adr nenv lp table

	dw    $0000              ; adr lfo  table
	dw    ttbl_data_table    ; adr inst table

	dw    opl3tbl_data_table ; adr opl3 table

pcm_flags:
	; pos: 0x2a  PCM Flag

	; 0 = no use PCM
	; 1 = PCM is packed into the MDR file.
	db    $00
	db    $00

	; pos: 0x2c  PCM string address (if not zero)

	.if	(SOUND_USERPCM = 1)
	dw  userpcm_string
	.else
	dw  $0000
	.endif

	; pos: 0x2e reserved
	dw  $0000

	; pos: 0x30
	db $00 ; start address (x * 0x10000)
	db $00 ; start bank of PCM
	db $00 ; size of PCM banks
	db $00 ; size of last bank(x * 0x100)

	; pos: 0x40 (PCM filename; the format should be 8.3)
	.org $8040

	.if	(SOUND_USERPCM = 1)
userpcm_string:
	PCMFILE
	.endif

	.org $8080

	.include "effect.h"
