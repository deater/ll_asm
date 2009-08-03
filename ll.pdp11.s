#
#  linux_logo in PDP-11 assembler 0.34
#
#       Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -o ll.o ll.pdp11.s"
#  link with         "ld -o ll ll.o"
#
#  We use a cross-compiled pdp11-dec-aout binutils for assembling
#   2.19 and earlier has a bug with index/index deferred mode
#   I use a patched version, the bug has been reported to binutils

#
# Architectural info
#
# + We assume a pdp-11/40 with EIS instructions available
# + 64k address space (more is possible with MMU)
# + 8 gp 16-bit regs, r0-r7.  r6=stack, r7=pc
# + optional fpu, ac0-ac3
# + Status registers Z,N,C,V
# + Little-endian (Actually PDP-endian for 32-bit vals)
# + no unaligned memory accesses

# leis (limited eis) and eis (extended instruction set) are
#  instructions later added to the instruction set

# Addressing modes:
# + Single operand - one operand
# + Double operand - two operands (source and destination)
# + Direct Addressing
#   - Register -  Rx     
#   - Auto-inc - (Rx)+   - register used, then incremented (1 for byte,2 word)
#   - Auto-dec - -(Rx)   - register decremented, then used
#   - Index    - N(Rx)   - offset used against Rx
# + Indirect Addressing
#   - Register -  @Rx or (Rx)  - reg contains address of op
#   - Auto-inc -  @(Rn)+       - reg used as pointer, then inc by 2
#   - Auto-dec -  @-(Rn)       - reg dec by 2, then used as pointer
#   - Index    -  @N(Rx)       - X is added to Rn and that is used as pointer
# + PC based
#   - Immediate - #n   - the immediate value follows immediately inline
#   - Absolute  - @#A  - the immediate value follows after, used as pointer
#   - Relative  - A    - address calculated relative to PC
#   - Relative Indirect - @A - address calculated relative to PC, use as point

# Instruction summary
# CLR, CLRB - clear a destination
# COM, COMB - complement destination
# INC, INCB - increment
# DEC, DECB - decrement
# NEG, NEGB - two's complement
# TST, TSTB - set condition codes

# ASR, ASRB - arith shift right (into carry)
# ASL, ASLB - arith shift left (into carry)
# ROR, RORB - rotate right (through carry)
# ROL, ROLB - rotate left (through carry)
# SWAB      - swap upper and lower bytes

# ADC, ADCB - add with carry
# SBC, SBCB - subtract with carry
# SXT       - (leis) sign extend

# MOV, MOVB - move (for movb, sign extends)
# CMP, CMPB - compare and set condition codes
# ADD       - add
# SUB       - subtract

# BIT, BITB - test if bits set, sets condition code
# BIC, BICB - clears bits in destination set in source (mask. can make and)
# BIS, BISB - or
# XOR       - (leis) xor

# BR        - branch unconditional
# BNE, BEQ  - branch if equal or not to zero (Z)
# BPL, BMI  - branch if plus or minus (N)
# BVC, BVS  - branch if (V) set or not
# BCC, BCS  - branch if carry or not
# BGE, BLT  - branhh if ge/lt
# BGT, BLE  - branch if gt/le
# BHI, BLOS - branch if higher, branch if lower or same
# BHIS, BLO - branch if higher or same, if lower
# JMP       - unconditional jump (can be used for vector jumps)
# JSR       - jump subroutine.  pushes old addr on stack.
#             stack parameters can be read with auto-increment
#             special JSR PC insn for passing arguments in registers
# RTS       - return from subroutine
# MARK      - (leis) marks end of stack, returns can auto-clean up stack size
# SOB       - (leis) subtract one, branch if not zero

# CLN,CLZ,CLV,CLC,CCC,SEn,SEZ,SEV,SEC,SCC - set/clear condition codes.
#             can be ored together

# MUL       - OPTIONAL eis multiply instruction
# DIV       - OPTIONAL eis divide instruction
# ASH       - OPTIONAL eis shift right or left by more than one
# ASHC      - OPTIONAL eis shift right or left of two combined registers

# System calls:
#
# See great resource: http://mdfs.net/Docs/Comp/Unix/pdp11/SYSCalls
#   by J.G.Hartson
#
# + use "trap X" syntax
# + somtimes the parameter is in r0 (such as exit)
# + other times the parameters directly follow inline
# + Sometimes self-modifying code and the indirect syscall are used
# + Return value in r0 if applicable


# Optimizations
# + 938 bytes = Original straight port of the THUMB code
# + 934 bytes = fix up the unaligned load code
# + 930 bytes = remove unnecessary use of r0 in output_loop, store_byte
# + 928 bytes = change mov $1 into an inc because we know existing val 0
# + 922 bytes = keep out_buffer value on top of stack
# + 906 bytes = semi-merge the prints in first-line.  In reality
#               we completely fake it so it could all be one string
#               but that would make the comparison across architectures
#               even more unfair
# + 904 bytes = make exit return 0 (was 5 before for debugging)
# + 900 bytes = replace mov 0 with clrb
# + 892 bytes = pass write_stdout param after the call
# + 890 bytes = make fallthrough from num_to_ascii be strcat

.include "logo.include"
	
# Sycscalls
.equ SYSCALL_EXIT,	1
.equ SYSCALL_READ,	3
.equ SYSCALL_WRITE,	4
.equ SYSCALL_OPEN,	5
.equ SYSCALL_CLOSE,	6

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

	# r0 = loaded_byte
	# r1 = output_buffer
	# r2 = R
	# r3 = logo 
	# r4 = byte to output
	# r5 = text_buf pointer
	# $counter = counter
	
	mov	$out_buffer,r1		# out_buffer in r1
	mov	r1,-(r6)		# save on stack for later use
	mov	$(N-F),r2       	# R is in r2
	mov	$logo,r3		# r3 points to logo data
		
decompression_loop:
	movb	(r3)+,r0   		# load a byte, increment

	bis	$0xff00,r0		# load top as a hackish 8-bit counter

test_flags:
	cmp	r3,$logo_end		# have we reached the end?
	beq	done_logo  		# if so, exit

	asr 	r0			# shift bottom bit into carry flag
	bic	$0x8000,r0		# make it a logical shift
	
	bcs	discrete_char		# if C set, we jump to discrete char

offset_length:
				# load an unaligned little-endian word
				# and increment pointer by two
				
				# this has match_length and match_position

	movb	(r3)+,r4	# load byte1
	movb	(r3)+,r5	# load byte2
	bic	$0xff00,r4	# undo sign-extension
	ash	$0x8,r5		# shift byte high
	bisb	r4,r5		# or together
	

	mov	r5,r4		# copy r5 to r4
	
				# no need to mask r5, as we do it
				# by default in output_loop

	ash	$-P_BITS,r4	# shift right (negative) p-bits
	bic	$0xffc0,r4      # mask because arith shift	
	add	$(THRESHOLD+1),r4

	mov	r4,counter

				# counter = (r4 >> P_BITS) + THRESHOLD + 1
				#                       (=match_length)

output_loop:
	    	# Position Mask <<8 + 0xff = 0x3ff
		# Inverted 16-bits is 0xfc00
		# not sure why ~ not working here
	bic 	$0xfc00,r5
					# r5 = r5 & (POSITION_MASK<<8+0xff)

	mov	r5,-(r6)		# push r5 onto stack

	add	$text_buf,r5
	movb	(r5),r4			# load byte from text_buf[]
	mov	(r6)+,r5		# restore r5 from stack
	
	inc	r5			# advance pointer in text_buf

store_byte:
	movb	r4,(r1)+		# store a byte, increment pointer


	mov	r2,-(r6)		# push r2 onto stack

	add	$text_buf,r2
	movb	r4,(r2)			# store a byte to text_buf[r]
	
	mov	(r6)+,r2		# restore r2 from stack	
	inc 	r2			# r++


		# N-1 = 1023 = 0x3ff
		# ~0x3ff = 0xfc00
	bic 	$0xfc00,r2			
					# mask r

	dec	counter			# decrement, repeat if !=0
	bne	output_loop		# sad we can't use SOB only works regs

	bit	$0x100,r0		# is bit 8 0?
	bne	test_flags		# if not, re-load flags

	br	decompression_loop

discrete_char:
	movb	(r3)+,r4		# load a byte, increment pointer
	inc	counter			# set counter to output once
					# we know it has to be zero here

	br	store_byte		# and store it

# end of LZSS code

done_logo:

	jsr	r2,write_stdout		# print the logo
	.word	out_buffer		# out_buffer is the param
		
	#==========================
	# PRINT VERSION
	#==========================
	
first_line:
	mov	(r6),r1			# point r1 to out_buffer
	
	   				# UN*X v7 has no uname syscall
					# so fake it up
	mov     $os_string,r0
	jsr	r2,strcat
					
#	mov	$ver_string,r0		# source is " Version "
	jsr	r2,strcat

#	mov	$compiled_string,r0	# source is ", Compiled "
	jsr	r2,strcat

#	mov	$compiled_date,r0       # compiled date
	jsr	r2,strcat		# call strcat_r5

#	mov	$linefeed,r0		# source is "\n"
	jsr	r2,strcat		# call strcat_r4
			
	jsr	r2,center_and_print	# center and print

	#===============================
	# Middle-Line
	#===============================

middle_line:		

	mov	(r6),r1			# point r1 to output_buffer
	
	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	trap	SYSCALL_OPEN		# call open
	.word 	cpuinfo			# cpuinfo filename
	.word 	0			# 0 = O_RDONLY
	
					# result returned in r0
					
	mov	r0,r3			# save our fd
	
	trap	SYSCALL_READ
	.word	disk_buffer
	.word	4096

	mov	r3,r0			# restore fd
	trap	SYSCALL_CLOSE  		# close (to be correct)


	#=============
	# Number of CPUs
	#=============
number_of_cpus:

	mov	$one,r0			# Assume one processor
	jsr	r2,strcat

	#=========
	# MHz
	#=========
print_mhz:
	
	# We don't have MHz

	#=========
	# Chip Name
	#=========
chip_name:
	
	mov	$('t'<<8+'y'),r4
	mov	$('p'<<8+'e'),r5
	jsr	r2,find_string		# find 'type\t: ' and grab up to '\n'

	mov	$processor,r0		# print " Processor, "
	jsr	r2,strcat		
	
	#========
	# RAM
	#========
print_ram:	
	# not sure how you know how much RAM on pdp-11
	# let's assume 64kB

	# Amount of RAM in r4:r5

	mov	$0x1,r4
	clr	r5     			# size in bytes of RAM r4:r5
	ashc	$-10,r4			# divide by 1024 to get K

	mov	$1,r4
	jsr	r2,num_to_ascii

	mov	$ram_comma,r0		# print 'K RAM, '
	jsr	r2,strcat		# call strcat

	#========
	# Bogomips
	#========
print_bogomips:

	mov     $('M'<<8+'I'),r4
	mov	$('P'<<8+'S'),r5
	jsr	r2,find_string		# find 'MIPS\t: ' and grab up to '\n'

	mov	$bogo_total,r0          # print bogomips total
	jsr	r2,strcat

	jsr	r2,center_and_print	# center and print

	#=================================
	# Print Host Name
	#=================================
last_line:
	mov	(r6),r1			# copy out_buffer to r1
	
	mov     $host_string,r0
	jsr	r2,strcat      		# print host name

	jsr	r2,center_and_print	# center and print

	jsr	r2,write_stdout		# write_stdout
	.word	default_colors		# restore colors, print a few linefeeds

	#================================
	# Exit
	#================================
exit:
        clr	r0			# exit syscall takes param in r0
	trap	$SYSCALL_EXIT


	#=================================
	# FIND_STRING 
	#=================================
	# r4,r5 = string to find
	# writes to r1
	# r0,r3 trashed
	
find_string:
	mov	$disk_buffer,r3		# look in cpuinfo buffer
find_loop:
	movb	(r3)+,compare+1
	beq	almost_done   		# leave if we hit 0	
	mov	r3,-(r6)       		# push next r3 on stack
	movb	(r3)+,compare
	movb	(r3)+,compare2+1
	movb	(r3)+,compare2	
	mov	(r6)+,r3		# restore r3 from stack

	cmp	r4,@$compare		# see if first 2 bytes match	
	bne	find_loop
	
	cmp	r5,@$compare2		# see if next 2 bytes match	
	bne	find_loop

find_colon:
	movb	(r3)+,r0	        # load a byte
	cmpb	r0,$':'
	bne	find_colon		# repeat till we find colon

	inc	r3			# skip the space
		
store_loop:
	cmpb	(r3),$'\n'
	beq	almost_done
	movb	(r3)+,(r1)+		# load/store byte, incrementing both
	br	store_loop
	
almost_done:
	clrb	(r1)	       		# replace last value with NUL	
	
done:
     	rts	r2			# return


	#==============================
	# center_and_print
	#==============================
	# r1 = end of string
	# string to center at output_buffer

center_and_print:

	jsr	r2,write_stdout
	.word	escape	       		# we want to output ^[[
	
str_loop2:
	sub	$out_buffer,r1
	neg	r1
	add	$81,r1

	bmi	done_center		# if result negative, don't center

	asr	r1			# divide by 2

	mov	r1,r5
	clr	r4			# print to stdout
	jsr	r2,num_to_ascii		# print number of spaces

	jsr	r2,write_stdout		# write_stdout
	.word	C			# writing out "C"

done_center:
	jsr	r2,write_stdout		# write_stdout
	.word	out_buffer		# writing out out_buffer
	rts	r2
	
	#=============================
	# num_to_ascii
	#=============================
	# r5 = value to print
	# r4 = 0=stdout, 1=strcat
	# r3 trashed
	
num_to_ascii:
	mov  	r4,-(r6)		# store r4 on stack	
	
	mov  	$(ascii_buffer+9),r3	# point to end of our buffer

div_by_10:
	clr	r4			# clear the top of the 32-bit
					# number we are dividing by
					
	div	$10,r4			# divide by 10
					# Q in r4
					# R in r5

	add	$0x30,r5		# convert R to ascii
	movb	r5,-(r3)		# store a byte, decrement

	mov	r4,r5		# move Q in for next divide, update flags
	bne	div_by_10	# if Q not zero, loop
	
write_out:
	mov	(r6)+,r4	# restore r4 from stack
	
	bne	num_strcat	# if r4==1 then strcat
	
num_stdout:
	mov	r3,output_val
	jsr	r2,write_stdout		# jump to stdout
output_val:
	.word	0
	rts	r2

num_strcat:
	mov	r3,r0
		     			# fall through to strcat


	#================================
	# strcat
	#================================
	# value to cat in r0
	# output buffer in r1
	# return value in r2
	
strcat:
	movb	(r0)+,(r1)+		# load and store byte, increment both
	bne	strcat			# loop if not zero
	dec	r1			# point to before terminating nul
	rts	r2			# return

	#================================
	# WRITE_STDOUT
	#================================
	# (r2)+: has pointer to string
	# r0 trashed

write_stdout:

	mov  	(r2),r0			# get string addr from after
					# jump instruction
	mov	r0,write_val		# store in proper place

str_loop:
	tstb	(r0)+			# test if byte is 0
	bne	str_loop		# if not, loop incrementing
	
	sub	(r2)+,r0		# subtract to get length in r0
					# also point return address
					# to be after our call
					
	mov	r0,write_count		# move r0 to our count location

	mov	$STDOUT,r0		# fd passed in r0
	trap	SYSCALL_WRITE		# call syscall
write_val:
	.word 	0			# pointer to string goes here
write_count:	
	.word 	2			# count goes here

	rts	r2			# return


#===========================================================================
#	section .data
#===========================================================================
#.data
os_string:	.asciz	"UN*X "
ver_string:	.asciz	"Version 7"
compiled_string:.asciz	", Compiled "
compiled_date:	.asciz  "Fri Jun 8 10:00:00 EDT 1979"
linefeed:	.asciz	"\n"
one:		.asciz	"One "
processor:	.asciz	" Processor, "
ram_comma:	.asciz	"K RAM, "
bogo_total:	.asciz	" Bogomips Total\n"
host_string:	.asciz	"esw"

default_colors:	.asciz "\033[0m\n\n"
escape:		.asciz "\033["
C:		.asciz "C"

.ifdef FAKE_PROC
cpuinfo:	.asciz  "proc/cp.pdp11"
.else
cpuinfo:	.asciz	"/proc/cpuinfo"
.endif


.include	"logo.lzss_new"


#============================================================================
#	section .bss
#============================================================================
.bss
.lcomm counter,2
.lcomm compare,2
.lcomm compare2,2
.lcomm ascii_buffer,10
.lcomm text_buf, (N+F-1)
.lcomm	disk_buffer,4096	# we cheat!!!!
.lcomm	out_buffer,16384


