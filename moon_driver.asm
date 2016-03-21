; MoonDriver for MoonSound / Programmed by BKC
; DRIVER (PAGE1)
; TAB:2 UTF-8


;********************************************
; defines
;********************************************
MOON_VERNUM: equ $0002

; MoonSound I/O
MOON_BASE:	equ	$00C4
MOON_REG1:	equ	MOON_BASE
MOON_DAT1:	equ	MOON_BASE+1
MOON_REG2:	equ	MOON_BASE+2
MOON_DAT2:	equ	MOON_BASE+3
MOON_STAT:	equ	MOON_BASE

; MoonSound Wave part I/O
MOON_WREG:	equ	$7E
MOON_WDAT:	equ	MOON_WREG+1

RAM_PAGE3: 	equ	$FE


USE_CH: 		equ	24+18
FM_BASECH:	equ	24

;********************************************
; MDR file format
;********************************************

MDR_ID:        equ $8000
MDR_PACKED:    equ $802A ; 1 if packed

MDR_DSTPCM:    equ $8030 ; destination address of PCM
MDR_STPCM:     equ $8031 ; PCM start bank
MDR_PCMBANKS:  equ $8032 ; PCM banks
MDR_LASTS:     equ $8033 ; PCM size of lastbank


S_DEVICE_FLAGS:	equ	$8007

S_TRACK_TABLE:	equ	$8010
S_TRACK_BANK:	  equ	S_TRACK_TABLE + 2
S_LOOP_TABLE:	  equ	S_TRACK_TABLE + 4
S_LOOP_BANK:	  equ	S_TRACK_TABLE + 6
S_VENV_TABLE:	  equ	S_TRACK_TABLE + 8
S_VENV_LOOP:	  equ	S_TRACK_TABLE + 10
S_PENV_TABLE:	  equ	S_TRACK_TABLE + 12
S_PENV_LOOP:	  equ	S_TRACK_TABLE + 14
S_NENV_TABLE:	  equ	S_TRACK_TABLE + 16
S_NENV_LOOP:	  equ	S_TRACK_TABLE + 18
S_LFO_TABLE:	  equ	S_TRACK_TABLE + 20
S_INST_TABLE:	  equ	S_TRACK_TABLE + 22
S_OPL3_TABLE:	  equ	S_TRACK_TABLE + 24

	org	$4000

;********************************************
; Entry points
;********************************************
	; $4000 初期化
	jp	moon_init_all

	; $4003 1フレーム実行 (1/60)
	jp	moon_proc_tracks

	; $4006 すべてのチャンネルをキーオフ
	jp	moon_seq_all_keyoff

	; $4009 H.TIMIのセット
	ret
	ret
	ret

	; $400C H.TIMIのリストア
	ret
	ret
	ret

	; $400F バージョン番号
	dw	MOON_VERNUM

	; $4011 バージョン文字列のアドレス
	dw	str_moondrv

	; $4013 PCM読み出し
	jp  moon_load_pcm

	org	$4020

str_moondrv:
	db "MOONDRIVER "
	db "VER 160321"
	db $0d,$0a,'$'

;********************************************
; work for debug
	IF DEFINED MOON_HOOT

MDB_BASE: equ $2F0

	ELSE

MDB_BASE:
	ds		$08

	ENDIF



;********************************************
; ドライバのすべてを初期化
;
moon_init_all:
	ld		hl, moon_work_start
	ld		de, moon_work_start + 1
	ld		bc, moon_work_end - moon_work_start - 1
	xor		a
	ld		(hl), a
	ldir

	call	moon_init
	jp	moon_seq_init


;********************************************
; moon_init
; MoonSound初期化
;
moon_init:
	; CONNECTION SEL
	ld	de, $0400
	call	moon_fm2_out

	; set 1 to NEW2, NEW
	ld	de, $0503
	call	moon_fm2_out

	; RHYTHM
	ld	de, $bd00
	call	moon_fm1_out

	; WaveTableのセット
	ld	de, $0210
	call	moon_wave_out

	ret


;********************************************
; ワークエリア
	db "work"

moon_work_start:

seq_dsel:
	db $00

seq_cur_ch:
	db $00
seq_dev_ch:
	db $00
seq_max_ch:
	db $00

seq_jmptable:
	dw $0000

seq_cur_bank:
	db $00
seq_opsel:
	db $00
seq_reg_bd:
	db $00
seq_tmp_note:
	db $00
seq_tmp_ch:
	db $00
seq_tmp_oct:
	db $00
seq_tmp_fnum:
	dw $0000

; 0でなければスキップ
seq_skip_flag:
	db $00


;********************************************
; チャンネルごとのワークエリア
;
seq_work:
seq_ch1_dsel:
	db $00
seq_ch1_devch:
	db $00
seq_ch1_opsel:
	db $00
seq_ch1_synth:
	db $00
seq_ch1_efx1:
	db $00
seq_ch1_cnt:
	db $00
seq_ch1_loop:
	db $00
seq_ch1_bank:
	db $00
seq_ch1_addr:
	dw $0000
seq_ch1_tadr:
	dw $0000
seq_ch1_tone:
	dw $0000
seq_ch1_key:
	db $00
seq_ch1_damp:
	db $00
seq_ch1_lfo:
	db $00
seq_ch1_lfo_vib:
	db $00
seq_ch1_ar_d1r:
	db $00
seq_ch1_dl_d2r:
	db $00
seq_ch1_rc_rr:
	db $00
seq_ch1_am:
	db $00
seq_ch1_note:
	db $00
seq_ch1_pitch:
	dw $0000
seq_ch1_p_ofs:
	dw $0000
seq_ch1_oct:
	db $00
seq_ch1_fnum:
	dw $0000
seq_ch1_reverb:
	db $00
seq_ch1_vol:
	db $00
seq_ch1_pan:
	db $00
seq_ch1_detune:
	db $00
seq_ch1_venv:
	db $00
seq_ch1_nenv:
	db $00
seq_ch1_penv:
	db $00
seq_ch1_nenv_adr:
	dw $0000
seq_ch1_penv_adr:
	dw $0000
seq_ch1_venv_adr:
	dw $0000
seq_work_end:

; IDX_DSEL
; 0 = OPL4, 1 = OPL3

IDX_DSEL:     equ (seq_ch1_dsel    - seq_work) ; Device Select
IDX_DEVCH:    equ (seq_ch1_devch   - seq_work) ; Device Channel
IDX_OPSEL:    equ (seq_ch1_opsel   - seq_work) ; Operator Select
IDX_SYNTH:    equ (seq_ch1_synth   - seq_work) ; FeedBack,Synth and OpMode
IDX_EFX1:     equ (seq_ch1_efx1    - seq_work) ; Effect flags
IDX_CNT:      equ (seq_ch1_cnt     - seq_work) ; Counter
IDX_LOOP:     equ (seq_ch1_loop    - seq_work) ; Loop
IDX_BANK:     equ (seq_ch1_bank    - seq_work) ; Which bank
IDX_ADDR:     equ (seq_ch1_addr    - seq_work) ; Address to data
IDX_TADR:     equ (seq_ch1_tadr    - seq_work) ; Address of a Tone Table
IDX_TONE:     equ (seq_ch1_tone    - seq_work) ; Tone number in OPL4
IDX_KEY:      equ (seq_ch1_key     - seq_work) ; data in Key register
IDX_DAMP:     equ (seq_ch1_damp    - seq_work) ; Damp switch
IDX_LFO:      equ (seq_ch1_lfo     - seq_work) ; LFO switch
IDX_LFO_VIB:  equ (seq_ch1_lfo_vib - seq_work) ; LFO and VIB
IDX_AR_D1R:   equ (seq_ch1_ar_d1r  - seq_work) ; AR and D1R
IDX_DL_D2R:   equ (seq_ch1_dl_d2r  - seq_work) ; DL and D2R
IDX_RC_RR:    equ (seq_ch1_rc_rr   - seq_work) ; RC and RR
IDX_AM:       equ (seq_ch1_am      - seq_work) ; AM
IDX_NOTE:     equ (seq_ch1_note    - seq_work) ; Note data
IDX_PITCH:    equ (seq_ch1_pitch   - seq_work) ; Pitch data
IDX_P_OFS:    equ (seq_ch1_p_ofs   - seq_work) ; Offset for pitch
IDX_OCT:      equ (seq_ch1_oct     - seq_work) ; Octave in OPL4
IDX_FNUM:     equ (seq_ch1_fnum    - seq_work) ; F-number in OPL4
IDX_REVERB:   equ (seq_ch1_reverb  - seq_work) ; Pseudo reverb
IDX_VOL:      equ (seq_ch1_vol     - seq_work) ; Volume in OPL4
IDX_PAN:      equ (seq_ch1_pan     - seq_work) ; Pan in OPL4
IDX_DETUNE:   equ (seq_ch1_detune  - seq_work) ; Detune
IDX_VENV:     equ (seq_ch1_venv    - seq_work) ; Volume envelope in data
IDX_NENV:     equ (seq_ch1_nenv    - seq_work) ; Vote envelope  in data
IDX_PENV:     equ (seq_ch1_penv    - seq_work) ; Pitch envelope in data
IDX_NENV_ADR: equ (seq_ch1_nenv_adr - seq_work)
IDX_PENV_ADR: equ (seq_ch1_penv_adr - seq_work)
IDX_VENV_ADR: equ (seq_ch1_venv_adr - seq_work)

IDX_VOLOP:    equ (seq_ch1_reverb  - seq_work) ; Volume Operator in connect
IDX_OLDAT1:   equ (seq_ch1_ar_d1r  - seq_work) ; Volume Data for 1stOP

;
; Note : IDX_SYNTH OxxFFFSS
;
; O : 4OP mode
; F : FeedBack
; S : SynthType (bit0 for 1st&2nd bit1 for 3rd&4th)
;

SEQ_WORKSIZE: equ (seq_work_end - seq_work)

	ds	(SEQ_WORKSIZE * (USE_CH-1))

moon_work_end:


;********************************************
	db	"PianoTone"			; Piano OPL4
piano_tone:
	db	$14,$27				; min -> max
	dw	$012c				; tone
	dw	7474				; pitch offset
	db 	$20,$f2,$13,$08,$00 ;regs


	db	$28,$2d
	dw	$012d
	dw	6816
	db	$20,$f2,$14,$08,$00

	db	$2e,$33
	dw	$012e
	dw	5899
	db	$20,$f2,$14,$08,$00

	db	$34,$39
	dw	$012f
	dw	5290
	db	$20,$f2,$14,$08,$00

	db	$3a,$3f
	dw	$0130
	dw	4260
	db	$20,$f2,$14,$08,$00

	db	$40,$45
	dw	$0131
	dw	3625
	db	$20,$f2,$14,$08,$00

	db	$46,$4b
	dw	$0132
	dw	3116
	db	$20,$f2,$14,$08,$00

	db	$4c,$52
	dw	$0133
	dw	2081
	db	$20,$f2,$14,$18,$00

	db	$53,$58
	dw	$0134
	dw	1444
	db  $20,$f3,$14,$18,$00

	db	$59,$6d
	dw	$0135
	dw	1915
	db  $20,$f4,$15,$08,$00

	; terminator ( both min and max should be zero )
	db	$00,$00
	dw	$0000
	dw	0
	db  $00,$00,$00,$00,$00

fm_fnumtbl:
	dw	345 ; C 523.300000
	dw	365 ; C+ 554.400000
	dw	387 ; D 587.300000
	dw	410 ; D+ 622.300000
	dw	435 ; E 659.300000
	dw	460 ; F 698.500000
	dw	488 ; F+ 740.000000
	dw	517 ; G 784.000000
	dw	547 ; G+ 830.600000
	dw	580 ; A 880.000000
	dw	614 ; A+ 932.300000
	dw	651 ; B 987.800000
	dw	690 ; C 1046.500000

;
; Tonedata for OPL3
;
opl3_testtone:
	db	$00 ; FBS
	db	$00 ; FBS2
	db	$00 ; BD

	db	$01 ; TREMOLO VIB SUS KSR MUL
	db	$00 ; KSL OL
	db	$11 ; AR DR
	db	$13 ; SL RR
	db	$01 ; WF

	db	$04 ;
	db	$00 ;
	db	$11 ;
	db	$18 ;
	db	$00 ; WF

	db	$01
	db	$3f
	db	$55
	db	$55
	db	$00

	db	$01
	db	$3f
	db	$55
	db	$55
	db	$00

fm_op2reg_tbl:
	db	$00 ; 0
	db	$01
	db	$02 ; 2
	db	$03
	db	$04 ; 4
	db	$05
	db	$08 ; 6
	db	$09
	db	$0A ; 8
	db	$0B
	db	$0C ; 10
	db	$0D
	db	$10 ; 12
	db	$11
	db	$12 ; 14
	db	$13
	db	$14 ; 16
	db	$15 ; 17



fm_opbtbl:
	db	$00 ; CH0
	db	$01 ; CH1
	db	$02 ; CH2
	db	$06 ; CH3
	db	$07 ; CH4
	db	$08 ; CH5
	db	$0c ; CH6
	db	$0d ; CH7
	db	$0e ; CH8
	db	$12 ; CH9
	db	$13 ; CH10
	db	$14 ; CH11
	db	$18 ; CH12
	db	$19 ; CH13
	db	$1a ; CH14
	db	$1e ; CH15
	db	$1f ; CH16
	db	$20 ; CH17

;********************************************
; BSMCH
fm_drum_fnum:
	dw $0120 ; B
	dw $0150 ; S
	dw $01c0 ; M
	dw $01c0 ; C
	dw $0150 ; H

fm_drum_fnum_map:
	db $06 ; B
	db $07 ; S
	db $08 ; M
	db $08 ; C
	db $07 ; H

fm_drum_oct:
	db $02 ; B
	db $02 ; S
	db $00 ; M
	db $00 ; C
	db $02 ; H

;////////////////////////////////////
; jump utility
;////////////////////////////////////

call_hl:
	jp	(hl)

; 自己書き換えキーオン
moon_key_on:
	jp	opl4_keyon

; 自己書き換えキーオフ
moon_key_off:
	jp	opl4_keyoff


;////////////////////////////////////
; Memory access routines
;////////////////////////////////////

;********************************************
; set page3 to the bank of current channel
; dest : AF
set_page3_ch:
	ld	a, (ix + IDX_BANK)
	jr	change_page3

;********************************************
; changes page3
; in   : A = page
; dest : AF
change_page3:

	srl	a
	add	a, $04 ; The system uses 4pages for initial work area
	out	(RAM_PAGE3), a
	ret

;********************************************
; get_table
; in   : A = index , HL = address
; out  : HL = (HL + (A * 2) )
; dest : AF,DE
get_table:
	ld	e, a
	ld	d, $00
	jr	get_table_hl_2de

;********************************************
; get_hl_table
; in   : HL = address
; out  : HL = (HL + (cur_ch * 2) )
; dest : AF,DE
get_hl_table:
	ld	a, (seq_cur_ch)
	ld	e, a
	ld	d, $00

get_table_hl_2de:
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a

	add	hl, de
	add	hl, de

	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a

	ret

;********************************************
; get_a_table
; in   : HL = address
; out  : A = (HL + (cur_ch * 2) )
; dest : HL,DE
get_a_table
	ld	a,(seq_cur_ch)
	ld	e,a
	ld	d,$00

	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a

	add	hl,de

	ld	a,(hl)

	ret


;********************************************
; moon_seq_init
; initializes all channel's work
; dest : ALL
moon_seq_init:
	; デバイス選択を無効状態にする
	ld		a, $ff
	ld		(seq_dsel), a

	xor		a
	ld		(seq_max_ch), a
	ld		(seq_cur_ch), a
	call	change_page3  ; Page to Top

	ld		a, (S_DEVICE_FLAGS)
	or		a
	jr		nz, skip_def_device
	ld		a, $01 ; OPL4のみがデフォルト
skip_def_device:
	ld		b, a

	ld		iy, fm_opbtbl
	ld		ix, seq_work

	; OPL4
	ld		d, $00 ; device id
	ld		e, $18 ; 24channels ; OPL4

	; OPL4音色初期化ルーチン
	ld		hl, init_opl4tone
	ld		(init_gen_adrs), hl

	rr		b
	call	c, seq_init_chan

	; OPL3
	inc		d
	ld		e, $12 ; 18channels

	; OPL3音色初期化ルーチン
	ld		hl, init_opl3tone
	ld		(init_gen_adrs), hl

	rr		b
	call	c, seq_init_chan

skip_use_opl3:
	ld		ix, seq_work
	ret

;********************************************
; seq_init_chan
; in   : D = device id, E = channels
; dest : AF,E
seq_init_chan:
	; デバイス内チャンネル番号
	xor		a
	ld		(seq_dev_ch), a

	; 使用チャンネル数を加算
	ld		a, (seq_max_ch)
	add		a, e
	ld		(seq_max_ch), a

seq_init_chan_lp:
	push	de
	call	init_common
	ld		hl, (init_gen_adrs)
	call	call_hl

	; 次のワークへ
	ld		de, SEQ_WORKSIZE
	add		ix, de

	pop		de

	; 次のチャンネルへ
	ld		a, (seq_dev_ch)
	inc		a
	ld		(seq_dev_ch), a

	; 次のトラックへ
	ld		a, (seq_cur_ch)
	inc		a
	ld		(seq_cur_ch), a
	dec		e
	jr		nz, seq_init_chan_lp
	ret

init_gen_adrs:
	dw		$0000

init_common:
	xor		a
	ld		(ix + IDX_CNT),a
	ld		a, d
	ld		(ix + IDX_DSEL), a
	ld		a, (seq_dev_ch)
	ld		(ix + IDX_DEVCH), a

	ld		a, $ff
	ld		(ix + IDX_VENV), a
	ld		(ix + IDX_PENV), a
	ld		(ix + IDX_NENV), a
	ld		(ix + IDX_DETUNE), a

	ld		hl, S_TRACK_TABLE
	call	get_hl_table
	ld		(ix + IDX_ADDR), l
	ld		(ix + IDX_ADDR + 1), h

	ld		hl, S_TRACK_BANK
	call	get_a_table
	ld		(ix + IDX_BANK), a
	ret

; OPL3音色初期化
init_opl3tone:
	ld		hl, opl3_testtone
	ld		(ix + IDX_TADR), l
	ld		(ix + IDX_TADR+1), h
	ld		a, $30
	ld		(ix + IDX_PAN), a
	ld		a, $02
	ld		(ix + IDX_VOLOP), a
	ld		a, $3f
	ld		(ix + IDX_VOL),a
	ld		a, (iy)
	ld		(ix + IDX_OPSEL),a
	inc		iy
	ret

; OPL4音色初期化
init_opl4tone:
	ld		hl, piano_tone
	ld		(ix + IDX_TADR),l
	ld		(ix + IDX_TADR+1),h
	xor		a
	ld		(ix + IDX_PAN),a
	ret

;********************************************
;seq_all_keyoff
;this makes all keys off
;
moon_seq_all_keyoff:
	xor		a
	ld		(seq_cur_ch), a
	ld		(seq_dev_ch), a

	call	moon_seq_all_release_fm


	ld		ix, seq_work
seq_all_keyoff_lp:
	; デバイスを切り替える
	call	moon_set_device

	ld		a, (ix + IDX_DEVCH)
	ld		(seq_dev_ch), a

	call  moon_key_off

	; 次のワークへ
	ld		de, SEQ_WORKSIZE
	add		ix, de

	; 次のチャンネルがあれば処理する
	ld		a, (seq_max_ch)
	ld		e, a
	ld		a, (seq_cur_ch)
	cp		e
	ret		nc

	inc		a
	ld		(seq_cur_ch), a

	jr		seq_all_keyoff_lp


; RRをすべてのFMチャンネルに設定する
moon_seq_all_release_fm:
  ; D = $80(reg adrs) E = (sl = $00, rr = $0f)
	ld		de, $800F
	ld		b, 18
	ld		hl, fm_opbtbl

	; channel loop
moon_set_rr_ch_lp:
	; read opsel tbl
	ld		a, (hl)
	ld		(seq_opsel), a
	inc		hl

	ld		c, 4
moon_set_rr_op_lp:
	; write fm op
	push	de
	call	moon_write_fmop
	pop		de

	; add opsel
	ld		a, (seq_opsel)
	add		a, $03
	ld		(seq_opsel), a

	;
	dec		c
	jr		nz, moon_set_rr_op_lp
	djnz	moon_set_rr_ch_lp
	ret

;********************************************
; moon_proc_tracks
; 次のフレームを処理 (1/60)
;
moon_proc_tracks:

	; マッパーメモリを変更
	xor		a
	call	change_page3

	; ワークエリアを先頭に
	ld		ix, seq_work
	xor		a
	ld		(seq_cur_ch), a

proc_tracks_lp:
	; デバイスを切り替える
	call	moon_set_device

	ld		a, (ix + IDX_DEVCH)
	ld		(seq_dev_ch), a

	call	proc_venv
	call	proc_penv
	call	proc_nenv

	call	proc_venv_reg
	call	proc_freq_reg

	call	seq_track

	; 次のトラックへ
	ld	de, SEQ_WORKSIZE
	add	ix, de

	ld	a, (seq_max_ch)
	ld	e, a
	ld	a, (seq_cur_ch)
	inc	a
	cp	e
	jr	nc, proc_tracks_end
	ld	(seq_cur_ch), a
	jr	proc_tracks_lp

proc_tracks_end:
	ld a, (seq_skip_flag)
	or a
	ret z
	jr moon_proc_tracks

; moon_set_device
; dest: AF, HL
; デバイスごとの処理アドレスをセットする
moon_set_device:
	ld	l, (ix + IDX_DSEL)
	ld	a, (seq_dsel)
	cp	l
	ret z

	; 以前とは違うデバイス
	ld	a, l
	ld	(seq_dsel), a

	or	a
	jr	z, proc_set_opl4

	cp	1
	jp	proc_set_opl3
	; jr	z, proc_set_opl3

	ret

proc_set_opl4:
	; テーブル
	ld	hl, opl4_jumptable
	ld	(seq_jmptable), hl
	; キーオン
	ld	hl, opl4_keyon
	ld	(moon_key_on + 1), hl
	; キーオフ
	ld	hl, opl4_keyoff
	ld	(moon_key_off + 1), hl
	; ノート
	ld	hl, opl4_note
	ld	(moon_note + 1), hl
	ret

proc_set_opl3:
	; テーブル
	ld	hl, opl3_jumptable
	ld	(seq_jmptable), hl
	; キーオン
	ld	hl, opl3_keyon
	ld	(moon_key_on + 1), hl
	; キーオフ
	ld	hl, opl3_keyoff
	ld	(moon_key_off + 1), hl
	; ノート
	ld	hl, opl3_note
	ld	(moon_note + 1), hl

	ret



;********************************************
;seq_track
; カウントダウンとトラック処理
;
seq_track:
	ld		a, (ix + IDX_CNT)
	or		a
	jr		z, seq_cnt_zero
	dec		a
	ld		(ix + IDX_CNT),a
	ret

; カウントゼロ
seq_cnt_zero:
	; 現在のチャンネル
	ld		a, (ix + IDX_DEVCH)
	ld		(seq_dev_ch), a

	ld		l, (ix + IDX_ADDR)
	ld		h, (ix + IDX_ADDR + 1)

seq_track_lp:
	; コマンドの読み出し
	call	set_page3_ch
	ld		a, (hl)
	inc		hl
	cp		$e0
	jr		nc, seq_command
	jp		seq_repeat_or_note

seq_command:
	ld		bc, seq_track_lp
	push	bc
	push	hl ; <- Preserve HL as pointer
	add		a, $20
	sla		a
	; ジャンプテーブルの読み出し
	ld		hl, (seq_jmptable)
	ld		c, a
	ld		b, $00
	add		hl, bc

	; テーブルから実行アドレスを読みだす
	ld		a, (hl)
	inc		hl
	ld		h, (hl)
	ld		l, a

	jp		(hl)

;********************************************
; seq_next
; preserves  address and do next
; in   : HL
; dest : AF
seq_next:
	ld	(ix + IDX_ADDR),l
	ld	(ix + IDX_ADDR+1),h
	jr	seq_track

	ret

;********************************************
; seq_repeat_or_note
;
; n < $90 =  note
; $A0     =  repeat_end
; $A1     =  repeat_esc

seq_repeat_or_note:
	cp	$90
	jr	c, moon_note

	cp	$a1
	jr	z,seq_repeat_esc

;********************************************
seq_repeat_end:
	ld	a,(ix + IDX_LOOP)
	cp	$01
	jr	z,seq_skip_rep_jmp

	or	a
	jr	nz,seq_skip_set_repcnt_end

	ld	a,(hl)    ; read repeat counter

seq_skip_set_repcnt_end:
	jr	seq_rep_jmp

;********************************************
seq_repeat_esc:
	ld	a,(ix + IDX_LOOP)
	cp	$01
	jr	z,seq_rep_jmp

	or	a
	jr	nz,seq_skip_set_repcnt_esc

	ld	a,(hl)      ; read repeat counter

seq_skip_set_repcnt_esc:
	jr	seq_skip_rep_jmp

seq_skip_rep_jmp:
	inc	hl
	dec	a
	ld	(ix + IDX_LOOP),a
	inc	hl  ; bank
	inc	hl  ; addr l
	inc	hl  ; addr h
	jr	seq_next

seq_rep_jmp:
	inc	hl
	dec	a
	ld	(ix + IDX_LOOP),a

	ld	bc,seq_next
	push	bc
	push	hl

	; 謎…。
	ld	hl,seq_bank ; go to address
	jp	(hl)

;********************************************
moon_note:
	jp opl4_note

; Note command
opl3_note:
	push	hl
	push	af
	xor	a
	call	change_page3
	pop	af
	ld	(ix + IDX_NOTE),a
	call 	moon_set_fmnote
	jr	set_note_fin

opl4_note:
	push	hl
	push	af
	xor	a
	call	change_page3
	pop	af
	call	conv_data_to_midi
	ld	(ix + IDX_NOTE),a
	call	moon_set_midinote

set_note_fin:
	call	set_page3_ch
	call	moon_key_on
	pop		hl

; note length
	ld	a, (hl)
	ld	(ix + IDX_CNT),a
	inc	hl
	jr	seq_next
;
;
read_cmd_length:
	pop	af
	ld	a, (hl)
	ld	(ix + IDX_CNT),a
	inc	hl
	jr	seq_next


opl4_jumptable:
	dw	seq_nop								; $e0 : Set drum note
	dw	seq_nop								; $e1 : Set drum bits
	dw	seq_jump							; $e2 :
	dw	seq_fbs								; $e3 : Set FBS
	dw	seq_tvp								; $e4 : Set TVP
	dw	seq_ld2ops_opl4				; $e5 : Load 2OP Instrument
	dw	seq_setop							; $e6 : Set opbase
	dw	seq_nop								; $e7 : Pitch shift
	dw	seq_nop								; $e8 :
	dw	seq_slar	 						; $e9 : Slar switch
	dw	seq_revbsw 						; $ea : Reverb switch / VolumeOP
	dw	seq_damp_opl4					; $eb : Damp switch / OPMODE
	dw	seq_nop								; $ec : LFO freq
	dw	seq_nop								; $ed : LFO mode
	dw	seq_bank							; $ee : Bank change
	dw	seq_lfosw							; $ef : Mode change
	dw	seq_pan_opl4					; $f0 : Set Pan
	dw	seq_inst_opl4					; $f1 : Load Instrument (4OP or OPL4)
	dw	seq_drum							; $f2 : Set Drum
	dw	seq_nop								; $f3 :
	dw	seq_wait							; $f4 : Wait
	dw	seq_skip_3 						; $f5 : Data Write
	dw	seq_nop								; $f6
	dw	seq_nenv							; $f7 : Note envelope
	dw	seq_penv	 						; $f8 : Pitch envelope
	dw	seq_skip_1						; $f9
	dw	seq_detune						; $fa : Detune
	dw	seq_nop								; $fb : LFO
	dw	seq_rest							; $fc : Rest
	dw	seq_volume						; $fd : Volume
	dw	seq_skip_1						; $fe : Not used
	dw	seq_loop							; $ff : Loop

opl3_jumptable:
	dw	seq_drumnote					; $e0 : Set drum note
	dw	seq_drumbit 					; $e1 : Set drum bits
	dw	seq_jump							; $e2 :
	dw	seq_fbs								; $e3 : Set FBS
	dw	seq_tvp								; $e4 : Set TVP
	dw	seq_ld2ops_opl3				; $e5 : Load 2OP Instrument
	dw	seq_setop							; $e6 : Set opbase
	dw	seq_nop								; $e7 : Pitch shift
	dw	seq_nop								; $e8 :
	dw	seq_slar							; $e9 : Slar switch
	dw	seq_revbsw 						; $ea : Reverb switch / VolumeOP
	dw	seq_damp_opl3	 				; $eb : Damp switch / OPMODE
	dw	seq_nop								; $ec : LFO freq
	dw	seq_nop								; $ed : LFO mode
	dw	seq_bank							; $ee : Bank change
	dw	seq_lfosw							; $ef : Mode change
	dw	seq_pan_opl3					; $f0 : Set Pan
	dw	seq_inst_opl3					; $f1 : Load Instrument (4OP or OPL4)
	dw	seq_drum							; $f2 : Set Drum
	dw	seq_nop								; $f3 :
	dw	seq_wait							; $f4 : Wait
	dw	seq_data_write_opl3		; $f5 : Data Write
	dw	seq_nop								; $f6
	dw	seq_nenv							; $f7 : Note	envelope
	dw	seq_penv							; $f8 : Pitch envelope
	dw	seq_skip_1						; $f9
	dw	seq_detune						; $fa : Detune
	dw	seq_nop								; $fb : LFO
	dw	seq_rest							; $fc : Rest
	dw	seq_volume						; $fd : Volume
	dw	seq_skip_1						; $fe : Not used
	dw	seq_loop							; $ff : Loop

;********************************************
; Volume envelope stuff
;
start_venv:
	ld	a,(ix + IDX_VENV)
	cp	$ff
	ret	z

	call	set_venv_head
	jr	proc_venv_start

proc_venv:
	ld	a,(ix + IDX_VENV)
	cp	$ff
	ret	z

proc_venv_start:
	ld	l,(ix + IDX_VENV_ADR)
	ld	h,(ix + IDX_VENV_ADR + 1)
	ld	a,l
	or	h
	ret	z

	call	read_effect_value
	cp	$ff
	jr	z,proc_venv_end
	inc	hl
	ld	(ix + IDX_VENV_ADR),l
	ld	(ix + IDX_VENV_ADR + 1),h

	ld	(ix + IDX_VOL),a
	ret


proc_venv_end:
	jp	set_venv_loop

;********************************************
; Set venv's volume to register actually
;
proc_venv_reg:
	ld	a,(ix + IDX_VENV)
	cp	$ff
	ret	z
	jp	moon_set_vol_ch


;********************************************
; Pitch envelope stuff
;
start_penv:
	ld	a,(ix + IDX_PENV)
	cp	$ff
	ret	z

	call	set_penv_head
	jr	proc_penv_start


proc_penv:
	ld	a,(ix + IDX_PENV)
	cp	$ff
	ret	z
proc_penv_start:
	ld	l,(ix + IDX_PENV_ADR)
	ld	h,(ix + IDX_PENV_ADR + 1)

	call	read_effect_value
	cp	$ff
	jr	z,proc_penv_end

	inc	hl
	ld	(ix + IDX_PENV_ADR),l
	ld	(ix + IDX_PENV_ADR + 1),h

	push	af
	ld	a, (ix + IDX_DSEL)
	or	a
	jr	nz,proc_penv_opl3

proc_penv_opl4:
	pop	af

	ld	l,(ix + IDX_PITCH)
	ld	h,(ix + IDX_PITCH + 1)
	call	add_freq_offset
	ld	(ix + IDX_PITCH),l
	ld	(ix + IDX_PITCH+1),h

	jp	moon_calc_opl4freq


proc_penv_end:
	jp	set_penv_loop

proc_penv_opl3:
	pop	af
	ld	l,(ix + IDX_FNUM)
	ld	h,(ix + IDX_FNUM + 1)
	call	add_freq_offset

	ld	a,h
	cp	$80
	jr	nc,penv_fm_set_fnum

	ld	de,346
	call	comp_hl_de
	jr	c,penv_fm_dec_oct
	jr	z,penv_fm_dec_oct

	ld	de,693
	call	comp_hl_de
	jr	nc,penv_fm_inc_oct
	jr	z, penv_fm_inc_oct

penv_fm_set_fnum:
	ld	(ix + IDX_FNUM), l
	ld	(ix + IDX_FNUM+1), h
	jp	moon_key_fmfreq

penv_fm_dec_oct:
	; hl < de
	dec	(ix + IDX_OCT)
	add	hl,de
	call	comp_hl_de
	jr	c,penv_fm_dec_oct

	jr	penv_fm_set_fnum

penv_fm_inc_oct:
	; hl > de
	ld	bc,346
penv_fm_inc_oct_lp:
	inc	(ix + IDX_OCT)
	xor	a
	sbc	hl,bc
	call	comp_hl_de
	jr	nc,penv_fm_inc_oct_lp
	jr	penv_fm_set_fnum


;********************************************
; comp_hl_de
; Compare hl with de
; in   : HL,DE
; out  : C = (HL < DE), NC = (HL > DE), Z = (HL == DE)
; dest : AF
comp_hl_de:
	ld	a,h
	cp	d
	ret	nz
	ld	a,l
	cp	e
	ret

;********************************************
; Note envelope stuff
;
start_nenv:
	ld	a,(ix + IDX_NENV)
	cp	$ff
	ret	z

	call	set_nenv_head
	jr	proc_nenv_start

proc_nenv:
	ld	a,(ix + IDX_NENV)
	cp	$ff
	ret	z

proc_nenv_start:
	ld	l, (ix + IDX_NENV_ADR)
	ld	h, (ix + IDX_NENV_ADR + 1)

	call	read_effect_value
	cp	$ff
	jp	z, set_nenv_loop

	inc	hl
	ld	(ix + IDX_NENV_ADR), l
	ld	(ix + IDX_NENV_ADR + 1), h

	push	af
	ld	a, (ix + IDX_DSEL)
	or	a
	jr	nz, proc_nenv_fm
	jr	proc_nenv_opl4

proc_nenv_opl4:
	pop	af
	bit	7, a
	jr	nz, proc_nenv_nega_opl4

	add	a, (ix + IDX_NOTE)
	ld	(ix + IDX_NOTE), a
proc_nenv_opl4_setnote
	call	moon_calc_midinote
	jp	moon_calc_opl4freq

proc_nenv_nega_opl4:
	and	$7f
	ld	e, a
	ld	a, (ix + IDX_NOTE)
	sub	e
	ld	(ix + IDX_NOTE), a
	jr	proc_nenv_opl4_setnote

proc_nenv_fm:
	pop	af
	ld	b, $00
	bit	7, a
	jr	nz, proc_nenv_fm_nega
proc_nenv_fm_lp1:
	cp	$0c
	jr	c, proc_nenv_fm_add
	sub	$0c
	inc	b
	jr	proc_nenv_fm_lp1
proc_nenv_fm_add:
	ld	c, a ; C = (note % 12)
	ld	a, (ix + IDX_NOTE)
	and	$0f
	add	a, c
	cp	$0c
	jr	c, skip_nenv_inc_oct
	add	a, $04
	and	$0f
	inc	b
skip_nenv_inc_oct:
	ld	c, a ; C = (note & 0x0f)
	ld	a, b ; B = oct
	rlca
	rlca
	rlca
	rlca
	ld	b, a
	ld	a, (ix + IDX_NOTE)
	and	$f0
	add	a, b
	or	c
	ld	(ix + IDX_NOTE), a
	call	moon_set_fmnote
	jp	moon_key_fmfreq

proc_nenv_fm_nega:
	and	$7f

proc_nenv_fm_nega_lp1:
	cp	$0c
	jr	c,proc_nenv_fm_sub
	sub	$0c
	inc	b
	jr	proc_nenv_fm_nega_lp1
proc_nenv_fm_sub:
	ld	c, a ; C = (note % 12)
	ld	a,(ix + IDX_NOTE)
	and	$0f
	sub	c
	jr	nc,skip_nenv_dec_oct
	sub	$04
	and	$0f
	inc	b
skip_nenv_dec_oct:
	ld	c,a ; C = (note & 0x0f)
	ld	a,b ; B = oct
	rlca
	rlca
	rlca
	rlca
	ld	b,a
	ld	a,(ix + IDX_NOTE)
	and	$f0
	sub	b
	or	c
	ld	(ix + IDX_NOTE),a
	call	moon_set_fmnote
	jp	moon_key_fmfreq



;********************************************
;Set frequency to registers actually
;
proc_freq_reg:
	ld	a,(ix + IDX_PENV)
	cp	$ff
	jr	nz,proc_freq_to_moon
	ld	a,(ix + IDX_NENV)
	cp	$ff
	jr	nz,proc_freq_to_moon
	ret
proc_freq_to_moon:
	jp	moon_set_freq_ch



;********************************************
; Subroutines to process sequence
; dest : AF, BC, DE

; No Program
seq_nop:
	pop	hl
	ret

; Skip 1 argument
seq_skip_1:
	pop	hl
	inc	hl
	ret

; Skip 2 arguments
seq_skip_2:
	pop	hl
	inc	hl
	inc	hl
	ret

; Skip 3 arguments
seq_skip_3:
	pop	hl
	inc	hl
	inc	hl
	ret

; cmd $FF : loop point
seq_loop:
	pop	hl
	xor	a
	call	change_page3

	ld	hl, S_LOOP_TABLE
	call	get_hl_table

	push	hl

	ld	hl, S_LOOP_BANK
	call	get_a_table
	ld	(ix + IDX_BANK),a
	call	change_page3

	pop	hl


	ret


; cmd $FD : volume
seq_volume:
	pop	hl

	ld	a,(hl)
	ld	(ix + IDX_VENV),a

	bit	7,a
	jr	z,seq_venv
	and	$7f

	ld	(ix + IDX_VOL),a

	ld	a, $ff
	ld	(ix + IDX_VENV),a  ; venv = off

	call	moon_set_vol_ch

	inc	hl
	ret

seq_venv:

	call	set_venv_head

	inc	hl
	ret

; cmd $FC : rest
seq_rest:
	pop		hl
	call	moon_key_off
	jp		read_cmd_length

; cmd $FA : detune
seq_detune:
	pop	hl

	ld	a,(hl)
	ld	(ix + IDX_DETUNE),a
	inc	hl
	ret

; cmd $F8 : pitch env
seq_penv:
	pop	hl

	ld	a, (hl)
	inc	hl

	ld	(ix + IDX_PENV),a
	cp	$ff
	call	nz,set_penv_head

	ret

; cmd $F7 : note env
seq_nenv:
	pop	hl

	ld	a, (hl)
	inc	hl

	ld	(ix + IDX_NENV), a
	cp	$ff
	call	nz,set_nenv_head

	ret


; cmd $F5 : data_write
; in: low, high, data
seq_data_write_opl3:
	pop	hl
	ld	a, (hl)
	ld	d, a ; Address Low
	inc	hl
	ld	a, (hl) ; Address High
	or	a
	jr	z, write_data_cur_fm ; (a >> 8) == 0
	dec a
	jr	z, write_data_fm1 ; (a >> 8) == 1
	dec a
	jr	z, write_data_fm2 ; (a >> 8) == 2
	inc	hl
	ret

write_data_cur_fm:
	inc	hl
	ld	a, (hl)
	ld	e, a ; Data
	inc	hl

	; チャンネルによって振り分ける
	ld	a, (seq_dev_ch)
	cp	$9
	jp	c, moon_fm1_out
	jp	moon_fm2_out

write_data_fm1:
	inc	hl
	ld	a, (hl)
	ld	e, a ; Data
	inc	hl
	jp	moon_fm1_out

write_data_fm2:
	inc	hl
	ld	a, (hl)
	ld	e, a ; Data
	inc	hl
	jp	moon_fm2_out

; cmd $F4 : wait
seq_wait:
	pop	hl
	jp	read_cmd_length

; cmd $F2 : drum
seq_drum:
	pop	hl
	ld	a, (hl)
	and	$1f
	ld	e, a
	ld	a, (seq_reg_bd)
	and	$e0
	or	e
	ld	(seq_reg_bd), a
	ld	e, a
	ld	d, $bd
	call	moon_fm1_out
	inc	hl
	ret

; cmd $E1 : drumbit
seq_drumbit:
	pop	hl

	; drums key-off
	ld	a, (hl)
	and	$1f
	xor	$ff

	; e = mask bits of drums
	ld	e, a
	ld	a, (seq_reg_bd)
	and	e
	ld	(seq_reg_bd), a
	ld	e, a
	ld	d, $bd
	call	moon_fm1_out

	; set fnum
	push	hl
	ld	a, (hl)
	and	$1f

	ld	c, $00
	ld	b, $05

	rlca
	rlca
	rlca

; A = drum bits, BC = count
drumbit_fnum_lp:
	rlca

	jr	nc, drumbit_fnum_next
	push	af
	push	bc
	call	drumbit_set_fnum ; set Fnum for drums
	pop	bc
	pop	af

drumbit_fnum_next:
	inc	c
	djnz	drumbit_fnum_lp

	pop	hl

	; skip if jump flag is true
	ld	a, (seq_skip_flag)
	or	a
	jr	nz, drumbit_skip_keyon

	; drums key-on
	ld	a, (hl)
	and	$1f
	ld	e, a
	ld	a, (seq_reg_bd)
	and	$e0
	or	e
	ld	(seq_reg_bd), a
	ld	e, a
	ld	d, $bd
	call	moon_fm1_out

drumbit_skip_keyon:
	; length check
	ld	a, (hl)
	and $80 ; Lxxxxxxx L = the command has length
	jr	nz, drumbit_with_length
	inc	hl
	ret

; drumbit with length
drumbit_with_length:
	inc hl
	jp	read_cmd_length

;
; Set Fnum for drum
; C = index
; dest : almost all
drumbit_set_fnum:
	; fnum
	ld	hl, fm_drum_fnum
	ld	b, $00
	add	hl, bc
	add	hl, bc
	ld	a, (hl)
	ld	(seq_tmp_fnum), a
	inc	hl
	ld	a, (hl)
	ld	(seq_tmp_fnum + 1), a

	; oct
	ld	hl, fm_drum_oct
	add	hl, bc
	ld	a, (hl)
	ld	(seq_tmp_oct), a

	; ch
	ld	hl, fm_drum_fnum_map
	add	hl, bc
	ld	a, (hl)
	ld	(seq_tmp_ch), a

	; write FnumL
	call	moon_key_write_fmfreq_base

	ld	e, a
	ld	d, $b0
	ld	a, (seq_tmp_ch)

	; write FnumH and BLK
	jp	moon_write_fmreg_nch


; cmd $E0 : drum note
seq_drumnote:
	pop	hl

	; set fnum
	ld	a, (hl) ; drum bits
	and	$1f

	push	af
	inc	hl
	ld	a, (hl) ; note
	ld	(seq_tmp_note), a
	inc	hl
	pop	af

	push	hl

	ld	c, $00
	ld	b, $05

	rlca
	rlca
	rlca

; A = drum bits, BC = count
drumnote_lp:
	rlca

	jr	nc, drumnote_next
	push	af
	push	bc
	call	drumnote_fnum ; set Fnum for drums
	pop	bc
	pop	af

drumnote_next:
	inc c
	djnz	drumnote_lp

	pop	hl
	inc	hl
	ret

; C = index
; dest: AF, BC, HL
drumnote_fnum:
	push	bc
	ld	a, (seq_tmp_note)
	call	moon_calc_opl3note
	pop	bc

	; oct
	ld	b, $00
	ld	hl, fm_drum_oct
	add	hl, bc
	ld	a, (seq_tmp_oct)
	ld	(hl), a

	; fnum
	ld	hl, fm_drum_fnum
	add	hl, bc
	add	hl, bc
	ld	a, (seq_tmp_fnum)
	ld	(hl), a
	inc	hl
	ld	a, (seq_tmp_fnum + 1)
	ld	(hl), a

	ret


; cmd $F1 : Load instrument
seq_inst_opl3:
	pop	hl
	ld	a, (hl)

	push	af
	xor	a
	call	change_page3

	; Load OPL3 instrument
	pop	af
	push	hl
	ld	hl, S_OPL3_TABLE
	call	get_table

	ld	(ix + IDX_TADR), l
	ld	(ix + IDX_TADR+1), h

	; set tone to FM
	call	moon_set_fmtone

	jr	seq_inst_fin

; cmd $F1 : Load instrument
seq_inst_opl4:
	pop		hl
	ld		a, (hl)

	push	af
	xor		a
	call	change_page3

	pop		af
	push	hl
	ld		hl, S_INST_TABLE
	call	get_table

	ld		(ix + IDX_TADR), l
	ld		(ix + IDX_TADR+1), h

seq_inst_fin:
	call	set_page3_ch
	pop		hl

	inc		hl
	ret

; cmd $F0 : pan
seq_pan_opl3:
	pop		hl
	ld		a,(hl)
	and		$0f
	rlca
	rlca
	rlca
	rlca
	ld		(ix + IDX_PAN), a ; PPPPxxxx
	call	moon_write_fmpan ; Write PAN to FM

	jr		seq_pan_fin

seq_pan_opl4:
	pop		hl

	ld		a, (hl)
	ld		(ix + IDX_PAN), a
seq_pan_fin:
	inc		hl
	ret

; cmd $EF : mode change
seq_lfosw:
	pop	hl

	ld	a,(hl)
	ld	(ix + IDX_LFO),a
	inc	hl
	ret


; cmd $EE : change bank
seq_bank:
	pop	hl

	ld	a,(hl) ; read number of bank
	inc	hl

	push	af

	ld	a,(hl) ; read address
	inc	hl
	ld	h,(hl)
	ld	l,a

	pop	af

	ld	(ix + IDX_BANK),a
	call	change_page3
	ret

; cmd $EB : damp switch / OPMODE
seq_damp_opl3:
	pop		hl

	ld	a,(hl)
	and	$3f
	ld	e,a
	ld	d,$04
	call	moon_fm2_out
	jr	seq_damp_fin

seq_damp_opl4:
	pop		hl
	ld		a,(hl)
	ld		(ix + IDX_DAMP),a

seq_damp_fin:
	inc		hl
	ret

; cmd $EA : reverb sw / VolumeOP
seq_revbsw:
	pop	hl
	ld	a,(hl)
	ld	(ix + IDX_REVERB),a
	inc	hl
	ret

; cmd $E9 : slar sw
seq_slar:
	pop	hl
	set	0,(ix + IDX_EFX1)
	ret


; cmd $E6 : set opbase
seq_setop:
	pop	hl
	ld	a, (hl)
	ld	(ix + IDX_OPSEL), a
	inc	hl
	ret

; cmd $E5 : load 2ops
seq_ld2ops_opl4:
	pop		hl
	inc		hl
	ret

seq_ld2ops_opl3:
	pop		hl

	ld	a,(hl)

	push	af
	xor	a
	call	change_page3
	pop	af

	push	hl
	ld	hl, S_OPL3_TABLE
	call	get_table

	ld	(ix + IDX_TADR), l
	ld	(ix + IDX_TADR+1), h

	; Set 2OP tone to FM
	call	moon_set_fmtone2

	call	set_page3_ch
	pop		hl
	inc		hl
	ret


; cmd $E4 : tvp
seq_tvp:
	pop	hl
	ld	a, (hl)
	and	$07
	rrca
	rrca
	rrca
	ld	e, a
	ld	a, (seq_reg_bd)
	and	$1f
	or	e

	ld	(seq_reg_bd), a
	ld	e, a
	ld	d, $bd
	call	moon_fm1_out

	inc	hl
	ret

; cmd $E3 : fb
seq_fbs:
	pop	hl
	ld	a, (hl)
	and	$7
	rlca
	rlca
	ld	e, a
	ld	a,(ix + IDX_SYNTH)
	and	$e3
	or	e
	ld	(ix + IDX_SYNTH),a
	inc	hl
	ret

; cmd $E2 : set jump flag
seq_jump:
	pop	hl
	ld	a, (hl)
	ld (seq_skip_flag), a
	inc	hl
	ret


;********************************************
; pause_venv
; dest : AF
pause_venv:
	xor	a
	ld	(ix + IDX_VENV_ADR), a
	ld	(ix + IDX_VENV_ADR+1), a
	ret

;********************************************
; read_effect_table
; in   : A  = index
;      : HL = table address
;      : DE = pointer to value in work
; out  : (ix + de) = (HL + 2A)
; dest : AF
read_effect_table:
	push	ix
	add	ix, de

	push	af
	xor	a
	call	change_page3
	pop	af

	call	get_table

	ld	(ix), l
	ld	(ix+1), h

	pop	ix
	call	set_page3_ch
	ret


;********************************************
; set_venv_loop
; dest : AF,DE
set_venv_loop:
	push	hl
	ld	hl, S_VENV_LOOP
	jr	set_venv_hl

;********************************************
; set_venv_head
; dest : AF,DE
set_venv_head:
	push	hl
	ld	hl, S_VENV_TABLE
set_venv_hl:
	ld	de, IDX_VENV_ADR
	ld	a, (ix + IDX_VENV)
	and	$7f
	call	read_effect_table
	pop	hl
	ret


;********************************************
; set_penv_loop
; dest : AF, DE
set_penv_loop:
	push	hl
	ld	hl, S_PENV_LOOP
	jr	set_penv_hl

;********************************************
; set_penv_head
; dest : AF, DE
set_penv_head:
	push	hl
	ld	hl, S_PENV_TABLE
set_penv_hl:
	ld	de, IDX_PENV_ADR
	ld	a, (ix + IDX_PENV)
	call	read_effect_table
	pop	hl
	ret

;********************************************
; set_nenv_loop
; dest : AF, DE
set_nenv_loop:
	push	hl
	ld	hl, S_NENV_LOOP
	jr	set_nenv_hl

;********************************************
; set_nenv_head
; dest : AF, DE
set_nenv_head:
	push	hl
	ld	hl, S_NENV_TABLE
set_nenv_hl:
	ld	de, IDX_NENV_ADR
	ld	a, (ix + IDX_NENV)
	call	read_effect_table
	pop	hl
	ret



;********************************************
; read_effect_value
; read_effect_value
; in  : HL = address
; out : A = data
read_effect_value:
	xor	a
	call	change_page3

	ld	a, (hl)
	push	af
	call	set_page3_ch
	pop	af
	ret

;********************************************
; conv_data_to_midi
; Converts data to midi note
; in   : A = data ($40 = o4c)
; out  : A = midi note
; dest : AF,DE

conv_data_to_midi:
	ld	d,$00
	ld	e,a

	rrca
	rrca
	rrca
	rrca
	and	$0f
	ld	d,a
	jr	z,skip_conv_midi_lp
	xor	a
conv_midi_lp:
	add	a,$0c
	dec	d
	jr	nz,conv_midi_lp
skip_conv_midi_lp:
	ld	d,a
	ld	a,e
	and	$0f
	add	a,d
	add	a,$0c
	ret



;********************************************
; oct_div
; octave divider
; in   : H = pitch / 0x100
; out  : L = octave
; dest : AF
oct_div:
	ld	a,h
	ld	l,$00

oct_div_lp:
	add	a,$fa
	ret	nc
	inc	l
	jr	oct_div_lp

;********************************************
; make_fnum
; Make F-number from pitch
; F-num = pitch / $600
; in   : HL = pitch
; out  : HL = f-num
; dest : AF, DE

make_fnum:
	ld	de, $fa00
make_fnum_lp:
	add	hl, de
	jr	c, make_fnum_lp
	ld	de, $0600
	add	hl, de

	ex	de,hl

	ld	hl, freq_table
	add	hl, de
	add	hl, de

	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a

	ret

;********************************************
; moon_set_fmtone2
; load and set 2 oprators from data in table
; in   : work
; dest : DE
;
moon_set_fmtone2:
	push	af
	push	bc
	push	hl

	; repeat 2times
	ld	c, $02

	jr	moon_set_fmtone_start_lp

;********************************************
; moon_set_fmtone
; load and set 4 oprators from data in table
; in   : work
; dest : DE
;
moon_set_fmtone:
	push	af
	push	bc
	push	hl

 ; repeat 4 times
	ld	c, $04

moon_set_fmtone_start_lp:
	ld	l, (ix + IDX_TADR)
	ld	h, (ix + IDX_TADR+1)

	ld	a, (ix + IDX_OPSEL)
	ld	(seq_opsel), a

	; FBS   store to IDX_SYNTH( OxxFFFSS )
	ld	a, (hl)
	and	$0e
	rlca
	ld	e, a
	ld	a, (hl)
	and	$01
	or	e
	ld	e, a
	inc	hl

	ld	a, (ix + IDX_SYNTH)
	and	$e2
	or	e
	ld	(ix + IDX_SYNTH), a ; xxxFFFxS

	ld	a, c
	cp	$04
	jr	nz, fmtone_skip_set_fbs2

	; FBS-2  Store SynthType for 4OP
	ld	a, (hl)
	and	$01
	rlca
	or	$80    ; 4OP flag
	ld	e, a

	ld	a, (ix + IDX_SYNTH)
	and	$7d    ; mask for 4OP and 2nd SynthType
	or	e
	ld	(ix + IDX_SYNTH), a ; OxxFFFSS
	inc	hl

	jr	fmtone_set_tvp

fmtone_skip_set_fbs2:
	ld	a, (ix + IDX_SYNTH)
	and	$7f
	ld	(ix + IDX_SYNTH), a
	inc	hl

fmtone_set_tvp:
	; TYP in W/WX is removed
	inc	hl
	call	moon_load_fmvol

moon_set_fmtone_lp1:
	call	moon_set_fmop
	ld	a, (seq_opsel)
	add	a, $03
	ld	(seq_opsel), a

	dec	c
	jr	nz, moon_set_fmtone_lp1

	call moon_write_fmpan

	pop	hl
	pop	bc
	pop	af
	ret

moon_load_fmvol:
	push	hl
	push	bc
	push	ix
	inc	hl ; skip Reg.$20
	ld	de, $0005
moon_load_fmvol_lp:
	ld	a, (hl)
	ld	(ix + IDX_OLDAT1), a
	inc	ix
	add	hl, de
	dec	c
	jr	nz, moon_load_fmvol_lp

	pop	ix
	pop	bc
	pop	hl
	ret

moon_set_fmop:
	ld	a, (hl)
	ld	e, a
	ld	d, $20
	call	moon_write_fmop
	inc	hl
	ld	a, (hl)
	ld	e, a
	ld	d, $40
	call	moon_write_fmop  ; OL
	inc	hl
	ld	a, (hl)
	ld	e, a
	ld	d, $60
	call	moon_write_fmop
	inc	hl
	ld	a, (hl)
	ld	e, a
	ld	d, $80
	call	moon_write_fmop
	inc	hl
	ld	a, (hl)
	ld	e, a
	ld	d, $e0
	call	moon_write_fmop
	inc	hl
	ret

;********************************************
; moon_tonesel
; Select tone number from table ( OPL4 )
; in   : work
; dest : flags, HL
;
moon_tonesel:
	ld	l,(ix + IDX_TADR)
	ld	h,(ix + IDX_TADR+1)
tonesel_lp01:
	push	af
	push	hl
	ld	a,(hl)
	inc	hl
	or	(hl)
	jr	z,tonesel_fin ; if min == 0 && max == 0
	pop	hl
	pop	af

	cp	(hl)
	jr	c,tonesel_skip01    ; if a < (hl)
	inc	hl
	cp	(hl)
	jr	c,tonesel_loadtone  ; if a < (hl)
	jr	z,tonesel_loadtone  ; if a == (hl)
	jr	tonesel_skip02

tonesel_fin:
	pop	hl
	pop	af
	ret

tonesel_skip01:
	inc	hl
tonesel_skip02:
	push	de
	ld	de, $000a
	add	hl, de
	pop	de

	jr	tonesel_lp01

tonesel_loadtone:
	push	af
	inc	hl
	ld	a,(hl)
	ld	(ix + IDX_TONE),a
	inc	hl
	ld	a,(hl)
	ld	(ix + IDX_TONE+1),a
	inc	hl
	ld	a,(hl)
	ld	(ix + IDX_P_OFS),a
	inc	hl
	ld	a,(hl)
	ld	(ix + IDX_P_OFS+1),a

	inc	hl
	ld	a,(hl)
	ld	(ix + IDX_LFO_VIB),a
	inc	hl
	ld	a,(hl)
	ld	(ix + IDX_AR_D1R),a
	inc	hl
	ld	a,(hl)
	ld	(ix + IDX_DL_D2R),a
	inc	hl
	ld	a,(hl)
	ld	(ix + IDX_RC_RR),a
	inc	hl
	ld	a,(hl)
	ld	(ix + IDX_AM),a

	pop	af
	ret

;********************************************
; moon_calc_opl4freq
; in   : HL = pitch
; dest : AF,HL

moon_calc_opl4freq:
	push	hl
	call	oct_div
	ld	a,l
	add	a,$f8
	ld	(ix + IDX_OCT),a
	pop	hl

	call	make_fnum

	ld	(ix + IDX_FNUM),l
	ld	(ix + IDX_FNUM+1),h
	ret

;********************************************
; moon_calc_midinote
; calclulates freq from note
; in   : A = note ( 04c = 0x3c )
; out  : work
; dest : AF,DE

moon_calc_midinote:
	add	a,$c4	; a -= $3c

	ld	l,$00
	srl	a
	ld	h,a
	rr	l
	and	$40
	jr	z,skip_set_nega ; if a >= $80 then it's negative
	ld	a,h
	or	$80
	ld	h,a
skip_set_nega:
	ld	de,$1e00 ; 7680
	add	hl,de
	ld	e,(ix + IDX_P_OFS)
	ld	d,(ix + IDX_P_OFS+1)
	add	hl,de

	ld	a,(ix + IDX_DETUNE)
	call	add_freq_offset

skip_detune:
	ld	a,h
	cp	$60
	jr	c,skip_set_pitch ; if a < $60
	ld	hl,$5fff
skip_set_pitch:
	ld	(ix + IDX_PITCH),l
	ld	(ix + IDX_PITCH + 1),h
	ret

;********************************************
; add_freq_offset
; HL = HL + VALUE
; in : A ( detune data )
; dest : DE

add_freq_offset:

	cp	$ff
	ret	z

	bit	7,a
	jr	nz,add_freq_nega

	ld	e,a
	ld	d,$00
	jr	add_freq_de

add_freq_nega:
	and	$7f
	ld	d,$00
	ld	e,a
	xor	a
	sub	e
	jr	nc,add_freq_de
	dec	d
add_freq_de:
	ld	e,a
	add	hl,de
	add	hl,de
	ret



;********************************************
; moon_set_midinote
; in : A = note
;
moon_set_midinote:
	bit	0,(ix + IDX_EFX1)
	call	z,moon_tonesel
	call	moon_calc_midinote
	jp	moon_calc_opl4freq


;********************************************
; moon_set_fmnote
; in   : A = note
; dest : AF, HL, BC
moon_set_fmnote:
	call	moon_calc_opl3note

	; oct
	ld	a, (seq_tmp_oct)
	ld	(ix + IDX_OCT), a

	; Fnum
	ld	hl, (seq_tmp_fnum)
	ld	(ix + IDX_FNUM), l
	ld	(ix + IDX_FNUM+1), h
	ret

;********************************************
; moon_calc_opl3note
; in : A = note , (ix + IDX_DETUNE)
; out : (seq_tmp_fnum), (seq_tmp_oct)
; dest AF, BC, HL

moon_calc_opl3note:
	push	af
	and	$0f
	cp	$0c
	jr	c, fm_load_fnumtbl
	sub	$0c
fm_load_fnumtbl:
	ld	hl, fm_fnumtbl
	ld	c, a
	ld	b, $00
	add	hl, bc
	add	hl, bc
	ld	a, (hl)
	ld	(seq_tmp_fnum), a
	inc	hl
	ld	a, (hl)
	ld	(seq_tmp_fnum + 1), a
	pop	af
	rra
	rra
	rra
	rra
	and	$0f
	ld	(seq_tmp_oct), a

	; Add detune effect
	ld	hl, (seq_tmp_fnum)

	ld	a, (ix + IDX_DETUNE)
	call	add_freq_offset

	ld	(seq_tmp_fnum), hl

	ret

;********************************************
; moon_write_fmop
; Write an OPL3 reg for op
; (opsel)
; in   : seq_opsel, D = addr, E = data
; dest : AF, DE
moon_write_fmop:
	push	hl
	ld	a, (seq_opsel)
	cp	$12
	jr	c,skip_sub_a
	sub	$12
skip_sub_a:
	ld	hl, fm_op2reg_tbl ; HL = HL + A
	add	a,l
	ld	l,a
	jr	nc,add_hl_fin
	inc	h
add_hl_fin:
	ld	a,(hl)
	add	a,d
	ld	d,a
	pop	hl

	ld	a,(seq_opsel)
	cp	$12
	jr	c,moon_write_fmop_1
	jp	moon_fm2_out
moon_write_fmop_1:
	jp	moon_fm1_out

;********************************************
; moon_write_fmreg
; moon_write_fmreg_ch
; Write to OPL3 register
; in : D = addr, E = data
; dest : AF, DE
;
moon_write_fmreg:
	ld	a, (seq_dev_ch)
	jr	moon_write_fmreg_nch

; A = ch
moon_write_fmreg_nch:
moon_write_fm_ch:
; first or second FM register
	cp	$9
	jr	nc, moon_write_fm2

; first register
moon_write_fm1:
	add	a, d
	ld	d, a
	jp	moon_fm1_out

; second register
moon_write_fm2:
	sub	$9
	add	a, d
	ld	d, a
	jp	moon_fm2_out

;********************************************
; wait while BUSY
; dest : AF

moon_wait:
	in	a, (MOON_STAT)
	and	$01
	jr	nz, moon_wait
	ret

;********************************************
; write moonsound fm1 register
; in   : D = an address of register , E = data
; dest : AF

moon_fm1_out:
	call	moon_wait
	ld	a, d
	out	(MOON_REG1), a
	call	moon_wait
	ld	a, e
	out	(MOON_DAT1), a
	ret

;********************************************
; write moonsound fm2 register
; in   : D = an address of register , E = data
; dest : AF

moon_fm2_out:
	call	moon_wait
	ld	a, d
	out	(MOON_REG2), a
	call	moon_wait
	ld	a, e
	out	(MOON_DAT2), a
	ret


;********************************************
; write moonsound wave register
; in   : D = an address of register , E = data
; dest : AF

moon_wave_out:
	call	moon_wait
	ld	a, d
	out	(MOON_WREG),a
	call	moon_wait
	ld	a, e
	out	(MOON_WDAT),a
	ret

;********************************************
; read moonsound wave register
; in   : D = an address of register
; out : A = read register

moon_wave_in:
	call	moon_wait
	ld	a, d
	out	(MOON_WREG),a
	call	moon_wait
	in	a, (MOON_WDAT)
	ret

;
;********************************************
; add number of channel to the index of register
; in : D = index of register
; dest : AF
moon_add_reg_ch:
	ld	a, (seq_dev_ch)
	add	a, d
	ld	d, a
	ret

;
;********************************************
; set frequency on the channel
; in   : work
; dest : AF,DE
moon_set_freq_ch:
	ld	a, (ix + IDX_DSEL)
	or	a
	ret	nz

set_freq_ch_opl4:
	; ocatve and f-number(hi)
	ld	a, (ix + IDX_FNUM + 1)
	rlca
	and	$0e
	ld	e,a
	ld	a, (ix + IDX_FNUM)
	rlca
	and	$01
	or	e
	ld	e,a

	ld	a, (ix + IDX_OCT)
	and	$0f
	rlca
	rlca
	rlca
	rlca
	or	e
	ld	e, a

	ld	a, (ix + IDX_REVERB)
	or	a
	jr	z, moon_set_freq_ch_skip_reverb
	set	3, e
moon_set_freq_ch_skip_reverb:

	ld	d, $38
	call	moon_add_reg_ch
	call	moon_wave_out

	; f-number(lo)
	ld	a, (ix + IDX_TONE+1)
	and	$01
	ld	e,a

	ld	a, (ix + IDX_FNUM)
	rlca
	and	$fe
	or	e
	ld	e, a

	ld	d, $20
	call	moon_add_reg_ch
	jp	moon_wave_out



;********************************************
; set volume on the channel
; in   : work
; dest : AF,DE
moon_set_vol_ch:
	ld	a, (ix + IDX_DSEL)
	or	a
	jr	nz, moon_set_fmvol_ch

	; volume ( 0x7f = -inf )
	ld	a, (ix + IDX_VOL)
	xor	$7f
	rlca
	or	$01
	ld	e, a
	ld	d, $50
	call	moon_add_reg_ch
	jp	moon_wave_out

moon_set_fmvol_ch:
	push	ix
	push	hl
	push	bc

	ld	a, (ix + IDX_OPSEL)
	ld	(seq_opsel), a

	ld	b, (ix + IDX_VOL)

	ld	h, (ix + IDX_VOLOP)

	ld	c, $02
	ld	a, (ix + IDX_SYNTH)
	and	$80
	jr	z,moon_set_fmvol_lp ; 4OP check
	ld	c,$04
moon_set_fmvol_lp
	rr	h
	jr	nc, skip_set_fmvol
	call	moon_calc_current_fmvol
	ld	e, a
	ld	d, $40
	call	moon_write_fmop
skip_set_fmvol:
	inc	ix
	ld	a, (seq_opsel)
	add	a, $03
	ld	(seq_opsel), a

	dec	c
	jr	nz, moon_set_fmvol_lp

	pop	bc
	pop	hl
	pop	ix
	ret

moon_calc_current_fmvol:
	; A = (OL + (63-VOL))
	ld	a,b
	and	$3f
	xor	$3f
	ld	e,a

	ld	a, (ix + IDX_OLDAT1)
	and	$3f
	add	a, e
	cp	$40
	jr	nc, set_fmvol_min
	ld	e, a
	jr	set_fmvol_ks
set_fmvol_min:
	ld	e, $3f
set_fmvol_ks:
	ld	a, (ix + IDX_OLDAT1)
	and	$c0
	or	e
	ret



;********************************************
; set ADSR regs
; in   : work
; dest : AF,DE
moon_set_adsr:
	ld	e, (ix + IDX_LFO_VIB)
	ld	d, $80
	call	moon_add_reg_ch
	call	moon_wave_out
	ld	e, (ix + IDX_AR_D1R)
	ld	d, $98
	call	moon_add_reg_ch
	call	moon_wave_out
	ld	e, (ix + IDX_DL_D2R)
	ld	d, $B0
	call	moon_add_reg_ch
	call	moon_wave_out
	ld	e, (ix + IDX_RC_RR)
	ld	d, $C8
	call	moon_add_reg_ch
	call	moon_wave_out
	ld	e, (ix + IDX_AM)
	ld	d, $E0
	call	moon_add_reg_ch
	jp	moon_wave_out

;********************************************
; moon_key_data
; make data for key-on/off
; in   : work
; out  : E = data for key
; dest : almost all
moon_key_data:
	ld	a, (ix + IDX_PAN)
	and	$0f

;;	or	$10 ; PCM-MIX

	ld	e,a
	ld	a,(ix + IDX_LFO)
	or	a
	jr	nz,moon_key_data_lfo_on
	set	5,e  ; LFO deactive
moon_key_data_lfo_on:
	ld	a,(ix + IDX_DAMP)
	or	a
	jr	z,moon_key_data_damp_off
	set	6,e  ; Damp on
moon_key_data_damp_off:
	ret


;********************************************
; moon_key_off
; this function does : key-off
; in   : work
; dest : almost all

opl3_keyoff:
	ld		a, (ix + IDX_KEY)
	and		$20
	ret		z
	ld		a, (ix + IDX_KEY)
	and		$df
	ld		e, a
	ld		d, $b0
	ld		(ix + IDX_KEY), e

	; 0でなければスキップする
	ld		a, (seq_skip_flag)
	or		a
	ret		nz

	jp		moon_write_fmreg ; key-off

opl4_keyoff:
	ld		a, (ix + IDX_KEY)
	and		$80
	ret		z
	ld		a, (ix + IDX_KEY)
	and		$7f
	ld		e, a
	ld		d, $68
	ld		(ix + IDX_KEY),e
	call	moon_add_reg_ch
	jp		moon_wave_out ; key-off

;********************************************
; moon_write_fmpan
; calc and write Reg $Cx
; dest AF, DE

moon_write_fmpan:
	ld	a, (ix + IDX_SYNTH)
	ld	d, a
	and	$1c ; 000FFF00
	rrca
	ld	e, a
	ld	a, d
	and	$01 ; SynthType
	or	e
	or	(ix + IDX_PAN)

	; E -> $C0
	ld	e,a
	ld	d,$c0
	call moon_write_fmreg

	; 4OP
	ld	a, (ix + IDX_SYNTH)
	ld	d, a
	and	$80

	; skip if not 4op
	ret z

	; 4 OP
	ld	a, d
	rrca
	and	$01 ; 2nd SynthType
	or	(ix + IDX_PAN)
	ld	e, a
	ld	d, $c0

	; E -> $C0 + 3 + ch
	ld	a, (seq_dev_ch)
	add	a, $03
	jp	moon_write_fmreg_nch


;********************************************
; moon_key_on
; Set tone number, frequency and key-on
; in   : work
; dest : almost all
;
opl3_keyon:
	bit		0, (ix + IDX_EFX1)
	jr		nz, slar_opl3_on

	call	moon_key_off
	call	start_venv
	call	start_penv
	call	start_nenv

slar_opl3_on:
	res		0, (ix + IDX_EFX1)
	call	moon_key_write_fmfreq
	or		$20 ; key on
	ld		e, a
	ld		d, $b0
	ld		(ix + IDX_KEY), e

	; 0でなければスキップ
	ld		a, (seq_skip_flag)
	or		a
	ret		nz

	jp		moon_write_fmreg ; key-on


opl4_keyon:
	bit		0, (ix + IDX_EFX1)
	jr		nz, slar_opl4_on

	call	moon_key_off
	call	start_venv
	call	start_penv
	call	start_nenv

	; tone number(hi)
	ld		a, (ix + IDX_TONE+1)
	and		$01
	ld		e, a
	ld		d, $20
	call	moon_add_reg_ch
	call	moon_wave_out

	; tone number(lo)
	ld		e, (ix + IDX_TONE)
	ld		d, $08
	call	moon_add_reg_ch
	call	moon_wave_out

moon_wavechg_lp:
	in		a, (MOON_STAT)
	and		$02
	jr		nz, moon_wavechg_lp

	call	moon_set_freq_ch
	call	moon_set_vol_ch
	call	moon_set_adsr

moon_opl4_set_keyreg:
	; OPL4 key-on
	; 0でなければスキップ
	ld		a, (seq_skip_flag)
	or		a
	ret		nz

	call	moon_key_data
	ld		a,e
	or		$80 ; key-on
	ld		e, a
	ld		d, $68
	ld		(ix + IDX_KEY),e

	call	moon_add_reg_ch
	jp		moon_wave_out ; key-on

slar_opl4_on:
	res		0, (ix + IDX_EFX1)
	jp		moon_set_freq_ch

;********************************************
; moon_key_write_fmfreq
; calculates and writes related FM frequency
; out : A = Reg.$B0 ( FnumH + BLK )
; dest : almost all
moon_key_write_fmfreq:
	ld	a, (ix + IDX_OCT)
	ld	(seq_tmp_oct), a

	ld	l, (ix + IDX_FNUM)
	ld	h, (ix + IDX_FNUM + 1)
	ld	(seq_tmp_fnum), hl

moon_key_write_fmfreq_base:
	ld	a, (seq_tmp_fnum)
	ld	e, a
	ld	d, $a0
	ld	a, (seq_dev_ch)
	call	moon_write_fmreg_nch

	ld	a, (seq_tmp_fnum + 1)
	and	$03
	ld	e, a

	ld	a, (seq_tmp_oct)
	rlca
	rlca
	and	$1c ; mask for Octave
	or	e   ; F-Number
	ret

;********************************************
; moon_key_fmfreq
; calculates and writes related regs with keeping key

moon_key_fmfreq:
	call	moon_key_write_fmfreq
	ld	e,a
	ld	a, (ix + IDX_KEY)
	and	$20
	or	e

	ld	(ix + IDX_KEY), a
	ld	e, a
	ld	d, $b0

	; 0でなければスキップ
	ld	a, (seq_skip_flag)
	or	a
	ret nz

	jp	moon_write_fmreg ; key-on


;********************************************
;  load pcm


MDB_LDFLAG: equ MDB_BASE
MDB_ADRHI:	equ MDB_BASE + 1
MDB_ADRMI:	equ MDB_BASE + 2
MDB_ADRLO:	equ MDB_BASE + 3
MDB_RESULT:	equ MDB_BASE + 4
MDB_ROM:	equ MDB_BASE + 5


; reset R/W address pointer
moon_reset_sram_adrs:
	ld		a, (MDR_DSTPCM)
	ld		(MDB_ADRHI), a
	xor		a
	ld		(MDB_ADRMI), a
	ld		(MDB_ADRLO), a
	jp		moon_set_sram_adrs


; incliments address pointer
moon_inc_sram_adrs:
	ld		a, (MDB_ADRLO)
	inc		a
	ld		(MDB_ADRLO), a
	ret		nz

	ld		a, (MDB_ADRMI)
	inc		a
	ld		(MDB_ADRMI), a
	ret		nz

	ld		a, (MDB_ADRHI)
	inc		a
	ld		(MDB_ADRHI), a
	ret


; set SRAM address
moon_set_sram_adrs:

	ld		a, (MDB_ADRHI)
	ld		e, a
	ld		d, $03
	call	moon_wave_out

	ld		a, (MDB_ADRMI)
	ld		e, a
	ld		d, $04
	call	moon_wave_out

	; the last should be lowest to set chip's internal pointer.
	; (trigger to set)
	ld		a, (MDB_ADRLO)
	ld		e, a
	ld		d, $05
	jp		moon_wave_out


; check ROM
moon_check_rom:

	xor		a
	ld		(MDB_ADRHI), a
	ld		(MDB_ADRLO), a
	ld		a, $12
	ld		(MDB_ADRMI), a

	; A <- (001200h)
	call	moon_set_sram_adrs
	ld		b, $08
	ld		hl, str_romchk

	; check loop
moon_check_rom_lp:
	ld		a, (hl)
	ld		e, a

	; A <- (SRAM)
	ld		d, $06
	call	moon_wave_in
	ld		(MDB_ROM), a
	cp		e
	ret		nz
	inc		hl
	djnz	moon_check_rom_lp
	ret

str_romchk:
	db "Copyright"





; check SRAM
moon_check_sram:

	; $77 -> ($200000)
	call	moon_reset_sram_adrs
	ld		de, $0677
	call	moon_wave_out

	; ok if $77 <- ($200000)
	call	moon_set_sram_adrs
	ld		d, $06
	call	moon_wave_in
	cp		$77
	ret		nz

	; $88 -> ($200000)
	call	moon_set_sram_adrs
	ld		de, $0688
	call	moon_wave_out

	; ok if $88 <- ($200000)
	call	moon_set_sram_adrs
	ld		d, $06
	call	moon_wave_in
	cp		$88
	ret		nz

	; $99 -> ($200001)
	ld		a, $01
	ld		(MDB_ADRLO), a
	call	moon_set_sram_adrs
	ld		de, $0699
	call	moon_wave_out

	; ok if $99 <- ($200001)
	call	moon_set_sram_adrs
	ld		d, $06
	call	moon_wave_in
	cp		$99
	ret		nz

	; ok if $88 <- ($200000)
	xor		a
	ld		(MDB_ADRLO), a
	call	moon_set_sram_adrs
	ld		d, $06
	call	moon_wave_in
	cp		$88
	ret


; Load User PCM
moon_load_pcm:
	xor		a
	call	change_page3

	; is PCM packed song file?
	ld		a, (MDR_PACKED)
	; output status for debug
	ld		(MDB_LDFLAG), a

	or		a
	ret		z

	; initialize to enable OPL4 function
	call 	moon_init

	; memory write mode
	ld		de, $0211
	call	moon_wave_out

	; check ROM
	call	moon_check_rom
	jr		z, check_sram_start

	; failed to check ROM
	ld		a, $03
	ld		(MDB_LDFLAG), a
	; address reset
	call	moon_reset_sram_adrs
	ret

check_sram_start:
	; check sram
	call	moon_check_sram
	jr		z, sram_found

	; result
	ld		(MDB_RESULT), a

	; SRAM is not found
	ld		a, $02
	ld		(MDB_LDFLAG), a
	ret

sram_found:
	; reset SRAM address
	call	moon_reset_sram_adrs


	; PCM number of banks
	ld		a, (MDR_PCMBANKS)
	ld		(moon_pcm_numbanks), a
	ld		(moon_pcm_bank_count), a

	; size of lastbank
	ld		a, (MDR_LASTS)
	ld		(moon_pcm_lastsize), a

	; size of start page
	ld		a, (MDR_STPCM)
	ld		(moon_pcm_bank), a

	; start of source address
	ld		hl, $8000

	; address = $A000 if (start_bank & 1) != 0
	and		$01
	or		a
	jr		z, pcm_copy_bank

	; bank1 = $A000
	ld		h, $A0

	; RAM to PCM
pcm_copy_bank:

	; bank size = $2000
	ld		bc, $2000

	; Change to user pcm bank
	ld		a, (moon_pcm_bank)
	push	af
	call	change_page3
	pop 	af

	inc		a
	ld		(moon_pcm_bank), a

	; reset address if HL >= $C000
	ld		a, h
	cp		$C0
	jr		c, pcm_chk_last

	; reset source address
	ld		hl, $8000

	; is the bank last?
pcm_chk_last:
	ld		a, (moon_pcm_bank_count)
	or		a
	jr		nz, pcm_copy_lp

	; use lastsize if the bank is last one.
	ld		a, (moon_pcm_lastsize)
	ld		b, a

pcm_copy_lp:
	ld		a, (hl)
	ld		e, a
	ld		d, $06

	; A -> (PCM SRAM)
	call	moon_wave_out

	inc		hl
	dec		bc

	; loop if BC > 0
	ld		a, b
	or		c
	jr		nz, pcm_copy_lp

	; end if count is 0
	ld		a, (moon_pcm_bank_count)
	or		a
	jr		z, pcm_copy_end
	dec		a
	ld		(moon_pcm_bank_count), a
	jr		pcm_copy_bank

	; end of PCM copy
pcm_copy_end:

	; normal mode
	ld		de, $0210
	jp		moon_wave_out

moon_pcm_bank_count:
	db	$00

moon_pcm_bank:
	db	$00

moon_pcm_numbanks:
	db	$00

moon_pcm_lastsize:
	db	$00





;********************************************
; freq_table
freq_table:
	include	"ftbl600.inc"
