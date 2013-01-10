#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {

   char buffer[BUFSIZ],*result;
   int i;
   int quotes_open=0;

   while(1) {
      result=fgets(buffer,BUFSIZ,stdin);
      if (result==NULL) return 0;

      printf("\t.byte ");
      for(i=0;i<strlen(buffer);i++) {
	 if (buffer[i] < 32) {
	    if (quotes_open) printf("\",");
	    printf("$%02x",buffer[i]);
	    if (i<strlen(buffer)-1) printf(", ");
	    quotes_open=0;
	 }
	 else {
	    if (!quotes_open) printf("\"");
	    printf("%c",buffer[i]);
	    quotes_open=1;
	 }
      }
      if (quotes_open) printf("\"");
      quotes_open=0;
      printf("\n");

   }

   return 0;
}
