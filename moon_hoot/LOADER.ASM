; MoonDriver hoot LOADER ver 0.2
; by BouKiCHi 

I_JP:		EQU 0C3H
I_RET:		EQU 0C9H
I_NOP:		EQU 000H

DRV_INIT:	EQU 04000H
DRV_INTR:	EQU 04003H
DRV_STOP:	EQU 04006H
DRV_LDPCM:	EQU 04013H


HTIMI:		EQU 0FD9FH

STACK:		EQU 00400H


			ORG 0100H

ENTRY:
	; 割り込みをIM 1に (すべて38Hで受ける)
	DI
	IM		1
	LD		SP, STACK
	; フックする
	CALL	HOOK
	EI
	
LOOP:
	; キー入力待ち
	IN		A,(02h)
	OR		A
	JR		Z,LOOP
	
	; 1以外でストップ
	CP		01H
	JR		NZ, STOP
	
LOAD_SONG:
	DI
	; 再生中でなければ発音停止をスキップ
	LD		A, (FLAG_PLAY)
	OR		A
	JR		Z, SKIP_STOP

	; 発音停止
	CALL	DRV_STOP
	

SKIP_STOP:	
	; リクエスト番号をベースに曲データを読みだす
	IN		A, (03H)
	OUT		(03H), A
	
	; ユーザーPCM読み込み
	CALL	DRV_LDPCM
	
	; ドライバ初期化
	CALL	DRV_INIT
	
	; 再生中フラグをセット
	LD		A, 1
	LD		(FLAG_PLAY), A

	; 発音停止
	CALL	DRV_STOP
	
	; タイマー割り込みを有効にする
	LD		A, I_JP
	LD		(HTIMI), A
	
	; ループへ
	EI
	JR		LOOP


STOP:
	; 割り込みを停止する
	DI
	CALL	 DRV_STOP
	
	LD		A, I_RET
	LD		(HTIMI), A

	; 再生中フラグをリセット
	XOR		A
	LD		(FLAG_PLAY), A


	; hoot側にステータス更新を伝える
	XOR		A
	OUT		(02H), A
	EI
	JR		LOOP

	; タイマーを未使用状態でフックする
HOOK:
	LD		A, I_RET
	LD		(HTIMI), A
	LD		HL, USRINT
	LD		(HTIMI + 1), HL
	RET

	; 再生中フラグ
FLAG_PLAY:
	DB	00H

; ユーザー割り込み 1/60を実行
USRINT:
	JP		DRV_INTR


