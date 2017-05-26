@
@  linux_logo in ARM THUMB-2 assembler 0.46
@
@  By
@       Vince Weaver <vince _at_ deater.net>
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

@  -- crazy immediate encoding.  Does have 12 bits, but allocated as such
@     top 4 bits 0000 -- 00000000 00000000 00000000 abcdefgh
@                0001 -- 00000000 abcdefgh 00000000 abcdefgh
@                0010 -- abcdefgh 00000000 abcdefgh 00000000
@                0011 -- abcdefgh abcdefgh abcdefgh abcdefgh
@                0100 -- 1bcdedfh 00000000 00000000 00000000
@                 ...
@                1111 -- 00000000 00000000 00000001 bcdefgh0

@ Optimizing:
@ LZSS
@  -- 70 bytes, where it stood for a while
@  -- 68 bytes, due to mvns interting trick, found on a random internet
@               thread (people, send your fixes too me!)
@
@ Overall
@  -- 1145 bytes, direct port of THUMB code
@  --  957 bytes, make sure we use 16-bit encoding whenever possible
@                 (this mostly meant adding .n or s to the opcodes)
@  --  953 bytes, use cbz (compare and branch zero) THUMB2 instruction
@  --  949 bytes, use ldmia to load initial constants
@  --  941 bytes, use mul instead of subtract for div_by_10
@  --  937 bytes, use movw to load 16-bit constants
@  --  935 bytes, eliminate use of r0 as temp, moving one var down to low
@  --  933 bytes, change 16-bit compare to 8-bit compare
@  --  929 bytes, can mask simply with lsl/lsr
@  --  927 bytes, change another mask to lsl/lsr
@  --  925 bytes, load one more reg via ldm
@  --  924 bytes, move logo to beginning of data segment
@  --  920 bytes, use pc-relative to load addresses_begin
@  --  916 bytes, get logo address for free after ldm
@  --  912 bytes, or in 0x8000 rather than 0xff00
@  --  912 bytes, smaller loads with additional add rather than more complex
@  --  908 bytes, remove unnecessary copy, take advantage of 3-operand

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

	@ r0 = text_addr
	@ r1 = output_buffer
	@ r2 = R
	@ r3 = logo_data
	@ r4 = temp
	@ r5 = counter
	@ r6 = position
	@ r7 = match length
	@ r8 = logo end

	adr	r3,addresses_begin
	ldm	r3!,{r0,r1,r2,r8,r11,r12}
					@ r12 is a dummy value to
					@ skip a literal value


decompression_loop:
	ldrb	r5,[r3]		@ load a byte
	adds	r3,r3,1		@ increment pointer

	mvns	r5,r5		@ set top 24 bits to one
				@ (while inverting sense of the low byte)

test_flags:
	cmp	r3,r8		@ have we reached the end?
	bge.n	done_logo  	@ if so, exit

	lsrs 	r5,#1		@ shift bottom bit into carry flag

	ittt cc			@ If shifted a zero then run next
				@ 4 instructions
discrete_char:

	ldrbcc	r4,[r3]		@ load a byte
	addcc	r3,#1		@ increment pointer
	movcc	r6,#1		@ we set r6 to one byte to write out

	bcc.n	store_byte	@ and store it

offset_length:

	ldrb	r4,[r3]		@ load a byte, increment pointer
	ldrb	r7,[r3,#1]	@ load a byte, increment pointer
	adds	r3,r3,#2
				@ we can't load halfword
				@ as no unaligned loads on original arm

				@ FIXME: recent arms do have unaligned?

	orrs	r7,r4,r7, LSL #8	@ merge back into 16 bits
				@ this has match_length and match_position

				@ no need to mask r7, as we do it
				@ by default in output_loop

	movs	r4,#(THRESHOLD+1)
	add	r6,r4,r7,LSR #(P_BITS)
				@ r6 = (r6 >> P_BITS) + THRESHOLD + 1
				@                       (=match_length)

output_loop:
@	movw	r4,((POSITION_MASK<<8)+0xff)
@	ands	r7,r4			@ mask it

					@ Assume
					@ ((POSITION_MASK<<8)+0xff) = 0x3ff
	lsls	r7,#22			@ shift up to see if bit 10 set
	lsrs	r7,#22			@ otherwise restore value

	ldrb 	r4,[r0,r7]		@ load byte from text_buf[]
	adds	r7,#1			@ advance pointer in text_buf

store_byte:
	strb	r4,[r1],#+1		@ store a byte, increment pointer
	strb	r4,[r0,r2]		@ store a byte to text_buf[r]
	adds	r2,#1			@ r++

					@ can't mask with 0x3ff due
					@ to thumb2's crazy immediate
					@ values

					@ was wasting a reg as a temp
					@ value

					@ So mask another way
					@ 22 = 32-log2(N)

	lsls	r2,#22			@ shift up to see if bit 10 set
	lsrs	r2,#22			@ otherwise restore value

	subs	r6,#1			@ decement count
	bne.n 	output_loop		@ repeat until k>j

	lsrs    r4, r5, #25		@ check to see if shifted 8 bits
					@ by seeing if 24th bit zero

	bcs.n	test_flags		@ if not, re-load flags
	b.n	decompression_loop

# end of LZSS code

done_logo:
	ldr	r1,out_addr		@ buffer we are printing to

	mov	r0,r11			@ point r11 to "strcat_r4"
	subs	r0,#8
	mov	r10,r0			@ point r10 to "strcat_r5"
	subs.n	r0,#(strcat_r5-write_stdout)
	mov	r9,r0			@ point r9 to "write_stdout"

	subs.n	r0,#(write_stdout-center_and_print)
	mov	r8,r0

	blx	r9			@ print the logo



	#==========================
	# PRINT VERSION
	#==========================

first_line:
	ldr	r0,uname_addr
	mov	r5,r0			@ point r5 at uname buffer
	movs	r7,#SYSCALL_UNAME
	swi	#0			@ do uname syscall

					@ os-name from uname "Linux"

	ldr	r6,out_addr		@ point r6 to out_buffer

	blx	r10			@ call strcat_r5

	ldr	r4,ver_addr		@ source is " Version "

	blx 	r11			@ call strcat_r4

	adds	r5,#U_RELEASE
					@ version from uname, ie "2.6.20"
	blx	r10			@ call strcat_r5

					@ source is ", Compiled "
	blx	r11			@ call strcat_r4

	adds	r5,#(U_VERSION-U_RELEASE)
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

	ldr	r6,out_addr		@ point r6 to out_buffer

	mov	r0,r4			@ point r0 to '/proc/cpuinfo'

	movs	r1,#0			@ 0 = O_RDONLY <bits/fcntl.h>
	movs	r7,#SYSCALL_OPEN
	swi	#0			@ syscall.  return in r0?

	mov	r3,r0			@ save our fd

	ldr	r1,disk_addr
	mov	r2,#4096		@ 4096 is maximum size of proc file ;)
	movs	r7,#SYSCALL_READ
	swi	#0

	mov	r0,r3			@ restore fd
	movs	r7,#SYSCALL_CLOSE
	swi	#0			@ close (to be correct)


	@=============
	@ Number of CPUs
	@=============
number_of_cpus:

					@ cheat.  Who has an SMP arm?
					@ 2012 calling, my pandaboard is one
	adds	r4,#14			@ length of /proc/cpuinfo
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

	movs	r0,#'a'
	movs	r1,#'r'
	movs	r2,#'e'
	movs	r3,#'\n'
	bl	find_string
					@ find 'sor\t: ' and grab up to ' '

	blx	r11			@ print " Processor, "

ram:
	@========
	@ RAM
	@========
	ldr	r0,sysinfo_addr
	mov	r2,r0

	movs	r7,#SYSCALL_SYSINFO
	swi	#0			@ sysinfo() syscall

	adds	r2,#S_TOTALRAM
	ldr	r3,[r2]
					@ size in bytes of RAM
	lsrs	r3,#20			@ divide by 1024*1024 to get M

	movs	r0,#1
	bl num_to_ascii

					@ print 'M RAM, '
	blx	r11			@ call strcat

bogomips:
	@========
	@ Bogomips
	@========

	movs	r0,#'I'
	movs	r1,#'P'
	movs	r2,#'S'
	movs	r3,#'\n'
	bl	find_string

	blx	r11			@ print bogomips total

	blx	r8			@ center and print

	#=================================
	# Print Host Name
	#=================================
last_line:
	ldr	r6,out_addr		@ point r6 to out_buffer

	subs	r5,#(U_VERSION-U_NODENAME)
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
	movs	r0,#0				@ result is zero
	movs	r7,#SYSCALL_EXIT
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
	cbz	r5,done
	@cmp	r5,#0			@ off the end?
	@beq.n	done			@ then finished

	adds	r7,#1			@ increment pointer
	cmp	r5,r0			@ compare against first byte
	bne.n	find_loop

	ldrb	r5,[r7]			@ load next byte
	cmp	r5,r1
	bne.n	find_loop		@ if not equal, loop

	ldrb	r5,[r7,#1]		@ load next byte
	cmp	r5,r2
	bne.n	find_loop		@ if not equal, loop

					@ if all 3 matched, we are found

find_colon:
	ldrb	r5,[r7]			@ load a byte
	adds	r7,#1			@ increment pointer
	cmp	r5,#':'
	bne.n	find_colon		@ repeat till we find colon

	adds	r7,r7,#1		@ skip the space

store_loop:
	ldrb	r5,[r7]			@ load a byte, increment pointer
	strb	r5,[r6]			@ store a byte, increment pointer
	adds	r7,#1			@ increment pointers
	adds	r6,#1
	cmp	r5,r3
	bne.n	store_loop

almost_done:
	movs	r0,#0
	strb	r0,[r6]			@ replace last value with NUL
	subs	r6,#1			@ adjust pointer

done:
	pop	{r5,r7,pc}		@ return



	#==============================
	# center_and_print
	#==============================
	# string to center in at output_buffer

center_and_print:

	push	{r3,r4,LR}		@ store return address on stack

	ldr	r1,colors_addr		@ we want to output ^[[
	movs	r2,#2

	bl	write_stdout_we_know_size

str_loop2:
	ldr	r2,out_addr		@ point r2 to out_buffer
	subs	r2,r2,r6		@ get length by subtracting
					@ actually, negative value here
					@ an optimization...

					@ subtract r2 from 81
	adds	r2,#81			@ we use 81 to not count ending \n

	blt.n	done_center		@ if result negative, don't center

	lsrs	r3,r2,#1		@ divide by 2

	movs	r0,#0			@ print to stdout
	bl	num_to_ascii		@ print number of spaces

	adds	r1,#7			@ we want to output C
	blx	r9			@ write_stdout

done_center:
	ldr	r1,out_addr		@ point r1 to out_buffer
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
	adds	r2,#9			@ point to end of our buffer

        @===================================================
        @ div_by_10: because ARM has no divide instruction
        @==================================================
        @ r3=numerator
        @ r7=quotient    r1=remainder
div_by_10:
        ldr     r4,=429496730	@ 1/10 * 2^32
        umull   r4,r7,r4,r3	@ {r4,r7}=r4*r3

        movs	r4,#10		@ calculate remainder
	mls	r1,r4,r7,r3	@ r1 = r3 - (r4*r7)
        adds	r1,r1,#0x30	@ convert to ascii
        strb	r1,[r2]		@ store a byte, decrement pointer
        subs	r2,#1
        adds	r3,r7,#0	@ move Q in for next divide, update flags
        bne.n	div_by_10	@ if Q not zero, loop


write_out:
	adds	r1,r2,#1	@ adjust pointer

	cbz	r0,num_stdout
#	beq.n	num_stdout

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
	adds	r4,#1			@ increment pointer
	strb	r3,[r6]			@ store a byte
	adds	r6,#1			@ increment pointer
	cmp	r3,#0			@ is it zero?
	bne.n	strcat_loop		@ if not loop
	                                @ cbz insn only goes forward
	subs	r6,r6,#1		@ point to one less than null
	pop	{r3,pc}			@ return

	#================================
	# WRITE_STDOUT
	#================================
	# r1 has string
	# r0,r2,r3 trashed
write_stdout:
	movs	r2,#0				@ clear count

str_loop1:
	adds	r2,#1
	ldrb	r3,[r1,r2]
	cmp	r3,#0
	bne.n	str_loop1			@ repeat till zero

write_stdout_we_know_size:
	movs	r0,#STDOUT			@ print to stdout
	movs	r7,#SYSCALL_WRITE
	swi	#0				@ run the syscall
	bx	lr				@ return


.align 2

ver_addr:	.word ver_string
colors_addr:	.word default_colors

uname_addr:	.word uname_info
sysinfo_addr:	.word sysinfo_buff
ascii_addr:	.word ascii_buffer
disk_addr:	.word disk_buffer

addresses_begin:
@ These need to be consecutive; loaded by ldmia
text_addr:	.word text_buf
out_addr:	.word out_buffer
R:		.word (N-F)
@logo_addr:	.word logo
logo_end_addr:	.word logo_end
strcat_addr:	.word (strcat_r4+1)	@ +1 to make it a thumb addr



@ function pointers
.align 1
#===========================================================================
#	section .data
#===========================================================================
.data
.include	"logo.lzss_new"
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




#============================================================================
#	section .bss
#============================================================================
.bss
bss_begin:
.lcomm	uname_info,(65*6)
.lcomm	sysinfo_buff,(64)
.lcomm	ascii_buffer,10
.lcomm	text_buf, (N+F-1)
.lcomm	disk_buffer,4096	@ we cheat!!!!
.lcomm	out_buffer,16384

