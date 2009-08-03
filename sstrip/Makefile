#  Makefile for sstrip

ifeq ($(ARCH),)
 ARCH = $(shell uname -m)
endif

sstrip: sstrip.c
	gcc -ggdb -Wall -W -DARCHITECTURE=\"asm_elf_$(ARCH).h\" -o sstrip sstrip.c

clean:
	rm -f sstrip *~ *.o
