#include <stdio.h>

    /* This program creates the "logo.inc" file used by "ll" */
    /* It takes a standard file with ansi escape sequences   */
    /* and outputs gnu assembler, run-length-encoded         */

    /* The RLE encoding reduces size by 1k+ on the standard   */
    /* logo which is repetitive.  This might not be ideal for */
    /* more complicated pictures.  In that case you might be  */
    /* best off with an empty-logo and "cat"ing your ansi     */
    /* before running "ll" if you are optimizing for size     */

    /* How the format works: */
       /* first character is char to output, second is run-length     */
       /* if first char is ESC (27) then what follows is a color      */
       /* to be print using "^[[xm" where x is the color              */
       /* 0,0 pair signifies EOF                                      */
       /* I could have compressed this more, but I left it generic    */
       /* enough that _any_ logo, not just default, can be used       */
       /* we could save a mov instruction by flipping order of fields */
       /* oh well                                                     */
        
int main(int argc, char **argv) {
   
   
    FILE *ansi,*output;
    int ch,oldchar,run,elements,byte_count=0,orig_byte_count=0;
    char temp_string[BUFSIZ];
   
       /* Hard coded output.  This shouldn't be a problem I hope */
    output=fopen("logo.inc","w");
    if (output==NULL) {
       printf("Could not open \"logo.inc\"\n");
       return 1;
    }
   
       
    if (argc<2) {
       printf("\nUseage:\n\t%s ansi_file\n\n",argv[0]);
    }
   
    ansi=fopen(argv[1],"r");
    if (ansi==NULL) {
       printf("Could not open \"%s\"\n",argv[1]);
       return 2;
    }
   
       /* The symbol we use for the logo */
    fprintf(output,"new_logo:\n");

       /* I wrote this part like an assembly program w evil goto's       */
       /* because I am too lazy to work out the equivelant while() loops */    
loop_w_read:   
    ch=fgetc(ansi);
loop_no_read:   
    if (ch==EOF) goto finished;
   
       /* Handle the escape sequences, which are of form  */
       /* ^[[x;x;......;xm  where x is a number 0<x<255   */
       /*                   and m is a non-numerical char */
       /*	            and ^[ is ascii 27            */
    if (ch==27) {
       fprintf(output,"\t.byte\t27, "); byte_count++;
       ch=fgetc(ansi); /* if ansi, should be '[' which we ignore */
       
       run=0;
       elements=0;
       do {
	  ch=fgetc(ansi);
          elements++;
	  do {
	     temp_string[run]=ch; run++;
	     ch=fgetc(ansi);     
	  } while( (ch>='0') && (ch<='9'));
	  byte_count++;
	  temp_string[run]=','; run++;
	  temp_string[run]=' '; run++;
       } while (ch==';');
       temp_string[run]='\0';
       fprintf(output,"%i, %s '%c'\n",elements,temp_string,ch);
       byte_count+=2;
    }
       /* not part of escape sequence, so we RLE encode */
    else {
       run=1;
       
       run_loop:
          oldchar=ch;
          ch=fgetc(ansi);
          if (ch==oldchar) {
             run++;
             goto run_loop;
          }
             /* if non-printable, ',", or \ we print the decimal value */
             /* as these might be confused if put into a string        */
          fprintf(output,"\t.byte\t");
          if ( (oldchar==0x5c) || (oldchar==0x27) || (oldchar==0x22) ||
	       (oldchar<0x20) || (oldchar>0x7e)) {
	     fprintf(output,"%i",oldchar);  
	  }
          else 
             fprintf(output,"'%c'",oldchar);
       
          fprintf(output,", %i\n",run);
          byte_count+=2;
          goto loop_no_read;
       
    }

    goto loop_w_read;
 
finished:   

    fprintf(output,"\t.byte\t0,0\n");
    byte_count+=2;
    fclose(output);
    fclose(ansi);
   
    printf("Size of RLE version: %i\n",byte_count);
    ansi=fopen(argv[1],"r");
    while((ch=fgetc(ansi))!=EOF) {
	orig_byte_count++;
    }
    fclose(ansi);
    printf("Size of original version: %i\n",orig_byte_count);	
    
    if (orig_byte_count<byte_count) {
	printf("!!! e-mail vince and tell him to add a no-compress mode\n");
     }
   
    return 0;
						    
}
