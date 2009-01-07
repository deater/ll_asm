ANSI_TO_USE = banner_logo.ansi

#CRIS_EXTRA=--section-start .text=0x80000
#CRIS_EXTRA=--section-alignment 0x1000

ifeq ($(ARCH),)
   ARCH = $(shell uname -m)
endif

# Fix the ARCH for architectures who have multiple names for same thing

#
# See if arch has "86" in it (ie, 386,486,586,686) but _not_ x86_64
#
ifneq (,$(findstring 86,$(ARCH)))
   ifeq (,$(findstring x86_64,$(ARCH)))
      ARCH := i386
   endif
endif

#
# Handle various ARM variants
#
ifneq (,$(findstring arm,$(ARCH)))
   ARCH := arm
   THUMB := ll_thumb
endif

#
# Handle CRIS
#
ifneq (,$(findstring cris,$(ARCH)))
   ARCH := crisv32
   C_EXTRA := --march=v32
endif

#
# Handle SPARC
#
ifneq (,$(findstring sparc,$(ARCH)))
   ARCH := sparc
endif

#
# Handle MIPS
#
ifneq (,$(findstring mips,$(ARCH)))
   ARCH := mips
   THUMB := ll_mips16
endif


CC = gcc
CFLAGS = -O2 -Wall
LFLAGS = 

all:	ll $(THUMB) ansi_compress ./sstrip/sstrip

sstrip_ll: ll ./sstrip/sstrip
	./sstrip/sstrip ll

./sstrip/sstrip:
	cd sstrip && make
       
ansi_compress:  ansi_compress.o lzss.o lzss_new.o 
	$(CC) $(LDFLAFS) -o ansi_compress ansi_compress.o lzss.o lzss_new.o

ansi_compress.o:    ansi_compress.c
	$(CC) $(CFLAGS) -c ansi_compress.c

lzss.o:	   lzss.c
	$(CC) $(CFLAGS) -c lzss.c

lzss_new.o:    lzss_new.c
	$(CC) $(CFLAGS) -c lzss_new.c


#ll_c.o:	ll_c.c
#	$(CC) $(CFLAGS) -c -g ll_c.c
	
#ll_c:	ll_c.o logo.lzss_new.h
#	$(CC) $(LFLAGS) -o ll_c ll_c.o

#
# The -N option avoids padding the .text segment, at least on x86_64
#

ll:	ll.o
	$(CROSS)$(LD) $(L_EXTRA) -N -o ll ll.o	

ll.o:	ll.s logo.lzss
	$(CROSS)$(AS) $(C_EXTRA) -o ll.o ll.s

ll_thumb:	ll.thumb.o
	$(CROSS)$(LD) -N --thumb-entry=_start -o ll_thumb ll.thumb.o

ll.thumb.o:	ll.thumb.s
	$(CROSS)$(AS) -mthumb-interwork -o ll.thumb.o ll.thumb.s

ll.mips16.o:	ll.mips16.s
	$(CROSS)$(AS) -EL -o ll.mips16.o ll.mips16.s
	
ll_mips16:	ll.mips16.o
	$(CROSS)$(LD) -EL -N -o ll_mips16 ll.mips16.o

ll.s:	
	rm -f ll.s
	ln -s ll.$(ARCH).s ll.s
		   
logo.inc:	   $(ANSI_TO_USE) ansi_compress
		   ./ansi_compress $(ANSI_TO_USE)

logo.lzss:	   $(ANSI_TO_USE) ansi_compress
		   ./ansi_compress $(ANSI_TO_USE)

clean:
	rm -f ll ll_c *.o *~ ll.s ll_thumb ll_mips16 ansi_compress logo.inc logo.lzss logo.lzss_new core logo.include logo_optimize logo.include.parisc logo.lzss_new.parisc a.out
	cd sstrip && make clean


