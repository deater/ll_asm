#
#  linux_logo in ppc assembler    0.12
#
#  by Vince Weaver <vince@deater.net>
#
#  assemble with     "as -o ll.o ll.ppc.s"
#  link with         "ld -o ll ll.o"

#  BUGS:  No Pretty Printing (rounding, cpu-model cleanup)
#      :  Doesn't print vendor name
#      :  doesn't count CPU's on SMP systems

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
.equ SYSCALL_STAT,   106
.equ SYSCALL_SYSINFO,116
.equ SYSCALL_UNAME,  122

#
.equ STDIN, 0
.equ STDOUT,1
.equ STDERR,2

.equ BSS_BEGIN,25
.equ DATA_BEGIN,26

	.globl _start	
_start:	
#	eieio				# coolest opcode of all time ;)
					# not needed, but I had to put it here
        #=========================
	# PRINT LOGO
	#=========================

# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver

  	# the hack loading BSS_BEGIN and DATA_BEGIN
	# saves one instruction on any future load from memory
	# as we can just do an addi rather than an lis;addi

	lis	25,bss_begin@ha
	addi	25,25,bss_begin@l
	
	lis	26,data_begin@ha
	addi	26,26,data_begin@l

	addi	11,BSS_BEGIN,(text_buf-bss_begin)
 	     				# fill "text_buf" with most common char
				        # frequent char is '#' in default logo

	addi	12,DATA_BEGIN,(logo-data_begin)-1
					# logo_pointer

	addi	13,DATA_BEGIN,(logo_end-data_begin)
					# end of the logo
	
	addi	14,BSS_BEGIN,(out_buffer-bss_begin)
					# the output buffer

	mr	17,14		    	# store out-buffer for later

	li	31,FREQUENT_CHAR	# load the "frequent char"
	li	10,(N-F)		# grab how many times to store it
	mr	6,10			# save also as "r"
	li	5,0	
fill_loop:	
	addi	5,5,1			# decrement pointer
	stbx	31,11,5			# store the frequent char
	cmp	0,5,10
	bne	fill_loop		# loop until filled our block

	li	8,0			# load the shift counter
decompression_loop:
	srwi 	10,10,1			# shift right our flags

	addic.	8,8,-1			# decrement the shift counter
	bgt	check_flags		# if <0 we need a new flag
grab_new_flags:
	li     	8,8			# reload shift counter
	bl      read_byte		# load a byte
	mr	10,9			# move it to r10

check_flags:
	andi.	7,10,1			# grab low bit and check for zero
	
	beq	offset_length		# if zero, offset_length and move ahead

discreet_char:	
	bl	read_byte		# get a byte
	stbu	9,1(14)			# store it to output
	stbx	9,11,6			# store it to tex_buf["r"]
	addi	6,6,1			# increment "r"
	andi.	6,6,(N-1)		# mask it
	b       decompression_loop	# and keep looping
	
offset_length:				
	bl read_byte			# get a byte
	mr	5,9			# save it
	bl	read_byte		# get another byte
	
	# 5=i, 9=j
	
	rlwinm 	4,9,4,20,23		# rotate r9 left by 4, mask
					# off bits 20-24, then store in r4
					# very CISC ;)
					
	or	5,4,5			# i= top 4 bits of j, 8 bits of i

	andi.	9,9,0x0f		# j= bottom 4 bits + threshold
	addi	9,9,THRESHOLD+1		# plus one to make it work out
	
	li	3,0	     	# k=0
	
      	
	
output_loop:
	add 	4,5,3		# r4= i+k
	andi.	4,4,(N-1)	# r4= (i+k)&(N-1)
	lbzx	4,11,4		# r4=text_buf[(i+k)&(N-1)]
	addi	3,3,1		# k++
	
	stbu	4,1(14)		# out(c)
	
	stbx	4,11,6		# text_buf[r]=c
	addi	6,6,1		# r++
	andi.	6,6,(N-1)	# r&=(N-1)
	
	cmp	0,3,9		# if k>j?
	blt	output_loop	# if not, loop

	b   	decompression_loop
	
read_byte:
	lbzu    9,1(12)		# get a byte from pointed to area
        cmpw	0,12,13		# does our pointer match end pointer?
     	
        beq	done_decompressing	# if so stop decoding
	blr			# otherwise return
	
	
done_decompressing:

	addi	4,17,1		# restore (plus one because r17 is decremented)
	bl	write_stdout	# and print the logo


	#==========================
	# PRINT VERSION
	#==========================
	
	li	0,SYSCALL_UNAME		# uname syscall
	addi	3,BSS_BEGIN,(uname_info-bss_begin)		
					# uname struct
	sc				# do syscall

	mr	14,17			# restore out buffer

	addi	16,BSS_BEGIN,(uname_info-bss_begin)+U_SYSNAME@l-1	
					# os-name from uname "Linux"
	bl	strcat
	
	addi	16,DATA_BEGIN,(ver_string-data_begin)-1
					# source is " Version "
	bl 	strcat
	
	addi	16,BSS_BEGIN,(uname_info-bss_begin)+U_RELEASE@l-1
					# version from uname "2.4.1"
	bl 	strcat
	
	addi	16,DATA_BEGIN,(compiled_string-data_begin)-1
					# source is ", Compiled "
	bl 	strcat

	addi	16,BSS_BEGIN,(uname_info-bss_begin)+U_VERSION-1
      					# compiled date
	bl 	strcat
	
	addi	14,17,1			# restore pointer to output buffer
	bl	center			# center it
	
	li	6,0x0a00  		# load linefeed and null
	sthu	6,0(14)			# save to end of string

	addi	4,17,1			# restore pointer to output
	bl	write_stdout		# write it to screen

	
	#===============================
	# Middle-Line
	#===============================
	
	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	li	0,SYSCALL_OPEN		# open()
	addi	3,DATA_BEGIN,(cpuinfo-data_begin)		
					# '/proc/cpuinfo'
	li	4,0			# O_RDONLY <bits/fcntl.h>
	sc				# syscall.  fd in r0.  
					# we should check that r0>=0
					
	mr	13,3			# save fd in r13
	
	li	0,SYSCALL_READ		# read
	addi	4,BSS_BEGIN,(disk_buffer-bss_begin)
	li	5,4096		 	# 4096 is maximum size of proc file ;)
	sc	

	mr	3,13			# restore fd
	li	0,6			# close
	sc

	#=============
	# Number of CPU's
	#=============
	
	mr	14,17 			# point output to out_buf

	# Assume 1 CPU for now
	# my iBook's /proc/cpuinfo does not have a "processor" line ???
	
	addi	16,DATA_BEGIN,(one-data_begin)-1
	bl	strcat
	
	#=========
	# MHz
	#=========
	
    	lis	20,('l'<<8)+'o'		# find 'lock ' and grab up to M
	addi	20,20,('c'<<8)+'k'
	li	23,'M'			
   	bl	find_string
   
	addi	16,DATA_BEGIN,(megahertz-data_begin)-1
					# print 'MHz '
	bl	strcat
   
  
	#=========
	# Chip Name
	#=========
	
   	lis     20,('c'<<8)+'p'     	# find 'cpu\t: ' and grab up to \n
	addi	20,20,('u'<<8)+'\t'
	li	23,'\n'
	bl	find_string
	
	addi	16,DATA_BEGIN,(comma-data_begin)-1
					# print ', '
	bl	strcat
	
	#========
	# RAM
	#========
	
	li	0,SYSCALL_SYSINFO	# sysinfo() syscall
	addi	3,BSS_BEGIN,(sysinfo_buff-bss_begin)
					# sysinfo_buffer

	sc

	addi	18,BSS_BEGIN,(sysinfo_buff-bss_begin)+S_TOTALRAM
					# load pointer to bytes of RAM into r18
	lwz	19,0(18)		# load bytes of RAM into r19

	srawi	19,19,20		# divide by 2^20 to get MB


	addi	16,BSS_BEGIN,(num_to_ascii_end-bss_begin)
					# the end of a backwards growing
					# 10 byte long buffer.  Hopefully
					# our RAM is less than that


	li	20,10			# load in 10
div_by_10:
	divw	21,19,20		# divide r19 by r20 put into r21 
	
	mullw	22,21,20		# find remainder.  1st q*dividend
	subf	22,22,19		# then subtract from original = R
	addi	22,22,0x30		# convert remainder to ascii
    	
	stbu	22,-1(16)		# Store to backwards buffer
	
	mr	19,21			# move Quotient as new dividend
	cmpwi	19,0			# was quotient zero?
	bne    	div_by_10		# if not keep dividing
	
write_out:
	addi	16,16,-1		# point to the beginning
	bl	strcat			# and print it

	addi	16,DATA_BEGIN,(ram_comma-data_begin)-1
					# print 'M RAM, '

	bl	strcat
	
	#========
	# Bogomips
	#========
	
	lis	20,('m'<<8)+'i'		# find 'mips' and grab up to \n
	addi	20,20,('p'<<8)+'s'
	li	23,'\n'
	bl	find_string
      
	addi	16,DATA_BEGIN,(bogo_total-data_begin)-1
					# print "Bogomips Total"
	bl	strcat

	addi	14,17,1			# point to output buffer
	bl	center			# center it
	
	li	6,0x0a00		# tack a linefeed and null on end
	sthu	6,0(14)			# write out 16 bits
	
	addi	4,17,1			# point to buffer
	bl	write_stdout		# print it

	#=================================
	# Print Host Name
	#=================================

	addi	14,BSS_BEGIN,(uname_info-bss_begin)+U_NODENAME
					# hostname		       
	bl	center
	
	addi	4,BSS_BEGIN,(uname_info-bss_begin)+U_NODENAME
					# hostname again
	bl	write_stdout
	
	addi	4,DATA_BEGIN,(default_colors-data_begin)
					# ansi to restore colors and two lf's
	bl	write_stdout

	#================================
	# Exit
	#================================
	
        li      3,0		# 0 exit value
	li      0,SYSCALL_EXIT  # put the exit syscall number in eax
	sc	             	# and exit


	#================================
	# WRITE_STDOUT
	#================================
	# r4 has string
	# r0,r3,r4,r5,r6 trashed
	
	
write_stdout:
	li	0,SYSCALL_WRITE		# write syscall
	li	3,STDOUT		# stdout	
	
	li	5,0			# string length counter
strlen_loop:
	addi	5,5,1			# increment counter
	lbzx 	6,4,5			# get string[r5]
	cmpi	0,6,0			# is it zero?
	bne	strlen_loop		# if not keep counting
	
	sc				# syscall
	
	blr				# return



	#=================================
	# FIND_STRING 
	#=================================
	#   r23 is char to end at
	#   r20 is the 4-char ascii string to look for
	#   r14 points at output buffer

find_string:
		
	addi	16,BSS_BEGIN,(disk_buffer-bss_begin)-1	
					# look in cpuinfo buffer
					# -1 so we can use lbzu
	
find_loop:
	lwzu	13,1(16)		# load in 32 bits, incrementing 8bits
	cmpwi	13,0			# if null, we are done
	beq	done
	cmpw	13,20			# compare with out 4 char string
	bne	find_loop		# if no match, keep looping

	
					# if we get this far, we matched
					
	li	21,':'
find_colon:
	lbzu	13,1(16)		# repeat till we find colon
	cmpwi	13,0
	beq	done
	cmpw	13,21
	bne	find_colon

	addi	16,16,1			# skip a char [should be space]
	
store_loop:	 
	 lbzu	13,1(16)
	 cmpwi	13,0
	 beq	done
    	 cmpw	13,23			# is it end string?
	 beq 	almost_done		# if so, finish
	 stbu	13,1(14)		# if not store and continue
	 b	store_loop
	 
almost_done:	 
	li	13,0			# replace last value with null
	stb	13,1(14)

done:
	blr

	#================================
	# strcat
	#================================
	# r13 = "temp"
	# r16 = "source"
       	# r14 = "destination"
strcat:
	lbzu	13,1(16)		# load a byte from [r16]
	stbu	13,1(14)		# store a byte to [r14]
	cmpwi	13,0			# is it zero?
	bne	strcat			# if not loop
	subi	14,14,1			# point to one less than null
	blr				# return

	#==============================
	# center
	#==============================
	# r13, r7, r5, r6 =temp
	# r14 is string (points to end afterwards)
	
center:


	li	5,0			# string length counter
str_loop:
	addi	5,5,1			# increment counter
	lbzu 	6,1(14)			# get string[r5]
	cmpi	0,6,0			# is it zero?
	bne	str_loop		# if not keep counting
	
	cmpwi	5,80			# see if we are >80
        bgt	done_center		# if so, bail

	li	13,80			# 80 column screen
	subf	13,5,13			# subtract strlen
	srawi	13,13,1			# divide by tw
	addi	4,DATA_BEGIN,(space-data_begin)
					# load pointer to space		

	mtctr   13	   		# load into count register

center_loop: 
	li	0,SYSCALL_WRITE		# write char
	li	3,STDOUT		# stdout
	li	5,1			# write 1 char
	sc				# print it
	bdnz	center_loop
done_center:	
	blr


#===========================================================================
.data
#===========================================================================


data_begin:

.include "logo.lzss"

ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
megahertz:	.ascii	"MHz PPC \0"
.equ space, ram_comma+6
.equ comma, ram_comma+5
ram_comma:	.ascii	"M RAM, \0"

bogo_total:	.ascii	" Bogomips Total\0"

default_colors:	.ascii	"\033[0m\n\n\0"

cpuinfo:	.ascii	"/proc/cpuinfo\0"
kcore:		.ascii	"/proc/kcore\0"


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




