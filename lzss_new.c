/**************************************************************
	LZSS.C -- A Data Compression Program
	(tab = 4 spaces)
***************************************************************
	4/6/1989 Haruhiko Okumura
	Use, distribute, and modify this program freely.
	Please send me your improved versions.
		PC-VAN		SCIENCE
		NIFTY-Serve	PAF01022
		CompuServe	74050,1022
**************************************************************
 
         WARNING: order of match_position and match_lenght changed!
         see lines 178 to 182
         Mofication by <stephan.walter@gmx.ch>

 
         Also modified to have N,F,etc, etc to be parameters, not
         hard-coded  -- vmw
 */



#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "lzss.h"

#define num_trees 256

  /* initialize trees */
void newInitTree(int ring_buffer_size,int binary_search_index,
		 int *rson, int *dad) {
	
    int  i;

	/* For i = 0 to N - 1, rson[i] and lson[i] will be the right and
	   left children of node i.  These nodes need not be initialized.
	   Also, dad[i] is the parent of node i.  These are initialized to
	   NIL (= N), which stands for 'not used.'
	   For i = 0 to 255, rson[N + i + 1] is the root of the tree
	   for strings that begin with character i.  These are initialized
	   to NIL.  Note there are 256 trees. */

    for (i=ring_buffer_size+1; i<=ring_buffer_size+num_trees; i++) 
        rson[i] = binary_search_index;
    for (i=0; i<ring_buffer_size; i++) dad[i] = binary_search_index;
}

void newInsertNode(int r, int ring_buffer_size, int binary_search_index,
		   int match_length_limit,
		   unsigned char *text_buf, int *rson,int *lson, int *dad,
		   int *match_length, int *match_position) {
	/* Inserts string of length F, text_buf[r..r+F-1], into one of the
	   trees (text_buf[r]'th tree) and returns the longest-match position
	   and length via the global variables match_position and match_length.
	   If match_length = F, then removes the old node in favor of the new
	   one, because the old one will be deleted sooner.
	   Note r plays double role, as tree node and position in buffer. */

    int  i, p, cmp;
    unsigned char  *key;

    cmp = 1;  
    key = text_buf+r;  
    p = ring_buffer_size + 1 + key[0];
    rson[r] = lson[r] = binary_search_index;  
    *match_length = 0;
	
    for( ; ; ) {
       
       if (cmp >= 0) {
	  if (rson[p] != binary_search_index) p = rson[p];
	  else {  
	     rson[p] = r;  
	     dad[r] = p;  
	     return;  
	  }
       } 
       
       else {
          if (lson[p] != binary_search_index) p = lson[p];
	  else {  
	     lson[p] = r;  
	     dad[r] = p;  
	     return;  
	  }		
       }
       
       for(i = 1; i < match_length_limit; i++)
	  if ((cmp = key[i] - text_buf[p + i]) != 0)  break;
       if (i > *match_length) {
	  *match_position = p;
	  if ((*match_length = i) >= match_length_limit)  break;
       }

    }

    dad[r] = dad[p];  
    lson[r] = lson[p];  
    rson[r] = rson[p];
    dad[lson[p]] = r;  
    dad[rson[p]] = r;
    
    if (rson[dad[p]] == p) rson[dad[p]] = r;
    else                   lson[dad[p]] = r;
    dad[p] = binary_search_index;  /* remove p */

}

  /* deletes node p from tree */
void newDeleteNode(int p, int binary_search_index, 
		   int *dad, int *rson, int *lson) {
   
    int  q;
	
    if (dad[p] == binary_search_index) return;  /* not in tree */
    if (rson[p] == binary_search_index) q = lson[p];
    else if (lson[p] == binary_search_index) q = rson[p];
    else {
       q = lson[p];
       if (rson[q] != binary_search_index) {
	  do {  q = rson[q];  } while (rson[q] != binary_search_index);
	  rson[dad[q]] = lson[q];  
	  dad[lson[q]] = dad[q];
	  lson[q] = lson[p];  
	  dad[lson[p]] = q;
       }
       rson[q] = rson[p];  dad[rson[p]] = q;
    }
    dad[q] = dad[p];
    if (rson[dad[p]] == p) rson[dad[p]] = q;  
    else lson[dad[p]] = q;
    dad[p] = binary_search_index;
}

int lzss_encode_better(FILE *infile,FILE *header,FILE *outfile,
		       unsigned char frequent_char,
		       int ring_buffer_size, int position_length_threshold,
		       int output_type) {

//    unsigned char frequent_char='#';
//    int ring_buffer_size=1024;  /* N */
      int match_length_limit;  //=64;  /* F */
      /*int position_length_threshold=2;  THRESHOLD */
      int binary_search_index=ring_buffer_size;  /* NIL */
      int position_bits; //=10;
//    int length_bits=16-position_bits;
   
    unsigned long int codesize = 0;	/* code size counter */
   
    int  i, c, len, r, s, last_match_length, code_buf_ptr;
    
    unsigned char  code_buf[8*2+1], mask;

    unsigned char *text_buf;

    int match_position, match_length;  /* of longest match.  These are
			                 set by the InsertNode() procedure. */
    int *lson, *rson, *dad;  /* left & right children &
			                        parents -- These constitute 
					        binary search trees. */
   
   
    /* determine stuff from ring_buffer_size */
    /* fake log2 algorithm */
    
    i=1;
    while (((ring_buffer_size-1)>>i) >=1) {
       i++;  
    };
    
    position_bits=i;
    match_length_limit=1<<(16-position_bits);
//    printf("%i, %i %i %i '%c'\n",ring_buffer_size,position_bits,match_length_limit
//          ,position_length_threshold,frequent_char); 
   
   
    
   
   
   
                                   /* ring buffer of size N, with extra F-1 
				      bytes to facilitate string comparison */
    text_buf=calloc(ring_buffer_size+match_length_limit-1,sizeof(unsigned char));
    lson=calloc(ring_buffer_size+1,sizeof(int));
    rson=calloc(ring_buffer_size+num_trees+1,sizeof(int));
    dad=calloc(ring_buffer_size+1,sizeof(int));

    newInitTree(ring_buffer_size,binary_search_index,rson,dad);  /* initialize trees */

    code_buf[0] = 0;  /* code_buf[1..16] saves eight units of code, and
		         code_buf[0] works as eight flags, "1" representing 
		         that the unit is an unencoded letter (1 byte), 
		         "0" a position-and-length pair (2 bytes).  
		         Thus, eight units require at most 16 bytes of code. */
    code_buf_ptr = mask = 1;
    s = 0;  
    r = ring_buffer_size - match_length_limit;
   
    if (header!=NULL) {
       if (output_type==PARISC) {
	  fprintf(header,"FREQUENT_CHAR: .equ %i\n",frequent_char);
          fprintf(header,"N: .equ %i\n",ring_buffer_size);
          fprintf(header,"F: .equ %i\n",match_length_limit);
          fprintf(header,"THRESHOLD: .equ %i\n",position_length_threshold);
          fprintf(header,"P_BITS: .equ %i\n",position_bits);
          fprintf(header,"POSITION_MASK: .equ %i\n",(0xff>>(8-(position_bits-8))));
       }
       else if (output_type==NORMAL_ASM) {
	 if (frequent_char<32) {
            fprintf(header,".equ FREQUENT_CHAR,%d\n",frequent_char);
	 }
	 else {
	    fprintf(header,".equ FREQUENT_CHAR,'%c'\n",frequent_char);
	 }
         fprintf(header,".equ N,%i\n",ring_buffer_size);
         fprintf(header,".equ F,%i\n",match_length_limit);
         fprintf(header,".equ THRESHOLD,%i\n",position_length_threshold);
         fprintf(header,".equ P_BITS,%i\n",position_bits);
         fprintf(header,".equ POSITION_MASK,%i\n",(0xff>>(8-(position_bits-8))));
       }
       else if (output_type==C) {
//	 fprintf(header,"#define FREQUENT_CHAR '%c'\n",frequent_char);
         fprintf(header,"#define N %i\n",ring_buffer_size);
         fprintf(header,"#define F %i\n",match_length_limit);
         fprintf(header,"#define THRESHOLD %i\n",position_length_threshold);
         fprintf(header,"#define P_BITS %i\n",position_bits);
         fprintf(header,"#define POSITION_MASK %i\n",(0xff>>(8-(position_bits-8))));
       }
    }

    if (outfile==NULL) return 0;
   
    if (output_type!=C) {
       fprintf(outfile,"logo:\n");
    }
    else {
       fprintf(outfile,"unsigned char logo[]={\n");  
    }
       /* Clear the buffer with any character that will appear often. */
    for(i=0; i<(ring_buffer_size-match_length_limit); i++) 
       text_buf[i]=frequent_char;  

//    printf("%i to %i = %i\n",0,ring_buffer_size-match_length_limit,frequent_char);

//    printf("%i to %i = ",r,r+match_length_limit);
    for(len=0; len<match_length_limit && (c=getc(infile))!=EOF; len++) {
	  text_buf[r+len]=c;  /* Read F bytes into the last F bytes of
			         the buffer */
 //         printf("%i ",text_buf[r+len]);
    }
 //   printf("\n");
    if (len== 0) return 0;  /* trying to compress empty file */

    for(i = 1; i <= match_length_limit; i++) 
          newInsertNode(r-i,ring_buffer_size,binary_search_index,
		        match_length_limit,text_buf,rson,lson,dad,
		        &match_length,&match_position);

             /* Insert the F strings,
		each of which begins with one or more 'space' characters.  Note
		the order in which these strings are inserted.  This way,
		degenerate trees will be less likely to occur. */
    newInsertNode(r,ring_buffer_size,binary_search_index,
		     match_length_limit,text_buf,rson,lson,dad,
		     &match_length,&match_position);
               /* Finally, insert the whole string just read.  The
		global variables match_length and match_position are set. */
    do {
       if (match_length > len) match_length = len;  /* match_length
			may be spuriously long near the end of text. */
       if (match_length <= position_length_threshold) {
	  match_length=1;  /* Not long enough match.  Send one byte. */
	  code_buf[0] |= mask;  /* 'send one byte' flag */
	  code_buf[code_buf_ptr++] = text_buf[r];  /* Send uncoded. */
//	  printf("single: %i @ %i\n",text_buf[r],r);
       } else {
//	  printf("pos : %i\tlen : %i\n",match_position,match_length);
	  
          code_buf[code_buf_ptr++] = (unsigned char) match_position;
	  

	  code_buf[code_buf_ptr++] = (unsigned char)
	         ( ((match_position>>8) & (0xff >> (8-(position_bits-8)))) |
	         ((match_length-(position_length_threshold+1))<<(position_bits-8)) );
	  
//	  code_buf[code_buf_ptr++] = (unsigned char)
//                                     (((match_position >> 8) & 7) | 
//			  (match_length - (position_length_threshold+1))<<3);
		          		     
       }
       if ((mask <<= 1) == 0) {  /* Shift mask left one bit. */		   
          if (output_type!=C) {
	     fprintf(outfile,"\t.byte\t");
	     for(i=0; i<code_buf_ptr; i++) { /* Send at most 8 units of */
	        fprintf(outfile,"%d%c",code_buf[i],(i==code_buf_ptr-1)?'\n':',');
	     }
	  }
	  else {
	     fprintf(outfile,"\t");
	     for(i=0; i<code_buf_ptr; i++) { /* Send at most 8 units of */
	        fprintf(outfile,"%d,%c",code_buf[i],(i==code_buf_ptr-1)?'\n':' ');
	     }
	  }
	  codesize += code_buf_ptr;
	  code_buf[0] = 0;  code_buf_ptr = mask = 1;
       }
       last_match_length = match_length;
       for (i = 0; i < last_match_length && (c = getc(infile)) != EOF; i++) {
	  newDeleteNode(s,binary_search_index, 
		                      dad,rson,lson);		/* Delete old strings and */
	  text_buf[s] = c;	/* read new bytes */
	  if (s < match_length_limit - 1) text_buf[s + ring_buffer_size] = c;  /* If the position is
				near the end of buffer, extend the buffer to make
				string comparison easier. */
	  s = (s + 1) & (ring_buffer_size - 1);  
	  r = (r + 1) & (ring_buffer_size - 1);
				/* Since this is a ring buffer, increment the position
				   modulo N. */
	  newInsertNode(r,ring_buffer_size,binary_search_index,
		        match_length_limit,text_buf,rson,lson,dad,
		        &match_length,&match_position);	
		   /* Register the string in text_buf[r..r+F-1] */
       }
		
       while (i++ < last_match_length) {	/* After the end of text, */
          newDeleteNode(s,binary_search_index, 
		                      dad,rson,lson);					/* no need to read, but */
	  s = (s + 1) & (ring_buffer_size - 1);  
	  r = (r + 1) & (ring_buffer_size - 1);
	  if (--len) newInsertNode(r,ring_buffer_size,binary_search_index,
		     match_length_limit,text_buf,rson,lson,dad,
		     &match_length,&match_position); 
		     /* buffer may not be empty. */
       }
    } while (len > 0);	/* until length of string to be processed is zero */
	
    if (code_buf_ptr > 1) {		/* Send remaining code. */
       if (output_type!=C) {
          fprintf(outfile,"\t.byte\t");
       }
       else {
	  fprintf(outfile,"\t");
       }
	  
       for(i=0; i<code_buf_ptr; i++) {
	  fprintf(outfile,"%d",code_buf[i]);
	  if (output_type!=C) {
	     if (i==code_buf_ptr-1) {
		fprintf(outfile,"\n");
	     } else {
		fprintf(outfile,",");
	     }
	  }
	  else {
	     if (i==code_buf_ptr-1) {
		fprintf(outfile,",\n");
	     } else {
		fprintf(outfile,",");
	     }		
	  }          
       }
       codesize += code_buf_ptr;
    }
    if (output_type!=C) {
       fprintf(outfile,"logo_end:\n");
    }
    else {
       fprintf(outfile,"};\n");
    }
    
    free(text_buf);
    free(lson);
    free(rson);
    free(dad);
    return codesize;
}
