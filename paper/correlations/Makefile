CC = gcc
CFLAGS = -O2 -Wall
LFLAGS =

all:	convert_grid

convert_grid:	convert_grid.o
	$(CC) $(LFLAGS) -o convert_grid convert_grid.o

convert_grid.o:	convert_grid.c
	$(CC) $(CFLAGS) -c convert_grid.c


clean:	
	rm -f *~ *.o convert_grid




