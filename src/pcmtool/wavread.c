#include <stdio.h>
#include <string.h>

typedef struct
{
	FILE *fp;
	unsigned long pcmsize;
	unsigned int freq;
	unsigned int bit;
	unsigned int ch;
} wavfmt_t;

unsigned long dword_le(unsigned char *ptr)
{
	return ((unsigned long)ptr[0]) | 
	((unsigned long)ptr[1]) << 8 | 
	((unsigned long)ptr[2]) << 16 | 
	((unsigned long)ptr[3]) << 24;
}

unsigned short word_le(unsigned char *ptr)
{
	return ((unsigned long)ptr[0]) | 
	((unsigned long)ptr[1]) << 8;
}

int wavGetFormat(wavfmt_t *lf)
{
	FILE *fp;
	unsigned char buf[10];

	fp = lf->fp;
	
	if (!fp) return -1;

	fread(buf,4,1,fp);
	if (memcmp(buf,"RIFF",4) !=0) return -1; // not RIFF

	fread(buf,4,1,fp); // size of RIFF
	fread(buf,8,1,fp);

	if (memcmp(buf,"WAVE",4) !=0) return -1; // not WAVE

	fread(buf,4,1,fp); // chunk size

	fread(buf,2,1,fp);

	if (word_le(buf) != 1) return -1; // not PCM

	fread(buf,2,1,fp); // Channel
	lf->ch = word_le(buf);

	fread(buf,4,1,fp); // Frequency
	lf->freq = dword_le(buf);

	fread(buf,4,1,fp); // byte_per_sec
	fread(buf,2,1,fp); // sample size

	fread(buf,2,1,fp); // bit size
	lf->bit = word_le(buf);

//	lf->freq=44100;
	return 0;
}

int wavSeekDataChunk(wavfmt_t *lf) {
	unsigned char buf[10];
	long lslen;	
	FILE *fp = lf->fp;

	do {
	    fread(buf,4,1,fp);
	    if (memcmp(buf,"data",4) == 0) {
			fread(buf,4,1,fp);
			lf->pcmsize = dword_le(buf);
			return 0;
	    } else {
			fread(buf,4,1,fp);
			lslen = dword_le(buf);
			fseek(fp,lslen,SEEK_CUR);
	    }
	}while(!feof(fp));
	return -1;
}

long wavConvBit(unsigned data,int inBit,int outBit) {
	if (inBit==outBit) return data;
		
	if (inBit < outBit) data <<= ( outBit - inBit );
	else data >>= ( inBit - outBit);
	return data;
}

// EOF確認
int wavIsEof(wavfmt_t *lf) {
	return (feof(lf->fp) ? 1 : 0);
}

// サンプルを得る
int wavGetSample(wavfmt_t *lf,int outBit) {	
	if (feof(lf->fp)) return 0;

	unsigned char buf[8];

	long mixch = 0;
	if (lf->bit == 8) memset(buf,0x80,sizeof(buf)); // 8bit is unsigned
	else memset(buf,0,sizeof(buf));

	if (lf->ch == 2) {
		// stereo
		if (lf->bit == 16) {
			// 16bit
			fread(buf,4,1,lf->fp);
			mixch = (short)word_le(buf);
			mixch += (short)word_le(buf+2);
			mixch /= 2;
		} else {
			// probably 8bit
			fread(buf,2,1,lf->fp);
			mixch = buf[0] - 0x80;
			mixch += ((long)buf[1] - 0x80);
			mixch /= 2;
		}
	} else {
		// mono
		if (lf->bit == 16) {
			// 16bit
			fread(buf,2,1,lf->fp);
			mixch = (short)word_le(buf);
		} else {
			// probably 8bit
			fread(buf,1,1,lf->fp);
			mixch = buf[0] - 0x80;
		}
	}

	mixch = wavConvBit(mixch,lf->bit,outBit);
	return mixch;
}

// wavを閉じる
void wavClose(wavfmt_t *wfmt) {
	fclose(wfmt->fp);
	wfmt->fp = NULL;
}

// wavを開く
int wavOpen(char *file,wavfmt_t *wfmt) {
	memset(wfmt,0,sizeof(wavfmt_t));

	wfmt->fp = fopen(file,"rb");
	if (!wfmt->fp) {
		printf("Error : File open error(%s)\n",file);
		return -1;
	}

	wfmt->freq = 11025;
	if (wavGetFormat(wfmt)) {
		printf("Error : Unsupported format file\n");
		return -1;
	}
	
	printf("freq = %d,bit = %d,ch = %d\n", wfmt->freq,wfmt->bit,wfmt->ch);

	if (wavSeekDataChunk(wfmt)) {
		printf("Error : data chank not found\n");
		wavClose(wfmt);
		return -1;
	}
	
	return 0;
}

#ifndef USE_AS_LIB

int main(int argc,char *argv[])
{	
	int i;
	wavfmt_t wav;
	
	printf("wavreader test\n");
	if (argc < 2)
	{
		printf("Usage wavtest <file>\n");
		return 1;
	}
	
	if (wavOpen(argv[1],&wav) < 0)
		return 1;
	
	for(i=0; i < 20; i++)
	{
		printf(" %d \n",wavGetSample(&wav,16));		
	}
	wavClose(&wav);
	
	return 0;
}

#endif
