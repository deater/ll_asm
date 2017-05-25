#  linux_logo in micromips (mips16e2) assembler 0.49
#
#  By
#       Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -mmicromips -o ll.micromips.o ll.micromips.s"
#  link with         "ld -o ll_micromips ll.micromips.o"

#.nan    legacy

.include "logo.include"

#
# If ARM -> THUMB -> THUMB2 then
#   MIPS -> MIPS16 -> MICROMIPS

# hard to find a good accurate document on all of this
#
# MIPS Architecture for Programmers Volume II-B: microMIPS32TM Instruction Set

# Various things:
#	for stores, can't store s0 but stores zero instead
#

#	Apparently R6 added a lot of new micromips instructions but
#		documentation not clear which is which.
#	To get QEMU to execute an R6 sysetem (complains about NaN ABIFAG)
#		need -mnan=2008 to as


# New 32-bit instructions
#	+ addiupc -- addi pc relative
#	+ beqzc/bnezc	-- branch, no delay slot
#	+ jals/jalrs -- jump and link, sort (16-bit) delay slot
#	+ jalrs.hb -- hazzard barrier?
#	+ lwp/lwxs/lwm32 -- load word pairs
#	+ swp/swm32 -- store word pairs

# New 16-bit instructions
#	+ bc -- branch compact
#	+ jrcaddiusp -- adjust stack pointer
#	+ lbu16 -- can have offset of 0-14 and -1
#	+ lwgp -- load from global pointer
#		gas syntax seems to be
#			lw      $s0,1024($gp)
#		and you can't do useful pointer math on it :(

# can put "16" or "32" at end of instruction to force encoding

# Difference from mips16
#	+ andi/ori/xori
#	+ cache
#	+ ext -- extract bitfield
#	+ ins -- insert bitfield
#	+ loads can be GP relative
#	+ lui -- load upper immediate
#	+ ll/sc/pause
#	+ move conditional
#	+ prefetch
# + Removal of all non-MIPS32 instructions (bt/cmp/save/restore)?


#
# MIPS16e2
#
# Can do 64-bit ops on 64-bit procs
#  Has 8 registers:
#	0,1,2,3,4,5,6,7 correpsond to MIPS32 16,17,2,3,4,5,6,7
#	don't use 0-7 though, use $16,$17,$2 etc
# MIPS32 reg 24 is used as a condition code register
# MIPS32 reg 29 is SP and 31 is RA
#   mips16 mov instruction can access all registers
# JALX, JR, JALR, JALRC and JRC can switch between 16/32 mode
# PC relative addressing is added for lw and addi
# an instruction can be "extended" to have up to a 16-bit immediate

# Instructions (64-bit instructions only avail on 64-bit CPU)
# + load instructions : lb/lbu/ld/lh/lhu/lw/lwu
#   * lb ry, offset(rx)  -- offset=5bits (extnd to 16-bits)
#   * lw can also be SP or PC relative
# + store instructions: sb/sd/sh/sw
#
# "Extended" instructions allow making immediate field larger,
#    for a 32-bit instruction
#    cannot be in branch delay slots

#
# Optimization:
#  LZSS:
#	+ 118 bytes -- original port of mips16 code
#	+ 108 bytes -- use andi and lhu where appropriate
#	+  86 bytes -- lots of fighting to get 16-bit versions,
#			using non-mips16-regs, and playing
#			with branch delay slots

#
# Overall:
#	+ 1396 bytes -- original port of mips16 code
#	+ 1362 bytes -- use --relax flag to ld
#	+ 1396 bytes -- when using relax it segfaults :(
#	+ 1388 bytes -- use andi and lhu where appropriate
#	+ 1387 bytes -- finish with lzss optimization
#			as you can see, there were tradeoffs :(
#	+ 1323 bytes -- optimized first line.
#			Used "jals" when possible
#			Also made sure addiu16 could be used (mult of 4)
#			Also use of gp-based  loads
#	+ 1323 bytes -- undo the syscall# optimization as it doesn't help here
#			due to limitations on 16-bit addiu constant size
#	+ 1275 bytes -- make all ver_string_addr calls gp relative
#	+ 1243 bytes -- optimize the syscall area, lots of gp relative
#	+ 1227 bytes -- optimize RAM, jals and gp use
#	+ 1211 bytes -- more jals/gp relative
#	+ 1195 bytes -- more gp/jals/delay slot
#	+ 1163 bytes -- more of the same, through end of center_and_print

#
# ASSEMBLER ANNOYANCES: (gas 2.28)
#	+ doesn't know about about the bc16 instruction
#		(though that might be a r6 only instruction, grr)
#	+ can't handle complex math on gp indexed loads
#	+ can't do addiupc on a symbol, and only uses it on
#		la with --relax but that breaks other things

#
# Keep gas from handling branch-delay and load-delay slots automatically
#

#.set noreorder

#
# Register definitions.  Older gas could only hand numerical
#                        16 17  2  3  4  5  6  7
# On MIPS16 you only get s0,s1,v0,v1,a0,a1,a2,a3

# Traditional MIPS register values
# zero  = 0
# at    = 1     # Assembler Temporary
# v0-v1 = 2-3   # Returned value registers
# a0-a3 = 4-7   # Argument Registers (Caller Saved)
# t0-t7 = 8-15  # Temporary (Caller Saved)
# s0-s7 = 16-23 # Callee-Saved
# t8-t9 = 24-25
# k0-k1 = 26-27 # Kernel Reserved (do not use!)
# gp    = 28    # Global Pointer
# sp    = 29    # Stack Pointer
# fp    = 30    # Frame Pointer (GCC)
# s8    = 30    # s8 on mips compiler
# ra    = 31    # return address (of subroutine call)


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
.equ SYSCALL_SYNC,	SYSCALL_LINUX+36

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


	# I hate gas!  These should be easy to convert to PC relative
	# and take only 32-bits, but gas takes 64-bits to load them
	la	$s1,logo
	la	$gp,data_begin		# point gp reg to data_begin

#	lw	$s0,out_buffer_addr
	lw	$s0,0x0($gp)		# 0x00 = out_buffer_addr

	li      $a2,(N-F)   	     	# R
	la	$t0,logo_end


decompression_loop:

	lbu	$v0,0($s1)	# load in a byte
	addiu	$s1,$s1,1	# increment source pointer

	ori	$v0,0xff00	# put 0xff in top as a hackish 8-bit counter


test_flags:

	# Have to force the delay slot here, the assembler couldn't see it
.set noreorder
					# have we reached the end?
	beq	$s1,$t0,done_logo	# if so, exit

	andi	$a3,$v0,1	# test to see if discrete char
.set reorder

	srl	$v0,$v0,1	# shift

	bnez	$a3,discrete_char
				# if set, we jump to discrete char

offset_length:
	lhu	$a0,0($s1)	# unaligned 16-bit load
	wsbh	$a0,$a0		# byte swap to get big-endian

	addiu	$s1,2		# increment source pointer

	srl	$a1,$a0,P_BITS	# get the top bits, which is length

	addiu	$a1,$a1,THRESHOLD+1
	      			# add in the threshold

output_loop:
	andi	$a0,(POSITION_MASK<<8+0xff)
					# get the position bits

	lw	$a3,4($gp)		# text_buf_addr
	addu	$a3,$a0
	lbu	$v1,0($a3)		# load byte from text_buf[]

	addiu	$a0,$a0,1	    	# advance pointer in text_buf

store_byte:
	sb	$v1,0($s0)		# store byte to output buffer
	addiu	$s0,1      		# increment pointer

	lw      $a3,4($gp)		# text_buf_addr
	addu	$a3,$a2

	sb	$v1,0($a3)		# store also to text_buf[r]
	addiu 	$a2,$a2,1		# r++

	andi 	$a2,(N-1)	        # wrap r if we are too big

	addiu	$a1,$a1,-1		# decrement count


	bnezc	$a1,output_loop		# repeat until k>j
	andi	$v1,$v0,0xff00		# if 0 we shifted through 8 and must

	bnez	$v1,test_flags		# re-load flags
.set noreorder
	beqz	$v1,decompression_loop
					# force the next insn in delay
					# slot, which is harmless
discrete_char:
	lbu	$v1,0($s1)		# load a byte
.set reorder
	addiu	$s1,1			# increment pointer
	li	$a1,1			# force a one-byte output
	b	store_byte		# and store it

# end of LZSS code

done_logo:
	lw	$a1,0($gp)		# point $a1 to out_buffer
	jals	write_stdout		# print the logo

	la	$s1,strcat

first_line:
	#==========================
	# PRINT VERSION
	#==========================

	li	$v0, SYSCALL_UNAME	# uname syscall in $v0
	lw	$a0,8($gp)		# uname_info_addr
					# destination of uname in $a0
	syscall

	lw	$s0,0($gp)		# point $s0 to out_buffer

					# os-name from uname "Linux"
	lw	$a1,8($gp)
	#addiu	$a1,U_SYSNAME		U_SYSNAME is zero
	jalrs	$s1			# strcat

					# source is " Version "
	lw	$a1,12($gp)		# ver_string_addr
	jalrs	$s1			# strcat

					# version from uname, ie "2.6.20"
	lw	$a1,8($gp)		# uname_info_addr
	addiu	$a1,U_RELEASE
	jalr	$s1			# strcat

compiled:
	lw	$a1,12($gp)		# ver_string_addr
	addiu	$a1,12			# (compiled_string-ver_string)
					# source is ", Compiled "
	jalrs	$s1			# strcat

					# compiled date
	lw	$a1,8($gp)		# uname_info_addr
	addiu	$a1,U_VERSION
	jalr	$s1			# strcat

	jals	center_and_print	# center and print

	#===============================
	# Middle-Line
	#===============================
middle_line:

	lw	$s0,0($gp)		# point $s0 to out_buffer

	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	# syscalls are high enough to make loading the value take
	# extended instructions, which keeps them from going in
	# the branch delay slot.  So we use offsets instead.
	li	$v0,SYSCALL_OPEN	# open()

	lw	$a0,12($gp)		# ver_string_addr
	addiu	$a0,(cpuinfo-ver_string)
					# '/proc/cpuinfo'
	li	$a1, 0			# 0 = O_RDONLY <bits/fcntl.h>

	syscall				# syscall.  fd in v0
					# we should check that
					# return v0>=0

	move	$a0,$v0			# copy $v0 (the result) to $a0

	li	$v0,SYSCALL_READ	# read()

	lw	$a1,16($gp)		# point $a1 to the buffer
	li	$a2, 4096		# 4096 should be more than enough
					# for this proc file
	syscall

	li	$v0,SYSCALL_CLOSE	# close (to be correct)
		    			# fd should still be in a0
	syscall


	li	$v0,SYSCALL_SYSINFO	# sysinfo() syscall
	lw	$a0,20($gp) 		# sysinfo_buff_addr
	syscall


	#=============
	# Number of CPUs
	#=============
number_of_cpus:

	# we cheat here and just assume 1.
	# besides, I don't have a SMP Mips machine to test on

	lw	$a1,12($gp)
	addiu	$a1,(one-ver_string)	# print "One MIPS "
	jalr	$s1			# strcat

	#=========
	# MHz
	#=========
print_mhz:

	# Mips /proc/cpuinfo does not indicate MHz


   	#=========
	# Chip Name
	#=========
chip_name:
   	lw	$a0,124($gp)		# odel_string
					# find 'odel\t: ' and grab up to ' '
	li	$a3,' '
	jals	find_string

					# print "Processor, "
	lw	$a1,12($gp)
	addiu	$a1,(processor-ver_string)
	jalr	$s1			# strcat

	#========
	# RAM
	#========
ram:
	lw	$a0, 20($gp)		# sysinfo_buff_addr
	lw	$a0, S_TOTALRAM($a0)	# size in bytes of RAM

	srl	$a0,$a0,20		# divide by 1024*1024 to get M
					# note, splitting into two does
					# not help with delay slot
					# (still too big)
	li	$a3,1			# print to strcat, not stderr
	jals	num_to_ascii

					# print 'M RAM, '
	lw	$a1,12($gp)
	addiu16	$a1,24			# (ram_comma-ver_string)
	jalrs	$s1			# strcat

	#========
	# Bogomips
	#========
bogomips:
   	lw	$a0,128($gp)		# mips_string
					# find 'MIPS\t: ' and grab up to \n

	li	$a3, 0xa
	jals	find_string

					# bogo total follows RAM
	lw	$a1,12($gp)
	addiu	$a1,32			# (bogo_total-ver_string)
	jalr	$s1			# strcat

	jals	center_and_print	# center and print


	#=================================
	# Print Host Name
	#=================================
hostname:
	lw	$s0,0($gp)		# point $s0 to out_buffer

					# host name from uname()
	lw	$a1,8($gp)		# uname_info_addr
	addiu	$a1,U_NODENAME
	jalr	$s1			# strcat

	jals	center_and_print	# center and print


					# (.txt) pointer to default_colors
	lw	$a1,12($gp)

	addiu	$a1,48			# (default_colors-ver_string)
	jal	write_stdout


	#================================
	# Exit
	#================================
exit:
	li	$v0,SYSCALL_EXIT	# put exit syscall in v0
	li	$a0,5			# put exit code in a0
	syscall

	#=================================
	# FIND_STRING
	#=================================
	#   $a3 is char to end at
	#   $a0 is 4-char ascii string to look for
	#   $s0 is the output buffer
	#
	#   $v0 is trashed

find_string:
	lw	$a2,16($gp)		# disk_buffer_addr
					# look in cpuinfo buffer
find_loop:
	lw	$v0,1($a2)		# load un-aligned 32 bits
	addiu   $a2,$a2,1		# increment pointer
	beqz	$v0,done		# are we at EOF?
					# if so, done

	li	$v1,':'			# can go in delay slot

	bne	$v0,$a0, find_loop	# do the strings match?
					# if not, loop

					# if we get this far, we matched


find_colon:
	lbu	$v0,1($a2)		# repeat till we find colon
	addiu	$a2,$a2,1

	beqz	$v0,done		# not found? then done

	xor	$v0,$v1
	bnez	$v0,find_colon


	addiu   $a2,$a2,2		# skip a char [should be space]

store_loop:
	lbu	$v0,0($a2)		# load value
	addiu	$a2,$a2,1		# increment

	beqz	$v0,done		# off end, then stop

	beq	$v0,$a3,done		# is it end char?

	sb	$v0,0($s0)		# if not store and continue
	addiu	$s0,$s0,1		# increment output pointer
	b	store_loop		# loop

done:
	jr	$31			# return

	#================================
	# strcat
	#================================
	# string to cat a1
	# output_buffer s0
	# trashed v0


strcat:
	lbu	$v0,0($a1)		# load byte from string
	addiu	$a1,$a1,1		# increment string
	sb  	$v0,0($s0)		# store byte to output_buffer
	addiu	$s0,$s0,1		# increment output_buffer
	bnez	$v0,strcat		# if zero, we are done

done_strcat:
	addiu	$s0,$s0,-1		# correct pointer
	jr	$31			# return

	#==============================
	# center_and_print
	#==============================
	# string is in output_buffer
        #

center_and_print:

	swm	$s0,$s1,$ra,0($sp)	# save return address

	li	$v0,0xa00		# append linefeed
	sh	$v0,0($s0)

	lw	$a1,0($gp)		# out_buffer_addr
					# a1 is beginning of string
					# s0 is end of string

	subu	$s1,$s0,$a1		# subtract end pointer from start
       		    			# to get length

	li	$v0,80

	slt	$v1,$s1,$v0		# set v1 if length less than 80

	sub	$s1,$v0,$s1		# subtract 80-length

	beqz	$v1,done_center		# don't center if > 80

	lw	$a1,12($gp)
	addiu	$a1,(escape-ver_string)
	jal	write_stdout		# print ESCAPE char

	srl	$a0,$s1,1		# divide by 2


	li    	$a3,0 			# print to stdout
	jals	num_to_ascii		# print number of spaces



	lw	$a1,12($gp)

	addiu	$a1,(c-ver_string)	# print "C"
	jal	write_stdout






done_center:
					# point to the string to print
	lw	$a1,0($gp)		# out_buffer_addr

	lwm	$s0,$s1,$ra,0($sp)
				# restore saved pointer
				# so we'll return to
				# where we were called from
				# at the end of the write_stdout


	#================================
	# WRITE_STDOUT
	#================================
	# a1 has the string


write_stdout:

	swm	$s0,$s1,$ra,16($sp)	# save return address

	move    $a0,$a1			# copy string pointer to $a0
	li      $a2,0			# 0 (count) in $a2

str_loop1:
	lbu	$v0,1($a0)		# load byte
	addiu	$a0,1
	addiu	$a2,1			# increment a2
	bnez	$v0,str_loop1		# if not nul, repeat

	li	$v0,SYSCALL_WRITE	# Write syscall in $v0
	li	$a0,STDOUT		# 1 in $a0 (stdout)

	syscall				# call syscall

	lwm	$s0,$s1,$ra,16($sp)	# restore return address

	jr	$ra			# retrun


	##############################
	# num_to_ascii
	##############################
	# a0 = value to print
	# a1 = output buffer
	# a3 = stdout(0) or strcat(1)
	# destroys v1
num_to_ascii:

	lw	$a1,ascii_buff_addr	# point to end of ascii_buffer

div_by_10:
	addiu	$a1,$a1,-1	# point back one
	li	$v1,10		# divide by 10
	divu	$a0,$v1		# divide.  hi= remainder, lo=quotient
	mfhi	$v1		# remainder into v1
	addiu	$v1,0x30	# convert to ascii
	sb	$v1,0($a1)	# store to buffer
	mflo	$a0		# move old result into next divide
	bnez	$a0, div_by_10

write_out:

	beqz	$a3,write_stdout
				# if write stdout, go there
	b	strcat		# else, strcat will return for us



#===========================================================================
#	section .data
#===========================================================================
.data
.align 4
data_begin:
out_buffer_addr:	.word out_buffer	# 0
text_buf_addr:		.word text_buf		# 4
uname_info_addr:	.word uname_info	# 8
ver_string_addr:	.word ver_string	# 12
disk_buffer_addr:	.word disk_buffer	# 16
sysinfo_buff_addr:	.word sysinfo_buff	# 20
ascii_buff_addr:	.word (ascii_buffer+10)	# 24


ver_string:		.ascii " Version \0\0\0"	# extra padding to x4
							# makes code genetation
							# better
compiled_string:	.ascii ", Compiled \0"
ram_comma:		.ascii "M RAM, \0"
bogo_total:		.ascii " Bogomips Total\0"
default_colors:		.ascii "\033[0m\n\0"
escape:			.ascii "\033[\0"
c:			.ascii "C\0"

cpuinfo:		.ascii "proc/cpu.mips\0"

one:			.ascii "One MIPS \0"
processor:		.ascii " Processor, \0"
odel_string:		.ascii "odel"
mips_string:		.ascii "MIPS"

.align 4
.include	"logo.lzss_new"
			.byte 0,0	# note, without this
					# the assembler puts
					# logo_end in a weird
					# place which messes up
					# the end of the logo decode


#============================================================================
#	section .bss
#============================================================================
.bss
.align 4
.lcomm	ascii_buffer,10		# 32 bit can't be > 9 chars
.lcomm	sysinfo_buff,128
.lcomm	uname_info,(65*6)
.lcomm	text_buf, (N+F-1)
.lcomm	disk_buffer,4096	# we cheat!!!!
.lcomm	out_buffer,16384

   # see /usr/src/linux/include/linux/kernel.h

