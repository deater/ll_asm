#
#  linux_logo in vax assembler 0.26
#
#  Originally by 
#       Vince Weaver <vince _at_ deater.net>
#
#  Crazy size-optimization hacks by
#       Stephan Walter <stephan.walter _at_ gmx.ch>
#
#  assemble with     "as -o ll.o ll.vax.s"
#  link with         "ld -o ll ll.o"
#
#  I have to cross-compile, so what I do is was more like
#      make CROSS=vax-linux- ARCH=vax

# gnu assembler additions:
#  immediate char is $  (not #)
#  indirect char is *   (not @)
#  displacement sizing char is ` (not ^)
#  register names are r0 r1 r2 .. r15 ap fp sp pc
#  bitfields are not supported

# watch out for being able to use minimal sized jumps

#
# Has support for using variable length bitfields as an arbitrarily sized
#   integer!  Crazy.  gnu assembler doesn't support this.
# Hardware support for queues and strings?

# 16 32-bit general purpose registers.  Processor status longword.
#   r15=pc, r14=sp, r13=fp, r12=ap (argument pointer)
# Big-endian
# variable length instructions, 0-6 arguments
# >32 bit values are stored in adjacent registers




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
.equ SYSCALL_SYSINFO,	116
.equ SYSCALL_UNAME,	122

#
.equ STDIN,0
.equ STDOUT,1
.equ STDERR,2

	.globl _start	
_start:



pushl   %ap
pushl   $12 	     # length
pushl   $hello_string  # string
pushl   $STDOUT	     # stdout
pushl   $0x3
movl    %sp, %ap
movl	$SYSCALL_WRITE,%r0
chmk    %r0      
addl2   $16, %sp 
movl    (%sp)+, %ap
# returns in r0?


pushl  %ap
pushl  $0x2   		# exit value
pushl  $0x1   		# one argument?
movl   %sp, %ap 
movl   $SYSCALL_EXIT,%r0
chmk   %r0    		# chipmunk?       
addl2  $8, %sp 
movl    (%sp)+, %ap

#       movl	$SYSCALL_EXIT,%r0
#       movl	%sp,%ap
#       chmk	%r0


# from uclibc
# pushl   %%ap
# pushl   %2   
# pushl   $0x1 
# movl    %%sp, %%ap 
# chmk    %%r0       
# addl2   $8, %%sp 
# movl    (%%sp)+, %%ap



#register long _sc_0 __asm__("r0") = SYS_ify (name);
# long _sc_ret; \
# pushl   %%ap
# pushl   %4  
# pushl   %3  
# pushl   %2  
# pushl   $0x3
# movl    %%sp, %%ap
# chmk    %%r0      
# addl2   $16, %%sp 
# movl    (%%sp)+, %%ap
# returns in r0?
			   








































	#=========================
	# PRINT LOGO
	#=========================

# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver


#	move.l	#out_buffer,%a6		# buffer we are printing to
#	move.l	%a6,%a1
#	move.l  #(N-F),%d2		# R

#	move.l	#(logo),%a3		# a3 points to logo data
#	move.l	#(logo_end),%a4		# a4 points to logo end
#	move.l	#text_buf,%a5		# r5 points to text buf
	

decompression_loop:
#        clr.l	%d5			# clear the %d5 register
#	move.b	%a3@+,%d5		# load a byte, increment pointer

#	or.w	#0xff00,%d5		# load top as a hackish 8-bit counter

test_flags:
#	cmp.l	%a4,%a3		# have we reached the end?
#	bge	done_logo  	# if so, exit

#	lsr 	#1,%d5		# shift bottom bit into carry flag
#	bcs	discrete_char	# if set, we jump to discrete char

offset_length:
#	clr.l   %d4
#	move.b	%a3@+,%d0	# load 16-bits, increment pointer	
#	move.b	%a3@+,%d4	# do it in 2 steps because our data is little-endian :(
#	lsl.l	#8,%d4
#	move.b	%d0,%d4

#	move.l	%d4,%d6		# copy d4 to d6
				# no need to mask d6, as we do it
				# by default in output_loop

#	moveq.l	#P_BITS,%d0
#	lsr.l	%d0,%d4
#	move.l	#(THRESHOLD+1),%d0
#	add.l	%d0,%d4
#	add	%d4,%d1
				# d1 = (d4 >> P_BITS) + THRESHOLD + 1
				#                       (=match_length)

output_loop:
#   	andi	#((POSITION_MASK<<8)+0xff),%d6		# mask it
#	move.b 	%a5@(0,%d6),%d4		# load byte from text_buf[]
#	addq	#1,%d6			# advance pointer in text_buf

store_byte:

#	move.b	%d4,%a1@+		# store a byte, increment pointer
#	move.b	%d4,%a5@(0,%d2)		# store a byte to text_buf[r]
#	add 	#1,%d2			# r++
#	andi	#(N-1),%d2		# mask r

#	dbf	%d1,output_loop		# decrement count and loop
					# if %d1 is zero or above

#	bftst	%d5,16:8		# are the top bits 0?
#	bne	test_flags		# if not, re-load flags

#	jmp	decompression_loop

discrete_char:

#	move.b	%a3@+,%d4		# load a byte, increment pointer
#	clr.l	%d1			# we set d1 to zero which on m68k
					# means do the loop once

#	jmp	store_byte		# and store it


# end of LZSS code

done_logo:
#	move.l	%a6,%a3			# out_buffer we are printing to

#	bsr	write_stdout		# print the logo

optimizations:
	# Optimization setup
	
#	move.l	#strcat,%a5		# load strcat address into %a5
	
	#==========================
	# PRINT VERSION
	#==========================
first_line:



#	move.l	#uname_info,%d1			# uname struct
#	moveq.l	#SYSCALL_UNAME,%d0
#	trap	#0				# do syscall

#	move.l	%d1,%a1
						# os-name from uname "Linux"

#	move.l	%a6,%a2				# point %a2 to out_buffer

#	jsr	(%a5)				# call strcat

#	move.l	#ver_string,%a1			# source is " Version "
#	jsr 	(%a5)			        # call strcat

#	move.l	%a1,%a4
#	move.l	#((uname_info)+U_RELEASE),%a1
						# version from uname, ie "2.6.20"
#	jsr	(%a5)				# call strcat
#	move.l	%a4,%a1
	
						# source is ", Compiled "
#	jsr	(%a5)				#  call strcat

#	move.l	%a1,%a4
#	move.l	#((uname_info)+U_VERSION),%a1
						# compiled date
#	jsr	(%a5)				# call strcat

#	move.l	%a4,%a1
#	move.b	#0xa,%a2@+	        # store a linefeed, increment pointer
#	move.b	#0,%a2@+		# NUL terminate, increment pointer

#	bsr	center_and_print	# center and print

	#===============================
	# Middle-Line
	#===============================
middle_line:

	#=========
	# Load /proc/cpuinfo into buffer
	#=========

#	move.l	%a6,%a2			# point a2 to out_buffer
	
#	move.l	#(cpuinfo),%d1
					# '/proc/cpuinfo'
#	movq.l	#0,%d2			# 0 = O_RDONLY <bits/fcntl.h>
#	movq.l	#SYSCALL_OPEN,%d0			
#	trap	#0			# syscall.  return in d0?  
#	move.l	%d0,%d5			# save our fd
	
#	move.l	%d0,%d1			# move fd to right place
#	move.l	#disk_buffer,%d2
#	move.l	#4096,%d3
				 	# 4096 is maximum size of proc file ;)
#	move.l	#SYSCALL_READ,%d0
#	trap	#0

#	move.l	%d5,%d1
#	move.l	#SYSCALL_CLOSE,%d0
#	trap	#0
					# close (to be correct)


	#=============
	# Number of CPUs
	#=============
number_of_cpus:

					# cheat.  Who has an SMP arm?
#	jsr	(%a5)

	#=========
	# MHz
	#=========
print_mhz:
	
#	move.l	#(('i'<<24)+('n'<<16)+('g'<<8)+':'),%d0
#	bsr	find_string
					# find 'ing:' and grab up to '\n'

#	move.b  #' ',%a2@+		# put in a space

	#=========
	# Chip Name
	#=========
chip_name:	
#	move.l	#(('C'<<24)+('P'<<16)+('U'<<8)+':'),%d0
#	bsr	find_string
					# find 'CPU:' and grab up to '\n'

					# print " Processor, "
#	jsr	(%a5)	
	
	#========
	# RAM
	#========
	
#	move.l	#(sysinfo_buff),%d1
#	move.l	%d1,%a0		   	# copy
#	moveq.l	#SYSCALL_SYSINFO,%d0
#	trap	#0
					# sysinfo() syscall
	
#	move.l	%a0@(S_TOTALRAM),%d1	# size in bytes of RAM
#	moveq.l #20,%d3	
#	lsr.l	%d3,%d1			# divide by 1024*1024 to get M
#	adc	r3,r3,#0		# round

#	moveq.l	#1,%d0
#	move.l	%a1,%a4
#	bsr 	num_to_ascii
#	move.l	%a4,%a1

					# print 'M RAM, '
#	jsr	(%a5)			# call strcat
	

	#========
	# Bogomips
	#========
 #       move.l	#(('i'<<24)+('p'<<16)+('s'<<8)+':'),%d0
#	bsr	find_string
					# find 'ips:' and grab up to '\n'
					
#	jsr	(%a5)			# print bogomips total
	
#	bsr	center_and_print	# center and print

	#=================================
	# Print Host Name
	#=================================
last_line:
#	move.l	%a6,%a2			# point a2 to out_buffer	
	
#	move.l	#((uname_info)+U_NODENAME),%a1
					# host name from uname()
#	jsr	(%a5)			# call strcat
	
#	bsr	center_and_print	# center and print

#	move.l	#(default_colors),%a3
					# restore colors, print a few linefeeds
#	bsr	write_stdout
	
	
	#================================
	# Exit
	#================================
	

exit:
 #    	moveq.l	#0,%d1			# return a 0
#	moveq.l	#SYSCALL_EXIT,%d0
#	trap	#0		 	# and exit


	#=================================
	# FIND_STRING 
	#=================================
	# %d0 = string to find

find_string:

#	move.l	#(disk_buffer-1),%a3	# look in cpuinfo buffer
find_loop:
#	lea  	%a3@(1),%a3		# add one to pointer
#	move.l	%a3@,%d1		# load an unaligned word
#	beq	done			# if off the end, finish
#	cmp.l	%d1,%d0
#	bne	find_loop

#	lea	%a3@(4),%a3		# skip what we just searched
skip_tabs:
#	move.b	%a3@+,%d3		# read in a byte
#	cmp.b	#'\t',%d3		# are we a tab?
#	beq	skip_tabs		# if so, loop
	
#	lea	%a3@(-1),%a3		# adjust pointer
store_loop:
#	move.b	%a3@+,%d3		# load a byte, increment pointer
#	move.b	%d3,%a2@+		# store a byte, increment pointer
#	cmp.b	#'\n',%d3
#	bne	store_loop
	
almost_done:
#	move.l	#0,%d7
#	move.b	%d7,%a2@-		# replace last value with NUL

done:
#	rts				# return

	#================================
	# strcat
	#================================
	# value to cat in a1
	# output buffer in a2
	# d3 trashed
strcat:
#        move.b	%a1@+,%d3		# load a byte, increment pointer 
#	move.b	%d3,%a2@+		# store a byte, increment pointer
#	bne	strcat			# loop if not zero
#	sub	#1,%a2			# point to one less than null 
#	rts				# return
	

	#==============================
	# center_and_print
	#==============================
	# string to center in at output_buffer

center_and_print:

#	move.l	#(escape),%a3
					# we want to output ^[[
#	bsr	write_stdout

#	move.l	%a6,%a3			# point %a3 to out_buffer
#	suba.l	%a3,%a2			# get length by subtracting
					# a2 = a2-a3

#	move.l	%a2,%d3
#	move.l	#81,%d1
#	sub.l	%d3,%d1			# subtract! d1=d1-d3
					# we use 81 to not count ending \n

#	bmi	done_center		# if result negative, don't center
	
#	lsr	#1,%d1			# divide by 2
#	addx.l	%d1,#0     		# round?

#	move.l	#0,%d0			# print to stdout
#	bsr	num_to_ascii		# print number of spaces

#	move.l	#(C),%a3
					# we want to output C
#	bsr	write_stdout

#	move.l	%a6,%a3

done_center:

	#================================
	# WRITE_STDOUT
	#================================
	# a3 has string
	# d0,d1,d2,d3 trashed
write_stdout:
#	moveq.l	#0,%d3				# clear count

str_loop1:
#	add	#1,%d3
#	move.b	%a3@(0,%d3),%d2
#	bne	str_loop1			# repeat till zero

write_stdout_we_know_size:
#	move.l	%a3,%d2
#	moveq.l	#STDOUT,%d1			# print to stdout
#	moveq.l	#SYSCALL_WRITE,%d0		# load the write syscall
#	trap	#0				# actually run syscall
#	rts					# return


	##############################
	# num_to_ascii
	##############################
	# d1 = value to print
	# d0 = 0=stdout, 1=strcat
	
num_to_ascii:
#	move.l	#(ascii_buffer+10),%a3
				# point to end of our buffer

div_by_10:
#	divu.w	#10,%d1		# divide by 10.  Q in lower, R in upper
#	bfextu	%d1,0:16,%d2	# copy remainder to %d2
#	bfextu	%d1,16:16,%d1	# mask out quotient into %d1

#	bl	divide		@ Q=r7,$0, R=r8,$1
#	add	#0x30,%d2	# convert to ascii
#	move.b	%d2,%a3@-	# store a byte, decrement pointer
#	cmp	#0,%d1		#
#	bne	div_by_10	# if Q not zero, loop
	
write_out:


#	cmp	#0,%d0
#	beq	ascii_stdout
#	move.l	%a3,%a1
#	jmp	(%a5)		# if 1, strcat
		
ascii_stdout:
#	jmp 	write_stdout	# else, fallthrough to stdout


							
#===========================================================================
#	section .data
#===========================================================================
.data
data_begin:
hello_string:   .ascii "Hello World\n\0"
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
one:	.ascii	"One \0"
processor:	.ascii	" Processor, \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\n\0"

default_colors:	.ascii "\033[0m\n\n\0"
escape:		.ascii "\033[\0"
C:		.ascii "C\0"
		
cpuinfo:	.ascii	"/proc/cpuinfo\0"

.include	"logo.lzss_new"


#============================================================================
#	section .bss
#============================================================================
#.bss
bss_begin:
.lcomm uname_info,(65*6)
.lcomm sysinfo_buff,(64)
.lcomm ascii_buffer,10
.lcomm  text_buf, (N+F-1)

.lcomm	disk_buffer,4096	# we cheat!!!!
.lcomm	out_buffer,16384


	# see /usr/src/linux/include/linux/kernel.h

