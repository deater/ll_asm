#
#  linux_logo in ppc-vle (variable-length)  assembler    0.50
#
#  by Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -o ll.o ll.ppc.s"
#  link with         "ld -o ll ll.o"
#

# Variable-Length Encoding (VLE) extension programming interface manual
#  Claims 30% reduction in code size

# 16-bit instructions restricted to r0-r7 and r24-r31
#  move can be used to access r8-r23
# Can only access CR0

#
# 32-bit PPC register usage

# Register        Usage                CALLEE SAVE
# r0            prolog/epilog           NO
# r1            stack pointer           YES
# r2            TOC pointer (reserved)  YES
# r3-r4         1/2 para and return     NO
# r5-r10        3-8th para              NO
# r11-r12       Func Linkage reg        NO
# r12           Used by global linkage  NO
# r13           Small data area pointer NO
# r14-r30       General Int registers   YES
# r31           Global Environment Ptr  YES
# CR0-CR7       Condition Regs          2,3,4 Yes
# LR            Link register           YES
# CTR           Counter register        NO

# CR = condition register.
#   There are actually 8 condition registers, CR0-CR7
# CR0, default for "."  =  4 bits.  Negative, Positive, Zero, Overflow
# CR1, gets floating point results
# CRx, as result of compare instruction.
#      bit 0=less than, 1=greater than 2=equal, 3=overflow
# XER = holds carry and overflow flags
# CTR = counter register, used as a loop index

# 32-bit Instruction set
# add add. addo addo. - "." means update condition reg. "o" means handle oflo
# addc addc. addco addco. - add while setting carry
# addex adde. addeo addeo. - add extended (with carry from XER)
# addi - add immediate
# addic addic. - add immediate while setting carry
# addis - add immediate shifted (high bits from immediate << 16)
# addme addme. addmeo addmeo. - add to minus one extended  (ra + carry + -1)
# addze addze. addzeo addzeo. - add to zero extended  (ra + carry)
# and and. - logical and
# andc andc. - and compliment
# andi. - and immediate
# andis. - and immediate shifted << 16
# b ba bl bla - a means absolute, l means and link
# bc bca bcl bcla - branch conditional.  bc BO,BI,target
#                   BO specifies true, false, always, CTR
#                   BI specifies bit in the CR to use
# bcctr bcctrl - branch conditional to count register
# bclr bclrl - branch conditional to link register
# cmp crfD,L,rA,rB - compare.  crfD = which CR to use, L is 32 or 64 bit?
# cmpi - compare immediate
# cmpl - compare logical (unsigned?)
# cmpli - compare logical immediate
# cntlzw cntlzw. - count leading zeros
# creqv - condition register equivelent
# crand crnand crandc - condition register and nand and compliment
# cror crnor crorc - condition register or nor or compliment
# crxor - condition register xor
# divw divw. divwo divwo. - divide word
#    no remainder.. need to divw/mullw/subf to get it
# divwu divwu. divwuo divwuo. - divide unsigned
# eieio - enforce in-order execution of external io
# eqv eqv. - exclusive nor
# extsb extsb. - extend sign byte
# extsh extsh. - estend sign half
# lbz - load byte and zero
# lbzu - load byte and update.  the Effective address is stored back into RA
# lbzux - load byte and update, indexed.  EA is RA+RB
# lbzx - load byte indexed
# lha lhau - load half and sign extend, with update
# lhax, laux - load half indexed, sign extend, with update
# lhbrx - load half byte reversed indexed
# lhz lhzu lhzux lhzx - load half all the various ways
# lmw - load multiple words.  multiple words loaded into consecutive regs
# lswi lswx - load string word immediate.  load bytes into regs
# lwarx - load word and reserve (for atomic)
# lwbrx - load word byte reversed
# lwz lwzu lwzux lwzx - load word and zero
# mcrf - move cond reg field
# mcrxr - move xer to cond reg
# mfcr - move from cond reg
# mulhw mulhw. - multiply high word - 32x32, get resulting top 32 bits
# mulhwu mulhwu. - multiplu high word unsigned
# mulli - multiply low immediate
# mullw mullw. mullwo mullwo. - muliply low
# nand nand. - nand
# neg neg. nego nego. - negate
# nor nor. - nor
# or or. - or
# orc orc. - or with complement
# ori oris - or immediate, or immediate shifted
# rlwimi rlwmimi. - ra,rs,sh,mb,me - rotate left word immed then mask insert
#                   rs rotated by sh. mb to me specify mask
# rlwinm rlwinm. - rotate left word immed then and mask
# rlwnm rlwnm. - rotate left word and with mask
# sc - system call
# slw slw. - shift left word
# sraw sraw. - shift right algebraic word
# srawi srawi. - shift right algebraic word immediate
# srw srw. - shift right word
# stb stbu stbux stbx - store byte, update, indexed
# sth sthu sthux sthx - store halfword
# sthbrx - store halfword byte reversed
# stmw - store multiple regs
# stswi stswx - store string word immediate, indexed
# stw stwu stwux stwx - store word, update
# stwbrx - store word byte reversed indexed
# stwcx. - store word conditional (for atomic)
# subf subf. subfo subfo. - subtract from
# subfc subfc. subfco subfco. - subtract from carrying
# subfe subfe. subfeo subfeo. - subtract from extended (carry)
# subfic - sub from immediate carrying
# subfme subfme. subfmeo subfmeo. - subtract from minus one extended
# subfze subfze. subfzeo subfzeo. - subtract from zero extended
# xor xor. - xor
# xori xoris - xor immediate, shifted

# Pseudo instructions
#  li, la, subi
#  blt, bne cr2, bdnz
#  bltctr, bnectr cr2
#  bltlr, bnelr cr2, bdnzlr
#  cmpd, cmpw cr3
#  cmpid, cmpiw
#  cmpld, cmplw
#  cmpldi, cmplwi
#  crse, crclr
#  not
#  mr - move register
#  nop
#  extlwi extrwi rotlwi rotrwi slwi srwi clrlwi clrrwi clrlslwi
#  rotlw
#  sub subc

# Optimization:
# + lzss
#  - ?? - ported from ppc code
#
# + overall
#  - ???? - ported from ppc code

# offsets into the results returned by the uname syscall
.equ U_SYSNAME,0
.equ U_NODENAME,65
.equ U_RELEASE,65*2
.equ U_VERSION,(65*3)
.equ U_MACHINE,(65*4)
.equ U_DOMAINNAME,65*5

# offset into the SYSCALL_SYSINFO buffer
.equ S_TOTALRAM,16

# Sycscalls
.equ SYSCALL_EXIT,     1
.equ SYSCALL_READ,     3
.equ SYSCALL_WRITE,    4
.equ SYSCALL_OPEN,     5
.equ SYSCALL_CLOSE,    6
.equ SYSCALL_SYSINFO,116
.equ SYSCALL_UNAME,  122

#
.equ STDIN, 0
.equ STDOUT,1
.equ STDERR,2

.equ BSS_BEGIN,25
.equ DATA_BEGIN,26

.include "logo.include"

	.globl _start
_start:

        #========================
	# Initialization
	#========================

  	# the hack loading BSS_BEGIN and DATA_BEGIN
	# saves one instruction on any future load from memory
	# as we can just do an addi rather than an lis;addi

#	e_la	25,bss_begin		# bss offset in r25

#	e_la	26,data_begin		# data offset in r26

#	addi	17,BSS_BEGIN,(out_buffer-bss_begin)
					# output buffer in r17

#	addi	21,BSS_BEGIN,(text_buf-bss_begin)
					# text_buf in r21


        #=========================
	# PRINT LOGO
	#=========================

# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver


#	li	8,(N-F)			# grab "R"

#	addi	9,DATA_BEGIN,(logo-data_begin)-1
					# logo_pointer

#	addi	12,DATA_BEGIN,(logo_end-data_begin)-1
					# end of the logo

	mr      16,17			# r16 starts at output pointer

decompression_loop:
#	lbzu 	10,1(9)			# load in a byte
					# auto-update
#	ori	11,10,0xff00		# load top as a hackish
					# 8-bit counter

test_flags:
#	cmpw	0,12,9			# have we reached the end?
#	ble	done_logo		# if so exit

#	andi.	13,11,0x1		# test bottom bit
	srawi   11,11,1			# shift over

#	bne	0,discrete_char		# if bit was 0, we have a single char

offset_length:
	      				# Load 16-bit little endian
#	addi	9,9,1			# have to do this because
					# we use lbzu for rest of loads
	lhbrx	24,0,9			# load half-word byte reversed index
					#   0 means use 0, not r0
#	addi	9,9,1			# we loaded two bytes

	srawi  15,24,P_BITS
#	addi   15,15,THRESHOLD+1 	# match length is top bits

output_loop:
#	andi.  24,24,(POSITION_MASK<<8+0xff)
	       				# offset in text_buf is bottom bits

	lbzx   10,21,24			# load byte from text_buf
#	addi   24,24,1			# increment pointer

store_byte:
#	stbu   10,1(16)			# store byte to putput

	stbx    10,21,8			# store byte to text_buf
#	addi	8,8,1			# increment pointer
#	andi.	8,8,(N-1)		# mask to prevent overflow

#	addic.	15,15,-1		# decrement count
#	bne	0,output_loop		# loop if not output

#	andi.	13,11,0xff00		# test to see if done with 8 bits of
#	bne	test_flags		# flags

#	b	decompression_loop	# loop

discrete_char:

#	lbzu    10,1(9)			# load byte to output
#	li	15,1			# set to only output one byte

#	b       store_byte		# go to store byte routine

done_logo:

#	addi	4,17,1			# restore output pointer
					# (plus one because r17 is decremented)
#	bl	write_stdout		# and print the logo


        #==========================
	# First Line
	#==========================

first_line:
	mr	14,17		    	# copy output pointer to r14

	#==========================
	# PRINT VERSION
	#==========================

run_uname:

#	li	0,SYSCALL_UNAME		# uname syscall
#	addi	3,BSS_BEGIN,(uname_info-bss_begin)
					# uname struct
#	sc				# do syscall

print_version:

#	addi	16,BSS_BEGIN,(uname_info-bss_begin)+U_SYSNAME@l-1
					# os-name from uname "Linux"
#	bl	strcat

#	addi	16,DATA_BEGIN,(ver_string-data_begin)-1
					# source is " Version "
#	bl 	strcat

#	addi	16,BSS_BEGIN,(uname_info-bss_begin)+U_RELEASE@l-1
					# version from uname "2.4.1"
#	bl 	strcat

#	addi	16,DATA_BEGIN,(compiled_string-data_begin)-1
					# source is ", Compiled "
#	bl 	strcat

#	addi	16,BSS_BEGIN,(uname_info-bss_begin)+U_VERSION-1
      					# compiled date
#	bl 	strcat

#	bl	center_and_print	# write it to screen


	#===============================
	# Middle-Line
	#===============================
middle_line:

	mr	14,17 			# point output to out_buf

	#=========
	# Load /proc/cpuinfo into buffer
	#=========

#	li	0,SYSCALL_OPEN		# open()
#	addi	3,DATA_BEGIN,(cpuinfo-data_begin)
					# '/proc/cpuinfo'
#	li	4,0			# O_RDONLY <bits/fcntl.h>
#	sc				# syscall.  fd in r0.
					# we should check that r0>=0

	mr	13,3			# save fd in r13

#	li	0,SYSCALL_READ		# read
#	addi	4,BSS_BEGIN,(disk_buffer-bss_begin)
#	li	5,4096		 	# assume cpuinfo file < 4k
#	sc

	mr	3,13			# restore fd
#	li	0,6			# close
#	sc

	#=============
	# Number of CPUs
	#=============

num_cpu:
	# Assume 1 CPU for now
	# my iBook's /proc/cpuinfo does not have a "processor" line ???

#	addi	16,DATA_BEGIN,(one-data_begin)-1
#	bl	strcat

	#=========
	# MHz
	#=========

mhz:
#	lis	20,('l'<<8)+'o'		# find 'lock ' and grab up to M
#	addi	20,20,('c'<<8)+'k'
#	li	23,'M'
#	bl	find_string

#	addi	16,DATA_BEGIN,(megahertz-data_begin)-1
					# print 'MHz '
#	bl	strcat


	#=========
	# Chip Name
	#=========
chip_name:
#	lis     20,('c'<<8)+'p'     	# find 'cpu\t: ' and grab up to \n
#	addi	20,20,('u'<<8)+'\t'
#	li	23,'\n'
#	bl	find_string

#	addi	16,DATA_BEGIN,(comma-data_begin)-1
					# print ', '
#	bl	strcat

	#========
	# RAM
	#========
ram:
#	li	0,SYSCALL_SYSINFO	# sysinfo() syscall
#	addi	3,BSS_BEGIN,(sysinfo_buff-bss_begin)
					# sysinfo_buffer

#	sc

#	lwz	4,(sysinfo_buff+S_TOTALRAM-bss_begin)(BSS_BEGIN)
					# load bytes of RAM into r4

#	srwi	19,4,20		# divide by 2^20 to get MB

#	li	5,0

#	bl	num_to_ascii

#	addi	16,DATA_BEGIN,(ram_comma-data_begin)-1
					# print 'M RAM, '

#	bl	strcat

	#========
	# Bogomips
	#========

bogomips:
#	lis	20,('m'<<8)+'i'		# find 'mips' and grab up to \n
#	addi	20,20,('p'<<8)+'s'
#	li	23,'\n'
#	bl	find_string

#	addi	16,DATA_BEGIN,(bogo_total-data_begin)-1
					# print "Bogomips Total"
#	bl	strcat

#	bl	center_and_print	# center it


	#=================================
	# Print Host Name
	#=================================
host_name:
	mr	14,17			# restore out buffer

#	addi	16,BSS_BEGIN,((uname_info-bss_begin)+U_NODENAME)-1
					# hostname

#	bl	strcat

#	bl	center_and_print

#	addi	4,DATA_BEGIN,(default_colors-data_begin)
					# restore default colors

#	bl	write_stdout

	#================================
	# Exit
	#================================
exit:
#	li      3,0		# 0 exit value
#	li      0,SYSCALL_EXIT  # put the exit syscall number in eax
#	sc	             	# and exit


	#=================================
	# FIND_STRING
	#=================================
	#   r23 is char to end at
	#   r20 is the 4-char ascii string to look for
	#   r14 points at output buffer
	#   r16,r21

find_string:

#	addi	16,BSS_BEGIN,(disk_buffer-bss_begin)-1
					# look in cpuinfo buffer
					# -1 so we can use lbzu

find_loop:
#	lwzu	13,1(16)		# load in 32 bits, incrementing 8bits
#	cmpwi	13,0			# if null, we are done
#	beq	done
	cmpw	13,20			# compare with out 4 char string
#	bne	find_loop		# if no match, keep looping


					# if we get this far, we matched

find_colon:
#	lbzu	13,1(16)		# repeat till we find colon

#	cmpwi	13,0			# if zero, bail
#	beq	done

#	cmpwi	13,':'			# compare to colon
#	bne	find_colon

#	addi	16,16,1			# skip a char [should be space]

store_loop:
#	 lbzu	13,1(16)		# load byte

#	 cmpwi	13,0			# if zero, bail
#	 beq	done

    	 cmpw	13,23			# is it end string?
#	 beq 	almost_done		# if so, finish
#	 stbu	13,1(14)		# if not store and continue
#	 b	store_loop

almost_done:
#	li	13,0			# replace last value with null
#	stb	13,1(14)

done:
#	blr				# return

	#==============================
	# center_and_print
	#==============================
	# r14 is end of buffer
	# r17 is start of buffer
	# r29 = saved link register
	# r4-r10, r19-r22, r30 trashed

center_and_print:

	mflr 	29			# back up return address

	subf	5,17,14			# see how long the output
					# buffer is

#	cmpwi	5,80			# see if we are >80
#	bgt	done_center		# if so, bail

#	subfic	4,5,80			# r4 = 80-r5
					#   is it possible to combine this
					#   with the >80 test?

	srawi	23,4,1			# divide by two

#	addi	4,DATA_BEGIN,(escape-data_begin)
#	bl	write_stdout

	mr	19,23	    		# move size into argument
#	li	5,1			# print to stdout
#	bl	num_to_ascii		# print number

#	addi	4,DATA_BEGIN,(c-data_begin)
#	bl	write_stdout

done_center:

#	addi	4,17,1			# move string to output+1
#	bl	write_stdout		# call write stdout

#	addi	4,DATA_BEGIN,(linefeed-data_begin)

	mtlr	29	      		# restore link register
					# and let write_stdout
					# return for us



	#================================
	# WRITE_STDOUT
	#================================
	# r4 has string
	# r0,r3,r4,r5,r6 trashed

write_stdout:
#	li	0,SYSCALL_WRITE		# write syscall
#	li	3,STDOUT		# stdout

#	li	5,0			# string length counter
strlen_loop:
	lbzx 	6,4,5			# get byte from (r4+r5)
#	addi	5,5,1			# increment counter
#	cmpi	0,6,0			# is it zero?
#	bne	strlen_loop		# if not keep counting

#	addi	5,5,-1			# adjust back down
#	sc				# syscall

#	blr				# return


	#================================
	# Num to Ascii
	#================================
	# num is in r19
	#  breaks on negative values
	# r5 =0 then strcat, otherwise stdout
	# r5-r10,r19,r20,r21,r22,r30 trashed

num_to_ascii:

	mflr    30			# save the link register

#	addi	16,BSS_BEGIN,(num_to_ascii_end-bss_begin)
					# the end of a backwards growing
					# 10 byte long buffer.

#	li	20,10			# we will divide by 10

div_by_10:
	divw	21,19,20		# divide r19 by r20 put into r21

	mullw	22,21,20		# find remainder.  1st q*dividend
	subf	22,22,19		# then subtract from original = R
#	addi	22,22,0x30		# convert remainder to ascii

#	stbu	22,-1(16)		# Store to backwards buffer

	mr	19,21			# move Quotient as new dividend
#	cmpwi	19,0			# was quotient zero?
#	bne    	div_by_10		# if not keep dividing

write_out:
	mtlr	30			# restore link register

#	cmpwi	5,0			# if r5 is 0 then skip ahead
#	beq 	strcat_num

stdout_num:
        mr	4,16			# point to our buffer
#	b	write_stdout		# stdout will return for us

strcat_num:
#	addi	16,16,-1		# point to the beginning

					# fall through to strcat

	#================================
	# strcat
	#================================
	# r13 = "temp"
	# r16 = "source"
       	# r14 = "destination"
strcat:
#	lbzu	13,1(16)		# load a byte from [r16]
#	stbu	13,1(14)		# store a byte to [r14]
#	cmpwi	13,0			# is it zero?
#	bne	strcat			# if not loop
#	subi	14,14,1			# point to one less than null
#	blr				# return


#===========================================================================
.data
#===========================================================================


data_begin:

.include "logo.lzss_new"

ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
megahertz:	.ascii	"MHz PPC \0"
.equ comma, ram_comma+5
linefeed:   	.ascii  "\n\0"
escape:		.ascii	"\033[\0"
c:		.ascii  "C\0"
ram_comma:	.ascii	"M RAM, \0"

bogo_total:	.ascii	" Bogomips Total\0"

default_colors:	.ascii	"\033[0m\n\0"

.ifdef FAKE_PROC
cpuinfo:	.ascii	"proc/cpui.ppc\0"
.else
cpuinfo:	.ascii	"/proc/cpuinfo\0"
.endif

one:	.ascii	"One \0"

#============================================================================
#.bss
#============================================================================

.lcomm bss_begin,0
.lcomm	num_to_ascii_buff,10
.lcomm num_to_ascii_end,1
.lcomm  text_buf, (N+F-1)	# These buffers must follow each other
.lcomm	out_buffer,16384

	# see /usr/src/linux/include/linux/kernel.h

.lcomm  sysinfo_buff,(64)
.lcomm  uname_info,(65*6)

.lcomm	disk_buffer,4096,4	# we cheat!!!!
