#include <stdio.h>
#include <stdlib.h> /* calloc() */

#include "lzss.h"

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

int rle_one(FILE *ansi,FILE *output) {

    int ch,oldchar,byte_count=0,run,elements;
    char temp_string[BUFSIZ];
   
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


    return byte_count;
   
}


int rle_two(FILE *ansi,FILE *output) {

    int ch,oldchar,byte_count=0,run,digit,i,j,match,miss;
    int bufsize=4096;
    int buffer_pointer=0;
    unsigned char *buffer;
#define ANSI_SIZE 8   
    unsigned char ansi_table[128][ANSI_SIZE];
    unsigned char temp_ansi[ANSI_SIZE];
    int ansi_table_entries=0,temp_ansi_pointer;
   
    buffer=(unsigned char *)calloc(bufsize,sizeof(char));
   
loop_w_read:   
    ch=fgetc(ansi);
loop_no_read:   
    if (ch==EOF) goto finished;
   
       /* Handle the escape sequences, which are of form  */
       /* ^[[x;x;......;xm  where x is a number 0<x<255   */
       /*                   and m is a non-numerical char */
       /*	            and ^[ is ascii 27            */
    if (ch==27) {
       ch=fgetc(ansi); /* if ansi, should be '[' which we ignore */

       temp_ansi_pointer=0;
       for(i=0;i<ANSI_SIZE;i++) temp_ansi[i]=0;       
       do {
	  ch=fgetc(ansi);
	  digit=0;

	  do {
	     temp_ansi[temp_ansi_pointer]*=10;
	     temp_ansi[temp_ansi_pointer]+=(ch-0x30);
	     digit++;
	     if (temp_ansi_pointer>3) printf("ERROR digit!\n");
	     ch=fgetc(ansi);     
	  } while( (ch>='0') && (ch<='9'));
	  temp_ansi_pointer++;
	  if (temp_ansi_pointer>(ANSI_SIZE-2)) printf("ERROR ANSI_POINTER!\n");
       } while (ch==';');
       
       temp_ansi[temp_ansi_pointer]=ch;       
       temp_ansi[ANSI_SIZE-1]=temp_ansi_pointer;

              
       /* search for our new pointer in the array */
//       for(i=0;i<ANSI_SIZE;i++) printf(" %i",temp_ansi[i]);
//       printf("\n");
       
       i=0;
       match=0;
       miss=0;
       for(i=0;i<ansi_table_entries;i++) {
	  miss=0;
	  for(j=0;j<ANSI_SIZE;j++) {
	     if (temp_ansi[j]!=ansi_table[i][j]) miss++;
	  }
	  
	  if (!miss) {
	     buffer[buffer_pointer]=i+128;
	     buffer_pointer++;
	     printf("MATCH: %d\n",i);
	     goto skip_add;
	  }
       }

	  for(i=0;i<ANSI_SIZE;i++) {  
	     ansi_table[ansi_table_entries][i]=temp_ansi[i];
	  }
       	     buffer[buffer_pointer]=ansi_table_entries+128;
	     buffer_pointer++;
	     ansi_table_entries++;
	     printf("%i: ",ansi_table_entries-1);
             for(j=0;j<ANSI_SIZE;j++) printf(" %i",temp_ansi[j]);	    
	     printf("\n");
	  
       skip_add:  ;
	  
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

        buffer[buffer_pointer]=run;
        buffer[buffer_pointer+1]=oldchar;
        buffer_pointer+=2;
        goto loop_no_read;
       
    }

    goto loop_w_read;
 
finished:        
   
   
   
   
       /* The symbol we use for the logo */
    fprintf(output,"newest_logo:\n");

       /* I wrote this part like an assembly program w evil goto's       */
       /* because I am too lazy to work out the equivelant while() loops */    

    fprintf(output,"\t.byte\t%i\n",ansi_table_entries);
    byte_count++;
   
    for(i=0;i<ansi_table_entries;i++) {
       fprintf(output,"\t.byte\t");
       for(j=0;j<ANSI_SIZE;j++) {
	  fprintf(output,"%i%c",ansi_table[i][j],j==ANSI_SIZE-1?'\n':',');
       }
    }
    byte_count+=(ANSI_SIZE*ansi_table_entries);

    fprintf(output,"\t.byte\t");
    for(i=0;i<buffer_pointer;i++) {
       fprintf(output,"%i%c",buffer[i],i==buffer_pointer-1?'\n':',');
    }
    byte_count+=buffer_pointer;
   
    fprintf(output,"\t.byte\t0,0\n");
    byte_count+=2;


    return byte_count;
   
}

int main(int argc, char **argv) {
      
    FILE *output,*header,*ansi;
    int ch,byte_count=0,orig_byte_count=0;

       /* Check command line arguments */
    if (argc<2) {
       printf("\nUseage:\n\t%s ansi_file\n\n",argv[0]);
       return 3;
    }

       /* Open input file */
    ansi=fopen(argv[1],"r");
    if (ansi==NULL) {
       printf("Could not open \"%s\"\n",argv[1]);
       return 2;
    }   

   
    /* RLE version */
    output=fopen("logo.inc","w");
    if (output==NULL) {
       printf("Could not open \"logo.inc\"\n");
       return 1;
    }
    byte_count=rle_one(ansi,output);
    printf("Size of RLE version: %i\n",byte_count);   
    fclose(output);



    /* Old lzss version */   
    output=fopen("logo.lzss","w");
    if (output==NULL) {
       printf("Could not open \"logo.lzss\"\n");
       return 1;
    }

    rewind(ansi);
    byte_count=lzss_encode(ansi,output);
    printf("Size of LZSS version: %i\n",byte_count);
    fclose(output);


    /* new lzss */
    output=fopen("logo.lzss_new","w");
    if (output==NULL) {
       printf("Could not open \"logo.lzss_new\"\n");
       return 1;
    }   
    header=fopen("logo.include","w");
    if (header==NULL) {
       printf("Could not open \"header\"\n");
       return 1;
    }
      
    rewind(ansi);
    byte_count=lzss_encode_better(ansi,header,output,'\0',1024,2,0);


    printf("Size of LZSS-NEW version: %i\n",byte_count);
    fclose(output);
    fclose(header);

    /* PA-RISC lzss */
    output=fopen("logo.lzss_new.parisc","w");
    if (output==NULL) {
       printf("Could not open \"logo.lzss_new.parisc\"\n");
       return 1;
    }   
    header=fopen("logo.include.parisc","w");
    if (header==NULL) {
       printf("Could not open \"header\"\n");
       return 1;
    }
    rewind(ansi);
    lzss_encode_better(ansi,header,output,'\0',1024,2,1);

    fclose(output);
    fclose(header);
    rewind(ansi);

    
    /* calculate size of original */
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
