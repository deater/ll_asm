all:	LL_6502 PROC_DETECT


LL_6502:	ll_6502 
		make_b ./ll_6502 ./LL_6502 0xC00

ll_6502:	ll_6502.o
	ld65 -C ./apple2_c00.inc -o ll_6502 ll_6502.o

ll_6502.o:	ll_6502.s
		ca65 -o ll_6502.o -l ll_6502.s


PROC_DETECT:	proc_detect 
		make_b ./proc_detect ./PROC_DETECT 0xC00

proc_detect:	proc_detect.o
	ld65 -C ./apple2_c00.inc -o proc_detect proc_detect.o

proc_detect.o:	proc_detect.s
		ca65 -o proc_detect.o -l proc_detect.s


disk:		
		dos33 ll_6502.dsk SAVE B LL_6502
		dos33 ll_6502.dsk SAVE B PROC_DETECT		
		

clean:		
		rm -f *.lst *.o ll_6502 *~ LL_6502 PROC_DETECT proc_detect
