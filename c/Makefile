all:	llc_glibc_static_gcc42_O3 llc_glibc_static_gcc42_Os \
	llc_glibc_static_gcc42_O3.strip llc_glibc_static_gcc42_Os.strip \
	llc_glibc_static_gcc42_O3.sstrip llc_glibc_static_gcc42_Os.sstrip \
	llc_glibc_dynamic_gcc42_O3 llc_glibc_dynamic_gcc42_Os \
	llc_glibc_dynamic_gcc42_O3.strip llc_glibc_dynamic_gcc42_Os.strip \
	llc_glibc_dynamic_gcc42_O3.sstrip llc_glibc_dynamic_gcc42_Os.sstrip \
	llc_raw_gcc42_O3 llc_raw_gcc42_Os \
	llc_raw_gcc42_O3.strip llc_raw_gcc42_Os.strip \
	llc_raw_gcc42_O3.sstrip llc_raw_gcc42_Os.sstrip 
	
icc:	llc_glibc_static_icc_O3 llc_glibc_static_icc_Os \
	llc_glibc_static_icc_O3.strip llc_glibc_static_icc_Os.strip \
	llc_glibc_static_icc_O3.sstrip llc_glibc_static_icc_Os.sstrip \
	llc_glibc_dynamic_icc_O3 llc_glibc_dynamic_icc_Os \
	llc_glibc_dynamic_icc_O3.strip llc_glibc_dynamic_icc_Os.strip \
	llc_glibc_dynamic_icc_O3.sstrip llc_glibc_dynamic_icc_Os.sstrip	\
	llc_raw_icc_O3 llc_raw_icc_Os \
	llc_raw_icc_O3.strip llc_raw_icc_Os.strip \
	llc_raw_icc_O3.sstrip llc_raw_icc_Os.sstrip 

sun:	llc_glibc_static_sun_O3 \
	llc_glibc_static_sun_O3.strip \
	llc_glibc_static_sun_O3.sstrip \
	llc_glibc_dynamic_sun_O3 \
	llc_glibc_dynamic_sun_O3.strip \
	llc_glibc_dynamic_sun_O3.sstrip 	

uclibc:	llc_uclibc_static_gcc41_O3 llc_uclibc_static_gcc41_Os \
	llc_uclibc_static_gcc41_O3.strip llc_uclibc_static_gcc41_Os.strip \
	llc_uclibc_static_gcc41_O3.sstrip llc_uclibc_static_gcc41_Os.sstrip \
	llc_uclibc_dynamic_gcc41_O3 llc_uclibc_dynamic_gcc41_Os \
	llc_uclibc_dynamic_gcc41_O3.strip llc_uclibc_dynamic_gcc41_Os.strip \
	llc_uclibc_dynamic_gcc41_O3.sstrip llc_uclibc_dynamic_gcc41_Os.sstrip	
	

GCC42 = gcc-4.2
ICC = /opt/intel/cc/9.1.038/bin/icc
SUNCC = /opt/sunstudio12/bin/cc
UCLIBCC = /home/perfmon/uclibc/cross-compiler-i686/bin/i686-gcc

STRIP = strip
SSTRIP = ../sstrip/sstrip

CFLAGS_Os = -Os -Wall -m32
CFLAGS_O3 = -O3 -Wall -m32
CFLAGS_Os_INTEL = -Os -Wall
CFLAGS_O3_INTEL = -O3 -Wall
CFLAGS_Os_SUN = -Os -m32
CFLAGS_O3_SUN = -O3 -m32

LFLAGS = -m32

STATIC = -static
STATIC_SUN = -dn -m32

#####################################################
# .o files for llc_gcc42                            #
#####################################################

llc_gcc42_O3.o:	ll_glibc.c ../logo.lzss_new.h
	$(GCC42) $(CFLAGS_O3) -o llc_gcc42_O3.o -c ll_glibc.c
	
llc_gcc42_Os.o:	ll_glibc.c ../logo.lzss_new.h
	$(GCC42) $(CFLAGS_Os) -o llc_gcc42_Os.o -c ll_glibc.c	


#####################################################
# .o files for llc_icc                              #
#####################################################

llc_icc_O3.o:	ll_glibc.c ../logo.lzss_new.h
	$(ICC) $(CFLAGS_O3) -o llc_icc_O3.o -c ll_glibc.c
	
llc_icc_Os.o:	ll_glibc.c ../logo.lzss_new.h
	$(ICC) $(CFLAGS_Os) -o llc_icc_Os.o -c ll_glibc.c	
	
	
#####################################################
# .o files for llc_sun                              #
#####################################################

llc_sun_O3.o:	ll_glibc.c ../logo.lzss_new.h
	$(SUNCC) $(CFLAGS_O3_SUN) -Bstatic -o llc_sun_O3.o -c ll_glibc.c
	
llc_sun_Os.o:	ll_glibc.c ../logo.lzss_new.h
	$(SUNCC) $(CFLAGS_Os_SUN) -o llc_sun_Os.o -c ll_glibc.c


#####################################################
# .o files for llc_uclibc                           #
#####################################################

llc_uclibc_O3.o:	ll_glibc.c ../logo.lzss_new.h
	$(UCLIBCC) $(CFLAGS_O3) -o llc_uclibc_O3.o -c ll_glibc.c
	
llc_uclibc_Os.o:	ll_glibc.c ../logo.lzss_new.h
	$(UCLIBCC) $(CFLAGS_Os) -o llc_uclibc_Os.o -c ll_glibc.c	

#####################################################
# .o files for llc_raw_gcc42                        #
#####################################################

llc_raw_gcc42_O3.o:  ll_raw.c ../logo.lzss_new.h
	$(GCC42) $(CFLAGS_O3) -ffreestanding -o llc_raw_gcc42_O3.o -c ll_raw.c
	
llc_raw_gcc42_Os.o:  ll_raw.c ../logo.lzss_new.h
	$(GCC42) $(CFLAGS_Os) -ffreestanding -o llc_raw_gcc42_Os.o -c ll_raw.c	
	
#####################################################
# .o files for llc_raw_icc                          #
#####################################################

llc_raw_icc_O3.o:  ll_raw.c ../logo.lzss_new.h
	$(ICC) $(CFLAGS_O3) -o llc_raw_icc_O3.o -c ll_raw.c
	
llc_raw_icc_Os.o:  ll_raw.c ../logo.lzss_new.h
	$(ICC) $(CFLAGS_Os) -o llc_raw_icc_Os.o -c ll_raw.c	
	

###############################################
# glibc, static, gcc42                        #
###############################################

llc_glibc_static_gcc42_O3:		llc_gcc42_O3.o
	$(GCC42) $(LFLAGS) $(STATIC) -o llc_glibc_static_gcc42_O3 llc_gcc42_O3.o

llc_glibc_static_gcc42_Os:	llc_gcc42_Os.o 
	$(GCC42) $(LFLAGS) $(STATIC) -o llc_glibc_static_gcc42_Os llc_gcc42_Os.o
	
###############################################
# glibc, static, gcc42, stripped              #
###############################################

llc_glibc_static_gcc42_O3.strip:	llc_glibc_static_gcc42_O3
	$(STRIP) llc_glibc_static_gcc42_O3 -o llc_glibc_static_gcc42_O3.strip
	
llc_glibc_static_gcc42_Os.strip:	llc_glibc_static_gcc42_Os
	$(STRIP) llc_glibc_static_gcc42_Os -o llc_glibc_static_gcc42_Os.strip	
	

###############################################
# glibc, static, gcc42, sstripped             #
###############################################

llc_glibc_static_gcc42_O3.sstrip:	llc_glibc_static_gcc42_O3
	cp llc_glibc_static_gcc42_O3 llc_glibc_static_gcc42_O3.sstrip
	$(SSTRIP) llc_glibc_static_gcc42_O3.sstrip
	
llc_glibc_static_gcc42_Os.sstrip:	llc_glibc_static_gcc42_Os
	cp llc_glibc_static_gcc42_Os llc_glibc_static_gcc42_Os.sstrip
	$(SSTRIP) llc_glibc_static_gcc42_Os.sstrip	

###############################################
# glibc, static, icc                          #
###############################################

llc_glibc_static_icc_O3:	llc_icc_O3.o 
	$(ICC) $(STATIC) -o llc_glibc_static_icc_O3 llc_icc_O3.o
	
llc_glibc_static_icc_Os:	llc_icc_Os.o 
	$(ICC) $(STATIC) -o llc_glibc_static_icc_Os llc_icc_Os.o

###############################################
# glibc, static, icc, stripped                #
###############################################

llc_glibc_static_icc_O3.strip:	llc_glibc_static_icc_O3
	$(STRIP) llc_glibc_static_icc_O3 -o llc_glibc_static_icc_O3.strip
	
llc_glibc_static_icc_Os.strip:	llc_glibc_static_icc_Os
	$(STRIP) llc_glibc_static_icc_Os -o llc_glibc_static_icc_Os.strip	
	

###############################################
# glibc, static, icc, sstripped               #
###############################################

llc_glibc_static_icc_O3.sstrip:	llc_glibc_static_icc_O3
	cp llc_glibc_static_icc_O3 llc_glibc_static_icc_O3.sstrip
	$(SSTRIP) llc_glibc_static_icc_O3.sstrip
	
llc_glibc_static_icc_Os.sstrip:	llc_glibc_static_icc_Os
	cp llc_glibc_static_icc_Os llc_glibc_static_icc_Os.sstrip
	$(SSTRIP) llc_glibc_static_icc_Os.sstrip	


###############################################
# glibc, static, sun                          #
###############################################

llc_glibc_static_sun_O3:	llc_sun_O3.o 
	$(GCC42) $(LFLAGS) $(STATIC) -o llc_glibc_static_sun_O3 llc_sun_O3.o
	
llc_glibc_static_sun_Os:	llc_sun_Os.o 
	$(GCC42) $(LFLAGS) $(STATIC) -o llc_glibc_static_sun_Os llc_sun_Os.o

###############################################
# glibc, static, sun, stripped                #
###############################################

llc_glibc_static_sun_O3.strip:	llc_glibc_static_sun_O3
	$(STRIP) llc_glibc_static_sun_O3 -o llc_glibc_static_sun_O3.strip
	
llc_glibc_static_sun_Os.strip:	llc_glibc_static_sun_Os
	$(STRIP) llc_glibc_static_sun_Os -o llc_glibc_static_sun_Os.strip	
	

###############################################
# glibc, static, sun, sstripped               #
###############################################

llc_glibc_static_sun_O3.sstrip:	llc_glibc_static_sun_O3
	cp llc_glibc_static_sun_O3 llc_glibc_static_sun_O3.sstrip
	$(SSTRIP) llc_glibc_static_sun_O3.sstrip
	
llc_glibc_static_sun_Os.sstrip:	llc_glibc_static_sun_Os
	cp llc_glibc_static_sun_Os llc_glibc_static_sun_Os.sstrip
	$(SSTRIP) llc_glibc_static_sun_Os.sstrip	


###############################################
# uclibc, static, gcc41                       #
###############################################

llc_uclibc_static_gcc41_O3:		llc_uclibc_O3.o
	$(UCLIBCC) $(LFLAGS) $(STATIC) -o llc_uclibc_static_gcc41_O3 llc_uclibc_O3.o
	
llc_uclibc_static_gcc41_Os:	llc_uclibc_Os.o 
	$(UCLIBCC) $(LFLAGS) $(STATIC) -o llc_uclibc_static_gcc41_Os llc_uclibc_Os.o
	
###############################################
# uclibc, static, gcc41, stripped              #
###############################################

llc_uclibc_static_gcc41_O3.strip:	llc_uclibc_static_gcc41_O3
	$(STRIP) llc_uclibc_static_gcc41_O3 -o llc_uclibc_static_gcc41_O3.strip
	
llc_uclibc_static_gcc41_Os.strip:	llc_uclibc_static_gcc41_Os
	$(STRIP) llc_uclibc_static_gcc41_Os -o llc_uclibc_static_gcc41_Os.strip	
	

###############################################
# uclibc, static, gcc41, sstripped             #
###############################################

llc_uclibc_static_gcc41_O3.sstrip:	llc_uclibc_static_gcc41_O3
	cp llc_uclibc_static_gcc41_O3 llc_uclibc_static_gcc41_O3.sstrip
	$(SSTRIP) llc_uclibc_static_gcc41_O3.sstrip
	
llc_uclibc_static_gcc41_Os.sstrip:	llc_uclibc_static_gcc41_Os
	cp llc_uclibc_static_gcc41_Os llc_uclibc_static_gcc41_Os.sstrip
	$(SSTRIP) llc_uclibc_static_gcc41_Os.sstrip	


###############################################
# glibc, dynamic, gcc42                        #
###############################################

llc_glibc_dynamic_gcc42_O3:		llc_gcc42_O3.o
	$(GCC42) $(LFLAGS) -o llc_glibc_dynamic_gcc42_O3 llc_gcc42_O3.o

llc_glibc_dynamic_gcc42_Os:	llc_gcc42_Os.o 
	$(GCC42) $(LFLAGS) -o llc_glibc_dynamic_gcc42_Os llc_gcc42_Os.o
	
###############################################
# glibc, dynamic, gcc42, stripped              #
###############################################

llc_glibc_dynamic_gcc42_O3.strip:	llc_glibc_dynamic_gcc42_O3
	$(STRIP) llc_glibc_dynamic_gcc42_O3 -o llc_glibc_dynamic_gcc42_O3.strip
	
llc_glibc_dynamic_gcc42_Os.strip:	llc_glibc_dynamic_gcc42_Os
	$(STRIP) llc_glibc_dynamic_gcc42_Os -o llc_glibc_dynamic_gcc42_Os.strip	
	

###############################################
# glibc, dynamic, gcc42, sstripped            #
###############################################

llc_glibc_dynamic_gcc42_O3.sstrip:	llc_glibc_dynamic_gcc42_O3
	cp llc_glibc_dynamic_gcc42_O3 llc_glibc_dynamic_gcc42_O3.sstrip
	$(SSTRIP) llc_glibc_dynamic_gcc42_O3.sstrip
	
llc_glibc_dynamic_gcc42_Os.sstrip:	llc_glibc_dynamic_gcc42_Os
	cp llc_glibc_dynamic_gcc42_Os llc_glibc_dynamic_gcc42_Os.sstrip
	$(SSTRIP) llc_glibc_dynamic_gcc42_Os.sstrip	

###############################################
# glibc, dynamic, icc                         #
###############################################

llc_glibc_dynamic_icc_O3:	llc_icc_O3.o 
	$(ICC) -o llc_glibc_dynamic_icc_O3 llc_icc_O3.o
	
llc_glibc_dynamic_icc_Os:	llc_icc_Os.o 
	$(ICC) -o llc_glibc_dynamic_icc_Os llc_icc_Os.o

###############################################
# glibc, dynamic, icc, stripped               #
###############################################

llc_glibc_dynamic_icc_O3.strip:	llc_glibc_dynamic_icc_O3
	$(STRIP) llc_glibc_dynamic_icc_O3 -o llc_glibc_dynamic_icc_O3.strip
	
llc_glibc_dynamic_icc_Os.strip:	llc_glibc_dynamic_icc_Os
	$(STRIP) llc_glibc_dynamic_icc_Os -o llc_glibc_dynamic_icc_Os.strip	
	

###############################################
# glibc, dynamic, icc, sstripped              #
###############################################

llc_glibc_dynamic_icc_O3.sstrip:	llc_glibc_dynamic_icc_O3
	cp llc_glibc_dynamic_icc_O3 llc_glibc_dynamic_icc_O3.sstrip
	$(SSTRIP) llc_glibc_dynamic_icc_O3.sstrip
	
llc_glibc_dynamic_icc_Os.sstrip:	llc_glibc_dynamic_icc_Os
	cp llc_glibc_dynamic_icc_Os llc_glibc_dynamic_icc_Os.sstrip
	$(SSTRIP) llc_glibc_dynamic_icc_Os.sstrip	


###############################################
# glibc, dynamic, sun                         #
###############################################

llc_glibc_dynamic_sun_O3:	llc_sun_O3.o 
	$(GCC42) $(LFLAGS) -o llc_glibc_dynamic_sun_O3 llc_sun_O3.o
	
llc_glibc_dynamic_sun_Os:	llc_sun_Os.o 
	$(GCC42) $(LFLAGS) -o llc_glibc_dynamic_sun_Os llc_sun_Os.o

###############################################
# glibc, dynamic, sun, stripped               #
###############################################

llc_glibc_dynamic_sun_O3.strip:	llc_glibc_dynamic_sun_O3
	$(STRIP) llc_glibc_dynamic_sun_O3 -o llc_glibc_dynamic_sun_O3.strip
	
llc_glibc_dynamic_sun_Os.strip:	llc_glibc_dynamic_sun_Os
	$(STRIP) llc_glibc_dynamic_sun_Os -o llc_glibc_dynamic_sun_Os.strip	
	

###############################################
# glibc, dynamic, sun, sstripped              #
###############################################

llc_glibc_dynamic_sun_O3.sstrip:	llc_glibc_dynamic_sun_O3
	cp llc_glibc_dynamic_sun_O3 llc_glibc_dynamic_sun_O3.sstrip
	$(SSTRIP) llc_glibc_dynamic_sun_O3.sstrip
	
llc_glibc_dynamic_sun_Os.sstrip:	llc_glibc_dynamic_sun_Os
	cp llc_glibc_dynamic_sun_Os llc_glibc_dynamic_sun_Os.sstrip
	$(SSTRIP) llc_glibc_dynamic_sun_Os.sstrip	


###############################################
# uclibc, dynamic, gcc41                      #
###############################################

llc_uclibc_dynamic_gcc41_O3:		llc_uclibc_O3.o
	$(UCLIBCC) $(LFLAGS) -o llc_uclibc_dynamic_gcc41_O3 llc_uclibc_O3.o
	
llc_uclibc_dynamic_gcc41_Os:	llc_uclibc_Os.o 
	$(UCLIBCC) $(LFLAGS) -o llc_uclibc_dynamic_gcc41_Os llc_uclibc_Os.o
	
###############################################
# uclibc, dynamic, gcc41, stripped            #
###############################################

llc_uclibc_dynamic_gcc41_O3.strip:	llc_uclibc_dynamic_gcc41_O3
	$(STRIP) llc_uclibc_dynamic_gcc41_O3 -o llc_uclibc_dynamic_gcc41_O3.strip
	
llc_uclibc_dynamic_gcc41_Os.strip:	llc_uclibc_dynamic_gcc41_Os
	$(STRIP) llc_uclibc_dynamic_gcc41_Os -o llc_uclibc_dynamic_gcc41_Os.strip	
	

###############################################
# uclibc, dynamic, gcc41, sstripped           #
###############################################

llc_uclibc_dynamic_gcc41_O3.sstrip:	llc_uclibc_dynamic_gcc41_O3
	cp llc_uclibc_dynamic_gcc41_O3 llc_uclibc_dynamic_gcc41_O3.sstrip
	$(SSTRIP) llc_uclibc_dynamic_gcc41_O3.sstrip
	
llc_uclibc_dynamic_gcc41_Os.sstrip:	llc_uclibc_dynamic_gcc41_Os
	cp llc_uclibc_dynamic_gcc41_Os llc_uclibc_dynamic_gcc41_Os.sstrip
	$(SSTRIP) llc_uclibc_dynamic_gcc41_Os.sstrip	


###############################################
# raw, gcc42                                  #
###############################################

llc_raw_gcc42_O3:    llc_raw_gcc42_O3.o
	      $(GCC42) -o llc_raw_gcc42_O3 -nostdlib -nodefaultlibs -static llc_raw_gcc42_O3.o
	      
llc_raw_gcc42_Os:    llc_raw_gcc42_Os.o
	      $(GCC42) -o llc_raw_gcc42_Os -nostdlib -nodefaultlibs -static llc_raw_gcc42_Os.o


###############################################
# raw, gcc42, stripped                        #
###############################################

llc_raw_gcc42_O3.strip:	llc_raw_gcc42_O3
	$(STRIP) llc_raw_gcc42_O3 -o llc_raw_gcc42_O3.strip
	
llc_raw_gcc42_Os.strip:	llc_raw_gcc42_Os
	$(STRIP) llc_raw_gcc42_Os -o llc_raw_gcc42_Os.strip	
	

###############################################
# raw, gcc42, sstripped                       #
###############################################

llc_raw_gcc42_O3.sstrip:	llc_raw_gcc42_O3
	cp llc_raw_gcc42_O3 llc_raw_gcc42_O3.sstrip
	$(SSTRIP) llc_raw_gcc42_O3.sstrip
	
llc_raw_gcc42_Os.sstrip:	llc_raw_gcc42_Os
	cp llc_raw_gcc42_Os llc_raw_gcc42_Os.sstrip
	$(SSTRIP) llc_raw_gcc42_Os.sstrip	
	
###############################################
# raw, icc                                    #
###############################################

llc_raw_icc_O3:    llc_raw_icc_O3.o
	      $(ICC) -o llc_raw_icc_O3 -nostdlib -nodefaultlibs -static llc_raw_icc_O3.o
	      
llc_raw_icc_Os:    llc_raw_icc_Os.o
	      $(ICC) -o llc_raw_icc_Os -nostdlib -nodefaultlibs -static llc_raw_icc_Os.o


###############################################
# raw, icc, stripped                          #
###############################################

llc_raw_icc_O3.strip:	llc_raw_icc_O3
	$(STRIP) llc_raw_icc_O3 -o llc_raw_icc_O3.strip
	
llc_raw_icc_Os.strip:	llc_raw_icc_Os
	$(STRIP) llc_raw_icc_Os -o llc_raw_icc_Os.strip	
	

###############################################
# raw, icc, sstripped                         #
###############################################

llc_raw_icc_O3.sstrip:	llc_raw_icc_O3
	cp llc_raw_icc_O3 llc_raw_icc_O3.sstrip
	$(SSTRIP) llc_raw_icc_O3.sstrip
	
llc_raw_icc_Os.sstrip:	llc_raw_icc_Os
	cp llc_raw_icc_Os llc_raw_icc_Os.sstrip
	$(SSTRIP) llc_raw_icc_Os.sstrip		
	


###############################################
# clean                                       #
###############################################
	
clean:	
	rm -f llc_*Os llc_*O3 *~ *.o *.strip *.sstrip


###############################################
# old                                         #
###############################################

ll_sun_raw_O3.o:	ll_raw.c ../logo.lzss_new.h
			$(SUNCC) -O3 -m32 -o ll_sun_raw_O3.o -c ll_raw.c

ll_sun_raw_O3:		ll_sun_raw_O3.o
			$(GCC) -m32 -nostdlib -static -o ll_sun_raw_O3 ll_sun_raw_O3.o

