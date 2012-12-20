AS=cl65
LD=ld65


all:	ll.65c816.sfc

ll.65c816.sfc:	ll.65c816.o 
	$(LD) -o ll.65c816.sfc --config snes.cfg --obj ll.65c816.o

ll.65c816.o:	ll.65c816.s snes_init.s ll.tiles
	$(AS) -t none -o ll.65c816.o -l ll.65c816.lst -c ll.65c816.s

ll.tiles:	ll.ans ./tools/ansi_to_tile
	./tools/ansi_to_tile < ll.ans > ll.tiles

tools/ansi_to_tile:	
	cd tools && make

clean:
	rm -f *~ *.o *.lst *.sfc ll.tiles
	cd tools && make clean
