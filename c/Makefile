all:	ll_gcc_static_O3 ll_gcc_static_Os ll_gcc_dynamic_O3 ll_gcc_dynamic_Os \
	ll_gcc_raw_O3 ll_gcc_raw_Os

icc:	ll_icc_raw_O3 ll_icc_raw_Os

sun:	ll_sun_raw_O3

GCC = gcc-4.2
ICC = /opt/intel/cc/9.1.038/bin/icc
SUNCC = /opt/sunstudio12/bin/cc

CFLAGS_OS = -Os -Wall -g
CFLAGS_O3 = -O3 -Wall -g
STATIC = -static
#SSTRIP = ../sstrip/sstrip
SSTRIP = touch

ll_sun_raw_O3.o:	ll_raw.c ../logo.lzss_new.h
			$(SUNCC) -O3 -m32 -o ll_sun_raw_O3.o -c ll_raw.c

ll_sun_raw_O3:		ll_sun_raw_O3.o
			$(GCC) -m32 -nostdlib -static -o ll_sun_raw_O3 ll_sun_raw_O3.o

ll_gcc_raw_O3.o:  ll_raw.c ../logo.lzss_new.h
	      $(GCC) $(CFLAGS_O3) -ffreestanding -o ll_gcc_raw_O3.o -c ll_raw.c
	      
ll_gcc_raw_O3:    ll_gcc_raw_O3.o
	      $(GCC) -o ll_gcc_raw_O3 -nostdlib -nodefaultlibs -static ll_gcc_raw_O3.o
	      
ll_gcc_raw_Os.o:  ll_raw.c ../logo.lzss_new.h
	      $(GCC) $(CFLAGS_OS) -ffreestanding -o ll_gcc_raw_Os.o -c ll_raw.c
	      
ll_gcc_raw_Os:    ll_gcc_raw_Os.o
	      $(GCC) -o ll_gcc_raw_Os -nostdlib -nodefaultlibs -static ll_gcc_raw_Os.o
	      
ll_icc_raw_O3.o:  ll_raw.c ../logo.lzss_new.h
	      $(ICC) -fast -o ll_icc_raw_O3.o -c ll_raw.c
	      
ll_icc_raw_O3:    ll_icc_raw_O3.o
	      $(ICC) -o ll_icc_raw_O3 -nostdlib -nodefaultlibs -static ll_icc_raw_O3.o
	      
ll_icc_raw_Os.o:  ll_raw.c ../logo.lzss_new.h
	      $(ICC) -Os -o ll_icc_raw_Os.o -c ll_raw.c
	      
ll_icc_raw_Os:    ll_icc_raw_Os.o
	      $(ICC) -o ll_icc_raw_Os -nostdlib -nodefaultlibs -static ll_icc_raw_Os.o	      

ll_gcc_O3.o:	ll_glibc.c ../logo.lzss_new.h
	$(GCC) $(CFLAGS_O3) -o ll_gcc_O3.o -c ll_glibc.c
	
ll_gcc_Os.o:	ll_glibc.c ../logo.lzss_new.h
	$(GCC) $(CFLAGS_Os) -o ll_gcc_Os.o -c ll_glibc.c	


ll_gcc_static_O3:	ll_gcc_O3.o 
	$(GCC) $(STATIC) -o ll_gcc_static_O3 ll_gcc_O3.o
	$(SSTRIP) ./ll_gcc_static_O3

ll_gcc_static_Os:	ll_gcc_Os.o 
	$(GCC) $(STATIC) -o ll_gcc_static_Os ll_gcc_Os.o
	$(SSTRIP) ./ll_gcc_static_Os


ll_gcc_dynamic_O3:	ll_gcc_O3.o 
	$(GCC) -o ll_gcc_dynamic_O3 ll_gcc_O3.o
	$(SSTRIP) ./ll_gcc_dynamic_O3

ll_gcc_dynamic_Os:	ll_gcc_Os.o 
	$(GCC) -o ll_gcc_dynamic_Os ll_gcc_Os.o
	$(SSTRIP) ./ll_gcc_dynamic_Os

	
clean:	
	rm -f ll_*Os ll_*O3 *~ *.o
