int lzss_encode(FILE *infile,FILE *outfile);
int lzss_encode_better(FILE *infile,FILE *header,FILE *outfile,  
		       unsigned char frequent_char,
		       int ring_buffer_size, int position_length_threshold);
