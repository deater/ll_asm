all:	16

16:	16.o
	$(LD) -Ttext-segment=0x4000 -o 16 16.o

16.o:	16.s
	$(AS) -o 16.o 16.s

clean:	
	rm -f *~ *.o 16
