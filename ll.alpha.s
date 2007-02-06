#
#  linux_logo in alpha assembler    0.6
#
#  by Vince Weaver <vince _at_ deater.net>
#
#  assemble with     "as -o ll.o ll.alpha.s"
#  link with         "ld -o ll ll.o"

#  BUGS:  No Pretty Printing (rounding, cpu-model cleanup)
#      :  Doesn't print vendor name


# offsets into the results returned by the uname syscall
.equ U_SYSNAME,0
.equ U_NODENAME,65
.equ U_RELEASE,65*2
.equ U_VERSION,(65*3)
.equ U_MACHINE,(65*4)
.equ U_DOMAINNAME,65*5

# offset into the results returned by the stat syscall
.equ S_SIZE,32

# syscall numbers

.equ SYSCALL_EXIT,1	
.equ SYSCALL_READ,3
.equ SYSCALL_WRITE,4
.equ SYSCALL_CLOSE,6
.equ SYSCALL_OPEN,45
.equ SYSCALL_STAT,67
.equ SYSCALL_UNAME,339

	.globl _start
_start:
	br      $27,0           # fake branch, to grab the location
	                        # of our entry point
	ldgp    $gp,0($27)      # load the GP proper for our entry point
				# this does automagic stuff
		
        #=========================
	# PRINT LOGO
	#=========================
	
	lda	$9,new_logo	  	# point input to new_logo
	lda	$10,out_buffer		# point output to buffer
	mov	$10,$11			# save pointer to begin of output
	mov	';',$14			# semicolon, used later

main_logo_loop:
	ldb	$1,0($9)		# load character
	addq	$9,1,$9			# update pointer
	beq	$1,done_logo		# if zero, we are done
	
	cmpeq	$1,27,$4		# if ^[, we are a color
        beq	$4,blit_repeat          # if not go to the RLE blit

	mov	27,$5			# output ^[[ to buffer
	stb	$5,0($10)
	mov	'[',$5
	stb	$5,1($10)
	addq	$10,2,$10

	ldb	$3,0($9)		# load number of ; separated elements 
	addq	$9,1,$9			# update pointer
		
element_loop:
        ldb	$2,0($9)		# load color
	addq	$9,1,$9			# update pointer

	mov	$2,$16			# convert byte to ascii decimal
	br	$26,num_to_ascii
			
	stb	$14,0($10)		# load ';'
	addq	$10,1,$10		# and output it
	
	subq	$3,1,$3			# decrement counter
	bne	$3,element_loop		# loop if elements left

	subq	$10,1,$10		# remove extra ';'
	
	ldb	$5,0($9)		# load last char
	addq	$9,1,$9

	stb	$5,0($10)		# save last char
	addq	$10,1,$10
	
	jmp 	main_logo_loop		# done with color

blit_repeat:
	ldb	$3,0($9)		# get times to repeat
	addq	$9,1,$9			# increment pointer
blit_loop:	
	stb	$1,0($10)		# write character
	addq	$10,1,$10
	subq	$3,1,$3 		# decrement counter
	bne	$3,blit_loop		# if not zero, loop
	
	jmp	main_logo_loop

done_logo:	
	ldi	$0,SYSCALL_WRITE	# number of the "write" syscall
	ldi	$16,1			# stdout
	mov	$11,$17			# output_buffer pointer
	mov	10,$18
	jsr	$26,strlen		# get length of string
	callsys	           		# do syscall

	lda	$17,line_feed		# print line feed
	br	$26,put_char
	
	#==========================
	# PRINT VERSION
	#==========================

	ldi	$0,SYSCALL_UNAME   	# uname syscall
	lda	$16,uname_info		# uname struct
	callsys				# do syscall
	
	mov	$11,$10			# restore output to out_buffer

	lda	$1,uname_info
		
	lda	$16,U_SYSNAME($1)	# os-name from uname "Linux"
	br	$26,strcat

	lda	$16,ver_string		# source is " Version "
	br	$26,strcat
	
	lda	$16,U_RELEASE($1)    	# version from uname "2.4.1"
	br	$26,strcat
	
	lda	$16,compiled_string	# source is ", Compiled "
	br	$26,strcat

	lda	$16,U_VERSION($1)	# compiled date
	br	$26,strcat
	
	mov	$11,$17  		# restore saved location of out_buff
	
	br	$26,strlen		# returns size in $18
	
	br	$26,center		# print some spaces
	
	ldi	$0,SYSCALL_WRITE	# write out the buffer
	ldi	$16,1
	mov	$11,$17
	br	$26,strlen
	callsys
	
	lda	$17,line_feed		# print line feed
	br	$26,put_char		
	
	#===============================
	# Middle-Line
	#===============================

	mov	$11,$10			# restore output pointer
		
	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	ldi	$0,SYSCALL_OPEN		# open()
	lda	$16,cpuinfo		# '/proc/cpuinfo'
	ldi	$17,0			# O_RDONLY <bits/fcntl.h>
	callsys				# syscall.  fd in $0.  
					# we should check that $0>=0

	mov	$0,$5			# save fd in $5
	
	ldi	$0,SYSCALL_READ		# read
	mov	$5,$16			# copy fd
	lda	$17,disk_buffer
	ldi	$18,4096	 	# 4096 is upper-limit guess of procfile
	callsys

	mov	$5,$16			# restore fd
	ldi	$0,SYSCALL_CLOSE	# close
	callsys

	#=============
	# Number of CPU's
	#=============

	ldi	$17,'t'			# find 'cycl' and grab after ':'
	ldi	$18,'e'
	ldi	$19,'d'
	ldi	$20,':'
	mov	$10,$14			# save output
	lda	$10,string_buffer	# load temp pointer
   	br	$26,find_string
	mov	$14,$10			# restore output

	lda	$16,string_buffer	# convert ascii to decimal
	br	$26,ascii_to_num	

	# Assume <=4 CPU's
	# have to learn how to do arrays on Alpha?

	cmpeq	$17,4,$5
	beq	$5,check_three
	lda	$16,four
	jmp	print_num_cpu
check_three:		
	cmpeq	$17,3,$5
	beq	$5,check_two
	lda	$16,three
	jmp	print_num_cpu
check_two:
	cmpeq	$17,2,$5
	beq	$5,check_one
	lda	$16,two
	jmp	print_num_cpu
check_one:	
	lda  	$16,one
print_num_cpu:		
	br	$26,strcat

	#=========
	# MHz
	#=========
	
	ldi	$17,'c'			# find 'cycl' and grab after ':'
	ldi	$18,'y'
	ldi	$19,'c'
	ldi	$20,':'
	mov	$10,$14			# save output
	lda	$10,string_buffer	# load temp pointer
   	br	$26,find_string
	mov	$14,$10			# restore output

	lda	$16,string_buffer	# convert string to a long
	br	$26,ascii_to_num

	mov	$17,$16			# divide by 1 million
	ldi	$17,1000000
	br	$26,divide
	
	mov	$18,$16			# convert back to ascii-decimal
	br	$26,num_to_ascii
	
	lda	$16,megahertz		# print 'MHz '
	br	$26,strcat
   
   
   	#=========
	# Chip Name
	#=========
	
   	ldi     $17,'o'     	# find 'ode ' and grab  after :
	ldi	$18,'d'
	ldi	$19,'e'
	ldi	$20,':'
	br	$26,find_string
	
	lda	$16,comma	# print ', '
	br	$26,strcat
	
	#========
	# RAM
	#========
	
	ldi	$0,SYSCALL_STAT	       	# stat() syscall
	lda	$16,kcore		# /proc/kcore
	lda	$17,stat_buff
	callsys

	lda	$17,stat_buff
	ldq	$5,S_SIZE($17)	

	sra	$5,10			# divide to get K
	sra	$5,10			# divide to get M

	mov	$5,$16			# convert to ascii
	br	$26,num_to_ascii
		
	lda	$16,ram_comma		# print 'M RAM, '
	br	$26,strcat
	
	#========
	# Bogomips
	#========
	
	ldi	$17,'I'      		# find 'IPS' and grab up to \n
	ldi	$18,'P'
	ldi	$19,'S'
	ldi	$20,':'
	br	$26,find_string

	lda	$16,bogo_total
	br	$26,strcat


	mov	$11,$17  		# restore saved location of out_buff
	
	br	$26,strlen		# returns size in $18
	
	br	$26,center		# print some spaces
	
	ldi	$0,SYSCALL_WRITE	# write the buffer out
	ldi	$16,1
	mov	$11,$17
	br	$26,strlen
	callsys
	
	lda	$17,line_feed		# print line feed
	br	$26,put_char       		
	
	#=================================
	# Print Host Name
	#=================================

	lda	$17,U_NODENAME($1)	# print node name

	br	$26,strlen		# center
	br	$26,center
	
	ldi	$0,SYSCALL_WRITE	# write it out
	ldi	$16,1
	lda	$17,U_NODENAME($1)
	br	$26,strlen
	callsys

	ldi	$0,SYSCALL_WRITE	# restore default colors
	ldi	$16,1
	lda	$17,default_colors
	br	$26,strlen
	callsys
		
	lda	$17,line_feed		# print line feed
	br	$26,put_char
	br	$26,put_char

	#================================
	# Exit
	#================================
	
        mov	0,$16			# 0 exit value
        mov	SYSCALL_EXIT,$0         # put the exit syscall number in v0
        callsys				# and exit


	#=================================
	# Divide
	# yes this is an awful algorithm, but simple
	# and uses few registers
	#=================================
	#  $16 =numerator $17=denominator
	#  $18 =quotient  $19=remainder
	#  $20,$21=scratch
divide:
	mov	$31,$18			# zero out result
divide_loop:	
	mulq	$18,$17,$20		# multiply temp by denominator
	addq	$18,1,$18
	cmple	$20,$16,$21		# is it greater than numerator?

	bne	$21,divide_loop		# if not, increment temp
	subq	$18,2,$18		# otherwise went too far, decrement
					# and done
	
	mulq	$18,$17,$20		# calculate remainder
	subq	$16,$20,$19		# R=N-(Q*D)

	ret $26	
	

	#=================================
	# FIND_STRING 
	#=================================
	#   $20 is char to end at
	#   $17,$18,$19 are 3-char ascii string to look for
	#   $10 points at output buffer
	#   $5,$6,$7=temp
find_string:
					
	lda	$5,disk_buffer		# look in cpuinfo buffer
	
find_loop:
	ldb	$6,0($5)		# watch for first char
	addq	$5,1,$5
	beq	$6,done
	cmpeq	$17,$6,$7
	beq	$7,find_loop

	ldb	$6,0($5)		# watch for second char
	addq	$5,1,$5
	cmpeq	$18,$6,$7
	beq	$7,find_loop
	
	ldb	$6,0($5)		# watch for third char
	addq	$5,1,$5
	cmpeq	$19,$6,$7
	beq	$7,find_loop
	
					# if we get this far, we matched
find_colon:
	ldb	$6,0($5)		# repeat till we find colon
	addq	$5,1,$5
	beq	$6,done
	cmpeq	$20,$6,$7
	beq	$7,find_colon

	addq	$5,1,$5			# skip a char [should be space]
	
store_loop:	 
	ldb	$6,0($5)
	addq	$5,1,$5
	beq	$6,done
    	cmpeq	$6,'\n',$7		# is it end string?
	bne 	$7,almost_done		# if so, finish
	cmpeq	$6,' ',$7		# cpuinfo has trailing spaces?
	bne	$7,almost_done		# watch for them too
	stb	$6,0($10)		# if not store and continue
	addq	$10,1,$10
	jmp	store_loop
	 
almost_done:	 
	ldi	$7,0			# replace last value with null
	stb	$7,0($10)

done:
	ret	$26

	#================================
	# put_char
	#================================
	# output value at $17

put_char:
	ldi	$0,SYSCALL_WRITE	# number of the "write" syscall
	ldi	$16,1			# stdout
	mov	1,$18			# 1 byte to output
	callsys	           		# do syscall
	ret	$26
	

	#================================
	# strcat
	#================================
	# $5 = "temp"
	# $16 = "source"
	# $10 = "destination"
strcat:
	ldb	$5,0($16)		# load a byte from $16
	addq	$16,1,$16
	stb	$5,0($10)		# store a byte to $10
	addq	$10,1,$10
	bne	$5,strcat		# if not zero, loop
	
	subq	$10,1,$10		# back up pointer to the zero
	ret	$26
	
	#===============================
	# strlen
	#===============================
	# $17 points to string
	# $18 is returned with length

strlen:
	mov	$17,$3			# copy pointer
	mov	$31,$18			# set count to 0
str_loop:
	addq	$3,1,$3			# increment pointer
	addl	$18,1,$18		# increment counter
	ldb	$4,0($3)		# load byte
	bne	$4,str_loop		# is it zero? if not, loop
	ret	$26			# return
	
	#==============================
	# center
	#==============================
	# $18 has length of string
	# $5,$6=temp
	
center:
	mov	$26,$6			# save return address
	cmple	$18,80,$5		# see if we are >80
	beq	$5,done_center		# if so, bail

	ldi	$5,80			# 80 column screen
	subq	$5,$18,$5		# subtract strlen
	sra	$5,1			# divide by two
	lda	$17,space		# load pointer to space		
center_loop: 
	br 	$26,put_char		# and print that many spaces
	subq	$5,1,$5
	bne	$5,center_loop
done_center:	
	mov	$6,$26			# restore return address
	ret	$26


	#===========================
	# ascii_to_num
	#===========================
	# $16=string
	# $17=result
	# $5=temp
ascii_to_num:
	mov	$31,$17			# zero result
ascii_loop:		
	ldb	$5,0($16)		# load value
	addq	$16,1,$16
	beq	$5,ascii_done
	mulq	$17,10,$17		# shift decimal left
	subq	$5,0x30,$5		# convert ascii->decimal
	addq	$17,$5,$17		# add it in
	jmp	ascii_loop
ascii_done:			
	ret	$26
	
	#===========================
	# num_to_ascii
	#===========================
	# $16=num
	# $10=output
	# $6,$7,$8=temp
num_to_ascii:
	mov	$26,$6			# save return value

	lda	$7,string_buffer	#load buffer
	mov	$31,$8		
	addq	$7,63,$7		# start at end of string
	stb	$8,0($7)		# make sure trailing zero
	subq	$7,1,$7			# we work backwards

num_loop:		
	ldi	$17,10			# we divide by 10 always
	br	$26,divide

	addq	$18,$19,$8		# if remainder and quotient zero
	beq	$8,num_done		# then we are done shifting
	
	addq	$19,0x30,$19		# convert to ascii
	stb	$19,0($7)		# and store to buffer
	subq	$7,1,$7			# move to left
	mov	$18,$16
	jmp	num_loop
num_done:		
	addq	$7,1,$7			# done, but re-adjust pointer
num_loop2:		
	ldb	$8,0($7)		# write out the buffer
	addq	$7,1,$7
	beq	$8,num_all_done
	stb	$8,0($10)
	addq	$10,1,$10
	jmp	num_loop2
	
num_all_done:		
	mov	$6,$26			# restore return value
	ret	$26	
		
#===========================================================================
#.data
#===========================================================================

.include "logo.inc"

line_feed:	.ascii  "\n"
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
space:		.ascii	" \0"
megahertz:	.ascii	"MHz Alpha \0"
comma:		.ascii	", \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"

default_colors:	.ascii	"\033[0m\0"

cpuinfo:	.ascii	"/proc/cpuinfo\0"
kcore:		.ascii	"/proc/kcore\0"


one:	.ascii	"One \0"
two:	.ascii	"Two \0"
three:	.ascii  "Three \0"
four:	.ascii	"Four \0"
	

#============================================================================
#.bss
#============================================================================
	
.lcomm out_char,1
	
.lcomm stat_buff,(4*32)
	# urgh get above from /usr/src/linux/include/asm/stat.h
	# not glibc

.lcomm uname_info,(65*6)

.lcomm	string_buffer,64
	
.lcomm	disk_buffer,4096	# we cheat!!!!
.lcomm	out_buffer,16384	# we cheat, 16k output buffer





