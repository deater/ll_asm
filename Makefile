ANSI_TO_USE = banner_logo.ansi

all:	ll configure ansi_compress

ansi_compress:  ansi_compress.o lzss.o
	   gcc -o ansi_compress ansi_compress.o lzss.o
	   
ansi_compress.o:    ansi_compress.c	   
	   gcc -O2 -Wall -c ansi_compress.c

lzss.o:	   lzss.c
	   gcc -O2 -Wall -c lzss.c

ll:	ll.o
	ld -o ll ll.o
	@strip ll
	
ll.o:	ll.s 
	as -o ll.o ll.s

ll.s:	configure logo.inc
	./configure
	
logo.inc:	   $(ANSI_TO_USE) ansi_compress
		   ./ansi_compress $(ANSI_TO_USE)

logo.lzss:	   $(ANSI_TO_USE) ansi_compress
		   ./ansi_compress $(ANSI_TO_USE)

configure:	configure.c
	gcc -O2 -Wall -o configure configure.c

clean:
	rm -f ll *.o *~ configure ll.s ansi_compress logo.inc logo.lzss core
