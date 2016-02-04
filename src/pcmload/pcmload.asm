;********************************************
; PCMLOAD for OPL4 by BKC
; 2007/05/09 first
;
; 2007/05/10 changed program name to display
;
;********************************************
BDOS:		equ	$0005
FCB:		equ	$005C

MOON_BASE:	equ	$00C4
MOON_REG1:	equ	MOON_BASE
MOON_DAT1:	equ	MOON_BASE+1
MOON_REG2:	equ	MOON_BASE+2
MOON_DAT2:	equ	MOON_BASE+3
MOON_STAT:	equ	MOON_BASE

MOON_WREG:	equ	$007E
MOON_WDAT:	equ	MOON_WREG+1


;********************************************
; Entry point

	org	$100

; A trap for x86
	jp	x86_trap
x86_trap:

; Output an welcome message
	ld	de,str_prgname
	ld	c,$09
	call	BDOS

	call	moon_init
	ret	nz

; "Loading..."
	ld	de,str_loadmsg
	ld	c,$09
	call	BDOS

; Load PCM file
 	call	load_pcmfile
	or	a
	jr	nz,file_error

; Terminate
	ret

;********************************************
; Output "file error" and exit
file_error:
	ld	de,str_file_error
	ld	c,$09
	call	BDOS
	ld	c,$00
	jp	BDOS


;********************************************
; load_pcmfile
; Load PCM file from disk
; in   : FCB ( a parameter from DOS )
; dest : DE

load_pcmfile:
	ld	de,FCB
	ld	c,$0f
	call	BDOS
	or	a
	ret	nz

	ld	de,dos_dta
	ld	c,$1a   ; set DTA
	call	BDOS

	ld	de,$0211 ; memory write mode
	call	moon_wave_out


	ld	de,$0320
	call	moon_wave_out

	ld	de,$0400
	call	moon_wave_out

	ld	de,$0500
	call	moon_wave_out

load_pcmfile_lp01:

	push	hl
	ld	de,FCB
	ld	c,$14   ; sequencial read
	call	BDOS
	pop	hl

	push	af
	ld	hl,dos_dta
	ld	bc,$0080
write_pcm_lp:
	ld	a,(hl)
	ld	e,a
	ld	d,$06
	inc	hl

	call	moon_wave_out
	dec	bc
	ld	a,b
	or	c
	jr	nz,write_pcm_lp
	pop	af

	or	a
	jr	nz,load_pcmfile_eof
	jr	load_pcmfile_lp01
	
load_pcmfile_eof:

	ld	de,$0210 ; normal mode
	call	moon_wave_out


	ld	de,FCB
	ld	c,$10  ; close
	jp	BDOS


;********************************************
; Strings
str_prgname:
	db "PCMLOAD(OPL4) VER 070510",$0d,$0a,'$'

str_file_error:
	db "FILE ERROR",$0d,$0a,'$'

str_moon_fnd:
	db "MOONSOUND DETECTED",$0d,$0a,'$'

str_moon_not:
	db "MOONSOUND IS NOT FOUND",$0d,$0a,'$'


str_loadmsg:
	db "LOADING...",$0d,$0a,'$'


;//////////////////////////////////////
; MoonSound routines
;//////////////////////////////////////

;********************************************
; Initializes MoonSound
; out : NZ if not found
;
moon_init:
	in	a,(MOON_BASE)
	cp	$ff
	jr	nz,moon_init_01


; moonsound is not found

	ld	de,str_moon_not
	ld	c,$09
	call	BDOS
	ld	a,$ff

	and	a
	ret

moon_init_01:

; moonsound is found

	ld	de,str_moon_fnd
	ld	c,$09
	call	BDOS

	ld	de,$0120
	call	moon_fm1_out

	; set D0 and D1 in FM reg5
	ld	de,$0503
	call	moon_fm1_out

	ld	de,$0400
	call	moon_fm2_out

	ld	de,$bd00
	call	moon_fm1_out

	ld	de,$0210
	call	moon_wave_out

	xor	a
	ret


;********************************************
; check moonsound 
; out : Z = not found

moon_check:
	in	a,(MOON_BASE)
	cp	$ff
	ret

dos_dta:
	ds	$80


;********************************************
; wait while BUSY
; dest : AF

moon_wait:
	in	a,(MOON_STAT)
	and	$01
	jr	nz,moon_wait
	ret

;********************************************
; write moonsound fm1 register
; in   : D = an address of register , E = data
; dest : AF

moon_fm1_out:
	ld	a,d
	out	(MOON_REG1),a
	call	moon_wait
	ld	a,e
	out	(MOON_DAT1),a
	call	moon_wait
	ret

;********************************************
; write moonsound fm2 register
; in   : D = an address of register , E = data
; dest : AF

moon_fm2_out:
	ld	a,d
	out	(MOON_REG2),a
	call	moon_wait
	ld	a,e
	out	(MOON_DAT2),a
	call	moon_wait
	ret


;********************************************
; write moonsound wave register
; in   : D = an address of register , E = data
; dest : AF

moon_wave_out:
	ld	a,d
	out	(MOON_WREG),a
	call	moon_wait
	ld	a,e
	out	(MOON_WDAT),a
	call	moon_wait
	ret

