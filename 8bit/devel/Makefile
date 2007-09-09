CFLAGS = -O2 -Wall
LFLAGS =
CC = gcc

all:	sim

sim:	sim.o
	$(CC) $(LFLAGS) -o sim sim.o
	
sim.o:	sim.c
	$(CC) $(CFLAGS) -c sim.c
	
clean:	
	rm -f *~ *.o sim
