all:	LL_6502


LL_6502:	ll_6502 
		make_b ./ll_6502 ./LL_6502 0xC00

ll_6502:	ll_6502.o
	ld65 -C ./apple2_c00.inc -o ll_6502 ll_6502.o

ll_6502.o:	ll_6502.s
		ca65 -o ll_6502.o -l ll_6502.s

disk:		
		dos33 ll_6502.dsk SAVE B LL_6502
		

clean:		
		rm -f *.lst *.o ll_6502 *~ add_to_disk LL_6502 make_b a.out
