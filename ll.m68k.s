|
|   linux_logo in m68k assembler 0.48
|
|   Originally by:
|		Vince Weaver <vince _at_ deater.net>
|
|   Optimizations contributed by:
|
|
|  assemble with     "as -o ll.o ll.m68k.s"
|  link with         "ld -o ll ll.o"

| Notes somewhat grumpily contributed by Matthew Hey:
|  * Did you not see that there is a TST instruction for CMP #0
|  * and ADDQ/SUBQ instead of LEA to add/sub small immediates including to
|    address registers?
|  * You can do MOVE EA,EA where EA is almost any addressing mode and MOVE
|    sets the condition codes for a Bcc without a CMP or TST
|  * You use LEA where you shouldn't but not where you should which is
|    instead of MOVE.L #address,An.

| From the m68k programming manual:
|   16 general purpose 32-bit registers, d7-d0, a7-a0
|   32-bit program counter, 8-bit condition code register
|   stack pointer is a7, frame pointer is a6
|   condition codes are Carry, oVerflow, Zero, Negative, eXtend
|   address registers cannot be used for byte-sized operations
|   bigendian architecture
|   instructions are variable length, from 1 to 11 16-bit words


| From google searches:
| Syscalls:
|   trap #0 instruction.  Syscall num on d0, arguments in d1-d?

| gleaned from the as info file
|   comment character is | (need --bitwise-or if need to use it for or)
|   m68k assemly developed at MIT? compatible with Sun assembler
|   %a0-%a7 = gp regs.  %pc , %zpc (zero address regard to pc)
|   %za0-%za7 (suppressed address reg?)

| Crazy number of addressing modes (18):
|   Immediate: $NUM
|   Data reg direct:    %d0-%d7
|   Address reg direct: %a0-%a7  %a7=stack pointer, %a6=frame pointer
|   Addr reg indirect:  %a0@ through %a7@
|   Addr reg postincrement: %a0@+ - %a7@+
|   Addr reg postdecrement: %a0@- - %a7@-
|   Indirect plus offset: %a0@(NUMBER)
|   Index: %a0@(NUMBER,REGISTER:SIZE:SCALE)
|   Postindex: %a0(NUMBER)@(ONUMBER,REGISTER:SIZE:SCALE)
|   Preindex:  APC@(NUMBER,REGISTER:SIZE:SCALE)@(ONUMBER)
|   Absolute:  SYMBOL or DIGITS?
|
|  There is an alternate morotolla syntax that gas can also handle
| exg = exchange, lea=load effecive address,
| link= update stack frame

| move
|   N and Z updated.
|   can move to and from the CCR register
| move16 = moves 16-byte block
| movem stores a list of registers to memory (or stack)

|	movem.l	%d0-%d7/%a0-%a6,-(%sp)
|	move.l	%d5,%d1
|	moveq.l	#0,%d0
|	bsr	num_to_ascii
|	movem.l	(%sp)+,%d0-%d7/%a0-%a6

| movep = output to 8-bit peripheral
| moveq = move quick (load an 8-bit value)
| pea = push immediate on stack
| unlk reverse of link

| add (works on d regs), adda (works on a regs)
| addi = immediate, addq = immediate value of 1-8
| addx = add two regs plus the X condition code
| clr (set to zero) cmp,cmpi,cmpa (compare), cmpm (compare memory)
| cmp2 (compare if in range?) like chk but sets CCR, doesn't trap

| divs/divu
| chk = check register against bound, trap. chk2 compare between two bounds

| ext,extb sign extend
| muls,mulu - multiply (signed/unsigned)
| neg=negate,negx=substrat 0-dest-X CCR
| sub,suba,subi,subq,subx
| and,andi,eor,eori,not,or,ori
|    andi,eori,ori  can have CCR as destination
| asl,asr=arithmatic shift
|  shifted out values goes to both C and X
| lsl,lsr=logical shift
|   shifted out goes to C and X, 0 is shifted in.  shift value can be imm or r
| rol,ror = rotate.  the rotated off bit also goes into C
| roxl roxr rotate through X
| swap = swap high and low words
| bchg,bclr,bset,btst = bit mabipulation options
|  bchg tests a bit and sets the Z flag, then inverts the bit?!
|  bcl rests a bit and sets the Z flag, then clears the bit
|  bset tests a bit and sets the z flag and sets the bit
|  btst just tests the bit and sets Z


| bfchg,bfclr,bfexts,bfextu,bfffo,bfins,bfset,bfst = bitfield manipulation
|  bfchg is like bchg, just N is also set if the high bit is set
|  bfexts exracts bit field and sign extends (bfextu is same, zero extended)
|  bfffo finds first one in a bit field
|  bfins inserts a bit field
|  bfset set N and C based on bitfield of ea, and sets the bits
|  bftst like above but no setting

| abcd,nbcd,pack,sbcd,unpk = bcd instructions

| CC = one of CC,CS (carry clear/set) EQ NE GE GT LE LT (comparison)
|      HI,LS (low), MI (minus),  PL (plus) VC, VS (overflow clear/set)
| bCC = branch
| dbCC = check condition.  If true, nothing.  If not-true,
|        decrement counter and brach (a loop instruction)
|        ie, DBMI=decrememnt and loop until minus
|        in addition to normal flags, also F and T (false and true)

| sCC = if condition code than 1s to result, else 0s to result
| bra=branch always, bsr=branch subroutine
|   bsr pushes return value on stack

| jmp,jsr=push return address on stack
| nop = also forces all pending bus transactions to complete
| rtd = returns (pulls pc off stack) and adds displacement to stack
| rtr = return and pull CCR from stack
| rts = just pulls pc from stack

| assembly has two operations, ie add source,destination



| many others for fp, system mode (cache invalidation,mmu,smp,etc)


| Optimization
| + 1078 - First working version
| + 1062 - Make all strcat calls use %a5
| + 1038 - Make out_buffer be stored in %a6
| + 1038 - Use the "dbf" instruction in a loop (saves 2 words)
| + 1030 - (note, only goes down 4 bytes at a time)
|          Make sure to use addq instead of addi, don't recopy the uname pointer
| + 1014 - Change the printing code to use linear %a1 instead of re-loading
|          each time
| lots of time passes, start optimizing based on e-mail from Matthew Hay
| +  982 - where we stand in May of 2017
| +  978 - use bra.b instead of jump various places
| +  970 - use .b suffix on a few other branches
| +  938 - use .b suffix on all other branches if possible
| +  938 - specifically use addq (recent gas seems to do this for you)
| +  934 - complicated move.l to 16-bit lea conversion in prelude
| +  928 - we have a spare reg so use counter rather than shifter
|          to keep track of the bits left if flag byte.
|          This saves a lot because it is hard to load 0xff00 on m68k
| +  922 - load a word and endian swap rather than make byte-by-byte
| +  922 - mask with d3 register not consant.  Overall program size
|          is the same but lzss size decreased
| +  920 - move P_BITS into a register
| +  918 - move/lea conversion
| +  912 - adjust pointers with addq rather than lea
| +  908 - find_string, use auto-increment addressing directly rather
|          than loading a byte and then operating
| +  906 - use fancy addressing in strcat to do move in one instruction
| +  898 - fix lots of silly redundant instructions in center_and_print
| +  894 - use tst instead of cmp
| +  890 - write lf/nul in one word byte
| +  890 - switch strcat to be in %a6 to free up %a5
| +  872 - use lea against %a5 for bss addressing
| +  870 - keep the saved output pointer in %a6

.include "logo.include"


| offsets into the results returned by the uname syscall
.equ U_SYSNAME,0
.equ U_NODENAME,65
.equ U_RELEASE,65*2
.equ U_VERSION,(65*3)
.equ U_MACHINE,(65*4)
.equ U_DOMAINNAME,65*5

| offset into the results returned by the sysinfo syscall
.equ S_TOTALRAM,16

| Sycscalls
.equ SYSCALL_EXIT,	1
.equ SYSCALL_READ,	3
.equ SYSCALL_WRITE,	4
.equ SYSCALL_OPEN,	5
.equ SYSCALL_CLOSE,	6
.equ SYSCALL_SYSINFO,	116
.equ SYSCALL_UNAME,	122

|
.equ STDIN,0
.equ STDOUT,1
.equ STDERR,2

	.globl _start
_start:


	|=========================
	| PRINT LOGO
	|=========================

| LZSS decompression algorithm implementation
| by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
| optimized some more by Vince Weaver

| Set up a registers


	| lea is only a win over move.l if we don't have a separate
	| data segment.
	| figuring out forcing 16-bit lea in gas syntax was a pain

	lea	bss_begin,%a5		| bss base ptr
	lea	%pc@(logo),%a3		| a3 points to logo data
	lea	%pc@(logo_end),%a4	| a4 points to logo end
	lea	%a5@(out_buffer-bss_begin:w),%a6	| buffer we are printing to
	lea	%a5@(text_buf-bss_begin:w),%a0		| a0 points to text buf
	move.l	%a6,%a1

| Set up d registers

	move.l	#P_BITS,%d0
	move.l  #(N-F),%d2		| R
	move.w	#(N-1),%d3		| mask (N-1)= ((POSITION_MASK<<8)+0xff)
					|           = 0x3ff

| *** LZSS code begin ***

decompression_loop:
	move.q	#7,%d7		| load a counter
	move.b	%a3@+,%d5	| load a byte, increment pointer

test_flags:
	cmp.l	%a4,%a3		| have we reached the end?
	bge.b	done_logo  	| if so, exit

	lsr.w 	#1,%d5		| shift bottom bit into carry flag
	bcs.b	discrete_char	| if set, we jump to discrete char

offset_length:
|	clr.l   %d4		| (unnecessary?)
	move.w	%a3@+,%d4	| load 16-bits, increment pointer
	ror.w	#8,%d4		| unfair big-endian penalty

	move.l	%d4,%d6		| copy d4 to d6
				| no need to mask d6, as we do it
				| by default in output_loop

	lsr.l	%d0,%d4		| unsigned shift right by P_BITS
	addq.l	#(THRESHOLD+1),%d4

	add.w	%d4,%d1
				| d1 = (d4 >> P_BITS) + THRESHOLD + 1
				|                       (=match_length)

output_loop:
	and.w	%d3,%d6			| mask it
	move.b 	%a0@(0,%d6),%d4		| load byte from text_buf[]
	addq.w	#1,%d6			| advance pointer in text_buf

store_byte:

	move.b	%d4,%a1@+		| store a byte, increment pointer
	move.b	%d4,%a0@(0,%d2)		| store a byte to text_buf[r]
	addq.w 	#1,%d2			| r++
	andw	%d3,%d2			| mask r

	dbf	%d1,output_loop		| decrement count and loop
					| if %d1 is zero or above

	dbf	%d7,test_flags		| decement flags counter
					| if not zero, continue

	bra.b	decompression_loop	| need to load new byte

discrete_char:

	move.b	%a3@+,%d4		| load a byte, increment pointer
	clr.l	%d1			| we set d1 to zero which on m68k
					| means do the loop once

	bra.b	store_byte		| and store it


| *** LZSS code end ***

done_logo:
	move.l	%a6,%a3			| out_buffer we are printing to

	bsr.w	write_stdout		| print the logo

optimizations:
	| Optimization setup

	lea	%pc@(strcat),%a4	| load strcat address into %a4


	|==========================
	| PRINT VERSION
	|==========================
first_line:
	move.l	%a5,%d1				| uname struct

	moveq.l	#SYSCALL_UNAME,%d0
	trap	#0				| do syscall

	move.l	%d1,%a1
						| os-name from uname "Linux"

	move.l	%a6,%a2				| point %a2 to out_buffer

	jsr	(%a4)				| call strcat

	lea	%pc@(ver_string),%a1		| source is " Version "
	jsr 	(%a4)			        | call strcat

	move.l	%a1,%d4
	lea	%a5@((uname_info-bss_begin)+U_RELEASE:w),%a1
						| version from uname, ie "2.6.20"
	jsr	(%a4)				| call strcat
	move.l	%d4,%a1

						| source is ", Compiled "
	jsr	(%a4)				|  call strcat

	move.l	%a1,%d4
	lea	%a5@((uname_info-bss_begin)+U_VERSION:w),%a1
						| compiled date
	jsr	(%a4)				| call strcat

	move.l	%d4,%a1

	move.w	#0xa00,%a2@+		| store a linefeed, NUL terminate
					| increment pointer

	bsr.w	center_and_print	| center and print

	|===============================
	| Middle-Line
	|===============================
middle_line:

	|=========
	| Load /proc/cpuinfo into buffer
	|=========

	move.l	%a6,%a2			| point a2 to out_buffer

	move.l	#(cpuinfo),%d1
					| '/proc/cpuinfo'
	moveq.l	#0,%d2			| 0 = O_RDONLY <bits/fcntl.h>
	moveq.l	#SYSCALL_OPEN,%d0
	trap	#0			| syscall.  return in d0? 
	move.l	%d0,%d5			| save our fd

	move.l	%d0,%d1			| move fd to right place
	move.l	#disk_buffer,%d2
	move.l	#4096,%d3
				 	| 4096 is maximum size of proc file ;)
	move.l	#SYSCALL_READ,%d0
	trap	#0

	move.l	%d5,%d1
	move.l	#SYSCALL_CLOSE,%d0
	trap	#0
					| close (to be correct)


	|=============
	| Number of CPUs
	|=============
number_of_cpus:

					| cheat.  Who has an SMP arm?
	jsr	(%a4)

	|=========
	| MHz
	|=========
print_mhz:

	move.l	#(('i'<<24)+('n'<<16)+('g'<<8)+':'),%d0
	bsr.b	find_string
					| find 'ing:' and grab up to '\n'

	move.b  #' ',%a2@+		| put in a space

	|=========
	| Chip Name
	|=========
chip_name:
	move.l	#(('C'<<24)+('P'<<16)+('U'<<8)+':'),%d0
	bsr.b	find_string
					| find 'CPU:' and grab up to '\n'

					| print " Processor, "
	jsr	(%a4)

	|========
	| RAM
	|========

	lea	%a5@(sysinfo_buff-bss_begin:w),%a0
	move.l	%a0,%d1		   	| copy
	moveq.l	#SYSCALL_SYSINFO,%d0
	trap	#0
					| sysinfo() syscall

	move.l	%a0@(S_TOTALRAM),%d1	| size in bytes of RAM
	moveq.l #20,%d3
	lsr.l	%d3,%d1			| divide by 1024*1024 to get M
|	adc	r3,r3,#0		| round

	moveq.l	#1,%d0
	move.l	%a1,%d4
	bsr.w	num_to_ascii
	move.l	%d4,%a1

					| print 'M RAM, '
	jsr	(%a4)			| call strcat


	|========
	| Bogomips
	|========
        move.l	#(('i'<<24)+('p'<<16)+('s'<<8)+':'),%d0
	bsr.b	find_string
					| find 'ips:' and grab up to '\n'

	jsr	(%a4)			| print bogomips total

	bsr.b	center_and_print	| center and print

	|=================================
	| Print Host Name
	|=================================
last_line:
	move.l	%a6,%a2			| point a2 to out_buffer

	lea	%a5@(U_NODENAME),%a1
					| host name from uname()
	jsr	(%a4)			| call strcat

	bsr.b	center_and_print	| center and print

	lea	%pc@(default_colors),%a3
					| restore colors, print a few linefeeds
	bsr.b	write_stdout


	|================================
	| Exit
	|================================


exit:
     	moveq.l	#0,%d1			| return a 0
	moveq.l	#SYSCALL_EXIT,%d0
	trap	#0		 	| and exit


	|=================================
	| FIND_STRING
	|=================================
	| %d0 = string to find

find_string:

|	move.l	#(disk_buffer-1),%a3	| look in cpuinfo buffer
	lea	%a5@(disk_buffer-bss_begin-1:w),%a3
					| look in cpuinfo buffer

find_loop:
	addq.l	#1,%a3			| add one to pointer
	move.l	%a3@,%d1		| load an unaligned word
	beq.b	done			| if off the end, finish
	cmp.l	%d1,%d0
	bne.b	find_loop

	addq.l	#4,%a3			| skip what we just searched
skip_tabs:
	cmp.b	#'\t',%a3@+		| read byte, inc, are we a tab?
	beq.b	skip_tabs		| if so, loop

	subq.l	#1,%a3			| adjust pointer
store_loop:
	move.b	%a3@+,%d3		| load a byte, increment pointer
	move.b	%d3,%a2@+		| store a byte, increment pointer
	cmp.b	#'\n',%d3
	bne.b	store_loop

almost_done:
	clr.b	%a2@-			| replace last value with NUL

done:
	rts				| return


	|==============================
	| center_and_print
	|==============================
	| string to center in at output_buffer

center_and_print:

	lea	%pc@(escape),%a3	| we want to output ^[[
	bsr.b	write_stdout

	suba.l	%a6,%a2			| get length by subtracting
					| a2 = a2-a6
	moveq.l	#81,%d1
	sub.l	%a2,%d1			| subtract! d1=d1-a2
					| we use 81 to not count ending \n

	bmi.b	done_center		| if result negative, don't center

	lsr	#1,%d1			| divide by 2
|	addx.l	%d1,#0     		| round?

	moveq.l	#0,%d0			| print to stdout
	bsr	num_to_ascii		| print number of spaces

	lea	%pc@(C),%a3		| we want to output C

	bsr.b	write_stdout

done_center:
	move.l	%a6,%a3

	|================================
	| WRITE_STDOUT
	|================================
	| a3 has string
	| d0,d1,d2,d3 trashed
write_stdout:
	moveq.l	#0,%d3				| clear count

str_loop1:
	addq.l	#1,%d3
	move.b	%a3@(0,%d3),%d2
	bne.b	str_loop1			| repeat till zero

write_stdout_we_know_size:
	move.l	%a3,%d2
	moveq.l	#STDOUT,%d1			| print to stdout
	moveq.l	#SYSCALL_WRITE,%d0		| load the write syscall
	trap	#0				| actually run syscall
	rts					| return


	|#############################
	| num_to_ascii
	|#############################
	| d1 = value to print
	| d0 = 0=stdout, 1=strcat
	| a3 = special(?)
	| d2 = trashed

num_to_ascii:
	lea	%a5@(ascii_buffer-bss_begin+10:w),%a3
				| point to end of our buffer

div_by_10:
	divu.w	#10,%d1		| divide by 10.  Q in lower, R in upper
	bfextu	%d1,0:16,%d2	| copy remainder to %d2
	bfextu	%d1,16:16,%d1	| mask out quotient into %d1

	add.w	#0x30,%d2	| convert to ascii
	move.b	%d2,%a3@-	| store a byte, decrement pointer
	tst.w	%d1
	bne.b	div_by_10	| if Q not zero, loop

write_out:
	tst.w	%d0
	beq.s	ascii_stdout

	move.l	%a3,%a1
	jmp	(%a4)		| if 1, strcat

ascii_stdout:
	bra.b 	write_stdout	| else, fallthrough to stdout


	|================================
	| strcat (like stpcpy)
	|================================
	| value to cat in a1
	| output buffer in a2
strcat:
        move.b	%a1@+,%a2@+		| copy byte, increment pointers
	bne.b	strcat			| loop if not zero
	subq.l	#1,%a2			| point to one less than null
	rts				| return



#===========================================================================
#	section .data
#===========================================================================
# Static (read only) data is combined with code just like compilers do.
# This allows for efficient PC relative addressing to access the data.
#===========================================================================

|.data
data_begin:
ver_string:		.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
one:			.ascii	"One \0"
processor:		.ascii	" Processor, \0"
ram_comma:		.ascii	"M RAM, \0"
bogo_total:		.ascii	" Bogomips Total\n\0"

default_colors:		.ascii "\033[0m\n\n\0"
escape:			.ascii "\033[\0"
C:			.ascii "C\0"

.ifdef FAKE_PROC
cpuinfo:		.ascii	"proc/cpu.m68k\0"
.else
cpuinfo:		.ascii	"/proc/cpuinfo\0"
.endif

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

.lcomm	disk_buffer,4096	| we cheat!!!!
.lcomm	out_buffer,16384


	# see /usr/src/linux/include/linux/kernel.h

