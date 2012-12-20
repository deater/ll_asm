/* dumps a 2bpp snes tileset to ASCII asm suitable for including */


#include <stdio.h>

int main(int argc, char **argv) {
 
   int i,j,k;
   unsigned char temp;
   
   for(i=0;i<256;i++) {
      
      if ((i>=0x20) && (i<127))
         printf("Char : 0x%x %c\n",i,i);
      else
	 printf("Char : 0x%x\n",i);
      
      for(j=0;j<16;j++) {
	 if (fread(&temp,1,1,stdin)<1) return -1;
	 printf("0x%02x : ",temp);
	 for(k=0;k<8;k++) {
	    if ((1<<(7-k))&temp) {
	       printf("#");
	    }
	    else {
	       printf(" ");
	    }
	 }
	 printf("\n");

      }
   }
   
   return 0;
   
}
