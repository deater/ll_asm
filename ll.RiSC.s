#
#  linux_logo in RiSC assembler 0.41
#
#  by Vince Weaver <vince _at_ deater.net>

# takes 872528 cycles on "nestle" running in-order RiSC-sim
#   cycle count will vary machine to machine as string lengths
#   for the system info aren't always going to be the same

#
# Dedicated to baby Sam Clemens, born while this was being worked on
# 

# RiSC is described fully here: http://www.ece.umd.edu/~blj/RiSC/

# Features
# + 16-bit architecture
# + 3-operand instructions
# + 7 general purpose int registers
# + signed 7-bit immediate
# + zero register
# + big-endian (though no byte instructions so you can't tell)
# + no unaligned loads

# ABI
# + r0 is always zero
# + r7 often used as stack pointer or zero-page pointer
# + r6 is jump-and-link register
# + Syscalls - "sys 0".  Number in r1, args in r2,r3,r4, etc.

# Instructions
# + add  rd,r1,r2	- rd = r1+r2	
# + addi rd,r1,IMM	- rd = r1+IMM (signed 7-bit immediate)
# + nand rd,r1,r2	- rd = ~(r1&r2)
# + lui  rd,IMM         - rd = upper 10 bits of immediate
# + sw   rd,r1,IMM	- rd is written to address formed by r1+IMM
# + lw   rd,r1,IMM	- rd is loaded with memory found at r1+IMM
# + beq	 rd,r1,IMM	- if r1==0 then add IMM to PC
# + jalr rd,r1		- rd=current pc, jump to addr in r1
# + halt 		- halt execution
# + sys  IMM		- system call (4-bit IMMEDIATE)
# + exc  IMM		- exception   (4-bit IMMEDIATE)
#
# Pseudo-ops
# + movi rd,IMM		- move immediate, expands to lui/addi 
# + nop  		- is an add 0,0,0
# + lli  rd,6bitImm 	- ?  expands to addi rd,rd,6bitIMM
#
# Directives
# + .space SIZE         - alocate SIZE 16-bit zeros
# + .fill  VAL          - place directly one 16-bit value VAL


# Syscalls
.equ SYSCALL_EXIT,     1
.equ SYSCALL_READ,     3
.equ SYSCALL_WRITE,    4
.equ SYSCALL_OPEN,     5
.equ SYSCALL_CLOSE,    6
.equ SYSCALL_SYSINFO,116
.equ SYSCALL_UNAME,  122

# File Descriptors
.equ STDIN,0
.equ STDOUT,1
.equ STDERR,2

# Optimizations
# + 1682 bytes - 2200536 cycles - Original fully working implementation
# + 1676 bytes - 2200524 cycles - pre-initialize pointers on the stack
# + 1650 bytes - 2183559 cycles - remove common movi's by stack addressing
# + 1626 bytes - 2170094 cycles - have read_byte return r3 instead of on stack
# + 1614 bytes - 2169767 cycles - add indirect jumps to avoid jalr
# + 1586 bytes - 2169577 cycles - more stack pointers, for first line of output
# + 1568 bytes - 2169751 cycles - stack pointers, for middle line of input
# + 1558 bytes - 2169746 cycles - stack pointers, last line of input
# + 1556 bytes - 2169746 cycles - optimize read_byte
# + 1524 bytes - 2139850 cycles - optimize shift_left
# + 1526 bytes -  978223 cycles - fix missing return at end of write_byte
# + 1482 bytes -  877829 cycles - optimize shift_right
# + 1480 bytes -  877706 cycles - optimize strcat
# + 1462 bytes -  877559 cycles - optimize center_and_print
# + 1456 bytes -  873014 cycles - optimize strlen
# + 1452 bytes -  873002 cycles - optimize num_to_ascii
# + 1430 bytes -  872568 cycles - optimize find_string
# + 1424 bytes -  872551 cycles - misc stack pointers
# + 1418 bytes -  872528 cycles - mask cleanup in write_byte

######################
# Initial stack layout
######################
# -15  num_to_ascii
# -14  ascii_buffer
# -13  disk_buffer
# -12  strlen
# -11  find_string
# -10  center_and_print
#  -9  uname_info
#  -8  strcat
#  -7  write_stdout
#  -6  out_buffer
#  -5  shift_left_8
#  -4  shift_right
#  -3  text_buf
#  -2  write_byte
#  -1  read_byte
#   0  logo
#  +1  out_buffer (to be modified)
#  +2  text_ptr
#  +3  logo_byte
#  ----------------- Below this is in BSS, initialized to zero
#  +4  out_byte
#  +5  text_byte
#  +6  command
#  +7  mask
#  +8  position
#  +9  count

.include "logo.include"

_start:

	#=========================
	# PRINT LOGO
	#=========================


   	movi 	7,stack   	    # point r7 to the stack

				    # logo_ptr is already loaded at stack+0
				    # logo_byte is already 0 at stack+3
				    # output_ptr is already at stack+1
   	  		    	    # output_byte is already 0 at stack+4
				    # r_ptr is already N-F at stack+2
		    		    # r_byte is alrady 0 at stack+5
   
decompression_loop:
   
	lw      5,7,0      	    # logo_ptr
   	lw   	4,7,3      	    # logo_byte
	
	lw	1,7,-1		    # load read_byte
 	jalr 	6,1		    # read byte
				    # result in r3
	
	sw   	3,7,6      	    # store command byte

	sw   	5,7,0      	    # store logo_ptr
   	sw   	4,7,3      	    # store logo_byte

   	addi 	1,0,1      	    # reset mask to "1" 
   	sw     	1,7,7		    # store mask
   
test_flags:
   
	lw      1,7,0               # load logo_ptr
   	movi 	2,logo_end 	    # compare with end
	addi	2,2,-1		    # cheat!  we have an odd number of bytes
				    # so hard on this arch to detect properly
        beq 	1,2,done_logo_jump

not_done:
   	lw 	1,7,6          	    # load back command word
   	lw 	2,7,7        	    # load in mask
   	nand 	1,1,2      	    # mask
   	nand 	1,1,1
   	add  	2,2,2      	    # shift mask left
   	sw   	2,7,7      	    # store out mask 
   
	beq  	1,0,offset_length   # if low bit was not set, offset_length

discrete_char:

   	lw      5,7,0   	    # load in logo_ptr
  	lw 	4,7,3   	    # load in logo_byte
	
   	lw 	1,7,-1		    # load read_byte target
  	jalr 	6,1		    # read byte
				    # result is in r3
		
   	sw 	5,7,0   	    # store logo_ptr
   	sw 	4,7,3   	    # store logo_byte
	
   	addi 	1,0,1 		    # count is 1 (write one byte)
   	sw   	1,7,9 		    # store count
  	beq 	0,0,store_byte

offset_length:
	lw     	5,7,0      	    # load logo_ptr
   	lw   	4,7,3      	    # load logo_byte
	
   	lw 	1,7,-1		    # load read_byte target
   	jalr 	6,1		    # read byte   
	add   	2,0,3     	    # get result in r2

	jalr 	6,1   		    # call read_byte again   
				    # result is in r3
	
   	sw   	5,7,0      	    # update logo_ptr
   	sw   	4,7,3      	    # update logo_byte

				    # we want to shift r3
   	lw 	1,7,-5		    # load shift_left_8 target
   	jalr 	6,1		    # shift_left_8

   	add  	2,3,2      	    # merge into 16-bit value
   	sw   	2,7,8      	    # store as position

				    # value to shift in r2
   	lui  	3,0x400    	    # amount to shift (P_BITS)
	lw	1,7,-4	     	    # shift_right target
   	jalr 	6,1		    # shift right
				    # result in r1

	addi 	1,1,3      	    # add in THRESHOLD+1
   	sw   	1,7,9     	    # store as count

	beq	0,0,output_loop

	# Jump tables to handle jumps > 64 instructions
	# w/o these we'd need to jalr

done_logo_jump:
	beq     0,0,done_logo
test_flags_jump:
	beq	0,0,test_flags
decompression_jump:
	beq	0,0,decompression_loop

output_loop:
   	movi 	1,0x3ff    	    # mask 
   	lw   	2,7,8      	    # load in position
   	nand 	2,1,2
   	nand 	2,2,2
   	sw   	2,7,8      	    # store back masked pos
   
   				    # value to shift in r2
   	addi 	3,0,2      	    # shift right by 1 (divide by 2)
   	lw 	1,7,-4	   	    # load shift_right target
   	jalr 	6,1		    # shift right
				    # result in r1
	
   	lw 	5,7,-3		    # point to text_buf
   	add  	5,5,1      	    # add in position
   
   	lw	2,7,8
   
   	addi 	1,0,1      	    # mask for byte hi/lo
   	nand 	4,2,1
   	nand 	4,4,4   
   
       	lw 	1,7,-1		    # load target for read_byte
   	jalr 	6,1		    # read byte      
				    # result is in r3
   
   	addi 	2,2,1    	    # increment position
   	sw   	2,7,8     	    # store out to mem
   
store_byte:

   	lw   	5,7,1     	    # load output_ptr
   	lw   	4,7,4     	    # load output_byte
   	lw 	1,7,-2		    # load target for write_byte
   	jalr 	6,1		    # write byte
   
   	sw   	4,7,4     	    # save output_byte
   	sw   	5,7,1     	    # save output_ptr
   
   	lw 	2,7,-3		    # load text_buffer
   	lw   	5,7,2     	    # load r_ptr
   	add  	5,2,5     	    # text+r_ptr
   	lw   	4,7,5     	    # load r_byte
	
   	lw 	1,7,-2		    # load target for write_byte
   	jalr 	6,1		    # wrte byte

   	sw   	4,7,5    	    # store r_byte
   	nand 	1,2,2    	    # flip bits in TEXT
   	addi 	1,1,1    	    # add one (2s complement)
   	add  	1,5,1    	    # we effectively subtracted
   
  	movi 	2,511    	    # mask with (1024>>2)-1
   	nand 	1,1,2
   	nand 	1,1,1
	
   	sw   	1,7,2    	    # store back r_ptr

   	lw   	1,7,9   	    # load in count
   	addi 	1,1,-1   	    # decrement
  	sw   	1,7,9   	    # save back count
   
   	beq  	1,0,done_count
      
   	beq  	0,0,output_loop
      
done_count:  
   
   	lw   	1,7,7               # load in mask
   	lui 	2,0x100     	    # see if we are done
	
 	beq 	1,2,decompression_jump
 	beq 	0,0,test_flags_jump
	
done_logo:
	  			   # because the logo is an odd number of
				   # bytes, we cheat and put the ending
				   # linefeed and null termination here
				   
   	lw   	5,7,1		   # output_ptr
   	lw   	4,7,4		   # output_byte
	addi	3,0,10		   # store a linefeed
	lw	2,7,-2		   # load write_byte target	   
	jalr	6,2		   # write byte

	lw	3,7,-6		   # out_buffer
	lw	4,7,-7		   # write_stdout target
	jalr	6,4		   # write stdout


first_line:

	# set up pointers
	
	lw      5,7,-6	    	    # set 5/4 to out_buffer/byte
	add	4,0,0
	
        #==========================
	# PRINT VERSION
	#==========================
	
	# call uname
	
	movi	1,SYSCALL_UNAME     # put uname sysall in r1
	lw	2,7,-9	    	    # point to uname info
	sys	0		    # syscall

	# print OS

	add	3,2,0		    # point to first entry of uname_info
	add	2,0,0		    # start at aligned byte
	lw	1,7,-8	    	    # load strcat target
	jalr	6,1		    # strcat

	# print Version string

	movi	3,ver_string        # store version string
	lw	1,7,-8	    	    # load strcat target
	jalr	6,1		    # strcat
	
	# print Version info

	lw	3,7,-9	    	    # point to first entry of uname_info
	addi	3,3,32		    # skip to 2nd entry
	lw	1,7,-8	    	    # load strcat target
	jalr	6,1		    # strcat
	
	# print Compiled string

	movi	3,compiled_string   # store version string
	lw	1,7,-8		    # load strcat target
	jalr	6,1		    # strcat
	
	# print Compiled info

	lw	3,7,-9	     	    # point to first entry of uname_info
	addi	3,3,48		    # skip to 3rd entry
	lw	1,7,-8	    	    # load strcat target
	jalr	6,1		    # strcat

	lw	1,7,-10		    # load center_and_print target
	jalr	6,1		    # center and print


        #===============================
	# Middle-Line
	#===============================
middle_line:
	
        #=========
	# Load /proc/cpuinfo into buffer
	#=========
			
	addi    1,0,SYSCALL_OPEN    # open() syscall
	movi	2,cpuinfo	    # "proc/cpu.RiSC"
	add	3,0,0		    # 0 = O_RDONLY <bits/fcntl.h>
	sys	0		    # syscall.  fd returned in r1
		                    # we should check that return >=0
	
	add	2,1,0		    # copy the fd to the right place
	
        addi	1,0,SYSCALL_READ    # read() syscall
	lw	3,7,-13		    # point r3 to the disk buffer
	lui	4,0x200		    # assume smaller than 512 bytes
	sys	0		    # syscall
	
	addi	1,0,SYSCALL_CLOSE   # close() the file
	sys	0		    # fd already in r2

	# restore pointer to output
	
	lw	5,7,-6	     	    # set 5/4 to out_buffer/byte
	add	4,0,0

	#=============
        # Number of CPUs
        #=============
number_of_cpus:
				
	# we cheat here and just assume 1.  

	movi	3,one       	    # store "One" string
	add	2,0,0
	lw	1,7,-8	    	    # load strcat target
	jalr	6,1		    # strcat

        #=========
	# MHz
        #=========
print_mhz:

	movi	2,0x6672	    # Find 'fr'
	lw	1,7,-11		    # load find_string target
	jalr	6,1		    # find_string

	movi	3,mhz       	    # store "MHz" string
	lw	1,7,-8		    # load strcat target
	jalr	6,1		    # strcat
				
        #=========
	# Chip Name
        #=========
chip_name:

	movi	2,0x7075	    # Find 'pu'
        lw	1,7,-11		    # load find_string target
	jalr	6,1		    # find_string

	movi	3,processor         # store "Processor " string	
	lw	1,7,-8		    # load strcat target
	jalr	6,1		    # strcat


        #========
	# RAM
	#========
ram:
    	
    	movi	1,SYSCALL_SYSINFO
	movi	2,sysinfo_buff
	sys	0
	
	lw	2,2,3		    # total ram is the 4th field

	lw	1,7,-15		    # point to num_to_ascii target
	jalr	6,1	      	    # num_to_ascii
	
	movi	3,ram_comma         # store "K RAM, " string
	add	2,0,0
	lw	1,7,-8		    # load strcat target
	jalr	6,1		    # strcat

        #=========
	# Bogomips
	#=========
bogomips:

	movi	2,0x426f	    # Find 'Bo'
        lw	1,7,-11		    # load find_string target
	jalr	6,1		    # find_string

	movi	3,bogo_total        # store "Bogomips Total" string
	lw	1,7,-8		    # load strcat target
	jalr	6,1		    # strcat

	lw	1,7,-10		    # load center_and_print target
	jalr	6,1		    # center_and_print

        #=================================
	# Print Host Name
        #=================================

last_line:
	# restore pointer to output
	
	lw    	5,7,-6	  	    # set 5/4 to out_buffer/byte
	add	4,0,0

        # host name from uname()
	
	lw      3,7,-9	 	    # load uname_info
	addi	3,3,16		    # point to 2nd entry
	add	2,0,0
	lw	1,7,-8		    # point to strcat target
	jalr	6,1		    # strcat
	
	lw	1,7,-10		    # point to center_and_print
	jalr	6,1		    # center_and_print
	
	movi	3,default_colors
	lw	1,7,-7		    # point to write_stdout target
	jalr	6,1		    # write_stdout


	#================================
	# Exit
	#================================
exit:	
        addi 	1,0,SYSCALL_EXIT	    # Put syscall in R1
	add	2,0,0		    	    # Exit with a 0
	sys 	0			    # syscall	
	halt				    # just in case


	#================================
	# Read Byte
	#================================
	# r5 points to byte to read
	# r4 stores odd/even info
	# r3 has result
read_byte:

        addi 	7,7,16		    # move stack
        sw  	6,7,6		    # back up return reg
        sw	2,7,2		    # back up r2
        sw	1,7,1		    # back up r1

	lui	3,0x100		    # load 0x100 for later use

        lw	2,5,0		    # load a word from r5
        beq	4,0,read_even
	
read_odd:	
        addi	3,3,-1   	    # r3=0xff, mask to get low byte
        nand	3,2,3
        nand	3,3,3
        add  	4,0,0   	    # make even
        addi 	5,5,1  		    # increment r5
        beq	0,0,done_read
		
read_even:
	  			    # shift right by 8
        movi 	1,shift_right	
        jalr 	6,1
		   		    # result in r1
        add   	3,0,1		    # move result to r3
        addi 	4,0,1 	    	    # make odd

done_read:
        lw 	6,7,6		    # restore link reg
        lw	2,7,2		    # restore r2
        lw	1,7,1		    # restore r1
        addi 	7,7,-16		    # restore stack
	jalr	0,6		    # return


	#================================
	# write_byte
	#================================
	# r5 points to byte to read
	# r4 stores odd/even info
	# r3 is value to store

write_byte:
   
        addi 	7,7,16		    # move stack
        sw  	6,7,6		    # back up return reg
        sw	3,7,3		    # back up r3
        sw	2,7,2		    # back up r2
        sw	1,7,1		    # back up r1
   
        lw      1,5,0		    # load existing halfword
        lui 	2,0xff00	    # mask base
        beq	4,0,write_even   

write_odd:
        nand 	1,1,2		    # mask to get high byte
        nand 	1,1,1
	
        add  	1,1,3		    # move in new low byte
        sw   	1,5,0   	    # store new half-word
	
        add  	4,0,0         	    # make even
   	addi 	5,5,1         	    # increment pointer
        beq	0,0,done_write

write_even:	
        nand 	2,2,2	    	    # create 0x00ff mask
   	nand 	2,1,2
   	nand 	2,2,2         	    # erase top half
	
				    # we want to shift r3
   	movi 	1,shift_left_8
   	jalr 	6,1	    	    # shift_left_8

   	add  	2,2,3         	    # put new value in
   	sw   	2,5,0   	    # store new half-word
	
   	addi 	4,0,1         	    # make odd
   
done_write:
   
        lw 	6,7,6		    # restore link reg
        lw	3,7,3		    # restore r3
        lw	2,7,2		    # restore r2
        lw	1,7,1		    # restore r1
        addi 	7,7,-16		    # restore stack
	jalr	0,6		    # return


	#================================
	# shift_right
	#================================
	# r2   = value to shift
	# r3   = amount to divide by
	#        (power of 2 only)
	# r1   = return value 
shift_right:

        addi 	7,7,16		    # move stack
        sw	5,7,5		    # back up r5
        sw	4,7,4		    # back up r4
        
        add	1,0,0		    # clear output
        addi	5,0,1		    # adder
	
shift_loop:
        nand	4,2,3		    # use mask on original value
        nand	4,4,4
	
        beq	4,0,no_add	    # if it's zero, no need to add
        add	1,1,5		    # otherwise, add in the adder value
	
no_add:
        add	3,3,3		    # shift left the mask
        add	5,5,5		    # shift left the adder
	
        beq	3,0,done_shift	    # if we've overflowed the mask, done
        beq	0,0,shift_loop

done_shift:
   
        lw	5,7,5		    # restore r5
        lw	4,7,4		    # restore r4
        addi 	7,7,-16		    # restore stack	
	jalr	0,6  		    # return         


	#================================
	# shift_left_8
	#================================
	# r3   = value to shift/result
	# r1 trashed
	
shift_left_8:
   
        addi	1,0,8 		    # always shift by 8	
left_loop:      
        add     3,3,3		    # shift left by 1
        addi    1,1,-1		    # decrement count
        beq     1,0,left_done
        beq 	0,0,left_loop
left_done:
	jalr	0,6


	#============================
	# strcat
	#============================
	# input  is  3/2
	# output is  5/4
	# r2 is cleared
	# r1 is trashed
	
strcat:
        addi 	7,7,16		    # move stack   
        sw	6,7,6		    # back up r6

strcat_loop:
	sw	5,7,5		    # back up r5
	sw	4,7,4		    # back up r4

	add	5,3,0		    # move input(r3) into r5
	add	4,2,0		    # move input_byte(r2) into r4
	lw   	1,7,-17		    # point to read_byte target
	jalr	6,1		    # read byte
				    # result is in r3

	sw	5,7,3		    # store incremented input on stack
	add	2,4,0		    # store incremented byte into r2

	lw	5,7,5		    # restore r5
	lw	4,7,4		    # restore r4
	lw	1,7,-18		    # point to write_byte target
	jalr	6,1		    # write_byte

	add	1,3,0		    # move byte into r1
	lw	3,7,3		    # restore input pointer

	beq	1,0,done_strcat	    # if 0, done	
	
	beq	0,0,strcat_loop	    # else, loop
	
done_strcat:
	lw	5,7,5		    # restore r5 before last increment
	lw	4,7,4		    # restore r4 before last increment
	
	add	2,0,0		    # clear r2, makes repeated cats easier
	
        lw	6,7,6		    # restore r6	
        addi 	7,7,-16		    # restore stack
        jalr	0,6		    # return


	#============================
	# center_and_print
	#============================
	# out_buffer = string to print

center_and_print:
        addi 	7,7,16		    # move stack   
        sw	6,7,6		    # back up r6

	movi	3,escape	    # Print "^[["
	lw	1,7,-23		    # point to write_stdout target
	jalr	6,1		    # write_stdout

	lw	5,7,-22		    # point r3 to out_buffer

	lw	1,7,-28		    # point to strlen target
	jalr	6,1		    # strlen

	movi	1,80		    # load in 80
	nand	4,4,4		    # two's complement the string length
	addi	4,4,1		    #

	add	2,4,1		    # subtract

	addi	3,0,2		    # we want to divide by 2
	lw	1,7,-20		    # point to shift_right target
	jalr	6,1		    # shift right

	add	2,1,0		    # load back the result

	lw	5,7,-30	    	    # point to our ascii_buffer
	add	4,0,0
	lw	1,7,-31		    # point to num_to_ascii target
	jalr	6,1		    # num_to_ascii

	lw	3,7,-30		    # Point to our ascii number and print
	lw	1,7,-23		    # point to write_stdout target
	jalr	6,1		    # write stdout
	
	movi	3,c	    	    # Print "C"
	lw	1,7,-23		    # point to write_stdout target
	jalr	6,1		    # write stdout
	
	lw	3,7,-22		    # point r3 to out_buffer
	lw	1,7,-23		    # point to write_stdout target
	jalr	6,1		    # write stdout

	movi	3,linefeed	    # Point to string	
        lw	6,7,6		    # restore r6	
        addi 	7,7,-16		    # restore stack

				    # fall through to write_stdout

	#============================
	# write_stdout
	#============================
	# r3 = string to print
	# r1,r2,r4,r5 = trashed

write_stdout:
        sw      6,7,0			    # store return value on stack
	
	add	5,0,3			    # copy r3 to r5

	movi	1,strlen
	jalr	6,1

	addi 	1,0,SYSCALL_WRITE	    # Put syscall in R1
	addi	2,0,STDOUT		    # Stdout in R2
	sys 	0			    # syscall

	lw	6,7,0			    # load return off stack

	jalr	0,6			    # return


	#===============================
	# strlen
	#===============================
	# r5 points to string (assumes starts at even address)
	# r1,r2 trashed
	# r4 returns count

strlen:
	addi	4,0,0			    # clear count
strlen_loop:

	lw  	2,5,0			    # load 16-bit value
	
        lui	1,0xff00		    # load mask
	nand	1,1,2			    # nand it
	nand	1,1,1			    # invert to get and

	beq	1,0,strlen_done		    # if 0, we're done
	
	addi	4,4,1	       		    # increment count
	
	lw  	2,5,0			    # load 16-bit value	
	
	beq	1,2,strlen_done		    # if the loaded string matches
					    # the masked string, it means
					    # the bottom byte is 0
	
	addi	4,4,1	       		    # increment count
	addi	5,5,1			    # increment pointer
	
	beq	0,0,strlen_loop		    # loop
	
strlen_done:

	jalr	0,6			    # return
	

	#==============================
	# num_to_ascii
	#==============================
	# r5/r4=buffer
	# r2=value

num_to_ascii:
        addi 	7,7,16		    # move stack   
        sw	6,7,6		    # save return value

	sw 	5,7,5		    # save the output_ptr
	sw 	4,7,4		    # save the output_byte

	sw 	0,7,8    	    # seen non-zero = 0
   
	movi 	5,ten_thousand	    # point to end of tens array
   
div_loop:   
	lw  	6,5,0		    # load current power of 10 into r6
	beq 	6,0,done_div	    # if it's a zero, we're done
	add 	3,0,0  		    # set our counter to zero	
sub_loop:
	add 	1,6,0		    # This code checks for r2<r6
	nand 	1,1,1		    # We have to twos complement by hand
	addi 	1,1,1		    
	add 	1,1,2		    # Then add
	lui 	4,0x8000	    # Then check if high bit set (negative)
	nand 	1,1,4
	nand 	1,1,1
	beq  	1,0,not_less	    # if not negative, skip ahead
	beq  	0,0,done_sub	    # if negative, we've gone too far!
	
not_less:   
	addi 	3,3,1 		    # increment count
	lw   	1,5,0		    # load in power of 10 again
	add  	6,6,1		    # add it to the comparator
	beq  	0,0,sub_loop	    # loop and substract again
	
done_sub:
	add 	1,0,6		    # subtract off the digit we found
	nand 	1,1,1		    # we have to two's complement by hand
   	addi 	1,1,1
 	add 	2,2,1
	
   	lw  	1,5,0		    # since we already incremented
   	add 	2,2,1		    # we have to adjust back up by one

	# The following code detects whether we should print
	# a leading zero or not, i.e. leading zero suppression

	beq 	3,0,we_have_a_zero  # if digit is zero, run some more checks
	beq 	0,0,write_char	    # otherwise write the char
	
we_have_a_zero:
	addi    1,1,-1		    # see if we are ones digit
	beq  	1,0,write_char	    # we always print the ones digit
	
	lw   	1,7,8		    # see if we've printed non-zero before
	beq  	1,0,skip_write	    # if not, leading zero, so skip
	 
write_char:	 
        addi 	3,3,0x30	    # convert digit to ASCII
	sw   	5,7,9		    # back up r5 as we go to print
	lw   	5,7,5		    # restore output_ptr
	lw   	4,7,4		    # restore output_byte
       	movi 	1,write_byte
	jalr 	6,1	    	    # call write_byte
	sw   	5,7,5		    # save updated output_ptr
	sw   	4,7,4		    # save updated output_byte
	lw   	5,7,9		    # restore the tens pointer
	addi	1,0,1
	sw   	1,7,8		    # no need to skip leading zeros anymore

skip_write:   
	addi  	5,5,-1		    # adjust 10s array to next entry
	beq  	0,0,div_loop	    # and loop
   
done_div:   
	add  	3,0,0		    # output a terminating NUL
	lw   	5,7,5		    # restore output_ptr
	lw   	4,7,4		    # restore output_byte
	movi 	1,write_byte	    # call write_byte
	jalr 	6,1
	
	lw   	5,7,5		    # restore output_ptr
	lw   	4,7,4		    # restore output_byte	
   
        lw	6,7,6		    # restore r6	
        addi 	7,7,-16		    # restore stack
	
	jalr  	0,6		    # return

        #=================================
        # FIND_STRING 
	#=================================
	# r2 is 2-char string to find
	# r2 is zero on return
	
find_string:
        addi 	7,7,16		    # save stack
	sw	6,7,6		    # save return value
	sw	5,7,5		    # save output_ptr
	sw	4,7,4		    # save output_byte
	
	lw	5,7,-29	    	    # point to disk buffer
	add	4,0,0

find_loop:
	lw	1,7,-17		    # point to read_byte target
	jalr	6,1		    # read_byte
		   		    # result is in r3

	sw	5,7,8		    # save pointer, as we
	sw	4,7,9		    # don't want to increment twice

	beq	3,0,done_with_find  # if it was a zero, we ran off the end..

				    # we want to shift r3 left by 8
	lw	1,7,-21		    # load shift_left_8 target
	jalr	6,1		    # shift left by 8

	sw	3,7,3		    # store result on stack

	lw	1,7,-17		    # point to read_byte target
	jalr	6,1		    # read_byte
				    # result in r3
				    
	lw	1,7,3		    # restore previous value
	
	add	3,1,3 		    # make one big 16-bit unaligned value
	
	lw	5,7,8		    # move pointer back by one
	lw	4,7,9
	
	beq	3,2,found_match	    # if found match, then done
	beq	0,0,find_loop	    # otherwise, loop
	
found_match:	
        movi	1,0x3a		    # load colon value
find_colon:
	lw	2,7,-17		    # point to read_byte target
	jalr	6,2		    # read_byte
	
		   		    # result in r3

	beq	1,3,found_colon	    # if found, move ahead
	beq	0,0,find_colon	    # else, loop
	
found_colon:	

	jalr	6,2		    # call read_byte again
	
write_loop:

	jalr	6,2		    # call read_byte
		   		    # result in r3

	sw	5,7,8		    # backup the input ptr
	sw	4,7,9		    # backup the input byte

	lw	5,7,5		    # restore output ptr
	lw	4,7,4		    # restore output byte

	addi	1,0,10		    # look for linefeed
	beq	1,3,done_with_find  # if we match, we are done

	lw	1,7,-18		    # point to write_byte target
	jalr	6,1		    # write byte
	
	sw	5,7,5		    # save output ptr
	sw	4,7,4		    # save output byte

	lw	5,7,8		    # restore input ptr
	lw	4,7,9		    # restore input byte
	
	beq	0,0,write_loop	    # loop


done_with_find:

	add     2,0,0		    # makes strcat on return easier

	lw	6,7,6		    # restore return value
	
        addi 	7,7,-16		    # restore stack
	jalr	0,6		    # return
 


#===========================================================================
#	section .data
#===========================================================================

ver_string:      .ascii  " Version \0"
compiled_string: .ascii  ", Compiled \0"
one:		 .ascii  "One \0"
mhz:		 .ascii  " \0"
processor:	 .ascii  " Processor \0"
ram_comma:       .ascii  "K RAM, \0"
bogo_total:      .ascii  " Bogomips Total\0"
linefeed:        .ascii  "\n\0"
default_colors:  .ascii "\033[0m\n\n\0"
escape:          .ascii "\033[\0"
c:               .ascii "C\0"

cpuinfo:
      .ascii "proc/cpu.RiSC\0"

tens:
     		 .fill 0
		 .fill 1
		 .fill 10
		 .fill 100
		 .fill 1000
ten_thousand:		 
		 .fill 10000

.include "logo.lzss_new"

#
# Commonly used values that can be obtained by subtracting off the stack
#
 		.fill  num_to_ascii	 # -15
 		.fill  ascii_buffer	 # -14
 		.fill  disk_buffer	 # -13
 		.fill  strlen		 # -12 = doesn't decrease size
 		.fill  find_string	 # -11
 		.fill  center_and_print  # -10
 		.fill  uname_info   	 # -9
 		.fill  strcat	    	 # -8
 		.fill  write_stdout 	 # -7
                .fill  out_buffer   	 # -6
	 	.fill  shift_left_8   	 # -5
	 	.fill  shift_right  	 # -4
	 	.fill  text_buffer  	 # -3
	  	.fill  write_byte   	 # -2
	 	.fill  read_byte    	 # -1
stack:
logo_ptr:	.fill  logo         	#  0
out_ptr:	.fill  out_buffer   	#  1
text_ptr:	.fill  480	    	#  2 : N-F  (1024-64)/2

#============================================================================
#	section .bss
#============================================================================

zeroed_stack:	.space  128
out_buffer:     .space	4096
# (N+F)-1 = 1087 ... /2 = 544
text_buffer:	.space  544
uname_info:	.space  80
disk_buffer:	.space  256
ascii_buffer:	.space	4
sysinfo_buff:	.space  64
