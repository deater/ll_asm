#
#  linux_logo in ix86 assembler 0.9
#
#  Originally by 
#       Vince Weaver <vince@deater.net>
#
#  Extensive Size Optimization Suggestions from
#       Stephan Walter <stephan.walter@gmx.ch>
#
#  assemble with     "as -o ll.o ll.ix86.s"
#  link with         "ld -o ll ll.o"

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
	
	mov 	$new_logo,%esi		# point input to new_logo
	mov 	$out_buffer,%edi	# point output to buffer

main_logo_loop:	
	lodsb				# load character
	cmp	$0,%al			# if zero, we are done
	je 	done_logo
	
	cmp	$27,%al			# if ^[, we are a color
	jne 	blit_repeat

	mov 	$'[',%ah		# load ^[[
	stosw				# out to buffer

	lodsb				# counter, for num to output
	mov	%al,%cl			# move to loop register

out_elements:
	xor	%eax,%eax		# clear eax
        lodsb				# load color

	call num_to_ascii

	mov	$';',%al		# store semi-colon
	stosb

	loop 	out_elements

	dec 	%di			# erase extra semi-colon
	lodsb				# load closing char
	stosb				# store to buffer

	jmp 	main_logo_loop		# done with color

blit_repeat:
	mov     %al,%dl			# save the character
	lodsb				# get times to repeat
	mov	%al,%cl			# move times to repeat in loop reg
	mov	%dl,%al			# restore the character to output
	rep 				# rle to buffer
	stosb				# stosb on separate line to work
					# around 2.9.1 binutils

	jmp main_logo_loop

done_logo:	
	mov	$0xa,%al
	stosb				# print linefeed
	
	mov     $out_buffer,%ecx	# our nice huge logo
	call	write_stdout
	
	#==========================
	# PRINT VERSION
	#==========================
	
	push 	$SYSCALL_UNAME		# uname syscall
	pop	%eax			# in 3 bytes
	
	mov	$uname_info,%ebx	# uname struct
	int	$0x80			# do syscall
	
	mov	$out_buffer,%edi		# destination is temp_string
	mov	$(uname_info+U_SYSNAME),%esi	# os-name from uname "Linux"
	call	strcat
	
	mov	$ver_string,%esi		# source is " Version "
	call 	strcat
	
	mov	$(uname_info+U_RELEASE),%esi    # version from uname "2.4.1"
	call 	strcat
	
	mov	$compiled_string,%esi		# source is ", Compiled "
	call 	strcat

	mov	$(uname_info+U_VERSION),%esi	# compiled date
	call 	strcat
	
	mov	$out_buffer,%ecx
	
	call	center			# print some spaces
	
	mov	$0xa,%ax		# store linefeed on end
	stosw				# and zero			  
	
	mov 	$out_buffer,%ecx	
        call	write_stdout
	
  
	
	#===============================
	# Middle-Line
	#===============================
	
	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	push	$SYSCALL_OPEN		# load 5 [ open() ]
	pop	%eax			# in 3 bytes
	
	mov	$cpuinfo,%ebx		# '/proc/cpuinfo'
	xor	%ecx,%ecx		# 0 = O_RDONLY <bits/fcntl.h>
	xor	%edx,%edx
	int	$0x80			# syscall.  fd in eax.  
					# we should check that eax>=0
	mov	%eax,%ebx
	
	push	$SYSCALL_READ		# load 3 = read()
	pop	%eax			# in 3 bytes
	
	mov	$disk_buffer,%ecx
	mov	$16,%dh		 	# 4096 is maximum size of proc file #)
					# we load sneakily by knowing
					# 16<<8 = 4096. be sure edx clear
	int	$0x80

	push	$SYSCALL_CLOSE		# close (to be correct)
	pop	%eax
	int	$0x80			

	#=============
	# Number of CPU's
	#=============
	
	xor	%ebx,%ebx		# chip count
	
	mov	$disk_buffer,%esi
bogo_loop:	
	lods    %ds:(%esi),%eax		# load 32 bits (lodsd)
	dec     %esi			# back up 3 bytes to we will
	dec	%esi			# cover whole file eventually
	dec	%esi
	cmp	$0,%al
	je	done_bogo
	cmp	$0x6f676f62,%eax	# "bogo" in little-endian
	jne	bogo_loop
	inc	%ebx			# we have a bogo
	jmp	bogo_loop

done_bogo:

        mov      ordinal-4(,%ebx,4),%esi	# yes, intel assembly
		 				# is CRAZY
						# point to the (ebx-1)th
						# element of 4byte wide
						# array at ordinal
					# mov esi, [ebx*4+ordinal-4]
					# for those of you using intel syntax

	mov	$out_buffer,%edi	# destination string
	call	strcat			# copy it

	mov	$space,%esi		# print a space
	call	strcat
	
	
	#=========
	# MHz
	#=========
	
	mov	$('z'<<24+'H'<<16+'M'<<8+' '),%ebx	
			   		# find ' MHz\t: ' and grab up to .
	                                # we are little endian
	mov	$'.',%dl			
   	call	find_string
   
   	mov	$megahertz,%esi		# print 'MHz '
	call	strcat
   
   
   	#=========
	# Chip Name
	#=========
	
   	mov	$('e'<<24+'m'<<16+'a'<<8+'n'),%ebx     	
					# find 'name\t: ' and grab up to \n
       					# we are little endian
	mov	$0xa,%dl
	call	find_string
	
	mov	$comma,%esi		# print ', '
	call	strcat
	
	# if we were being clever here we could have saved 'bx' from
	# the bogomips count and then add an 's' to make the chip
	# plural.  Sadly this doesn't look right with any of the chips
	# I have (yet another feature from Stephan Walter)
	
	
	#========
	# RAM
	#========
	
	push    $SYSCALL_STAT		# stat() syscall (106)
	pop	%eax
	
	mov	$kcore,%ebx		# size of /proc/kcore
	mov	$stat_buff,%ecx		# is size of RAM
	int	$0x80
	
	mov	(stat_buff+S_SIZE),%eax	# size in bytes of RAM
	shr	$20,%eax		# divide by 1024*1024 to get M

#	adc	$0, %eax		# round ??

	call	num_to_ascii
		
	mov	$ram_comma,%esi		# print 'M RAM, '
	call	strcat
	
	#========
	# Bogomips
	#========
	
	mov	$('s'<<24+'p'<<16+'i'<<8+'m'),%ebx      	
					# find 'mips\t: ' and grab up to \n
	mov	$0xa,%dl
	call	find_string
   
   	mov	$bogo_total,%esi
	call	strcat
   
	mov	$out_buffer,%ecx	# string done, lets print it
	
	call	center			# print some spaces
	
	mov	$0xa,%eax		# and line feed and zero
	stosw

	mov 	$out_buffer,%ecx		
	call 	write_stdout
	
	#=================================
	# Print Host Name
	#=================================
	
	mov	$out_buffer,%edi		# output string
	mov	$(uname_info+U_NODENAME),%esi	# host name from uname()
	mov	$out_buffer,%ecx		# for strlen
	call	strcat
	call	center			# center it
	
	mov	$0xa0a,%eax		# tack 2 line-feeds and zero on end
	stos    %eax,%es:(%edi)		# load 32 bits (lodsd)

	mov 	$out_buffer,%ecx		
	call	write_stdout

	mov	$default_colors,%ecx
	call	write_stdout

	#================================
	# Exit
	#================================
	
        xor     %ebx,%ebx
	xor	%eax,%eax
	inc	%eax	 		# put exit syscall number (1) in eax
        int     $0x80             	# and exit


	#================================
	# WRITE_STDOUT
	#================================
	# ecx has string
	# eax,ebx,ecx,edx trashed
write_stdout:
	push	$SYSCALL_WRITE		# put 4 in eax (write syscall)
	pop     %eax     		# in 3 bytes of code
	
	xor	%ebx,%ebx		# put 1 in ebx (stdout)
	inc	%ebx			# in 3 bytes of code
	
	call	strlen			# get strlength in edx
	
	int	$0x80  			# run the syscall
	ret


	#=================================
	# NUM_TO_ASCII
	#=================================
	# al has number
	# output [edi]
	# bl, eax trashed
	
num_to_ascii:	
	push	 %ecx		# save ecx
	xor	 %ecx,%ecx	# clear ecx
	
	mov	 $10,%bl	# we will divide by 10
div_by_10:	
	div	 %bl		# divide
	
	ror	 $8,%ax		# get the remainder in al
	add	 $0x30,%al	# convert to ascii
	push	 %eax		# save for later
	inc	 %ecx		# add to length counter
	
	shr	 $8,%ax		# restore quotient and clear ah
       
        cmp	 $0,%al		# was Q zero?
       	jnz	 div_by_10	# if not divide again
	
write_out:
	pop	 %eax		# restore in reverse order
	stosb	     		# save digit
	loop     write_out	# loop till done
	pop	 %ecx		# restore ecx
	ret


	#=================================
	# FIND_STRING 
	#=================================
	#   dl is char to end at
	#   ebx is 4-char ascii string to look for
	#   edi points at output buffer

find_string:
					
	mov	$disk_buffer,%esi	# look in cpuinfo buffer
find_loop:
	lods    %ds:(%esi),%eax		# load 32 bits (lodsd)	
	dec	%esi
	dec	%esi
	dec	%esi			# move pointer +1 to search all file

	cmp	$0,%al
	je	done

	cmp	%eax,%ebx
	jne	find_loop
	
					# if we get this far, we matched

find_colon:
	lodsb				# repeat till we find colon
	cmp	$0,%al
	je	done
	cmp	$':',%al
	jne	find_colon

	lodsb				# skip a char [should be space]
	
store_loop:	 
	 lodsb				# load value
	 cmp	$0,%al
	 je	done
    	 cmp	%dl,%al			# is it end string?
	 je 	almost_done		# if so, finish
	 stosb				# if not store and continue
	 jmp	store_loop
	 
almost_done:	 
	xor	%eax,%eax		# replace last value with null
	stosb
	dec	%edi			# move pointer back 
done:
	ret


	#================================
	# strcat
	#================================

strcat:
	lodsb				# load a byte from [ds:esi]
	stosb				# store a byte to [es:edi]
	cmp	$0,%al			# is it zero?
	jne	strcat			# if not loop
	dec	%edi			# point to one less than null
	ret				# return

	#===============================
	# strlen
	#===============================
	# ecx points to string
	# edx is returned with length

strlen:
	push 	%ecx			# save pointer
	xor	%edx,%edx		# clear counter
str_loop:
	inc	%ecx
	inc	%edx
	cmpb 	$0,(%ecx)		# repeat till we find zero
	jne	str_loop
	
	pop %ecx
	ret
	
	#==============================
	# center
	#==============================

	
center:
        call	strlen
	
	push	$80
	pop	%ebp
	
	cmp	%bp,%dx			# see if we are >=80
	jge	done_center		# if so, bail
	
	sub	%dx,%bp			# subtract size from 80
	
	shr	%bp			# then divide by 2
	mov 	$space,%ecx		# load in a space
	
center_loop:
	call 	write_stdout		# and print that many spaces
	dec	%bp
	jnz	center_loop
done_center:	
	ret


#===========================================================================
#	section .data
#===========================================================================
.data
.include	"logo.inc"

ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
space:		.ascii	" \0"
megahertz:	.ascii	"MHz \0"
comma:		.ascii	", \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"

default_colors:	.ascii "\033[0m\0"

cpuinfo:	.ascii	"/proc/cpuinfo\0"
kcore:		.ascii	"/proc/kcore\0"

ordinal:	.long	one,two,three,four	

one:	.ascii	"One\0"
two:	.ascii	"Two\0"
three:	.ascii	"Three\0"
four:	.ascii	"Four\0"

#============================================================================
#	section .bss
#============================================================================
.bss

.lcomm	disk_buffer,4096	# we cheat!!!!
.lcomm	out_buffer,16384

.lcomm stat_buff,(4*2+2*4+4*12)
	# urgh get above from /usr/src/linux/include/asm/stat.h
	# not glibc

.lcomm uname_info,(65*6)





