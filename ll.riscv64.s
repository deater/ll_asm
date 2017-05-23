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
#    - 136 bytes = original port of MIPS code
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

	la	s0,data_begin	# s0 = .data segment begin
	la	s1,bss_begin	# s1 = .bss segment begin
	li	s2,(N-F)	# s2 = R

	la	s3,logo
	la	s4,logo_end
	la	s5,out_buffer

decompression_loop:
	lbu	t1,0(s3)	# load a logo byte
	addi	s3,s3,1		# increment pointer
	li	t6,8

test_flags:
	beq	s4,s3,done_logo	# have we reached the end?
				# if so, exit

	andi	t2,t1,0x1	# check low bit

	srli	t1,t1,1		# shift
	bnez	t2,discrete_char
				# if low bit set
				# we have a discrete char

offset_length:
	lhu	t4,0(s3)	# load an unagligned halfword
	addi	s3,s3,2		# increment

	srli	t3,t4,P_BITS
	addi	t3,t3,THRESHOLD+1

				# t3 = (t4 >> P_BITS) + THRESHOLD + 1
				#                       (=match_length)

output_loop:
	andi	t4,t4,((POSITION_MASK<<8)+0xff)
	                                # mask it
	la	t0,text_buf
	add	t0,t0,t4
	lbu 	t0,0(t0)		# load byte from text_buf[]
	addi	t4,t4,1			# increment pointer in text_buf

store_byte:
	sb	t0,0(s5)		# store a byte to output
	addi	s5,s5,1			# increment pointer
	la	t5,text_buf
	add	t5,t5,s2
	sb	t0,0(t5)		# store a byte to text_buf[r]
	addi	s2,s2,1			# increment pointer (r)

	addi	t3,t3,-1		# decement count
	andi	s2,s2,(N-1)		# wrap R if too big
	bnez 	t3,output_loop		# repeat until k>j

	addi	t6,t6,-1
	bnez	t6,test_flags		# have we shifted by 8 bits?
					# if so bit 8 is clear and
					# we need new flags
	j	decompression_loop
discrete_char:
	lbu	t0,0(s3)	# load a byte
	addi	s3,s3,1		# increment pointer
	li	t3,1		# we set t3 to one so byte
				# will be output once

	j	store_byte	# and store it



# end of LZSS code

done_logo:
	la	a1,out_buffer		# buffer we are printing to
	jal	write_stdout		# print the logo

	#==========================
	# PRINT VERSION
	#==========================
first_line:

	la	a0,uname_info			# uname struct
	li	a7,SYSCALL_UNAME
	ecall			 		# do syscall

	la	s5,out_buffer			# point s5 to out_buffer

	la	s3,uname_info			# os-name from uname "Linux"

	jal	strcat				# call strcat

	la	s3,ver_string			# source is " Version "
	jal 	strcat			        # call strcat

	la	s3,(uname_info+U_RELEASE)	# version from uname,
						#   ie "2.6.20"
	jal	strcat				# call strcat

	la	s3,compiled_string		# source is ", Compiled "
	jal	strcat				#  call strcat

	la	s3,(uname_info+U_VERSION)	# compiled date
	jal	strcat				# call strcat

	jal	center_and_print	# center and print

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
	la	s5,out_buffer		# point s5 to out_buffer

	la	s3,(uname_info+U_NODENAME)
					# host name from uname()
	jal	strcat			# call strcat

	jal	center_and_print	# center and print

	la	a1,default_colors	# restore colors, print a few linefeeds
	jal	write_stdout


	#================================
	# Exit
	#================================
exit:
	li	a0,2				# result
	li	a7,SYSCALL_EXIT			# Why can't we use v0?
	ecall					# and exit


#print_hex:
#	li	a3,8
#	la	a1,hello
#hexloop:
#	addi	a3,a3,-1
#	andi	a4,a0,0xf
#	add	a4,a4,48
#	srli	a0,a0,4
#
#	sb	a4,0(a1)
#
#	addi	a1,a1,1
#	bnez	a3,hexloop


#	la	a1,hello
#	move	a6,ra
#	jal	write_stdout
#	move	ra,a6
#
#	ret

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
	# string to center in output buffer

center_and_print:
	move	a6,ra			# save return address
	move	t0,s5			# t0 is now end of string
	la	s5,out_buffer		# point s5 to beginning

	li	t2,0x0a
	sh	t2,0(t0)		# put linefeed at end

	sub	t1,t0,s5		# subtract end pointer to get length
	li	t0,80

	bge	t1,t0,done_center	# don't center if >80

	sub	t0,t0,t1		# t0=80-length
	srli	t4,t0,1			# divide by two

	la	a1,escape
	jal	write_stdout		# print an escape character

	li	a0,0			# print to stdout
	jal	num_to_ascii		# print num spaces

	la	a1,C			# print "C"
	jal	write_stdout

done_center:
	move	a1,s5			# point to string to print

	move	ra,a6			# restore return address

	# fallthrough

	#================================
	# WRITE_STDOUT
	#================================
	# a1 has string
	# a2 size
	# t1,t2 trashed
write_stdout:
	li	a2,0
	move	t1,a1				# move a1 into t1
str_loop1:
	addiw	a2,a2,1
	lbu	t2,0(t1)
	addi	t1,t1,1
	bnez	t2,str_loop1			# loop until hit NUL

write_stdout_we_know_size:
	li	a0,STDOUT			# print to stdout
	li	a7,SYSCALL_WRITE
	ecall			 		# run the syscall
	jr	ra				# return


	##############################
	# num_to_ascii
	#############################
	# t4 = value to print
	# a0 = 0=stdout, 1=strcat

num_to_ascii:
	la	a1,ascii_buffer+10	# point to end of ascii buffer

div_by_10:
	addi	a1,a1,-1		# point back one
	li	t0,10			# divide by 10

	remu	t3,t4,t0
	divu	t4,t4,t0

	addi	t3,t3,0x30	# convert to ascii
	sb	t3,0(a1)	# store the byte
	bnez	t4,div_by_10	# if Q not zero, loop

write_out:
#	add	x1,x10,#1		# adjust pointer


	beqz	a0,write_stdout		# if 0, write_stdout

					# else, strcat


	#================================
	# strcat
	#================================
	# value to cat in s3
	# output buffer in s5
	# t0 trashed
strcat:
	lbu	t0,0(s3)		# load a byte
	addi	s3,s3,1			# increment pointer
	sb	t0,0(s5)		# store a byte
	addi	s5,s5,1			# increment pointer
	bnez	t0,strcat		# loop if not zero
	add	s5,s5,-1		# point to one less than null
	ret				# return


literals:
# Put literal values here
#.ltorg


#===========================================================================
#	section .data
#===========================================================================
.data
data_begin:
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
processor:	.ascii	" Processor, \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\n\0"

default_colors:	.ascii "\033[0m\n\n\0"
escape:		.ascii "\033[\0"
C:		.ascii "C\0"

.ifdef FAKE_PROC
cpuinfo:	.ascii  "proc/cp.riscv\0"
.else
cpuinfo:	.ascii	"/proc/cpuinfo\0"
.endif

one:	.ascii	"One \0"

#hello:	.ascii	"Hello World\n\0\0\0\0\0\0\0\0\0"

.include	"logo.lzss_new"


#============================================================================
#	section .bss
#============================================================================
.bss
bss_begin:
.align	(P_BITS+1)
.lcomm	text_buf, N
.lcomm	disk_buffer,4096	## we cheat!!!!
.lcomm	out_buffer,16384
.lcomm	uname_info,(65*6)
.lcomm	sysinfo_buff,(64)
.lcomm	ascii_buffer,32

	# see /usr/src/linux/include/linux/kernel.h
