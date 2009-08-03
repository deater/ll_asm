#
#  linux_logo in microblaze assembler 0.37
#
#  By 
#       Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -o ll.o ll.microblaze.s"
#  link with         "ld -o ll ll.o"
#
#  I have to cross-compile, so what I do is was more like
#      make CROSS=/usr/local/bin/mb- ARCH=microblaze


#
# I use qemu for simulating this code (I have no microblaze hardware)
#

# Architectural Info

# Big-endian
# 3-operand
# 32 32-bit registers
#  r0 is a zero register
#  r1 is stack pointer
#  r2 = r/o small data area
#  r3,r4 = return value
#  r5-r10 = parameters
#  r11-r12 = temp vars
#  r13 = r/w small data area
#  r14 = return address for interrupt
#  r15 = return area for functions
#  r16 = return address for debug/breaks
#  r17 = exception return address
#  r18 = reserved for compiler

# has (optional) branch-delay slots
# aligned memory accesses (can be configured otherwise v3.0 and later)



#  HW multiply (post Virtex-II)

# System Calls
#   syscall number in r12
#   params in r5-r?
# brki r14, 0x08 
# nop   

# instruction set
#  32-bit wide instructions
#  16-bit immediates
#  usually add rd,ra,rb (rd=destination)
#   add, addc, addk, addkc  [carry, keep carry means don't update carry]
#   addi, addic, addik, addikc [add immediate]
#   and, andi, andn, andni [and, and not]
#   beq, beqd, beqi, beqid [branch if equal, with delay, immediate]
#   bge, bged, bgei, bgeid [branch if greater or equal]
#   bgt, bgtd, bgti, bgtid [branch if greater than]
#   ble, bled, blei, bleid [branch if less or equal]
#   blt, bltd, blti, bltid [branh if less than]
#   bne, bned, bnei, bneid [branch if not equal]
#   br, bra, brd, brad, brld, bald [unconditional branch.  l = and link]
#   bri, brai, brid, braid, brlid, bralid [unconditional branch immediate]
#   brk, brki  [break]
#   bsrl, bsra, bsll [barrel shift right logical, right arith, left logic]
#   bsrli, bsrai, bslli [barrel shift immediate]
#   cmp, cmpu [compare]
#   get, nget, cget, ncget [read from interface]
#   idiv, idivu [divide.  only valid if config'd for divider]
#   imm [load 16-bit immediate value to be used to make 32-bit immediate]
#   lbu, lbui [load byte unsigned]
#   lhu, lhui [load halfword unsigned]
#   lw, lwi [load word]
#   mfs, msrclr, msrset, mts  [manipulate special reg]
#   mul, muli [multiply, if configured]
#   or, ori [ or ]
#   put, nput, cput, ncput [write to interface]
#   rsub, rsubc, rsubk, rsubkc [reverse subtract]
#   rsubi, rsubic, rsubik, subikc [reverse subtract immediate]
#   rtbd, rtid, rted [ return from break, interrupt, exception]
#   rtsd [return from subroutine.  always has delay slot]
#   sb,sbi [store byte]
#   sext16, sext8 [sign extend]
#   sh, shi [store halfword]
#   sra, src, srl [shift right, arith, with carry, logical]
#   sw, swi [store word]
#   wdc, wic [write to data, instruction cache]
#   xor, xori [xor]




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
.equ SYSCALL_OPEN,	5    # openat?
.equ SYSCALL_CLOSE,	6
.equ SYSCALL_SYSINFO,	116
.equ SYSCALL_UNAME,	122

#
.equ STDIN,0
.equ STDOUT,1
.equ STDERR,2

	.globl _start	
_start:	
	#=========================
	# PRINT LOGO
	#=========================

	bri test
	nop
	
# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver

	#addi	r19,r0,data_begin	# point r19 at .data segment begin
	#addi	r20,r0,bss_begin	# point r20 at .bss segment begin

	#addi    r8,r0,(N-F)   	     	# R
		
	#addi  	r9,r0,logo		# r9 points to logo 
	#addi	r12,r0,logo_end		# r12 points to end of logo
	#addi	r21,r0,out_buffer	# point r21 to out_buffer

decompression_loop:

	#lbu	r10,r0,r9       # load in a byte
	#addi	r9,r9,1		# increment source pointer

#	move 	$11, $10	# move in the flags
#	ori 	$11,$11,0xff00  # put 0xff in top as a hackish 8-bit counter

test_flags:
	#cmp	r18, r12, r9
	#beqi	r18, done_logo	# have we reached the end?
				# if so, exit

#        andi	$13,$11,0x1	# test to see if discrete char


#	bne	$13,$0,discrete_char	# if set, we jump to discrete char
	
	# BRANCH DELAY SLOT
#	srl	$11,$11,1  	# shift	


offset_length:
#	lbu     $10,0(r9)	# load 16-bit length and match_position combo
#	lbu	$24,1(r9)	# can't use lhu because might be unaligned
#	addiu	r9,r9,2	 	# increment source pointer	
#	sll	$24,$24,8
#	or	$24,$24,$10
	

	
#	srl $15,$24,P_BITS	# get the top bits, which is length
	
#	addiu $15,$15,THRESHOLD+1 
	      			# add in the threshold?
		
output_loop:
 #       andi 	$24,$24,(POSITION_MASK<<8+0xff)  	
					# get the position bits
#	addiu	$10,r20,(text_buf-bss_begin)
#	addu	$10,$10,$24
#	lbu	$10,0($10)		# load byte from text_buf[]
					# should have been able to do
					# in 2 not 3 instr
#	addiu	$24,$24,1	    	# advance pointer in text_buf
store_byte:	
 #       sb      $10,0(r21)
#	addiu	r21,r21,1      		# store byte to output buffer

#	addiu	$1,r20,(text_buf-bss_begin)
##	addu	$1,$1,r8	
#	sb      $10, 0($1)		# store also to text_buf[r]
#	addi 	r8,r8,1        		# r++


#	addiu	$15,$15,-1		# decrement count
#	bne	$15,$0,output_loop	# repeat until k>j
	#BRANCH DELAY SLOT
#	andi 	r8,r8,(N-1)		# wrap r if we are too big

#	andi	$13,$11,0xff00		# if 0 we shifted through 8 and must
#	bne	$13,$0,test_flags	# re-load flags
	# BRANCH DELAY SLOT
#	nop
	
#	j 	decompression_loop
#	# BRANCH DELAY SLOT
#	nop

discrete_char:
#	lbu     $10,0(r9)
#	addiu	r9,r9,1		       	# load a byte
 #       j     store_byte		# and store it
#	# BRANCH DELAY SLOT
#	li   	$15,1			# force a one-byte output

# end of LZSS code

done_logo:
	#addi	r5,r0,out_buffer		# point r5 to out_buffer

        #brlid	r15,write_stdout		# print the logo
	# BRANCH DELAY SLOT
	#nop
	



first_line:	
	#==========================
	# PRINT VERSION
	#==========================

#	li	$2, SYSCALL_UNAME		# uname syscall in $2
#	addiu	$4, r20,(uname_info-bss_begin)	# destination of uname in $4
#	syscall					# do syscall

#	addiu	r21,r20,(out_buffer-bss_begin)	# point r21 to out_buffer
		

					# os-name from uname "Linux"
#	jal	strcat
	# BRANCH DELAY SLOT
#	addiu	$5,r20,((uname_info-bss_begin)+U_SYSNAME)	


					# source is " Version "	
 #      	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
#	addiu	$5,r19,(ver_string-data_begin)


					# version from uname, ie "2.6.20"
#	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
#	addiu	$5,r20,((uname_info-bss_begin)+U_RELEASE)



					# source is ", Compiled "
#	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
#	addiu	$5,r19,(compiled_string-data_begin)
	     

					# compiled date
#	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
#	addiu	$5,r20,((uname_info-bss_begin)+U_VERSION)	

#	jal	center_and_print	# center and print
#	nop				# branch delay
 	
	#===============================
	# Middle-Line
	#===============================
middle_line:
	
#	addiu	r21,r20,(out_buffer-bss_begin)	# point r21 to out_buffer
	
	#=========
	# Load /proc/cpuinfo into buffer
	#=========

#	li	$2, SYSCALL_OPEN	# OPEN Syscall
	
#	addiu	$4,r19,(cpuinfo-data_begin)
					# '/proc/cpuinfo'
#	li	$5, 0			# 0 = O_RDONLY <bits/fcntl.h>

#	syscall				# syscall.  fd in v0  
					# we should check that 
					# return v0>=0
						
#	move	$4,$2			# copy $2 (the result) to $4
	
#	li	$2, SYSCALL_READ	# read()
	
#	addiu	$5, r20,(disk_buffer-bss_begin)
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
#	addiu	$5,r19,(one-data_begin)		# print "One"	


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
#	addiu	$5,r19,(processor-data_begin)
	
	#========
	# RAM
	#========
	
#	li	$2, SYSCALL_SYSINFO	# sysinfo() syscall
##	addiu	$4, r20,(sysinfo_buff-bss_begin)
#	syscall
	
#	lw	$4, S_TOTALRAM($4)	# size in bytes of RAM
	# LOAD DELAY SLOT
#	li	$19,1			# print to strcat, not stderr
			
#	jal     num_to_ascii
	# BRANCH DELAY SLOT
#	srl	$4,$4,20		# divide by 1024*1024 to get M

	
					# print 'M RAM, '
#	jal	strcat			# call strcat
#	addiu	$5,r19,(ram_comma-data_begin)

	

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
#	addiu	$5,r19,(bogo_total-data_begin)


#	jal	center_and_print	# center and print
#	nop
	
	#=================================
	# Print Host Name
	#=================================

#	addiu	r21,r20,(out_buffer-bss_begin)  
					# point r21 to out_buffer


					# host name from uname()
#	jal	strcat			# call strcat
	# BRANCH DELAY SLOT
#	addiu	$5,r20,(uname_info-bss_begin)+U_NODENAME    	
	
#	jal	center_and_print	# center and print
	# BRANCH DELAY SLOT
#	nop
	
					# (.txt) pointer to default_colors
#	jal	write_stdout
	# BRANCH DELAY SLOT
#	addiu	$5,r19,(default_colors-data_begin)	
	

	#================================
	# Exit
	#================================
test:
	addi r12, r0, SYSCALL_WRITE
	addi r5, r0, STDOUT
	addi r6, r0, hello
	addi r7,r0, 13
	brki r14, 0x08			# syscall
	nop

exit:
        addi r12, r0, SYSCALL_EXIT	# put exit syscall in r12
	addi r5, r0,5			# return value 
        brki r14, 0x08			# syscall
	nop   	   			# branch delay slot


	#=================================
	# FIND_STRING 
	#=================================
	#   $6 (a2) is char to end at
	#   $4 (a0) is 4-char ascii string to look for
	#   r19 (s1) is the output buffer
	
	#   $5 is destroyed
	#   $11 (t3) is destroyed

find_string:					
#	addiu	$5, r20,(disk_buffer-bss_begin)-1	
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
	
#	sb	$11,0(r21)		# if not store and continue
#	j	store_loop		# loop
#	# BRANCH DELAY SLOT
#	addiu	r21,r21,1		# increment output pointer

done:
#	jr	$31			# return
	# BRANCH DELAY SLOT
#	nop

	#================================
	# strcat
	#================================
	# output_buffer_offset = r21 (s0)
	# string to cat = $5         (a1)
	# destroys t0 (r8)

strcat:
#	lbu 	r8,0($5)		# load byte from string
#	# LOAD DELAY SLOT	
#	addiu	$5,$5,1			# increment string	
#	sb  	r8,0(r21)		# store byte to output_buffer

#	bne 	r8,$0,strcat		# if zero, we are done
#	# BRANCH DELAY SLOT
#	addiu	r21,r21,1		# increment output_buffer

done_strcat:
#	jr	$31			# return
	# BRANCH DELAY SLOT
#	addiu	r21,r21,-1		# correct pointer	


	#==============================
	# center_and_print
	#==============================
	# string is in r21 (s0) output_buffer
	# s3 $19= stdout or strcat
        # $20, $21, $22 trashed
       
center_and_print:

#	move	$21,$31				# save return address
#	move	$20,r21				# $20 is the end of our string
#	addiu	r21,r20,(out_buffer-bss_begin)	# point r21 to beginning 
	

#	subu	$4, $20,r21		# subtract end pointer from start
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
#	addiu	$5,r19,(escape-data_begin)


#	jal	num_to_ascii		# print number of spaces
	# BRANCH DELAY SLOT
#	move	$4,$22			# how much to shift to right

#	jal	write_stdout
	# BRANCH DELAY SLOT
#	addiu	$5,r19,(c-data_begin)	# print "C"


done_center:
					# point to the string to print
#	jal 	write_stdout
	# BRANCH DELAY SLOT
#	addiu	$5,r20,(out_buffer-bss_begin)


#	addiu	$5,r19,(linefeed-data_begin)
					# print linefeed at end of line
	
#	move 	$31,$21 		# restore saved pointer
	     				# so we'll return to
					# where we were called from 
					# at the end of the write_stdout
	
	#================================
	# WRITE_STDOUT
	#================================
	# $5 (a1) has string
	# $24,$25 (t8,t9) destroyed
	
write_stdout:
#	li      $2, SYSCALL_WRITE       # Write syscall in $2
#	li	$4, STDOUT		# 1 in $4 (stdout)
	
#	li	$6, 0			# 0 (count) in $6
	
#	move	$25,$5			# copy string to $25
	
str_loop1:
#	lbu	$24,1($25)		# load byte at (t9)
#	addi	$25,$25,1		# LOAD DELAY SLOT	
#	bnez	$24,str_loop1		# if not nul, repeat
	# BRANCH DELAY SLOT
#	addi	$6,$6,1			# increment a2
#	syscall  			# run the syscall

	br	r15 			# return
	# BRANCH DELAY SLOT

	
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
	# BRANCH DELAY SLOT
#	move	$4,$10		# move old result into next divide	
	
write_out:
#	beq	$19,$0,write_stdout
#	nop			# if write stdout, go there 
 #   	j	strcat		# else, strcat will return for us
#	nop

#===========================================================================
#	section .data
#===========================================================================
.data
.align 8	# needed?

hello:	.ascii "Hello World!\n\0"

data_begin:	
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"
linefeed:	.ascii  "\n\0"
default_colors:	.ascii "\033[0m\n\n\0"
escape:		.ascii "\033[\0"
c:		.ascii "C\0"

cpuinfo:	.ascii	"/proc/cpuinfo\0"

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
