/* converts a VGA type font (well the top half of one) */
/* into a 4bpp SNES tilemap.                           */
/* mainly for use converting my TB1 font               */

#define COLOR 15
#define START_FONT 0x20
#define END_FONT   0x80

#include <stdio.h>

int main(int argc, char **argv) {
 
   int i,j,k,plane;
   unsigned char temp_char[16];
   
   /* Skip to right part of code */
   for(i=0;i<START_FONT;i++) {
      for(j=0;j<16;j++) {
	 if (fread(&temp_char[j],1,1,stdin)<1) return -1;
      }
   }
   
   for(i=START_FONT;i<END_FONT;i++) {  
      
      if ((i>=0x20) && (i<127))
         printf("; Char : 0x%x %c\n",i,i);
      else
	 printf("; Char : 0x%x\n",i);
      
      for(j=0;j<16;j++) {
	 if (fread(&temp_char[j],1,1,stdin)<1) return -1;
      }

      for(plane=0;plane<2;plane++) {
	 fprintf(stdout,"; planes %d and %d\n",plane*2,(plane*2)+1);
         for(j=0;j<16;j++) {
	    if (j<8) {
	       fprintf(stdout,".byte $%02x,$%02x\t",temp_char[j],temp_char[j]);  
	       fprintf(stdout,"; ");
	       for(k=0;k<8;k++) {
	          if ((1<<(7-k))&temp_char[j]) {
	             printf("#");
	          }
	          else {
	             printf(" ");
	          }
	       }
	       fprintf(stdout,"\n");		    
	    }
         }
      }
   }
   return 0;
   
}
      

