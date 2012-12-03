@
@  linux_logo in ARM THUMB2 assembler 0.46
@
@  Originally by 
@       Vince Weaver <vince _at_ deater.net>
@
@  Crazy size-optimization hacks by
@       Stephan Walter <stephan.walter _at_ gmx.ch>
@
@  assemble with     "as -o ll.thumb2.o ll.thumb2.s"
@  link with         "ld -o ll_thumb2 ll.thumb2.o"

.include "logo.include"

@ Indicates Unified Thumb-2 syntax
.syntax unified

@ Use thumb 16/32 mode
.thumb

@ Use ARM 32-bit mode
@ .arm


@
@ Architectural info
@
@ ARM has 16 GP registers
@ In thumb, only r0-r7 are accessible normally
@ The BX instruction is used to change into thumb.  Bottom bit
@   of the target address is the important one.
@ + r13 = stack pointer
@ + r14 = link register
@ + r15 = program counter
@ powerful push/pop that can push/pop any combination of r0-r7 in one insn.
@    also can push LR and pop that to PC
@ Instructions that can use the high registers:
@  add, cmp, mov
@ "bl" instructions are 32 bits!
@
@ syscalls are like EABI syscalls, syscall num is in r7, args in r0-r?
@ reading r15 in general gives you current PC+4
@ 6 Status registers (only one visible in userspace)
@ - NZCVQ (Negative, Zero, Carry, oVerflow, saturate)

@ comment character is a @
@ # can be used if on a line w/o any code
@ /* C-style comments can also be used */

@ There's a thumb-2 mode that extends thumb to provide 32-bit encodings
@   of some instructions unavailable in THUMB (but not the same encoding
@   as full 32-bit ARM).
@ In addition it adds support for cbz, cbnz (compare and branch)
@   but only works for forward branch?
@ IT (if/then) instruction
@   allows setting blocks of conditional instructions
@   IT directive ignored in 32-bit mode	but used in THUMB-2

@ Deprecated in Thumb-2 (and armv7)
@ Upward growing stack?
@ rsc (reverse-subtract with carry)

@ Thumb2 stuff
@  -- use "adds" for small immediate adds or assembler uses wide add.w
@  -- make sure you properly indicate "s" for instructions that need it.
@     in 16-bit thumb the "s" is assumed in many instructions and gas
@     won't let you set it explicitly

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


.thumb	@ use 16-bit thumb instructions

	.globl _start
_start:

	#=========================
	# PRINT LOGO
	#=========================

# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver

	@ r0 = temp
	@ r1 = output_buffer
	@ r2 = R
	@ r3 = logo data inputting from
	@ r4 = temp
	@ r5 = counter
	@ r6 = position
	@ r7 = match length
	@ r8 = logo end
	@ r9 = text_addr


	ldr	r1,=out_buffer		@ buffer we are printing to
	ldr	r2,R			@ R

	ldr	r3,logo_addr		@ r3 points to logo data

	ldr	r0,logo_end_addr
	mov	r8,r0			@ r8 points to logo end

	ldr	r0,text_addr		@ r9 points to text buf
	mov	r9,r0

decompression_loop:
	ldrb	r4,[r3]			@ load a byte
	adds	r3,#1			@ increment pointer

	mov	r5,#0xff		@ load top as a hackish 8-bit counter
	lsl	r5,#8			@ shift 0xff left by 8
	orr 	r5,r4			@ or in the byte we loaded

test_flags:
	cmp	r3,r8		@ have we reached the end?
	bge	done_logo  	@ if so, exit

	lsrs 	r5,#1		@ shift bottom bit into carry flag
	bcs	discrete_char	@ if set, we jump to discrete char

offset_length:
	ldrb	r0,[r3]		@ load a byte
	add	r3,#1		@ increment pointer
	ldrb	r4,[r3]		@ load a byte
	add	r3,#1		@ increment pointer
				@ we can't load halfword
				@ as no unaligned loads on arm

	lsl	r4,#8
	orr	r4,r0,r4	@ merge back into 16 bits
				@ this has match_length and match_position

	mov	r7,r4		@ copy r4 to r7
				@ no need to mask r7, as we do it
				@ by default in output_loop

	mov	r0,#(THRESHOLD+1)
	lsr	r4,#(P_BITS)
	add	r6,r4,r0
				@ r6 = (r4 >> P_BITS) + THRESHOLD + 1
				@                       (=match_length)

output_loop:
	ldr	r0,pos_mask		@ urgh, can't handle simple constants
	and	r7,r0			@ mask it
	mov	r0,r9
	ldrb 	r4,[r0,r7]		@ load byte from text_buf[]
	add	r7,#1			@ advance pointer in text_buf

store_byte:
	strb	r4,[r1]			@ store a byte
	add	r1,#1			@ increment pointer
	mov	r0,r9
	strb	r4,[r0,r2]		@ store a byte to text_buf[r]
	add 	r2,#1			@ r++

	ldr	r0,NMINUS1		@ grrr no way to get this easier
	and 	r2,r0			@ mask r

	subs	r6,#1			@ decement count
	bne 	output_loop		@ repeat until k>j

	mov	r0,#0xff
	lsl	r0,#8
	tst	r5,r0			@ are the top bits 0?
	bne	test_flags		@ if not, re-load flags

	b	decompression_loop

discrete_char:
	ldrb	r4,[r3]			@ load a byte
	add	r3,#1			@ increment pointer
	mov	r6,#1			@ we set r6 to one so byte
					@ will be output once

	b	store_byte		@ and store it

# end of LZSS code

done_logo:
	ldr	r1,=out_buffer		@ buffer we are printing to


	ldr	r0,strcat_addr
	mov	r11,r0			@ point r11 to "strcat_r4"
	sub	r0,#8
	mov	r10,r0			@ point r10 to "strcat_r3"
	sub	r0,#(strcat_r5-write_stdout)
	mov	r9,r0			@ point r9 to "write_stdout"

	sub	r0,#(write_stdout-center_and_print)
	mov	r8,r0

	blx	r9			@ print the logo



	#==========================
	# PRINT VERSION
	#==========================

first_line:
	ldr	r0,uname_addr
	mov	r5,r0
	mov	r7,#SYSCALL_UNAME
	swi	#0			@ do uname syscall

					@ os-name from uname "Linux"

	ldr	r6,=out_buffer		@ point r6 to out_buffer

	blx	r10			@ call strcat_r5

	ldr	r4,ver_addr		@ source is " Version "

	blx 	r11			@ call strcat_r4

	add	r5,#U_RELEASE
					@ version from uname, ie "2.6.20"
	blx	r10			@ call strcat_r5

					@ source is ", Compiled "
	blx	r11			@ call strcat_r4

	add	r5,#(U_VERSION-U_RELEASE)
					@ compiled date
	blx	r10			@ call strcat_r5

					@ source is "\n"
	blx	r11			@ call strcat_r4

	blx	r8			@ center and print

	@===============================
	@ Middle-Line
	@===============================
middle_line:
	@=========
	@ Load /proc/cpuinfo into buffer
	@=========

	ldr	r6,=out_buffer		@ point r6 to out_buffer

	mov	r0,r4
					@ '/proc/cpuinfo'
	mov	r1,#0			@ 0 = O_RDONLY <bits/fcntl.h>
	mov	r7,#SYSCALL_OPEN
	swi	#0			@ syscall.  return in r0?

	mov	r3,r0			@ save our fd
	ldr	r1,disk_addr
	mov	r2,#128
	lsl	r2,#5		 	@ 4096 is maximum size of proc file ;)
	mov	r7,#SYSCALL_READ
	swi	#0

	mov	r0,r3
	mov	r7,#SYSCALL_CLOSE
	swi	#0			@ close (to be correct)


	@=============
	@ Number of CPUs
	@=============
number_of_cpus:

					@ cheat.  Who has an SMP arm?
					@ Print "One"
	add	r4,#14			@ length of /proc/cpuinfo
	blx	r11			@ call strcat_r4

	@=========
	@ MHz
	@=========
print_mhz:

	@ the arm system I have does not report MHz

	@=========
	@ Chip Name
	@=========
chip_name:

	mov	r0,#'s'
	mov	r1,#'o'
	mov	r2,#'r'
	mov	r3,#' '
	bl	find_string
					@ find 'sor\t: ' and grab up to ' '

	blx	r11			@ print " Processor, "

	@========
	@ RAM
	@========
	ldr	r0,sysinfo_addr
	mov	r2,r0

	mov	r7,#SYSCALL_SYSINFO
	swi	#0			@ sysinfo() syscall

	add	r2,#S_TOTALRAM
	ldr	r3,[r2]
					@ size in bytes of RAM
	lsr	r3,#20			@ divide by 1024*1024 to get M

	mov	r0,#1
	bl num_to_ascii

					@ print 'M RAM, '
	blx	r11			@ call strcat

	@========
	@ Bogomips
	@========

	mov	r0,#'I'
	mov	r1,#'P'
	mov	r2,#'S'
	mov	r3,#'\n'
	bl	find_string

	blx	r11			@ print bogomips total

	blx	r8			@ center and print

	#=================================
	# Print Host Name
	#=================================
last_line:
	ldr	r6,=out_buffer		@ point r6 to out_buffer

	sub	r5,#(U_VERSION-U_NODENAME)
					@ host name from uname()
	blx	r10			@ call strcat_r5

	blx	r8			@ center and print

	ldr	r1,colors_addr

					@ restore colors, print a few linefeeds
	blx	r9			@ write_stdout

	@================================
	@ Exit
	@================================
exit:
	mov	r0,#0				@ result is zero
	mov	r7,#SYSCALL_EXIT
	swi	#0



	@=================================
	@ FIND_STRING
	@=================================
	@ r0,r1,r2 = string to find
	@ r3 = char to end at
	@ writes to r6

find_string:
	push	{r5,r7,lr}
	ldr	r7,disk_addr		@ look in cpuinfo buffer
find_loop:
	ldrb	r5,[r7]			@ load a byte
	cmp	r5,#0			@ off the end?
	beq	done			@ then finished	

	add	r7,#1			@ increment pointer	
	cmp	r5,r0			@ compare against first byte
	bne	find_loop

	ldrb	r5,[r7]			@ load next byte
	cmp	r5,r1
	bne	find_loop		@ if not equal, loop

	ldrb	r5,[r7,#1]		@ load next byte
	cmp	r5,r2
	bne	find_loop		@ if not equal, loop

					@ if all 3 matched, we are found

find_colon:
	ldrb	r5,[r7]			@ load a byte
	add	r7,#1			@ increment pointer
	cmp	r5,#':'
	bne	find_colon		@ repeat till we find colon

	add	r7,r7,#1		@ skip the space

store_loop:
	ldrb	r5,[r7]			@ load a byte, increment pointer
	strb	r5,[r6]			@ store a byte, increment pointer
	add	r7,#1			@ increment pointers
	add	r6,#1
	cmp	r5,r3
	bne	store_loop

almost_done:
	mov	r0,#0
	strb	r0,[r6]			@ replace last value with NUL
	sub	r6,#1			@ adjust pointer

done:
	pop	{r5,r7,pc}		@ return



	#==============================
	# center_and_print
	#==============================
	# string to center in at output_buffer

center_and_print:

	push	{r3,r4,LR}		@ store return address on stack

	ldr	r1,colors_addr		@ we want to output ^[[
	mov	r2,#2

	bl	write_stdout_we_know_size

str_loop2:
	ldr	r2,=out_buffer		@ point r2 to out_buffer
	sub	r2,r2,r6		@ get length by subtracting
					@ actually, negative value here
					@ an optimization...

					@ subtract r2 from 81
	adds	r2,#81			@ we use 81 to not count ending \n

	blt	done_center		@ if result negative, don't center

	lsr	r3,r2,#1		@ divide by 2

	mov	r0,#0			@ print to stdout
	bl	num_to_ascii		@ print number of spaces

	add	r1,#7			@ we want to output C
	blx	r9			@ write_stdout

done_center:
	ldr	r1,=out_buffer		@ point r1 to out_buffer
	blx	r9			@ write_stdout
	pop	{r3,r4,PC}		@ restore return address from stack

	@#############################
	@ num_to_ascii
	@#############################
	@ r3 = value to print
	@ r0 = 0=stdout, 1=strcat

num_to_ascii:

	push	{r1,r2,r3,r4,r5,LR}	@ store return address on stack
	ldr	r2,ascii_addr
	add	r2,#9			@ point to end of our buffer

	mov	r7,#10		@ we'll be dividing by 10
div_by_10:


	@===================================================
	@ Divide - because ARM has no hardware int divide
	@ yes this is an awful algorithm, but simple
	@  and uses few registers
	@==================================================
	@ r3=numerator   r7=denominator
	@ r5=quotient    r4=remainder

divide:
	mov	r5,#0		@ zero out quotient
divide_loop:
	mov	r1,r5		@ move Q temporarily to r2
	mul	r1,r7		@ multiply Q by denominator
	add	r5,#1		@ increment quotient
	cmp	r1,r3		@ is it greater than numerator?
	ble	divide_loop	@ if not, loop
	sub	r5,#2		@ otherwise went too far, decrement
				@ and done

	mov	r1,r5		@ move Q temporarily to r2
	mul	r1,r7		@ calculate remainder
	sub	r4,r3,r1	@ R=N-(Q*D)

@	bl	divide		@ Q=r5, R=r4
	add	r4,#0x30	@ convert to ascii
	strb	r4,[r2]		@ store a byte
	sub	r2,#1		@ decrement pointer
	movs	r3,r5		@ move Q in for next divide, update flags
	bne	div_by_10	@ if Q not zero, loop

write_out:
	add	r1,r2,#1	@ adjust pointer

	cmp	r0,#0
	beq	num_stdout

	mov	r5,r1
	blx	r10			@ if 1, strcat_r5
	pop	{r1,r2,r3,r4,r5,pc}	@ pop and return

num_stdout:
	blx	r9			@ else, fallthrough to stdout
	pop	{r1,r2,r3,r4,r5,pc}	@ pop and return


	#================================
	# strcat
	#================================
	# value to cat in r4
	# output buffer in r6
	# r3 trashed
strcat_r5:
	push	{r4,lr}
	mov	r4,r5
	blx	r11
	pop	{r4,pc}

strcat_r4:
	push	{r3,lr}
strcat_loop:
	ldrb	r3,[r4]			@ load a byte
	add	r4,#1			@ increment pointer
	strb	r3,[r6]			@ store a byte
	add	r6,#1			@ increment pointer
	cmp	r3,#0			@ is it zero?
	bne	strcat_loop		@ if not loop
	sub	r6,r6,#1		@ point to one less than null
	pop	{r3,pc}			@ return

	#================================
	# WRITE_STDOUT
	#================================
	# r1 has string
	# r0,r2,r3 trashed
write_stdout:
	mov	r2,#0				@ clear count

str_loop1:
	add	r2,#1
	ldrb	r3,[r1,r2]
	cmp	r3,#0
	bne	str_loop1			@ repeat till zero

write_stdout_we_know_size:
	mov	r0,#STDOUT			@ print to stdout
	mov	r7,#SYSCALL_WRITE
	swi	#0				@ run the syscall
	bx	lr				@ return


.align 2
@ data address
ver_addr:	.word ver_string
colors_addr:	.word default_colors
logo_addr:	.word logo
logo_end_addr:	.word logo_end

@bss addresses
uname_addr:	.word uname_info
sysinfo_addr:	.word sysinfo_buff
ascii_addr:	.word ascii_buffer
text_addr:	.word text_buf
disk_addr:	.word disk_buffer

@ constant values
pos_mask:	.word ((POSITION_MASK<<8)+0xff)
R:		.word (N-F)
NMINUS1:	.word (N-1)

@ function pointers
strcat_addr:	.word (strcat_r4+1)	@ +1 to make it a thumb addr
.align 1
#===========================================================================
#	section .data
#===========================================================================
.data
ver_string:	.asciz	" Version "
compiled_string:.asciz	", Compiled "
linefeed:	.asciz	"\n"
.ifdef FAKE_PROC
cpuinfo:	.asciz  "proc/cpui.arm"
.else
cpuinfo:	.asciz	"/proc/cpuinfo"
.endif
one:		.asciz	"One "
processor:	.asciz	" Processor, "
ram_comma:	.asciz	"M RAM, "
bogo_total:	.asciz	" Bogomips Total\n"

default_colors:	.asciz "\033[0m\n\n"
C:		.asciz "C"
		


.include	"logo.lzss_new"


#============================================================================
#	section .bss
#============================================================================
.bss
bss_begin:
.lcomm uname_info,(65*6)
.lcomm sysinfo_buff,(64)
.lcomm ascii_buffer,10
.lcomm text_buf, (N+F-1)
.lcomm	disk_buffer,4096	@ we cheat!!!!
.lcomm	out_buffer,16384



