#
#  linux_logo in crisv32 assembler 0.32
#
#  By 
#       Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -o ll.o ll.crisv32.s"
#  link with         "ld -o ll ll.o"
#
#  I have to cross-compile, so what I do is was more like
#      make CROSS=/usr/local/cris/crisv32-axis-linux-gnu/bin/ ARCH=crisv32


#
# I use qemu for simulating this code (I have no cris hardware)
#   and qemu simulates the newer cris fs, that is crisv32
#   instruction set.
# Qemu gives a mmap error if the "-N" flag is passed to as
#   This can be worked around by commenting out the
#   "offset & ~TARGET ..." line in mmap.c in qemu/linux-user

# The older Cris LX has a different instruction set (for example,
#   the PC is r15, among other differences) and might be able
#   to be optimized more.

#
# It'd be nice to have an Axis 88 development board...
#

# Little Endian
# no alignment
# 16-bit instructions (though immediate values can follow)
# branch delay slots
# 2 operand (genearlly Rs,Rd)
# *not* load store? i.e can do add.b [Rs],Rd


# 14 gp 32-bit registers (r0-r13)
#  1 stack pointer (r14 "sp")
#  1 address calc reg (r15 "acr")
# 16 special purpose registers (p0-p15)
#    name  pval  bits   desc
#   + bz -  p0 - 8     zero byte constant
#   + vr -  p1 - 8     version 
#   + pid - p2 - 32    process id
#   + srs - p3 - 8     support reg select (pick reg bank)
#   + wz  - p4 - 16    word zero constant
#   + exs - p5 - 32    exception status
#   + eda - p6 - 32    exception address
#   + mof - p7 - 32    multiply overflow
#   + dz  - p8 - 32    dword zero constant
#   + ebp - p9 - 32    exception base
#   + erp - p10- 32    exception return
#   + srp - p11- 32    subroutine return
#   + nrp - p12- 32    nmi return
#   + ccs - p13- 32    cond code stack
#   + usp - p14- 32    user mode stack
#   + spc - p15- 32    single step pc

# Flags
#
# Carry oVerflow Zero Negative eXtend 
# Interrupt User (P)SeqBroken RestoreP Singlestep 
# Q(pendingSingle) nMi 
#
# Has room for 3 copies, HW shifts them when
# exception occurs.

# Condition codes
# CC carry clear  !C    CS carry set    C
# NE not equal    !Z    EQ equal        Z
# VC not overflow !V    VS overflow set V
# PL plus         !N    MI minus        N
# LS low or same  C||Z  HI high         !C && !Z
# GE greater eq   N&&V  || !N&&!V
# LT less than    N&&!V || !N&&!V
# LE less equal   Z||N&&!V||!N&&V
# A  always
# SB Sequence Broken P

# N,Z set on all
# N,Z,V,C set on ADD,ADDQ,ADDS,ADDU,ADDC
# N,Z,V,C on CMP,CMPQ,CMPS,CMPU,NEG,SUB,SUBQ,SUBS,SUBU
# N,Z,V  on MULS,MULU
# N,Z on BTST,BTSTQ
# P set on restore from exception, cache miss cond write
# C set if cond write fails

# Addressing Modes
# Quick Immediate  - 6 bit, extended
# Register         - register
# Indirect         - reg pointer [R5]
# Autoincrement	   - [R5+]
#                     (cannot [ACR+] or [R15+])
# Immediate	   - follows immediately after insn

# branches can have 8 or 16 bit offsets
# no jumps or instructions with long immediates in delay slot

# bas - branch and save.
#       takes 32 bit value, followed by delay slot
# jasc/basc - gives you 4 unused bytes you can
#             use yourself before delay slot

# address calc instrucions (addo) often used with acr
#   don't affect flags
# lapc - relative address based on PC

# the "ax" ins enables extended arithmetic
#  this makes next instruction taken into account
#  the C andother flags as if one big arith insn

# instruction summary

# ABS - absolute value
# ADD.s - add (size = b,w,d), ADDC, ADDQ
# ADDI - add index (scaled add)
# ADDO - add offset (dest is ACR), ADDOQ (quick - 8bit imm)
# ADDS - add with sign extend, ADDU zero extend
# AX - enable extended arithmetic
# CMP, CMPQ, CMPS (sign extend), CMPU
# DSTEP - divide step
# LAPC - load PC relative, LAPCQ
# MCP - multiply carry propagation
# MULS - signed multiply, MULU
# NEG, NOT
# SUB, SUBQ, SUBS, SUBU

# logical
# AND, ANDQ
# BTST - bit test (N set to bit Rs, Z = if bits to right 0)
# BTSTQ
# OR, ORQ
# TEST - compare with zero
# XOR

# shift
# ASR,ASRQ, LSL, LSLQ, LSR, LSRQ

# branch
# BA
# BAS - branch and save, BASC (with context), BSR, BSRC
# Bcc - conditionally
# JAS, JASC, JSR, JSRC, JUMP
# RET

# misc
# BOUND - limit index to a maximum
# CLEAR - set register to zero
# CLEARF - clear flags
# LZ - count leading zeros
# MOVE - move register, MOVEQ, MOVS, MOVU
# MOVEM - move memory into multiple registers
# NOP
# SCC - set conditional
# SETF - set flags
# SWAPs - Swap bits (inverting, reversing or swapping)
#         N (invert) W (swap words) B (swap bytes) R (reverse)


# Calling convention
# parms passed in R10-R13, return in R10
# r0-r8 callee saved, r9-r15 caller saved


# differences between FS and LX
# - pc is not r15
# - BDAP, BIAP, DIP prefixes removed (addr calc)
# - MSTEP removed (MUL instructions added)
# - MOVE to PC removed
# - BOUND with memory operand removed
# - MOVEM order changed
# - NOP is not SETF instead of ADDI R0.b,R15
# - RET is not JUMP Ps


# Optimization (the assembler pads to 32 byte boundary)
# + 1267 bytes = Initial direct port of avr32 code
# + 1107 bytes = Reduce constants to 16 bit when possible
# + 1043 bytes = Fill branch delay slots
# + 1011 bytes = loop the divide routine
# +  979 bytes = subroutine jsr to reg instead of bsr for strcat
# +  979 bytes = use "addi acr" instruction
# +  947 bytes = use r8 for write_stdout jsr instead of bsr
# +  947 bytes = remove all bsr instructions
# +  947 bytes = consistently use r3 instead of loading out_buffer
# +  915 bytes = miscellaneous fixes, enough to push under the barrier
# +  913 bytes = remove unused variable
# +  911 bytes = merge bogomips and linefeed strings
# +  905 bytes = remove .section bss and .section data directives

.include "logo.include"

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
.equ SYSCALL_EXIT,	1
.equ SYSCALL_READ,	3
.equ SYSCALL_WRITE,	4
.equ SYSCALL_OPEN,	5
.equ SYSCALL_CLOSE,	6
.equ SYSCALL_SYSINFO,	116
.equ SYSCALL_UNAME,	122

#
.equ STDIN,0
.equ STDOUT,1
.equ STDERR,2

	.globl _start	
_start:


	;=========================
	; PRINT LOGO
	;=========================

; LZSS decompression algorithm implementation
; by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
; optimized some more by Vince Weaver

	movu.w	out_buffer,r1	; r1 is out_buffer
	movu.w  (N-F),r2	; r2 is R (N-F)
	movu.w	logo,r3		; r3 points to logo
	movu.w	logo_end,r4	; r4 points to logo_end	
	movu.w	text_buf,r12	; r12 points to text_buf
	
decompression_loop:
	movu.b	[r3+],r8	; load a byte, increment pointer
	or.w	0xff00,r8	; load top as a hackish 8-bit counter

test_flags:
	cmp.d	r3,r4		; have we reached the end?
	beq	done_logo  	; if so, exit

	btstq	0,r8		; [DS] check bit 0

	bmi	discrete_char	; if set, we jump to discrete char
	lsrq 	1,r8		; [DS] shift bottom bit into carry flag
	

offset_length:
	movu.w 	[r3+],r10	; load a halfword

	move.d	r10,r11		; copy r9 to r11
				; no need to mask r11, as we do it
				; by default in output_loop

	lsrq	P_BITS,r10
	addq	(THRESHOLD+1),r10
				; d1 = (d4 >> P_BITS) + THRESHOLD + 1
				;                       (=match_length)
	
output_loop:
	and.w 	((POSITION_MASK<<8)+0xff),r11

	addi	r12.b,r11,acr
	movu.b	[acr],r9       		; load byte from text_buf[]
	addq	1,r11			; advance pointer in text_buf

store_byte:
	move.b	r9,[r1+]	       	; store a byte, increment pointer

	addi	r12.b,r2,acr
	move.b	r9,[acr]       		; store a byte to text_buf[r]
	
	addq 	1,r2			; r++

	subq	1,r10			; decrement count and loop
	bne	output_loop		; if r10 is zero or above
	
	and.w	(N-1),r2		; [DS] mask r

	btstq	8,r8			; test if bit 8 set (top 24 bits zero)
					; one less instruction and one less
					; temp reg than lz /cmpq

	bmi	test_flags		; if not, re-load flags
	nop				; [DS]
	
	ba	decompression_loop	; 
	nop				; [DS]

discrete_char:

	movu.b	[r3+],r9       		; load a byte, increment pointer
					
	ba	store_byte		; and store it
	moveq	1,r10			; [DS] only output one byte	


; end of LZSS code

done_logo:
	movu.w	write_stdout,r8		; make r0 hold address of write_stdout
	movu.w	out_buffer,r11		; out_buffer we are printing to
	
	jsr	r8			; call write_stdout (print the logo)
	move.d	r11,r3			; [DS] save for later

	movu.w	strcat,r13		; make r13 hold strcat for jsr
					; instead of bsr
	movu.w	center_and_print,r5
	movu.w	num_to_ascii,r2
	movu.w	find_string,r7

	;==========================
	; PRINT VERSION
	;==========================
first_line:

	movu.w	uname_info,r10			; uname struct
	move.d	r10,r4				; copy for later
	movu.b	SYSCALL_UNAME,r9
	break	13				; do syscall

						; os-name from uname "Linux"
						; already at r10
	
	
	jsr	r13				; call strcat
	movu.w	r3,r1				; [DS]point to out buffer
						; r4 already points to Linux
	
	jsr 	r13			        ; call strcat
	movu.w	ver_string,r4			; [DS] source is " Version "

	jsr	r13				; call strcat
	movu.w  ((uname_info)+U_RELEASE),r4	; [DS] version from uname, ie "2.6.20"
						;  can't use addoq, not enough
						;  bits (just barely)

	jsr	r13				; call strcat
	movu.w	compiled_string,r4		; [DS] source is ", Compiled "

	jsr	r13				; call strcat
	movu.w	((uname_info)+U_VERSION),r4	; [DS] compiled date

	jsr	r13				; call strcat
	movu.w	linefeed,r4			; [DS] print a linefeed	
	
	jsr	r5				; call center_and_print
	nop
	
	;===============================
	; Middle-Line
	;===============================
middle_line:

	;=========
	; Load /proc/cpuinfo into buffer
	;=========

	move.d	r3,r1			; point to out_buffer
	
	movu.w	cpuinfo,r10		; '/proc/cpuinfo'
	clear.d	r11			; 0 = O_RDONLY <bits/fcntl.h>
	moveq	SYSCALL_OPEN,r9			
	break	13	       		; syscall.  return in r10  
	
	move.d	r10,r6			; save our fd
	
	movu.w	disk_buffer,r11
	movu.w	4096,r12	        ; 4096 is maximum size of proc file ;)
	moveq	SYSCALL_READ,r9
	break	13

	move.d	r6,r10			; restore fd
	moveq	SYSCALL_CLOSE,r9
	break	13			; close (to be correct)


	;=============
	; Number of CPUs
	;=============
number_of_cpus:

	jsr	r13			; call strcat
	movu.w  one,r4			; [DS] cheat.  assuming no smp cris machines	

	;=========
	; MHz
	;=========
print_mhz:

	; /proc/cpuinfo on crisv32 does not report megahertz

	;=========
	; Chip Name
	;=========
chip_name:	
	jsr	r7			; call find_string 
	move.d	('l'<<24)+('e'<<16)+('d'<<8)+'o',r10	   	 ; [DS] look for "cpu model"
	

	jsr	r13			; call strcat	
	movu.w	processor,r4		; [DS] print " Processor, "
	
	;========
	; RAM
	;========
ram:	
	movu.w	sysinfo_buff,r10
	movu.b	SYSCALL_SYSINFO,r9
	break	13     			; sysinfo() syscall
	
	movu.w	sysinfo_buff+S_TOTALRAM,acr		; size in bytes of RAM
	move.d	[acr],r10
	lsrq	20,r10			; divide by 1024*1024 to get M

	jsr 	r2			; call num_to_ascii
	moveq	1,r12			; [DS] use strcat

	jsr	r13			; call strcat
	movu.w	ram_comma,r4		; [DS] print 'M RAM, '	

	;========
	; Bogomips
	;========
bogomips:	
	jsr	r7			; call find_string
        move.d	('s'<<24)+('p'<<16)+('i'<<8)+'m',r10  ; [DS] find 'mips' and grab up to '\n'	

	jsr	r13			; call strcat			
	movu.w	bogo_total,r4		; [DS] print bogomips total
	
	jsr	r5			; call center_and_print
	nop

	;=================================
	; Print Host Name
	;=================================
last_line:
	move.d	r3,r1	        	; point r1 to out_buffer
					
	jsr	r13			; call strcat
	movu.w	((uname_info)+U_NODENAME),r4
					; [DS] host name from uname()

	
	jsr	r5			; call center_and_print
	nop
	
	jsr	r8			; call write_stdout
	movu.w	default_colors,r11	; restore colors, print a few linefeeds	
	
	
	;================================
	; Exit
	;================================
	
exit:
        moveq 	      SYSCALL_EXIT,r9	; load syscall value
        clear.d	      r10	      	; return a 0
	break	      13		; exit
	
	
	;=================================
	; FIND_STRING 
	;=================================
	; r10 = string to find

find_string:
	movu.w	disk_buffer,r6		; look in cpuinfo buffer
find_loop:
	move.d	[r6],r0			; load unaligned word
	beq	done			; if zero, then not found	
	addq	1,r6			; [DS] increment pointer
	
	cmp.d	r0,r10
	bne	find_loop		; loop until we find our string
	nop				; [DS]
	
	addq	3,r6			; skip what we just searched
	
skip_tabs:
	movu.b	[r6+],r0		; read in a byte
	cmp.b	' '+1,r0		; are we whitespace 
		  			; (grrr, one bit too big for cmpq)
	blt	skip_tabs		; if so, loop
	nop				; [DS]
	
	addq	1,r6			; adjust pointer (skip colon)
	
store_loop:
	movu.b	[r6+],r0		; load a byte, increment pointer
	cmpq	'\n',r0		
	beq	almost_done		; 
	nop				; [DS]
	
	move.b	r0,[r1+]		; store a byte, increment pointer
	ba	store_loop		; 
	
almost_done:
      	move	bz,[r1]	       		; [DS] replace last value with NUL

done:
	ret	   			; return
	nop				; [DS]


	
	
	;==============================
	; center_and_print
	;==============================
	; string to center in out_buffer

center_and_print:
	move	srp,r15			; save link register
		
	jsr	r8			; call write_stdout
	movu.w	escape,r11     		; [DS] we want to output ^[[

	move.d	r1,r10			; save end of buffer	
	move.d	r3,r11 			; point r11 to out_buffer
	
	sub.d	r3,r10			; subtract
	neg.d	r10,r10
	adds.b	81,r10			; (buf_begin-buf_end)+80
	
	bmi	done_center		; if result negative, don't center
	lsrq	1,r10			; [DS] divide by 2

	jsr	r2			; call num_to_ascii (print number of spaces)
	clear.d r12			; [DS] print to stdout

	jsr	r8			; call write_stdout
	movu.w	C,r11			; [DS] we want to output C
	
	move.d	r3,r11			; point to out_buffer

done_center:
	move	r15,srp	      		; restore link register
	


	;================================
	; WRITE_STDOUT
	;================================
	; r11 has string
	; r9,r10,r12 trashed

write_stdout:
	move.d	r11,r12	        	; copy string pointer to r12

str_loop1:
        test.b	[r12+]			; test if zero, auto-increment
	bne	str_loop1		; branch if not zero
	nop				; [DS] branch delay slot

	sub.d	r11,r12			; get count into r12
	subq	1,r12			; adjust for overcount
	
write_stdout_we_know_size:

	moveq	SYSCALL_WRITE,r9        ; load the write syscall
	moveq	STDOUT,r10	        ; print to stdout
	break	13		        ; actually run syscall
	ret				; return

	;=============================
	; num_to_ascii
	;=============================
	; r10 = value to print
	; r12 = 0=stdout, 1=strcat
		
num_to_ascii:
	
	movu.w	(ascii_buffer+9),r11	; [DS] point to end of our buffer

div_by_10:
	  		   ; 16 bit div code orig from crisv32 manual
	moveq	10,r6	   ; divide by 10
	lslq	16,r6	
	subq	1,r6       ; Subtract one from the denominator.
	
	moveq	16,r0
div_loop:	
	subq	1,r0
	bne	div_loop
	dstep	r6,r10	   ; [DS] Perform 16 interations
		
			        ; q is in lower 16 bits
				; r is in upper 16 bits
	move.d	r10,r0
	lsrq	16,r0
	
	
	addq	48,r0		; convert to ASCII

	subq	1,r11 		; decrement pointer
	move.b	r0,[r11]	; store a byte

	movu.w	r10,r10		; mask off remainder
	
	bne	div_by_10	; if Q not zero, loop
	
write_out:
	cmpq	0,r12		; [DS]
	bne	strcat
	move.d	r11,r4		; [DS] move for strcat		
				; (harmless for write_stdout)

ascii_stdout:
	ba	write_stdout	; else, branch to stdout

	;================================
	; strcat (used to preserve linear string pointer)
	;================================
	; value to cat in r4
	; output buffer in r1
	; r0 trashed
strcat:
        movu.b	[r4+],r6		; [DS] load a byte, increment pointer 
	bne	strcat			; loop if not zero	
	move.b	r6,[r1+]		; [DS] store a byte, increment pointer

	ret		       		; return
	subq	1,r1			; [DS] point to one less than null 



;===========================================================================
;	section .data
;===========================================================================
;.data
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
one:	.ascii	"One CRIS \0"
processor:	.ascii	" Processor, \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total"
linefeed:	.ascii  "\n\0"

default_colors:	.ascii "\033[0m\n\n\0"
escape:		.ascii "\033[\0"
C:		.ascii "C\0"

.ifdef FAKE_PROC
cpuinfo:	.ascii  "proc/cpu.cris\0"
.else
cpuinfo:	.ascii	"/proc/cpuinfo\0"
.endif

.include	"logo.lzss_new"


;============================================================================
;	section .bss
;============================================================================
;.section bss
.lcomm uname_info,(65*6)
.lcomm sysinfo_buff,(64)
.lcomm  text_buf, (N+F-1)
.lcomm ascii_buffer,10

.lcomm	disk_buffer,4096	; we cheat!!!!
.lcomm	out_buffer,16384

	; see /usr/src/linux/include/linux/kernel.h

