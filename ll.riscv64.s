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
#    - 120 bytes = move text_buf to dedicated register
#    - 116 bytes = move back to 0xff in high bits for telling when shift done
#
#  + Overall
#    - 1277 bytes = original working version
#    - 1261 bytes = reserve register to hold out_buffer
#    - 1249 bytes = use register to hold uname pointer
#    - 1233 bytes = remove much of "la" use before lzss

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
	#la	s1,bss_begin	# s1 = .bss segment begin
	addi	s1,s0,0x17c	# (bss_begin-data_begin)

	li	s2,(N-F)	# s2 = R

	# hack as the riscv assembler won't let you do pointer math

	#la	s3,logo
	addi	s3,s0,0x5a		# (logo-data_begin)

	#la	s4,logo_end
	addi	s4,s3,0x11b		# (logo-data_end)

	la	s9,out_buffer		# too big for 12-bit offset
	move	s5,s9

	# lots of extraneous registers to waste
	# feels a bit cheating to optimize the size of lzss at
	#	the expense of overall program size

	#la	s6,text_buf
	move	s6,s1
	li	s10,0xff00
	li	s11,0xff

decompression_loop:
	lbu	t1,0(s3)	# load a logo byte
	or	t1,s10,t1	# load upper 8 bits as hacky counter
	addi	s3,s3,1		# increment pointer

test_flags:
	beq	s4,s3,done_logo	# have we reached the end?
				# if so, exit

	andi	t2,t1,0x1	# check low bit

	srli	t1,t1,1		# done with bit, shift to right
	bnez	t2,discrete_char
				# if low bit set
				# we have a discrete char

offset_length:
	lhu	t4,0(s3)	# load an unagligned halfword
	addi	s3,s3,2		# increment pointer

	srli	t3,t4,P_BITS
	addi	t3,t3,THRESHOLD+1

				# t3 = (t4 >> P_BITS) + THRESHOLD + 1
				#                       (=match_length)

output_loop:
	andi	t4,t4,((POSITION_MASK<<8)+0xff)
	                                # mask it

	add	t0,s6,t4
	lbu 	t0,0(t0)		# load byte from text_buf[]
	addi	t4,t4,1			# increment pointer in text_buf

store_byte:
	sb	t0,0(s5)		# store a byte to output
	addi	s5,s5,1			# increment pointer

	add	t5,s6,s2
	sb	t0,0(t5)		# store a byte to text_buf[r]
	addi	s2,s2,1			# increment pointer (r)

	addi	t3,t3,-1		# decement count
	andi	s2,s2,(N-1)		# wrap R if too big
	bnez 	t3,output_loop		# repeat until k>j

	bne	t1,s11,test_flags	# have we shifted by 8 bits?
					# if so t1 is now 0xff
					# and we need new flags
	j	decompression_loop

discrete_char:
	lbu	t0,0(s3)	# load a byte
	addi	s3,s3,1		# increment pointer
	li	t3,1		# we set t3 to one so byte
				# will be output once

	j	store_byte	# and store it

# end of LZSS code

done_logo:
	move	a1,s9
	jal	write_stdout		# print the logo

	#==========================
	# PRINT VERSION
	#==========================
first_line:

	la	s7,uname_info			# uname struct
	move	a0,s7

	li	a7,SYSCALL_UNAME
	ecall			 		# do syscall

	move	s5,s9				# point s5 to out_buffer

	move	s3,s7				# os-name from uname "Linux"

	jal	strcat				# call strcat

	la	s3,ver_string			# source is " Version "
	jal 	strcat			        # call strcat

	addi	s3,s7,U_RELEASE			# version from uname,
						#   ie "2.6.20"
	jal	strcat				# call strcat

	la	s3,compiled_string		# source is ", Compiled "
	jal	strcat				#  call strcat

	addi	s3,s7,U_VERSION			# compiled date
	jal	strcat				# call strcat

	jal	center_and_print	# center and print

	#===============================
	# Middle-Line
	#===============================
middle_line:
	#===============================
	# Load /proc/cpuinfo into buffer
	#===============================

	move	s5,s9			# point s5 to out_buffer

	# regular SYSCALL_OPEN not supported on new machines?

	li	a0,AT_FDCWD		# dirfd.  AT_FDWCD is old open behavior

	la	a1,cpuinfo		# '/proc/cpuinfo'
	li	a2,0			# 0 = O_RDONLY <bits/fcntl.h>
	li	a7,SYSCALL_OPENAT
	ecall

					# syscall.  return in a0?
	move	a5,a0			# save our fd
	la	a1,disk_buffer
	li	a2,4096	 	# cheat and assume maximum of 4kB
	li	a7,SYSCALL_READ
	ecall

	move	a0,a5
	li	a7,SYSCALL_CLOSE
	ecall				# close (to be correct)


	#=============
	# Number of CPUs
	#=============
number_of_cpus:

	la	s3,one			# cheat and assume one cpu
					# not necessarily a good assumption
	jal	strcat

	#=========
	# MHz
	#=========
print_mhz:

	# the arm system I have does not report MHz

	#===========
	# Chip Name
	#===========
chip_name:
	li	t0,(('l'<<24) | ('e'<<16) | ('d'<<8) | 'o')
	li	t3,'\n'
	jal	find_string		# find line including "model"
					# and grab up to ' '

	la	s3,processor		# print " Processor, "
	jal	strcat

	#========
	# RAM
	#========

	la	a0,sysinfo_buff
	move	t0,a0
	li	a7,SYSCALL_SYSINFO
	ecall				# sysinfo() syscall

	ld	t0,S_TOTALRAM(t0)	# size in bytes of RAM

	srli	t4,t0,20		# divide by 1024*1024 to get M

	li	a0,1
	jal 	num_to_ascii		# print to string

	la	s3,ram_comma		# print 'M RAM, '
	jal	strcat			# call strcat


	#==========
	# Bogomips
	#==========

	li	t0,( ('S'<<24) | ('P'<<16) | ('I'<<8) | 'M')
	li	t3,'\n'
	jal	find_string		# Find MIPS then get to \n

	la	s3,bogo_total
	jal	strcat			# print bogomips total

	jal	center_and_print	# center and print

	#=================================
	# Print Host Name
	#=================================
last_line:
	move	s5,s9			# point s5 to out_buffer

	addi	s3,s7,U_NODENAME	# host name from uname()
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

	#=================================
	# FIND_STRING
	#=================================
	# t0 = string to find
	# t3 = char to end at
	# t5 trashed,t6,t1
find_string:
	la	t6,disk_buffer	# look in cpuinfo buffer
find_loop:
	lwu	t1,0(t6)	# load a byte
	addi	t6,t6,1		# increment pointer

	beqz	t1,done		# are we at EOF?
				# if so, done

	bne	t0,t1,find_loop	# if no match, then loop

find_colon:
	lbu	t5,0(t6)	# load a byte
	addi	t6,t6,1		# increment pointer
	li	t1,':'
	bne	t5,t1,find_colon	# repeat till we find colon

store_loop:
	lbu	t5,1(t6)	# load a byte (+1 to skip space)
	addi	t6,t6,1		# increment pointer

	beqz	t5,done		# stop if off send
	beq	t5,t3,done	# stop if end char

	sb	t5,0(s5)	# store a byte
	addi	s5,s5,1		# increment pointer

	j	store_loop

done:
	ret			# return


	#==============================
	# center_and_print
	#==============================
	# string to center in output buffer

center_and_print:
	move	a6,ra			# save return address
	move	t0,s5			# t0 is now end of string
	move	s5,s9			# point s5 to out_buffer

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

	beqz	a0,write_stdout		# if 0, write_stdout

					# else, strcat

	move	s3,a1

	#================================
	# strcat (stpcpy)
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

#===========================================================================
#	section .data
#===========================================================================
.data
data_begin:
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
processor:	.ascii	" Processor, \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"

default_colors:	.ascii "\033[0m\n\n\0"
escape:		.ascii "\033[\0"
C:		.ascii "C\0"

.ifdef FAKE_PROC
cpuinfo:	.ascii  "proc/cp.riscv\0"
.else
cpuinfo:	.ascii	"/proc/cpuinfo\0"
.endif

one:	.ascii	"One \0"

.include	"logo.lzss_new"


#============================================================================
#	section .bss
#============================================================================
.bss
bss_begin:
.lcomm	text_buf, N
.lcomm	disk_buffer,4096	## we cheat!!!!
.lcomm	out_buffer,16384
.lcomm	uname_info,(65*6)
.lcomm	sysinfo_buff,(128)
.lcomm	ascii_buffer,32

	# see /usr/src/linux/include/linux/kernel.h
