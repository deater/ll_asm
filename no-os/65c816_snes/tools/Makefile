CC = gcc
CFLAGS = -O2 -Wall
LFLAGS =

all:	bin2byte color_convert convert_font convert_font_bin \
	dump_font make_pal pcx_to_sprite pcx_to_tiles \
	ansi_to_tile string_to_bytes convert_font_4bpp
	
	
ansi_to_tile:	ansi_to_tile.o
	$(CC) $(LFLAGS) -o ansi_to_tile ansi_to_tile.o

ansi_to_tile.o:	ansi_to_tile.c
	$(CC) $(CFLAGS) -c ansi_to_tile.c


bin2byte:	bin2byte.o
	$(CC) $(LFLAGS) -o bin2byte bin2byte.o

bin2byte.o:	bin2byte.c
	$(CC) $(CFLAGS) -c bin2byte.c


color_convert:	color_convert.o
	$(CC) $(LFLAGS) -o color_convert color_convert.o

color_convert.o:	color_convert.c
	$(CC) $(CFLAGS) -c color_convert.c


convert_font:	convert_font.o
	$(CC) $(LFLAGS) -o convert_font convert_font.o

convert_font.o:	convert_font.c
	$(CC) $(CFLAGS) -c convert_font.c


convert_font_4bpp:	convert_font_4bpp.o
	$(CC) $(LFLAGS) -o convert_font_4bpp convert_font_4bpp.o

convert_font_4bpp.o:	convert_font_4bpp.c
	$(CC) $(CFLAGS) -c convert_font_4bpp.c


convert_font_bin:	convert_font_bin.o
	$(CC) $(LFLAGS) -o convert_font_bin convert_font_bin.o

convert_font_bin.o:	convert_font_bin.c
	$(CC) $(CFLAGS) -c convert_font_bin.c


dump_font:	dump_font.o
	$(CC) $(LFLAGS) -o dump_font dump_font.o

dump_dont.o:	dump_font.c
	$(CC) $(CFLAGS) -c dump_font.c


make_pal:	make_pal.o
	$(CC) $(LFLAGS) -o make_pal make_pal.o

make_pal.o:	make_pal.c
	$(CC) $(CFLAGS) -c make_pal.c


pcx_to_sprite:	pcx_to_sprite.o
	$(CC) $(LFLAGS) -o pcx_to_sprite pcx_to_sprite.o

pcx_to_sprite.o:	pcx_to_sprite.c
	$(CC) $(CFLAGS) -c pcx_to_sprite.c


pcx_to_tiles:	pcx_to_tiles.o
	$(CC) $(LFLAGS) -o pcx_to_tiles pcx_to_tiles.o

pcx_to_tiles.o:	pcx_to_tiles.c
	$(CC) $(CFLAGS) -c pcx_to_tiles.c


string_to_bytes:	string_to_bytes.o
	$(CC) $(LFLAGS) -o string_to_bytes string_to_bytes.o

string_to_bytes.o:	string_to_bytes.c
	$(CC) $(CFLAGS) -c string_to_bytes.c


clean:	
	rm -f *.o *~ bin2byte color_convert convert_font \
		convert_font_bin dump_font make_pal pcx_to_sprite \
		pcx_to_tiles ansi_to_tile string_to_bytes \
		convert_font_4bpp


