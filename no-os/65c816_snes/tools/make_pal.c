#include <stdio.h>

int convert_bgr2rgb(int rgb) {
   int r,g,b,bgr;
   
   r=((rgb>>16)>>3)&0x1f;
   g=((rgb>>8)>>3)&0x1f;
   b=(rgb>>3)&0x1f;
   
   bgr=(b<<10)|(g<<5)|r;
   
   return bgr;
}

int main(int argc, char **argv) {
   
   int i,r,g,b,rgb,bgr;
   
   fprintf(stdout,"; 15-color BGR palette\n");
   for(i=0;i<256;i++) {
      if (i%4==0) {
         fprintf(stdout,"; palette %d?\n",i/4);	 
      }
      if (i%4==3) {
         r=((i/4)&1)?0:0xff;
	 g=((i/4)&2)?0:0xff;
	 b=((i/4)&4)?0:0xff;
	 rgb=r<<16|g<<8|b;
	 bgr=convert_bgr2rgb(rgb);
	 fprintf(stdout,".word $%04x\t; %06x\n",bgr,rgb);
      }
      
      else {
         fprintf(stdout,".word $0000\n");
      }
   }
   
 
   return 0;
}
