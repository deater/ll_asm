#
#  linux_logo in mips assembler 0.38
#
#  By
#       Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -o ll.o ll.mips.s"
#  link with         "ld -o ll ll.o"

.include "logo.include"

#
# Keep gas from handling branch-delay and load-delay slots automatically
#

.set noreorder

#
# Keep gas from using the assembly temp register (no pseudo-ops basically)
#

.set noat

#
# Register definitions.  Why does't gas know these?
#

#.equ zero , 0
#.equ at   , 1  # Assembler Temporary
#.equ v0   , 2  # Returned value registers
#.equ v1   , 3
#.equ a0   , 4  # Argument Registers (Caller Saved)
#.equ a1   , 5
#.equ a2   , 6
#.equ a3   , 7
#.equ t0   , 8  # Temporary (Caller Saved)
#.equ t1   , 9
#.equ t2   ,10
#.equ t3   ,11
#.equ t4   ,12
#.equ t5   ,13
#.equ t6   ,14
#.equ t7   ,15
#.equ s0   ,16  # Callee-Saved
#.equ s1   ,17
#.equ s2   ,18
#.equ s3   ,19
#.equ s4   ,20
#.equ s5   ,21
#.equ s6   ,22
#.equ s7   ,23
#.equ t8   ,24
#.equ t9   ,25
#.equ k0   ,26  # Kernel Reserved (do not use!)
#.equ k1   ,27
#.equ gp   ,28  # Global Pointer
#.equ sp   ,29  # Stack Pointer
#.equ fp   ,30  # Frame Pointer (GCC)
#.equ s8   ,30  # s8 on mips compiler
#.equ ra   ,31  # return address (of subroutine call)


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
#  -- the lower syscalls are compat with IRIX, etc
#     syscalls trash r14?
#  -- no branch delay after syscall

.equ SYSCALL_LINUX,	4000
.equ SYSCALL_EXIT,      SYSCALL_LINUX+1
.equ SYSCALL_READ,      SYSCALL_LINUX+3
.equ SYSCALL_WRITE,     SYSCALL_LINUX+4
.equ SYSCALL_OPEN,      SYSCALL_LINUX+5
.equ SYSCALL_CLOSE,     SYSCALL_LINUX+6
.equ SYSCALL_SYSINFO,   SYSCALL_LINUX+116
.equ SYSCALL_UNAME,     SYSCALL_LINUX+122

#
.equ STDIN, 0
.equ STDOUT,1
.equ STDERR,2

	.globl __start
__start:
	#=========================
	# PRINT LOGO
	#=========================

# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver

	la	$17,data_begin		# point $17 at .data segment begin
	la	$18,bss_begin		# point $18 at .bss segment begin

	li      $8,(N-F)   	     	# R

	addiu  	$9,$17,(logo-data_begin)	# $9 points to logo
	addiu	$12,$17,(logo_end-data_begin)	# $12 points to end of logo
	addiu	$16,$18,(out_buffer-bss_begin)	# point $16 to out_buffer

decompression_loop:

	lbu	$10,0($9)       # load in a byte
	addiu	$9,$9,1		# increment source pointer

	move 	$11, $10	# move in the flags
	ori 	$11,$11,0xff00  # put 0xff in top as a hackish 8-bit counter

test_flags:
	beq	$12, $9, done_logo	# have we reached the end?
					# if so, exit
	# BRANCH DELAY SLOT
        andi	$13,$11,0x1	# test to see if discrete char


	bne	$13,$0,discrete_char	# if set, we jump to discrete char

	# BRANCH DELAY SLOT
	srl	$11,$11,1  	# shift


offset_length:
	lbu     $10,0($9)	# load 16-bit length and match_position combo
	lbu	$24,1($9)	# can't use lhu because might be unaligned
	addiu	$9,$9,2	 	# increment source pointer
	sll	$24,$24,8
	or	$24,$24,$10

	srl $15,$24,P_BITS	# get the top bits, which is length

	addiu $15,$15,THRESHOLD+1
	      			# add in the threshold?

output_loop:
        andi 	$24,$24,(POSITION_MASK<<8+0xff)
					# get the position bits
	addiu	$10,$18,(text_buf-bss_begin)
	addu	$10,$10,$24
	lbu	$10,0($10)		# load byte from text_buf[]
					# should have been able to do
					# in 2 not 3 instr
	addiu	$24,$24,1	    	# advance pointer in text_buf
store_byte:
        sb      $10,0($16)
	addiu	$16,$16,1      		# store byte to output buffer

	addiu	$1,$18,(text_buf-bss_begin)
	addu	$1,$1,$8
	sb      $10, 0($1)		# store also to text_buf[r]
	addi 	$8,$8,1        		# r++


	addiu	$15,$15,-1		# decrement count
	bne	$15,$0,output_loop	# repeat until k>j
	#BRANCH DELAY SLOT
	andi 	$8,$8,(N-1)		# wrap r if we are too big

	andi	$13,$11,0xff00		# if 0 we shifted through 8 and must
	bne	$13,$0,test_flags	# re-load flags
	# BRANCH DELAY SLOT
	nop

	j 	decompression_loop
	# BRANCH DELAY SLOT
	nop

discrete_char:
	lbu     $10,0($9)
	addiu	$9,$9,1		       	# load a byte
        j     store_byte		# and store it
	# BRANCH DELAY SLOT
	li   	$15,1			# force a one-byte output

# end of LZSS code

done_logo:

        jal	write_stdout			# print the logo
	# BRANCH DELAY SLOT
	addiu	$5,$18,(out_buffer-bss_begin)	# point $5 to out_buffer


first_line:
	#==========================
	# PRINT VERSION
	#==========================

	li	$2, SYSCALL_UNAME		# uname syscall in $2
	addiu	$4, $18,(uname_info-bss_begin)	# destination of uname in $4
	syscall					# do syscall

	addiu	$16,$18,(out_buffer-bss_begin)	# point $16 to out_buffer


					# os-name from uname "Linux"
	jal	strcat
	# BRANCH DELAY SLOT
	addiu	$5,$18,((uname_info-bss_begin)+U_SYSNAME)


					# source is " Version "
       	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
	addiu	$5,$17,(ver_string-data_begin)


					# version from uname, ie "2.6.20"
	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
	addiu	$5,$18,((uname_info-bss_begin)+U_RELEASE)

					# source is ", Compiled "
	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
	addiu	$5,$17,(compiled_string-data_begin)

					# compiled date
	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
	addiu	$5,$18,((uname_info-bss_begin)+U_VERSION)

	jal	center_and_print	# center and print
	# BRANCH DELAY SLOT
	nop

	#===============================
	# Middle-Line
	#===============================
middle_line:

	addiu	$16,$18,(out_buffer-bss_begin)	# point $16 to out_buffer

	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	li	$2, SYSCALL_OPEN	# OPEN Syscall

	addiu	$4,$17,(cpuinfo-data_begin)
					# '/proc/cpuinfo'
	li	$5, 0			# 0 = O_RDONLY <bits/fcntl.h>

	syscall				# syscall.  fd in v0
					# we should check that
					# return v0>=0

	move	$4,$2			# copy $2 (the result) to $4

	li	$2, SYSCALL_READ	# read()

	addiu	$5, $18,(disk_buffer-bss_begin)
					# point $5 to the buffer

	li	$6, 4096		# 4096 is maximum size of proc file ;)
					# we load sneakily by knowing
	syscall

	li	$2, SYSCALL_CLOSE	# close (to be correct)
		    			# fd should still be in a0
	syscall

	#=============
	# Number of CPUs
	#=============
number_of_cpus:

	# we cheat here and just assume 1.
	# besides, I don't have a SMP Mips machine to test on

	jal	strcat
	# BRANCH DELAY SLOT
	addiu	$5,$17,(one-data_begin)		# print "One"


	#=========
	# MHz
	#=========
print_mhz:

	# Mips /proc/cpuinfo does not indicate MHz


   	#=========
	# Chip Name
	#=========
chip_name:

.ifdef LITTLE_ENDIAN
   	li	$4,('l'<<24+'e'<<16+'d'<<8+'o')
.else
   	li	$4,('o'<<24+'d'<<16+'e'<<8+'l')
.endif
					# find 'odel\t: ' and grab up to ' '

	jal	find_string
	# BRANCH DELAY SLOT
	li	$6,' '

					# print "Processor, "
	jal	strcat
	# BRANCH DELAY SLOT
	addiu	$5,$17,(processor-data_begin)

	#========
	# RAM
	#========

	li	$2, SYSCALL_SYSINFO	# sysinfo() syscall
	addiu	$4, $18,(sysinfo_buff-bss_begin)
	syscall

	lw	$4, S_TOTALRAM($4)	# size in bytes of RAM
	# LOAD DELAY SLOT
	li	$19,1			# print to strcat, not stderr

	jal     num_to_ascii
	# BRANCH DELAY SLOT
	srl	$4,$4,20		# divide by 1024*1024 to get M


					# print 'M RAM, '
	jal	strcat			# call strcat
	# BRANCH_DELAY_SLOT
	addiu	$5,$17,(ram_comma-data_begin)


	#========
	# Bogomips
	#========

.ifdef LITTLE_ENDIAN
	li	$4, ('S'<<24+'P'<<16+'I'<<8+'M')
.else
	li	$4, ('M'<<24+'I'<<16+'P'<<8+'S')
.endif
					# find 'mips\t: ' and grab up to \n

	jal	find_string
	# BRANCH DELAY SLOT
	li	$6, 0xa

					# bogo total follows RAM
	jal 	strcat			# call strcat
	# BRANCH DELAY SLOT
	addiu	$5,$17,(bogo_total-data_begin)


	jal	center_and_print	# center and print
	# BRANCH DELAY SLOT
	nop

	#=================================
	# Print Host Name
	#=================================

	addiu	$16,$18,(out_buffer-bss_begin)
					# point $16 to out_buffer


					# host name from uname()
	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
	addiu	$5,$18,(uname_info-bss_begin)+U_NODENAME

	jal	center_and_print	# center and print
	# BRANCH DELAY SLOT
	nop
					# (.txt) pointer to default_colors
	jal	write_stdout
	# BRANCH DELAY SLOT
	addiu	$5,$17,(default_colors-data_begin)


	#================================
	# Exit
	#================================
exit:
     	li	$2, SYSCALL_EXIT	# put exit syscall in v0
	li	$4, 0			# put exit code in a0
        syscall	    			# exit


	#=================================
	# FIND_STRING
	#=================================
	#   $6 (a2) is char to end at
	#   $4 (a0) is 4-char ascii string to look for
	#   $17 (s1) is the output buffer

	#   $5 is destroyed
	#   $11 (t3) is destroyed

find_string:
	addiu	$5, $18,(disk_buffer-bss_begin)-1
					# look in cpuinfo buffer
find_loop:

	ulw	$11,1($5)		# load un-aligned 32 bits
	beq	$11,$0,done		# are we at EOF?
					# if so, done
	# BRANCH DELAY SLOT
	addiu   $5,$5,1		        # increment pointer


	bne	$4,$11, find_loop	# do the strings match?
					# if not, loop

					# if we get this far, we matched
	# BRANCH DELAY SLOT
	nop

find_colon:
	lbu	$11,1($5)		# repeat till we find colon
	# LOAD DELAY SLOT
	addiu	$5,$5,1
	beq	$11,$0,done		# not found? then done
	# BRANCH DELAY SLOT
	nop

	bne	$11,$1,find_colon
	# BRANCH DELAY SLOT
	li	$1,':'

	addiu   $5,$5,2			# skip a char [should be space]

store_loop:
	lbu	$11,0($5)		# load value
	# LOAD DELAY SLOT
	addiu	$5,$5,1			# increment
	beq	$11,$0,done		# off end, then stop
	# BRANCH DELAY SLOT
	nop

	beq	$11,$6,done      	# is it end char?
	# BRANCH DELAY SLOT
	nop				# if so, finish

	sb	$11,0($16)		# if not store and continue
	j	store_loop		# loop
	# BRANCH DELAY SLOT
	addiu	$16,$16,1		# increment output pointer

done:
	jr	$31			# return
	# BRANCH DELAY SLOT
	nop


	#==============================
	# center_and_print
	#==============================
	# string is in $16 (s0) output_buffer
	# s3 $19= stdout or strcat
        # $20, $21, $22 trashed

center_and_print:

	move	$21,$31				# save return address
	move	$20,$16				# $20 is the end of our string
	addiu	$16,$18,(out_buffer-bss_begin)	# point $16 to beginning


	subu	$4, $20,$16		# subtract end pointer from start
       		    			# (cheaty way to get size of string)

	slti	$1,$4,81
	beq	$1,$0, done_center	# don't center if > 80
	# BRANCH DELAY SLOT
	li    	$19,0 			# print to stdout

	neg	$4,$4  			# negate length
	addiu	$4,$4,80		# add to 80

	srl	$22,$4,1		# divide by 2

	jal	write_stdout		# print ESCAPE char
	# BRANCH DELAY SLOT
	addiu	$5,$17,(escape-data_begin)


	jal	num_to_ascii		# print number of spaces
	# BRANCH DELAY SLOT
	move	$4,$22			# how much to shift to right

	jal	write_stdout
	# BRANCH DELAY SLOT
	addiu	$5,$17,(c-data_begin)	# print "C"


done_center:
					# point to the string to print
	jal 	write_stdout
	# BRANCH DELAY SLOT
	addiu	$5,$18,(out_buffer-bss_begin)


	addiu	$5,$17,(linefeed-data_begin)
					# print linefeed at end of line

	move 	$31,$21 		# restore saved pointer
	     				# so we'll return to
					# where we were called from
					# at the end of the write_stdout

	#================================
	# WRITE_STDOUT
	#================================
	# $5 (a1) has string
	# $24,$25 (t8,t9) destroyed


write_stdout:
	li      $2, SYSCALL_WRITE       # Write syscall in $2
	li	$4, STDOUT		# 1 in $4 (stdout)

	li	$6, 0			# 0 (count) in $6

	move	$25,$5			# copy string to $25

str_loop1:
	lbu	$24,1($25)		# load byte at (t9)
	addi	$25,$25,1		# LOAD DELAY SLOT
	bnez	$24,str_loop1		# if not nul, repeat
	# BRANCH DELAY SLOT
	addi	$6,$6,1			# increment a2
	syscall  			# run the syscall

	jr	$31 			# return
	# BRANCH DELAY SLOT
	nop

	#=============================
	# num_to_ascii
	#=============================
	# a0 ($4)  = value to print
	# a1 ($5)  = output buffer
	# s3 ($19) = 0=stdout, 1=strcat
	# destroys t2 ($10)
	# destroys t3 ($11)
	# destroys a0 ($4)

num_to_ascii:

	addiu	 $5,(ascii_buffer-bss_begin)+10
				# point to end of ascii_buffer

div_by_10:
	addiu	$5,$5,-1	# point back one
	li	$1,10
	divu	$10,$4,$1	# divide.  hi= remainder, lo=quotient
	mfhi	$11		# remainder into t3 ($11)
	addiu	$11,$11,0x30	# convert to ascii
	sb	$11,0($5)	# store to buffer
	bne	$10,$0, div_by_10
	# BRANCH DELAY SLOT
	move	$4,$10		# move old result into next divide

write_out:
	beq	$19,$0,write_stdout
	# BRANCH DELAY SLOT
	nop			# if write stdout, go there

				# fall through to strcat

	#================================
	# strcat
	#================================
	# output_buffer_offset = $16 (s0)
	# string to cat = $5         (a1)
	# destroys t0 ($8)

strcat:
	lbu 	$8,0($5)		# load byte from string
	# LOAD DELAY SLOT
	addiu	$5,$5,1			# increment string
	sb  	$8,0($16)		# store byte to output_buffer

	bne 	$8,$0,strcat		# if zero, we are done
	# BRANCH DELAY SLOT
	addiu	$16,$16,1		# increment output_buffer

done_strcat:
	jr	$31			# return
	# BRANCH DELAY SLOT
	addiu	$16,$16,-1		# correct pointer




#===========================================================================
#	section .data
#===========================================================================
.data

data_begin:
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"
linefeed:	.ascii  "\n\0"
default_colors:	.ascii "\033[0m\n\n\0"
escape:		.ascii "\033[\0"
c:		.ascii "C\0"

.ifdef FAKE_PROC
.ifdef LITTLE_ENDIAN
cpuinfo:	.ascii  "proc/c.mipsel\0"
.else
cpuinfo:	.ascii  "proc/cpu.mips\0"
.endif
.else
cpuinfo:	.ascii	"/proc/cpuinfo\0"
.endif

one:	.ascii	"One MIPS \0"
processor:	.ascii " Processor, \0"

.include	"logo.lzss_new"

#============================================================================
#	section .bss
#============================================================================
.bss
bss_begin:
.lcomm  text_buf, (N+F-1)
.lcomm	out_buffer,16384

.lcomm	disk_buffer,4096	# we cheat!!!!

.lcomm  ascii_buffer,10		# 32 bit can't be > 9 chars

   # see /usr/src/linux/include/linux/kernel.h
.lcomm sysinfo_buff,(64)
.lcomm uname_info,(65*6)
