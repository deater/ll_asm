/* converts an .incbin type binary include into an ascii text one */

#include <stdio.h>

int main(int argc, char **argv) {
 
   unsigned char blah;
   int result,count=0;
   
   while(1) {

      result=fread(&blah,1,1,stdin);
      if (result<1) break;
      
      if (count%16==0) {      
         fprintf(stdout,".byte ");	 
      }
      fprintf(stdout,"$%02x",blah);
      if (count%16!=15) {
         fprintf(stdout,",");	 
      }
      else {
         fprintf(stdout,"\n");	 
      }
      count++;
   }
   
   return 0;
}
