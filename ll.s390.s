#
#  linux_logo in s390 assembler 0.10
#
#  by 
#       Vince Weaver <vince@deater.net>
#
#  assemble with     "as -o ll.o ll.s390.s"
#  link with         "ld -o ll ll.o"

# NOTES:	
#      + very CISC'y.  Makes nice small code-size.  Would be even smaller
#        if I could figure out how to use some of the more complex string
#        and packing opcodes
#      + Couldn't figure out "gas"'s addressing here.  Labels point
#	 from the start of the segment rather than relative.  And they
#	 seem to overflow at about 4096 or so, so I had to use a pointer
#	 table (This was very annoying to track down)
#      + Have some extraneous "sr %r0,%r0" that could probably be removed
#        to minimize size more.
	
#  BUGS:  No Pretty Printing (rounding, cpu-model cleanup)
#      :  Only works with <896MB of RAM (linux limitation of /proc/kcore)
#         need to parse /proc/iomem to get up to 4gig reporting
#      :  Doesn't print vendor name

# offsets into the results returned by the uname syscall
.equ U_SYSNAME,0
.equ U_NODENAME,65
.equ U_RELEASE,65*2
.equ U_VERSION,(65*3)
.equ U_MACHINE,(65*4)
.equ U_DOMAINNAME,65*5

# offset into the results returned by the stat syscall
.equ S_SIZE,20

# Sycscalls
.equ SYSCALL_EXIT,   1
.equ SYSCALL_READ,   3
.equ SYSCALL_WRITE,  4
.equ SYSCALL_OPEN,   5
.equ SYSCALL_CLOSE,  6
.equ SYSCALL_STAT, 106
.equ SYSCALL_UNAME,122

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
	sr	%r1,%r2			# addys are releative to segment
					# so subtract off current offset
	la	%r12,new_logo(%r1)	# point input to new_logo
	la 	%r13,out_buffer(%r1)	# point output to buffer
	
main_logo_loop:
	lh	%r6,0(0,%r12)		# load 16-bits
	sra	%r6,8			# shift to get byte
	ahi	%r12,1			# increment pointer

	chi	%r6,0			# if zero, we are done
	je 	done_logo
	
	chi	%r6,27			# if ^[, we are a color
	jne 	blit

	lhi	%r5,0x1b5b		# load ^[[
	sth	%r5,0(0,%r13)		# out to buffer
	ahi	%r13,2			# increment pointer		

	lh	%r5,0(0,%r12)		# load counter of num to output
	sra	%r5,8			
	ahi	%r12,1			

out_elements:

	lh	%r6,0(0,%r12)		# load color
	sra	%r6,8			
	ahi	%r12,1			

	bras	%r15,num_to_ascii	# convert to ascii string

	lhi	%r4,';'			# store semi-colon
	stc	%r4,0(0,%r13)
	ahi	%r13,1

	brct 	%r5,out_elements	# decreemnt r5 and loop

	ahi	%r13,-1			# erase extra semi-colon

	lh	%r6,0(0,%r12)		# load closing char
	sra	%r6,8
	stc	%r6,0(0,%r13)		# save it tooutput
	ahi	%r12,1		
	ahi	%r13,1	

	j	main_logo_loop		# done with color

blit:
	lh	%r5,0(0,%r12)		# load counter of times to blit
	sra	%r5,8			
	ahi	%r12,1			

blit_repeat:		
	stc	%r6,0(0,%r13)		# save it
	ahi	%r13,1				
	brct	%r5,blit_repeat		# decrement r5, compare to zero, loop
				
	j main_logo_loop

done_logo:
	lhi	%r4,0x0a00	
	sth	%r4,0(0,%r13)		# append linefeed and nul

	la	%r3,out_buffer(%r1)	# point to beginning of buffer

	bras	%r15,write_stdout	# and print it
	
	#==========================
	# PRINT VERSION
	#==========================
print_version:
	la 	%r13,out_buffer(%r1)	# re-point point to output buffer
		
	la	%r2,uname_info(%r1)	# point to beginning of buffer
	svc 	SYSCALL_UNAME		# uname syscall

	sr	%r0,%r0			# nul is our end of line for mvst
	
	la	%r12,uname_info+U_SYSNAME(%r1)	# os-name from uname "Linux"
	mvst	%r13,%r12

	la	%r12,ver_string(%r1)	# source is " Version "
	mvst	%r13,%r12
	
	la	%r12,uname_info+U_RELEASE(%r1)	# version from uname "2.4.1"
	mvst	%r13,%r12
	
	la	%r12,compiled_string(%r1)	# source is ", Compiled "
	mvst	%r13,%r12

	la	%r12,uname_info+U_VERSION(%r1)	# compiled date
	mvst	%r13,%r12
	
	la	%r3,out_buffer(%r1)	# point to beginning of buffer
	
	bras	%r15,center		# print some spaces
	
	lhi	%r4,0x0a00	
	sth	%r4,0(0,%r13)		# append linefeed and nul	

	la	%r3,out_buffer(%r1)	# point to beginning of buffer

	bras	%r15,write_stdout	# and print it
		
	#===============================
	# Middle-Line
	#===============================

	la	%r13,out_buffer(%r1)	# point to beginning of buffer
	
	#=========
	# Load /proc/cpuinfo into buffer
	#=========
start_cpuinfo:	
	la	%r2,cpuinfo(%r1)	# '/proc/cpuinfo'
	sr	%r3,%r3			# 0 = O_RDONLY <bits/fcntl.h>
	sr	%r4,%r4
			
	svc	SYSCALL_OPEN		# open().  fd=%r2
					# we should check that %r2>=0
	
	lr	%r6,%r2			# save the fd
	
	l	%r3,disk_buffer_p(%r1)
	lhi	%r4,4096	 	# 4096 is maximum size of proc file #)
					# we load sneakily by knowing
	
	svc	SYSCALL_READ		# read()
				
	lr	%r2,%r6
	svc	SYSCALL_CLOSE		# close (to be correct)
end_cpuinfo:

	
	#=============
	# Number of CPU's
	#=============

	la	%r4,search_sors(%r1)
	l	%r5,0(%r4)		# 4-byte string in r5
	l	%r6,disk_buffer_p(%r1)	# point to cpuinfo
	
cpu_loop:
	l	%r7,0(%r6)		# load 4 bytes from cpuinfo
	ahi	%r6,1			# increment pointer
	cr	%r5,%r7			# do we match search pattern?
	jne	cpu_loop		# if not, keep searching
					# (should check for EOF as well	
	
					# if we get this far, we matched

cpu_colon:
	lhi	%r0,':'			# search for colon
	srst	%r5,%r6			# repeat till we find colon

	ahi	%r5,1			# point after colon

	lh	%r4,0(%r5)		# grab the number
        n       %r4,half_byte_mask(%r1) # mask off (convert from ascii)
	ahi	%r4,-1			# decrement (arrays start at 0)
	sla	%r4,2			# shift over (32bit pointer)
	
	la	%r5,ordinal(%r1)	# load the pointer
	ar	%r5,%r4			# add the offset

	l	%r12,0(%r5)		# print the string
	sr	%r0,%r0	
	mvst	%r13,%r12   		
	
	la	%r12,space(%r1)		# print a space
	mvst	%r13,%r12
	
	
	#=========
	# MHz
	#=========
	
# No MHz detection on this architecture
	   
   	#=========
	# Chip Name
	#=========

	la	%r4,search_r_id(%r1)	# Look for "vendor_id"
	bras	%r15,find_string	

	sr	%r0,%r0	
	la	%r12,comma(%r1)		# print ' Processor, '
	mvst	%r13,%r12   		
			
	# if we were being clever here we could have saved 'bx' from
	# the bogomips count and then add an 's' to make the chip
	# plural.  Sadly this doesn't look right with any of the chips
	# I have (yet another feature from Stephan Walter)
	
	
	#========
	# RAM
	#========

	la	%r3,stat_buff(%r1)	# do stat() syscall
	la	%r2,kcore(%r1)		# on /proc/kcore (rough size of RAM)
	svc	SYSCALL_STAT
	
	l	%r6,stat_buff+S_SIZE(%r1)	# size in bytes of RAM

	sra	%r6,20			# divide by 1024*1024 to get M
	bras	%r15,num_to_ascii
	
	sr	%r0,%r0	
	la	%r12,ram_comma(%r1)	# print 'M RAM, '
	mvst	%r13,%r12   	
		
	#========
	# Bogomips
	#========

	la	%r4,search_bogo(%r1)	# Grab number of bogomips
	bras	%r15,find_string
		
	lhi	%r0,0
	la	%r12,bogo_total(%r1)	# source is " Bogomips Total"
	mvst	%r13,%r12   

	la	%r3,out_buffer(%r1)	# point to beginning of buffer
	
	bras	%r15,center		# print some spaces
	
	lhi	%r4,0x0a00	
	sth	%r4,0(0,%r13)		# append linefeed and nul	

	la	%r3,out_buffer(%r1)	# point to beginning of buffer

	bras	%r15,write_stdout	# and print it
	
		
	#=================================
	# Print Host Name
	#=================================
print_host_name:
	la	%r13,out_buffer(%r1)	# point to beginning of buffer	

	sr	%r0,%r0
	
	la	%r12,uname_info+U_NODENAME(%r1)	# host name from uname()

	mvst	%r13,%r12

	la	%r3,out_buffer(%r1)	# point to beginning of buffer
	
	bras	%r15,center		# center it
	
	lhi	%r4,0x0a0a
	sla	%r4,16	
	st	%r4,0(0,%r13)		# append 2 linefeeds and nul	

	la	%r3,out_buffer(%r1)	# point to beginning of buffer	
		
	bras	%r15,write_stdout	# and print it  
	
	la	%r3,default_colors(%r1)	# restore the default colors
	bras	%r15,write_stdout

	#================================
	# Exit
	#================================
	
	xr	%r2,%r2	 		# exit(0)
        svc	SYSCALL_EXIT	        # and exit

	
	#================================
	# WRITE_STDOUT
	#================================
	# r3 has string
	# r2,r4 trashed
write_stdout:
	lhi	%r2,STDOUT		# write to STDOUT
	
	bras	%r14,strlen		# get strlength in %r4
	
	svc	SYSCALL_WRITE  		# run the syscall
	basr	0,%r15

	#=================================
	# NUM_TO_ASCII
	# (note, only works for values < 999)
	#=================================
	# r6 is input
	# output r13
	# r3,r4 trashed
	
num_to_ascii:
	cvd	%r6,decimal(%r1)	# convert int to packed decimal


					# wish we could use the "pack ascii"
					# intruction here.  Alas
	
	lhi	%r4,12			# shift-right amount
	sr	%r3,%r3			# clear r3
num_loop2:	
	lh	%r6,6+decimal(%r1)	# load bottom word (1.5 bytes+sign)

	sra	%r6,0(%r4)		# shift
	n	%r6,half_byte_mask(%r1)	# mask
	jnz	num_print		# if not zero, print it
	
	chi	%r3,0			# if not "printing_zeros" yet, skip
	je	skip_print
	
num_print:		
	ahi	%r6,0x30		# convert to ascii
	stc	%r6,0(%r13)		# store
	ahi	%r13,1			# update pointer
	lhi	%r3,1			# set "printing_zeros" flag
skip_print:
	chi	%r4,8			# if we just did tens column
	jne	no_set_printing_zeros	# set printing_zeros
	lhi	%r3,1
no_set_printing_zeros:		
	ahi	%r4,-4			# change shift counter
	jnz	num_loop2		# loop until done
	
num_done:	
	basr	0,%r15

	#=================================
	# FIND_STRING 
	#=================================
	#   r5 is char to end at
	#   r4 points to search string
	#   ebx is 4-char ascii string to look for
	#   edi points at output buffer

find_string:
	l	%r5,0(%r4)		# 4-byte string in r5
	l	%r6,disk_buffer_p(%r1)	# point to cpuinfo

# really want to use "cuse %r4,%r6" but can't figure it out
	
find_loop:
	l	%r7,0(%r6)		# load 4 bytes from cpuinfo
	ahi	%r6,1			# increment pointer
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
	basr	0,%r15			# return	

	#===============================
	# strlen
	#===============================
	# %r3 points to string
	# %r4 is returned with length
	# %r5 is trashed
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

	basr	0,%r14			# return


	
	#==============================
	# center
	#==============================
	# item to center in r3
	# r2,r3,r4,r8,r9 trashed
		
center:
	lr	%r9,%r15		# save return address
        bras	%r14,strlen		# r4 has length

	lhi	%r8,80

	chi	%r4,80			# see if we are >=80
	jl	keep_going		# if so, bail
	j	done_center
keep_going:		
	sr	%r8,%r4			# subtract size from 80
	
	sra	%r8,1			# then divide by 2
	la 	%r3,space(%r1)		# load in a space
	
center_loop:
	bras 	%r15,write_stdout	# and print that many spaces
	brct	%r8,center_loop
done_center:
	lr	%r15,%r9		# restore return address
	basr	0,%r15			# return	



#===========================================================================
#	section .data
#===========================================================================

.include	"logo.inc"

	
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
space:		.ascii	" \0"
megahertz:	.ascii	"MHz \0"
comma:		.ascii	" Processor, \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"

default_colors:	.ascii "\033[0m\0"

cpuinfo:	.ascii	"/proc/cpuinfo\0"
kcore:		.ascii	"/proc/kcore\0"

ordinal:	.long	one,two,three,four	

search_sors:	.ascii "sors"
search_bogo:	.ascii "bogo"
search_r_id:	.ascii "r_id"
			
one:	.ascii	"One\0"
two:	.ascii	"Two\0"
three:	.ascii	"Three\0"
four:	.ascii	"Four\0"

half_byte_mask:	.long	0xf

disk_buffer_p:	.long disk_buffer		
#============================================================================
#	section .bss
#============================================================================
#.bss

.lcomm decimal,8
.lcomm uname_info,(65*6)
.lcomm stat_buff,(4*2+2*4+4*12)
	# urgh get above from /usr/src/linux/include/asm/stat.h
	# not glibc	
.lcomm out_buffer,16384
.lcomm	disk_buffer,4096	# we cheat!!!!









