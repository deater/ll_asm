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
# can also use r0 - r31?
# xsp/wsp and xzr/wzr can be used for zero and stack registers

# Also a 64-bit PC (program counter) and SP (stack pointer)
# Also 32 128-bit SIMD registers

# When operating on 32-bit values:
#    for source upper 32 is ignored, for destination upper 32 cleared to zero
#    right shifts/rotates bring in bit 31 not 63
#    condition flags from 32-bit not full reg


# Addressing modes
#  Base register 		[r0,#0]
#  Base plus offset		[r0,#imm]
#  Base plus register shift	[r0,r1,LSL #imm]
#  Base plus sign extended reg	[r0, W0, (S|U)XTW #imm]
#  Pre-indexed (update r0)	[r0,#imm]!
#  Post-indexed	(update r0)	[r0],#imm
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
#  TBNZ / TBZ	-- test and branch if nonzero/zero
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

# comment character is //




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
.equ SYSCALL_EXIT,	93
.equ SYSCALL_READ,	63
.equ SYSCALL_WRITE,	64
.equ SYSCALL_OPEN,	1024
.equ SYSCALL_CLOSE,	57
.equ SYSCALL_SYSINFO,	179
.equ SYSCALL_UNAME,	160

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
	mov	x2,#(N-F)	// x2 = N-F (R)
	adr	x3,logo		// x3 = logo begin
	adr	x8,logo_end	// x8 = logo end
	adr	x9,text_buf	// x9 = text_buf
	adr	x11,data_begin	// x11 = data_begin
	adr	x12,bss_begin	// x12 = bss_begin

decompression_loop:
	ldrb	w4,[x3],#1		// load a byte, increment pointer

	mov	x5,#0xff		// load top as a hackish 8-bit counter
	orr 	x5,x4,x5,LSL #8		// shift 0xff left by 8 and or in the byte we loaded

test_flags:
	cmp	x3,x8		// have we reached the end?
	b.ge	done_logo  	// if so, exit

	tst	x5,#1		// test low bit
	lsr 	x5,x5,#1	// shift bottom bit into carry flag
	b.eq	offset_length	// if not set, we jump to offset_length
				// USE CONDITIONAL EXECUTION INSTEAD OF BRANCH
discrete_char:
	ldrb	w4,[x3],#+1		// load a byte, increment pointer
	mov	x6,#1			// we set r6 to one so byte
					// will be output once

	b	store_byte		// and store it


offset_length:
	ldrb	w0,[x3],#+1	// load a byte, increment pointer
	ldrb	w4,[x3],#+1	// load a byte, increment pointer
				// we can't load halfword as no unaligned loads on arm

	orr	x4,x0,x4,LSL #8	// merge back into 16 bits
				// this has match_length and match_position

	mov	x7,x4		// copy r4 to r7
				// no need to mask r7, as we do it
				// by default in output_loop

	mov	x0,#(THRESHOLD+1)
	add	x6,x0,x4,LSR #(P_BITS)
				// r6 = (r4 >> P_BITS) + THRESHOLD + 1
				//                       (=match_length)

output_loop:
	mov	x0,#((POSITION_MASK<<8)+0xff)
	                                // urgh, can't handle simple constants
	and	x7,x7,x0		// mask it
	ldrb 	w4,[x9,x7]		// load byte from text_buf[]
	add	x7,x7,#1		// advance pointer in text_buf

store_byte:
	strb	w4,[x1],#+1		// store a byte, increment pointer
	strb	w4,[x9,x2]		// store a byte to text_buf[r]
	add 	x2,x2,#1		// r++
	mov	x0,#(N)			// grr, N-1 won't fit in 12-bits
	sub	x0,x0,#1		// grrr no way to get this easier
	and 	x2,x2,x0		// mask r

	subs	x6,x6,#1		// decement count
	b.ne 	output_loop		// repeat until k>j

	cmp	x5,#0xff		// are the top bits 0?
	b.gt	test_flags		// if not, re-load flags

	b	decompression_loop



# end of LZSS code

done_logo:
	adr	x1,out_buffer		// buffer we are printing to

	bl	write_stdout		// print the logo

	#==========================
	# PRINT VERSION
	#==========================
first_line:

//	add	r0,r12,#(uname_info-bss_begin)	@ uname struct
//	mov	r7,#SYSCALL_UNAME
//	swi	0x0		 		@ do syscall

//	add	r1,r12,#(uname_info-bss_begin)
//						@ os-name from uname "Linux"

//	adr	r10,out_buffer			@ point r10 to out_buffer

//	bl	strcat				@ call strcat

//
//	add	r1,r11,#(ver_string-data_begin) @ source is " Version "
//	bl 	strcat			        @ call strcat

//	add	r1,r12,#((uname_info-bss_begin)+U_RELEASE)
//						@ version from uname, ie "2.6.20"
//	bl	strcat				@ call strcat
//
//	add	r1,r11,#(compiled_string-data_begin)
//						@ source is ", Compiled "
//	bl	strcat				@  call strcat
//
//	add	r1,r12,#((uname_info-bss_begin)+U_VERSION)
//						@ compiled date
//	bl	strcat				@ call strcat
//
//	mov	r3,#0xa
//	strb	w3,[x10],#+1		@ store a linefeed, increment pointer
//	strb	w0,[x10],#+1		@ NUL terminate, increment pointer
//
//	bl	center_and_print	@ center and print
//
//	@===============================
//	@ Middle-Line
//	@===============================
middle_line:
//	@=========
//	@ Load /proc/cpuinfo into buffer
//	@=========

//	adr	r10,out_buffer		@ point r10 to out_buffer

//	add	r0,r11,#(cpuinfo-data_begin)
//					@ '/proc/cpuinfo'
//	mov	r1,#0			@ 0 = O_RDONLY <bits/fcntl.h>
//	mov	r7,#SYSCALL_OPEN
//	swi	0x0
//					@ syscall.  return in r0?
//	mov	r5,r0			@ save our fd
//	ldr	r1,=disk_buffer
//	mov	r2,#4096
//				 	@ 4096 is maximum size of proc file ;)
//	mov	r7,#SYSCALL_READ
//	swi	0x0

//	mov	r0,r5
//	mov	r7,#SYSCALL_CLOSE
//	swi	0x0
//					@ close (to be correct)


//	@=============
//	@ Number of CPUs
//	@=============
number_of_cpus:

//	add	r1,r11,#(one-data_begin)
//					# cheat.  Who has an SMP arm?
//					# 2012 calling, my pandaboard is...
//	bl	strcat
//
//	@=========
//	@ MHz
//	@=========
print_mhz:

//	@ the arm system I have does not report MHz

//	@=========
//	@ Chip Name
//	@=========
chip_name:
//	mov	r0,#'s'
//	mov	r1,#'o'
//	mov	r2,#'r'
//	mov	r3,#' '
//	bl	find_string
//					@ find 'sor\t: ' and grab up to ' '

//	add	r1,r11,#(processor-data_begin)
//					@ print " Processor, "
//	bl	strcat

//	@========
//	@ RAM
//	@========

//	add	r0,r12,#(sysinfo_buff-bss_begin)
//	mov	r7,#SYSCALL_SYSINFO
//	swi	0x0
//					@ sysinfo() syscall
//
//	ldr	r3,[r12,#((sysinfo_buff-bss_begin)+S_TOTALRAM)]
//					@ size in bytes of RAM
//	movs	r3,r3,lsr #20		@ divide by 1024*1024 to get M
//	adc	r3,r3,#0		@ round
//
//	mov	r0,#1
//	bl num_to_ascii
//
//	add	r1,r11,#(ram_comma-data_begin)
//					@ print 'M RAM, '
//	bl	strcat			@ call strcat


//	@========
//	@ Bogomips
//	@========
//
//	mov	r0,#'I'
//	mov	r1,#'P'
//	mov	r2,#'S'
//	mov	r3,#'\n'
//	bl	find_string
//
//	add	r1,r11,#(bogo_total-data_begin)
//	bl	strcat			@ print bogomips total
//
//	bl	center_and_print	@ center and print

//	#=================================
//	# Print Host Name
//	#=================================
last_line:
//	adr	r10,out_buffer		@ point r10 to out_buffer
//
//	add	r1,r12,#((uname_info-bss_begin)+U_NODENAME)
//					@ host name from uname()
//	bl	strcat			@ call strcat
//
//	bl	center_and_print	@ center and print
//
//	add	r1,r11,#(default_colors-data_begin)
//					@ restore colors, print a few linefeeds
//	bl	write_stdout
//
//
//	@================================
//	@ Exit
//	@================================
exit:
	mov	x0,#0				// result
	mov	x8,#SYSCALL_EXIT
	svc	0				// and exit


//	@=================================
//	@ FIND_STRING
//	@=================================
//	@ r0,r1,r2 = string to find
//	@ r3 = char to end at
//	@ r5 trashed
find_string:
//	ldr	r7,=disk_buffer		@ look in cpuinfo buffer
find_loop:
//	ldrb	w5,[x7],#+1		@ load a byte, increment pointer
//	cmp	r5,r0			@ compare against first byte
//	ldrb	w5,[x7]			@ load next byte
//	cmpeq	r5,r1			@ if first byte matched, comp this one
//	ldrb	w5,[x7,#+1]		@ load next byte
//	cmpeq	r5,r2			@ if first two matched, comp this one
//	beq	find_colon		@ if all 3 matched, we are found

//	cmp	r5,#0			@ are we at EOF?
//	beq	done			@ if so, done

//	b	find_loop

find_colon:
//	ldrb	w5,[x7],#+1		@ load a byte, increment pointer
//	cmp	r5,#':'
//	bne	find_colon		@ repeat till we find colon

//	add	r7,r7,#1		@ skip the space

store_loop:
//	ldrb	w5,[x7],#+1		@ load a byte, increment pointer
//	strb	w5,[x10],#+1		@ store a byte, increment pointer
//	cmp	r5,r3
//	bne	store_loop

almost_done:
//	mov	r0,#0
//	strb	w0,[x10],#-1		@ replace last value with NUL

done:
//	mov	pc,lr			@ return

//	#================================
//	# strcat
//	#================================
//	# value to cat in r1
//	# output buffer in r10
//	# r3 trashed
strcat:
//	ldrb	w3,[x1],#+1		@ load a byte, increment pointer
//	strb	w3,[x10],#+1		@ store a byte, increment pointer
//	cmp	r3,#0			@ is it zero?
//	bne	strcat			@ if not loop
//	sub	r10,r10,#1		@ point to one less than null
//	mov	pc,lr			@ return


	#==============================
	# center_and_print
	#==============================
	# string to center in at output_buffer

center_and_print:

//	stmfd	SP!,{LR}		@ store return address on stack
//
//	add	r1,r11,#(escape-data_begin)
//					@ we want to output ^[[
//	bl	write_stdout

str_loop2:
//	adr	r2,out_buffer		@ point r2 to out_buffer
//	sub	r2,r10,r2		@ get length by subtracting

//	rsb	r2,r2,#81		@ reverse subtract!  r2=81-r2
//					@ we use 81 to not count ending \n

//	bne	done_center		@ if result negative, don't center
//
//	lsrs	r3,r2,#1		@ divide by 2
//	adc	r3,r3,#0		@ round?

//	mov	r0,#0			@ print to stdout
//	bl	num_to_ascii		@ print number of spaces
//
//	add	r1,r11,#(C-data_begin)
//					@ we want to output C
//	bl	write_stdout

done_center:
//	adr	r1,out_buffer		@ point r1 to out_buffer
//	ldmfd	SP!,{LR}		@ restore return address from stack

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


//	@#############################
//	@ num_to_ascii
//	@#############################
//	@ r3 = value to print
//	@ r0 = 0=stdout, 1=strcat

num_to_ascii:
//	stmfd	SP!,{r10,LR}		@ store return address on stack
//	add	r10,r12,#((ascii_buffer-bss_begin))
//	add	r10,r10,#10
//					@ point to end of our buffer

div_by_10:
//	@================================================================
//	@ Divide by 10 - because ARM has no hardware divide instruction
//	@    the algorithm multiplies by 1/10 * 2^32
//	@    then divides by 2^32 (by ignoring the low 32-bits of result)
//	@================================================================
//	@ r3=numerator
//	@ r7=quotient    r8=remainder
//	@ r5=trashed
divide_by_10:
//	ldr	r4,=429496730			@ 1/10 * 2^32
//	sub	r5,r3,r3,lsr #30
//	umull	r8,r7,r4,r5			@ {r8,r7}=r4*r5

//	mov	r4,#10				@ calculate remainder

//						@ could use "mls" on
//						@ armv6/armv7
//	mul	r8,r7,r4
//	sub	r8,r3,r8

//	@ r7=Q, R8=R

//	add	r8,r8,#0x30	@ convert to ascii
//	strb	w8,[x10],#-1	@ store a byte, decrement pointer
//	adds	r3,r7,#0	@ move Q in for next divide, update flags
//	bne	div_by_10	@ if Q not zero, loop


write_out:
//	add	r1,r10,#1	@ adjust pointer
//	ldmfd	SP!,{r10,LR}	@ restore return address from stack

//	cmp	r0,#0
//	bne	strcat		@ if 1, strcat

//	b write_stdout		@ else, fallthrough to stdout

# Put literal values here
.ltorg


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
cpuinfo:	.ascii  "proc/c.arm64\0"
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
.lcomm uname_info,(65*6)
.lcomm sysinfo_buff,(64)
.lcomm ascii_buffer,10
.lcomm  text_buf, (N+F-1)

.lcomm	disk_buffer,4096	//@ we cheat!!!!
.lcomm	out_buffer,16384


	# see /usr/src/linux/include/linux/kernel.h

