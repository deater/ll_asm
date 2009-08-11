#
#  linux_logo in microblaze assembler 0.38
#
#  By 
#       Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -o ll.o ll.microblaze.s"
#  link with         "ld -o ll ll.o"
#
#  I have to cross-compile, so what I do is was more like
#      make CROSS=/usr/local/bin/mb- ARCH=microblaze


#
# I use qemu for simulating this code (I have no microblaze hardware)
#

# Architectural Info

# Big-endian
# 3-operand
# 32 32-bit registers
#  r0 is a zero register
#  r1 is stack pointer
#  r2 = r/o small data area
#  r3,r4 = return value
#  r5-r10 = parameters
#  r11-r12 = temp vars
#  r13 = r/w small data area
#  r14 = return address for interrupt
#  r15 = return area for functions
#  r16 = return address for debug/breaks
#  r17 = exception return address
#  r18 = reserved for compiler
#  r19-r31 = general use?

# has (optional) branch-delay slots
# aligned memory accesses (can be configured otherwise v3.0 and later)

#  HW multiply (post Virtex-II)

# System Calls
#   syscall number in r12
#   params in r5-r10
# brki r14, 0x08 
# nop   

# instruction set
#  32-bit wide instructions
#  16-bit immediates
#  usually add rd,ra,rb (rd=destination)
#   add, addc, addk, addkc  [carry, keep carry means don't update carry]
#   addi, addic, addik, addikc [add immediate]
#   and, andi, andn, andni [and, and not]
#   beq, beqd, beqi, beqid [branch if equal, with delay, immediate]
#   bge, bged, bgei, bgeid [branch if greater or equal]
#   bgt, bgtd, bgti, bgtid [branch if greater than]
#   ble, bled, blei, bleid [branch if less or equal]
#   blt, bltd, blti, bltid [branh if less than]
#   bne, bned, bnei, bneid [branch if not equal]
#   br, bra, brd, brad, brld, bald [unconditional branch.  l = and link]
#   bri, brai, brid, braid, brlid, bralid [unconditional branch immediate]
#   brk, brki  [break]
#   bsrl, bsra, bsll [barrel shift right logical, right arith, left logic]
#   bsrli, bsrai, bslli [barrel shift immediate]
#   cmp, cmpu [compare]
#   get, nget, cget, ncget [read from interface]
#   idiv, idivu [divide.  only valid if config'd for divider]
#   imm [load 16-bit immediate value to be used to make 32-bit immediate]
#   lbu, lbui [load byte unsigned]
#   lhu, lhui [load halfword unsigned]
#   lw, lwi [load word]
#   mfs, msrclr, msrset, mts  [manipulate special reg]
#   mul, muli [multiply, if configured]
#   or, ori [ or ]
#   put, nput, cput, ncput [write to interface]
#   rsub, rsubc, rsubk, rsubkc [reverse subtract]
#   rsubi, rsubic, rsubik, subikc [reverse subtract immediate]
#   rtbd, rtid, rted [ return from break, interrupt, exception]
#   rtsd [return from subroutine.  always has delay slot]
#   sb,sbi [store byte]
#   sext16, sext8 [sign extend]
#   sh, shi [store halfword]
#   sra, src, srl [shift right, arith, with carry, logical]
#   sw, swi [store word]
#   wdc, wic [write to data, instruction cache]
#   xor, xori [xor]

# Optimization
#  + 1671 bytes - original version, ported from MIPS
#  + 1518 bytes - remove extraneous alignment of data segment
#  + 1490 bytes - make r20 be the "out_buffer" register
#  + 1334 bytes - make data loads use r19 and an offset
#                 eliminate as many empty branch delay slots as possible
#                 either by filling or replacing branch with no-delay version.
#                 Had to be careful not to have a 32-bit load immediate 
#		  in a delay slot.
#  + 1318 bytes - Put text_buf into a reg and use ra+rb addressing
#  + 1314 bytes - remove un-needed register move
#  + 1310 bytes - re-optimize write_stdout
#  + 1298 bytes - have find_string use 3 bytes, not 4

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

# Offsets into the data segment
# Wish I could get the assembler to do this automatically
.equ VER_OFFSET, 0
.equ COMPILED_OFFSET, 10
.equ RAM_OFFSET,22
.equ BOGO_OFFSET,30
.equ LINEFEED_OFFSET,46
.equ DEFAULT_COLORS_OFFSET,48
.equ ESCAPE_OFFSET,54
.equ C_OFFSET,57
.equ CPUINFO_OFFSET,59
.equ ONE_OFFSET,73
.equ MHZ_OFFSET,78
.equ PROCESSOR_OFFSET,94
.equ LOGO_OFFSET,107

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
	#=========================
	# PRINT LOGO
	#=========================

# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver

	addi	r19,r0,data_begin	# point r19 at .data segment begin
	addi	r20,r0,out_buffer	# point r20 at out_buffer

	addi    r8,r0,(N-F)   	     	# R
		
	addi  	r9,r19,LOGO_OFFSET	# r9 points to logo 
	addi	r12,r0,logo_end		# r12 points to end of logo
	add	r21,r0,r20		# point r21 to out_buffer

	addi	r26,r0,text_buf		# point r26 to text_buf

decompression_loop:

	lbu	r22,r0,r9       # load in a byte
	addi	r9,r9,1		# increment source pointer

	ori 	r22,r22,0xff00  # put 0xff in top as a hackish 8-bit counter
				# ugh this expands to two instructions
				# because the 16-bit immediate is sign-extended

test_flags:
	cmp	r18, r12, r9	# have we reached the end?
	beqi	r18, done_logo	# if so, exit
				
        andi	r23,r22,0x1	# test to see if discrete char

	bneid	r23,discrete_char	# if set, we jump to discrete char
	
	# BRANCH DELAY SLOT
	srl	r22,r22  	# shift	right logical by 1


offset_length:
	lbu     r10,r0,r9	# load 16-bit length and match_position combo
	lbui	r24,r9,1	# can't use lhu because might be unaligned
	addi	r9,r9,2	 	# increment source pointer	
	bslli	r24,r24,8
	or	r24,r24,r10
		
	bsrli r25,r24,P_BITS	# get the top bits, which is length
	
	addi r25,r25,THRESHOLD+1 
	      			# add in the threshold?
		
output_loop:
        andi 	r24,r24,(POSITION_MASK<<8+0xff)  	
					# get the position bits
	lbu	r10,r26,r24		# load byte from text_buf[]
			
	addi	r24,r24,1	    	# advance pointer in text_buf

store_byte:
	sb      r10,r0,r21		# store byte to output buffer
	addi	r21,r21,1      		# increment pointer

	sb      r10,r8,r26		# store also to text_buf[r]
	addi 	r8,r8,1        		# r++

	addi	r25,r25,-1		# decrement count
	bneid	r25,output_loop		# repeat until k>j
	#BRANCH DELAY SLOT
	andi 	r8,r8,(N-1)		# wrap r if we are too big

	andi	r23,r22,0xff00		# if 0 we shifted through 8 and must
	bnei	r23,test_flags		# re-load flags
	
	bri 	decompression_loop


discrete_char:
	lbu     r10,r0,r9		# load a byte
	addi	r9,r9,1		       	# increment pointer
	brid     store_byte		# and store it
	# BRANCH DELAY SLOT
	addi   	r25,r0,1		# force a one-byte output

# end of LZSS code

done_logo:

        brlid	r15,write_stdout	# print the logo
	# BRANCH DELAY SLOT
	add	r6,r0,r20		# point r6 to out_buffer	
	
first_line:	
	#==========================
	# PRINT VERSION
	#==========================

	addi	 r24,r0,uname_info 	# r24 holds uname_info

uname_call:
        addi	 r12,r0, SYSCALL_UNAME	# put exit syscall in r12
	add	 r5,r0,r24		# destination struct
        brki	 r14, 0x08	      	# syscall

	add	 r21,r0,r20		# point r21 to out_buffer
		
os_name:
		 			# os-name from uname "Linux"
	brlid	 r15,strcat
	# BRANCH DELAY SLOT
	addi	 r5,r24,U_SYSNAME

version:
					# source is " Version "
       	brlid	r15,strcat     		# call strcat	
	# BRANCH DELAY SLOT
	addi	r5,r19,VER_OFFSET

					# version from uname, ie "2.6.20"
	brlid	r15,strcat		# call strcat
	# BRANCH DELAY SLOT
	addi	r5,r24,U_RELEASE	

compiled:
					# source is ", Compiled "
	brlid	r15,strcat		# call strcat
	# BRANCH DELAY SLOT
	addi	r5,r19,COMPILED_OFFSET
	     
					# compiled date
	brlid	r15,strcat		# call strcat
	# BRANCH DELAY SLOT
	addi	r5,r24,U_VERSION

	brlid	r15,center_and_print	# center and print
	# BRANCH DELAY SLOT
	nop	       	   		# no such instruction as brli
					# without a delay :(
 	
	#===============================
	# Middle-Line
	#===============================
middle_line:
	
	add	r21,r0,r20		# point r21 to out_buffer
	
	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	addi	r12,r0,SYSCALL_OPEN	# OPEN Syscall	
	addi	r5,r19,CPUINFO_OFFSET	# '/proc/cpuinfo'
	add	r6,r0,r0		# 0 = O_RDONLY <bits/fcntl.h>

	brki	r14,0x08		# syscall.  fd in v0  
					# we should check that 
					# return r3>=0
						
	add	r5,r3,r0		# copy r3 (the result) to r5
	
	addi	r12,r0,SYSCALL_READ	# read()
	addi	r6,r0,disk_buffer
					# point r6 to the buffer

	addi	r7,r0,4096		# we assume cpuinfo file is <4096bytes
				      
	brki	r14,0x08

	addi	r12,r0,SYSCALL_CLOSE	# close (to be correct)
		    			# fd should still be in r5
	brki	r14,0x08

	#=============
	# Number of CPUs
	#=============
number_of_cpus:

	# we cheat here and just assume 1.  
	# I don't know if SMP microblaze machines exist

	brlid	r15,	strcat
	# BRANCH DELAY SLOT
	addi	r5,r19,ONE_OFFSET		# print "One"

	#=========
	# MHz
	#=========
print_mhz:

   	addi	r5,r0,('M'<<16+'H'<<8+'z')     	
					# find '-MHz' and grab up to '.'

	brlid	r15,find_string
	# BRANCH DELAY SLOT
	addi	r6,r0,'.'		# find up to "."
	
					# print "MHz"
	brlid	r15,strcat
	# BRANCH DELAY SLOT
	addi	r5,r19,MHZ_OFFSET

   	#=========
	# Chip Name
	#=========
chip_name:	
   	addi	r5,r0,('r'<<16+'c'<<8+'h')     	
					# find 'Arch' and grab up to '\n'

	brlid	r15	find_string
	# BRANCH DELAY SLOT
	addi	r6,r0,'\n' 		# find up to "\n"
	
					# print "Processor, "
	brlid	r15,strcat
	# BRANCH DELAY SLOT
	addi	r5,r19,PROCESSOR_OFFSET

	
	#========
	# RAM
	#========
ram:	
	addi	r12,r0,SYSCALL_SYSINFO	# sysinfo() syscall
	addi	r5,r0,sysinfo_buff
	brki	r14,0x08
	
	lwi	r5,r5,S_TOTALRAM	# size in bytes of RAM
	add	r7,r0,r0		# print to strcat, not stderr

	brlid	r15,num_to_ascii
	# BRANCH DELAY SLOT
	bsrli	r5,r5,20		# divide by 1024*1024 to get M

	
					# print 'M RAM, '
	brlid	r15,strcat     		# call strcat
	# BRANCH DELAY SLOT
	addi	r5,r19,RAM_OFFSET


	#========
	# Bogomips
	#========
bogomips:	
	addi	r5,r0,('i'<<16+'p'<<8+'s')      	
					# find 'Mips' and grab up to \n
	brlid	r15,find_string
	# BRANCH DELAY SLOT
	addi	r6,r0,'\n'		# find up to "\n"

	
					# bogo total follows RAM 
	brlid	r15,strcat     		# call strcat
	# BRANCH DELAY SLOT
	addi	r5,r19,BOGO_OFFSET

	brlid	r15,center_and_print	# center and print
	# BRANCH DELAY SLOT
	nop	       	   		# no such thing as brli :(
	
	#=================================
	# Print Host Name
	#=================================
last_line:
	add	r21,r0,r20		# point r21 to out_buffer

					# host name from uname()
	brlid	r15,strcat		# call strcat
	# BRANCH DELAY SLOT
	addi	r5,r24,U_NODENAME	
	
	brlid	r15,center_and_print	# center and print
	# BRANCH DELAY SLOT
	nop	       	   		# brli doesn't exist :(
	
					# (.txt) pointer to default_colors

	brlid	r15,write_stdout
	# BRANCH DELAY SLOT
	addi	r6,r19,DEFAULT_COLORS_OFFSET
	

	#================================
	# Exit
	#================================
	
exit:
        addi	 r12, r0, SYSCALL_EXIT	# put exit syscall in r12
	addi	 r5, r0,5		# return value 
        brki	 r14, 0x08	      	# syscall


	#=================================
	# FIND_STRING 
	#=================================
	#   r5 is 3-char ascii string to look for	
	#   r6 is char to end at

find_string:					
	addi	r11,r0,disk_buffer	
					# look in cpuinfo buffer
find_loop:
	  				# load unaligned 3 bytes into reg

	lbui	r22,r11,0		# load first byte
	add	r23,r22,r0		# move
	bslli	r23,r23,8		# shift
	lbui	r22,r11,1		# load second byte
	add	r23,r22,r23		# move
	bslli	r23,r23,8		# shift
	lbui	r22,r11,2		# load third byte
	add	r23,r22,r23		# move
	
	beqi	r23,done		# are we at EOF?
					# if so, done
	addi    r11,r11,1		# increment pointer

	cmp	r22,r23,r5
	bnei	r22, find_loop		# do the strings match?
					# if not, loop
	
					# if we get this far, we matched
					
	addi	r11,r11,4		# skip to spacing				
					
skip_spaces:
	lbui	r22,r11,1		# repeat till we find non-space
	addi	r11,r11,1

	beqi	r22,done		# if 0, at end

	addi	r23,r0,' '
	cmp	r23,r23,r22
	blei	r23,skip_spaces
	
store_loop:
	lbu	r22,r0,r11		# load value
	addi	r11,r11,1		# increment
	beqi	r22,done		# off end, then stop

	cmp	r23,r22,r6
	beqi	r23,done      		# is it end char?
	
	sb	r22,r0,r21		# if not store and continue
	
	brid	store_loop		# loop
	# BRANCH DELAY SLOT
	addi	r21,r21,1		# increment output pointer	

	
done:

	rtsd	r15,8			# return (delay slot version)
	# BRANCH DELAY SLOT
	nop


	#==============================
	# center_and_print
	#==============================
	# string is in output_buffer (r21 points to end of string)
	# r31 trashed (backup of return address)
	
center_and_print:

	add	r31,r0,r15		# save return address
       
	add	r23,r0,r20              # point r23 to beginning 
				        # end is in r21

	rsub	r5,r23,r21		# subtract end pointer from start
       		    			# (cheaty way to get size of string)

	rsubi	r5,r5,80
	blti	r5,done_center		# don't center if > 80

	srl	r23,r5			# divide by 2, store for later

	brlid	r15,write_stdout	# print ESCAPE char
	# BRANCH DELAY SLOT
	addi	r6,r19,ESCAPE_OFFSET
	
	addi	r7,r0,1			# print to stdout
	brlid	r15,num_to_ascii       	# print number of spaces
	# BRANCH DELAY SLOT
	add	r5,r0,r23      		# how much to shift to right

	brlid	r15,write_stdout
	# BRANCH DELAY SLOT
	addi	r6,r19,C_OFFSET		# print "C"


done_center:

	brlid	r15,write_stdout
	# BRANCH DELAY SLOT
	add	r6,r0,r20		# point to the string to print

	addi	r6,r19,LINEFEED_OFFSET	# print linefeed at end of line
	
	add 	r15,r0,r31		# restore return address

					# fall through to write_stdout


	#================================
	# WRITE_STDOUT
	#================================
	# r6 has string
	# r9,r12 destroyed

write_stdout:

	addi 	r12, r0, SYSCALL_WRITE	# Write syscall in r12
	addi	r5, r0, STDOUT		# STDOUT in r5
	add	r7,r0,r0		# count in r7
		
str_loop1:
	lbu	r9,r6,r7		# load byte at r10
	beqi	r9,str_done		# if nul, done
	brid	str_loop1		# loop
	# BRANCH DELAY SLOT
	addi	r7,r7,1			# increment count

str_done:
	brki r14, 0x08			# run the syscall

	rtsd	r15,8 			# return (branch delayed version)
	# BRANCH DELAY SLOT
	nop

	
	#=======================
	# num_to_ascii
	#=======================
	# r5 = value to print
	# r6 = pointer to output 
	# r7 = 1 if stdout, 0 if strcat
	# r8,r11,r22 trashed
	
num_to_ascii:

	addi	 r6,r0,ascii_buffer+10	
				# point to end of ascii_buffer

div_by_10:
	addi	r6,r6,-1	# point back one
	
	addi	r11,r0,10	# divide by 10

	idiv	r22,r11,r5	# quotient in r22
	
	muli	r8,r22,10	# calculate remainder
	rsub	r8,r8,r5	# remainder is in r7

	addi	r8,r8,0x30	# convert to ascii
	sb	r8,r0,r6	# store to buffer
	add	r5,r22,r0      	# move old result into next divide
	bnei	r22, div_by_10

write_out:

	bnei	r7,write_stdout	# if write_stdout, go there
	
	# else fall through to strcat
	
	add    r5,r6,r0



	#================================
	# strcat
	#================================
	# output_buffer_offset = r21
	# string to cat = r5
	# destroys r11

strcat:
	lbu 	r11,r0,r5		# load byte from string
	addi	r5,r5,1			# increment string	
	sb  	r11,r0,r21		# store byte to output_buffer

	bneid 	r11,strcat		# if zero, we are done
	# BRANCH DELAY SLOT
	addi	r21,r21,1		# increment output_buffer

done_strcat:
	rtsd	r15,8			# return
	# BRANCH DELAY SLOT
	addi	r21,r21,-1		# correct pointer	


#===========================================================================
#	section .data
#===========================================================================
.data



data_begin:	
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"
linefeed:	.ascii  "\n\0"
default_colors:	.ascii "\033[0m\n\0"
escape:		.ascii "\033[\0"
c:		.ascii "C\0"

.ifdef FAKE_PROC
cpuinfo:	.ascii	"proc/c.ublaze\0"
.else
cpuinfo:	.ascii	"/proc/cpuinfo\0"
.endif

one:	.ascii	"One \0"
mhz:	.ascii  "MHz Microblaze \0"
processor:	.ascii " Processor, \0"

.include	"logo.lzss_new"

#============================================================================
#	section .bss
#============================================================================
.bss
bss_begin:	
.lcomm	out_buffer,16384
.lcomm  text_buf, (N+F-1)
.lcomm	disk_buffer,4096	# we cheat!!!!

.lcomm  ascii_buffer,10		# 32 bit can't be > 9 chars

   # see /usr/src/linux/include/linux/kernel.h
.lcomm sysinfo_buff,(64)
.lcomm uname_info,(65*6)
