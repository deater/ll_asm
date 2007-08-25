
/* output types */
#define NORMAL_ASM 0
#define PARISC     1
#define C          3



int lzss_encode(FILE *infile,FILE *outfile);
int lzss_encode_better(FILE *infile,FILE *header,FILE *outfile,  
		       unsigned char frequent_char,
		       int ring_buffer_size, int position_length_threshold,
		       int output_type);
