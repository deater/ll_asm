#include <stdio.h>
#include <stdlib.h> /* calloc() */

#include "lzss.h"

int main(int argc, char **argv) {
      
    FILE *ansi,*stats;
    int byte_count=0,i;

    stats=fopen("logo.stats","w");
    if (stats==NULL) {
       printf("Could not open \"stats\"\n");
       return 1;
    }
   
   
    if (argc<2) {
       printf("\nUseage:\n\t%s ansi_file\n\n",argv[0]);
       return 3;
    }
   
    ansi=fopen(argv[1],"r");
    if (ansi==NULL) {
       printf("Could not open \"%s\"\n",argv[1]);
       return 2;
    }   

       /* Frequent Char test */
//    for(i=0;i<255;i++) {
//       rewind(ansi);
//       byte_count=lzss_encode_better(ansi,NULL,i,1024,2);
//       fprintf(stats,"%i\t%i\n",i,byte_count);
//    }
      
      fprintf(stats,"\n\n");
    for(i=1024;i<2048;i++) {
       rewind(ansi);
       byte_count=lzss_encode_better(ansi,NULL,NULL,'#',i,2);
       printf("%i\t%i\n",i,byte_count);
       fflush(stdout);
    }
    fclose(stats);
    fclose(ansi);
    return 0;
						    
}
