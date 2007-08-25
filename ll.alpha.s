#
#  linux_logo in alpha assembler    0.30
#
#  by Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -o ll.o ll.alpha.s"
#  link with         "ld -o ll ll.o"


# Things to know about Alpha assembly:
#   + 32 int registers, 64-bit, $0-$31
#     Standard calling convention:	
#     $0 = v0 (return value)
#     $1-$8 are $t0-$t7 (temporaries)
#     $9-$14 are $s0-$s5 (saved)
#     $15 = frame pointer (if needed)
#     $16-$21 = $a0-$a5 (arguments)
#     $22-$25 = t8-t11 (temporaries)
#     $26 = $ra (default return address)
#     $27 = procdeure value?				
#     $28 = at (assembler temp) 
#     $29 = gp, 
#     $30 = sp (stack pointer)
#     $31 always contains zero
#   + Scaled add instructions.
#   + Standard thing to do at procedure call time is  ldgp    $gp,0($27)
#   + syscalls, the syscall number is in $0, the arguments $16-?
#	then a "callsys" instruction	
#   + Loading a byte expands into 5 opcodes if signed! 3 if unsigned!
#   + Assembly is OP src1,src2,dest
#   + Alpha has no integer division routine.

# offsets into the results returned by the uname syscall
.equ U_SYSNAME,0
.equ U_NODENAME,65
.equ U_RELEASE,65*2
.equ U_VERSION,(65*3)
.equ U_MACHINE,(65*4)
.equ U_DOMAINNAME,65*5

# syscall numbers

.equ SYSCALL_EXIT,1	
.equ SYSCALL_READ,3
.equ SYSCALL_WRITE,4
.equ SYSCALL_CLOSE,6
.equ SYSCALL_OPEN,45
.equ SYSCALL_SYSINFO,318
.equ SYSCALL_UNAME,339

# From /usr/include/linux/kernel.h
.equ S_TOTALRAM,32
		
.equ STDIN,0
.equ STDOUT,1
.equ STDERR,2	
	
.include "logo.include"
	
	.globl _start
_start:
	
	br      $27,0           # fake branch, to grab the location
	                        # of our entry point
	ldgp    $gp,0($27)      # load the GP proper for our entry point
				# this does automagic stuff...
				# gp is used for 64-bit jumps and constants
				# so if you use "la" and the like it will
				# load from gp for you.  This is an
				# optimization done by hand in other
				# ll implementations
		
        #=========================
	# PRINT LOGO
	#=========================

# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver

	lda	$11,out_buffer		# point $11 to out_buffer
	
	ldil	$12,(N-F)		# R

	lda	$9,logo			# $9 points to logo
	lda	$10,logo_end		# $10 points to end of logo
	ldil	$15,0x1fe0		# we use this constant a few times

decompression_loop:
	ldbu	$13,0($9)		# load in a byte
	addq	$9,1,$9			# increment source pointer
	s8addq	$15,$13,$2		# shift to get 0xff00 and add
	                                # top is a hackish 8-bit counter

test_flags:	
	cmpeq	$9,$10,$1		# have we reached the end?
	bne	$1,done_logo		# if so, exit

	mov	$2,$1			# save current value
	srl	$2,1,$2			# shift for next rounf
	blbs	$1,discrete_char	# test to see if discrete char

offset_length:
	ldbu	$13,0($9)	# load 16-bit length and match_position combo
	ldbu	$4,1($9)	# can't use lhu because might be unaligned
	addq	$9,2,$9		# increment source pointer
	sll	$4,8,$4
	or      $4,$13,$4
	
	srl	$4,P_BITS,$3	# get the top bits, which is length
	
	addq	$3,THRESHOLD+1,$3
				# add in the threshold?
		
output_loop:
	ldil	$1,(POSITION_MASK<<8+0xff)	
	and	$4,$1,$4
	                                # get the position bits
	lda	$13,text_buf
	addq	$13,$4,$13		#
	ldbu	$13,0($13)
	                                # load byte from text_buf[]
	addq	$4,1,$4			# advance pointer in text_buf
		
store_byte:	
	stb	$13,0($11)
	addq	$11,1,$11		#  store byte to output buffer

	lda	$1,text_buf
	addq	$1,$12,$1
	stb	$13,0($1)		# store also to text_buf[r]
	
	addq	$12,1,$12		# r++
	ldil	$6,(N-1)
	and	$12,$6,$12		# wrap r if we are too big	

	subq	$3,1,$3			# decrement count
	bne	$3,output_loop		# repeat until k>j

	srl	$2,8,$1			# if 0 we shifted through 8 and must
	bne	$1,test_flags		# re-load flags

	br	decompression_loop

discrete_char:
	ldbu	$13,0($9)
	addq	$9,1,$9			# load a byte
	ldiq	$3,1			# force a one-byte output	
	br	store_byte		# and store it
	
done_logo:
	lda	$17,out_buffer		# point $16 to out_buffer	
	br	$26,write_stdout	# print the logo
	
first_line:
	#==========================
	# PRINT VERSION
	#==========================

	ldi	$0,SYSCALL_UNAME	# uname syscall
	lda	$16,uname_info		# uname struct
	mov	$16,$9			# save pointer to uname_info for later
	callsys				# do syscall
	
	lda	$11,out_buffer		# restore output to out_buffer
	
	br	$26,strcat		# print "Linux"

	lda	$16,ver_string		# source is " Version "
	br	$26,strcat
	
	addq	$9,U_RELEASE,$16    	# version from uname "2.4.1"
	br	$26,strcat
	
	lda	$16,compiled_string	# source is ", Compiled "
	br	$26,strcat

	addq	$9,U_VERSION,$16	# compiled date
	br	$26,strcat

	br	$25,center_and_print	# print the string

	
	#===============================
	# Middle-Line
	#===============================
middle_line:	

	lda	$11,out_buffer		# restore output pointer
		
	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	ldi	$0,SYSCALL_OPEN		# open()
	lda	$16,cpuinfo		# '/proc/cpuinfo'
	ldi	$17,0			# O_RDONLY <bits/fcntl.h>
	callsys				# syscall.  fd in $0.  
					# we should check that $0>=0

	mov	$0,$5			# save fd in $5
	
	ldi	$0,SYSCALL_READ		# read
	mov	$5,$16			# copy fd
	lda	$17,disk_buffer
	ldi	$18,4096	 	# 4096 is upper-limit guess of procfile
	callsys

	mov	$5,$16			# restore fd
	ldi	$0,SYSCALL_CLOSE	# close
	callsys

	#=============
	# Number of CPUs
	#=============

	ldi	$17,('d'<<24)+('e'<<16)+('t'<<8)+'c'
					# find 'cted' and grab after ':'
	ldi	$18,'\n'

	mov	$11,$16			# save output
   	br	$26,find_string
	stb	$31,0($11)		# nul terminate string

	mov	$16,$11			# restore string
	br	$26,ascii_to_num	# convert ascii to decimal

	subq	$11,1,$11		# fix pointer

	mov	$0,$4			# save for later (plural)
		
	cmple	$0,4,$1			# see if less than 4
	beq	$1,print_megahertz	# if so, just print the number

	mov	$16,$11
	lda	$16,one			# point to one

	subq	$0,1,$0			# decrement because we index from zero
	
	lda	$1,array		# get offset array
	addq	$1,$0,$1
	ldbu	$1,0($1)		# load offset of string
	addq	$16,$1,$16		# add to it
	
	br	$26,strcat		# print the number
	
	#=========
	# MHz
	#=========
print_megahertz:
	ldi	$16,' '
	stb	$16,0($11)
	addq	$11,1,$11		# add a space after the number
	
	ldi	$17,('l'<<24)+('c'<<16)+('y'<<8)+'c'
					# find 'cycl' and grab after ' '
	ldi	$18,' '
	
	mov	$11,$16			# save output
   	br	$26,find_string
	stb	$31,0($11)		# nul terminate string

	mov	$16,$11			# restore string
	br	$26,ascii_to_num	# convert ascii to decimal
	
	mov	$16,$11			# restore string

	mov	$0,$16			# divide by 1 million
	ldi	$17,1000000
	br	$24,divide

	ldi	$5,1			# strcat, not stdout	
	mov	$0,$16			# convert back to ascii-decimal
	br	$26,num_to_ascii
	
	lda	$16,megahertz		# print 'MHz '
	br	$26,strcat
   
   
   	#=========
	# Chip Name
	#=========
	
   	ldi     $17,('l'<<24)+('e'<<16)+('d'<<8)+'o'     	
					# find 'odel' and grab until space
	ldi	$18,'\n'
	br	$26,find_string

	lda	$16,processor
	br	$26,strcat
	
	lda	$16,comma	# print ', '
	cmpeq	$4,1,$1		
	beq	$1,plural
	addq	$16,1,$16	# skip s if not more than one cpu
plural:		
	br	$26,strcat
	
	#========
	# RAM
	#========
	
	ldi	$0,SYSCALL_SYSINFO	# sysinfo() syscall
	lda	$16,sysinfo_buff	# 
	callsys

	lda	$16,sysinfo_buff
	ldq	$16,S_TOTALRAM($16)

	sra	$16,20			# divide to get Megabytes

	ldi	$5,1
	br	$26,num_to_ascii
	
	lda	$16,ram_comma		# print 'M RAM, '
	br	$26,strcat
	
	#========
	# Bogomips
	#========
	
	ldi	$17,('S'<<24)+('P'<<16)+('I'<<8)+'M'
					# find 'MIPS' and grab up to \n
	ldi	$18,'\n'
	br	$26,find_string

	lda	$16,bogo_total		# print bogomips total
	br	$26,strcat

	br	$25,center_and_print
	

	#=================================
	# Print Host Name
	#=================================
last_line:
	lda	$11,out_buffer		# restore output buffer
	
	addq	$9,U_NODENAME,$16	# print node name
	br	$26,strcat		#
	
	br	$25,center_and_print

	lda	$17,default_colors	# restore default colors
	br	$26,write_stdout
	

	#================================
	# Exit
	#================================
exit:		
        clr	$16			# 0 exit value
        mov	SYSCALL_EXIT,$0		# put the exit syscall number in v0
        callsys				# and exit

	
	#=================================
	# FIND_STRING 
	#=================================
	#   $17 is pattern
	#   $18 is char to end at
	#   $11 points at output buffer
	#   $5,$6,$7=temp
	
find_string:
					
	lda	$5,disk_buffer		# look in cpuinfo buffer
	
find_loop:

	uldl	$6,0($5)		# Unaligned 32-bit load
	beq	$6,done
	addq	$5,1,$5			# incrememnt pointer
	
	cmpeq	$17,$6,$7
	beq	$7,find_loop		# compare it	
					# if we get this far, we matched
	
find_colon:
	ldbu	$6,0($5)		# look for a colon
	addq	$5,1,$5
	beq	$6,done
	cmpeq	$6,':',$7
	beq	$7,find_colon
	
	addq	$5,1,$5			# skip a char [should be space]
	
store_loop:	 
	ldbu	$6,0($5)
	addq	$5,1,$5
	beq	$6,done
    	cmpeq	$6,$18,$7		# is it end string?
	bne 	$7,done			# if so, finish
	stb	$6,0($11)		# if not store and continue
	addq	$11,1,$11
	br	store_loop
	 
done:
	ret	$26

	#================================
	# strcat
	#================================
	# $16 = source
	# $11 = destination
	# $1 = trashed
strcat:
	ldbu	$1,0($16)		# load a byte from $16
	addq	$16,1,$16
	stb	$1,0($11)		# store a byte to $11
	addq	$11,1,$11
	bne	$1,strcat		# if not zero, loop
	
	subq	$11,1,$11		# back up pointer to the zero
	ret	$26
	
	#===========================
	# ascii_to_num
	#===========================
	# $11=string
	# $0=result
	# $1=temp
ascii_to_num:
	clr	$0			# zero result
ascii_loop:		
	ldb	$1,0($11)		# load value
	addq	$11,1,$11
	beq	$1,ascii_done
	mulq	$0,10,$0		# shift decimal left
	subq	$1,0x30,$1		# convert ascii->decimal
	addq	$0,$1,$0		# add it in
	br	ascii_loop
ascii_done:			
	ret	$26


	#==============================
	# center_and_print
	#==============================
	# string is in out_buffer
	# end of buffer is in $11
	# $5 is print to stdout
	# we trash $1,$2,$17

center_and_print:
	lda	$17,out_buffer		# point to beginning
	subq	$11,$17,$2		# subtract end pointer to get size

	cmplt	$2,80,$1
	beq	$1,done_center		# don't center if > 80

	clr     $5			# print to stdout

	negq	$2			# negate length
	addq	$2,80,$2		# add to 80

	lda	$17,escape		# print ESCAPE char
	br	$26,write_stdout	#
	
	srl	$2,1,$16		# divide by 2

	br	$26,num_to_ascii	# print number of spaces

	lda	$17,c			# print "C"
	br	$26,write_stdout

done_center:
	lda	$17,out_buffer			# point to the string to print
	br	$26,write_stdout
	
	lda	$17,linefeed			# print linefeed
	
	mov	$25,$26				# write_stdout
						# will return for us
	
	#================================
	# WRITE_STDOUT
	#================================
	# $17 has string
	# $1 is trashed
	
write_stdout:	
	ldil	$0,SYSCALL_WRITE	# Write syscall in $0
	ldil	$16,STDOUT		# 1 in $16 (stdout)
	clr	$18			# 0 (count) in $18
	
str_loop1:
	addq	$17,$18,$1		# offset in $1
	ldbu    $1,0($1)		# load byte
	addq	$18,1,$18		# increment pointer
	bne	$1,str_loop1		# if not nul, repeat
	
	subq	$18,1,$18		# correct count
	callsys				# Make syscall
	
	ret	$26			# return
			
	
	#===========================
	# num_to_ascii
	#===========================
	# $16=num
	# $10=output
	# $5= strcat=1,stdout=0

num_to_ascii:
	lda	$10,ascii_buffer
	addq	$10,10,$10		# point to end of ascii buffer

	ldi	$17,10			# divide by 10	
div_by_10:

	br	$24,divide		# Q=$0, R=$1

	addq	$1,0x30,$1		# convert to ascii
	stb	$1,0($10)		# store to buffer
	subq	$10,1,$10		# move pointer
	mov	$0,$16			# move Q in for next divide
	bne	$0,div_by_10		# if Q not zero, loop

write_out:
	addq	$10,1,$10

	beq	$5,to_stdout
	mov	$10,$16
	
	br	strcat
to_stdout:
	mov	$10,$17			# point to buff
	br	write_stdout		# print and return
	
done_ascii:		


	#==================================================
	# Divide - because Alpha has no hardware int divide
	# yes this is an awful algorithm, but simple
	# and uses few registers
	#==================================================
	#  $16 =numerator $17=denominator
	#  $0 =quotient  $1=remainder
	#  $2,$3 = scratch
	
	# multiplying by 0xcccc cccd (2^34+1)/5
	# using umulh and then shifting left by 3
	# to divide by 10 is faster, but takes more bytes!
	
divide:
	clr	$0			# zero out quotient
divide_loop:
	mulq	$0,$17,$2		# multiply Q by denominator
	addq	$0,1,$0
	cmple	$2,$16,$3		# is it greater than numerator?

	bne	$3,divide_loop		# if not, loop
	subq	$0,2,$0			# otherwise went too far, decrement
					# and done
	
	mulq	$0,$17,$2		# calculate remainder
	subq	$16,$2,$1		# R=N-(Q*D)

	ret	$31,($24)		# return to addri n r24


	
#===========================================================================
#.data
#===========================================================================

data_begin:
ver_string:		.ascii  " Version \0"
compiled_string:	.ascii  ", Compiled \0"
megahertz:		.ascii  "MHz Alpha \0"
ram_comma:		.ascii  "M RAM, \0"
bogo_total:		.ascii  " Bogomips Total\0"
linefeed:		.ascii  "\n\0"
default_colors:		.ascii "\033[0m\n\n\0"
escape:			.ascii "\033[\0"
c:			.ascii "C\0"

cpuinfo:		.ascii  "/proc/cpuinfo\0"

one:			.ascii	"One\0"
two:			.ascii	"Two\0"
three:			.ascii  "Three\0"
four:			.ascii	"Four\0"
array:		.byte	0,4,8,14
			
processor:		.ascii " Processor\0"
comma:			.ascii "s, \0"

.include "logo.lzss_new"


#============================================================================
#.bss
#============================================================================

.lcomm bss_begin,1

.lcomm  text_buf, (N+F-1)
.lcomm  ascii_buffer,12         # Let's hope we aren't bigger than 12 digits

	   # see /usr/src/linux/include/linux/kernel.h
.lcomm sysinfo_buff,(64)
.lcomm uname_info,(65*6)

.lcomm  disk_buffer,4096        # we cheat!!!!
.lcomm  out_buffer,16384
	
