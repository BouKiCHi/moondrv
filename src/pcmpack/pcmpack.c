
#include <stdio.h>
#include <string.h>

typedef unsigned char byte;

#define PATH_MAX 1024

#define PRG_NAME "PCMPACK"
#define PRG_VER "Ver 0.1"
#define PRG_AUTHOR "BouKiCHi"

#ifdef _WIN32
#define PATH_DELIM '\\'
#else
#define PATH_DELIM '/'
#endif

// MDRファイル定義
typedef struct {
  FILE *fp;
  long size;
  byte header[0x80];

  char pcmname[PATH_MAX]; // pos:0x40 pcmname

  int pcm_packed; // pos: 0x2a 1:pcm is packed

  int pcm_startadrs; // pos:0x30 start address of PCM RAM(* 0x10000)
  int pcm_startbank; // pos:0x31 start bank (* 8192)
  int pcm_banks; // pos:0x32 number of PCM banks (* 8192)
  int pcm_lastsize; // pos:0x32 size of last bank (* 0x100)

  // actual size = (pcm_banks * 0x2000) + (pcm_lastsize * 0x100)
} _mdr;


// ファイルサイズを得る
long getFileSize(const char *file)
{

  FILE *fp = fopen(file,"rb");
  if (!fp)
    return -1;

  fseek(fp, 0, SEEK_END);

  long size = ftell(fp);
  fclose(fp);

  return size;
}

// ディレクトリ名作成
void makeDirNameFromPath(char *dest, const char *path)
{
  strcpy(dest, path);
  char *p = strrchr(dest, PATH_DELIM);

  // デリミタが存在する
  if (p)
  {
    // null termination
    *(p + 1) = 0;
  }
}

// ファイル名作成
void makeFileName(char *dest, const char *path, const char *ext)
{
  strcpy(dest, path);
  char *p = strrchr(dest, PATH_DELIM);

  // パス区切りから後ろに検索
  if (p)
  {
    p = strchr(p + 1, '.');
  }
  else
  {
    p = strchr(dest, '.');
  }

  // 拡張子がある場合は置き換える
  if (p)
  {
    strcpy(p, ext);
  }
  else
  {
    strcat(dest, ext);
  }
}

// ファイル位置を設定
long seekFile(FILE *fp, long pos)
{
  fseek(fp, pos, SEEK_SET);
}


// バイト値を得る
int getByte(byte *mem, int pos)
{
  return mem[pos];
}

// ワード値を得る(LE)
int getWord(byte *mem, int pos)
{
  return (int)mem[pos] | (int)mem[pos +1] << 8;
}

// バイト値を設定する
void setByte(byte *mem, int pos, int value)
{
  mem[pos] = (byte)value;
}

// ワード値を設定する(LE)
void setWord(byte *mem, int pos, int value)
{
  mem[pos] = (byte)(value & 0xff);
  mem[pos + 1] = (byte)((value>>8) & 0xff);
}

// MDRファイルを開く
int openMDRFile(const char *file, const char *mode, _mdr *m)
{
  // ファイルを開く
  m->fp = fopen(file, mode);
  if (!m->fp)
  {
    printf("File open error!:%s\n", file);
    return -1;
  }
}

// MDRファイルを閉じる
void closeMDRFile(_mdr *m)
{
  // クローズ
  if (m->fp)
    fclose(m->fp);

  m->fp = NULL;
}

// MDRファイル読み出し
int readMDRHeader(const char *file, _mdr *m)
{
  // ファイルを開く
  if (openMDRFile(file, "rb", m) < 0)
    return -1;

  // ファイルサイズを得る
  fseek(m->fp, 0, SEEK_END);
  m->size = ftell(m->fp);
  rewind(m->fp);

  // ヘッダ部分読み出し
  seekFile(m->fp, 0x00);
  fread(m->header, 0x80, 1, m->fp);

  // PCM文字列位置
  m->pcmname[0] = 0;
  int pcmpos = getWord(m->header, 0x2c);

  // PCM位置
  if (pcmpos == 0x8040)
  {
    strncpy(m->pcmname, &m->header[0x40], 0x40);
    m->pcmname[0x40] = 0;
  }

  // PCM設定値
  m->pcm_packed = getByte(m->header, 0x2a);

  m->pcm_startadrs = getByte(m->header, 0x30);
  m->pcm_startbank = getByte(m->header, 0x31);
  m->pcm_banks = getByte(m->header, 0x32);
  m->pcm_lastsize = getByte(m->header, 0x33);

  // クローズ
  closeMDRFile(m);
}

// MDRヘッダ再構築
void writeMDRHeader(_mdr *m)
{
  // PCM設定値
  setByte(m->header, 0x2a, m->pcm_packed);

  setByte(m->header, 0x30, m->pcm_startadrs);
  setByte(m->header, 0x31, m->pcm_startbank);
  setByte(m->header, 0x32, m->pcm_banks);
  setByte(m->header, 0x33, m->pcm_lastsize);

  seekFile(m->fp, 0);
  fwrite(m->header, 0x80, 1, m->fp);
}

#define BANK_SIZE 0x2000

// MDRファイル読み出し
int packPCMintoMDR(const char *file, const char *pcm, _mdr *m)
{
  byte bank[BANK_SIZE];
  printf("packing...\n");

  // ファイルを開く
  if (openMDRFile(file, "rb+", m) < 0)
    return -1;

  // PCM開始位置
  long start_pos = m->size;

  // パックされている場合はPCM先頭バングから計算する
  if (m->pcm_packed)
  {
    start_pos = m->pcm_startbank * BANK_SIZE;
  }

  // PCMファイルを開く
  FILE *pcmfp = fopen(pcm, "rb");

  if (!pcmfp)
  {
    printf("File open error!:%s\n", pcm);
    goto err;
  }

  // PCMデータ出力位置
  printf("PCM Start:%08Xh\n", start_pos);
  seekFile(m->fp, start_pos);

  int block_len = 0;
  int pcm_blocks = 0;
  do
  {
    block_len = fread(bank, 1, BANK_SIZE, pcmfp);
    fwrite(bank, 1, block_len, m->fp);
    pcm_blocks++;
  }while(!feof(pcmfp) && block_len == BANK_SIZE);


  m->pcm_packed = 1;
  m->pcm_startadrs = 0x20; // SRAM開始アドレス
  m->pcm_startbank = start_pos / BANK_SIZE; // 開始バンク
  m->pcm_banks = pcm_blocks - 1; // ブロック数
  m->pcm_lastsize = (block_len + 0xff) / 0x100; // 最後のブロックサイズ

  printf("PCM StartAdrs:%02xh\n", m->pcm_startadrs);
  printf("PCM StartBank:%02xh\n", m->pcm_startbank);
  printf("PCM Banks:%02xh\n", m->pcm_banks);
  printf("PCM LastSize:%02xh\n", m->pcm_lastsize);

  // ヘッダ出力
  writeMDRHeader(m);

  closeMDRFile(m);

  printf("ok!\n");
  return 0;

err:
  closeMDRFile(m);
  return -1;

}

int main(int argc, char *argv[])
{
  char pcmbody[PATH_MAX];
  char *pcmfile = NULL;
  char *mdrfile = NULL;

  // タイトル
  printf("%s %s by %s\n", PRG_NAME, PRG_VER, PRG_AUTHOR);

  if (argc < 2)
  {
    printf("Usage %s <.mdr file> [PCM file]\n");
    return 1;
  }

  mdrfile = argv[1];

  printf("File:%s\n", mdrfile);

  // 外部PCMファイル指定
  if (argc > 2)
  {
    pcmfile = argv[2];
  }

  // MDRファイルの読み出し
  _mdr m;
  readMDRHeader(mdrfile, &m);

  printf("Size:%d\n", m.size);

  // PCMファイル無指定
  if (!pcmfile)
  {
    pcmfile = pcmbody;
    pcmbody[0] = 0;

    // PCMファイル名が未定義
    if (m.pcmname[0])
    {
      makeDirNameFromPath(pcmfile, mdrfile);
      strcat(pcmfile, m.pcmname);
    }
  }

  if (!pcmfile[0])
  {
    printf("PCM filename is not defined!\n");
    return 1;
  }
  printf("PCM File:%s\n", pcmfile);

  // PCMを詰め込む
  packPCMintoMDR(mdrfile, pcmfile, &m);


  return 0;
}
