#
#  linux_logo in RISCV+RVM+RVC "compressed" 64-bit assembler 0.49
#
#  By:
#       Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -march=rv64imc -o ll.riscv.o ll.riscv.s"
#  link with         "ld -o ll.riscv ll.riscv.o"

.include "logo.include"

# This implementation is a lot like mips16

# New 16-bit instructions:
# C.LWSP/C.LDSP - load from stack
# C.SWSP/C.SDSP - store to stack
# C.LW/C.LD
# C.SW/C.SD
# C.J/C.JAL
# C.BEQZ/C.BNEZ
# C.LI/C.LUI
# C.ADDI/C.ADDIW/C.ADDI16SP
# C.SLLI/C.SRLI
# C.ANDI
# C.MV
# C.ADD
# C.AND/C.OR/C.XOR/C.SUB/C.ADDW/C.SUBW

# ASSEMBLER HASSLES:
#  + Same addressing problems in regular riscv
#  + Couldn't get C.JAL to work?



# Registers:
#  Works for s0,s1,a0,a1,a2,a3,a4,a5

#
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

# Optimization:
#  + LZSS
#    - 94 bytes = original port of riscv64 code
#    - 88 bytes = change registers used to fit in the magical 8

#  + Overall
#    - 1059 bytes = original port of riscv64 code
#    - 1091 bytes = after the lzss optimization
#    - 1061 bytes = sort out the fallout from the lzss fix
#    - 1059 bytes = move "strcat" to a reg and jalr to it

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


	# hacks as the riscv assembler won't let you do pointer math

	la	s5,data_begin	# s0 = .data segment begin
	#la	s4,bss_begin	# s1 = .bss segment begin
	addi	s4,s5,0x17c	# (bss_begin-data_begin)

	la	s9,out_buffer	# too big for 12-bit offset

	move	s0,s9		# out buffer

	#la	s1,logo
	addi	s1,s5,0x5a	# (logo-data_begin)
	li	a2,(N-F)	# a2 = R
	#la	t0,logo_end
	addi	t0,s1,0x11b	# (logo-data_end)

	la	s6,text_buf
	addi	s6,s4,550	# (text_buf-bss_start)

	# lots of extraneous registers to waste
	# feels a bit cheating to optimize the size of lzss at
	#	the expense of overall program size

	li	s10,0xff00
	li	s11,0xff


decompression_loop:
	lbu	a4,0(s1)	# load a logo byte
	addi	s1,s1,1		# increment pointer
	or	a4,a4,s10	# load upper 8 bits as hacky counter

test_flags:
	beq	s1,t0,done_logo	# have we reached the end?
				# if so, exit

	andi	a3,a4,0x1	# check low bit

	srli	a4,a4,1		# done with bit, shift to right
	bnez	a3,discrete_char
				# if low bit set
				# we have a discrete char

offset_length:
	lhu	a0,0(s1)	# load an unagligned halfword
	addi	s1,s1,2		# increment pointer

	srli	a1,a0,P_BITS
	addi	a1,a1,THRESHOLD+1

				# a1 = (a0 >> P_BITS) + THRESHOLD + 1
				#                       (=match_length)

output_loop:
	andi	a0,a0,((POSITION_MASK<<8)+0xff)
	                                # mask it

	add	a3,s6,a0
	lbu 	a5,0(a3)		# load byte from text_buf[]
	addi	a0,a0,1			# increment pointer in text_buf

store_byte:
	sb	a5,0(s0)		# store a byte to output
	addi	s0,s0,1			# increment pointer

	add	a3,s6,a2
	sb	a5,0(a3)		# store a byte to text_buf[r]
	addi	a2,a2,1			# increment pointer (r)

	addi	a1,a1,-1		# decement count
	andi	a2,a2,(N-1)		# wrap R if too big
	bnez 	a1,output_loop		# repeat until k>j

	bne	a4,s11,test_flags	# have we shifted by 8 bits?
					# if so t1 is now 0xff
					# and we need new flags
	j	decompression_loop

discrete_char:
	lbu	a5,0(s1)	# load a byte
	addi	s1,s1,1		# increment pointer
	li	a1,1		# we set t3 to one so byte
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

	la	s6,strcat

	addi	a0,s4,32			# (uname_info-bss_start)
	li	a7,SYSCALL_UNAME
	ecall			 		# do syscall

	move	s5,s9				# point s5 to out_buffer

	addi	s3,s4,32+U_SYSNAME		# os-name from uname "Linux"

	jalr	s6				# call strcat

#	la	s3,ver_string			# source is " Version "
	move	s3,s0				# (ver_string-data_begin)

	jalr 	s6			        # call strcat

	addi	s3,s4,32+U_RELEASE		# version from uname,
						#   ie "2.6.20"
	jalr	s6				# call strcat

#	la	s3,compiled_string		# source is ", Compiled "
	addi	s3,s0,10			# (compiled_string-data_begin)

	jalr	s6				#  call strcat

	addi	s3,s4,32+U_VERSION		# compiled date
	jalr	s6				# call strcat

	jal	center_and_print		# center and print

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

	#la	a1,cpuinfo		# '/proc/cpuinfo'
	addi	a1,s0,0x47		# (cpuinfo-data_begin)

	li	a2,0			# 0 = O_RDONLY <bits/fcntl.h>
	li	a7,SYSCALL_OPENAT
	ecall

					# syscall.  return in a0?
	move	a5,a0			# save our fd
	#la	a1,disk_buffer
	addi	a1,s4,0x628		# (disk_buffer-bss_begin)
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

	#la	s3,one			# cheat and assume one cpu
					# not necessarily a good assumption
	addi	s3,s0,0x55		# (one-data_begin)

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

	#la	s3,processor		# print " Processor, "
	addi	s3,s0,0x16		# (processor-data_begin)
	jal	strcat

	#========
	# RAM
	#========
ram:
	#la	a0,sysinfo_buff
	addi	a0,s4,0x1a8		# (sysinfo_buff-bss_start)

	move	t0,a0
	li	a7,SYSCALL_SYSINFO
	ecall				# sysinfo() syscall

	ld	t0,S_TOTALRAM(t0)	# size in bytes of RAM

	srli	t4,t0,20		# divide by 1024*1024 to get M

	li	a0,1
	jal 	num_to_ascii		# print to string

	#la	s3,ram_comma		# print 'M RAM, '
	add	s3,s0,0x23		# (ram_comma-data_begin)
	jal	strcat			# call strcat


	#==========
	# Bogomips
	#==========
bogomips:
	li	t0,( ('S'<<24) | ('P'<<16) | ('I'<<8) | 'M')
	li	t3,'\n'
	jal	find_string		# Find MIPS then get to \n

	#la	s3,bogo_total
	addi	s3,s0,0x2b		# (bogo_total-data_start)
	jal	strcat			# print bogomips total

	jal	center_and_print	# center and print

	#=================================
	# Print Host Name
	#=================================
last_line:
	move	s5,s9			# point s5 to out_buffer

	addi	s3,s4,32+U_NODENAME	# host name from uname()
	jal	strcat			# call strcat

	jal	center_and_print	# center and print

	#la	a1,default_colors	# restore colors, print a few linefeeds
	addi	a1,s0,0x3b		# (default_colors-data_start)

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
	#la	t6,disk_buffer	# look in cpuinfo buffer
	addi	t6,s4,0x628	# (disk_buffer-bss_start)
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
	# string to center in output buffer (s9)
	# s5 coming in is end of string to print

center_and_print:
	move	a6,ra			# save return address

	li	t2,0x0a
	sh	t2,0(s5)		# put linefeed at end

	sub	t1,s5,s9		# subtract end pointer to get length
	li	t0,80

	bge	t1,t0,done_center	# don't center if >80

	sub	t0,t0,t1		# t0=80-length
	srli	t4,t0,1			# divide by two

	#la	a1,escape
	addi	a1,s0,0x42		# (escape-data_start)

	jal	write_stdout		# print an escape character

	li	a0,0			# print to stdout
	jal	num_to_ascii		# print num spaces

	#la	a1,C			# print "C"
	addi	a1,s0,0x45		# (C-data_start)
	jal	write_stdout

done_center:
	move	a1,s9			# point to string to print

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
	ret					# return


	##############################
	# num_to_ascii
	#############################
	# t4 = value to print
	# a0 = 0=stdout, 1=strcat

num_to_ascii:
	#la	a1,ascii_buffer+10	# point to end of ascii buffer
	addi	a1,s4,0+10		# (bss_begin-ascii_buffer)+10

div_by_10:
	addi	a1,a1,-1		# point back one
	li	t0,10			# divide by 10

	remu	t3,t4,t0		# remainder in t3
	divu	t4,t4,t0		# quotient in t4

	addi	t3,t3,0x30		# convert to ascii
	sb	t3,0(a1)		# store the byte
	bnez	t4,div_by_10		# if Q not zero, loop

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
.lcomm	ascii_buffer,32
.lcomm	uname_info,(65*6)
.lcomm	sysinfo_buff,(128)
.lcomm	text_buf, N		# typically 1024
.lcomm	disk_buffer,4096	# we cheat!!!!
.lcomm	out_buffer,16384

	# see /usr/src/linux/include/linux/kernel.h
