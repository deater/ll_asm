ANSI_TO_USE = banner_logo.ansi


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
endif


CC = gcc
CFLAGS = -O2 -Wall
LDFLAGS = 

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

#
# The -N option avoids padding the .text segment, at least on x86_64
#

ll:	ll.o
	$(CROSS)$(LD) -N -o ll ll.o	

ll.o:	ll.s logo.lzss
	$(CROSS)$(AS) -o ll.o ll.s

ll_thumb:	ll.thumb.o
	$(CROSS)$(LD) -N --thumb-entry=_start -o ll_thumb ll.thumb.o

ll.thumb.o:	ll.thumb.s
	$(CROSS)$(AS) -mthumb-interwork -o ll.thumb.o ll.thumb.s

ll.s:	
	rm -f ll.s
	ln -s ll.$(ARCH).s ll.s
		   
logo.inc:	   $(ANSI_TO_USE) ansi_compress
		   ./ansi_compress $(ANSI_TO_USE)

logo.lzss:	   $(ANSI_TO_USE) ansi_compress
		   ./ansi_compress $(ANSI_TO_USE)

clean:
	rm -f ll *.o *~ ll.s ll_thumb ansi_compress logo.inc logo.lzss logo.lzss_new core logo.include logo_optimize logo.include.parisc logo.lzss_new.parisc
	cd sstrip && make clean


