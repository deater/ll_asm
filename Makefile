ANSI_TO_USE = banner_logo.ansi

all:	ll configure ansi_rle

ansi_rle:  ansi_rle.o
	   gcc -o ansi_rle ansi_rle.o
	   
ansi_rle.o:    ansi_rle.c	   
	   gcc -c ansi_rle.c
	   
ll:	ll.o
	ld -o ll ll.o
	@strip ll
	
ll.o:	ll.s 
	as -o ll.o ll.s

ll.s:	configure logo.inc
	./configure
	
logo.inc:	   $(ANSI_TO_USE) ansi_rle
		   ./ansi_rle $(ANSI_TO_USE)

configure:	configure.c
	gcc -O2 -Wall -o configure configure.c

clean:
	rm -f ll *.o *~ configure ll.s ansi_rle logo.inc core
