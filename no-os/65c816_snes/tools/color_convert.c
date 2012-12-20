/* converts a 15-bit BGR SNES style color to HTML #RRGGBB style */

#include <stdio.h>

int main(int argc, char **argv) {
   
   int bgr,b,g,r,html;
   
   fscanf(stdin,"%x",&bgr);
 
   b=(bgr>>10)&0x1f;
   g=(bgr>>5)&0x1f;
   r=bgr&0x1f;
   
   printf("rgb %x %x %x\n",r,g,b);
   html=((r<<3)<<16)|((g<<3)<<8)|(b<<3);
   printf("HTML: %x\n",html);
   
   return 0;
}
