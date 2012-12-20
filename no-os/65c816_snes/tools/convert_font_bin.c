/* converts a VGA type font (well the top half of one) */
/* into a 2bpp SNES tilemap.                           */
/* mainly for use converting my TB1 font               */

#include <stdio.h>

int main(int argc, char **argv) {
 
   int i,j;
   unsigned char temp;
   
   for(i=0;i<128;i++) {            
      for(j=0;j<16;j++) {
	 if (fread(&temp,1,1,stdin)<1) return -1;
	 if (j<8) {
	    fwrite(&temp,1,1,stdout); /* plane 1 */
	    fwrite(&temp,1,1,stdout); /* plane 2 */
	 }
      }
   }
   
   return 0;
   
}
