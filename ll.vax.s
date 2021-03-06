#
#  linux_logo in vax assembler 0.48
#
#  By:
#       Vince Weaver <vince _at_ deater.net>
#
#  Further optimization by:
#       Anders Magnusson <ragge _at_ ludd.ltu.se>
#
#  assemble with     "as -o ll.o ll.vax.s"
#  link with         "ld -o ll ll.o"
#
#  I have to cross-compile, so what I do is was more like
#      make CROSS=vax-linux- ARCH=vax

# gnu assembler differences from DEC assembler:
#  immediate char is $  (not #)
#  indirect char is *   (not @)
#  displacement sizing char is ` (not ^)
#  bitfields are not supported

# watch out for being able to use minimal sized jumps

#
# Has support for using variable length bitfields as an arbitrarily sized
#   integer!  Crazy.  gnu assembler doesn't support this.
# Hardware support for queues and strings?

# 16 32-bit general purpose registers.  Processor status longword.
#   r15=pc, r14=sp, r13=fp, r12=ap (argument pointer)
# Little-endian
# variable length instructions, 0-6 arguments
# >32 bit values are stored in adjacent registers

# crazy amount of addressing modes
#  + register
#  + register deferred  (deferred means load from memory address in reg)
#  + autodecrement   -(r1)
#  + autoincrement    (r1)+
#  + immediate address mode
#  + autoincrement deferred  *(r1)+
#  + absolute
#  + byte displacement
#  + word displacement
#  + longword displacement
#  + byte displace deferred
#  + word displace deferred
#  + longword displace deferred
#  + indexed   (%r5)[r4]

# cannot use PC or SP with instructions that group more than one reg together

#
# Syscalls are complicated, they are treated like a function call
#    save the ap register (argument pointer reg)
#    push the arguments in reverse order
#    push the number of arguments
#    move syscall into r0
#    run "chmk %r0"
#    restore the stack
#    restore the ap register
# Luckily you can avoid most of the above by creating a syscall helper
#   function and using the "calls" function which does most of this
#   for you

# If you call a subroutine, it has an "Entry mask" as the first 16-bits
#   which says which regs to save/restore.  If you don't get this right
#   weird errors will happen.

# Integer opcodes:
# + adawi - add aligned word interlock (locking)
# + addb2,addb3,addw2,addw3,addl2,addl3 (2 and 3 operation adds of var sizes)
# + adwc - add with carry
# + ashl,ashq - arithmetic shift.  Shift negative for left, pos for right
# + bicb2,bicb3,bicw2,bicw3,bicl2,bicl3 - bit clear
# + bisb2,bisb3,bisw2,bisw3,bisl2,bisl3 - bit set
# + bitb,bitw,bitl - bit test
# + clrb,clrw,clrl,clrq,clro - clear reg to 0 (1 byte shorter than a move)
# + cmpb,cmpw,cmpl - compare
# + cvtbw,cvtbl,cvtwb,cvtwl.cvtlb,cvtlw - convert type.  sign-extends or truncs
# + decb,decw,decl - decrement.  (1 byte shorter than subtract)
# + divb2,divb3,divw2,divw3,divl2,divl3 - divide
# + ediv - extended divide (with remainder)
# + emul - extended multiply (with 64-bit result)
# + incb,ibcw,incl - increment (1 byte shorter than an add)
# + mcomb,mcomw,mcoml - move complement
# + mnegb,mnegw,mnwgl - move negated
# + movb,movw,movl,movq,movo - move (updates flags)
# + movzbw,movzbl,movzwl - move zero extended
# + mulb2,mulb3,mulw2,mulw3,mull2,mull3 - multiply
# + pushl - push long (equiv to movl src, -(sp) but one byte shorter)
# + rotl - rotate long
# + sbwc - subtract with carry
# + subb2,subb3,subw2,subw3,subl2,subl3 - subtract
# + tstb,tstl,tstw - test (equiv to compare with 0, but one byte shorter)
# + xorb2,xorb3,xorw2,xorw3,xorl2,xorl3 - xor

# address opcodes
# + movab,movaw,moval,movaf,movaq,movad,movag,movah,movao - move address ?
# + pushab,pushaw,pushal,pushaf,pushaq,pushad,pushag,pushah,pushao - push addy

# variable bitlength opcodes
# + cmp,ext,ff,insv
#   - i leave these out, gas can't assemble them

# control instructions
# + acbb,acbw,acbl,acbf,acbd,acbg,acbh - add compare and branch
# + aobleq - add one and branch less than or equal
# + aoblss - add one and branch less than
# + bgtr,bleq,bneq,bnequ,beql,beqlu,bgeq,blss,bgtru,blequ
# + bvc,bvs,bgequ,bcc,blssu,bcs - various branches, signed and unsigned
# + bbs,bbc - branch on bit set/clea
# + bbss,bbcs,bbsc,bbcc - branch on bit and set/clear
# + bbssi,bbcci - branch on bit set and set/clear interlocked
# + blbs, blbc - branch on low bit set/clear
# + brb,brw - branch
# + bsbb,bsbw - branch to subroutine.  PC is pushed on stack
# + caseb,casew,casel - case statements in hardware
# + jmp - jump
# + jsb - jump to subroutine
# + rsb - return from subroutine (equiv to jmp @(sp)+ but 1 byte shorter)
# + sobgeq - subtract one and branch greater than or equal
# + sobgtr - subtract one and branch greater than

# procedure call instructions
# + callg - call with general arg list
# + calls - call with stack argument list
# + ret - return from procedure

# misc instructions
# + bicpsw,bispsw,bpt,bug,halt,index,movpsl,nop,popr,pushr
# + xfc - extdended func call, you can extend instr set on fly?

# queue instructions
# + insqhi,insqti,insque,remqhi,remqti,remque,

# floating point instructions
# + add,clr,cmp,cvt,div,emod,mneg,mov,mul
# + poly - evaluate polynomial!
# + sub,tst

# character-string instructions
#   r0-r1, r0-r3 or r0-r5 used
#   all but movc may be implemented in software
# + cmpc3,cmpc5 - compare characters
#                string specified by r0,r1 compared to r3 (or r3,r4)
# + locc - locate character
# + matchc - match characters (search for substring)
# + movc - move character
# + movtc - move translated characters
# + movtuc - move translated until character
# + scanc - scan characters (uses lookup table?)
# + skpc - skip character
# + spanc - span characters (uses lookup tapble?)

# CRC instructions
# + crc

# Decimal-string instructions
# + addp,ashp,cmpp,cvtlp,cvtpl,cvtps,cvtpt,cvtps,cvttp,divp,movp
# + mulp,subp
# + edit,editpc - format strings for output (COBOL, PL/I, etc)
# + eo$adjust_input,eo$blank_zero,eo$end,eo$end_float,eo$fill,eo$float
# + eo$insert,eo$load,eo$move,eo$replace_sign,eo$_signif,eo$store_sign

# various os instructions, including task switching ones
# ldpctx and svpctx that load/save process context

# we will ignore pdp-11 compatability mode


# optimization
# - 1102 bytes to start out
# - 1078 bytes (store out_buffer in r6)
# - 1078 bytes (convert acbl to acbb)
# - 1070 bytes (use movz where possible)
# - 1058 bytes (move strcat to the middle of things so bsbb insns reach it)
# - 1054 bytes (more movz optimizations)
# - 1050 bytes (use mneg/addl2 instead of mov/subl3)
# - 1050 bytes (make a subl3 instruction write directly to stack)
# - 1046 bytes (some more bsbb optimizations)
# - 1046 bytes (have center_and_print fallthrough to write_stdout)
# - 1046 bytes (use movq 0,-(sp) instead of two pushl $0)
# - 1014 bytes (use registers to hold memory pointers, then force
#               byte offset accesses instead of re-loading each time)
# - 1010 bytes (another pass of bsbw/bsbb changes)

# pause for a while.  Following were contributed by Anders Magnusson

# - 1006 bytes (move text_buf to r8, use (%r11)+[%r8] style addressing)
# -  998 bytes (move syscall to ap and call to register)
# -  994 bytes (use simple counter for the bit counter in lzss)
# -  982 bytes (remove extraneous byte swapping.  Vax is little-endian)
# -  978 bytes (use displacement sizing on constant?)
# -  978 bytes (use clear instead of move 0 on stack)
# -  962 bytes (use discrete instructions for strcat and find_string)
# -  946 bytes (optimize center_and_print and write_stdout)

# Back to vince
# -  950 bytes (lost a few when making it actually work under simh)

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
	.align 1
	.word 0x0			# this is the "entry mask"
	      				# which specifies which regs need savd

	#=========================
	# PRINT LOGO
	#=========================

# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver

	# we used to fill the buffer with FREQUENT_CHAR
	# but, that only gains us one byte of space in the lzss image.
	# the lzss algorithm does automatic RLE... pretty clever
	# so we compress with NUL as FREQUENT_CHAR and it is pre-done for us

	moval	data_begin,%r9	     	# use r9 as pointer to begin of data
	movzwl 	$(N-F),%r4   	     	# R in %r4
	moval  	b`LOGO_OFFSET(%r9),%r1	# %r1 points to logo
	moval	out_buffer,%r3		# point r3 to out_buffer
	moval	text_buf,%r8		# point r8 to text_buf
	movab	syscall,%ap		# put syscall address in %ap
	movl	%r3,%r6	    		# store out_buffer in %r6 forever

decompression_loop:
	movzbl	$8,%r5		# reload the shift count
	movzbl	(%r1)+,%r7	# load in a byte, zero extend

test_flags:
	cmpl	$logo_end, %r1 	# have we reached the end?
	beql	done_logo  	# if so, exit

	blbs	%r7,discrete_char
				# branch if low bit set

offset_length:
	movzwl	(%r1)+,%r11	# load 16-bit value, zero extend
				# not sure why the previous
				# code though VAX was big-endian

	ashl 	$-(P_BITS),%r11,%r2
	addl2	$(THRESHOLD+1),%r2

output_loop:
	bicw2 	$~(POSITION_MASK<<8+0xff),%r11  	# mask it

	movb 	(%r11)+[%r8], %r0	# load byte from text_buf[], inc r11

store_byte:
	movb	%r0,(%r3)+		# store it

	movb	%r0,(%r4)+[%r8]		# store also to text_buf[r], inc r4
	bicw2	$~(N-1),%r4		# mask r

	sobgtr 	%r2,output_loop		# subtract one and branch if >
					# repeat until k>j

	divl2	$2,%r7			# shift right by one
	sobgtr	%r5,test_flags		# subtract one and loop if not done

	brb 	decompression_loop

discrete_char:
	movb	(%r1)+,%r0		# load in a byte
	movzbl	$1,%r2			# set count to one
	brb	store_byte


# end of LZSS code

done_logo:

	movl	%r6,%r0			# move out_buffer to r0
	bsbw	write_stdout		# print the logo


	#==========================
	# PRINT VERSION
	#==========================
first_line:
	movl	%r6,%r11		# point to output buffer

	moval	uname_info,%r7
	pushl   %r7   			# uname_struct
	movzbl	$SYSCALL_UNAME,%r0	# uname syscall
	calls	$1,(%ap)		# call syscall handler, 1 parm

	movl	%r7,%r5			# os-name from uname "Linux"
	bsbb	strcat

	movl	%r9,%r5			# source is " Version "
	bsbb	strcat			# call strcat

	moval	U_RELEASE(%r7),%r5	# version from uname "2.4.1"
	bsbb	strcat			# call strcat

	moval	b`COMP_OFFSET(%r9),%r5	# source is ", Compiled "
	bsbb	strcat			# call strcat

	moval	U_VERSION(%r7),%r5	# compiled date
	bsbb 	strcat			# call strcat

	movw	$0x000a,(%r11)		# store linefeed and 0 on end

	bsbw	center_and_print	# center and print

	#===============================
	# Middle-Line
	#===============================
middle_line:

	movl   %r6,%r11			# point to output buffer

	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	clrq	-(%sp)			# push $0 twice (this is shorter)
					# arg3 (mode)
       					# arg2 (0) = O_RDONLY <bits/fcntl.h>
	pushl   $cpuinfo  		# arg1 '/proc/cpuinfo'
	movzbl	$SYSCALL_OPEN,%r0	# open syscall
	calls	$3,(%ap)		# call syscall handler, 3 parm

	movl	%r0,%r5			# save our fd

	pushl	$4096			# max size of proc file
	pushl	$disk_buffer		# disk_buffer
	pushl	%r5			# our fd
	movzbl	$SYSCALL_READ,%r0	# read syscall
	calls	$3,(%ap)		# call syscall, 3 parameters

	pushl	%r5			# push fd
	movzbl	$SYSCALL_CLOSE,%r0	# close (to be correct)
	calls	$1,(%ap)		# call syscall, 1 parameter

	brb	number_of_cpus		# skip strcat


	#================================
	# strcat
	#================================
	# copy string from r5 to end of r11

	# originally used CISC "locc" instruction
	# but smaller to just use discrete instructions
strcat:
	movb	(%r5)+,(%r11)+	# copy and increment including zero
	bneq	strcat
	decl	%r11		# set ready for another string
	rsb

	#=============
	# Number of CPUs
	#=============
number_of_cpus:

	# for now, assume only single-processor machines

	moval   b`ONE_OFFSET(%r9),%r5   # just print "One"
	bsbb	strcat			# call strcat

	#=========
	# MHz
	#=========
print_mhz:

	# no MHz value available

	#=========
	# Chip Name
	#=========
chip_name:
	moval	b`TYPE_OFFSET(%r9),%r5	# want to find "type"
	bsbb	find_string		# get from cpuinfo file

	moval	b`PROC_OFFSET(%r9),%r5	# "Processor, "
	bsbb	strcat			# call strcat


	#========
	# RAM
	#========

	moval	sysinfo_buff,%r10
	pushl	%r10		 	# sysinfo buffer
	movzbl	$SYSCALL_SYSINFO,%r0	# sysinfo syscall
	calls	$1,(%ap)		# call syscall, 1 parameter

	movl	b`S_TOTALRAM(%r10),%r3	# size in bytes of RAM
	ashl	$-20,%r3,%r2		# divide by 1024*1024 to get M

	bsbw	num_to_ascii		# convert to ascii

	movl	%r1,%r5
	bsbb	strcat 			# print value

	moval	b`RAM_OFFSET(%r9),%r5	# print 'M RAM, '
	bsbb	strcat			# call strcat

	#========
	# Bogomips
	#========

	moval	b`BOGO_OFFSET(%r9),%r5	# want to find "Bogo"
	bsbb	find_string		# get from cpuinfo file

	moval	b`TOTAL_OFFSET(%r9),%r5
	bsbb 	strcat			# call strcat

	bsbb	center_and_print	# center and print

	#=================================
	# Print Host Name
	#=================================
third_line:
	movl	%r6,%r11		# point to output buffer

	moval	b`U_NODENAME(%r7),%r5	# host name from uname()
	bsbb    strcat			# call strcat

	bsbb	center_and_print	# center and print

	moval	b`COLORS_OFFSET(%r9),%r0	# restore colors
	bsbb	write_stdout


	#================================
	# Exit
	#================================
exit:
	pushl  $0x0			# exit value
	movzbl $SYSCALL_EXIT,%r0	# syscall
	calls  $1,(%ap)			# call syscall handler, 1 parm



	#=================================
	# FIND_STRING
	#=================================
	#   %r5 points to 4-char ascii string to look for
	#   %r11 points at output buffer

find_string:

	# This code previously used the optional matchc instruction
	# but using discrete instructions was smaller

	moval   disk_buffer,%r0		# look in cpuinfo buffer

find_loop:
	cmpl	(%r5),(%r0)		# search for substring r5
	beql	find_colon
	cmpb	$0,(%r0)+		# increment pointer
					# check to see if we are off end
					# of buffer
	beql	done_find		# if reading 0's, off end, so done
	brb	find_loop		# loop until found

find_colon:
	cmpb	$':',(%r0)+		# find a colon
	bneq    find_colon
	incl	%r0			# skip space

copy_rest:
	movb	(%r0)+,(%r11)+		# copy the rest
	cmpb	$'\n',(%r0)
	bneq    copy_rest

done_find:
	clrb    (%r11)			# NUL-terminate output
	rsb				# return


	#==============================
	# center_and_print
	#==============================
	# string to center in out_buffer
	# %r11 has the end of the string

center_and_print:

	moval	b`ESCAPE_OFFSET(%r9),%r0	# we want to output ^[[
	bsbb	write_stdout

					# get length of string (end-begin)
	subl3	%r6,%r11,%r3		# r3=%r11-%r3

	subl3	%r3,$80,%r2		# reverse subtract
	blss	done_center		# if greater than 80, no center

	divl2	$2,%r2			# then divide by 2

	bsbb	num_to_ascii		# print number of spaces
	movl	%r1,%r0
	bsbb	write_stdout

	moval	b`C_OFFSET(%r9),%r0	# tack a 'C' on the end
	bsbb	write_stdout

done_center:
	movl	%r6,%r0			# fall through to write_stdout
					# it will return for us


	#================================
	# WRITE_STDOUT
	#================================
	# %r0 has string

write_stdout:

	clrl	%r1		# set r1 to zero
write_loop:
	tstb	(%r1)+[%r0]	# test for end NUL, auto-inc
	bneq	write_loop	# repeat until found

	decl	%r1

	movq    %r0,-(%sp)	# push length (in r1) and pointer (r0)
				# in one instruction
	pushl   $STDOUT	     	# argument 1 (stdout)
	movzbl	$SYSCALL_WRITE,%r0
	calls	$3,(%ap)	# call the syscall

	rsb		  	# return

	##############################
	# num_to_ascii
	##############################
	# r2 has number to convert
	# result is pointed to by r1

num_to_ascii:
	moval	ascii_buffer+8,%r1
	clrl	%r3		# clear top half of the quadword

div_by_10:
	ediv	$10,%r2,%r4,%r5	# divide r2 by 10, Q->%r4, R->%r5
				# grrrr, the dividend is actually a quadword
				# so r3 must be 0 or hilarity ensues

write_out:
	addl2	$0x30,%r5	# convert to ASCII
	movb	%r5,-(%r1)	# store to the buffer

	movl	%r4,%r2		# copy quotient to dividend
	bneq	div_by_10	# branch if quotient not zero

	rsb			# return

	#===============================
	# syscall handler
	#===============================
	# syscall to call in r0

syscall:
	.word   0x0			# entry mask
	chmk	%r0			# do the syscall
	ret				# return



#===========================================================================
#	section .data
#===========================================================================
.data
data_begin:
.equ VER_OFFSET,0x0
ver_string:	.ascii	" Version \0"
.equ COMP_OFFSET,0xa
compiled_string:	.ascii	", Compiled \0"
.equ ONE_OFFSET,0x16
one:			.ascii  "One \0"
.equ PROC_OFFSET,0x1b
processor_string:	.ascii	" Processor, \0"
.equ RAM_OFFSET,0x28
ram_comma:	.ascii	"M RAM, \0"
.equ TOTAL_OFFSET,0x30
bogo_total:	.ascii	" Bogomips Total\n\0"

.equ COLORS_OFFSET,0x41
default_colors:	.ascii "\033[0m\n\n\0"
.equ ESCAPE_OFFSET,0x48
escape:		.ascii "\033[\0"
.equ C_OFFSET,0x4b
C:		.ascii "C\0"

.equ TYPE_OFFSET,0x4d
type_string:	.ascii  "type"
.equ BOGO_OFFSET,0x51
bogo_string:	.ascii  "Bogo"
.ifdef FAKE_PROC
cpuinfo:	.ascii	"proc/cpui.vax\0"
.else
cpuinfo:	.ascii	"/proc/cpuinfo\0"
.endif
.equ LOGO_OFFSET, 0x63
.include	"logo.lzss_new"

#============================================================================
#	section .bss
#============================================================================
#.bss

.lcomm  text_buf, (N+F-1)
.lcomm ascii_buffer,9
	# see /usr/src/linux/include/linux/kernel.h
.lcomm sysinfo_buff,(64)
.lcomm uname_info,(65*6)
.lcomm	disk_buffer,4096	# we cheat!!!!
.lcomm	out_buffer,16384
