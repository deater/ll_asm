#
#  linux_logo in ARM64 "AARCH64" 64-bit assembler 0.47
#
#  By:
#       Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -o ll.arm64.o ll.arm64.s"
#  link with         "ld -o ll.arm64 ll.arm64.o"

.include "logo.include"

# Syscalls:    Use the standard generic Linux numbers
#              x0 - x7 are arguments, x8 has number, svc 0 does the call

# ARM64 is a completely new ISA with little relation to ARM32/Thumb2
#  it looks much more like a traditional RISC architecture

# ARM64 has 31 general-purpose 64-bit registers
# x0 - x30
# x30 is the link register
# x29 is the frame pointer
# The encoding of x31 is a special case that may mean zero or SP
# w0-w30 are the lower 32-bits of the X registers
# xsp/wsp and xzr/wzr can be used for zero and stack registers

# Also a 64-bit PC (program counter) and SP (stack pointer)
# Also 32 128-bit SIMD registers

# When operating on 32-bit values:
#    for source upper 32 is ignored, for destination upper 32 cleared to zero
#    right shifts/rotates bring in bit 31 not 63
#    condition flags from 32-bit not full reg


# Addressing modes
#  Base register 		[x0,#0]
#  Base plus offset		[x0,#imm]
#  Base plus register shift	[x0,x1,LSL #imm]
#  Base plus sign extended reg	[x0, W0, (S|U)XTW #imm]
#  Pre-indexed (update r0)	[x0,#imm]!
#  Post-indexed	(update r0)	[x0],#imm
#  Label			blah

# Stack pointer must be quadword-aligned

# ALU/Logic
# extended lets you sign extend one of values
#  ADD		-- add (immediate or reg or ext)
#  ADDC		-- addcarry (reg)
#  ADDCS	-- addcarry set flags (reg)
#  ADDS		-- add and set flags (imm or reg or ext)
#  SUB		-- substract (imm or reg or ext)
#  SUBS		-- substract and set flags (imm or reg or ext)
#  SBC		-- subtract with carry (reg)
#  SBCS		-- subtract with carry and set (reg)
#  CMP		-- compare (imm or reg or ext)
#  CMN		-- compare negative (imm or reg or ext)
#  NEG		-- negate (reg)
#  NEGS		-- negate and set (reg)
#  NGC		-- negate with carry (reg)
#  NGCS		-- negate with carry and set (reg)
#  AND		-- and (imm or reg)
#  ANDS		-- and and set flags (imm or reg)
#  BIC		-- bit clear (reg)
#  BICS		-- bit clear and set (reg)
#  EOR		-- exclusive or (imm or reg)
#  EON		-- exclusive or not (reg)
#  MVN		-- move not (reg) (bitwise not)
#  ORR		-- or (imm or reg)
#  ORN		-- or not (reg)
#  TST		-- test (imm or reg) (and with no update)

# Moves
#  MOVZ		-- move 16 bit with zero
#  MOVN		-- move 16-bit with invert
#  MOVK		-- move 16-bit with keep
#  MOV		-- move

# Bitfield
#  BFM		-- bitfield move
#  SBFM		-- signed bitfield move
#  UBFM		-- unsigned bitfield move
#  BFI		-- bitfield insert
#  BFXIL	-- extract and insert low
#  SBFIZ	-- signed bitfield insert zero
#  SBFX		-- signed bitfield extract
#  UBFIZ	-- unsigned bitfield insert zero
#  UBFX		-- unsigned bitfield extract
#  EXTR		-- extract register from pair

# Shifts
#  pseudo-instructions based on bitfield extract?
#  can take "V" to shift by register
#  ASR		-- airthmatic shift right
#  LSR		-- logical shift right
#  LSL		-- logical shift left
#  ROR		-- rotate right

# Sign and Zero Extend
#  SXTB/SXTH/SXTW/UXTB/UXTH

# Multiplies and Divides
#  MADD
#  MSUB
#  MNEG
#  MUL
#  SMADDL
#  SMSUBL
#  SMNEGL
#  SMULL
#  SMULH
#  UMADDL
#  UMSUBL
#  UMNEGL
#  UMULL
#  UMULH
#  SDIV
#  UDIV

# CRC instructions

# Count/Rotate Bits
#  CLS/CLZ/RBIT/REV/REV16/REV32

# Conditional Select
# Check condition flags.  If true, copy source to destination
#   If false, copy second source to desintation and perform action
#  CSEL		-- conditional select
#  CSINC	-- conditional select and increment
#  CSINV	-- conditional select and invert
#  CSNEG	-- conditional select and negate
#  CSET		-- conditional set
#  CSETM	-- conditional set and mask
#  CINC		-- conditional increment
#  CINV		-- conditional invert
#  CNEG		-- conditional negate

# Conditional Compare
#  ???
#  CCMN		-- conditional compare negative
#  CCMP		-- conditional compare

# Branches
#  B.cond	-- branch if one of below condition codes
#    EQ/NE/CS/CC/HS/LO/MI/PL/VS/VC/HI/LS/GE/LT/GT/LE/AL
#  CBNZ / CBZ	-- compare and branch if nonzero/zero
#  TBNZ / TBZ	-- test and branch if nonzero/zero (Specify bit to test)
#  B		-- branch always
#  BL		-- branch with link
#  BLR		-- branch with link to register
#  BR		-- branch to register
#  RET		-- return from subroutine

# Load/Stores
#   There are versions with "U" that force 12-bit vs 9-bit immediate
#   There are versions with "T" that force user-mode access
#   There are versions with "X" that are atomic
#   There are "A" acquire "R" release versions to avoid need for mem barrier
#  LDR		-- load register (64bit)
#  LDRB		-- load byte
#  LDRSB	-- load sign-extend byte
#  LDRH		-- load halfword
#  LDRSH	-- load sign-extend halfword
#  LDRSW	-- load 32-bit
#  STR		-- store register
#  STRB		-- store byte
#  STRH		-- store halfword

# load/store pairs
#  LDP		-- load pair
#  LDPSW	-- load pair signed word
#  STP		-- store pair
#  LDNP/STNP	-- load/store non-temporal (streaming hint)

# Load/Store Multiple
# can also have "R" to replicate
#  LD1/LD2/LD3/LD4	-- load multiple structures
#  ST1/ST2/ST3/ST4	-- store multiple structures

# Address Calc
#  ADR		-- sort of like LEA on x86
#  ADRP		-- compute PC-relative


# Prefetch
#  PRFM		-- prefetch memory
#  PRFUM	-- unscaled offset

# Exceptions
#  BRK		-- software breakpoint
#  HLT		-- halt
#  HVC		-- exception level 2
#  SMC		-- exception level 3
#  SVC		-- exception level 1
#  ERET		-- exception return

# Sytem Instructions
#  SYS		-- system
#  SYSL		-- system with return
#  IC/DC	-- instruction/data cache maintanence
#  AT		-- address translation
#  TLBI		-- TLB invalidate
#  MSR/MRC	-- move to system register

# Hints/Barriers/Synchronization
#  NOP
#  YIELD
#  WFE		-- wait for event
#  WFI		-- wait for interrupt
#  SEV/SEVL	-- send event, send event local
#  CLREX	-- clear exclusive
#  DSB/ISB/DSM  -- data/instruction/memory barrier


# All instructions fixed-with 32-bits

# Stack must always be 16-byte aligned.  No helpful
#   push instruction, though you can use ldp/stp to store two at once

# comment character is //


# Optimization:
#  + LZSS
#    - 132 bytes = original port of ARM32 code
#    - 112 bytes = use bigger immediates available with ARM64
#    - 108 bytes = use tbnz instead of separate compare and branch
#    - 100 bytes = use unaligned halfword load
#    -  96 bytes = another use of tbnz
#  + Overall
#    - 1138 bytes = original working version
#    - 1134 bytes = remove bss_start and data_start values
#    - 1130 bytes = store a halfword rather than two bytes
#    - 1114 bytes = optimize branches, zero register, in find_string
#    - 1110 bytes = use cbnz in strcat

# Overall optimization TODO:
# + cbz
# + better constants

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

	adr	x1,out_buffer	// x1 = buffer we are printing to
	mov	x2,#(N-F)	// x2 = R (starts as N-F)
	adr	x3,logo		// x3 = logo begin
	adr	x8,logo_end	// x8 = logo end
	adr	x9,text_buf	// x9 = text_buf

decompression_loop:
	ldrb	w5,[x3],#1	// load a byte, increment pointer
	orr	w5,w5,#0xff00	// load top as a hackish 8-bit counter

test_flags:
	cmp	x3,x8		// have we reached the end?
	b.ge	done_logo  	// if so, exit

	tbz	x5,#0,offset_length	// if low bit not set
					// jump to offset_length

discrete_char:
	ldrb	w4,[x3],#+1	// load a byte, increment pointer
	mov	x6,#1		// we set r6 to one so byte
				// will be output once

	b.ne	store_byte	// and store it


offset_length:
	ldrh	w4,[x3],#+2	// load an unagligned halfword, increment

	mov	x7,x4		// copy x4 to x7
				// no need to mask x7, as we do it
				// by default in output_loop

	mov	x0,#(THRESHOLD+1)
	add	x6,x0,x4,LSR #(P_BITS)
				// r6 = (r4 >> P_BITS) + THRESHOLD + 1
				//                       (=match_length)

output_loop:
	and	x7,x7,#((POSITION_MASK<<8)+0xff)
	                                // mask it
	ldrb 	w4,[x9,x7]		// load byte from text_buf[]
	add	x7,x7,#1		// advance pointer in text_buf

store_byte:
	strb	w4,[x1],#+1		// store a byte, increment pointer
	strb	w4,[x9,x2]		// store a byte to text_buf[r]
	add 	x2,x2,#1		// r++
	and 	x2,x2,#(N-1)		// mask r with N-1

	subs	x6,x6,#1		// decement count
	b.ne 	output_loop		// repeat until k>j

	lsr 	x5,x5,#1		// shift for next time

	tbnz	w5,#8,test_flags	// have we shifted by 8 bits?
					// if so bit 8 is clear and
					// we need new flags
	b	decompression_loop



# end of LZSS code

done_logo:
	adr	x1,out_buffer		// buffer we are printing to

	bl	write_stdout		// print the logo

	#==========================
	# PRINT VERSION
	#==========================
first_line:

	adr	x0,uname_info			// uname struct
	mov	x8,#SYSCALL_UNAME
	svc	0		 		// do syscall

	adr	x1,uname_info			// os-name from uname "Linux"

	adr	x10,out_buffer			// point x10 to out_buffer

	bl	strcat				// call strcat

	adr	x1,ver_string			// source is " Version "
	bl 	strcat			        // call strcat

	adr	x1,(uname_info+U_RELEASE)	// version from uname, 
						//   ie "2.6.20"
	bl	strcat				// call strcat

	adr	x1,compiled_string		// source is ", Compiled "
	bl	strcat				//  call strcat

	adr	x1,(uname_info+U_VERSION)	// compiled date
	bl	strcat				// call strcat

	mov	x3,#0xa
	strh	w3,[x10],#+2		// store a linefeed, and NULL,
					// increment pointer

	bl	center_and_print	// center and print

	#===============================
	# Middle-Line
	#===============================
middle_line:
	#===============================
	# Load /proc/cpuinfo into buffer
	#===============================

	adr	x10,out_buffer		// point x10 to out_buffer

	// regular SYSCALL_OPEN not supported on arm64?

	mov	x0,#AT_FDCWD		// dirfd.  AT_FDWCD is old open behavior

	adr	x1,cpuinfo		// '/proc/cpuinfo'
	mov	x2,#0			// 0 = O_RDONLY <bits/fcntl.h>
	mov	x8,#SYSCALL_OPENAT
	svc	0

					// syscall.  return in x0?
	mov	x5,x0			// save our fd
	adr	x1,disk_buffer
	mov	x2,#4096	 	// cheat and assume maximum of 4kB
	mov	x8,#SYSCALL_READ
	svc	0

	mov	x0,x5
	mov	x8,#SYSCALL_CLOSE
	svc	0			// close (to be correct)


	#=============
	# Number of CPUs
	#=============
number_of_cpus:

	adr	x1,one			// cheat and assume one cpu
					// not really a good assumption
	bl	strcat

	#=========
	# MHz
	#=========
print_mhz:

	# the arm system I have does not report MHz

	#===========
	# Chip Name
	#===========
chip_name:
	ldr	w0,=( ('c'<<24) | ('o'<<16) | ('r'<<8) | 'P')
	mov	x3,#' '
	bl	find_string		// find line starting with Proc
					// and grab up to ' '

	adr	x1,processor		// print " Processor, "
	bl	strcat

	#========
	# RAM
	#========

	adr	x0,sysinfo_buff
	mov	x3,x0
	mov	x8,#SYSCALL_SYSINFO
	svc	0
					// sysinfo() syscall

	ldr	x3,[x3,#S_TOTALRAM]	// size in bytes of RAM
	lsr	x3,x3,#20		// divide by 1024*1024 to get M
//	adc	x3,x3,#0		// round

	mov	x0,#1
	bl num_to_ascii			// print to string

	adr	x1,ram_comma		// print 'M RAM, '
	bl	strcat			// call strcat


	#==========
	# Bogomips
	#==========

	ldr	w0,=( ('S'<<24) | ('P'<<16) | ('I'<<8) | 'M')
	mov	x3,#'\n'
	bl	find_string		// Find MIPS then get to \n

	adr	x1,bogo_total
	bl	strcat			// print bogomips total

	bl	center_and_print	// center and print

	#=================================
	# Print Host Name
	#=================================
last_line:
	adr	x10,out_buffer		// point x10 to out_buffer

	adr	x1,(uname_info+U_NODENAME)
					// host name from uname()
	bl	strcat			// call strcat

	bl	center_and_print	// center and print

	adr	x1,default_colors	// restore colors, print a few linefeeds
	bl	write_stdout


	#================================
	# Exit
	#================================
exit:
	mov	x0,#0				// result
	mov	x8,#SYSCALL_EXIT
	svc	0				// and exit


	#=================================
	# FIND_STRING
	#=================================
	# x0 = string to find
	# x3 = char to end at
	# x5 trashed
find_string:
	adr	x7,disk_buffer	// look in cpuinfo buffer
find_loop:
	ldr	w5,[x7],#+1	// load a byte, increment pointer

	cbz	w5,done		// are we at EOF?
				// if so, done

	cmp	w5,w0		// compare against first byte

	b.ne	find_loop	// if no match, then loop

find_colon:
	ldrb	w5,[x7],#+1	// load a byte, increment pointer
	cmp	x5,#':'
	b.ne	find_colon	// repeat till we find colon

store_loop:
	ldrb	w5,[x7,#+1]!	// load a byte, increment pointer
				// by using pre-indexed increment
				// we skip the leading space

	strb	w5,[x10],#+1	// store a byte, increment pointer
	cmp	x5,x3
	b.ne	store_loop

almost_done:
	strb	wzr,[x10],#-1	// replace last value with NUL

done:
	ret			// return

	#================================
	# strcat
	#================================
	# value to cat in x1
	# output buffer in x10
	# x3 trashed
strcat:
	ldrb	w3,[x1],#+1		// load a byte, increment pointer
	strb	w3,[x10],#+1		// store a byte, increment pointer
	cbnz	w3,strcat		// is not NUL, loop
	sub	x10,x10,#1		// point to one less than null
	ret				// return


	#==============================
	# center_and_print
	#==============================
	# string to center in at output_buffer

center_and_print:

	str	x30,[sp,#-16]!		// store return address on stack

	adr	x1,escape		// we want to output ^[[
	bl	write_stdout

str_loop2:
	adr	x2,out_buffer		// point r2 to out_buffer
	sub	x2,x10,x2		// get length by subtracting

	mov	x0,#81
	sub	x2,x0,x2		// reverse subtract!  r2=81-r2
					// we use 81 to not count ending \n

	b.ne	done_center		// if result negative, don't center

	lsr	x3,x2,#1		// divide by 2
//	adc	x3,x3,#0		// round?

	mov	x0,#0			// print to stdout
	bl	num_to_ascii		// print number of spaces

	adr	x1,C			// we want to output C

	bl	write_stdout

done_center:
	adr	x1,out_buffer		// point x1 to out_buffer

	ldr	x30,[sp],#16		// restore return address from stack

	#================================
	# WRITE_STDOUT
	#================================
	# x1 has string
	# x0,x2,x3 trashed
write_stdout:
	mov	x2,#0				// clear count

str_loop1:
	add	x2,x2,#1
	ldrb	w3,[x1,x2]
	cmp	x3,#0
	b.ne	str_loop1			// repeat till zero

write_stdout_we_know_size:
	mov	x0,#STDOUT			// print to stdout
	mov	x8,#SYSCALL_WRITE
	svc	0		 		// run the syscall
	ret					// return


	##############################
	# num_to_ascii
	#############################
	# x3 = value to print
	# x0 = 0=stdout, 1=strcat

num_to_ascii:
	stp	x10,x30,[sp,#-16]!	// store return address on stack
	adr	x10,ascii_buffer
	add	x10,x10,#10
					// point to end of our buffer

div_by_10:
	# Divide by 10
	# r3=numerator
	# r7=quotient    r8=remainder
	# r5=trashed

	mov	x5,#10
	udiv	x7,x3,x5	// x7=x3/10
	umsubl	x8,w7,w5,x3	// x8=x3-(w7*10)

	add	x8,x8,#0x30	// convert to ascii
	strb	w8,[x10],#-1	// store a byte, decrement pointer
	adds	x3,x7,#0	// move Q in for next divide, update flags
	b.ne	div_by_10	// if Q not zero, loop


write_out:
	add	x1,x10,#1		// adjust pointer
	ldp	x10,x30,[SP],#16	// restore return address from stack

	cmp	x0,#0
	b.ne	strcat		// if 1, strcat

	b write_stdout		// else, fallthrough to stdout

# Put literal values here
.ltorg


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
.lcomm uname_info,(65*6)
.lcomm sysinfo_buff,(64)
.lcomm ascii_buffer,10
.lcomm  text_buf, (N+F-1)

.lcomm	disk_buffer,4096	//// we cheat!!!!
.lcomm	out_buffer,16384


	# see /usr/src/linux/include/linux/kernel.h

