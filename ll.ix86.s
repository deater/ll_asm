#
#  linux_logo in ix86 assembler 0.14
#
#  Originally by 
#       Vince Weaver <vince@deater.net>
#
#  Crazy size-optimization hacks by
#       Stephan Walter <stephan.walter@gmx.ch>
#
#  assemble with     "as -o ll.o ll.ix86.s"
#  link with         "ld -o ll ll.o"

#  BUGS:  No Pretty Printing (rounding, cpu-model cleanup)
#      :  MHz might crash on <586 machine w/o the field there
#      :  sysinfo() returns RAM - reserved area which can be from 1-20MB off
#      :  sysinfo results struct changed between 2.2 and 2.4 kernels
#      :  Doesn't print vendor name

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

# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver

        # we used to fill the buffer with FREQUENT_CHAR
	# but, that only gains us one byte of space in the lzss image.
        # the lzss algorithm does automatic RLE... pretty clever
	# so we compress with NUL as FREQUENT_CHAR and it is pre-done for us

	mov     $(N-F), %bp   	     	# R

	mov  	$logo, %esi		# %esi points to logo (for lodsb)

	mov	$out_buffer, %edi	# point to out_buffer
	push	%edi	     		# save this value for later

decompression_loop:	
	lodsb			# load in a byte

	mov 	$0xff, %bh	# re-load top as a hackish 8-bit counter
	mov 	%al, %bl	# move in the flags

test_flags:
	cmp	$logo_end, %esi # have we reached the end?
	je	done_logo  	# if so, exit

	shr 	$1, %ebx	# shift bottom bit into carry flag
	jc	discreet_char	# if set, we jump to discreet char

offset_length:
	lodsw                   # get match_length and match_position
	mov %eax,%edx		# copy to edx
	    			# no need to mask dx, as we do it
				# by default in output_loop
	
	shr $(P_BITS),%eax	
	add $(THRESHOLD+1),%al
	mov %al,%cl             # cl = (ax >> P_BITS) + THRESHOLD + 1
                                #                       (=match_length)
		
output_loop:
        and 	$POSITION_MASK,%dh  	# mask it
	mov 	text_buf(%edx), %al	# load byte from text_buf[]
	inc 	%edx	    		# advance pointer in text_buf
store_byte:	
	stosb				# store it
	
	mov     %al, text_buf(%ebp)	# store also to text_buf[r]
	inc 	%ebp 			# r++
	and 	$(N-1), %bp		# mask r

	loop 	output_loop		# repeat until k>j
	
	or	%bh,%bh			# if 0 we shifted through 8 and must
	jnz	test_flags		# re-load flags
	
	jmp 	decompression_loop

discreet_char:
	lodsb				# load a byte
	inc	%ecx			# we set ecx to one so byte
					# will be output once
					# (how do we know ecx is zero?)
					
        jmp     store_byte              # and cleverly store it


# end of LZSS code

done_logo:

	pop 	%ebp			# get out_buffer and keep in bp
	mov	%ebp,%ecx		# move out_buffer to ecx

        call	write_stdout		# print the logo

	#
	#  Setup
	#
setup:
	mov	$strcat,%edx		# use edx as call pointer

	#==========================
	# PRINT VERSION
	#==========================
	
	push 	$SYSCALL_UNAME		# uname syscall
	pop	%eax			# in 3 bytes	
	mov	$uname_info,%ebx	# uname struct
	int	$0x80			# do syscall

	mov	%ebp,%edi		# point %edi to out_buffer
		
	mov	$(uname_info+U_SYSNAME),%esi	# os-name from uname "Linux"
	call	*%edx			# call strcat
blah:	
	mov	$ver_string,%esi		# source is " Version "
	call 	*%edx			        # call strcat
	push	%esi  				# save our .txt pointer
	
	mov	$(uname_info+U_RELEASE),%esi    # version from uname "2.4.1"
	call 	*%edx				# call strcat
	
	pop	%esi  			# restore .txt pointer
                                        # source is ", Compiled "
	call 	*%edx			# call strcat
	push	%esi  			# store for later

	mov	$(uname_info+U_VERSION),%esi	# compiled date
	call 	*%edx			# call strcat

	mov	%ebp,%ecx		# move out_buffer to ecx

	mov	$0xa,%ax		# store linefeed on end
	stosw				# and zero			  

	call	*%edx			# call strcat
	
	call	center_and_print	# center and print
  	
	#===============================
	# Middle-Line
	#===============================
	
	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	push	%edx			# save call pointer

	push	$SYSCALL_OPEN		# load 5 [ open() ]
	pop	%eax			# in 3 bytes
	
	mov	$cpuinfo,%ebx		# '/proc/cpuinfo'
	xor	%ecx,%ecx		# 0 = O_RDONLY <bits/fcntl.h>
	cdq				# clear edx in clever way
	int	$0x80			# syscall.  fd in eax.  
					# we should check that eax>=0
					
	mov	%eax,%ebx		# save our fd
	
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
number_of_cpus:

	xor	%ebx,%ebx		# chip count
	
					# $disk_buffer still in ecx
bogo_loop:	
	mov	(%ecx), %eax		# load 4 bytes into eax
	inc	%ecx			# increment pointer
	
	cmp	$0,%al			# check for end of file
	je	done_bogo
	
	cmp	$('o'<<24+'g'<<16+'o'<<8+'b'),%eax	
				        # "bogo" in little-endian
					
	jne	bogo_loop		# if not equal, keep going
	
	inc	%ebx			# otherwise, we have a bogo
	inc	%ebx			# times too for future magic
	jmp	bogo_loop

done_bogo:
	lea	one-6(%ebx,%ebx,2), %esi	
				    	# Load into esi
					# [one]+(num_cpus*6)
					#
					# the above multiplies by three
					# esi = (ebx+(ebx*2))
	 				# and we double-incremented ebx 
					# earlier
	 
	mov	%ebp,%edi		# move output buffer to edi

	pop	%edx			# restore call pointer
	call	*%edx			# copy it (call strcat)

	mov	$' ',%al		# print a space
	stosb


	push %edx			# store strcat pointer
	
	#=========
	# MHz
	#=========
print_mhz:
	mov	$('z'<<24+'H'<<16+'M'<<8+' '),%ebx	
			   		# find ' MHz' and grab up to .
	                                # we are little endian
	mov	$'.',%ah

	# below is same as "sub $(strcat-find_string),%edx
	# gas won't let us force the one-byte constant
	.byte 0x83,0xEA,strcat-find_string   
	
	call	*%edx			# call find string
 
	mov	%ebx,%eax  		# clever way to get MHz in, sadly
	ror	$8,%eax			# not any smaller than a mov
	stosl	    			

   	#=========
	# Chip Name
	#=========
chip_name:	
   	mov	$('e'<<24+'m'<<16+'a'<<8+'n'),%ebx     	
					# find 'name\t: ' and grab up to \n
       					# we are little endian
	mov	$0xa,%ah
	call	*%edx	   		# call find_string

	mov	$0x202c,%ax		# ', '
	stosw
	
	# if we were being clever here we could have saved 'bx' from
	# the bogomips count and then add an 's' to make the chip
	# plural.  Sadly this doesn't look right with any of the chips
	# I have (yet another feature from Stephan Walter)
	
	
	#========
	# RAM
	#========
	
	push    $SYSCALL_SYSINFO	# sysinfo() syscall
	pop	%eax	
	mov	$sysinfo_buff,%ebx	
	int	$0x80
	
	mov	(sysinfo_buff+S_TOTALRAM),%eax	# size in bytes of RAM
	shr	$20,%eax		# divide by 1024*1024 to get M
	adc	$0, %eax		# round 


	call num_to_ascii
	
	pop  %edx	 		# restore strcat pointer
	
	pop     %esi	 		# print 'M RAM, '
	call	*%edx			# call strcat

	push	%esi
	

	#========
	# Bogomips
	#========
	
	mov	$('s'<<24+'p'<<16+'i'<<8+'m'),%ebx      	
					# find 'mips\t: ' and grab up to \n
	mov	$0xa,%ah
	call	find_string

 	pop	%esi	   		# bogo total follows RAM 

	call 	*%edx			# call strcat

	push	%esi
 
 
        mov	%ebp,%ecx		# point ecx to out_buffer

	mov	$0xa,%ax		# and line feed and zero
	stosw

	call	center_and_print	# center and print
	
	#=================================
	# Print Host Name
	#=================================

	mov     %ebp,%edi		  # point to output_buffer
	
	mov	$(uname_info+U_NODENAME),%esi	# host name from uname()
	call    *%edx			  # call strcat
	
		      			# ecx is unchanged
	call	center_and_print	# center and print
	
	pop	%ecx			# (.txt) pointer to default_colors
	
	call	write_stdout
	

	#================================
	# Exit
	#================================
exit:
        xor     %ebx,%ebx
	xor	%eax,%eax
	inc	%eax	 		# put exit syscall number (1) in eax
        int     $0x80             	# and exit


	#=================================
	# FIND_STRING 
	#=================================
	#   ah is char to end at
	#   ebx is 4-char ascii string to look for
	#   edi points at output buffer

find_string:
					
	mov	$disk_buffer-1,%esi	# look in cpuinfo buffer
find_loop:
	inc	%esi
	cmpb	$0, (%esi)		# are we at EOF?
	je	done			# if so, done

	cmp	(%esi), %ebx		# do the strings match?
	jne	find_loop		# if not, loop
	
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
    	cmp	%ah,%al			# is it end string?
	je 	almost_done		# if so, finish
	stosb				# if not store and continue
	jmp	store_loop
	 
almost_done:	 

	movb	 $0, (%edi)	        # replace last value with NUL 
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

	#==============================
	# center_and_print
	#==============================
	# string to center in ecx
       
center_and_print:
       push    %edx
       push	%ecx			# save the string pointer
       inc	%edi			# move to a clear buffer
       push	%edi			# save for later
       
       mov	$('['<<8+27),%ax	# we want to output ^[[
       stosw

       cdq	      			# clear dx
	
str_loop2:				# find end of string	
       inc	%edx
       cmpb	$0,(%ecx,%edx)		# repeat till we find zero
       jne	str_loop2
	
       push	$81	 		# one added to cheat, we don't
					# count the trailing '\n'
       pop	%eax
	
       cmp	%eax,%edx		# see if we are >=80
       jge	done_center		# if so, bail
	
       sub	%edx,%eax		# subtract size from 80
	
       shr	%eax			# then divide by 2

       call	num_to_ascii		# print number of spaces
       mov	$'C',%al		# tack a 'C' on the end
       					# ah is zero from num_to_ascii
       stosw				# store C and a NULL
       pop  %ecx			# pop the pointer to ^[[xC
       
       call write_stdout		# write to the screen
      
done_center:
        pop  %ecx			# restore string pointer
	     				# and trickily print the real string

	pop %edx
	
	#================================
	# WRITE_STDOUT
	#================================
	# ecx has string
	# eax,ebx,ecx,edx trashed
write_stdout:
	push    %edx
	push	$SYSCALL_WRITE		# put 4 in eax (write syscall)
	pop     %eax     		# in 3 bytes of code
	
	cdq   	      			# clear edx
	
	xor	%ebx,%ebx		# put 1 in ebx (stdout)
	inc	%ebx			# in 3 bytes of code
	
                       # another way of doing this:    lea 1(%edx), %ebx

str_loop1:
	inc	%edx
	cmpb	$0,(%ecx,%edx)		# repeat till zero
	jne	str_loop1

	int	$0x80  			# run the syscall
	pop	%edx
	ret

	##############################
	# num_to_ascii
	##############################
	# ax = value to print
	# edi points to where we want it
	
num_to_ascii:
        push    $10
        pop     %ebx
        xor     %ecx,%ecx       # clear ecx
 div_by_10:
        cdq                     # clear edx
        div     %ebx            # divide
        push    %edx            # save for later
        inc     %ecx            # add to length counter
        or      %eax,%eax       # was Q zero?
        jnz     div_by_10       # if not divide again
 
write_out:
        pop     %eax            # restore in reverse order
        add     $0x30, %al      # convert to ASCII
        stosb                   # save digit
        loop    write_out       # loop till done
	ret

#===========================================================================
#	section .data
#===========================================================================
.data

ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"

default_colors:	.ascii "\033[0m\n\n\0"

cpuinfo:	.ascii	"/proc/cpuinfo\0"
kcore:		.ascii	"/proc/kcore\0"

one:	.ascii	"One\0\0\0"
two:	.ascii	"Two\0\0\0"
three:	.ascii	"Three\0"
four:	.ascii	"Four\0"

.include	"logo.lzss_new"

#============================================================================
#	section .bss
#============================================================================
.bss

.lcomm  text_buf, (N+F-1)
.lcomm	out_buffer,16384

.lcomm	disk_buffer,4096	# we cheat!!!!


   # see /usr/src/linux/include/linux/kernel.h
.lcomm sysinfo_buff,(64)
.lcomm uname_info,(65*6)
