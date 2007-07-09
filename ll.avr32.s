#
#  linux_logo in avr32 assembler 0.27
#
#  By 
#       Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -o ll.o ll.avr32.s"
#  link with         "ld -o ll ll.o"
#
#  I have to cross-compile, so what I do is was more like
#      make CROSS=avr32-linux- ARCH=avr32

# 32-bit RISC
# 15 general purpose regs plus PC
# special support for running Java bytecode directly?
# avr32a-for small embedded.  
# avr32b-where interrupt latency impt (has regs for context switches
#     instead of stack)

# status reg
#  highword = O/S specific stuff
#  lo-word = Registeremap scraTch Lock saturationQ Overflow sigN Zero Carry

# Scratch-pad status reg bit can be used by user
# lock flag used by conditional store/atomic
# saturating flag indicates saturating arithmatic overflow

# addressing modes:
#   from a pointer reg, pointer reg with postincement
#   pointer gre with predecrement, pointer with displacement
#   small immediate, pointer reg with index

# Syscalls:
#   syscall number in r8
#   arguments in r12 down to r9, and r6 and r5
#   r12 has return value		   

# r15=pc, r14=link reg, r13=stack pointer

# branch folding?
#   if branch predicted, eliminate the branch and fold in the
#   proper condition codes with the following instruction
#   can turn off branch predicting
# no floating point?
# can only access 2GB of virtual memory

# return stack, 4 entry circular buffer holding return addresses
#   can be turned off
#    overflow handled in hardware?

# no hardware support for self modifying code, have to invalidate
#   cache yourself
# in special debug mode can read the raw values from cache
# the data cache can be memory mapped and used as a scratch ram?

# PC can be a destination register

# avr32 has all the "normal" instructions, but in addition has
#     a lot of unusual ones.  This lists the unusual ones.
# acall?
# addabs - add x with |y|
# addhh.w - add two halfwords into a word
# and with logical shift
# andh, andl - and into a halfword
# andnot - and x with ~y
# bfexts,bfextu - bitfield extract and extend (or zero)
# bfins - bitfield insert
# bld - copy arbitrary bit in reg to C and Z flags
# brev - reverse the bits [31:0] to [0:31]
# bst - copy the C flag to an arbitrary bit
# casts,castu - sign (or zero) extend byte or halfword
# cbr - clear bit in register
# clz - count leading zeros
# com - ones complement
# cpc - compare with carry.  updates carry, can do 64 and 128bit compares
# eor - exclusive or with optional shift
# frs - flush return stack
# icall - indirect call to submarine (Call to address in reg)
# lddpc - load from a pc-relative location
# lddsp - load from a sp-relative location
# ldins - load and insert a half/byte into a reg
# ldm - load multiple registers from consecutive memory (can load PC too)
# ldswp - load a halfword or word from memory and byte-swap (endianess)
# mac - multiply accumulate ( rd <- rx*ry + rd )
# mac* - lots of different types of multiply accumulate
# max  - return the maximum of rx or ry
# mcall - call to a location whose address is in memory
# min - return minimum of rx or ry
# mov* - conditional move
# mul* - lots of multiply types
# neg  - two's complement negate
# pabs - pack the absolute value of 4 bytes into a word
# pa*  - lots of packing/unpacking, as well as packed addition
# popm - pop multiple registers from stack
# pref - prefetch
# pushm - push multiple registers onto stack
# rcall - pc relative call
# ret*  - conditional return
#         you specify a register to be returned in r12
#         if you speficy LR or SP then you can set to -1 and 0 (success/fail)
#         also it sets the flags based on the return value being equal to 0
# rjmp  - jump relative to the program counter
# rsub  - reverse subtract
# sat*  - various saturating operations
# sbr   - set bit in register
# src   - set register conditionally
# stcond - store word conditionally
# stdsp  - store stack-pointer relative
# stm    - store multiple registers
# stswp  - swap and store (endianess)
# sub*   - conditional subtract
# swap   - swaps bytes
# tnbz   - test if no byte is equal to zero

# condition codes
#  eq=equal
#  ne=not equal
#  cc/hs=carry clear (higher or same)
#  cs/lo=carry set (lower)
#  ge=greater than or equal
#  lt=less than
#  mi=negative
#  pl=plus
#  ls=lower or same
#  gt=greater than
#  le=less than or equal
#  hi=higher
#  vs=overflow
#  vc=no overflow
#  qc=saturation
#  al=always

# Optimizations!
#  first run, 981 bytes.  to beat 969
# - brcc (branch on carry clear) 2-bytes less than bral (branch always)
# - when we use ld.ub it is sign extended so we can use 
#   cp.w which can take an immediate, saving 4 bytes each occurance
# - save out_buffer to reg of its own.  saves 2-bytes*5 or so
# - play with the branch flags some more, to use the 2-byte
#   versions of branches instead of 4-byte wherever possible
# - remove a debugging string I had forgotten about
# - add a "strcat2" so that we can preserve the r1 string
#   pointer across calls to print system info
# Down to 914 bytes now...



# no immediate form for most instructions

.include "logo.include"

# offsets into the results returned by the uname syscall
.equ U_SYSNAME,0
.equ U_NODENAME,65
.equ U_RELEASE,65*2
.equ U_VERSION,(65*3)
.equ U_MACHINE,(65*4)
.equ U_DOMAINNAME,65*5

# offset into the results returned by the sysinfo syscall
.equ S_TOTALRAM,16

# Sycscalls
.equ SYSCALL_EXIT,	1
.equ SYSCALL_READ,	3
.equ SYSCALL_WRITE,	4
.equ SYSCALL_OPEN,	5
.equ SYSCALL_CLOSE,	6
.equ SYSCALL_SYSINFO,	107
.equ SYSCALL_UNAME,	111

#
.equ STDIN,0
.equ STDOUT,1
.equ STDERR,2

	.globl _start	
_start:

	#=========================
	# PRINT LOGO
	#=========================

# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver

	mov	r1,out_buffer	# r1 is out_buffer
	mov     r2,(N-F)       	# r2 is R (N-F)
	mov	r3,logo		# r3 points to logo
	mov	r4,logo_end	# r4 points to logo_end
	mov	r12,text_buf	# r12 points to text_buf
	
decompression_loop:
        mov	r8,0			# clear the r8 register
	ld.ub	r8,r3++			# load a byte, increment pointer

	orl	r8,0xff00		# load top as a hackish 8-bit counter

test_flags:
	cp.w	r3,r4		# have we reached the end?
	brge	done_logo  	# if so, exit

	lsr 	r8,1		# shift bottom bit into carry flag
	brcs	discrete_char	# if set, we jump to discrete char

offset_length:
	ld.ub 	r0,r3++		# load a halfword and byteswap it
	ld.ub 	r9,r3++		
	lsl	r9,8	
	or	r9,r0

# we have a wonderful load and swap halfword instruction
#   but can't use it because it has to be aligned...
#	ldswp.uh r9,r3		# load 16-bits, increment pointer	
#	sub	 r3,-2
	
	mov	r11,r9		# copy r9 to r11
				# no need to mask r11, as we do it
				# by default in output_loop

	lsr	r9,P_BITS
	sub	r9,-(THRESHOLD+1)
				# d1 = (d4 >> P_BITS) + THRESHOLD + 1
				#                       (=match_length)
	mov	r10,r9          # loop value
	

output_loop:
	mov 	r0,((POSITION_MASK<<8)+0xff)
   	and	r11,r0			# mask it
	ld.ub 	r9,r12[r11]		# load byte from text_buf[]
	sub	r11,-1			# advance pointer in text_buf

store_byte:

	st.b	r1++,r9			# store a byte, increment pointer
	st.b	r12[r2],r9		# store a byte to text_buf[r]
	sub 	r2,-1			# r++
	mov	r0,(N-1)
	and	r2,r0			# mask r

	sub	r10,1			# decrement count and loop
	brne	output_loop		# if r10 is zero or above

	mov	r0,r8
	andl	r0,0xff00		# are the top bits 0?
	
	brne	test_flags		# if not, re-load flags

	breq	decompression_loop	# if above ne, we must be eq
					# optimization over bral

discrete_char:

	ld.ub	r9,r3++			# load a byte, increment pointer
	mov	r10,1			# only output one byte
					
	bral	store_byte		# and store it


# end of LZSS code

done_logo:
	mov	r11,out_buffer		# out_buffer we are printing to
	mov	r3,r11			# save for later
	call	write_stdout		# print the logo

optimizations:
	
	#==========================
	# PRINT VERSION
	#==========================
first_line:

	mov	r12,uname_info			# uname struct
	mov	r4,r12				# copy for later
	mov	r8,SYSCALL_UNAME
	scall					# do syscall

						# os-name from uname "Linux"
						# already at r1

	mov	r2,r3				# point r2 to out_buffer

	call	strcat2				# call strcat2

	mov	r1,ver_string			# source is " Version "
	call 	strcat			        # call strcat

	mov	r4,((uname_info)+U_RELEASE)
						# version from uname, ie "2.6.20"
	call	strcat2				# call strcat
	
#	mov	r1,compiled_string
						# source is ", Compiled "
	call	strcat				#  call strcat

	mov	r4,((uname_info)+U_VERSION)

						# compiled date
	call	strcat2				# call strcat

#	mov	r1,linefeed			# print a linefeed
	call	strcat

	call	center_and_print	# center and print

	#===============================
	# Middle-Line
	#===============================
middle_line:

	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	mov	r2,r3			# point a2 to out_buffer
	
	mov	r12,cpuinfo
					# '/proc/cpuinfo'
	mov	r11,0			# 0 = O_RDONLY <bits/fcntl.h>
	mov	r8,SYSCALL_OPEN			
	scall				# syscall.  return in r12  
	mov	r0,r12			# save our fd
	
					# fd should be in r12 still
	mov	r11,disk_buffer
	mov	r10,4096	        # 4096 is maximum size of proc file ;)
	
	mov	r8,SYSCALL_READ
	scall

	mov	r12,r0			# restore fd
	mov	r8,SYSCALL_CLOSE
	scall				# close (to be correct)


	#=============
	# Number of CPUs
	#=============
number_of_cpus:

#	mov     r1,one			# cheat.  How does avr32 do SMP?
		 			# r1 should be correct from before
	call	strcat

	#=========
	# MHz
	#=========
print_mhz:

	# /proc/cpuinfo on avr32 does not report megahertz
	# we'll report cpu family instead
	
        ld.w	r4,mily	   	  	 # look for cpu_family
	call	find_string		 # and print up to space

#	mov	r1,space		 # print a space
	call	strcat

	#=========
	# Chip Name
	#=========
chip_name:	
	ld.w	r4,type
	call	find_string
					# find 'type' and grab up to ' '

#	mov	r1,processor		# print " Processor, "
	call	strcat	
	
	#========
	# RAM
	#========
	
	mov	r12,sysinfo_buff
	mov	r8,SYSCALL_SYSINFO
	scall				# sysinfo() syscall
	
	mov	r0,sysinfo_buff		# size in bytes of RAM
	ld.w	r6,r0[S_TOTALRAM]
	lsr	r6,20			# divide by 1024*1024 to get M
	acr	r6			# round

	mov	r12,1			# use strcat
	call 	num_to_ascii

#	mov	r1,ram_comma		# print 'M RAM, '
	call	strcat			# call strcat
	

	#========
	# Bogomips
	#========
        ld.w	r4,mips
	call	find_string
					# find 'ips:' and grab up to '\n'
		
#	mov	r1,bogo_total	
	call	strcat			# print bogomips total
	
	call	center_and_print	# center and print

	#=================================
	# Print Host Name
	#=================================
last_line:
	mov	r2,r3		       	# point a2 to out_buffer	
	
	mov	r4,((uname_info)+U_NODENAME)
					# host name from uname()
	call	strcat2			# call strcat
	
	call	center_and_print	# center and print

	mov	r11,default_colors
					# restore colors, print a few linefeeds
	call	write_stdout
	
	
	#================================
	# Exit
	#================================
	

exit:
        mov r12,0			# return a 0
	mov r8,SYSCALL_EXIT
	scall		   		# exit

	#=================================
	# FIND_STRING 
	#=================================
	# r4 = string to find

find_string:
	mov	r6,(disk_buffer-1)	# look in cpuinfo buffer
find_loop:
	sub	r6,-1
	ld.w	r0,r6			# load unaligned word
	or	r0,r0
	breq	done			# if zero, then not found
	
	cp.w	r0,r4
	brne	find_loop		# loop until we find our string
		
	sub	r6,-4			# skip what we just searched
skip_tabs:
	ld.ub	r0,r6++			# read in a byte
	cp.w	r0,'\t'			# are we a tab?
	breq	skip_tabs		# if so, loop
	
	sub	r6,-1			# adjust pointer (skip colon)
	
store_loop:
	ld.ub	r0,r6++			# load a byte, increment pointer
	cp.w	r0,(' '+1)		
	brlt	almost_done		# using lt saves 2 bytes
	st.b	r2++,r0			# store a byte, increment pointer
	brge	store_loop		# if not lt, then must be ge
	
almost_done:
	mov	r0,0
	st.b	--r6,r0	       		# replace last value with NUL

done:
	retal	r12   			# return

	#================================
	# strcat (used to preserve linear string pointer)
	#================================
	# value to cat in r1
	# output buffer in r2
	# r0 trashed

strcat:
        ld.ub	r0,r1++			# load a byte, increment pointer 
	st.b	r2++,r0			# store a byte, increment pointer
	or	r0,r0			# set zero flag if zero
	brne	strcat			# loop if not zero
	sub	r2,1			# point to one less than null 
	retal	r12	       		# return
	#================================
	# strcat2
	#================================
	# value to cat in r4
	# output buffer in r2
	# r0 trashed	
strcat2:
        ld.ub	r0,r4++			# load a byte, increment pointer 
	st.b	r2++,r0			# store a byte, increment pointer
	or	r0,r0			# set zero flag if zero
	brne	strcat2			# loop if not zero
	sub	r2,1			# point to one less than null 
	retal	r12	       		# return	
	

	#==============================
	# center_and_print
	#==============================
	# string to center in output_buffer

center_and_print:

	pushm	lr			# save link register
	mov	r11,escape
					# we want to output ^[[
	call	write_stdout

	mov	r11,r3 			# point r11 to out_buffer
	mov	r6,r2
	sub	r6,r11			# get length by subtracting
					# r2 = r2-r11


	rsub	r6,r6,81		# reverse subtract! r2=81-r2
					# we use 81 to not count ending \n

	brmi	done_center		# if result negative, don't center
	
	lsr	r6,1			# divide by 2
	acr	r6     			# round?

	mov    	r12,0			# print to stdout
	call	num_to_ascii		# print number of spaces

	mov	r11,C			# we want to output C
	call	write_stdout

	mov	r11,r3			# point to out_buffer
	popm	lr	      		# restore link register
	
done_center:

	#================================
	# WRITE_STDOUT
	#================================
	# r11 has string

write_stdout:
	mov	r10,0				# clear count

str_loop1:
	sub	r10,-1
	ld.ub	r0,r11[r10]			# zero extend
	cp.w	r0,0				# see if we've reached end
	brne	str_loop1			# repeat till zero

write_stdout_we_know_size:

	mov	r12,STDOUT			# print to stdout
	mov	r8,SYSCALL_WRITE		# load the write syscall
	scall					# actually run syscall
	retal	r12				# return


	##############################
	# num_to_ascii
	##############################
	# r6 = value to print
	# r12 = 0=stdout, 1=strcat
		
num_to_ascii:

	csrf    0		# clear carry flag, so we can use
				# brcc which is 2 bytes smaller than bral
	
	mov	r11,(ascii_buffer+10)
				# point to end of our buffer

	mov	r0,10		# divide by 10

div_by_10:
	divu	r6,r6,r0	# divide by 10.  Q in r6, R in r7
	                        # GRRR! RD must be multiple of 2
				#   gas does not complain!

	sub	r7,-48		# convert to ascii
	st.b    --r11,r7	# store a byte, decrement pointer
	cp.w	r6,0		#
	brne	div_by_10	# if Q not zero, loop
	
write_out:
	cp.w	r12,0
	breq	ascii_stdout
	mov	r4,r11
	brcc	strcat2		# if 1, strcat
		
ascii_stdout:
	brcc 	write_stdout	# else, fallthrough to stdout

							
#===========================================================================
#	section .data
#===========================================================================
.data
data_begin:
#halfword_constants:	.short out_buffer,(N-F),logo,logo_end
#more_constants:		.short text_buf,uname_info,ver_string
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
linefeed:		.ascii  "\n\0"
one:	.ascii	"One \0"
space:	.ascii " \0"
processor:	.ascii	" Processor, \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\n\0"

default_colors:	.ascii "\033[0m\n\n\0"
escape:		.ascii "\033[\0"
C:		.ascii "C\0"
		
cpuinfo:	.ascii	"/proc/cpuinfo\0"
mily:		.ascii  "mily"
type:		.ascii  "type"
mips:		.ascii  "mips"


.include	"logo.lzss_new"


#============================================================================
#	section .bss
#============================================================================
#.bss
bss_begin:
.lcomm uname_info,(65*6),4
.lcomm sysinfo_buff,(64),4
.lcomm ascii_buffer,10,4
.lcomm  text_buf, (N+F-1),4
#
.lcomm	disk_buffer,4096,4	# we cheat!!!!
.lcomm	out_buffer,16384,4


	# see /usr/src/linux/include/linux/kernel.h

