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
      SOURCE_ARCH := i386
   endif
endif

#
# Handle various ARM variants
#
ifneq (,$(findstring arm,$(ARCH)))
   SOURCE_ARCH := arm
   THUMB := ll.thumb ll.thumb.stripped ll.thumb.fakeproc ll.thumb.fakeproc.stripped
endif

#
# Handle CRIS
#
ifneq (,$(findstring cris,$(ARCH)))
   SOURCE_ARCH := crisv32
   C_EXTRA := --march=v32
endif

#
# Handle SPARC
#
ifneq (,$(findstring sparc,$(ARCH)))
   SOURCE_ARCH := sparc
endif

#
# Handle MIPS
#
ifneq (,$(findstring mips,$(ARCH)))
   SOURCE_ARCH := mips
   THUMB := ll.mips16
endif

#
# Handle MIPSEL
#
ifneq (,$(findstring mipsel,$(ARCH)))
   LITTLE_ENDIAN := -defsym LITTLE_ENDIAN=1
endif



#
# Handle z80
#

ifneq (,$(findstring z80,$(ARCH)))
   SOURCE_ARCH := z80
   L_EXTRA := 
else
   L_EXTRA := -N
endif

ifeq ($(SOURCE_ARCH),)
   SOURCE_ARCH = $(ARCH)
endif

CC = gcc
CFLAGS = -O2 -Wall

all:	ll ll.$(ARCH) \
	ll.$(ARCH).fakeproc \
	$(THUMB) ansi_compress ./sstrip/sstrip \
	ll.$(ARCH).stripped ll.$(ARCH).fakeproc.stripped

sstrip_ll: ll ./sstrip/sstrip
	./sstrip/sstrip ll

export ARCH

./sstrip/sstrip:	./sstrip/sstrip.c
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
	$(CROSS)$(LD) $(L_EXTRA) -o ll ll.o	

ll.$(ARCH).stripped:  ll.$(ARCH) sstrip/sstrip
	cp ll.$(ARCH) ll.$(ARCH).stripped
	sstrip/sstrip ll.$(ARCH).stripped
	
ll.$(ARCH).fakeproc.stripped:		 ll.$(ARCH).fakeproc sstrip/sstrip
	cp ll.$(ARCH).fakeproc ll.$(ARCH).fakeproc.stripped
	sstrip/sstrip ll.$(ARCH).fakeproc.stripped

ll.$(ARCH):	ll.o
	$(CROSS)$(LD) $(L_EXTRA) -o ll.$(ARCH) ll.o	
	
ll.$(ARCH).fakeproc:	ll.fakeproc.o
	$(CROSS)$(LD) $(L_EXTRA) -o ll.$(ARCH).fakeproc ll.fakeproc.o

ll.o:	ll.$(SOURCE_ARCH).s logo.lzss
	$(CROSS)$(AS) $(C_EXTRA) $(LITTLE_ENDIAN) -o ll.o ll.$(SOURCE_ARCH).s
	
ll.fakeproc.o:	ll.s logo.lzss
	$(CROSS)$(AS) $(C_EXTRA) $(LITTLE_ENDIAN) -defsym FAKE_PROC=1 -o ll.fakeproc.o ll.s

ll.thumb.stripped:  ll.thumb sstrip/sstrip
	cp ll.thumb ll.thumb.stripped
	sstrip/sstrip ll.thumb.stripped

ll.thumb:	ll.thumb.o
	$(CROSS)$(LD) -N --thumb-entry=_start -o ll.thumb ll.thumb.o

ll.thumb.o:	ll.thumb.s
	$(CROSS)$(AS) -mthumb-interwork -o ll.thumb.o ll.thumb.s	

ll.thumb.fakeproc.stripped:  ll.thumb.fakeproc sstrip/sstrip
	cp ll.thumb.fakeproc ll.thumb.fakeproc.stripped
	sstrip/sstrip ll.thumb.fakeproc.stripped

ll.thumb.fakeproc:	ll.thumb.fakeproc.o
	$(CROSS)$(LD) -N --thumb-entry=_start -o ll.thumb.fakeproc ll.thumb.fakeproc.o

ll.thumb.fakeproc.o:	ll.thumb.s
	$(CROSS)$(AS) -defsym FAKE_PROC=1 -mthumb-interwork -o ll.thumb.fakeproc.o ll.thumb.s

ll.mips16.o:	ll.mips16.s
	$(CROSS)$(AS) -EL -o ll.mips16.o ll.mips16.s
	
ll.mips16:	ll.mips16.o
	$(CROSS)$(LD) -EL -N -o ll.mips16 ll.mips16.o

ll.s:	
	rm -f ll.s
	ln -s ll.$(SOURCE_ARCH).s ll.s
		   
logo.inc:	   $(ANSI_TO_USE) ansi_compress
		   ./ansi_compress $(ANSI_TO_USE)

logo.lzss:	   $(ANSI_TO_USE) ansi_compress
		   ./ansi_compress $(ANSI_TO_USE)

clean:
	rm -f ll ll_c ll.$(ARCH) *.fakeproc *.stripped *.o *~ ll.s ll.thumb \
	ll.mips16 ansi_compress logo.inc logo.lzss logo.lzss_new \
	core logo.include logo_optimize logo.include.parisc \
	logo.lzss_new.parisc a.out
	cd sstrip && make clean


