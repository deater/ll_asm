#
#  linux_logo in RiSC assembler
#
#  by Vince Weaver <vince@deater.net>

# takes 118685 cycles on simple-simulator

# FIXME: + only uses "write" syscall.  Should add uname,open,close,etc...
#        + uses "nand 0,0,0" as syscall.  Should probably use 
#               some sort of jalr nop in order not to confuse fancy
#               out-of-order simulators


	#=========================
	# PRINT LOGO
	#=========================

	movi	5,OUTPUT	  	# point to output buffer
	movi 	6,LOGO			# point input to new_logo
	movi 	7,STACK		        # point to 1k stack


logo_l:	lw   4,6,0			# load character
	addi 6,6,1			# increment pointer
	
	beq  0,4,done_l			# if zero, we are done

	movi 1,27			# if ^[, we are a color
	beq  4,1,color
	beq  0,0,blit
color:  sw   1,5,0     			# store ^[
	movi 1,91			# [
	sw   1,5,1			# store [
	addi 5,5,2

	lw   2,6,0			# counter, for num to output
	addi 6,6,1			# increment pointer
	
out_e:	lw   3,6,0			# load value
	addi 6,6,1			# increment pointer

	sw   	2,7,0			# push r2,r5,r6 onto stack
	sw   	5,7,1
	sw   	6,7,2
	addi 	7,7,3
	
	movi 	5,num_to_a		
	movi 	4,BUFFER		# point to buffer
	jalr	6,5	

	addi   	7,7,-3			# pop r6,r5,r2 off stack
	lw   	6,7,2
	lw   	5,7,1
	lw   	2,7,0
	
	movi	4,BUFFER
	lw	1,4,0			# load hundreds
	beq	1,0,tens
	sw	1,5,0			# store it
	addi	5,5,1
tens:	lw	1,4,1			# load tens
	beq	1,0,ones
	sw	1,5,0			# store it
	addi	5,5,1
ones:	lw	1,4,2			# load ones
	sw	1,5,0			# store it
	addi	5,5,1
	
	addi	1,0,59			# load semi-colon
	sw	1,5,0			# store semi-colon
	addi	5,5,1			# increment pointer
	
	addi	2,2,-1			# decrement counter
	beq	2,0,done_e		#if done, finish
	beq	0,0,out_e		# else, loop
	
done_e:	addi 	5,5,-1			# erase extra semi-colon
	lw	2,6,0  			# load closing char
	addi	6,6,1
	sw	2,5,0			# store to buffer
	addi	5,5,1
	
	beq 	0,0,logo_l		# done with color

blit: 	lw 	2,6,0			# get times to repeat
	addi	6,6,1
	
blit_r:	sw	4,5,0			# store character
	addi	5,5,1
	addi	2,2,-1			# decrement counter
	
	beq	2,0,done_r		# if zero we are done
	beq	0,0,blit_r
	
done_r:	beq	0,0,logo_l

done_l:	addi	1,0,4		  # syscall4 = write
	addi	2,0,1		  # stdout
	movi	3,OUTPUT	  # pointer
	movi	4,strlen	  # get length
	jalr	5,4
	nand	0,0,0		  # syscall

#
#  REAL versions of "ll" do other syscalls to uname and read() of
#  /proc/cpuinfo.  Could add those to the simulator.. maybe later
 

	#================================
	# Exit
	#================================
	
	halt


	#==============================
	# num_to_a (number to ascii)
	#==============================
	# r3=input
	# r4=buffpointer

num_to_a: sw 	6,7,0		# push return value
	addi    7,7,1		# increment stack

	sw	0,4,0		# zero out string
	sw	0,4,1
	sw   	0,4,2
	sw	0,4,3		# end of string
	
	movi	5,d_by_10
	jalr	6,5
	
	addi	2,2,0x30	# convert to ascii
	sw	2,4,2		# ones digit
	beq	1,0,done_num	# if zero, done
	
	add	3,0,1		# move result to input
	jalr	6,5		# divide
	
	addi	2,2,0x30	# convert to ascii
	sw	2,4,1		# tens digit
	beq	1,0,done_num	# if zero, done
	
	addi	1,1,0x30	# convert to ascii
	sw	2,4,0		# hundreds digit
	
done_num: addi	7,7,-1		# decrement stack
	 lw    	6,7,0		# pop return from stack
	 jalr  	0,6		# return

 	#==============================
	# d_by_10
	#==============================
	# r3 = input
	# r1 = result
	# r2 = remainder
	# r6 = return value
	
d_by_10: beq   3,0,cheat
	 beq   0,0,cont
	 
cheat:	 add   1,0,0   		# dividing 0
	 add   2,0,0
	 jalr  0,6	 


cont: 	 sw    6,7,0  	   	# push return on stack
	 sw    5,7,1		# push r5 on stack
	 sw    4,7,2		# push r4 on stack
	 addi  7,7,3
	 
	 addi  1,0,0		# clear r1
rep_d:	 movi  5,m_by_10
	 jalr  6,5
	 	 
	 nand   4,3,3		# subtract result from original
	 addi	4,4,1
	 
	 add	4,2,4

	 beq	4,0,exact	# if equals zero, no remainder
	 
	 movi	5,0x8000
	 
	 nand	5,4,5	        # is positive?
	 nand	5,5,5
	 beq   	5,0,done_d
	 addi  	1,1,1
	 beq   	0,0,rep_d
done_d:	 addi  	1,1,-1		# we went too far, back off

exact:	 movi  	5,m_by_10      	# calculate remainder
	 jalr  	6,5
	 
	 nand  	2,2,2		# negate result
	 addi  	2,2,1
	 
	 add   	2,3,2		# subtract

	 addi  	7,7,-3		# decrement stack
	 lw    	4,7,2		# pop r4 off stack
	 lw    	5,7,1		# pop r5 off stack
	 lw    	6,7,0		# pop return from stack
	 jalr  	0,6		# return


 	#==============================
	# m_by_10
	#==============================
	# r1 = input
	# r2 = result
	# r6 = return value
  
m_by_10: sw     4,7,0  		# push on stack
	add	4,1,1		# shift left once
	add	2,4,4		# shift left twice
	add	2,2,2
	add	2,2,4		# add (same as multiplying by 1010b)
	lw	4,7,0		# pop off stack
	jalr	0,6		# return

	#===============================
	# strlen
	#===============================
	# r3 points to string
	# r4 is returned with length
	# r5 is return address
	# r6,r7 trashed
	
strlen: add	7,3,0			# point to string
	add	4,0,0			# clear count
str_l:  addi	7,7,1
	addi	4,4,1
	lw	6,7,0
	beq	6,0,str_d
	beq	0,0,str_l
str_d:	jalr	0,5	 		# return
	


#============================================================================
#	section .bss
#============================================================================

OUTPUT: .space	4096
STACK:	.space	1024
BUFFER:	.space	4

#===========================================================================
#	section .data
#===========================================================================

# for "HELLO WORLD" purposes
HELLO:	    .fill     72
	    .fill     69
	    .fill     76
	    .fill     76
	    .fill     79
	    .fill     10
	    .fill     0	    
	    
# generated from main "ll" logo.inc via sed,tr, and hand tweaking
# this is ASCII with ANSI-color-escape sequences
# run-length-encoded for space-savings (and code complexity)

LOGO:	    .fill	27
.fill	 4
.fill	 0
.fill	 1
.fill	 37
.fill	 47
.fill	  109
	.fill	35
.fill	 65
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 9
	.fill	27
.fill	 3
.fill	 1
.fill	 37
.fill	 40
.fill	  109
	.fill	10
.fill	 1
	.fill	27
.fill	 4
.fill	 0
.fill	 1
.fill	 37
.fill	 47
.fill	  109
	.fill	35
.fill	 64
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 7
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 8
	.fill	27
.fill	 3
.fill	 1
.fill	 37
.fill	 40
.fill	  109
	.fill	10
.fill	 1
	.fill	27
.fill	 4
.fill	 0
.fill	 1
.fill	 37
.fill	 47
.fill	  109
	.fill	35
.fill	 19
	.fill	27
.fill	 1
.fill	 31
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 44
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	79
.fill	 1
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	79
.fill	 1
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 8
	.fill	27
.fill	 3
.fill	 1
.fill	 37
.fill	 40
.fill	  109
	.fill	10
.fill	 1
	.fill	27
.fill	 4
.fill	 0
.fill	 1
.fill	 37
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 6
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 10
	.fill	27
.fill	 1
.fill	 31
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 43
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 33
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 8
	.fill	27
.fill	 3
.fill	 1
.fill	 37
.fill	 40
.fill	  109
	.fill	10
.fill	 1
	.fill	27
.fill	 4
.fill	 0
.fill	 1
.fill	 37
.fill	 47
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 13
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 42
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 1
.fill	 33
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 6
	.fill	27
.fill	 3
.fill	 1
.fill	 37
.fill	 40
.fill	  109
	.fill	10
.fill	 1
	.fill	27
.fill	 4
.fill	 0
.fill	 1
.fill	 37
.fill	 47
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 9
	.fill	27
.fill	 1
.fill	 31
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 6
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 10
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 3
.fill	 1
.fill	 37
.fill	 40
.fill	  109
	.fill	10
.fill	 1
	.fill	27
.fill	 4
.fill	 0
.fill	 1
.fill	 37
.fill	 47
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 8
	.fill	27
.fill	 1
.fill	 31
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 1
.fill	 31
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 7
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 12
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 3
.fill	 1
.fill	 37
.fill	 40
.fill	  109
	.fill	10
.fill	 1
	.fill	27
.fill	 4
.fill	 0
.fill	 1
.fill	 37
.fill	 47
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 7
	.fill	27
.fill	 1
.fill	 31
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 1
.fill	 31
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 6
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 9
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 12
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 3
.fill	 1
.fill	 37
.fill	 40
.fill	  109
	.fill	10
.fill	 1
	.fill	27
.fill	 4
.fill	 0
.fill	 1
.fill	 37
.fill	 47
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 10
	.fill	27
.fill	 1
.fill	 31
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 6
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 8
	.fill	27
.fill	 1
.fill	 33
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 11
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 33
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 3
.fill	 1
.fill	 37
.fill	 40
.fill	  109
	.fill	10
.fill	 1
	.fill	27
.fill	 4
.fill	 0
.fill	 1
.fill	 37
.fill	 47
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 7
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 1
.fill	 31
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 1
.fill	 33
.fill	  109
	.fill	35
.fill	 6
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 7
	.fill	27
.fill	 1
.fill	 30
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 1
.fill	 33
.fill	  109
	.fill	35
.fill	 6
	.fill	27
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 3
.fill	 1
.fill	 37
.fill	 40
.fill	  109
	.fill	10
.fill	 1
	.fill	27
.fill	 4
.fill	 0
.fill	 1
.fill	 37
.fill	 47
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 6
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 1
.fill	 31
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 1
.fill	 33
.fill	  109
	.fill	35
.fill	 7
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 2
.fill	 1
.fill	 33
.fill	  109
	.fill	35
.fill	 7
	.fill	27
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 3
.fill	 1
.fill	 37
.fill	 40
.fill	  109
	.fill	10
.fill	 1
	.fill	27
.fill	 4
.fill	 0
.fill	 1
.fill	 37
.fill	 47
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 12
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 2
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 4
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 6
	.fill	27
.fill	 2
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 1
.fill	 33
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 1
.fill	 30
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 3
.fill	 0
.fill	 30
.fill	 47
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 1
.fill	 1
.fill	  109
	.fill	35
.fill	 1
	.fill	27
.fill	 1
.fill	 33
.fill	  109
	.fill	35
.fill	 5
	.fill	27
.fill	 1
.fill	 37
.fill	  109
	.fill	35
.fill	 3
	.fill	27
.fill	 3
.fill	 1
.fill	 37
.fill	 40
.fill	  109
	.fill	10
.fill	 1
	.fill	0
.fill	0
