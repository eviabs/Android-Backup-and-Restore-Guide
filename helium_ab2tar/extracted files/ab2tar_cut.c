#include <stdlib.h>
#include <stdio.h>

#pragma pack(1)

struct block {
  unsigned char type;
  unsigned short size;
  unsigned short compl;
};


int main(int argc, const char* argv[]) {
  unsigned char buf[65536];
  struct block bl;
  FILE *in, *out;
  int len;

  if (argc<=2) return -1;

  if ((in=fopen(argv[1],"rb"))==NULL) return -2;
  if ((out=fopen(argv[2],"wb"))==NULL) return -3;

  len=fread(buf,1,24,in);
  buf[len]='\0'; printf("%s\n",buf);

  len=fread(buf,1,2,in);
  printf("head? %02x %02x\nblocks? ",buf[0],buf[1]);

  bl.type=0;
  while (!bl.type&&!feof(in)) {

    len=fread(&bl,1,5,in);
    if (bl.size+bl.compl!=65535) printf("@");
    printf("%02x (0x%04x) ",bl.type,bl.size);

    len=fread(buf,1,bl.size,in);
    if (fwrite(buf,1,len,out)!=len) { printf("Write error!\n"); exit; }
  }  

  len=fread(buf,1,4,in);
  printf("\nchksum? %02x %02x %02x %02x\n",buf[0],buf[1],buf[2],buf[3]);

  fclose(in); fclose(out);

  return 0;
}
