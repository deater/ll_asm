#
#  linux_logo in ix86 assembler 0.12
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

#  WARNING:  uses undocumented SALC opcode

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

	mov 	$text_buf, %edi		# fill "text_buf" with most common char
	mov 	$FREQUENT_CHAR, %al     # frequent char is '#' in default logo

	mov 	$(N-F), %cx
	mov 	%ecx, %ebp
	rep 	
	stosb

	mov  	$logo, %esi
	mov	$out_buffer, %edi

decompression_loop:	

    	test	$0x2,%bh	# if 0, we shifted through 8 and must re-load
	jne 	test_flags     	# if not move on with things

	call 	read_byte	# load in a byte

	mov 	$0xff, %bh	# re-load top as a counter
	mov 	%al, %bl	# move in the flags

test_flags:
	rcr 	$1, %bx		# rotate bottom bit into carry flag
	jnc 	offset_length	# if one,  jump to offset_length

discreet_char:
	call  	read_byte		# get byte
	stosb				# store it	
	mov    	%al, text_buf(%ebp)	# move byte to text_buf[r]
	inc 	%ebp 			# r++
	and 	$(N-1), %ebp		# mask it
	jmp 	decompression_loop	# keep going

offset_length:

	call  	read_byte	# get first byte (ch1)
	mov 	%al, %dl	# move to dl

	call 	read_byte	# get next byte  (ch2)
	
	shl 	$4, %eax		# pointer is top 4bits of ch2 bottom 8 of ch1
	mov 	%ah, %dh 	# aka dx|=(al&0xf0)<<4;

	shr	$4, %al		# trick to mask off top 4bits (sams as and 0xf)
	mov	%al,%cl		# counter is bottom 4 of ch2 + THRESHOLD
	inc 	%ecx  		# add $THRESHOLD, %ebp (assume THRESHOLD=2)
	inc 	%ecx
	inc	%ecx		# and loop once more so the loop works out
	
output_loop:
	and 	$(N-1), %edx		# mask it
	mov 	text_buf(%edx), %al	# load byte from text_buf[]
	inc 	%edx	    		# advance pointer in text_buf
	stosb				# store it
	
	mov     %al, text_buf(%ebp)	# store also to text_buf[r]
	inc 	%ebp 			# r++
	and 	$(N-1), %ebp		# mask r

	loop 	output_loop		# repeat until k>j
	
	jmp 	decompression_loop

read_byte:
	lodsb				# load a byte
	cmp $logo_end, %esi		# have we reached the end?
	je done_logo   			# if so, exit
	ret

# end of LZSS code

done_logo:
	mov	$out_buffer,%ecx	# our nice huge logo
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
	cdq				# clear edx in clever way
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

	mov	$' ',%al		# print a space
	stosb


	#=========
	# MHz
	#=========
print_mhz:
	mov	$('z'<<24+'H'<<16+'M'<<8+' '),%ebx	
			   		# find ' MHz\t: ' and grab up to .
	                                # we are little endian
	mov	$'.',%dl			
   	call	find_string
 
	mov	$(' '<<24+'z'<<16+'H'<<8+'M'),%eax	
	stosl	    			# cheat and print MHz a little
					# faster
    
   	#=========
	# Chip Name
	#=========
chip_name:	
   	mov	$('e'<<24+'m'<<16+'a'<<8+'n'),%ebx     	
					# find 'name\t: ' and grab up to \n
       					# we are little endian
	mov	$0xa,%dl
	call	find_string

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
	
	mov	$0xa,%ax		# and line feed and zero
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
	
	mov 	$out_buffer,%ecx		
	call	write_stdout

	mov	$default_colors,%ecx	# print two linefeeds and color
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
	
	# old strlen()
	cdq   	      			# clear edx
str_loop1:
	inc	%edx
	cmpb	$0,(%ecx,%edx)		# repeat till zero
	jne	str_loop1

	int	$0x80  			# run the syscall
	ret


	#=================================
	# NUM_TO_ASCII
	#=================================
	# al has number
	# output [edi]
	# trashed eax,ebx,ecx,edx

num_to_ascii:	

	push	 $10
	pop	 %ebx		# we will divide by 10
	xor	 %ecx,%ecx	# clear ecx
		
div_by_10:	
	cdq			# clear edx
	div	 %ebx		# divide
	
	add	 $0x30,%dl	# convert to ascii
	push	 %edx		# save for later
	inc	 %ecx		# add to length counter
	
        or	 %eax,%eax	# was Q zero?
       	jnz	 div_by_10	# if not divide again
	
write_out:
	pop	 %eax		# restore in reverse order
	stosb	     		# save digit
	loop     write_out	# loop till done

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
	lodsl				# load 32 bits (lodsd)	
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
	
	# use undocumented SALC (.byte 0xD6) opcode here
	# since come from cmp; je we know carry=0
	
	.byte 0xD6   	       	     	# replace last value with null
	
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

	#==============================
	# center
	#==============================

	
center:
#        call	strlen

	cdq	      			# clear dx
str_loop2:	
	inc	%edx
	cmpb	$0,(%ecx,%edx)		# repeat till we find zero
	jne	str_loop2
	
	push	$80
	pop	%ebp
	
	cmp	%ebp,%edx		# see if we are >=80
	jge	done_center		# if so, bail
	
	sub	%edx,%ebp		# subtract size from 80
	
	shr	%ebp			# then divide by 2
	mov 	$space,%ecx		# load in a space
	
center_loop:
	call 	write_stdout		# and print that many spaces
	dec	%ebp
	jnz	center_loop
done_center:	
	ret


#===========================================================================
#	section .data
#===========================================================================
.data

.include	"logo.lzss"

ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
.equ	comma,ram_comma+5
.equ	space,ram_comma+6
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"

default_colors:	.ascii "\033[0m\n\n\0"

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

.lcomm  text_buf, (N+F-1)       # these two buffers must follow one after the other!
.lcomm	out_buffer,16384

.lcomm	disk_buffer,4096	# we cheat!!!!


   # see /usr/src/linux/include/linux/kernel.h
.lcomm sysinfo_buff,(64)
.lcomm uname_info,(65*6)
