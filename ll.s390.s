#
#  linux_logo in s390 assembler 0.28
#
#  by 
#       Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -o ll.o ll.s390.s"
#  link with         "ld -o ll ll.o"


# Note - we assume decimal and string hardware is installed.
#        this might not be true on older machines
#
# gas's addressing is a bit odd.  Labels start from the beginning of
#  the segment, rather than IP relative.  So I use %r1 as an offset reg

# register ABI
# r0,r1 = general purpose
# r2,r3 = params, return values
# r4-r6 = params
# r7-r11 = local
# r12 = GOT pointer
# r13 = literal pool pointer
# r14 = return address
# r15 = stack pointer

# Hardware Summary
# + 16 32-bit integer registers (r0-r15)
# + 4-16 64-bit floating point registers
# + PSW (Program Status Word) has PC and other info
# + can address 31-bit or 24-bit address spaces

# variable instruction length (16, 32 or 48 bits)
# big-endian

# addressing modes.  not orthogonal:
#   reg/reg
#   immediate
#   crazy complicated combinations
#
#  B=Base (value in register)
#  X=index (value in a register)
#  D=12-bit immediate

# Luckily can avoid using EBCDIC

# Syscalls
#   values in r2-r6
#   svc NUM to execute
#   result returned in r2

# assembly instructions
#   note, can you tell this is a CISC architecture?

# ar, a, ah, ahi (add, add halfword, add halfword immediate)
# nr, n, ni, nc (and )
# bal, balr (branch and link) [use branch and save instead?]
# basr, basm, bsm (branch and save)
# bcr, bc (branch on condition)
# bctr, bct (branch on count) [like x86 loop instruction]
# bxh, bxle (branch on index high, branch on index low or equal)
# bras (branch relative and save)
# brc (branch relative on condition)
# brct (branch relative on count)
# brxh, brxle (branch relative on index high / index low or equal)
# cksm (checksum)
# cr, c (compare) condition codes 0=equal, 1=first low, 2=first high  
# cfc (compare and for codeword) [crazy instruction for sorting?]
# cs, cds (compare and swap) 
# ch, chi (compare halfword)
# clr, cl, cli, clc (compare logical)
# clm (compare logical under mask)
# clcl (compare logical long) 64-bit compare
# clcle (compare logical long extended)
# clst (compare logical string) - compare up to 256 bytes
# cuse (compare until substring equal) 
# cvb, cvd (convert to binary/decimal)
# cuutf, cutfu (convert to unicode/utf-8)
# divide (divide)
# xr, x, xi ,xc (xor)
# ex (execute) - create an instruction and execute it
# ic (insert character) - insert 8 bits into a register
# icm (insert character under mask)
# lr,l (load)
# la, lae (load address, load address extended)
# ltr (load and test) - move register and set condition register
# lcr (load and complement) - negate a value
# lh, lhi (load halfword/immediate)
# lm (load multiple) - load consecutive mem into registers
# lnr (load negative) - negative of absolute value loaded
# lpr (load positive) - absolute value
# mc (monitor call)
# mvi, mvc, mvcin, mvcl,mvcle (move/move inverse/move long/move long extended)
# mnv (move numerics)
# mvpg (move page) - move a whole 4kb page
# mvst x,y (move string) -
#      copy string at y to x.  r0 holds the terminating character
# mvo, mvz (move with offset/zones)
# mr, m, mh, mhi (multiply/multiply halfword/multiply halfword immediate)
# msr, ms (multiply single)
# or, o, oi, oc (or)
# pack
# plo (perform locked operation)
# srst (search string)
# sla, sll, sldl (shif left single/single logical/double)
# sra, srl, srdl, srda (shift right single/logical/double)
# st (store)
# stc, stcm (Store char, store char under mask)
# sth (store halfword)
# stm (store multiple)
# sr, s (substract)
# sh (subtract halfword)
# slr, sl (subtract logical)
# svc (supervisor call)
# ts (test and set)
# tm, tmh, tml (test under mask, high, low)
# tr, trt (translate, translate and test)
# unpk (unpack)
# upt (update tree)

# a whole raft of decimal instructions
# a whole raft of floating point instructions
# a whole raft of operating-system level instructions


# OPTIMIZATIONS
# + 1168 - first draft
# + 1156 - remove unused code, minor ops
# + 1140 - use "bctr" to end loops instead of subtract/compare
# + 1096 - make num_to_ascii use divide instead of decimal opcodes 
# + 1092 - make r9 be a constant reg equalling 1
# + 1088 - remove some more unused variables
# + 1104 - make it properly print s if SMP system
# + 1096 - replace out_buffer with r8

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
.equ SYSCALL_EXIT,     1
.equ SYSCALL_READ,     3
.equ SYSCALL_WRITE,    4
.equ SYSCALL_OPEN,     5
.equ SYSCALL_CLOSE,    6
.equ SYSCALL_STAT,   106
.equ SYSCALL_SYSINFO,116
.equ SYSCALL_UNAME,  122

#
.equ STDIN,0
.equ STDOUT,1
.equ STDERR,2



	.globl _start	
_start:	
	#=========================
	# PRINT LOGO
	#=========================
	
	basr	%r1,0			# get data offset into r1
base:
	la	%r2,base
	sr	%r1,%r2			# addresses are releative to segment
					# so subtract off current offset


			
# LZSS decompression algorithm implementation
# by Vince Weaver based on LZSS.C by Haruhiko Okumura 1989
	
	lhi	%r10,(N-F)		# load "r"
	la	%r11,text_buf(%r1)	# point %r11 to text_buf	
	la	%r12,logo-1(%r1)	# point %r12 to logo
	la 	%r13,logo_end-1(%r1)	# point %r13 to logo_end
	la	%r14,out_buffer(%r1)	# point %r14 to output buffer
	lhi	%r9,1			# constant 1 in %r9

decompression_loop:

	lhi	%r8,8			# re-load shift counter
	lh	%r2,0(0,%r12)		# load flags register
	ar	%r12,%r9	       	# increment pointer		

test_flags:
	
	cr	%r12,%r13		# see if we've reached the end
	je	done_logo		# if so, exit


	tml	%r2,1			# is lowest bit 0

        srl	%r2,1			# shift right our flags

	jne	discrete_char		# if not, keep going


offset_length:
	      				# have to do two loads because
					# we are big-endian
					# there is probably an obscure
					# opcode that will do this for us
					
	lh	%r6,0(0,%r12)		# load a byte
	lhi	%r3,0xff		# load mask
	nr	%r6,%r3			# get only bottom byte

	
	lh	%r7,1(0,%r12)		# load next byte
	ahi	%r12,2			# increment pointer
	nr	%r7,%r3			# mask off bottom byte

	sll	%r7,8			# shift
	or	%r6,%r7			# and combine as one 16 bit value

	lr	%r5,%r6			# length is (hw>>P_BITS)+THRESHOLD+1
	srl	%r5,P_BITS
	ahi	%r5,(THRESHOLD+1)
	
	
output_loop:

	lhi 	%r3,((POSITION_MASK<<8)+0xff)
        nr   	%r6,%r3
					# mask to get position
	lh	%r4,0(%r6,%r11)		# load from text_buf[pos]
	srl	%r4,8			# shift to get actual byte
	ar	%r6,%r9			# increment pointer

store_byte:

	stc	%r4,0(0,%r14)		# store byte to output
	ar	%r14,%r9		# increment pointer
	stc	%r4,0(%r10,%r11)	# store byte to text_buf[r]
	ar	%r10,%r9       		# increment r
	lhi	%r3,(N-1)		# load mask	
	nr	%r10,%r3		# mask r with (N-1)

	bct	%r5,output_loop(%r1)	# subtract 1 from count, loop if not 0

	bct	%r8,test_flags(%r1)	# subtract 1 from count, reload if 0

	j	decompression_loop	# otherwise, loop

discrete_char:
	lh	%r4,0(0,%r12)		# load flags register
	ar	%r12,%r9       		# increment pointer
	lr	%r5,%r9			# set count (r5) to 1
	j	store_byte

done_logo:

	la	%r3,out_buffer(%r1)	# point to beginning of buffer
	lr	%r8,%r3			# store out buffer in r8
	bras	%r14,write_stdout	# and print it
	
	#==========================
	# PRINT VERSION
	#==========================
print_version:
	la      %r10,strcat(%r1)	# point r10 to strcat()
	lr 	%r13,%r8		# re-point point to output buffer
		
	la	%r2,uname_info(%r1)	# point to beginning of buffer

	lr	%r12,%r2		# U_SYSNAME is 0, so this will point
					# to os-name from uname "Linux
	
	svc 	SYSCALL_UNAME		# uname syscall
	
	basr	%r14,%r10		# strcat

	la	%r12,ver_string(%r1)	# source is " Version "
	basr	%r14,%r10

	la	%r12,uname_info+U_RELEASE(%r1)	# version from uname "2.4.1"
	basr	%r14,%r10		# strcat
	
	la	%r12,compiled_string(%r1)	# source is ", Compiled "
	basr	%r14,%r10		# strcat

	la	%r12,uname_info+U_VERSION(%r1)	# compiled date
	basr	%r14,%r10	        # strcat

	lhi	%r4,0x0a00	
	sth	%r4,0(0,%r13)		# append linefeed and nul	

	bras	%r14,center_and_print	# center and print
			
	#===============================
	# Middle-Line
	#===============================

middle_line:
	
	#=========
	# Load /proc/cpuinfo into buffer
	#=========
start_cpuinfo:	
	la	%r2,cpuinfo(%r1)	# '/proc/cpuinfo'
	sr	%r3,%r3			# 0 = O_RDONLY <bits/fcntl.h>
			
	svc	SYSCALL_OPEN		# open().  fd=%r2
					# we should check that %r2>=0
	
	lr	%r6,%r2			# save the fd
	
	l	%r3,disk_buffer_p(%r1)
	lhi	%r4,4096	 	# 4096 is maximum size of proc file ;)
	
	svc	SYSCALL_READ		# read()
				
	lr	%r2,%r6
	svc	SYSCALL_CLOSE		# close (to be correct)
end_cpuinfo:

	
	#=============
	# Number of CPUs
	#=============

	la	%r13,temp_ascii(%r1)	# point to beginning of temp_num
	la	%r4,search_sors(%r1)	# search for "sors"
	bras	%r14,find_string	

	ahi	%r13,-1			# back up result
	lh	%r4,0(%r13)		# grab the number
	sra	%r4,8
	
	lhi	%r3,0xf
        nr      %r4,%r3			# mask off (convert from ascii)
	lr	%r2,%r4
	
	ahi	%r4,-1			# decrement (arrays start at 0)
	sla	%r4,2			# shift over (32bit pointer)
	
	la	%r5,ordinal(%r1)	# load the pointer
	ar	%r5,%r4			# add the offset

	lr	%r13,%r8		# point to beginning of output buffer
	
	l	%r12,0(%r5)		# print the string
	basr	%r14,%r10		# call strcat   		

	#=========
	# MHz
	#=========
	
# No MHz detection on this architecture
	   
   	#=========
	# Chip Name
	#=========

	la	%r4,search_r_id(%r1)	# Look for "vendor_id"
	bras	%r14,find_string	

	la	%r12,processor(%r1)	# print ' Processor'
	basr	%r14,%r10		# call strcat

	la	%r12,s_comma(%r1)	# point to 's, '
	bct	%r2,no_s(%r1)		# if only one processor,
	ar	%r12,%r9     		# point past s
no_s:
	basr	%r14,%r10		# call strcat

	
	
	#========
	# RAM
	#========

	la	%r2,sysinfo_buff(%r1)	# do sysinfo() syscall
	svc	SYSCALL_SYSINFO
	
	l	%r7,sysinfo_buff+S_TOTALRAM(%r1)	
					# size in bytes of RAM

	sra	%r7,20			# divide by 1024*1024 to get M
	bras	%r14,num_to_ascii	# print to ascii

	lr	%r12,%r5		# point to ascii result
	basr	%r14,%r10		# call strcat

	la	%r12,ram_comma(%r1)	# print 'M RAM, '
	basr	%r14,%r10		# call strcat  	
		
	#========
	# Bogomips
	#========

	la	%r4,search_bogo(%r1)	# Grab number of bogomips
	bras	%r14,find_string

	la	%r12,bogo_total(%r1)	# source is " Bogomips Total"
	basr	%r14,%r10		# call strcat   

	
	bras	%r14,center_and_print	# print some spaces

	
		
	#=================================
	# Print Host Name
	#=================================
print_host_name:
	lr	%r13,%r8       		# point to beginning of buffer	
	
	la	%r12,uname_info+U_NODENAME(%r1)	# host name from uname()

	basr	%r14,%r10		# call strcat
	bras	%r14,center_and_print

	la	%r3,default_colors(%r1)	# restore the default colors
	bras	%r14,write_stdout

	#================================
	# Exit
	#================================
	
	xr	%r2,%r2	 		# exit(0)
        svc	SYSCALL_EXIT	        # and exit

	

	#================================
	# strcat
	#================================
	# destination=r13
	# source=r12
	# r0=trashed
strcat:
	sr	%r0,%r0			# nul is our end of line for mvst
move_loop:	
	mvst	%r13,%r12		# move (copy) string from r12 to r13
	bc	3,move_loop(%r1)	# loop if the CPU ended early and
					# we need to continue
					
	basr	0,%r14			# return
	

	#=================================
	# NUM_TO_ASCII
	#=================================
	# r7 is input
	# output returned in *r5
	# r0, r4, r6 trashed

	# I tried to make an excessively clever version of this
	# using the "cvd" (convert to decimal)
	#           "unpk" (unpack)
	#           and "ed" (display)
	# opcodes, but it ended up being much longer than
	# the RISC version.
	
num_to_ascii:
	la	%r5,temp_ascii+7(%r1)
	lhi	%r4,10 			# dividing by 10
div_by_10:	
	xr   	%r6,%r6
	dr	%r6,%r4			# divide r6r7/r4
					# q is in r7, remainder in r6
	ahi  	%r6,0x30		# convert to ascii
	stc	%r6,0(%r5)		# store
	ahi	%r5,-1			# update pointer	

	xr	%r0,%r0
	cr	%r7,%r0			# are we at the end?
	jne	div_by_10		# if not, loop
	
	ar	%r5,%r9	 		# fix pointer to point to beginning

	basr	0,%r14			# return
	

	#=================================
	# FIND_STRING 
	#=================================
	#   r5 is char to end at
	#   r4 points to search string
	#  r13 points at output buffer
	#   r0 trashed
	
find_string:

	# originally wanted to use "cuse" (compare until substring equal)
	# instruction, but it turns out that's not as much a search
	# as it is looking for matches at identical offsets into two strings

        l       %r5,0(%r4)              # 4-byte string in r5
	l       %r6,disk_buffer_p(%r1)  # point to cpuinfo
find_loop:
	l	%r7,0(%r6)		# load 4 bytes from cpuinfo
	ar	%r6,%r9			# increment pointer
	cr	%r5,%r7			# do we match search pattern?
	jne	find_loop		# if not, keep searching
					# (should check for EOF as well	
	
					# if we get this far, we matched

find_colon:
	lhi	%r0,':'			# search for colon
	srst	%r5,%r6			# repeat till we find colon

	ahi	%r5,2			# point after colon and space
store_loop:
	lhi	%r0,'\n'		# grab till end of line
	mvst	%r13,%r5   		# and print to screen
done:
	basr	0,%r14			# return	


	
	#==============================
	# center_and_print
	#==============================
	# 
		
center_and_print:
	lr	%r15,%r14		# save return address
	
	la	%r3,escape(%r1)		# point to escape
	bras	%r14,write_stdout	# print to stdout
	
	lr	%r3,%r8			# point to beginning of buffer
	sr	%r13,%r3	 	# calculate length
					# (r13=r13-r3)
	
	lhi	%r7,80			# load in 80
	cr	%r13,%r7		# compare r13 with r6
	
	bc	2,done_center(%r1)	# if r13 higher, do nothing

	sr	%r7,%r13		# subtract size from 80
	
	sra	%r7,1			# then divide by 2

	bras	%r14,num_to_ascii	# call num_to_ascii

	lr	%r3,%r5
	bras	%r14,write_stdout	# print shift to stdout
	
	la	%r3,C(%r1)		# point to escape
	bras	%r14,write_stdout	# print to stdout	
	
	lr	%r3,%r8			# point to beginning of buffer
	
done_center:
	lr  	%r14,%r15		# restore return address
					# write_stdout returns for us	


	#================================
	# WRITE_STDOUT
	#================================
	# r3 has string
	# r2,r4,r5 trashed
write_stdout:
	lhi	%r2,STDOUT		# write to STDOUT

strlen:
	sr	%r0,%r0			# clear r0 (subtract)
	lr	%r5,%r3			# save r3	
strlen_loop:		
	srst	%r4,%r5			# search for 0, starting at r3
					# and storing result in r4
					
	brc	3,strlen_loop		# cpu stops checking at 256
					# so we loop again if it times out
	
	sr	%r4,%r3			# subtract 0 pointer from original
					# pointer to get length

	svc	SYSCALL_WRITE  		# run the syscall
	basr	0,%r14



#===========================================================================
#	section .data
#===========================================================================


	
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
processor:		.ascii	" Processor\0"
s_comma:		.ascii  "s, \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\n\0"

default_colors: .ascii "\033[0m\n\n\0"
escape:         .ascii "\033[\0"
C:              .ascii "C\0"

.ifdef FAKE_PROC
cpuinfo:	.ascii	"proc/cpu.s390\0"
.else
cpuinfo:	.ascii	"/proc/cpuinfo\0"
.endif

ordinal:	.long	one,two,three,four	

search_sors:	.ascii "sors"
search_bogo:	.ascii "bogo"
search_r_id:	.ascii "r_id"
			
one:	.ascii	"One \0"
two:	.ascii	"Two \0"
three:	.ascii	"Three \0"
four:	.ascii	"Four \0"

.include	"logo.lzss_new"

disk_buffer_p:	.long disk_buffer		
#============================================================================
#	section .bss
#============================================================================
#.bss

.lcomm temp_ascii,16
.lcomm uname_info,(65*6)
.lcomm sysinfo_buff,(64)
	# urgh get above from /usr/src/linux/include/asm/stat.h
	# not glibc
.lcomm text_buf, (N+F-1)	
.lcomm out_buffer,16384
.lcomm	disk_buffer,4096	# we cheat!!!!

