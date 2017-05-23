#
#  linux_logo in RISCV 64-bit assembler 0.49
#
#  By:
#       Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -o ll.riscv.o ll.riscv.s"
#  link with         "ld -o ll.riscv ll.riscv.o"

.include "logo.include"

# Registers:
# UGH! They seem to have changed this mapping at least once
#	and some documents online have the old version

#	32 general purpose registers:
#		x0/zero:	always zero
#		x1/ra:		return address
#		x2/sp		stack pointer
#		x3/gp:		global pointer
#		x4/tp:		thread pointer
#		x5-x7/t0-t2	temp
#		x8/s0/fp	frame pointer
#		x9/s1		saved
#		x10-x11/a0-a1	function args/returns
#		x12-17/a2-a7	arguments
#		x18-27/s2-s11	saved
#		x28-x31/t3-t6	temporary
#	32 floating point registers
#	32 priviledged registers

# Syscalls:    
#	arguments in a0-a7, number in a7.  Result in a0?
#	was "scall" but now is "ecall"?

# Multiply/Div : optional
# Little Endian, optionally Big endian
# Misaligned memory OK

# Instruction set (not-surprisingly) is very MIPS like, just w/o delay slot
# fused compare/branch, no condition flags

# 64-bit Instructions have a *W variant that operates on low 32-bits
# The top 32 bits are sign extension of bottom 32-bits

# Instructions:
#	ADDI -- add immediate (12-bit)
#	ANDI/ORI/XORI	-- immediate logical (12 bit, sign extended)
#	SLTI/SLTIU -- set less than -- set to 1 if register less than immediate
#	SLLI/SRLI/SRAI - immediate shifts
#	LUI - load upper immediate, load top 20 bits in reg, zero out bottom
#	AUIPC - add upper immediate to PC
#	ADD -- add
#	AND/OR/XOR -- logical
#	SLT/SLTU - set if less than
#	SLL/SRL/SRA -- shifts
#	ADD	-- add
#	SUB -- subtract
#	LD/LW/LH/LB	-- load sign extend 64/32/16/8
#	LWU/LHU/LBU	-- load zero extend 32/16/8
#	NOP -- just an addi 0,0,0
#	JAL -- jump and link, can be to any reg but typically x1 and x5 target
#	JALR -- jump and link register
#	BEQ/BNE -- branch if equal/not equal
#	BLT/BLTU -- branch less than
#	BGE/BGEU -- branch greater than
#	Should use JALR rd=0 for unconditional branch rather than BEQ
#	Multiply/Divide are optional
#	MUL,MULH,MULU,MULHU,MULHSU
#	DIV/DIVU/REM/REMU

# Optimization:
#  + LZSS
#    - ??? bytes = original port of ARM64 code
#  + Overall
#    - ???? bytes = original working version

# offsets into the results returned by the uname syscall
.equ U_SYSNAME,0
.equ U_NODENAME,65
.equ U_RELEASE,65*2
.equ U_VERSION,(65*3)
.equ U_MACHINE,(65*4)
.equ U_DOMAINNAME,65*5

# offset into the results returned by the sysinfo syscall
# uptime=8 bytes, loads = 3*8 bytes, then totalram
.equ S_TOTALRAM,32

# Sycscalls
# used generic Linux syscall numbers
.equ SYSCALL_EXIT,	93
.equ SYSCALL_READ,	63
.equ SYSCALL_WRITE,	64
.equ SYSCALL_OPENAT,	56
.equ SYSCALL_CLOSE,	57
.equ SYSCALL_SYSINFO,	179
.equ SYSCALL_UNAME,	160

# From linux/fcntl.h
.equ AT_FDCWD,		-100

#
.equ STDIN,	0
.equ STDOUT,	1
.equ STDERR,	2

	.globl	_start
_start:

	#=========================
	# PRINT LOGO
	#=========================

# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver

#	adr	x1,out_buffer	# x1 = buffer we are printing to
#	adr	x3,logo		# x3 = logo begin
#	adr	x8,logo_end	# x8 = logo end
#	adr	x9,text_buf	# x9 = text_buf, guaranteed bottom N+1 bits are 0
#	add	x2,x9,#(N-F)	# x2 = &text_buf[R] (starts as N-F)

decompression_loop:
#	ldrb	w5,[x3],#1	# load a byte, increment pointer
#	orr	w5,w5,#0xff00	# load top as a hackish 8-bit counter

test_flags:
#	cmp	x3,x8		# have we reached the end?
#	b.ge	done_logo  	# if so, exit

#	tbz	x5,#0,offset_length	# if low bit not set
					# jump to offset_length

discrete_char:
#	ldrb	w4,[x3],#+1	# load a byte, increment pointer
#	mov	x6,#1		# we set r6 to one so byte
				# will be output once

#	b.ne	store_byte	# and store it


offset_length:
#	ldrh	w7,[x3],#+2	# load an unagligned halfword, increment

				# no need to mask x7, as we do it
				# by default in output_loop

#	mov	x0,#(THRESHOLD+1)
#	add	x6,x0,x7,LSR #(P_BITS)
				# r6 = (r7 >> P_BITS) + THRESHOLD + 1
				#                       (=match_length)

output_loop:
#	and	x7,x7,#((POSITION_MASK<<8)+0xff)
	                                # mask it
#	ldrb 	w4,[x9,x7]		# load byte from text_buf[]
#	add	x7,x7,#1		# advance pointer in text_buf

store_byte:
#	strb	w4,[x1],#+1		# store a byte, increment pointer
#	strb	w4,[x2],#+1		# store a byte to text_buf+r, increment pointer
#	bic 	x2,x2,#N		# clear any overflow

#	subs	x6,x6,#1		# decement count
#	b.ne 	output_loop		# repeat until k>j

#	lsr 	x5,x5,#1		# shift for next time

#	tbnz	w5,#8,test_flags	# have we shifted by 8 bits?
					# if so bit 8 is clear and
					# we need new flags
#	b	decompression_loop



# end of LZSS code

done_logo:
#	adr	x1,out_buffer		# buffer we are printing to

#	bl	write_stdout		# print the logo

	#==========================
	# PRINT VERSION
	#==========================
first_line:

#	adr	x0,uname_info			# uname struct
#	mov	x8,#SYSCALL_UNAME
#	svc	0		 		# do syscall

#	adr	x1,uname_info			# os-name from uname "Linux"

#	adr	x10,out_buffer			# point x10 to out_buffer

#	bl	strcat				# call strcat

#	adr	x1,ver_string			# source is " Version "
#	bl 	strcat			        # call strcat

#	adr	x1,(uname_info+U_RELEASE)	# version from uname, 
						#   ie "2.6.20"
#	bl	strcat				# call strcat

#	adr	x1,compiled_string		# source is ", Compiled "
#	bl	strcat				#  call strcat

#	adr	x1,(uname_info+U_VERSION)	# compiled date
#	bl	strcat				# call strcat

#	mov	x3,#0xa
#	strh	w3,[x10],#+2		# store a linefeed, and NULL,
					# increment pointer

#	bl	center_and_print	# center and print

	#===============================
	# Middle-Line
	#===============================
middle_line:
	#===============================
	# Load /proc/cpuinfo into buffer
	#===============================

#	adr	x10,out_buffer		# point x10 to out_buffer

	# regular SYSCALL_OPEN not supported on arm64?

#	mov	x0,#AT_FDCWD		# dirfd.  AT_FDWCD is old open behavior

#	adr	x1,cpuinfo		# '/proc/cpuinfo'
#	mov	x2,#0			# 0 = O_RDONLY <bits/fcntl.h>
#	mov	x8,#SYSCALL_OPENAT
#	svc	0

					# syscall.  return in x0?
#	mov	x5,x0			# save our fd
#	adr	x1,disk_buffer
#	mov	x2,#4096	 	# cheat and assume maximum of 4kB
#	mov	x8,#SYSCALL_READ
#	svc	0

#	mov	x0,x5
#	mov	x8,#SYSCALL_CLOSE
#	svc	0			# close (to be correct)


	#=============
	# Number of CPUs
	#=============
number_of_cpus:

#	adr	x1,one			# cheat and assume one cpu
					# not really a good assumption
#	bl	strcat

	#=========
	# MHz
	#=========
print_mhz:

	# the arm system I have does not report MHz

	#===========
	# Chip Name
	#===========
chip_name:
#	ldr	w0,=( ('c'<<24) | ('o'<<16) | ('r'<<8) | 'P')
#	mov	x3,#' '
#	bl	find_string		# find line starting with Proc
					# and grab up to ' '

#	adr	x1,processor		# print " Processor, "
#	bl	strcat

	#========
	# RAM
	#========

#	adr	x0,sysinfo_buff
#	mov	x3,x0
#	mov	x8,#SYSCALL_SYSINFO
#	svc	0
					# sysinfo() syscall

#	ldr	x3,[x3,#S_TOTALRAM]	# size in bytes of RAM
#	lsr	x3,x3,#20		# divide by 1024*1024 to get M
#	adc	x3,x3,#0		# round

#	mov	x0,#1
#	bl num_to_ascii			# print to string

#	adr	x1,ram_comma		# print 'M RAM, '
#	bl	strcat			# call strcat


	#==========
	# Bogomips
	#==========

#	ldr	w0,=( ('S'<<24) | ('P'<<16) | ('I'<<8) | 'M')
#	mov	x3,#'\n'
#	bl	find_string		# Find MIPS then get to \n

#	adr	x1,bogo_total
#	bl	strcat			# print bogomips total

#	bl	center_and_print	# center and print

	#=================================
	# Print Host Name
	#=================================
last_line:
#	adr	x10,out_buffer		# point x10 to out_buffer

#	adr	x1,(uname_info+U_NODENAME)
					# host name from uname()
#	bl	strcat			# call strcat

#	bl	center_and_print	# center and print

#	adr	x1,default_colors	# restore colors, print a few linefeeds
#	bl	write_stdout


	#================================
	# Exit
	#================================
exit:
	li	a0,5				# result
	li	a7,SYSCALL_EXIT			# Why can't we use v0?
	ecall					# and exit


	#=================================
	# FIND_STRING
	#=================================
	# x0 = string to find
	# x3 = char to end at
	# x5 trashed
find_string:
#	adr	x7,disk_buffer	# look in cpuinfo buffer
find_loop:
#	ldr	w5,[x7],#+1	# load a byte, increment pointer
#
#	cbz	w5,done		# are we at EOF?
				# if so, done

#	cmp	w5,w0		# compare against first byte

#	b.ne	find_loop	# if no match, then loop

find_colon:
#	ldrb	w5,[x7],#+1	# load a byte, increment pointer
#	cmp	x5,#':'
#	b.ne	find_colon	# repeat till we find colon

store_loop:
#	ldrb	w5,[x7,#+1]!	# load a byte, increment pointer
				# by using pre-indexed increment
				# we skip the leading space

#	strb	w5,[x10],#+1	# store a byte, increment pointer
#	cmp	x5,x3
#	b.ne	store_loop

almost_done:
#	strb	wzr,[x10],#-1	# replace last value with NUL

done:
#	ret			# return


	#==============================
	# center_and_print
	#==============================
	# string to center in at output_buffer

center_and_print:

#	str	x30,[sp,#-16]!		# store return address on stack

#	adr	x1,escape		# we want to output ^[[
#	bl	write_stdout

str_loop2:
#	adr	x2,out_buffer		# point r2 to out_buffer
#	sub	x2,x10,x2		# get length by subtracting

#	mov	x0,#81
#	subs	x2,x0,x2		# no reverse substract arm64!

#	b.mi	done_center		# if result negative, don't center

#	lsr	x3,x2,#1		# divide by 2
#	adc	x3,x3,#0		# round?

#	mov	x0,#0			# print to stdout
#	bl	num_to_ascii		# print number of spaces

#	adr	x1,C			# we want to output C

#	bl	write_stdout

done_center:
#	adr	x1,out_buffer		# point x1 to out_buffer

#	ldr	x30,[sp],#16		# restore return address from stack

	#================================
	# WRITE_STDOUT
	#================================
	# x1 has string
	# x0,x2,x3 trashed
write_stdout:
#	mov	x2,#0				# clear count

str_loop1:
#	add	x2,x2,#1
#	ldrb	w3,[x1,x2]
#	cbnz	w3,str_loop1			# repeat till zero

write_stdout_we_know_size:
#	mov	x0,#STDOUT			# print to stdout
#	mov	x8,#SYSCALL_WRITE
#	svc	0		 		# run the syscall
#	ret					# return


	##############################
	# num_to_ascii
	#############################
	# x3 = value to print
	# x0 = 0=stdout, 1=strcat

num_to_ascii:
#	stp	x10,x30,[sp,#-16]!	# store return address on stack
#	adr	x10,ascii_buffer+10	# point to end of our buffer

div_by_10:
	# Divide by 10
	# x3=numerator
	# x7=quotient    x8=remainder
	# x5=trashed

#	mov	x5,#10
#	udiv	x7,x3,x5	# Q=x7=x3/10
#	umsubl	x8,w7,w5,x3	# R=x8=x3-(w7*10)

#	add	x8,x8,#0x30	# convert to ascii
#	strb	w8,[x10],#-1	# store a byte, decrement pointer
#	adds	x3,x7,#0	# move Q in for next divide, update flags
#	b.ne	div_by_10	# if Q not zero, loop

write_out:
#	add	x1,x10,#1		# adjust pointer
#	ldp	x10,x30,[SP],#16	# restore return address from stack

#	cbz	x0,write_stdout		# if 0, write_stdout

					# else, strcat

	#================================
	# strcat
	#================================
	# value to cat in x1
	# output buffer in x10
	# x3 trashed
strcat:
#	ldrb	w3,[x1],#+1		# load a byte, increment pointer
#	strb	w3,[x10],#+1		# store a byte, increment pointer
#	cbnz	w3,strcat		# is not NUL, loop
#	sub	x10,x10,#1		# point to one less than null
#	ret				# return


literals:
# Put literal values here
#.ltorg


#===========================================================================
#	section .data
#===========================================================================
.data
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
processor:	.ascii	" Processor, \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\n\0"

default_colors:	.ascii "\033[0m\n\n\0"
escape:		.ascii "\033[\0"
C:		.ascii "C\0"

.ifdef FAKE_PROC
cpuinfo:	.ascii  "proc/cp.arm64\0"
.else
cpuinfo:	.ascii	"/proc/cpuinfo\0"
.endif

one:	.ascii	"One \0"


.include	"logo.lzss_new"


#============================================================================
#	section .bss
#============================================================================
.bss
.align	(P_BITS+1)
.lcomm	text_buf, N
.lcomm	disk_buffer,4096	## we cheat!!!!
.lcomm	out_buffer,16384
.lcomm	uname_info,(65*6)
.lcomm	sysinfo_buff,(64)
.lcomm	ascii_buffer,32


	# see /usr/src/linux/include/linux/kernel.h

