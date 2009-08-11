#
#  linux_logo in alpha assembler    0.38
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
#     $22-$25 = t8-t11 (temporaries)  (t9 and t10 used by ld/st pseudo ops?)
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

# LDA,LDAH = load address (16 bit+reg, or 16 bit << 16 + reg)
# LDL,LDQ,LDQ_U,LDL_L,LDQ_L = load 32, 64, unaligned, locked
# STL_C,STQ_C = store conditional (use with load locked)
# STL,STQ,STQ_U = store 32,64,unaligned
# BEQ,BNE = branch if reg zero or not zero
# BGE,BGT,BLE,BLT = branch if reg greatereq, greater, lesseq,less than zero
# BLBC,BLBS = branch if low bit clear/set
# BR, BSR = branch, branch subroutine
# JMP,JSR,RET,JSR_COUROUTINE = all same, but differ in branch prediction
# ADDL,ADDQ = add
# S4ADDL,S8ADDL,S4ADDQ,S8ADDQ = scale ra by 4 or 8 then add
# CMPEQ,CMPLE,CMPLT = compare two regs, set third to 0 or 1
# CMPULE,CMPULT = unsigned compare
# MULL,MULQ = mulyiply
# UMULH = generates the top 64 bits of a 64x64 multiply
# SUBL, S4SUBL, S8SUBL = subtract, scaled subtract
# SUBQ, S4SUBQ, S8SUBQ = subtract, scaled subtract
# AND,BIS,XOR = and, or, xor
# BIC, EQV, ORNOT = and/complement, xor/complement, or/complement
# CMOVEQ,CMOVGE,CMOVGT,CMOVLBC,MOVLBS,CMOVLE,CMOVLT,CMOVNE = conditional move
# SLL, SRL = shift logical
# SRA = shift right arithmetic (can use sll for arithemetic left shift)
# CMPBGE = compare 8 bytes in parallel.  Result is an 8-bit bitmask in RC
# EXTBL,EXTWL,EXTLL,EXTQL = extract from 0-7  bytes, shifting, zero padding
# EXTWH,EXTLH,EXTQH = same as above, but shift left instead of right.
# INSBL,INSWL,INSLL,INSQL = insert bytes into a field of zeros
# INSWH,INSLH,INSQH = like above
# MSKBL,MSKWL,MSKLL,MSKQL = mask bytes to 0 
# MSKWH,MSKLH,MSKQH = same as above
# ZAP,ZAPNOT = zap selected bytes in a quadword to 0

# Pseudo-ops
#   ldil = load immediate
#   ldbu = load byte unsigned
#   uldwu = unaligned load word unsigned
#   uldlu = unaligned load long unsigned
#   stb  = store byte
#   clr  = set to zero
#   negq = negate quadword

# Optimization (starting with already optimized code)
# 1957 - original
# 1949 - change 16-bit load code to use uldwu
# 1941 - change uldl in find_string to uldlu
# 1933 - change ldb to ldbu in ascii_to_num
# 1925 - have num_to_ascii fallthrough to strcat
# 1821 - use addition from data_begin instead of GOT to get DATA addresses


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
				# load from gp for you.  
				# For each such load against gp there is
				#   a 64-bit value stored in the GOT section
				# The "ldgp" pseudo-instruction expands
				#   to two Alpha instructions
				
	lda	$13,data_begin	# since all of our data fits in < 16kB
#	lda	$14,bss_begin	#  use our own offset registers
				#  instead of gp which is 4 byte insn/
				#                         8 byte in GOT
				#  instead we can just use one add instruction
				#  I currently can't figure out how
				#    to get the assembler to give me
				#    consistent BSS values, so not using
				#    them there for now :(  Could probably
				#    get another 100 bytes or so

        #=========================
	# PRINT LOGO
	#=========================

# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver

	lda	$11,out_buffer	# point $11 to out_buffer
	
	ldil	$12,(N-F)		# R
	addq	$13,LOGO_OFFSET,$9	# $9 points to logo
	lda	$10,logo_end		# $10 points to end of logo
	ldil	$15,0x1fe0		# we use this constant a few times

decompression_loop:
	ldbu	$8,0($9)		# load in a byte
					# expands to lda/ldq_u/extbl
	lda	$9,1($9)		# increment source pointer
	s8addq	$15,$8,$2		# shift to get 0xff00 and add
	                                # top is a hackish 8-bit counter

test_flags:	
	cmpeq	$9,$10,$1		# have we reached the end?
	bne	$1,done_logo		# if so, exit

	mov	$2,$1			# save current value
	srl	$2,1,$2			# shift for next round
	blbs	$1,discrete_char	# test to see if discrete char

offset_length:
        uldwu  	$4,0($9)	# unaligned load 16-bit unsigned
				# expands to lda/ldq_u/ldq_u/extwl/extwh
				
	lda	$9,2($9)        # increment source pointer by two

	srl	$4,P_BITS,$3	# get the top bits, which is length
	
	lda	$3,THRESHOLD+1($3)
				# add in the threshold?
		
output_loop:
	ldil	$1,(POSITION_MASK<<8+0xff)	
	and	$4,$1,$4
	                                # get the position bits
					# two step, as 1023 is greater
					# than maximum immediate of 256
	lda	$8,text_buf
	addq	$8,$4,$8		#
	ldbu	$8,0($8)	        # load byte from text_buf[]
					# expands to lda/ldq_u/extbl
	lda	$4,1($4)		# advance pointer in text_buf
		
store_byte:	
	stb	$8,0($11)		# store byte to output buffer
					#  expands to lda/ldq_u/insbl/mskbl
					#             or/stq_u
					
	lda	$11,1($11)		# increment pointer

	lda	$1,text_buf
	addq	$1,$12,$1
	stb	$8,0($1)		# store also to text_buf[r]
					#  expands to lda/ldq_u/insbl/mskbl
					#             or/stq_u
	
	lda	$12,1($12)		# r++
	
	ldil	$6,(N-1)
	and	$12,$6,$12		# wrap r if we are too big	

	lda	$3,-1($3)		# decrement count
	bne	$3,output_loop		# repeat until k>j

	srl	$2,8,$1			# if 0 we shifted through 8 and must
	bne	$1,test_flags		# re-load flags

	br	decompression_loop

discrete_char:
	ldbu	$8,0($9)		# load a byte
					# expands to lda/ldq_u/extbl
	lda	$9,1($9)		# increment pointer			
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

	addq	$13,VERSION_OFFSET,$16		# source is " Version "
	br	$26,strcat
	
	addq	$9,U_RELEASE,$16    	# version from uname "2.4.1"
	br	$26,strcat

	addq	$13,COMPILED_OFFSET,$16 # source is ", Compiled "
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
	addq	$13,CPUINFO_OFFSET,$16  # '/proc/cpuinfo'
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
	addq	$13,ONE_OFFSET,$16      # point to one

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
	ldi	$18,'\n'
	
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

	addq	$13,MEGAHERTZ_OFFSET,$16 # print 'MHz '
	br	$26,strcat
   
   
   	#=========
	# Chip Name
	#=========
	
   	ldi     $17,('l'<<24)+('e'<<16)+('d'<<8)+'o'     	
					# find 'odel' and grab until space
	ldi	$18,'\n'
	br	$26,find_string

	addq	$13,PROCESSOR_OFFSET,$16
	br	$26,strcat

	addq	$13,COMMA_OFFSET,$16		# print ', '
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

	addq	$13,RAM_COMMA_OFFSET,$16	# print 'M RAM, '
	br	$26,strcat
	
	#========
	# Bogomips
	#========
	
	ldi	$17,('S'<<24)+('P'<<16)+('I'<<8)+'M'
					# find 'MIPS' and grab up to \n
	ldi	$18,'\n'
	br	$26,find_string

	addq	$13,BOGO_TOTAL_OFFSET,$16    # print bogomips total
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
	
	addq	$13,DEFAULT_COLORS_OFFSET,$17
					# restore default colors
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

	uldlu	$6,0($5)		# Unaligned 32-bit load
	
					# this is expanded by the assembler
					# into 5 instructions!
					#    ldq_u t9,0(at)
					#    ldq_u t10,3(at)
					#    extll t9,at,t9
					#    extlh t9,t10,t5
					#    or    t9,t10,t5

	beq	$6,done			# quit if at end
	lda	$5,1($5)		# incrememnt pointer
	
	cmpeq	$17,$6,$7		# compare against our string
	beq	$7,find_loop		# loop back if not match
					# if we get this far, we matched
	
find_colon:
	ldbu	$6,0($5)		# look for a colon
					# expands to lda/ldq_u/extbl 
	lda	$5,1($5)		# increment counter
	beq	$6,done			# escape if zero
	cmpeq	$6,':',$7		# look for colon
	beq	$7,find_colon		# if no colon, repeat
	
	lda	$5,1($5)		# skip a char [should be space]
	
store_loop:	 
	ldbu	$6,0($5)		# load byte
					#  expands to lda/ldq_u/extbl
	lda	$5,1($5)		# increment pointer
	beq	$6,done			# if zero, exit
    	cmpeq	$6,$18,$7		# is it the end char?
	bne 	$7,done			# if so, finish
	stb	$6,0($11)		# if not store and continue
					#  expands to lda/ldq_u/insbl
					#             mskbl/or/stq_u
	lda	$11,1($11)		# increment pointer
	br	store_loop		# loop
	 
done:
	ret	$26			# return

	
	#===========================
	# ascii_to_num
	#===========================
	# $11=string
	# $0=result
	# $1,$2=temp
ascii_to_num:
	clr	$0			# zero result
ascii_loop:		
	ldbu	$1,0($11)		# load value
					#  expands to lda/ldq_u/extbl
	addq	$11,1,$11		# increment pointer
	cmplt	$1,'0',$2
	bne	$2,ascii_done		# done if < '0'
	
	mulq	$0,10,$0		# shift decimal left
	subq	$1,0x30,$1		# convert ascii->decimal
	addq	$0,$1,$0		# add it in
	br	ascii_loop		# loop
ascii_done:			
	ret	$26			# return


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

	addq	$13,ESCAPE_OFFSET,$17   # print ESCAPE char
	br	$26,write_stdout	#
	
	srl	$2,1,$16		# divide by 2

	br	$26,num_to_ascii	# print number of spaces

	addq	$13,C_OFFSET,$17        # print "C"
	br	$26,write_stdout

done_center:
	lda	$17,out_buffer		# point to the string to print
	br	$26,write_stdout
	
	addq	$13,LINEFEED_OFFSET,$17	
					# print linefeed
	
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
					#  lda/ldq_u/extbl
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
	lda	$10,ascii_buffer_end	# point to end of ascii buffer

	ldi	$17,10			# divide by 10	
div_by_10:

	br	$24,divide		# Q=$0, R=$1

	addq	$1,0x30,$1		# convert to ascii
	stb	$1,0($10)		# store to buffer
					#  lda/ldq_u/insbl
					#  mskbl/or/stq_ux
	subq	$10,1,$10		# move pointer
	mov	$0,$16			# move Q in for next divide
	bne	$0,div_by_10		# if Q not zero, loop

write_out:
	addq	$10,1,$10		# point to beginning of string

	bne	$5,to_strcat		# is it strcat?

to_stdout:
	mov	$10,$17			# point to buff
	br	write_stdout		# print and return
to_strcat:
	mov	$10,$16			# point to buff
	 				# fall-through to stract

	#================================
	# strcat
	#================================
	# $16 = source
	# $11 = destination
	# $1 = trashed
strcat:
	ldbu	$1,0($16)		# load a byte from $16
					#  expands to lda/ldq_u/extbl
	lda	$16,1($16)		# increment pointer
	
	stb	$1,0($11)		# store a byte to $11
					#  expands to lda/ldq_u/insbl
					#             mskbl/or/stq_u
					
	lda	$11,1($11)		# increment pointer
	bne	$1,strcat		# if not zero, loop
	
	subq	$11,1,$11		# back up pointer to the zero
					
	ret	$26			# return


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

	ret	$31,($24)		# return to addr in r24

	
#===========================================================================
#.data
#===========================================================================

# I wish I could auto-generate these
.equ VERSION_OFFSET,0
.equ COMPILED_OFFSET,10
.equ MEGAHERTZ_OFFSET,22
.equ RAM_COMMA_OFFSET,33
.equ BOGO_TOTAL_OFFSET,41
.equ LINEFEED_OFFSET,57
.equ DEFAULT_COLORS_OFFSET,59
.equ ESCAPE_OFFSET,66
.equ C_OFFSET,69
.equ PROCESSOR_OFFSET,71
.equ COMMA_OFFSET,82
.equ CPUINFO_OFFSET,86
.equ ONE_OFFSET,100
.equ LOGO_OFFSET,119

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
processor:		.ascii " Processor\0"
comma:			.ascii "s, \0"

.ifdef FAKE_PROC
cpuinfo:		.ascii  "proc/cp.alpha\0"
.else
cpuinfo:		.ascii  "/proc/cpuinfo\0"
.endif

one:			.ascii	"One\0"
two:			.ascii	"Two\0"
three:			.ascii  "Three\0"
four:			.ascii	"Four\0"

.include "logo.lzss_new"

array:		.byte	0,4,8,14




#============================================================================
#.bss
#============================================================================

.lcomm	bss_begin,8
.lcomm  text_buf, (N+F-1)
.lcomm  ascii_buffer,16        # Let's hope we aren't bigger than 16 digits
.lcomm  ascii_buffer_end,16    # has to be big, or else asm puts it in .sbss?

	   # see /usr/src/linux/include/linux/kernel.h
.lcomm sysinfo_buff,(64)
.lcomm uname_info,(65*6)
.lcomm  disk_buffer,4096        # we cheat!!!!
.lcomm  out_buffer,16384
	
