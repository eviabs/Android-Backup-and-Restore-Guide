#include <stdlib.h>
#include <stdio.h>

#define AB_HEADER "ANDROID BACKUP\n1\n1\nnone\n"

#pragma pack(1)

struct block {
  unsigned char type;
  unsigned short size;
  unsigned short compl;
};

int sizes[]={0xfffb,0x8005,0x8000};

int main(int argc, const char* argv[]) {
  unsigned char buf[65536];
  struct block bl;
  FILE *in, *out;
  int len, cnt=0;

  if (argc<=2) return -1;

  if ((in=fopen(argv[1],"rb"))==NULL) return -2;
  if ((out=fopen(argv[2],"wb"))==NULL) return -3;

  sprintf(buf,AB_HEADER); len=24;
  if (fwrite(buf,1,len,out)!=len) { printf("Write error!\n"); exit; }

  buf[0]=0x78; buf[1]=0x01; len=2;
  if (fwrite(buf,1,len,out)!=len) { printf("Write error!\n"); exit; }

  while (!feof(in)) {

    len=fread(buf,1,sizes[cnt],in);

    bl.size=len; bl.compl=65535-bl.size;
    bl.type=(len==sizes[cnt])?0:1;
    
    if (fwrite(&bl,1,5,out)!=5) { printf("Write error!\n"); exit; }
    if (fwrite(buf,1,len,out)!=len) { printf("Write error!\n"); exit; }

    if (cnt<2) cnt++;
  }  

  buf[0]=buf[1]=buf[2]=buf[3]=0;  // checksum???
  if (fwrite(buf,1,4,out)!=4) { printf("Write error!\n"); exit; }

  fclose(in); fclose(out);

  return 0;
}
