#include <stdio.h>
#include <string.h>

typedef struct
{
	int  use;
	char file[512];

	int  bit;
	unsigned  start;
	unsigned  loop;
	unsigned  end;

	int lfo,vib;
	int ar,d1r;
	int dl,d2r;
	int rc,rr;
	int am;
} userpcm_t;

userpcm_t pcmlist[384];

#define USE_AS_LIB
#include "wavread.c"


/************************************/
typedef struct
{
	char *filename;
	FILE *fp;
	int line;
	int quote;

	char lastchr;
	
} strmfile_t;


int strmStr2Int(char *ptr)
{
	int temp = 0;
	if (strncmp(ptr,"0x",2) == 0)
	{
		sscanf(ptr+2,"%x",&temp);
		return temp;
	}
	if (*ptr == '$')
	{
		sscanf(ptr+1,"%x",&temp);
		return temp;
	}
	
	sscanf(ptr,"%d",&temp);
	return temp;
}

int strmOpen(strmfile_t *sfp)
{
	
	sfp->fp = fopen(sfp->filename,"r");
	if (sfp->fp == NULL)
		return -1;
	
	sfp->quote = 0;
	sfp->line = 0;
	sfp->lastchr = 0;
	return 0;
}

int strmIsEOF(strmfile_t *sfp)
{
	return feof(sfp->fp);
}

int strmIsHex(int chr)
{
	if (chr >= '0' && chr <= '9') 
		return 1; 

	if (chr >= 'a' && chr <= 'f') 
		return 1; 

	if (chr >= 'A' && chr <= 'F') 
		return 1; 
	
	return 0;
}

int strmHex2Int(int chr)
{
	if (chr >= '0' && chr <= '9') 
		return chr-'0'; 

	if (chr >= 'a' && chr <= 'f') 
		return chr-'a'; 

	if (chr >= 'A' && chr <= 'F') 
		return chr-'A'; 
	
	return 0;
}

int strmEsc(strmfile_t *sfp)
{
	int chr;
	int num;
	
	num = 0;
	chr = fgetc(sfp->fp);
	
	switch(chr)
	{
		case '\"':
			return chr;
		case 'r':
			return '\r';
		case 'n':
			return '\n';
		case 'x':
			while(1)
			{
				chr = fgetc(sfp->fp);
				if (chr == EOF) break;
				if (strmIsHex(chr)) 
					num = (num * 16) + strmHex2Int(chr);
				else
					break;
			}
			return num;
	}
	return chr;
}


int strmGetStringWithFlags(char *buf,int len,strmfile_t *sfp,int skipSpace,int getLine)
{
	int chr;
	int i;

	i = 0;
	chr = fgetc(sfp->fp);
	
	while(i < len && !feof(sfp->fp))
	{
		if (chr == EOF)
			break;

		if (chr == 0x0d)
		{
			sfp->line++;
			if (i > 0) break;

			goto getNextChr;
		}
		if (chr == 0x0a)
		{
			if (sfp->lastchr != 0x0d)
				sfp->line++;

			if (i > 0) break;
			
			goto getNextChr;
		}
		if (skipSpace && !sfp->quote && isspace(chr))
		{
			if (!getLine && i > 0)
				break;

			goto getNextChr;
		}
		if (chr == '\"')
		{
			sfp->quote = !sfp->quote;

			goto getNextChr;
		}
		
		if (chr == ';')
		{
			while(chr != EOF && chr != 0x0d && chr != 0x0a)
			{
				sfp->lastchr = chr;
				chr = fgetc(sfp->fp);
			}
			continue;
		}
		if (chr == '\\')
			chr = strmEsc(sfp);
		
		buf[i++] = chr;
		
		getNextChr:
		sfp->lastchr = chr;
		chr = fgetc(sfp->fp);
	}
	
	buf[i++] = 0;
	return i;
}

int strmGetString(char *buf,int len,strmfile_t *sfp)
{
	return strmGetStringWithFlags(buf,len,sfp,1,0);
}

int strmGetLine(char *buf,int len,strmfile_t *sfp)
{
	return strmGetStringWithFlags(buf,len,sfp,0,1);
}

int strmGetInt(strmfile_t *sfp)
{
	char buf[512];
	strmGetStringWithFlags(buf,512,sfp,1,0);
	return strmStr2Int(buf);
}

void strmClose(strmfile_t *sfp)
{
	if (sfp->fp) 
	{
		fclose(sfp->fp);
		sfp->fp = NULL;
	}
}
/******************************************/


void printPCMinfo(userpcm_t *upcm)
{
	printf("File : %s\n",upcm->file);
	printf("Bit : %02x\n",upcm->bit);
	printf("Start : %08x\nLoop  : %04x\nEnd   : %04x\n",
		upcm->start,upcm->loop,upcm->end);
		
	printf("LFO : %02x  VIB : %02x\n",upcm->lfo,upcm->vib);
	printf("AR  : %02x  D1R : %02x\n",upcm->ar,upcm->d1r);
	printf("DL  : %02x  D2R : %02x\n",upcm->dl,upcm->d2r);
	printf("RC  : %02x  RR  : %02x\n",upcm->rc,upcm->rr);
	printf("AM  : %02x\n",upcm->am);
	
}

void checkPCMinfo(userpcm_t *upcm)
{
	if (upcm->bit > 2)
	{
		printf("Warning : bit > 2 is prohibited , forced bit = 2\n");
		upcm->bit = 2;
	}
	if (upcm->loop > 0xffff)
	{
		printf("Warning : too big loop address(addr > 0xffff)\n");
		upcm->loop = 0xffff;
	}
	if (upcm->end > 0xffff)
	{
		printf("Warning : too big end address(addr > 0xffff)\n");
		upcm->end = 0xffff;
	}
}

int calcPCMlength(userpcm_t *upcm)
{
	switch(upcm->bit)
	{
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

int makePCMfile(char *file)
{
	FILE *fp;

	int i,j;
	int dat1,dat2;
	
	unsigned char temp[0x10];

	fp = fopen(file,"wb");
	if (!fp)
		return -1;

	for(i=0; i < 384; i++)
	{
		memset(temp,0,0x10);
		if (pcmlist[i].use)
		{
			temp[0] =
			 ((pcmlist[i].bit & 0x03)<<6)
			 |((pcmlist[i].start>>16)&0x3f);
			temp[1] =
			 ((pcmlist[i].start>>8)&0xff);
			temp[2] =
			 ((pcmlist[i].start)&0xff);

			temp[3] =
			 ((pcmlist[i].loop>>8)&0xff);
			temp[4] =
			 ((pcmlist[i].loop)&0xff);

			temp[5] =
			 ((pcmlist[i].end>>8)&0xff)^0xff;
			temp[6] =
			 ((pcmlist[i].end)&0xff)^0xff;


			temp[7] =
			 ((pcmlist[i].lfo & 0x07)<<3) |
			 ((pcmlist[i].vib & 0x07));

			temp[8] =
			 ((pcmlist[i].ar & 0x0f)<<4) |
			 ((pcmlist[i].d1r & 0x0f));

			temp[9] =
			 ((pcmlist[i].dl & 0x0f)<<4) |
			 ((pcmlist[i].d2r & 0x0f));

			temp[10] =
			 ((pcmlist[i].rc & 0x0f)<<4) |
			 ((pcmlist[i].rr & 0x0f));

			temp[11] =
			 ((pcmlist[i].am & 0x07));
		}
		fwrite(temp,0x0c,1,fp);
	}
	
	for(i=0; i < 384; i++)
	{
		wavfmt_t wav;

		// printf("curpos : %08x \n",ftell(fp));
		
		if (!pcmlist[i].use)
			break;

		if (wavOpen(pcmlist[i].file,&wav) < 0)
			break;
			
		for(j=0; j <= pcmlist[i].end; j++)
		{
			switch(pcmlist[i].bit)
			{
				case 0:
					dat1 = wavGetSample(&wav,8);
					temp[0] = dat1;
					fwrite(temp,1,1,fp);
				break;
				case 1:
					dat1 = wavGetSample(&wav,12);
					dat2 = wavGetSample(&wav,12);
					
					temp[0] = dat1>>4;
					temp[1] = (dat1 & 0xf) | ((dat2 & 0x0f)<<4);
					temp[2] = dat2>>4;
					
					fwrite(temp,3,1,fp);
					j++;
				break;
				case 2:
					dat1 = wavGetSample(&wav,16);
					temp[0] = dat1>>8;
					temp[1] = dat1&0xff;

					fwrite(temp,2,1,fp);
				break;
			}
		}
		wavClose(&wav);
	}
	fclose(fp);
}

int readPCMdefine(char *file)
{
	int  i;
	int  addr;
	char buf[512];
	strmfile_t sf;

	for(i=0; i < 384; i++)
		memset(&pcmlist[i],0,sizeof(userpcm_t));

	i = 0;
	addr = 0x200000 + 0x0c * 0x180;

	sf.filename = file;

	if (strmOpen(&sf) < 0)
		return -1;
	
	while(i < 384 && !strmIsEOF(&sf))
	{
		strmGetString(buf,512,&sf);

		if (strmIsEOF(&sf))
			break;
			
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
		addr += ( calcPCMlength(&pcmlist[i]) );
		
		printPCMinfo(&pcmlist[i]);
		i++;
	}
	strmClose(&sf);
	
	
	return 0;
}

int main(int argc,char *argv[])
{

	char outfn[512];
	char *ptr;

	printf("PCMTOOL for OPL4 ver 0.3 by BouKiCHi\n");
	
	if (argc < 2)
	{
		printf("Usage pcmtool file [file.pcm]\n");
		return 1;
	}

	if ( strlen( argv[1] ) >= 512 )
	{
		strcpy(outfn,"pcm.bin");
	}
	else
	{
		strcpy(outfn,argv[1]);
		ptr = strrchr(outfn,'.');
		if (ptr)
			strcpy(ptr,".pcm");
		else
			strcat(outfn,".pcm");
	}

	if (readPCMdefine(argv[1]) < 0)
	{
		printf("Error : cound't read PCM definition file\n");
		return 1;
	}

	printf("%s -> %s\n",argv[1],outfn);
	makePCMfile(outfn);


	return 0;

}


