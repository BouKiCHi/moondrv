/*--------------------------------------------------------------
	mml2mck	mml to mck assembler data converter
--------------------------------------------------------------*/

#define	VersionNo		27

#define	MML_MAX			128

/* ÉeÉìÉ|ÉxÅ[ÉX -> ÉtÉåÅ[ÉÄÉxÅ[ÉXÇ÷ÇÃïœä∑ÉpÉâÉÅÅ[É^ */
#define	_BASE			192.0
#define	_BASETEMPO		75

typedef	struct {
	double	cnt;
	int		frm;
} LEN;

typedef struct {
	int rate;
	int adjust;
	// gate length = delta * rate/gate_denom + adjust
} GATE_Q;

/* */
typedef struct {
	char	*str;
	int		status;
} HEAD;

/* ÉâÉCÉìÉXÉeÅ[É^ÉX */
typedef struct st_line {
	char	*filename;		/* ÉtÉ@ÉCÉãñº							*/
	int		line;			/* çsî‘çÜ								*/
	int		status;			/* çsÉXÉeÅ[É^ÉX(â∫ãLdefineéQè∆)			*/
	int		param;			/* ÉpÉâÉÅÅ[É^(âπêF/ÉgÉâÉbÉNî‘çÜetc.)	*/
	char	*str;			/* çsï∂éöóÒ								*/
	struct st_line	*inc_ptr;		/* ÉCÉìÉNÉãÅ[ÉhÉtÉ@ÉCÉãÇÃÉfÅ[É^É|ÉCÉìÉ^ */
} LINE;

#define	_HEADER			1
#define	_TITLE			2
#define	_COMPOSER		3
#define	_MAKER			4
#define	_PROGRAMER		5
#define	_OCTAVE_REV		6
#define	_EX_DISKFM		7
#define	_EX_NAMCO106	8
#define	_INCLUDE		9
#define	_BANK_CHANGE	10
#define	_EFFECT_INCLUDE	11
#define	_SET_SBANK		12
#define _EX_VRC7		13
#define _EX_VRC6		14
#define _EX_FME7		15
#define _EX_MMC5		16
#define	_NO_BANKSWITCH	17
#define	_DPCM_RESTSTOP	18
#define _GATE_DENOM	19
#define _AUTO_BANKSWITCH	20
#define _PITCH_CORRECTION		21

#define	_SET_EFFECT		0x20
#define	_SET_TONE		0x21
#define	_SET_ENVELOPE	0x22
#define	_SET_PITCH_MOD	0x23
#define	_SET_PITCH_ENV	0x24
#define	_SET_ARPEGGIO	0x25
#define	_SET_DPCM_DATA	0x26
#define	_SET_FM_TONE	0x27
#define	_SET_N106_TONE	0x28
#define	_SET_VRC7_TONE	0x29
#define _SET_HARD_EFFECT	0x2A
#define _SET_EFFECT_WAVE	0x2B

// HuSIC
#define	_SET_XPCM_DATA  0x2C
#define _SET_WTB_TONE   0x2D

// MoonDriver
#define _SET_TONETBL    0x2E
#define _SET_FMOP       0x2F
#define _EX_OPL3        0x30
#define _OPL4_NOUSE     0x31

#define _PCM_FILE     0x32


#define	_TRACK			0x40
#define	_SAME_LINE		0x80000000

				//internal   dpcm    FDS  VRC7  VRC6 namco106 FME7 MMC5
// #define	_TRACK_MAX		(        4     +1     +1    +6    +3       +8     +3  +2)
// #define	_TRACK_STR		"ABCDEFGHIJKLMNOPQRSTUVWXYZabÄ0"

#define	_TRACK_MAX		(24 + 18)
//				 012345678901234567890123012345678901234567
#define	_TRACK_STR		"ABCDEFGHIJKLMNOPQRSTUVWXabcdefghijklmnopqr"


#define BTRACK(a)	(a)
#define	BNOISETRACK		BTRACK(3)
#define	BDPCMTRACK		BTRACK(4)
#define	BFMTRACK		BTRACK(5)
#define	BVRC7TRACK		BTRACK(6)
#define	BVRC6TRACK		BTRACK(12)
#define	BVRC6SAWTRACK		BTRACK(14)
#define	BN106TRACK		BTRACK(15)
#define BFME7TRACK		BTRACK(23)
#define BMMC5TRACK		BTRACK(26)

#define TRACK(a)	(1<<(a))

#define NOISETRACK		TRACK(BNOISETRACK)
#define DPCMTRACK		TRACK(BDPCMTRACK)
#define	FMTRACK			TRACK(BFMTRACK)
#define VRC7TRACK		(TRACK(BVRC7TRACK+5)|TRACK(BVRC7TRACK+4)|TRACK(BVRC7TRACK+3)|TRACK(BVRC7TRACK+2)|TRACK(BVRC7TRACK+1)|TRACK(BVRC7TRACK))
#define VRC6TRACK		(TRACK(BVRC6TRACK+2)|TRACK(BVRC6TRACK+1)|TRACK(BVRC6TRACK))
#define VRC6PLSTRACK		(TRACK(BVRC6TRACK+1)|TRACK(BVRC6TRACK))
#define VRC6SAWTRACK		(TRACK(BVRC6TRACK+2))
#define	N106TRACK		(TRACK(BN106TRACK+7)|TRACK(BN106TRACK+6)|TRACK(BN106TRACK+5)|TRACK(BN106TRACK+4)|TRACK(BN106TRACK+3)|TRACK(BN106TRACK+2)|TRACK(BN106TRACK+1)|TRACK(BN106TRACK))
#define FME7TRACK		(TRACK(BFME7TRACK+2)|TRACK(BFME7TRACK+1)|TRACK(BFME7TRACK))
#define MMC5TRACK		(TRACK(BMMC5TRACK+1)|TRACK(BMMC5TRACK))
#define MMC5PLSTRACK		(TRACK(BMMC5TRACK+1)|TRACK(BMMC5TRACK))

#define ALLTRACK	0xffffffff

#define	_PITCH_MOD_MAX	 64
#define	_PITCH_ENV_MAX	128
#define	_ENVELOPE_MAX	128
#define	_TONE_MAX		128
#define	_DPCM_MAX		 64
#define	_ARPEGGIO_MAX	128
#define	_FM_TONE_MAX	128
#define	_N106_TONE_MAX	128
#define	_VRC7_TONE_MAX	 64
#define _HARD_EFFECT_MAX	16
#define _EFFECT_WAVE_MAX	 8

// MoonSound
#define _TONETBL_MAX	256
#define _OPL3TBL_MAX	256


// HuSIC 
#define	_WTB_TONE_MAX	128

/* ÉRÉ}ÉìÉhÉXÉeÅ[É^ÉX */
#define	PARAM_MAX		8
typedef struct {
	char    *filename;
	int     line;
	double  cnt;    //ÉgÉâÉbÉNäJénéûì_Ç0Ç∆ÇµÇƒÅAÇªÇ±Ç©ÇÁÇÃåoâﬂÇµÇΩÉJÉEÉìÉgêî
	int     frm;    //Å™ÇÉtÉåÅ[ÉÄíPà Ç…ÇµÇΩÇ‡ÇÃ
	double  lcnt;   //ÉgÉâÉbÉNÇÃÉãÅ[Évì_(LÉRÉ}ÉìÉh)Ç0Ç∆ÇµÇƒÅAÇªÇ±Ç©ÇÁÇÃåoâﬂÇµÇΩÉJÉEÉìÉgêî(ÇΩÇæÇµLÇÊÇËëOÇÕ0)
	int     lfrm;   //Å™ÇÉtÉåÅ[ÉÄíPà Ç…ÇµÇΩÇ‡ÇÃ
	int     cmd;
	double  len;    //íPà :count
	int     param[PARAM_MAX];
} CMD;

#define PARAM_OMITTED	0x80000000

#define	_NOTE_C		 0
#define	_NOTE_D		 2
#define	_NOTE_E		 4
#define	_NOTE_F		 5
#define	_NOTE_G		 7
#define	_NOTE_A		 9
#define	_NOTE_B		11

#define	MIN_NOTE	-3
#define	MAX_NOTE	0x8f

enum {
	_TEMPO = (MAX_NOTE+1),
	_OCTAVE,
	_OCT_UP,
	_OCT_DW,
	_LENGTH,
	_ENVELOPE,
	_REL_ENV,
	_VOLUME,
	_VOL_PLUS, // 0x98
	_VOL_MINUS,
	_HARD_ENVELOPE,
	_TONE,
	_ORG_TONE,
	_REL_ORG_TONE,
	_SWEEP,
	_SLAR,
	_SONG_LOOP, // 0xa0
	_REPEAT_ST,
	_REPEAT_END,
	_REPEAT_ESC,
	_CONT_NOTE,
	_CONT_END,
	_QUONTIZE,
	_QUONTIZE2,

	_TIE, // 0xa8
	_DETUNE,
	_LFO_ON,
	_LFO_OFF,
	_EP_ON,
	_EP_OFF,
	_EN_ON,
	_EN_OFF,
	_NOTE, // 0xb0
	_KEY,
	_WAIT,
	_DATA_BREAK,
	_DATA_WRITE,
	_DATA_THRUE,

	_NEW_BANK,

	_REPEAT_ST2,
	_REPEAT_END2, // 0xb8
	_REPEAT_ESC2,

	_TEMPO2,
	_TRANSPOSE,
	_MH_ON,
	_MH_OFF,

	_SHUFFLE_QUONTIZE,
	_SHUFFLE_QUONTIZE_RESET,
	_SHUFFLE_QUONTIZE_OFF, // 0xc0

	/*_ARTICULATION_ADJUST,*/
	_KEY_OFF,
	_SELF_DELAY_OFF,
	_SELF_DELAY_ON,
	_SELF_DELAY_QUEUE_RESET,
	_XX_COMMAND,
	_VRC7_TONE,
	_SUN5B_HARD_SPEED,
	_SUN5B_HARD_ENV, // 0xc8
	_SUN5B_NOISE_FREQ,
	_SHIFT_AMOUNT,
	
// HuSIC

	_NOISE_SW,
	_PAN,
	_L_PAN,
	_R_PAN,
	_C_PAN, 
	_WAVE_CHG, // 0xd0
	_MODE_CHG,
	_FMLFO_SET,
	_FMLFO_OFF,
	_FMLFO_FRQ,

// MoonDriver
	_REVERB_SET,
	_DAMP_SET,

	_SET_OPBASE,
	_LOAD_OP2, // 0xd8
	_SET_TVP,
	_DRUM_SW,
	_SET_FBS,
	_SET_OPM,

	_JUMP_FLAG,
	
	_DRUM_BIT,
    _DRUM_NOTE,
    
    _DATA_WRITE_OFS,


	_REST		= 0xfc,
	_NOP		= 0xfe,
	_TRACK_END	= 0xff
};

#define SELF_DELAY_MAX 8

/* DPCMópÉoÉbÉtÉ@ */
typedef struct {
	int		flag;						// âπêFégóp/ñ¢égópÉtÉâÉO
	int		index;						// é¿ç€Ç…ÉtÉ@ÉCÉãÇ…èëÇ´çûÇ‹ÇÍÇÈÉCÉìÉfÉbÉNÉXî‘çÜ
										// ÉRÉRÇ™-1à»äOÇÃéûÇÕfilenameÇÕñ≥éãÇ≥ÇÍÇƒindexî‘çÜÇÃDPCMÇégópÇ∑ÇÈ(É\Å[Égéû)
	char	*fname;
	int		freq;
	int		start_adr;
	int		size;
	int		delta_init;
	int		bank_ofs;					//16KB(0x4000)
} DPCMTBL;

#define	_DPCM_TOTAL_SIZE	0x4000

#define BVRC6		0x01
#define BVRC7		0x02
#define	BDISKFM		0x04
#define	BMMC5		0x08
#define	BNAMCO106	0x10
#define	BFME7		0x20

// for MoonDriver
#define BOPL4FLAG 0x01
#define BOPL3FLAG 0x02


// defination for HuSIC
#define HULFO_TRK       TRACK(1)
#define HUNOISE_TRK		(TRACK(3)|TRACK(4)|TRACK(5))

#define HUS_ALLTRK		(ALLTRACK)

#define NUM_OF_TRACKS (23+18)

#define OPL4_MAX (24)
#define OPL3_MAX (18)

#define BOPL3TRACK	BTRACK(24)

#define MAX_VOLUME 127

#define HUSIC_EXT 1

enum {
	EFTBL_END = 0xffff,
	EFTBL_LOOP = 0xfffe
};


enum {
	MCK_REPEAT_END = 0xa0,
	MCK_REPEAT_ESC = 0xa1,

	MDR_OPBASE = 0xe6,
	MDR_LDOP2  = 0xe5,
	MDR_TVP    = 0xe4,
	MDR_DRUM   = 0xf2,
	MDR_FBS    = 0xe3,
	MDR_OPMODE = 0xeb,

	MCK_SLAR   = 0xe9,

	MDR_REVERB = 0xea,
	MDR_DAMP   = 0xeb,
	
	MDR_JUMP = 0xe2,
	MDR_DRUM_BIT = 0xe1,
    MDR_DRUM_NOTE = 0xe0,


	MCK_GOTO = 0xee,
	MCK_SET_SHIFT_AMOUNT = 0xef,
	MCK_SET_FDS_HWENV = 0xf0,
	MCK_SET_SUN5B_NOISE_FREQ = 0xf1,
	MCK_SET_SUN5B_HARD_SPEED = 0xf2,
	MCK_SET_FDS_HWEFFECT = 0xf3,
	MCK_WAIT = 0xf4,
	MCK_DATA_WRITE = 0xf5,
	MCK_DIRECT_FREQ = 0xf6,
	MCK_SET_NOTEENV = 0xf7,
	MCK_SET_PITCHENV = 0xf8,
	MCK_SET_HWSWEEP = 0xf9,
	MCK_SET_DETUNE = 0xfa,
	MCK_SET_LFO = 0xfb,
	MCK_REST = 0xfc,
	MCK_SET_VOL = 0xfd, MCK_SUN5B_HARD_ENV = 0xfd,
	MCK_SET_TONE = 0xfe,
	MCK_DATA_END = 0xff
};





