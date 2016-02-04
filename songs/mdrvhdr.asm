; MDRV file header ver 0004 by BKC
; 2007/04/21 first version
; 2007/05/15 second version
; 2007/05/22 third version
; 2015/03/02 Added PCMFILE definition.

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
	db    $00 ; Packed PCM into MDR if 1
	db    $00 ; Size of packed PCM in banks

	.if	(SOUND_USERPCM = 1)
	dw  userpcm_string
	.else
	dw  $0000
	.endif

	.org $8080	

	.if	(SOUND_USERPCM = 1)
userpcm_string:
	PCMFILE
	.endif
	
	.include "effect.h"


