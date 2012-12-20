/* converts a VGA type font (well the top half of one) */
/* into a 2bpp SNES tilemap.                           */
/* mainly for use converting my TB1 font               */

#include <stdio.h>

int main(int argc, char **argv) {
 
   int i,j,k;
   unsigned char temp;
   
   for(i=0;i<128;i++) {  
      
      if ((i>=0x20) && (i<127))
         printf("; Char : 0x%x %c\n",i,i);
      else
	 printf("; Char : 0x%x\n",i);
      
      for(j=0;j<16;j++) {
	 if (fread(&temp,1,1,stdin)<1) return -1;
	 if (j<8) {
	    fprintf(stdout,".byte $%02x,$%02x\t",temp,temp);  
	    fprintf(stdout,"; ");
	    for(k=0;k<8;k++) {
	       if ((1<<(7-k))&temp) {
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
   
   return 0;
   
}
      

