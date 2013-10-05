CC = gcc
CFLAGS = -O2 -Wall
LFLAGS = -lm

all:	convert_grid correlate

###

convert_grid:	convert_grid.o
	$(CC) $(LFLAGS) -o convert_grid convert_grid.o

convert_grid.o:	convert_grid.c
	$(CC) $(CFLAGS) -c convert_grid.c

###

correlate:	correlate.o
	$(CC) $(LFLAGS) -o correlate correlate.o

correlate.o:	correlate.c
	$(CC) $(CFLAGS) -c correlate.c

###


clean:	
	rm -f *~ *.o convert_grid correlate




