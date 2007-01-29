ANSI_TO_USE = banner_logo.ansi

CC = gcc
CFLAGS = -O2 -Wall
LFLAGS = 

all:	ll configure ansi_compress ./sstrip/sstrip

sstrip_ll: ll ./sstrip/sstrip
	./sstrip/sstrip ll

./sstrip/sstrip:
	cd sstrip && make
       
ansi_compress:  ansi_compress.o lzss.o lzss_new.o arch.o
	$(CC) -o ansi_compress ansi_compress.o lzss.o lzss_new.o arch.o
	   
ansi_compress.o:    ansi_compress.c arch.o
	$(CC) $(CFLAGS) -c ansi_compress.c

lzss.o:	   lzss.c
	$(CC) $(CFLAGS) -c lzss.c

lzss_new.o:    lzss_new.c
	$(CC) $(CFLAGS) -c lzss_new.c
			 
arch.o:	arch.c arch.h
	$(CC) $(CFLAGS) -c arch.c

ll:	ll.o
	ld -o ll ll.o	

	
ll.o:	ll.s 
	as -o ll.o ll.s

ll.s:	configure logo.inc
	./configure

logo_optimize:	   logo_optimize.o lzss_new.o
		   gcc -o logo_optimize logo_optimize.o lzss_new.o
		   
logo_optimize.o:   logo_optimize.c
		   gcc -Wall -O2 -c logo_optimize.c

logo.inc:	   $(ANSI_TO_USE) ansi_compress
		   ./ansi_compress $(ANSI_TO_USE)

logo.lzss:	   $(ANSI_TO_USE) ansi_compress
		   ./ansi_compress $(ANSI_TO_USE)

configure:	configure.o arch.o
	$(CC) -o configure configure.o arch.o

configure.o:	configure.c arch.h
	$(CC) $(CFLAGS) -c configure.c

clean:
	rm -f ll *.o *~ configure ll.s ansi_compress logo.inc logo.lzss logo.lzss_new core logo.include logo_optimize
	cd sstrip && make clean
