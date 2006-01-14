#
# TODO!  Remove nops, use gp!
#

#
#  linux_logo in mips assembler 0.14
#
#  By 
#       Vince Weaver <vince@deater.net>
#
#  assemble with     "as -o ll.o ll.mips.s"
#  link with         "ld -o ll ll.o"

.include "logo.include"


#
# Keep gas from handling branch-delay and load-delay slots automatically
#

#.set noreorder

#
# Register definitions.  Why does't gas know these?
#

.equ zero , 0
.equ at   , 1  # Assembler Temporary
.equ v0   , 2  # Returned value registers
.equ v1	  , 3
.equ a0	  , 4  # Argument Registers (Caller Saved)
.equ a1	  , 5
.equ a2	  , 6
.equ a3	  , 7
.equ t0   , 8  # Temporary (Caller Saved)
.equ t1   , 9
.equ t2   ,10
.equ t3   ,11
.equ t4   ,12
.equ t5   ,13
.equ t6   ,14
.equ t7   ,15
.equ s0   ,16  # Callee-Saved
.equ s1   ,17
.equ s2   ,18
.equ s3   ,19
.equ s4   ,20
.equ s5   ,21
.equ s6   ,22
.equ s7   ,23
.equ t8   ,24
.equ t9   ,25
.equ k0	  ,26  # Kernel Reserved (do not use!)
.equ k1   ,27
.equ gp	  ,28  # Global Pointer
.equ sp	  ,29  # Stack Pointer
.equ fp   ,30  # Frame Pointer
.equ s8	  ,30
.equ ra	  ,31  # return address (of subroutine call)


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

        # we used to fill the buffer with FREQUENT_CHAR
	# but, that only gains us one byte of space in the lzss image.
        # the lzss algorithm does automatic RLE... pretty clever
	# so we compress with NUL as FREQUENT_CHAR and it is pre-done for us

# bp = $8 = t0
# esi = $9 = t1
# edi = $17
# eax = $10 = t2
# ebx = $11 = t3
# logo_end = $12 = t4
# temp = $13 = t5
# ah = $14 = t6
# ecx = $15 = t7
# edx = $24 = t8

	li      $8,(N-F)   	     	# R

	la  	$9,logo			# t1 points to logo 
	la	$12,logo_end
	la	$16, out_buffer		# point s0 to out_buffer
	move	$17,$16			# copy to s0 for output


decompression_loop:

	lbu	$10,0($9)       # load in a byte
	addiu	$9,$9,1		# increment source pointer

	move 	$11, $10	# move in the flags
	ori 	$11,$11,0xff00  # re-load top as a hackish 8-bit counter

test_flags:
	beq	$12, $9, done_logo  # have we reached the end?
				# if so, exit

        andi	$13,$11,0x1
	srl	$11,$11,1  	# shift bottom bit into carry flag

	bne	$13,$0,discrete_char # if set, we jump to discrete char

offset_length:
	lbu     $10,0($9)	# le lodsw = high i
	lbu	$24,1($9)	
	sll	$24,$24,8
	or	$24,$24,$10
	move	$10,$24
	
	addiu	$9,$9,2	 	# get match_length and match_position
	    			# no need to mask dx, as we do it
				# by default in output_loop
	
	srl $15,$10,P_BITS	
	addiu $15,$15,THRESHOLD+1 
	      			# cl = (ax >> P_BITS) + THRESHOLD + 1
                                #                       (=match_length)
		
output_loop:
        andi 	$24,$24,(POSITION_MASK<<8+0xff)  	# mask it
	lbu 	$10,text_buf($24)	# load byte from text_buf[]
	addiu 	$24,$24,1	    	# advance pointer in text_buf
store_byte:	
        sb      $10,0($17)
	addiu	$17,$17,1      		# store it
	
	sb      $10, text_buf($8)	# store also to text_buf[r]
	addi 	$8,$8,1        		# r++
	andi 	$8,$8,(N-1)		# mask r

	addiu	$15,$15,-1		# decrement count
	bne	$15,$0,output_loop	# repeat until k>j

	andi	$13,$11,0xff00		# if 0 we shifted through 8 and must
	bne	$13,$0,test_flags	# re-load flags
	
	j 	decompression_loop

discrete_char:
	lbu     $10,0($9)
	addiu	$9,$9,1		       	# load a byte
	li   	$15,1		# we set ecx to one so byte
					# will be output once
					# (how do we know ecx is zero?)
					
        j     store_byte              # and cleverly store it


# end of LZSS code

done_logo:

	move	$5,$16

        jal	write_stdout		# print the logo


	#==========================
	# PRINT VERSION
	#==========================

	li	$2, SYSCALL_UNAME      # uname syscall in v0
	la	$4, uname_info	       # destination of uname
	or	$23, $4,$0 	       # point s7 to uname_info struct
	syscall	    		       # do syscall

	or	$17,$16,$0	       # copy s0 to s1 (output_buf_offset)
		
	la	$5, U_SYSNAME($23)     # os-name from uname "Linux"

	jal	strcat
	
	la	$5, ver_string		# source is " Version "
       	jal	strcat			# call strcat

	
	la	$5, U_RELEASE($23)	# version from uname "2.4.1"
	jal	strcat			# call strcat

	la	$5, compiled_string     # source is ", Compiled "
	jal	strcat			# call strcat

	la	$5,U_VERSION($23)	# compiled date
	jal	strcat			# call strcat

	jal	center_and_print	# center and print
	nop				# branch delay
  	
	#===============================
	# Middle-Line
	#===============================

	or	$17,$16,$0	       # copy s0 to s1 (output_buf_offset)

	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	li	$2, SYSCALL_OPEN	# OPEN Syscall
	
	la	$4, cpuinfo		# '/proc/cpuinfo'
	li	$5, 0			# 0 = O_RDONLY <bits/fcntl.h>
#	li	$6, 0			# 
	syscall				# syscall.  fd in v0  
					# we should check that 
					# return v0>=0
					
	or	$4,$2,$0		# copy v0 (the result) to a0
	
	li	$2, SYSCALL_READ	# read()
	
	la	$5, disk_buffer		# point a2 to the buffer


	li	$6, 4096		# 4096 is maximum size of proc file #)
					# we load sneakily by knowing
					# 16<<8 = 4096. be sure edx clear

	syscall

	li	$2, SYSCALL_CLOSE	# close (to be correct)
		    			# fd should still be in a0
	syscall

	#=============
	# Number of CPU's
	#=============
number_of_cpus:

	# we cheat here and just assume 1.  
	# besides, I don't have a SMP Mips machine to test on

	la	 $5,one	   	        # printf "One"
	jal	 strcat

	
	#=========
	# MHz
	#=========
print_mhz:

	# Mips /proc/cpuinfo does not indicate MHz


   	#=========
	# Chip Name
	#=========
chip_name:	
   	li	$4,('o'<<24+'d'<<16+'e'<<8+'l')     	
					# find 'odel\t: ' and grab up to ' '
	li	$6,' '
	jal	find_string

	la	$5,processor		# printf "Processor, "
	jal	strcat

	
	#========
	# RAM
	#========
	
	li	$2, SYSCALL_SYSINFO	# sysinfo() syscall
	la	$4, sysinfo_buff	
	syscall
	
	lw	$4, (sysinfo_buff+S_TOTALRAM)	# size in bytes of RAM
		
	srl	$4,$4,20		# divide by 1024*1024 to get M

	li	$19,1
	jal     num_to_ascii
	
	la   	$5, ram_comma           # print 'M RAM, '
	jal	strcat			# call strcat
	

	#========
	# Bogomips
	#========
	
	li	$4, ('M'<<24+'I'<<16+'P'<<8+'S')      	
					# find 'mips\t: ' and grab up to \n
	li	$6, 0xa
	jal	find_string

	la	$5, bogo_total	   	# bogo total follows RAM 
	jal 	strcat			# call strcat

	jal	center_and_print	# center and print
	
	#=================================
	# Print Host Name
	#=================================
	
	or	$17,$16,$0	       # copy s0 to s1 (output_buf_offset)
		
	la	$5, U_NODENAME($23)    # host name from uname()
	jal	strcat		       # call strcat
	
	jal	center_and_print       # center and print
	
	la	$5,default_colors      # (.txt) pointer to default_colors
	
	jal	write_stdout
	

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
					
	la	$5, disk_buffer-1	# look in cpuinfo buffer
find_loop:
	addiu   $5,$5,1		        # increment pointer
	ulw	$11,0($5)		# load un-aligned 32 bits
	beq	$11,$0,done		# are we at EOF?
					# if so, done

	bne	$4,$11, find_loop	# do the strings match?
					# if not, loop
	
					# if we get this far, we matched

find_colon:
	addiu	$5,$5,1
	lbu	$11,0($5)		# repeat till we find colon
	beq	$11,$0,done		# not found? then done

	bne	$11,':',find_colon


	addiu   $5,$5,2			# skip a char [should be space]
	
store_loop:	 
	lbu	$11,0($5)		# load value
	addiu	$5,$5,1			# increment
	beq	$11,$0,done		# off end, then stop
	
	beq	$11,$6,done      	# is it end char?
					# if so, finish
	sb	$11,0($17)		# if not store and continue
	addiu	$17,$17,1		# increment output pointer
	j	store_loop		# loop
	
done:
	jr	$31			# return


	#================================
	# strcat
	#================================
	# output_buffer_offset = $17 (s1)
	# string to cat = $5         (a1)
	# destroys t0 ($8)

strcat:
       lbu 	$8,0($5)		# load byte from string
       nop				# load delay (move inc here?)
       sb  	$8,0($17)		# store byte to output_buffer
       beq 	$8,$0,done_strcat	# if zero, we are done
       nop 				# branch delay

       addiu	$5,$5,1			# increment string
       addiu	$17,$17,1		# increment output_buffer
       
       j	strcat	 		# loop
       nop				# branch delay

done_strcat:
       jr	$31			# return
       nop				# branch delay	

	#==============================
	# center_and_print
	#==============================
	# string is in $16 (s0) output_buffer
        #$20
	#$22
       
center_and_print:
	move $5,$16			# save pointer
	move $21,$31			# save return address

#s3 $19= stdout or strcat

       move	$20,$5

       li    	$19,0 			# print to stdout
       subu	$4, $17,$16		# subtract end pointer from start
       		    			# (cheaty way to get size of string)

       bgt	$4,80, done_center	# don't center if > 80

       neg	$4,$4  			# negate length
       addiu	$4,$4,80		# add to 80 

       srl	$22,$4,1			# divide by 2 

       la	$5,escape
       jal	write_stdout
       
       move	$4,$22

       jal	num_to_ascii		# print number of spaces

       la	$5,c			# print "C"
       jal	write_stdout



done_center:
        move 	$5, $20			# point to the string to print
        jal 	write_stdout
       
	la	$5, linefeed	        # print linefeed at end of line
	
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
	li      $2, SYSCALL_WRITE       # Write syscall in v0
	li	$4, STDOUT		# 1 in a0 (stdout)
	
	li	$6, 0			# 0 (count) in a2
	
	or	$25,$5,$0		# move a1 -> t9
	
str_loop1:

	addi	$25,$25,1		# increment t9	
	lbu	$24,($25)		# load byte at (t9)
	addi	$6,$6,1			# increment a2  (load delay slot)
	
	bnez	$24,str_loop1		# if not nul, repeat

	syscall  			# run the syscall

	jr	$31 			# return
	nop
	
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

	 la	 $5,ascii_buffer+10	# point to end of ascii_buffer

 div_by_10:
 	 addiu	 $5,$5,-1	 # point back one
 	 divu	 $10,$4,10	 # divide.  hi= remainder, lo=quotient
	 mfhi	 $11		 # remainder into t3 ($11)
	 addiu	 $11,$11,0x30	 # convert to ascii
	 sb	 $11,0($5)	 # store to buffer
	 or	 $4,$10,$0	 # move old result into next divide
	 bne	 $10,$0, div_by_10	 
 
write_out:

	 beq	 $19,$0,write_stdout
     	 j	 strcat		 # strcat will return for us


#===========================================================================
#	section .data
#===========================================================================
.data

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

.lcomm  text_buf, (N+F-1)
.lcomm	out_buffer,16384

.lcomm	disk_buffer,4096	# we cheat!!!!

.lcomm  ascii_buffer,10		# 32 bit can't be > 9 chars

   # see /usr/src/linux/include/linux/kernel.h
.lcomm sysinfo_buff,(64)
.lcomm uname_info,(65*6)
