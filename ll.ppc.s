#
#  linux_logo in ppc assembler    0.5
#
#  by Vince Weaver <vince@deater.net>
#
#  assemble with     "as -o ll.o ll.ppc.s"
#  link with         "ld -o ll ll.o"

#  BUGS:  No Pretty Printing (rounding, cpu-model cleanup)
#      :  Only works with <1GB of RAM
#      :  Doesn't print vendor name
#      :  doesn't count CPU's on SMP systems

# offsets into the results returned by the uname syscall
.equ U_SYSNAME,0
.equ U_NODENAME,65
.equ U_RELEASE,65*2
.equ U_VERSION,(65*3)
.equ U_MACHINE,(65*4)
.equ U_DOMAINNAME,65*5

# offset into the results returned by the stat syscall
.equ S_SIZE,28

	.globl _start	
_start:	
#	eieio				# coolest opcode of all time ;)
					# not needed, but I had to put it here

# r0:  reserved   r1:  reserved
# r2:  reserved   r3:  reserved
# r4:  reserved   r5:  reserved
# r6:  reserved   r7:  scratch
# r8:  10         r9:  'm'
# r10: loop_count r11: 100
# r12: flag       r13: reserved
# r14: reserved   r15: output
# r16: new_logo   r17: output
# r18: scratch    r19: scratch
# r20: scratch    r21: reserved
# r22: reserved   r23: reserved
# r24: reserved   r25: reserved
# r26: reserved   r27: reserved
# r28: reserved   r29: reserved
# r30: reserved   r31: reserved

        #=========================
	# PRINT LOGO
	#=========================
	
	lis	16,new_logo@ha	  	# point input to new_logo
	addi	16,16,new_logo@l-1	# -1 so we can use lbzu
	lis	17,out_buffer@ha	# point output to buffer
	addi	17,17,out_buffer@l-1	# -1 so we can use stbu
	mr	15,17			# save pointer to begin of output
	addi	15,15,1			# fix r15 because of stbu offset
	li 	8,10			# ten, used in division later
	li	9,';'
	li	11,100			# one hundred, used later

main_logo_loop:	
	lbzu	18,1(16)		# load character
	cmpwi	18,0			# if zero, we are done
	beq 	done_logo
	
	cmpwi	18,27      		# if ^[, we are a color
        bne	blit_repeat             # with non-m character

	li	7,27
	stbu	7,1(17)			# out ^[[ to buffer
	li	7,'['
	stbu	7,1(17)


        lbzu	10,1(16)		# load number of elements
	mtctr	10
element_loop:
        lbzu	18,1(16)		# load color

        cmpwi	18,100			# is it less than 100?
	blt	out_tens		# if so skip ahead

        divw	19,18,11		# divide by 100
	addi	20,19,0x30		# convert hundreds to ascii
	stbu	20,1(17)		# out the hundreds digit
	mullw	19,19,11		# multiply
	subf	18,19,18		# then subtract for remainder
out_tens:
	cmpwi	18,10			# is it less than 10?		
	blt	out_ones		# if so skip ahead
	
	divw	19,18,8			# divide by 10
	addi	20,19,0x30		# convert tens to ascii
	stbu	20,1(17)		# out the tens digit
	mullw	19,19,8			# multiply
	subf	18,19,18		# then subtract for remainder
out_ones:
	addi	18,18,0x30		# convert ones digit to ascii
	stbu	18,1(17)		# out to buffer
	
	stbu	9,1(17)			# load ';'
	bdnz	element_loop
	
	addi	17,17,-1    		# remove excess ;
	
	lbzu	18,1(16)    		# write out char
	stbu	18,1(17)
	
	b 	main_logo_loop		# done with color

blit_repeat:
	lbzu	10,1(16)		# get times to repeat
	mtctr	10			# load into counter register
blit_loop:	
	stbu	18,1(17)
	bdnz	blit_loop		# decrement, check for zero, loop
	
	b main_logo_loop

done_logo:	
	li	0,4			# number of the "write" syscall
	li	3,1			# stdout
	mr	4,15			# output_buffer pointer
	bl	strlen
	sc	           		# do syscall

	lis	4,line_feed@ha
	addi	4,4,line_feed@l		# print line-feed
	bl	put_char
	
	#==========================
	# PRINT VERSION
	#==========================
	
	li	0,122		   	# uname syscall
	lis	3,uname_info@ha		# uname struct
	addi	3,3,uname_info@l
	sc				# do syscall
	
	mr	17,15			# restore output to out_buffer
	addi	17,17,-1		# adjust so can use stbu
	
	lis	16,uname_info+U_SYSNAME@ha	# destination is temp_string
	addi	16,16,uname_info+U_SYSNAME@l-1	# os-name from uname "Linux"
	bl	strcat
	
	lis	16,ver_string@ha		# source is " Version "
	addi	16,16,ver_string@l-1
	bl 	strcat
	
	lis	16,uname_info+U_RELEASE@ha    	# version from uname "2.4.1"
	addi	16,16,uname_info+U_RELEASE@l-1
	bl 	strcat
	
	lis	16,compiled_string@ha		# source is ", Compiled "
	addi	16,16,compiled_string@l-1
	bl 	strcat

	lis	16,uname_info+U_VERSION@ha	# compiled date
	addi	16,16,uname_info+U_VERSION@l-1
	bl 	strcat
	
	mr	4,15  			# restore saved location of out_buff
	
	bl	strlen			# returns size in r5
	
	bl	center			# print some spaces
	
	mr 	4,15			
	li	0,4			# write syscall
	li	3,1			# stdout	
	bl	strlen			
	sc
	
	lis	4,line_feed@ha		# print line-feed
	addi	4,4,line_feed@l
	bl	put_char
	
  
	
	#===============================
	# Middle-Line
	#===============================
	
	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	li	0,5			# open()
	lis	3,cpuinfo@ha		# '/proc/cpuinfo'
	addi	3,3,cpuinfo@l		# O_RDONLY <bits/fcntl.h>
	li	4,0
	sc				# syscall.  fd in r0.  
					# we should check that r0>=0
					
	mr	13,3			# save fd in r13
	li	0,3			# read
	lis	4,disk_buffer@ha
	addi	4,4,disk_buffer@l
	li	5,4096		 	# 4096 is maximum size of proc file ;)
	sc	

	mr	3,13			# restore fd
	li	0,6			# close
	sc

	#=============
	# Number of CPU's
	#=============
	
	mr	17,15 			# point output to out_buf
	addi	17,17,-1		# adjust so can use stbu

	# Assume 1 CPU for now
	# my iBook's /proc/cpuinfo does not have a "processor" line ???
	
	lis  	16,one@ha
	addi	16,16,one@l-1
	bl	strcat

	#=========
	# MHz
	#=========
	
	li	20,'o'			# find 'ock\t: ' and grab up to .
	li	21,'c'
	li	22,'k'
	li	23,'M'			
   	bl	find_string
   
 	lis	16,megahertz@ha		# print 'MHz '
	addi	16,16,megahertz@l-1
	bl	strcat
   
   
   	#=========
	# Chip Name
	#=========
	
   	li      20,'c'     	# find 'cpu\t: ' and grab up to \n
	li	21,'p'
	li	22,'u'
	li	23,'\n'
	bl	find_string
	
	lis	16,comma@ha		# print ', '
	addi	16,16,comma@l-1
	bl	strcat
	
	#========
	# RAM
	#========
	
	li	0,106	       		# stat() syscall
	lis	3,kcore@ha		# /proc/kcore
	addi	3,3,kcore@l

	lis	4,stat_buff@ha
	addi	4,4,stat_buff@l
	sc
	
	lis	18,stat_buff+S_SIZE@ha	# size in bytes of RAM
	addi	18,18,stat_buff+S_SIZE@l

	lwz	19,0(18)

	srawi	19,19,10		# divide to get K
	srawi	19,19,10		# divide to get M
	
	li	20,100			# load in 100
	divw	21,19,20		# divide mem by 100 
	cmpwi	21,0			# suppress leading zeros
	beq	tens
	addi	22,21,0x30		# convert to ascii
	stbu	22,1(17)		# store value
	mullw	21,21,20		# play some games to get remainder
	subf	19,21,19		# back in r19
tens:	
	li	20,10			# load in 10
	divw	21,19,20		# divide by 10
	cmpwi	21,0			# suppress leading zeros
	beq	ones
	addi	22,21,0x30		# convert to ascii
	stbu	22,1(17)		# print tens digit
	mullw	21,21,20
	subf	19,21,19		# remainder
ones:	
	addi	19,19,0x30		# convert to ascii
	stbu	19,1(17)		# print ones digit
	
	lis	16,ram_comma@ha		# print 'M RAM, '
	addi	16,16,ram_comma@l-1
	bl	strcat
	
	#========
	# Bogomips
	#========
	
	li	20,'i'      		# find 'ips\t: ' and grab up to \n
	li	21,'p'
	li	22,'s'
	li	23,10
	bl	find_string
      
   	lis	16,bogo_total@ha
	addi	16,16,bogo_total@l-1
	bl	strcat

	mr	4,15  	       		# string done, lets print it
	bl	strlen			# returns size in edx
	
	bl	center			# print some spaces
		
	li 	0,4			# write syscall
	li 	3,1			# stdout
	mr	4,15
       	bl	strlen			
        sc
       		
	lis 	4,line_feed@ha		# print line-feed
	addi	4,4,line_feed@l
	bl 	put_char
	
	#=================================
	# Print Host Name
	#=================================

	lis	4,uname_info+U_NODENAME@ha
	addi	4,4,uname_info+U_NODENAME@l
	
	bl	strlen
	bl	center			# center it
	li 	0,4			# write syscall
	li 	3,1			# stdout

	lis	4,uname_info+U_NODENAME@ha
	addi	4,4,uname_info+U_NODENAME@l
	bl	strlen
	sc

	li	0,4			# restore default colors
	li	3,1
	lis	4,default_colors@ha
	addi	4,4,default_colors@l
	bl	strlen
	sc

	lis	4,line_feed@ha		# print line-feed
	addi	4,4,line_feed@l
	bl 	put_char
	bl	put_char

	#================================
	# Exit
	#================================
	
        li      3,0		# 0 exit value
        li      0,1           	# put the exit syscall number in eax
        sc	             	# and exit



	#=================================
	# FIND_STRING 
	#=================================
	#   r23 is char to end at
	#   r20,r21,r22 are 3-char ascii string to look for
	#   r17 points at output buffer

find_string:
					
	lis	16,disk_buffer@ha	# look in cpuinfo buffer
	addi	16,16,disk_buffer@l-1	# -1 so we can use lbzu
	
find_loop:
	lbzu	13,1(16)		# watch for first char
	cmpwi	13,0
	beq	done
	cmpw	13,20
	bne	find_loop
	lbzu	13,1(16)		# watch for second char
	cmpw	13,21
	bne	find_loop
	lbzu	13,1(16)		# watch for third char
	cmpw	13,22
	bne	find_loop
	
					# if we get this far, we matched

	li	14,':'
find_colon:
	lbzu	13,1(16)		# repeat till we find colon
	cmpwi	13,0
	beq	done
	cmpw	13,14
	bne	find_colon

	addi	16,16,1			# skip a char [should be space]
	
store_loop:	 
	 lbzu	13,1(16)
	 cmpwi	13,0
	 beq	done
    	 cmpw	13,23			# is it end string?
	 beq 	almost_done		# if so, finish
	 stbu	13,1(17)		# if not store and continue
	 b	store_loop
	 
almost_done:	 
	li	13,0			# replace last value with null
	stb	13,1(17)

done:
	blr


	#================================
	# put_char
	#================================
	# value to print pointed to by r4

put_char:
	li	0,4			# write char
	li	3,1			# stdout
	li	5,1			# write 1 char
	sc
	blr
	

	#================================
	# strcat
	#================================
	# r13 = "temp"
	# r16 = "source"
	# r17 = "destination"
strcat:
	lbzu	13,1(16)		# load a byte from [r16]
	stbu	13,1(17)		# store a byte to [r17]
	cmpwi	13,0			# is it zero?
	bne	strcat			# if not loop
	subi	17,17,1			# point to one less than null
	blr				# return

	#===============================
	# strlen
	#===============================
	# r4 points to string
	# r5 is returned with length

strlen:
	mr	18,4			# copy pointer
	li	5,0			# set count to 0
str_loop:
	addi	18,18,1			# increment pointer
	addi	5,5,1			# increment counter
	lbz	19,0(18)		# load byte
	cmpwi	19,0			# is it zero?
	bne	str_loop		# if not, loop
	blr
	
	
	#==============================
	# center
	#==============================
	# r5 has length of string
	# r13, r14=temp
	
center:
        mflr	14			# store return address in r14
	cmpwi	5,80			# see if we are >80
	bgt	done_center		# if so, bail

	li	13,80			# 80 column screen
	subf	13,5,13			# subtract strlen
	srawi	13,13,1			# divide by two
	lis	4,space@ha		# load pointer to space		
	addi	4,4,space@l
	mtctr   13	   		# load into count register
center_loop: 
	bl 	put_char		# and print that many spaces
	bdnz	center_loop
done_center:	
	mtlr	14
	blr


#===========================================================================
#.data
#===========================================================================

.equ		NORMAL , 0
.equ		BOLD   , 1
.equ		F_BLACK,30
.equ		F_RED  ,31
.equ		F_YELLW,33
.equ		F_WHITE,37
.equ		B_BLACK,40
.equ		B_WHITE,47

		# logo is Run Length Encoded.  This saves ~1k
		# first character is char to output, second is run-length
		# if first char is ESC (27) then what follows is a color
		# to be print using "^[[xm" where x is the color
		# I could have compressed this more, but I left it generic
		# enough that _any_ logo, not just default, can be used
		# we could save a mov instruction by flipping order of fields
		# oh well

.include "logo.inc"

line_feed:	.ascii  "\n"
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
space:		.ascii	" \0"
megahertz:	.ascii	"MHz PPC \0"
comma:		.ascii	", \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"

default_colors:	.ascii	"\033[0m\0"

cpuinfo:	.ascii	"/proc/cpuinfo\0"
kcore:		.ascii	"/proc/kcore\0"


one:	.ascii	"One \0"

#============================================================================
#.bss
#============================================================================
	
.lcomm out_char,1,4

.lcomm stat_buff,(4*32),4
	# urgh get above from /usr/src/linux/include/asm/stat.h
	# not glibc

.lcomm uname_info,(65*6),4

.lcomm	disk_buffer,4096,4	# we cheat!!!!
.lcomm	out_buffer,16384,4	# we cheat, 16k output buffer



