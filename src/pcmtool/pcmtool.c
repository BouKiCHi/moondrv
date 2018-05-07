#include <stdio.h>
#include <string.h>
#include <ctype.h>

#define PCM_START_RAM 0x200000

#define PCM_ENTRY_SIZE 0x0c
#define PCM_MAX_ENTRY 0x180



typedef struct {
	int  use;
	char file[512];

	int  bit;
	unsigned  start;
	int loop;
	int end;

	int lfo,vib;
	int ar,d1r;
	int dl,d2r;
	int rc,rr;
	int am;
} userpcm_t;

userpcm_t pcmlist[PCM_MAX_ENTRY];


#define USE_AS_LIB
#include "wavread.c"


/************************************/
typedef struct {
	char *filename;
	FILE *fp;
	int line;
	int quote;

	char lastchr;
} strmfile_t;

// 文字列から整数
int strmStr2Int(char *ptr) {
	int temp = 0;

	if (strncmp(ptr,"0x",2) == 0) {
		sscanf(ptr+2,"%x",&temp);
		return temp;
	}
	if (*ptr == '$') {
		sscanf(ptr+1,"%x",&temp);
		return temp;
	}

	sscanf(ptr,"%d",&temp);
	return temp;
}

int strmOpen(strmfile_t *sfp) {
	sfp->fp = fopen(sfp->filename,"r");
	if (sfp->fp == NULL) return -1;
	
	sfp->quote = 0;
	sfp->line = 0;
	sfp->lastchr = 0;
	return 0;
}

int strmIsEOF(strmfile_t *sfp) {
	return feof(sfp->fp);
}

int strmIsHex(int chr) {
	if (chr >= '0' && chr <= '9') return 1; 
	if (chr >= 'a' && chr <= 'f') return 1; 
	if (chr >= 'A' && chr <= 'F') return 1; 
	return 0;
}

int strmHex2Int(int chr) {
	if (chr >= '0' && chr <= '9') return chr-'0'; 
	if (chr >= 'a' && chr <= 'f') return chr-'a'; 
	if (chr >= 'A' && chr <= 'F') return chr-'A'; 
	return 0;
}

int strmEsc(strmfile_t *sfp) {
	int chr;
	int num;
	
	num = 0;
	chr = fgetc(sfp->fp);
	
	switch(chr) {
		case '\"':
			return chr;
		case 'r':
			return '\r';
		case 'n':
			return '\n';
		case 'x':
			while(1) {
				chr = fgetc(sfp->fp);
				if (chr == EOF) break;
				if (strmIsHex(chr)) num = (num * 16) + strmHex2Int(chr);
				else { break; }
			}
			return num;
	}
	return chr;
}


int strmGetStringWithFlags(char *buf,int len,strmfile_t *sfp,int skipSpace,int getLine) {
	int chr;
	int i;
	const int CHR_CR = 0x0d;
	const int CHR_LF = 0x0a;

	i = 0;
	chr = fgetc(sfp->fp);
	
	while(i < len && !feof(sfp->fp)) {
		if (chr == EOF) break;

		// 次の行へ
		if (chr == CHR_CR) {
			sfp->line++;
			if (i > 0) break;
			goto getNextChr;
		}
		if (chr == CHR_LF) {
			if (sfp->lastchr != CHR_CR)
				sfp->line++;

			if (i > 0) break;
			goto getNextChr;
		}
		if (skipSpace && !sfp->quote && isspace(chr)) {
			if (!getLine && i > 0) break;
			goto getNextChr;
		}
		if (chr == '\"') {
			sfp->quote = !sfp->quote;
			goto getNextChr;
		}
		
		// 1行コメント
		if (chr == ';') {
			while(chr != EOF && chr != CHR_CR && chr != CHR_LF) {
				sfp->lastchr = chr;
				chr = fgetc(sfp->fp);
			}
			continue;
		}
		// エスケープ文字
		if (chr == '\\') chr = strmEsc(sfp);
		
		buf[i++] = chr;
		
		getNextChr:
		sfp->lastchr = chr;
		chr = fgetc(sfp->fp);
	}
	
	buf[i++] = 0;
	return i;
}

// 文字列
int strmGetString(char *buf,int len,strmfile_t *sfp) {
	return strmGetStringWithFlags(buf,len,sfp,1,0);
}

// 行
int strmGetLine(char *buf,int len,strmfile_t *sfp) {
	return strmGetStringWithFlags(buf,len,sfp,0,1);
}

// 文字列から整数
int strmGetInt(strmfile_t *sfp) {
	char buf[512];
	strmGetStringWithFlags(buf,512,sfp,1,0);
	return strmStr2Int(buf);
}

void strmClose(strmfile_t *sfp) {
	if (sfp->fp) {
		fclose(sfp->fp);
		sfp->fp = NULL;
	}
}
/******************************************/

void printPCMinfo(userpcm_t *upcm) {
	printf("File : %s\n",upcm->file);
	printf("Bit : %02x\n",upcm->bit);
	printf("Start : %08x\n",upcm->start);
	printf("Loop : %04x\n",upcm->loop);
	printf("End : %04x\n",upcm->end);

	printf("LFO : %02x  VIB : %02x\n",upcm->lfo,upcm->vib);
	printf("AR  : %02x  D1R : %02x\n",upcm->ar,upcm->d1r);
	printf("DL  : %02x  D2R : %02x\n",upcm->dl,upcm->d2r);
	printf("RC  : %02x  RR  : %02x\n",upcm->rc,upcm->rr);
	printf("AM  : %02x\n",upcm->am);
	
}

void checkPCMinfo(userpcm_t *upcm) {
	if (upcm->bit > 2) {
		printf("Warning : bit > 2 is prohibited , forced bit = 2\n");
		upcm->bit = 2;
	}
	if (upcm->loop > 0xffff) {
		printf("Warning : too big loop address(addr > 0xffff)\n");
		upcm->loop = 0xffff;
	}
	if (upcm->end > 0xffff) {
		printf("Warning : too big end address(addr > 0xffff)\n");
		upcm->end = 0xffff;
	}
}

// PCM開始アドレスの計算
int calcPCMlength(userpcm_t *upcm) {
	if (upcm->end < 0) return 0;
	switch(upcm->bit) {
		case 0:
			return upcm->end+1;
		break;
		case 1:
			return ((upcm->end+1)/2)*3;
		break;
		case 2:
			return (upcm->end+1)*2;
		break;
	}
	return 0;
}

// ヘッダの出力
void writePCMheader(FILE *fp) {
	unsigned char temp[0x10];

	for(int i=0; i < PCM_MAX_ENTRY; i++) {
		memset(temp,0,0x10);
		if (!pcmlist[i].use) {
			fwrite(temp,0x0c,1,fp);
			continue;
		}
		unsigned start = pcmlist[i].start;

		temp[0] = ((pcmlist[i].bit & 0x03)<<6) | ((start>>16)&0x3f);
		temp[1] = ((start>>8)&0xff);
		temp[2] = ((start)&0xff);

		int loop = pcmlist[i].loop < 0 ? 0 : pcmlist[i].loop;
		int end = pcmlist[i].end < 0 ? 0 : pcmlist[i].end;

		temp[3] = ((loop>>8)&0xff);
		temp[4] = ((loop)&0xff);

		temp[5] = ((end>>8)&0xff)^0xff;
		temp[6] = ((end)&0xff)^0xff;

		temp[7] = ((pcmlist[i].lfo & 0x07)<<3) | ((pcmlist[i].vib & 0x07));
		temp[8] = ((pcmlist[i].ar & 0x0f)<<4) | ((pcmlist[i].d1r & 0x0f));
		temp[9] = ((pcmlist[i].dl & 0x0f)<<4) | ((pcmlist[i].d2r & 0x0f));
		temp[10] = ((pcmlist[i].rc & 0x0f)<<4) | ((pcmlist[i].rr & 0x0f));
		temp[11] = ((pcmlist[i].am & 0x07));
		
		fwrite(temp,0x0c,1,fp);
	}
}

int makePCMfile(char *file) {
	FILE *fp;

	int i,j;
	int dat1,dat2;
	
	unsigned char temp[0x10];

	fp = fopen(file,"wb");
	if (!fp) return -1;

	writePCMheader(fp);

	int addr = PCM_START_RAM + PCM_ENTRY_SIZE * PCM_MAX_ENTRY;

	for(i=0; i < PCM_MAX_ENTRY; i++) {
		// printf("curpos : %08x \n",ftell(fp));
		if (!pcmlist[i].use) continue;

		wavfmt_t wav;
		if (wavOpen(pcmlist[i].file,&wav) < 0) break;

		pcmlist[i].start = addr;
		
		int pc = 0;
		int pcm_end = pcmlist[i].end < 0 ? 0xFFFF : pcmlist[i].end;
		for(; pc <= pcm_end && !wavIsEof(&wav); pc++) {
			switch(pcmlist[i].bit) {
				case 0:
					dat1 = wavGetSample(&wav,8);
					temp[0] = dat1;
					fwrite(temp,1,1,fp);
					addr += 1;
				break;
				case 1:
					// 2サンプル進める
					dat1 = wavGetSample(&wav,12);
					if (!wavIsEof(&wav)) {
						dat2 = wavGetSample(&wav,12);
						pc++;
					} else {
						dat1 = dat2;
					}
					
					temp[0] = dat1>>4;
					temp[1] = (dat1 & 0xf) | ((dat2 & 0x0f)<<4);
					temp[2] = dat2>>4;
					
					fwrite(temp,3,1,fp);
					addr += 3;
				break;
				case 2:
					dat1 = wavGetSample(&wav,16);
					temp[0] = dat1>>8;
					temp[1] = dat1&0xff;

					fwrite(temp,2,1,fp);
					addr += 2;
				break;
			}
		}
		wavClose(&wav);

		if (pcmlist[i].loop < 0) pcmlist[i].loop = pc;
		if (pcmlist[i].end < 0) pcmlist[i].end = pc;
		printPCMinfo(&pcmlist[i]);
	}

	// PCMヘッダ更新
	fseek(fp,0,SEEK_SET);
	writePCMheader(fp);

	fclose(fp);
}

// PCM定義を読む
int readPCMdefine(char *file) {
	int  i;
	char buf[512];
	strmfile_t sf;

	for(i=0; i < PCM_MAX_ENTRY; i++) memset(&pcmlist[i],0,sizeof(userpcm_t));

	i = 0;
	int addr = PCM_START_RAM + PCM_ENTRY_SIZE * PCM_MAX_ENTRY;

	sf.filename = file;

	if (strmOpen(&sf) < 0) return -1;
	
	while(i < PCM_MAX_ENTRY && !strmIsEOF(&sf)) {
		strmGetString(buf,512,&sf);

		if (strmIsEOF(&sf)) break;
			
		pcmlist[i].use = 1;
		strcpy(pcmlist[i].file,buf);

		pcmlist[i].bit  = strmGetInt(&sf);
		pcmlist[i].loop = strmGetInt(&sf);
		pcmlist[i].end  = strmGetInt(&sf);


		pcmlist[i].lfo = strmGetInt(&sf);
		pcmlist[i].vib = strmGetInt(&sf);
		pcmlist[i].ar  = strmGetInt(&sf);
		pcmlist[i].d1r = strmGetInt(&sf);
		pcmlist[i].dl  = strmGetInt(&sf);
		pcmlist[i].d2r = strmGetInt(&sf);
		pcmlist[i].rc  = strmGetInt(&sf);
		pcmlist[i].rr  = strmGetInt(&sf);
		pcmlist[i].am  = strmGetInt(&sf);
		
		checkPCMinfo(&pcmlist[i]);
		
		pcmlist[i].start = addr;
		addr += (calcPCMlength(&pcmlist[i]));
		
		i++;
	}
	strmClose(&sf);
	return 0;
}

int main(int argc,char *argv[]) {
	printf("PCMTOOL for OPL4 ver 0.4 by BouKiCHi\n");
	
	if (argc < 2) {
		printf("Usage pcmtool file [file.pcm]\n");
		return 1;
	}

	char outfn[512];
	char *ptr;

	if (strlen(argv[1]) >= 512) {
		strcpy(outfn,"pcm.bin");
	} else {
		strcpy(outfn,argv[1]);
		ptr = strrchr(outfn,'.');
		if (!ptr) ptr = outfn;
		strcpy(ptr,".pcm");
	}

	if (readPCMdefine(argv[1]) < 0) {
		printf("Error : cound't read PCM definition file\n");
		return 1;
	}

	printf("%s -> %s\n",argv[1],outfn);
	makePCMfile(outfn);
	return 0;

}


