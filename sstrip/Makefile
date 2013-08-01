#  Makefile for sstrip

ifeq ($(ARCH),)
 ARCH = $(shell uname -m)
endif

all:	sstrip

sstrip32:	sstrip.c
	gcc -ggdb -DOVERRIDE_32=1 -Wall -W -DARCHITECTURE=\"asm_elf_$(ARCH).h\" -o sstrip32 sstrip.c

sstrip: sstrip.c
	gcc -ggdb -Wall -W -DARCHITECTURE=\"asm_elf_$(ARCH).h\" -o sstrip sstrip.c

clean:
	rm -f sstrip sstrip32 *~ *.o
