#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
   
   char buffer[BUFSIZ],*result;
   int i;
	       
   while(1) {
      result=fgets(buffer,BUFSIZ,stdin);
      if (result==NULL) return 0;
      
      printf("\t.byte ");
      for(i=0;i<strlen(buffer)-1;i++) {
	 printf("$%2x, ",buffer[i]);
      }
      printf("\n");
    
      
   }
 
   return 0;
}
