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
	C_EXTRA = --32
	L_EXTRA = -melf_i386
   endif
   THUMB := ll_8086.com
endif


#
# Handle x86_64
#
ifneq (,$(findstring x86_64,$(ARCH)))
   SOURCE_ARCH := x86_64
   THUMB := ll.x86_x32 ll.x86_x32.stripped ll.x86_x32.fakeproc ll.x86_x32.fakeproc.stripped ll.x86_x32.dis ll.x86_x32.output
endif


#
# Handle various ARM variants
#
ifneq (,$(findstring arm,$(ARCH)))
   SOURCE_ARCH := arm.eabi
   ARCH := arm
   THUMB := ll.thumb ll.thumb.stripped ll.thumb.fakeproc ll.thumb.fakeproc.stripped \
            ll.thumb2 ll.thumb2.stripped ll.thumb2.fakeproc ll.thumb2.fakeproc.stripped
endif

#
# Give arm64 a sane name
#
ifneq (,$(findstring aarch64,$(ARCH)))
   SOURCE_ARCH := arm64
   ARCH := arm64
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
   C_EXTRA := -Av8 
endif

#
# Handle MIPS
#
ifneq (,$(findstring mips,$(ARCH)))
   SOURCE_ARCH := mips
   THUMB := ll.mips16
   THUMB := ll.mips16 ll.mips16.stripped ll.mips16.fakeproc ll.mips16.fakeproc.stripped \
            ll.micromips ll.micromips.stripped ll.micromips.fakeproc ll.micromips.fakeproc.stripped

endif


#
# Handle RISCV32
#
ifneq (,$(findstring riscv32,$(ARCH)))
	SOURCE_ARCH := riscv32
	C_EXTRA = -march=rv32im
	THUMB := ll.riscv-rv32c ll.riscv-rv32c.stripped ll.riscv-rv32c.fakeproc ll.riscv-rv32c.fakeproc.stripped
endif


#
# Handle RISCV64
#
ifneq (,$(findstring riscv64,$(ARCH)))
	SOURCE_ARCH := riscv64
	C_EXTRA = -march=rv64im
	THUMB := ll.riscv64-imc ll.riscv64-imc.stripped \
		ll.riscv64-imc.fakeproc ll.riscv64-imc.fakeproc.stripped
endif

#
# Handle RISCV128
#
ifneq (,$(findstring riscv128,$(ARCH)))
	SOURCE_ARCH := riscv128
	C_EXTRA = -march=rv128im
	THUMB := ll.riscv-rv128c ll.riscv-rv128c.stripped ll.riscv-rv128c.fakeproc ll.riscv-rv128c.fakeproc.stripped
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
   L_EXTRA := $(L_EXTRA) -N
endif

#
# Handle RiSC
#

ifneq (,$(findstring RiSC,$(ARCH)))
      SIM = RiSC-sim
endif


ifeq ($(SOURCE_ARCH),)
   SOURCE_ARCH = $(ARCH)
endif

CC = gcc
STRIP = strip
CFLAGS = -O2 -Wall

all:	ll ll.$(ARCH) \
	ll.$(ARCH).fakeproc \
	$(THUMB) ansi_compress ./sstrip/sstrip \
	ll.$(ARCH).stripped ll.$(ARCH).fakeproc.stripped \
	ll.$(ARCH).dis ll.$(ARCH).output lzss_code_size

sstrip_ll: ll ./sstrip/sstrip
	./sstrip/sstrip ll

export ARCH

./sstrip/sstrip:	./sstrip/sstrip.c
	cd sstrip && make

./sstrip/sstrip32:	./sstrip/sstrip.c
	cd sstrip && make sstrip32

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

ll.$(ARCH).dis:	ll.$(ARCH)
	$(CROSS)objdump --disassemble-all ll.$(ARCH) > ll.$(ARCH).dis

ll.$(ARCH).output:	ll.$(ARCH).fakeproc
	$(SIM) ./ll.$(ARCH).fakeproc > ll.$(ARCH).output
	@cmp -n $(shell wc -c banner_logo.ansi) ll.$(ARCH).output || \
	  echo '\n##### Error in logo decode #####\n'

ll:	ll.o
	$(CROSS)$(LD) $(L_EXTRA) -o ll ll.o

ll.$(ARCH).stripped:  ll.$(ARCH) sstrip/sstrip
	cp ll.$(ARCH) ll.$(ARCH).stripped
	$(CROSS)$(STRIP) ll.$(ARCH).stripped
	sstrip/sstrip ll.$(ARCH).stripped

ll.$(ARCH).fakeproc.stripped:		 ll.$(ARCH).fakeproc sstrip/sstrip
	cp ll.$(ARCH).fakeproc ll.$(ARCH).fakeproc.stripped
	$(CROSS)$(STRIP) ll.$(ARCH).fakeproc.stripped
	sstrip/sstrip ll.$(ARCH).fakeproc.stripped

ll.$(ARCH):	ll.o
	$(CROSS)$(LD) $(L_EXTRA) -o ll.$(ARCH) ll.o

ll.$(ARCH).fakeproc:	ll.fakeproc.o
	$(CROSS)$(LD) $(L_EXTRA) -o ll.$(ARCH).fakeproc ll.fakeproc.o

ll.o:	ll.$(SOURCE_ARCH).s logo.lzss
	$(CROSS)$(AS) $(C_EXTRA) $(LITTLE_ENDIAN) -o ll.o ll.$(SOURCE_ARCH).s

ll.fakeproc.o:	ll.s logo.lzss
	$(CROSS)$(AS) $(C_EXTRA) $(LITTLE_ENDIAN) -defsym FAKE_PROC=1 -o ll.fakeproc.o ll.s


#
# x32
#

ll.x86_x32:	ll.x86_x32.o
	$(CROSS)$(LD) -melf32_x86_64 -N -o ll.x86_x32 ll.x86_x32.o

ll.x86_x32.o:	ll.x86_x32.s
	$(CROSS)$(AS) --x32 -o ll.x86_x32.o ll.x86_x32.s

ll.x86_x32.stripped:  ll.x86_x32 sstrip/sstrip32
	cp ll.x86_x32 ll.x86_x32.stripped
	sstrip/sstrip32 ll.x86_x32.stripped


ll.x86_x32.fakeproc:	ll.x86_x32.fakeproc.o
	$(CROSS)$(LD) -melf32_x86_64 -N -o ll.x86_x32.fakeproc ll.x86_x32.fakeproc.o

ll.x86_x32.fakeproc.o:	ll.x86_x32.s
	$(CROSS)$(AS) -defsym FAKE_PROC=1 --x32 -o ll.x86_x32.fakeproc.o ll.x86_x32.s

ll.x86_x32.fakeproc.stripped:  ll.x86_x32.fakeproc sstrip/sstrip32
	cp ll.x86_x32.fakeproc ll.x86_x32.fakeproc.stripped
	sstrip/sstrip32 ll.x86_x32.fakeproc.stripped


ll.x86_x32.dis:	ll.x86_x32
	$(CROSS)objdump --disassemble-all ll.x86_x32 > ll.x86_x32.dis

ll.x86_x32.output:	ll.x86_x32.fakeproc
	$(SIM) ./ll.x86_x32.fakeproc > ll.x86_x32.output



#
# Thumb
#

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

#
# Thumb2
#

ll.thumb2.stripped:  ll.thumb2 sstrip/sstrip
	cp ll.thumb2 ll.thumb2.stripped
	sstrip/sstrip ll.thumb2.stripped

ll.thumb2:	ll.thumb2.o
	$(CROSS)$(LD) -N --thumb-entry=_start -o ll.thumb2 ll.thumb2.o

ll.thumb2.o:	ll.thumb2.s
	$(CROSS)$(AS) -mthumb-interwork -o ll.thumb2.o ll.thumb2.s

ll.thumb2.fakeproc.stripped:  ll.thumb2.fakeproc sstrip/sstrip
	cp ll.thumb2.fakeproc ll.thumb2.fakeproc.stripped
	sstrip/sstrip ll.thumb2.fakeproc.stripped

ll.thumb2.fakeproc:	ll.thumb2.fakeproc.o
	$(CROSS)$(LD) -N --thumb-entry=_start -o ll.thumb2.fakeproc ll.thumb2.fakeproc.o

ll.thumb2.fakeproc.o:	ll.thumb2.s
	$(CROSS)$(AS) -defsym FAKE_PROC=1 -mthumb-interwork -o ll.thumb2.fakeproc.o ll.thumb2.s

#
# Mips16
#

ll.mips16.stripped:  ll.mips16 sstrip/sstrip
	cp ll.mips16 ll.mips16.stripped
	sstrip/sstrip ll.mips16.stripped

ll.mips16:	ll.mips16.o
	$(CROSS)$(LD) -N -o ll.mips16 ll.mips16.o

ll.mips16.o:	ll.mips16.s
	$(CROSS)$(AS) -mips32r2 -mips16 -o ll.mips16.o ll.mips16.s

ll.mips16.fakeproc.stripped:  ll.mips16.fakeproc sstrip/sstrip
	cp ll.mips16.fakeproc ll.mips16.fakeproc.stripped
	sstrip/sstrip ll.mips16.fakeproc.stripped

ll.mips16.fakeproc:	ll.mips16.fakeproc.o
	$(CROSS)$(LD) -N -o ll.mips16.fakeproc ll.mips16.fakeproc.o

ll.mips16.fakeproc.o:	ll.mips16.s
	$(CROSS)$(AS) -defsym FAKE_PROC=1 -mips32r2 -mips16 -o ll.mips16.fakeproc.o ll.mips16.s

#
# microMips
#

ll.micromips.stripped:  ll.micromips sstrip/sstrip
	cp ll.micromips ll.micromips.stripped
	sstrip/sstrip ll.micromips.stripped

ll.micromips:	ll.micromips.o
	$(CROSS)$(LD) -N -o ll.micromips ll.micromips.o

ll.micromips.o:	ll.micromips.s
	$(CROSS)$(AS) -mmicromips -o ll.micromips.o ll.micromips.s
#	$(CROSS)$(AS) -mips32r6 -mnan=2008 -o ll.micromips.o ll.micromips.s

ll.micromips.fakeproc.stripped:  ll.micromips.fakeproc sstrip/sstrip
	cp ll.micromips.fakeproc ll.micromips.fakeproc.stripped
	sstrip/sstrip ll.micromips.fakeproc.stripped

ll.micromips.fakeproc:	ll.micromips.fakeproc.o
	$(CROSS)$(LD) -N -o ll.micromips.fakeproc ll.micromips.fakeproc.o
#	$(CROSS)$(LD) --relax -N -o ll.micromips.fakeproc ll.micromips.fakeproc.o

ll.micromips.fakeproc.o:	ll.micromips.s
	$(CROSS)$(AS) -defsym FAKE_PROC=1 -mmicromips -o ll.micromips.fakeproc.o ll.micromips.s


#
# riscv32-imc
#

ll.riscv32-imc.stripped:  ll.riscv32-imc sstrip/sstrip
	cp ll.riscv32-imc ll.riscv32-imc.stripped
	sstrip/sstrip ll.riscv32-imc.stripped

ll.riscv32-imc:	ll.riscv32-imc.o
	$(CROSS)$(LD) -N -o ll.riscv32-imc ll.riscv32-imc.o

ll.riscv32-imc.o:	ll.riscv32-imc.s
	$(CROSS)$(AS) -march=rv32imc -o ll.riscv32-imc.o ll.riscv32-imc.s

ll.riscv32-imc.fakeproc.stripped:  ll.riscv32-imc.fakeproc sstrip/sstrip
	cp ll.riscv32-imc.fakeproc ll.riscv32-imc.fakeproc.stripped
	sstrip/sstrip ll.riscv32-imc.fakeproc.stripped

ll.riscv32-imc.fakeproc:	ll.riscv32-imc.fakeproc.o
	$(CROSS)$(LD) -N -o ll.riscv32-imc.fakeproc ll.riscv32-imc.fakeproc.o

ll.riscv32-imc.fakeproc.o:	ll.riscv32-imc.s
	$(CROSS)$(AS) -defsym FAKE_PROC=1 -march=rv32imc -o ll.riscv32-imc.fakeproc.o ll.riscv32-imc.s


#
# riscv64-imc
#

ll.riscv64-imc.stripped:  ll.riscv64-imc sstrip/sstrip
	cp ll.riscv64-imc ll.riscv64-imc.stripped
	sstrip/sstrip ll.riscv64-imc.stripped

ll.riscv64-imc:	ll.riscv64-imc.o
	$(CROSS)$(LD) -N -o ll.riscv64-imc ll.riscv64-imc.o

ll.riscv64-imc.o:	ll.riscv64-imc.s
	$(CROSS)$(AS) -march=rv64imc -o ll.riscv64-imc.o ll.riscv64-imc.s

ll.riscv64-imc.fakeproc.stripped:  ll.riscv64-imc.fakeproc sstrip/sstrip
	cp ll.riscv64-imc.fakeproc ll.riscv64-imc.fakeproc.stripped
	sstrip/sstrip ll.riscv64-imc.fakeproc.stripped

ll.riscv64-imc.fakeproc:	ll.riscv64-imc.fakeproc.o
	$(CROSS)$(LD) -N -o ll.riscv64-imc.fakeproc ll.riscv64-imc.fakeproc.o

ll.riscv64-imc.fakeproc.o:	ll.riscv64-imc.s
	$(CROSS)$(AS) -defsym FAKE_PROC=1 -march=rv64imc -o ll.riscv64-imc.fakeproc.o ll.riscv64-imc.s



#
# riscv128-imc
#

ll.riscv128-imc.stripped:  ll.riscv128-imc sstrip/sstrip
	cp ll.riscv128-imc ll.riscv128-imc.stripped
	sstrip/sstrip ll.riscv128-imc.stripped

ll.riscv128-imc:	ll.riscv128-imc.o
	$(CROSS)$(LD) -N -o ll.riscv128-imc ll.riscv128-imc.o

ll.riscv128-imc.o:	ll.riscv128-imc.s
	$(CROSS)$(AS) -march=rv128imc -o ll.riscv128-imc.o ll.riscv128-imc.s

ll.riscv128-imc.fakeproc.stripped:  ll.riscv128-imc.fakeproc sstrip/sstrip
	cp ll.riscv128-imc.fakeproc ll.riscv128-imc.fakeproc.stripped
	sstrip/sstrip ll.riscv128-imc.fakeproc.stripped

ll.riscv128-imc.fakeproc:	ll.riscv128-imc.fakeproc.o
	$(CROSS)$(LD) -N -o ll.riscv128-imc.fakeproc ll.riscv128-imc.fakeproc.o

ll.riscv128-imc.fakeproc.o:	ll.riscv128-imc.s
	$(CROSS)$(AS) -defsym FAKE_PROC=1 -march=rv128imc -o ll.riscv128-imc.fakeproc.o ll.riscv128-imc.s



#
# 8086
#

ll_8086.com:	      ll.8086.o.o
		      dd if=ll.8086.o.o of=ll_8086.com bs=256 skip=1

ll.8086.o.o:	      ll.8086.o
		      objcopy -O binary ll.8086.o ll.8086.o.o

ll.8086.o:	      ll.8086.s
		      as --32 -R -o ll.8086.o ll.8086.s

ll.s:
	rm -f ll.s
	ln -s ll.$(SOURCE_ARCH).s ll.s

logo.inc:	   $(ANSI_TO_USE) ansi_compress
		   ./ansi_compress $(ANSI_TO_USE)

logo.lzss:	   $(ANSI_TO_USE) ansi_compress
		   ./ansi_compress $(ANSI_TO_USE)

lzss_code_size: ll.$(ARCH).dis
	perl calc_lzss_size.pl ll.$(ARCH).dis

clean:
	rm -f ll ll_c ll.$(ARCH) ll.$(SOURCE_ARCH) *.fakeproc *.stripped \
	*.o *~ ll.s ll.thumb ll.thumb2 ll.x86_x32 \
	ll.mips16 ll.micromips ansi_compress logo.inc logo.lzss logo.lzss_new \
	core logo.include logo_optimize logo.include.parisc \
	logo.lzss_new.parisc a.out *.dis *.output *.com
	cd sstrip && make clean


