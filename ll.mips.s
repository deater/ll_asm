#
#  linux_logo in mips assembler 0.49
#
#  By
#       Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -o ll.o ll.mips.s"
#  link with         "ld -o ll ll.o"


# Optimization
# + 1277 bytes - historical
# + 1340 bytes - when assembled with gas 2.28
# + 1336 bytes - get rid of extraneous move
# + 1332 bytes - fill a branch delay slot
# + 1326 bytes - some optimizations of center_and_print
# + 1322 bytes - a few more optimizations

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

	la	$s0,data_begin		# point $s0 at .data segment begin
	la	$s1,bss_begin		# point s2 at .bss segment begin
	#addiu	$s1,$s0,(bss_begin-data_begin) won't work due to different segs

	li      $s2,(N-F)   	     	# R

	addiu  	$s3,$s0,(logo-data_begin)	# $s3 points to logo
	addiu	$s4,$s0,(logo_end-data_begin)	# $s4 points to end of logo
	addiu	$s5,$s1,(out_buffer-bss_begin)	# point $s5 to out_buffer

decompression_loop:

	lbu	$t1,0($s3)	# load in a byte
	ori 	$t1,$t1,0xff00	# put 0xff in top as a hackish 8-bit counter
	addiu	$s3,$s3,1	# increment source pointer

test_flags:
	beq	$s4, $s3, done_logo	# have we reached the end?
					# if so, exit
	# BRANCH DELAY SLOT
        andi	$t2,$t1,0x1		# test to see if discrete char


	bne	$t2,$0,discrete_char	# if set, we jump to discrete char

	# BRANCH DELAY SLOT
	srl	$t1,$t1,1		# shift


offset_length:
	lbu     $at,0($s3)	# load 16-bit length and match_position combo
	lbu	$t4,1($s3)	# can't use lhu because might be unaligned
	sll	$t4,$t4,8
	or	$t4,$t4,$at

	addiu	$s3,$s3,2	# increment source pointer

	srl	$t3,$t4,P_BITS	# get the top bits, which is length

	addiu	$t3,$t3,THRESHOLD+1
	      			# add in the threshold?

output_loop:
        andi 	$t4,$t4,(POSITION_MASK<<8+0xff)
					# get the position bits
	addiu	$t0,$s1,(text_buf-bss_begin)
	addu	$t0,$t0,$t4
	lbu	$t0,0($t0)		# load byte from text_buf[]
					# should have been able to do
					# in 2 not 3 instr
	addiu	$t4,$t4,1	    	# advance pointer in text_buf
store_byte:
        sb      $t0,0($s5)
	addiu	$s5,$s5,1      		# store byte to output buffer

	addiu	$t5,$s1,(text_buf-bss_begin)
	addu	$t5,$t5,$s2
	sb      $t0,0($t5)		# store also to text_buf[r]
	addi 	$s2,$s2,1        		# r++

	addiu	$t3,$t3,-1		# decrement count
	bne	$t3,$0,output_loop	# repeat until k>j
	#BRANCH DELAY SLOT
	andi 	$s2,$s2,(N-1)		# wrap r if we are too big

	andi	$at,$t1,0xff00		# if 0 we shifted through 8 and must
	bne	$at,$0,test_flags	# re-load flags
	# BRANCH DELAY SLOT
	nop

	j 	decompression_loop
	# BRANCH DELAY SLOT
	nop

discrete_char:
	lbu     $t0,0($s3)
	addiu	$s3,$s3,1		       	# load a byte
        j     store_byte		# and store it
	# BRANCH DELAY SLOT
	li   	$t3,1			# force a one-byte output

# end of LZSS code

done_logo:

        jal	write_stdout			# print the logo
	# BRANCH DELAY SLOT
	addiu	$a1,$s1,(out_buffer-bss_begin)	# point $a1 to out_buffer


first_line:
	#==========================
	# PRINT VERSION
	#==========================

	li	$v0, SYSCALL_UNAME		# uname syscall in $v0
	addiu	$a0, $s1,(uname_info-bss_begin)	# destination of uname in $a0
	syscall					# do syscall

	addiu	$s5,$s1,(out_buffer-bss_begin)	# point $s5 to out_buffer


					# os-name from uname "Linux"
	jal	strcat
	# BRANCH DELAY SLOT
	addiu	$a1,$s1,((uname_info-bss_begin)+U_SYSNAME)


					# source is " Version "
       	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
	addiu	$a1,$s0,(ver_string-data_begin)


					# version from uname, ie "2.6.20"
	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
	addiu	$a1,$s1,((uname_info-bss_begin)+U_RELEASE)

					# source is ", Compiled "
	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
	addiu	$a1,$s0,(compiled_string-data_begin)

					# compiled date
	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
	addiu	$a1,$s1,((uname_info-bss_begin)+U_VERSION)

	jal	center_and_print	# center and print
	# BRANCH DELAY SLOT
	nop

	#===============================
	# Middle-Line
	#===============================
middle_line:

	addiu	$s5,$s1,(out_buffer-bss_begin)
					# point $s5 to out_buffer

	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	li	$v0, SYSCALL_OPEN	# OPEN Syscall

	addiu	$a0,$s0,(cpuinfo-data_begin)
					# '/proc/cpuinfo'
	li	$a1, 0			# 0 = O_RDONLY <bits/fcntl.h>

	syscall				# syscall.  fd in v0
					# we should check that
					# return v0>=0

	move	$a0,$v0			# copy $v0 (the result) to $a0

	li	$v0, SYSCALL_READ	# read()

	addiu	$a1, $s1,(disk_buffer-bss_begin)
					# point $a1 to the buffer

	li	$a2, 4096		# 4096 is maximum size of proc file ;)
					# we load sneakily by knowing
	syscall

	li	$v0, SYSCALL_CLOSE	# close (to be correct)
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
	addiu	$a1,$s0,(one-data_begin)		# print "One"


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
   	li	$a0,('l'<<24+'e'<<16+'d'<<8+'o')
.else
   	li	$a0,('o'<<24+'d'<<16+'e'<<8+'l')
.endif
					# find 'odel\t: ' and grab up to ' '

	jal	find_string
	# BRANCH DELAY SLOT
	li	$a2,' '

					# print "Processor, "
	jal	strcat
	# BRANCH DELAY SLOT
	addiu	$a1,$s0,(processor-data_begin)

	#========
	# RAM
	#========

	li	$v0, SYSCALL_SYSINFO	# sysinfo() syscall
	addiu	$a0, $s1,(sysinfo_buff-bss_begin)
	syscall

	lw	$a0, S_TOTALRAM($a0)	# size in bytes of RAM
	# LOAD DELAY SLOT
	li	$s3,1			# print to strcat, not stderr

	jal     num_to_ascii
	# BRANCH DELAY SLOT
	srl	$a0,$a0,20		# divide by 1024*1024 to get M


					# print 'M RAM, '
	jal	strcat			# call strcat
	# BRANCH_DELAY_SLOT
	addiu	$a1,$s0,(ram_comma-data_begin)


	#========
	# Bogomips
	#========

.ifdef LITTLE_ENDIAN
	li	$a0, ('S'<<24+'P'<<16+'I'<<8+'M')
.else
	li	$a0, ('M'<<24+'I'<<16+'P'<<8+'S')
.endif
					# find 'mips\t: ' and grab up to \n

	jal	find_string
	# BRANCH DELAY SLOT
	li	$a2, 0xa

					# bogo total follows RAM
	jal 	strcat			# call strcat
	# BRANCH DELAY SLOT
	addiu	$a1,$s0,(bogo_total-data_begin)


	jal	center_and_print	# center and print
	# BRANCH DELAY SLOT
	nop

	#=================================
	# Print Host Name
	#=================================

	addiu	$s5,$s1,(out_buffer-bss_begin)
					# point $s5 to out_buffer


					# host name from uname()
	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
	addiu	$a1,$s1,(uname_info-bss_begin)+U_NODENAME

	jal	center_and_print	# center and print
	# BRANCH DELAY SLOT
	nop
					# (.txt) pointer to default_colors
	jal	write_stdout
	# BRANCH DELAY SLOT
	addiu	$a1,$s0,(default_colors-data_begin)


	#================================
	# Exit
	#================================
exit:
     	li	$v0, SYSCALL_EXIT	# put exit syscall in v0
	li	$a0, 0			# put exit code in a0
        syscall	    			# exit


	#=================================
	# FIND_STRING
	#=================================
	#   $a2 (a2) is char to end at
	#   $a0 (a0) is 4-char ascii string to look for
	#   $s0 (s1) is the output buffer

	#   $a1 is destroyed
	#   $t3 (t3) is destroyed

find_string:
	addiu	$a1, $s1,(disk_buffer-bss_begin)-1
					# look in cpuinfo buffer
find_loop:

	ulw	$t3,1($a1)		# load un-aligned 32 bits
	beq	$t3,$0,done		# are we at EOF?
					# if so, done
	# BRANCH DELAY SLOT
	addiu   $a1,$a1,1		        # increment pointer


	bne	$a0,$t3, find_loop	# do the strings match?
					# if not, loop

					# if we get this far, we matched
	# BRANCH DELAY SLOT
	nop

find_colon:
	lbu	$t3,1($a1)		# repeat till we find colon
	# LOAD DELAY SLOT
	addiu	$a1,$a1,1
	beq	$t3,$0,done		# not found? then done
	# BRANCH DELAY SLOT
	nop

	bne	$t3,$at,find_colon
	# BRANCH DELAY SLOT
	li	$at,':'

	addiu   $a1,$a1,2			# skip a char [should be space]

store_loop:
	lbu	$t3,0($a1)		# load value
	# LOAD DELAY SLOT
	addiu	$a1,$a1,1			# increment
	beq	$t3,$0,done		# off end, then stop
	# BRANCH DELAY SLOT
	nop

	beq	$t3,$a2,done      	# is it end char?
	# BRANCH DELAY SLOT
	nop				# if so, finish

	sb	$t3,0($s5)		# if not store and continue
	j	store_loop		# loop
	# BRANCH DELAY SLOT
	addiu	$s5,$s5,1		# increment output pointer

done:
	jr	$ra			# return
	# BRANCH DELAY SLOT
#	nop
#	allow harmless next instruction

	#==============================
	# center_and_print
	#==============================
	# string is in output_buffer
	# $s5 = end of string
	# $s3 = stdout or strcat
        # $s4, $t6, trashed

center_and_print:

	move	$t6,$ra			# save return address

	li	$at,0xa00
	sh	$at,0($s5)		# put linefeed/nul on end

	addiu	$s4,$s1,(out_buffer-bss_begin)	# point $s4 to beginning

	subu	$a0,$s5,$s4		# subtract end pointer from start
       		    			# (get size of string)

	slti    $at,$a0,80
	beq	$at,$0, done_center	# don't center if > 80
	# BRANCH DELAY SLOT
	li    	$s3,0			# print to stdout

	neg	$a0,$a0			# negate length
	addiu	$a0,$a0,80		# add to 80

	srl	$s6,$a0,1		# divide by 2

	jal	write_stdout		# print ESCAPE char
	# BRANCH DELAY SLOT
	addiu	$a1,$s0,(escape-data_begin)


	jal	num_to_ascii		# print number of spaces
	# BRANCH DELAY SLOT
	move	$a0,$s6			# how much to shift to right

	jal	write_stdout
	# BRANCH DELAY SLOT
	addiu	$a1,$s0,(c-data_begin)	# print "C"


done_center:

	addiu	$a1,$s1,(out_buffer-bss_begin)
					# point to the string to print


	move 	$ra,$t6 		# restore saved pointer
	     				# so we'll return to
					# where we were called from
					# at the end of the write_stdout

	#================================
	# WRITE_STDOUT
	#================================
	# $a1 (a1) has string
	# $t8,$t9 (t8,t9) destroyed


write_stdout:
	li      $v0, SYSCALL_WRITE       # Write syscall in $v0
	li	$a0, STDOUT		# 1 in $a0 (stdout)

	li	$a2, 0			# 0 (count) in $a2

	move	$t9,$a1			# copy string to $t9

str_loop1:
	lbu	$t8,1($t9)		# load byte at (t9)
	addi	$t9,$t9,1		# LOAD DELAY SLOT
	bnez	$t8,str_loop1		# if not nul, repeat
	# BRANCH DELAY SLOT
	addi	$a2,$a2,1		# increment a2
	syscall  			# run the syscall

	jr	$ra 			# return
	# BRANCH DELAY SLOT
	nop

	#=============================
	# num_to_ascii
	#=============================
	# a0 = value to print
	# a1 = output buffer
	# s3 = 0=stdout, 1=strcat
	# destroys t2 ($t1)
	# destroys t3 ($t3)
	# destroys a0 ($a0)

num_to_ascii:

	addiu	 $a1,(ascii_buffer-bss_begin)+10
				# point to end of ascii_buffer

div_by_10:
	addiu	$a1,$a1,-1	# point back one
	li	$at,10
	divu	$a0,$a0,$at	# divide.  hi= remainder, lo=quotient
	mfhi	$t3		# remainder into t3 ($t3)
	addiu	$t3,$t3,0x30	# convert to ascii
	bne	$a0,$0, div_by_10
	# BRANCH DELAY SLOT
	sb	$t3,0($a1)	# store to buffer


write_out:
	beq	$s3,$0,write_stdout
	# BRANCH DELAY SLOT
	nop			# if write stdout, go there

				# fall through to strcat

	#================================
	# strcat
	#================================
	# output_buffer_offset = $s5
	# string to cat = $a1
	# destroys t0 ($s2)

strcat:
	lbu 	$s2,0($a1)		# load byte from string
	# LOAD DELAY SLOT
	addiu	$a1,$a1,1		# increment string
	sb  	$s2,0($s5)		# store byte to output_buffer

	bne 	$s2,$0,strcat		# if zero, we are done
	# BRANCH DELAY SLOT
	addiu	$s5,$s5,1		# increment output_buffer

done_strcat:
	jr	$ra			# return
	# BRANCH DELAY SLOT
	addiu	$s5,$s5,-1		# correct pointer




#===========================================================================
#	section .data
#===========================================================================
#.data

data_begin:
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"
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
