#
#  linux_logo in mips16 assembler 0.46
#
#  By
#       Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -mips16 -o ll.mips16.o ll.mips16.s"
#  link with         "ld -o ll_mips16 ll.mips16.o"

.include "logo.include"

#
# MIPS16 differences from MIPS
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
# + stack frame
#   * restore ra,s0,s1,framesize - optinally copy ra,s0,s1 off stack
#                                  then update stack with 4-bit imm
#     extended version can also restore other registers
#   * save is like restore, but in reverse
# + ALU
#   * addiu rx, imm : rx=rx+8-bit immediate  (extensible to 16-bit)
#   * addiu ry, rx, imm : ry=rx+4-bit immediate (extensible to 15 bit)
#   * addiu rx,pc, imm : generate pc relative address (8bit extend to 16bit)
#   * addiu sp, imm    : adjust stack pointer (8bit extnd to 16bit)
#   * addiu rx,sp, imm    : generate sp relative address (8bit extnd to 16bit)
#   * addu rz,rx,ry    : rz = rx + ry
#   * and  rx,ry       : rx = rx & ry
#   * cmp  rx,ry       : T = rx ^ ry
#   * cmpi rx,imm      : T = rx ^ zero-extend 8-bit imm (extnd to 16bit)
#   * li rx,imm        : 8-bit, extnd to 16-bit
#   * move r32,rz      : can be any of the 32 MIPS regs
#   * neg rx,ry        : rx = 0-ry
#   * not rx,ry        : rx = ~ry
#   * or  rx,ry        : rx = rx | ry
#   * seb/seh/sew      : sign extend
#   * slt rx,ry        : T = (rx < ry)
#   * slti rx,imm      : T = (rx < imm) 8-bit, extend to 16-bit
#   * sltu/slti/sltiu  : like above
#   * subu rz,rx,ry    : rx = rx - ry
#   * xor rx,ry        : rx = rx ^ ry
#   * zeb/zeh/zew      : zero extend
#   * daddiu, etc for 64-bit
# + special           : break/extend
# + mul/div           : ddiv/ddivu/div/divu/dmult/dmultu/mfhi/mflo/mult/multu
#   * results in hi/lo like regular MIPS
# + branch            : b/beqz/bnez/bteqz/btnez/jal/jalr/jalrc/jalx/jr/jrc
#   * the "T" version checks the special T register (set by cmp)
#   * jal jumps with 16-bit offset, result in r31
#   * jalrc has no delay slot
#   * jalx changes from 16-bit to 32-bit mode
# + shift (64)        : dsll/dsllv/dsra/dsrav/dsrl/dsrlv
# + shift (32)
#   * sll rx,ry,sa    : rx = ry << sa (8-bits, extend to 31)
#   * sllv ry,rx      : ry = ry << rx
#   * sra rx,ry,sa    : rx = ry >> sa (8-bits extend to 31)
#   * srav
#   * srl
#   * srlv

# PC relative instructions: lwd,ld,addiu,daddiu

# "Extended" instructions allow making immediate field larger,
#    for a 32-bit instruction
#    cannot be in branch delay slots

#
# Keep gas from handling branch-delay and load-delay slots automatically
#

#.set noreorder

#
# Keep gas from using the assembly temp register (no pseudo-ops basically)
#

#.set noat

#
# Register definitions.  Why does't gas know these?
#

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

	jal	start16		# I don't think this should
				# be necessary, how do I create
				# a native mips16 binary?

.set mips16

start16:

	#=========================
	# PRINT LOGO
	#=========================

# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver

#	la	$17,data_begin		# point $17 at .data segment begin
#	la	$18,bss_begin		# point $18 at .bss segment begin

	li      $6,(N-F)   	     	# R

#	addiu  	$9,$17,(logo-data_begin)	# $9 points to logo
#	addiu	$12,$17,(logo_end-data_begin)	# $12 points to end of logo
#	addiu	$16,$18,(out_buffer-bss_begin)	# point $16 to out_buffer

#	la	$16,blah_buffer

        la      $16,out_buffer
	la      $17,logo


decompression_loop:

	lbu	$2,0($17)       # load in a byte
	addiu	$17,$17,1	# increment source pointer

        move 	$3, $2	        # move in the flags
	li      $7,0xff00	# 32-bit, zero extended
	or 	$3,$7           # put 0xff in top as a hackish 8-bit counter

test_flags:
        la      $7, logo_end

	slt	$17, $7
	bteqz	done_logo

#	beq	$7, $17, done_logo	# have we reached the end?
					# if so, exit

        li      $7,1
        and     $7,$3	                # test to see if discrete char

	srl	$3,$3,1  	        # shift	

	bnez	$7,discrete_char	# if set, we jump to discrete char
	
offset_length:
	lbu     $2,0($17)	# load 16-bit length and match_position combo
	lbu	$4,1($17)	# can't use lhu because might be unaligned

	addiu	$17,2           # increment source pointer	

	sll	$4,8
	or	$4,$2           # $4 now has 16-bit value
	
	srl $5,$4,P_BITS	# get the top bits, which is length
	
	addiu $5,$5,THRESHOLD+1 
	      			# add in the threshold?

		
output_loop:
        li      $7,(POSITION_MASK<<8+0xff)
        and 	$4,$7
					# get the position bits


        la      $7,text_buf
	addu	$7,$4
	lbu	$2,0($7)		# load byte from text_buf[]
					# should have been able to do
					# in 2 not 3 instr



	addiu	$4,$4,1	    	# advance pointer in text_buf

store_byte:
        sb      $2,0($16)
	addiu	$16,1      		# store byte to output buffer

        la      $7,text_buf

	addu	$7,$6

#	jalx	dump_registers
#	nop

	sb      $2, 0($7)		# store also to text_buf[r]
	addiu 	$6,$6,1        		# r++

	li      $7,(N-1)
	and 	$6,$7		        # wrap r if we are too big	

	addiu	$5,$5,-1		# decrement count

	bnez	$5,output_loop	        # repeat until k>j



	sltiu	$3,0x100		# if 0 we shifted through 8 and must
	bteqz	test_flags	        # re-load flags
	
	b 	decompression_loop


discrete_char:
	lbu     $2,0($17)
	addiu	$17,1		        # load a byte
	li   	$5,1			# force a one-byte output	
	b	store_byte		# and store it

# end of LZSS code

done_logo:
	la	$5,out_buffer	                # point $5 to out_buffer
        jal	write_stdout			# print the logo

first_line:	
	#==========================
	# PRINT VERSION
	#==========================

#	li	$2, SYSCALL_UNAME		# uname syscall in $2
#	addiu	$4, $18,(uname_info-bss_begin)	# destination of uname in $4
#	syscall					# do syscall

#	addiu	$16,$18,(out_buffer-bss_begin)	# point $16 to out_buffer
		

					# os-name from uname "Linux"
#	jal	strcat
	# BRANCH DELAY SLOT
#	addiu	$5,$18,((uname_info-bss_begin)+U_SYSNAME)	


					# source is " Version "	
 #      	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
#	addiu	$5,$17,(ver_string-data_begin)


					# version from uname, ie "2.6.20"
#	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
#	addiu	$5,$18,((uname_info-bss_begin)+U_RELEASE)



					# source is ", Compiled "
#	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
#	addiu	$5,$17,(compiled_string-data_begin)
	     

					# compiled date
#	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
#	addiu	$5,$18,((uname_info-bss_begin)+U_VERSION)	

#	jal	center_and_print	# center and print
#	nop				# branch delay
 	
	#===============================
	# Middle-Line
	#===============================
middle_line:
	
#	addiu	$16,$18,(out_buffer-bss_begin)	# point $16 to out_buffer
	
	#=========
	# Load /proc/cpuinfo into buffer
	#=========

#	li	$2, SYSCALL_OPEN	# OPEN Syscall
	
#	addiu	$4,$17,(cpuinfo-data_begin)
					# '/proc/cpuinfo'
#	li	$5, 0			# 0 = O_RDONLY <bits/fcntl.h>

#	syscall				# syscall.  fd in v0  
					# we should check that 
					# return v0>=0
						
#	move	$4,$2			# copy $2 (the result) to $4
	
#	li	$2, SYSCALL_READ	# read()
	
#	addiu	$5, $18,(disk_buffer-bss_begin)
					# point $5 to the buffer

#	li	$6, 4096		# 4096 is maximum size of proc file ;) 
					# we load sneakily by knowing
#	syscall

#	li	$2, SYSCALL_CLOSE	# close (to be correct)
		    			# fd should still be in a0
#	syscall

	#=============
	# Number of CPUs
	#=============
number_of_cpus:

	# we cheat here and just assume 1.  
	# besides, I don't have a SMP Mips machine to test on

#	jal	strcat
	# BRANCH DELAY SLOT
#	addiu	$5,$17,(one-data_begin)		# print "One"	


	#=========
	# MHz
	#=========
print_mhz:

	# Mips /proc/cpuinfo does not indicate MHz


   	#=========
	# Chip Name
	#=========
chip_name:	
#   	li	$4,('o'<<24+'d'<<16+'e'<<8+'l')     	
					# find 'odel\t: ' and grab up to ' '

#	jal	find_string
	# BRANCH DELAY SLOT
#	li	$6,' '	
	
					# printf "Processor, "
#	jal	strcat
	# BRANCH DELAY SLOT
#	addiu	$5,$17,(processor-data_begin)
	
	#========
	# RAM
	#========
	
#	li	$2, SYSCALL_SYSINFO	# sysinfo() syscall
#	addiu	$4, $18,(sysinfo_buff-bss_begin)
#	syscall
	
#	lw	$4, S_TOTALRAM($4)	# size in bytes of RAM
	# LOAD DELAY SLOT
#	li	$19,1			# print to strcat, not stderr
			
#	jal     num_to_ascii
	# BRANCH DELAY SLOT
#	srl	$4,$4,20		# divide by 1024*1024 to get M

	
					# print 'M RAM, '
#	jal	strcat			# call strcat
#	addiu	$5,$17,(ram_comma-data_begin)

	

	#========
	# Bogomips
	#========
	
#	li	$4, ('M'<<24+'I'<<16+'P'<<8+'S')      	
					# find 'mips\t: ' and grab up to \n

#	jal	find_string
	# BRANCH DELAY SLOT
#	li	$6, 0xa	

	
					# bogo total follows RAM 
#	jal 	strcat			# call strcat
	# BRANCH DELAY SLOT
#	addiu	$5,$17,(bogo_total-data_begin)


#	jal	center_and_print	# center and print
#	nop
	
	#=================================
	# Print Host Name
	#=================================

#	addiu	$16,$18,(out_buffer-bss_begin)  
					# point $16 to out_buffer


					# host name from uname()
#	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
#	addiu	$5,$18,(uname_info-bss_begin)+U_NODENAME    	
	
#	jal	center_and_print	# center and print
	# BRANCH DELAY SLOT
#	nop
	
					# (.txt) pointer to default_colors
#	jal	write_stdout
	# BRANCH DELAY SLOT
#	addiu	$5,$17,(default_colors-data_begin)	
	

	#================================
	# Exit
	#================================
#        lw      $5, hello_addr

#        jal     write_stdout

exit:
     	li	$2, SYSCALL_EXIT	# put exit syscall in v0
	li	$4, 5			# put exit code in a0

	jalx    do_syscall



.set nomips16
.align 2

        #===================
	# syscall
	#===================
do_syscall:	
        syscall	    			# 

	jr    $31


	#===================
	# dump registers
	#===================
dump_registers:

	move	$18,$2
	move	$19,$3
	move	$20,$4
	move	$21,$5
	move	$22,$6

	la	$8,register_buffer
	
	sw	$0,0($8)
.set noat
	sw	$1,4($8)
.set at
	sw	$2,8($8)
	sw	$3,12($8)
	sw	$4,16($8)
	sw	$5,20($8)
	sw	$6,24($8)
	sw	$7,28($8)
	sw	$8,32($8)
	sw	$9,36($8)
	sw	$10,40($8)
	sw	$11,44($8)
	sw	$12,48($8)
	sw	$13,52($8)
	sw	$14,56($8)
	sw	$15,60($8)
	sw	$16,64($8)
	sw	$17,68($8)
	sw	$18,72($8)
	sw	$19,76($8)
	sw	$20,80($8)
	sw	$21,84($8)
	sw	$22,88($8)
	sw	$23,92($8)
	sw	$24,96($8)
	sw	$25,100($8)
	sw	$26,104($8)
	sw	$27,108($8)
	sw	$28,112($8)
	sw	$29,116($8)
	sw	$30,120($8)
	sw	$21,124($8)

	li	$2,	SYSCALL_WRITE
	li	$4,2			# stderr
	la	$5,register_buffer
	li	$6,128
	syscall

	li	$2, SYSCALL_SYNC
	syscall

	move	$2,$18
	move	$3,$19
	move	$4,$20
	move	$5,$21
	move	$6,$22


	jr      $31
	
.set mips16
.align 1
	#=================================
	# FIND_STRING 
	#=================================
	#   $6 (a2) is char to end at
	#   $4 (a0) is 4-char ascii string to look for
	#   $17 (s1) is the output buffer
	
	#   $5 is destroyed
	#   $11 (t3) is destroyed

find_string:					
#	addiu	$5, $18,(disk_buffer-bss_begin)-1	
					# look in cpuinfo buffer
find_loop:

#	ulw	$11,1($5)		# load un-aligned 32 bits
#	beq	$11,$0,done		# are we at EOF?
					# if so, done
	# BRANCH DELAY SLOT
#	addiu   $5,$5,1		        # increment pointer

	
#	bne	$4,$11, find_loop	# do the strings match?
					# if not, loop
	
					# if we get this far, we matched
	# BRANCH DELAY SLOT
#	nop
	
find_colon:
#	lbu	$11,1($5)		# repeat till we find colon
	# LOAD DELAY SLOT
#	addiu	$5,$5,1
#	beq	$11,$0,done		# not found? then done
	# BRANCH DELAY SLOT
#	nop
	
#	li	$1,':'
#	bne	$11,$1,find_colon
	# BRANCH DELAY SLOT
#	nop

#	addiu   $5,$5,2			# skip a char [should be space]
	
store_loop:	 
#	lbu	$11,0($5)		# load value
	# LOAD DELAY SLOT
#	addiu	$5,$5,1			# increment
#	beq	$11,$0,done		# off end, then stop
	# BRANCH DELAY SLOT
#	nop
	
#	beq	$11,$6,done      	# is it end char?
	# BRANCH DELAY SLOT
#	nop				# if so, finish
	
#	sb	$11,0($16)		# if not store and continue
#	j	store_loop		# loop
	# BRANCH DELAY SLOT
#	addiu	$16,$16,1		# increment output pointer

done:
#	jr	$31			# return
	# BRANCH DELAY SLOT
#	nop

	#================================
	# strcat
	#================================
	# output_buffer_offset = $16 (s0)
	# string to cat = $5         (a1)
	# destroys t0 ($8)

strcat:
#	lbu 	$8,0($5)		# load byte from string
	# LOAD DELAY SLOT	
#	addiu	$5,$5,1			# increment string	
#	sb  	$8,0($16)		# store byte to output_buffer

#	bne 	$8,$0,strcat		# if zero, we are done
	# BRANCH DELAY SLOT
#	addiu	$16,$16,1		# increment output_buffer

done_strcat:
#	jr	$31			# return
	# BRANCH DELAY SLOT
#	addiu	$16,$16,-1		# correct pointer	


	#==============================
	# center_and_print
	#==============================
	# string is in $16 (s0) output_buffer
	# s3 $19= stdout or strcat
        # $20, $21, $22 trashed
       
center_and_print:

#	move	$21,$31				# save return address
#	move	$20,$16				# $20 is the end of our string
#	addiu	$16,$18,(out_buffer-bss_begin)	# point $16 to beginning 
	

#	subu	$4, $20,$16		# subtract end pointer from start
       		    			# (cheaty way to get size of string)

#	slti	$1,$4,81
#	beq	$1,$0, done_center	# don't center if > 80
	# BRANCH DELAY SLOT
#	li    	$19,0 			# print to stdout	

#	neg	$4,$4  			# negate length
#	addiu	$4,$4,80		# add to 80 

#	srl	$22,$4,1		# divide by 2 

#	jal	write_stdout		# print ESCAPE char
	# BRANCH DELAY SLOT
#	addiu	$5,$17,(escape-data_begin)


#	jal	num_to_ascii		# print number of spaces
	# BRANCH DELAY SLOT
#	move	$4,$22			# how much to shift to right

#	jal	write_stdout
	# BRANCH DELAY SLOT
#	addiu	$5,$17,(c-data_begin)	# print "C"


done_center:
					# point to the string to print
#	jal 	write_stdout
	# BRANCH DELAY SLOT
#	addiu	$5,$18,(out_buffer-bss_begin)


#	addiu	$5,$17,(linefeed-data_begin)
					# print linefeed at end of line
	
#	move 	$31,$21 		# restore saved pointer
	     				# so we'll return to
					# where we were called from 
					# at the end of the write_stdout
	
	#================================
	# WRITE_STDOUT
	#================================
	# $5 (a1) has string
	

write_stdout:
	
        save    $31,8

        move    $4, $5                   # copy string pointer to $4
	li      $6, 0                   # 0 (count) in $6

str_loop1:
	lbu	$2,1($4)		# load byte at (4)
	addiu	$4,1		
	addiu	$6,1			# increment a2	
	bnez	$2,str_loop1		# if not nul, repeat

	li      $2, SYSCALL_WRITE       # Write syscall in $2
	li	$4, STDOUT		# 1 in $4 (stdout)	

	jalx 	do_syscall

	restore $31,8

	jr      $31


	##############################
	# num_to_ascii
	##############################	
	# a0 ($4)  = value to print
	# a1 ($5)  = output buffer	
	# s3 ($19) = 0=stdout, 1=strcat
	# destroys t2 ($10)
	# destroys t3 ($11)
	# destroys a0 ($4)
	
num_to_ascii:

#	addiu	 $5,(ascii_buffer-bss_begin)+10	
				# point to end of ascii_buffer

div_by_10:
#	addiu	$5,$5,-1	# point back one
#	li	$1,10
#	divu	$10,$4,$1	# divide.  hi= remainder, lo=quotient
#	mfhi	$11		# remainder into t3 ($11)
#	addiu	$11,$11,0x30	# convert to ascii
#	sb	$11,0($5)	# store to buffer
#	bne	$10,$0, div_by_10
#	# BRANCH DELAY SLOT
#	move	$4,$10		# move old result into next divide	
	
write_out:
#	beq	$19,$0,write_stdout
#	nop			# if write stdout, go there 
 #   	j	strcat		# else, strcat will return for us
#	nop

#===========================================================================
#	section .data
#===========================================================================

data_begin:	
hello_addr:      .int hello
hello:          .ascii "Hello\n\0"
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"
linefeed:	.ascii  "\n\0"
default_colors:	.ascii "\033[0m\n\n\0"
escape:		.ascii "\033[\0"
c:		.ascii "C\0"

cpuinfo:	.ascii	"/proc/cpuinfo\0"

one:	.ascii	"One Mips \0"
processor:	.ascii " Processor, \0"

.include	"logo.lzss_new"

#============================================================================
#	section .bss
#============================================================================
.bss

bss_start:

.lcomm blah_buffer,1024		# UGH!  There is some sort
				# of bug in the assembler
				# that points the first bss entry
				# to __start for some reason.
				# That took a while to debug.
				# Thank goodness for objdump

.lcomm  text_buf, (N+F-1)

.lcomm	out_buffer,16384

.lcomm	disk_buffer,4096	# we cheat!!!!

.lcomm  ascii_buffer,10		# 32 bit can't be > 9 chars

   # see /usr/src/linux/include/linux/kernel.h
.lcomm sysinfo_buff,(64)
.lcomm uname_info,(65*6)

.lcomm register_buffer,128
