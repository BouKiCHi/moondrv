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
	; ���荞�݂�IM 1�� (���ׂ�38H�Ŏ󂯂�)
	DI
	IM		1
	LD		SP, STACK
	; �t�b�N����
	CALL	HOOK
	EI
	
LOOP:
	; �L�[���͑҂�
	IN		A,(02h)
	OR		A
	JR		Z,LOOP
	
	; 1�ȊO�ŃX�g�b�v
	CP		01H
	JR		NZ, STOP
	
LOAD_SONG:
	DI
	; �Đ����łȂ���Δ�����~���X�L�b�v
	LD		A, (FLAG_PLAY)
	OR		A
	JR		Z, SKIP_STOP

	; ������~
	CALL	DRV_STOP
	

SKIP_STOP:	
	; ���N�G�X�g�ԍ����x�[�X�ɋȃf�[�^��ǂ݂���
	IN		A, (03H)
	OUT		(03H), A
	
	; ���[�U�[PCM�ǂݍ���
	CALL	DRV_LDPCM
	
	; �h���C�o������
	CALL	DRV_INIT
	
	; �Đ����t���O���Z�b�g
	LD		A, 1
	LD		(FLAG_PLAY), A

	; ������~
	CALL	DRV_STOP
	
	; �^�C�}�[���荞�݂�L���ɂ���
	LD		A, I_JP
	LD		(HTIMI), A
	
	; ���[�v��
	EI
	JR		LOOP


STOP:
	; ���荞�݂��~����
	DI
	CALL	 DRV_STOP
	
	LD		A, I_RET
	LD		(HTIMI), A

	; �Đ����t���O�����Z�b�g
	XOR		A
	LD		(FLAG_PLAY), A


	; hoot���ɃX�e�[�^�X�X�V��`����
	XOR		A
	OUT		(02H), A
	EI
	JR		LOOP

	; �^�C�}�[�𖢎g�p��ԂŃt�b�N����
HOOK:
	LD		A, I_RET
	LD		(HTIMI), A
	LD		HL, USRINT
	LD		(HTIMI + 1), HL
	RET

	; �Đ����t���O
FLAG_PLAY:
	DB	00H

; ���[�U�[���荞�� 1/60�����s
USRINT:
	JP		DRV_INTR

