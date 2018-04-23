#include <stdlib.h>
#include <stdio.h>

#define BLOCKS 16

struct header {                 /* byte offset */
  char name[100];               /*   0 */
  char mode[8];                 /* 100 */
  char uid[8];                  /* 108 */
  char gid[8];                  /* 116 */
  char size[12];                /* 124 */
  char mtime[12];               /* 136 */
  char chksum[8];               /* 148 */
  char typeflag;                /* 156 */
  char linkname[100];           /* 157 */
  char magic[6];                /* 257 */
  char version[2];              /* 263 */
  char uname[32];               /* 265 */
  char gname[32];               /* 297 */
  char devmajor[8];             /* 329 */
  char devminor[8];             /* 337 */
  char prefix[155];             /* 345 */
                                /* 500 */
};


int correct_hdr(struct header *hdr, int *blocks) {
  long size, mtime;
  int i;

  for (i=1;i<12;i++) hdr->size[i-1]=hdr->size[i];
  for (i=1;i<12;i++) hdr->mtime[i-1]=hdr->mtime[i];
  hdr->size[11]='\0'; hdr->mtime[11]='\0';

  sscanf(hdr->size,"%lo",&size);
  sscanf(hdr->mtime,"%lo",&mtime);

  snprintf(hdr->size,12,"%011lo",size);
  snprintf(hdr->mtime,12,"%011lo",mtime);

  *blocks=(size)?1+(size-1)/512:0;

  return 0;
}


int chksum_hdr(struct header *hdr) {
  unsigned char *ptr=(unsigned char *)(void*)hdr;
  int i, sum=0;

  for (i=0;i<8;i++) hdr->chksum[i]=' ';
  for (i=0;i<512;i++) sum+=*ptr++;
  snprintf(hdr->chksum,8,"%06o",sum);

  return 0;
}


int main(int argc, const char* argv[]) {
  unsigned char buf[BLOCKS*512];
  FILE *in, *out;
  int len, num;

  if (argc<=2) return -1;

  if ((in=fopen(argv[1],"rb"))==NULL) return -2;
  if ((out=fopen(argv[2],"wb"))==NULL) return -3;

  while (!feof(in)) {

    len=fread(buf,512,1,in);

    if (buf[0]) {
      correct_hdr((struct header*)(void*)buf,&num);
      chksum_hdr((struct header*)(void*)buf);
    } else num=0;

    if (fwrite(buf,512,len,out)!=len) { printf("Write error!\n"); exit; }

    while (num) {
      len=fread(buf,512,(num>BLOCKS)?BLOCKS:num,in);
      if (fwrite(buf,512,len,out)!=len) { printf("Write error!\n"); exit; }
      num-=len;
    }

  }  

  fclose(in); fclose(out);

  return 0;
}
