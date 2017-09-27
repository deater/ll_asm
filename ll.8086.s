#
#  linux_logo in 8086 assembler 0.49
#
#  Originally by
#       Vince Weaver <vince _at_ deater.net>

#
#  Must have ANSI.SYS or equivelent loaded for this to work
#

#  Thanks to Kragen Javier Sitaker for a blog post showing
#     how to create a DOS .COM file using gas

#  Thanks to Ralf Brown's DOS interrupt list
#     *fun fact* Ralf Brown grew up in the same town that I did
#		and his sister was a baby-sitter for my family
#

#  assemble with     "as --32 -R -o ll.8086.o ll.8086.s"
#  link with         "objcopy -O binary ll.8086.o ll.8086.o.o"
#                    "dd if=ll.8086.o.o of=ll_8086.com bs=256 skip=1"

#  Explanation for the above:
#     -R merges text and data segments
#     the DOS .com format is raw assembler, so no linking, just copy
#         the binary blob
#     the dd skips the first 0x100 bytes, as gas's .org directive
#         fills it with useless zeros

#  dump with  "objdump -bbinary --disassemble-all -mi8086 ./ll_8086.com"

# OPTIMIZATIONS
# + Check to see if the contant opts done for 386 actually help on 8086
#   (answer = no)

# Sizes
# + 793 bytes -- original port
# + 794 bytes -- fix to be 8086 (not 286) code.
#                gained a byte because can't do shr IMM
# + 786 bytes -- remove some unnecessary saving of %si
# + 780 bytes -- save %si around find_print, no need to save/restore at all

.include "logo.include"

.text

# generate only 8086 code
.arch i8086
.code16
# COM file is loaded at 0x100 offset
.org 0x100

	.globl start
start:
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

	mov  	$logo, %si		# %si points to logo (for lodsb)

	mov	$out_buffer, %di	# point to out_buffer
	push	%di	     		# save this value for later

	xor	%cx,%cx			# clear cx
					# unlike Linux cannot depend on cx
					# being zero, see
					# http://www.fysnet.net/yourhelp.htm

decompression_loop:
	lodsb			# load in a byte

	mov 	$0xff, %dh	# re-load top as a hackish 8-bit counter
	mov 	%al, %dl	# move in the flags

test_flags:
	cmp	$logo_end, %si  # have we reached the end?
	je	done_logo  	# if so, exit

	shr 	$1, %dx		# shift bottom bit into carry flag
	jc	discrete_char	# if set, we jump to discrete char

offset_length:
	lodsw                   # get match_length and match_position
	mov %ax,%bx		# copy to bx
	    			# no need to mask bx, as we do it
				# by default in output_loop

	mov $(P_BITS),%cl
	shr %cl,%ax
	add $(THRESHOLD+1),%al
	mov %al,%cl             # cl = (ax >> P_BITS) + THRESHOLD + 1
				#                       (=match_length)

output_loop:
	and 	$POSITION_MASK,%bh  	# mask it
	mov 	text_buf(%bx), %al	# load byte from text_buf[]
	inc 	%bx	    		# advance pointer in text_buf
store_byte:
	stosb				# store it
	mov     %al, text_buf(%bp)	# store also to text_buf[r]
	inc 	%bp 			# r++
	and 	$(N-1), %bp		# mask r

	loop 	output_loop		# repeat until k>j

	or	%dh,%dh			# if 0 we shifted through 8 and must
	jnz	test_flags		# re-load flags

	jmp 	decompression_loop

discrete_char:
	lodsb				# load a byte
	inc	%cx			# we set ecx to one so byte
					# will be output once

	jmp     store_byte              # and cleverly store it


# end of LZSS code

done_logo:
	mov	$'$',%al		# terminate string with $
	stosb

	pop 	%bp			# get out_buffer and keep in bp
	mov	%bp,%dx			# move out_buffer to dx

#	push	%bp			# needed?
	call	write_stdout		# print the logo
#	pop	%bp			# needed?

	#
	#  Setup
	#
setup:
	mov	$strcat,%cx		# use cx as call pointer

	#==========================
	# PRINT VERSION
	#==========================

	mov	%bp,%di		   	# point %di to out_buffer

	# We fake the OS-name
	# As DOS has no way of reporting it

	mov	$ver_string,%si		# source is " Version "
	call 	*%cx			# call strcat

	# Get DOS version

	push    %cx	 		# save %cx as the call trashes it
	mov     $0x30,%ah
	int	$0x21
	pop	%cx  			# restore %cx

	# AL = Major version, AH = Minor version
	push	%ax			# save version
	xor	%ah,%ah			# clear out minor version

	call   	num_to_ascii		# print major version

	mov	$'.',%al	  	# print period
	stosb

	pop	%ax
	mov	%ah,%al			# get minor version

	call	num_to_ascii		# print minor version

					# si points to ", Compiled "
	call 	*%cx			# call strcat

	# We fake compiled date
	# because DOS doesn't have such a notion

	mov	%bp,%dx			# move out_buffer to dx

	call	center_and_print	# center and print

	#===============================
	# Middle-Line
	#===============================
middle_line:

	mov     %bp,%di		  	# point to output_buffer

	push	%cx			# save call pointer

	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	mov	$0x3d,%ah		# DOS Open File
	xor	%al,%al			# Set read-only
	mov	$cpuinfo,%dx		# Point to File Name
	int	$0x21			# call DOS

					# error if CF set
	jc	exit

	push	%ax			# save fd

	mov	%ax,%bx			# copy fd into place
	mov	$disk_buffer,%dx	# point to disk buffer
	mov	$4096,%cx		# bytes to read
	mov	$0x3f,%ah		# READ
	int	$0x21			# call DOS

	pop	%bx			# put fd into bx
	mov	$0x3e,%ah		# CLOSE
	int	$0x21			# call DOS

	pop	%cx			# restore call pointer


	#=============
	# Number of CPUs
	#=============
number_of_cpus:

	# We assume only one CPU

					# si points to One
	call	*%cx			# copy it (call strcat)

	#=========
	# MHz
	#=========
print_mhz:
	mov	$('M'<<8+' '),%bx
	mov	$('z'<<8+'H'),%dx

			   		# find ' MHz' and grab up to \n
	                                # we are little endian
	mov	$'\n',%ah

	call	find_string		# call find string

					# si points to MHz
	call	*%cx			# copy it (call strcat)

	#=========
	# Chip Name
	#=========
chip_name:

	mov	$('a'<<8+'n'),%bx
	mov	$('e'<<8+'m'),%dx
					# find 'name\t: ' and grab up to \n
					# we are little endian
	mov	$'\n',%ah
	call	find_string

	call	*%cx			# si points to ' Processor'


	#========
	# RAM
	#========

	push	 %cx

	int	 $0x12			# BIOS get SIZE OF MEMORY
		 			# in Kilobytes

	call num_to_ascii

	pop  %cx	 		# restore strcat pointer

					# si points to 'M RAM, '
	call	*%cx			# call strcat


	#========
	# Bogomips
	#========

	mov	$('i'<<8+'m'),%bx
	mov	$('s'<<8+'p'),%dx
					# find 'mips\t: ' and grab up to \n
	mov	$'\n',%ah
	call	find_string

					# si points to bogo total
	call 	*%cx			# call strcat

	mov	%bp,%dx			# point dx to out_buffer

	call	center_and_print	# center and print

	#=================================
	# Print Host Name
	#=================================

	mov     %bp,%di		  	# point to output_buffer

					# si points to host name (hardcoded)
	call    *%cx			# call strcat

	call	center_and_print	# center and print

	mov	%si,%dx			# si now points to default_colors

	call	write_stdout


	#================================
	# Exit
	#================================
exit:
	xor     %al,%al			# return 0
	mov	$0x4c,%ah		# exit
	int     $0x21             	# and exit


	#=================================
	# FIND_STRING
	#=================================
	#   ah is char to end at
	#   bx/dx is 4-char ascii string to look for
	#   di points at output buffer
	#
	#   si = saved

find_string:
	push	%si

	mov	$disk_buffer-1,%si	# look in cpuinfo buffer
find_loop:
	inc	%si
	cmpb	$0, (%si)		# are we at EOF?
	je	done			# if so, done

	cmp	(%si), %bx		# do the strings match?
	jne	find_loop		# if not, loop

	cmp	2(%si,1), %dx		# do the strings match?
	jne	find_loop		# if not, loop

					# if we get this far, we matched

find_colon:
	lodsb				# repeat till we find colon
	cmp	$0,%al			# this is actually smaller code
	je	done			#   than an or ecx/repnz scasb
	cmp	$':',%al
	jne	find_colon


skip_spaces:
        lodsb                           # skip spaces
	cmp     $0x20,%al               # Loser new intel chips have lots??
        je      skip_spaces

store_loop:
	cmp	$0,%al
	je	done
	cmp	%ah,%al			# is it end string?
	je 	almost_done		# if so, finish
	cmp	$'\n',%al		# also end if linefeed
	je	almost_done
	stosb				# if not store and continue
	lodsb				# load value
	jmp	store_loop

almost_done:

	movb	 $0, (%di)	        # replace last value with NUL
done:
	pop	%si
	ret


	#================================
	# strcat
	#================================

strcat:
	lodsb				# load a byte from [ds:esi]
	stosb				# store a byte to [es:edi]
	cmp	$0,%al			# is it zero?
	jne	strcat			# if not loop
	dec	%di			# point to one less than null
	ret				# return

	#==============================
	# center_and_print
	#==============================
	# string to center in dx (saved)
	#
	# cx,dx = saved
	# di incremented
	# ax,bx trashed


center_and_print:
	push    %dx			# save the string pointer
	mov	%dx,%bx			# copy string pointer to bx

	inc	%di			# move to a clear buffer
	push	%di			# save for later

	mov	$('['<<8+27),%ax	# we want to output ^[[
	stosw

	cdq	      			# clear dx

str_loop2:				# find end of string
	inc	%dx
	inc	%bx
	cmpb	$0,(%bx)		# repeat till we find zero
	jne	str_loop2

	mov	$80,%ax	 		# assume 80 columns

	cmp	%ax,%dx			# see if we are >=80
	jl	not_too_big		# if so, don't center

	mov	$80,%dx			# don't center by setting
					# size to 80

not_too_big:
	sub	%dx,%ax			# subtract size from 80

	shr	%ax			# then divide by 2

	call	num_to_ascii		# print number of spaces

	mov	$(('$'<<8)+'C'),%ax	# tack a 'C' and '$' to the end
	stosw				# store C and a NULL

	pop	%di			# pop the pointer to ^[[xC

	mov	%di,%dx			# move to edx

	call write_stdout		# write to the screen

	dec  	%di			# point back to end of string

	mov	$('\n'<<8)+'\r',%ax	# store carriage return
	stosw				# and linefeed

	mov	$'$',%al		# terminate with a $
	stosb

done_center:
	pop 	%dx			# restore string pointer

					# fall through to write_stdout

	#================================
	# WRITE_STDOUT
	#================================
	# ds:dx has string
write_stdout:
     	mov	$0x09,%ah		# setup write_string value
	int	$0x21	 		# Call DOS

	ret	     			# return


	#==============================
	# num_to_ascii
	#==============================
	# ax = value to print (trashed)
	# di points to where we want it
	#
	# cx = saved
	# di = incremented
	# ax,bx,dx = trashed

num_to_ascii:
	push 	%cx
	mov     $10,%bx		# set bx to 10
	xor     %cx,%cx         # clear cx
div_by_10:
	cdq                     # clear dx
	div     %bx             # divide dx:ax by 10, dx=R ax=Q
	push    %dx             # save for later
	inc     %cx             # add to length counter
	or      %ax,%ax         # was Q zero?
	jnz     div_by_10       # if not divide again

write_out:
	pop     %ax             # restore in reverse order
	add     $0x30, %al      # convert to ASCII
	stosb                   # save digit
	loop    write_out       # loop till done
	pop	%cx		# restore cx
	ret

#===========================================================================
#	section .data
#===========================================================================
.data

ver_string:	.ascii	"DOS Version \0"
compiled_string:	.ascii	", Compiled #1 Sun Oct 17 17:56:29 EDT 1980\0"
one:			.ascii	"One \0"
MHz:			.ascii  "MHz \0"
processor:		.ascii " Processor, \0"
ram_comma:	.ascii	"K RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"
node_name:	.ascii	"DOSBOX\0"
default_colors:	.ascii "\033[0m\r\n$"

.ifdef FAKE_PROC
cpuinfo:	.ascii	"proc\\cpu8.086\0"
.else
cpuinfo:	.ascii	"proc\\cpu8.086\0"
.endif

.include	"logo.lzss_new"

#============================================================================
#	section .bss
#============================================================================
#.bss

fake_bss:

#.lcomm  text_buf, (N+F-1)
.equ    text_buf,fake_bss
#.lcomm	out_buffer,16384
.equ    out_buffer,text_buf+(N+F-1)
#.lcomm	disk_buffer,4096	# we cheat!!!!
.equ	disk_buffer,out_buffer+4096

