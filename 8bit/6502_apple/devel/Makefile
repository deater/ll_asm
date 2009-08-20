CFLAGS = -O2 -Wall
LFLAGS =
CC = gcc

all:	ll_sim findstring_sim

findstring_sim:		     findstring_sim.o sim.o
			     $(CC) $(LFLAGS) -o findstring_sim findstring_sim.o sim.o

findstring_sim.o:	     findstring_sim.c
			     $(CC) $(CFLAGS) -c findstring_sim.c

ll_sim:	ll_sim.o sim.o
	$(CC) $(LFLAGS) -o ll_sim ll_sim.o sim.o
	
ll_sim.o:	ll_sim.c
	$(CC) $(CFLAGS) -c ll_sim.c

sim.o:	sim.c sim.h
	$(CC) $(CFLAGS) -c sim.c

clean:	
	rm -f *~ *.o ll_sim findstring_sim
