;*********************************************
; MoonDriver for MoonSound / Programmed by BKC
;*********************************************
;
; 2007/04/17
;
; * Started
;
; 2007/04/23
;
; * First version
;
; 2007/04/24
;
; * Fixed volume after used envelope
; * Fixed tone length
;
; 2007/04/28
;
; * Fixed a part to read value of instrument command
; * Removed a part to store volume reg for env processes
; * Fixed set note routine to use envelope's value at start if needed
; * Improved to use ADSR registers
; * Added to use LFO
;
; 2007/04/30
;
; * Fixed effect on when detune is zero
; * Added damp (command $eb)
; * Don't Key-Off if not Key-On
; * Fixed an assign of PCM-MIX bit for key
;
; 2007/05/01
;
; * Fixed repeat command to work
; * Added pseudo reverb (cmd $ea)
;
; 2007/05/05
;
; * First release
;
; 2007/05/12
;
; * Added repeat_end command
;
; 2007/05/14
;
; * Added FM stuff temporarily
;
; 2007/05/16
;
; * Added a part to initialize opbase for OPL3
; * Added FBS and TVP values to tone define
; * Added Pitch Envelope and detune to OPL3 part
;
; 2007/05/18
;
; * Added FBS2 to OPL3 tone
; * Changed FBS to FB
; * Added Volume to OPL3
;
; 2007/05/19
;
; * Changed FM volume to subtract from register's value
;
; 2007/05/20
;
; * Changed calculation for FM volume.
; * Improved Key-On problem in pitch envelope on FM
; * Changed first charactor in the history.
; * Changed 4OP stuff

; 2007/05/24
;
; * Added device selector for initialize
;
; 2007/05/26
;
; * Rewritten a part of the source cleaner
; * Added Note Envelope to OPL3
; * Fixed minor bug
; * Improved Pitch Envelope for OPL3 to be over an octave
; * Added slar
;
; 2007/05/27
;
; * Changed slar effect on OPL4
;
; 2007/05/28
;
; * Changed Pitch Envelope effect on OPL3
;
; 2007/05/31
;
; * Fixed OPL4 Pitch correction when slar is used
; * Added a routine to check the file valid
; * Changed the way to handle timing
; * Fixed the way to wait a loading tone in OPL4
; * Changed handling of EXPANSION REGISTER
; * Optimized some routines
;
; 2007/06/01
;
; * Changed some way to make a value for register
;
; 2007/07/01
;
; * Changed version number for release
;
; 2015/01/30
;
; * Separates driver from loader.
;
; 2015/02/02
;
; * Improved usability of driver code.
;
; 2015/03/01
;
; * Changed to load MOON.BIN from disk
; * Improved strings for infomation
;
; 2016/02/05
;
; * try to load song file without extension.
;
;
;********************************************
; Memory usage
; Page 0 ( $0000 - $3FFF ) : Utility
; Page 1 ( $4000 - $7FFF ) : Driver
; Page 2 ( $8000 - $BFFF ) : Data
;
; Note for developers
;
; * Please don't forget to remount the folder if the program has been updated
; * DOS gets back mapper RAM when called via BDOS
;
; Note on the OPL4
; You can change F-num and octave after key-on
;
;********************************************

BDOS:		equ	$0005
FCB:		equ	$005C

MOON_BASE:   equ  $00C4

MDRV_INIT:	 equ	$4000
MDRV_INT:	   equ	$4003
MDRV_ALLOFF: equ	$4006
MDRV_VERSTR: equ	$4011
MDRV_LOADPCM: equ	$4013

RAM_PAGE3:	equ	$FE

MDR_ID:     equ $8000
MDR_PACKED: equ $802A ; 1 if packed

MDR_DSTPCM: equ $8030 ; destination address of PCM
MDR_STPCM:  equ $8031 ; PCM start bank
MDR_BANKS:  equ $8032 ; PCM banks
MDR_LASTS:  equ $8033 ; PCM size of lastbank

;********************************************
; Entry point

	org	$100
	jp	x86_trap	; a trap for x86

x86_trap:

	; displays program title.
	ld	de, str_prog_title
	ld	c, $09
	call	BDOS

	; check MoonSound and initalize it

	call	check_moon
	jr	nz, found_moon

	; MoonSound is not found

	ld	de, str_moon_not
	ld	c,$09
	jp	BDOS

found_moon:

; MoonSound is found

	ld	de, str_moon_fnd
	ld	c, $09
	call	BDOS

; Load driver
	call	load_driver
	or	a
	jr	nz, file_error

	ld	hl, MDRV_VERSTR
	ld	e, (hl)
	inc	hl
	ld	d, (hl)

	; skip if DE = 0x0000
	ld	a, e
	or	d
	jr	z, skip_verstr

	ld	c, $09
	call	BDOS

skip_verstr:

; load song
	call	load_file
	or	a
	jr	nz, file_error

	jr	main_check_file

; failed
file_error:
	ld	de, str_file_error
	ld	c, $09
	jp	BDOS

main_check_file:
	call	check_file
	jp	z, start_play

	ld	de, str_format_error
	ld	c, $09
	jp	BDOS


;********************************************
; load_pcm
; Load user pcm
;
load_pcm:
	xor	a
	call change_page3
	ld	a, (MDR_PACKED)
	or	a
	ret	z
	ld	de, str_loading_pcm
	call out_str

	; load pcm
	call	MDRV_LOADPCM

	ld	 de, str_ok
	call out_str
	jp   out_lf

;********************************************
;start_play
;Initialize workarea
;
start_play:
	call	load_pcm

	call	MDRV_INIT

	ld	de, str_play
	ld	c, $09
	call	BDOS

	xor	a
	ld	(intr_cnt), a
	call	set_timi	; set timer

start_play_lp1:
	; check key

	ld	c,$0b
	call	BDOS
	or	a
	jr	nz,start_play_fin ; if key was pressed then quit

	ld	a, (intr_cnt)
	or	a
	jr	z,start_play_lp1

start_play_lp2:
	call	MDRV_INT
	ld	a, (intr_cnt)
	dec	a
	ld	(intr_cnt), a
	jr	z, start_play_lp1
	jr	start_play_lp2

start_play_fin:

	call	restore_timi	; restore timer
	jp	MDRV_ALLOFF

;********************************************
;check_file
; check the file format is valid
check_file:
	ld	hl, $8000
	ld	de, str_file_id
	ld	c, $4
	xor	a
	call	change_page3

check_file_lp:
	ld	a,(de)
	cp	(hl)
	ret	nz
	inc	hl
	inc	de
	dec	c
	jr	nz,check_file_lp
	ret



;********************************************
; load_file
; Load sequence file from disk
; in   : FCB ( a parameter from DOS )
; out  : Z = success
; dest : DE

load_file:
	ld	 de, str_loading_song
	call out_str

	; try with fullname
	ld	de, FCB
	ld	c, $0f ; file open
	call	BDOS
	or	a
	jr	z, load_file_start

	; with .MDR extension
	ld	hl, str_mdrext
	ld	de, FCB + 9
	ld	bc, $0003
	ldir

	; open..
	ld	de, FCB
	ld	c, $0f ; file open
	call	BDOS
	or	a
	; failed if nz
	ret	nz

load_file_start:
	ld	de, dos_dta
	ld	c, $1a   ; set DTA
	call	BDOS

	; song start address
	ld	hl, $8000
	xor	a
	ld	(loaded_bank), a
load_file_lp01:

	push	hl
	ld	de, FCB
	ld	c, $14   ; sequencial read
	call	BDOS
	pop	hl

	push	af
	ld	a, (loaded_bank)
	call	change_page3
	ex	de, hl
	ld	hl, dos_dta
	ld	bc, $0080
	ldir
	ex	de, hl
	pop	af

	or	a
	jr	nz, load_file_eof
	ld	a, h
	cp	$c0
	jr	c, load_file_lp01 ; hl >= $c000


	ld	hl, $8000
	ld	a, (loaded_bank)
	add	a, $02
	ld	(loaded_bank), a

	jr	load_file_lp01

load_file_eof:
	ld	de, str_ok
	call out_str
	call out_lf

	ld	de, FCB
	ld	c, $10  ; close
	jp	BDOS


;********************************************
; load_driver
; dest : DE
; out : Z = success

load_driver:
	ld	de, str_loading_driver
	ld	c, $09 ; output string
	call	BDOS

	ld	de, driver_fcb
	ld	c, $0f ; file open
	call	BDOS
	or	a
	ret	nz

	ld	de, dos_dta
	ld	c, $1a   ; set DTA
	call	BDOS

	; song start address
	ld	hl, $4000
load_driver_lp01:
	push	hl
	ld	de, driver_fcb
	ld	c, $14   ; sequencial read
	call	BDOS
	pop	hl

	push	af
	ex	de, hl
	ld	hl, dos_dta
	ld	bc, $0080
	ldir
	ex	de, hl
	pop	af

	or	a
	jr	nz, load_driver_eof
	ld	a, h
	cp	$80
	jr	c, load_driver_lp01 ; hl >= $8000

load_driver_eof:
	ld	de, str_ok
	call out_str
	call out_lf

	ld	de, driver_fcb
	ld	c, $10  ; close
	jp	BDOS


;********************************************
; changes page3
; in   : A = bank number(0 = start of song file)
; dest : AF
change_page3:

	srl	a
	add	a, $04 ; The system uses 4pages for initial work area
	out	(RAM_PAGE3), a
	ret

;//////////////////////////////////////
; routines for debugging
;//////////////////////////////////////

;********************************************
; out_str
; output string
; in : DE = string
; dest: all
out_str:
	ld	c, $09 ; output string
	jp	BDOS

;********************************************
; out_ch
; output a charactor
; in : A = char
;
out_ch:
	push	de
	push	bc
	ld	e,a
	ld	c,2
	call	BDOS
	pop	bc
	pop	de
	ret

;********************************************
; output LF control
;
out_lf:
	ld	a, $0d
	call	out_ch
	ld	a, $0a
	jp	out_ch

;********************************************
; display a hex
; in   : A = num
; dest : AF

disp_hex:
	push	hl
	push	de
	push	af
	rra
	rra
	rra
	rra
	and	$0f

	ld	d,$00
	ld	e,a
	ld	hl,str_hextbl
	add	hl,de

	ld	a,(hl)
	call	out_ch

	pop	af
	and	$0f
	ld	d,$00
	ld	e,a
	ld	hl,str_hextbl
	add	hl,de
	ld	a,(hl)
	call	out_ch

	pop	de
	pop	hl
	ret


;********************************************
; check MoonSound and initialize it
; out : NZ if MoonSound is found
;
check_moon:
	in	a, (MOON_BASE)
	cp	$ff
	ret

PG2RAM: 	equ	$F342
H_TIMI:		equ	$FD9F


;********************************************
; set_timi
; hook to use an user interrupt routine
;
set_timi:
	ld	bc, $05
	ld	hl, H_TIMI
	ld	de, save_hook
	ldir
	di
	ld	a, $f7 ; rst30
	ld	(H_TIMI), a

	ld	a, (PG2RAM)
	ld	(H_TIMI + 1), a ; slot on RAM in page2
	; use my interrupt routine
	ld	hl,userint
	ld	a, l
	ld	(H_TIMI + 2), a
	ld	a, h
	ld	(H_TIMI + 3), a
	ei
	ret

;********************************************
; restore_timi
; restore interrupt
; dest : AF, BC, DE, HL
restore_timi:
	di
	ld	bc, $05
	ld	de, H_TIMI
	ld	hl, save_hook
	ldir
	ei
	ret

save_hook:
	ds	$05


;********************************************
; userint
; User interrupt routine for H_TIMI.

userint:
	push	hl
	push	de
	push	bc
	push	af
	exx
	ex	af,af'
	push	hl
	push	de
	push 	bc
	push	af
	push	iy
	push	ix


	call	intr_inc_cnt

usrint_end:
	pop	ix
	pop	iy
	pop	af
	pop	bc
	pop	de
	pop	hl
	ex	af,af'
	exx
	pop	af
	pop	bc
	pop	de
	pop	hl
	ret

;********************************************
intr_cnt:
	db $00

loaded_bank:
	db $00


intr_inc_cnt:
	ld	a, (intr_cnt)
	inc	a
	ld	(intr_cnt), a
	ret


;********
; FCB to load "MOON.BIN"
driver_fcb:
	db $00 ; drive
	db "MOON    " ; file
	db "BIN"      ; ext
	ds $19




;********************************************
; Strings
str_prog_title:
	db "MOONLOADER "
	db "VER 160205"
	db $0d,$0a,'$'

str_moon_fnd:
	db "MOONSOUND DETECTED",$0d,$0a,'$'

str_moon_not:
	db "MOONSOUND IS NOT FOUND",$0d,$0a,'$'

str_loading_song:
	db "LOADING SONG...",'$'

str_loading_driver:
	db "LOADING DRIVER...",'$'

str_loading_pcm:
	db "LOADING PCM...",'$'

str_lf:
	db $0d,$0a,'$'

str_ok:
	db "OK",'$'


str_play:
	db "PLAY",$0d,$0a,'$'
str_ram_error:
	db "RAM ERROR",$0d,$0a,'$'
str_file_error:
	db "FILE ERROR",$0d,$0a,'$'
str_format_error:
	db "FILE FORMAT ERROR",$0d,$0a,'$'

str_hextbl:
	db "0123456789ABCDEF"

str_mdrext:
	db "MDR"

str_file_id:
	db  "MDRV"


dos_dta:
	ds	$80
