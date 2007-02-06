!
!  linux_logo in sparc assembler    0.18
!
!  Should in theory work for both sparc32 and sparc64
!
!  by Vince Weaver <vince _at_ deater.net>
!
!  assemble with     "as -o ll.o ll.sparc.s"
!  link with         "ld -o ll ll.o"

! Things to remember about SPARC assembly:	
!     + Has a branch delay slot!  The annul bit can cancel that.
!     + Comments are the "!" character
!     + Syscalls have number in %g0, options in %o0,%o1,...
!	Result returned in %o0
!	Linux syscall is called by "ta 0x10"
!     + %g0 - %g7 regs always visible
!	%g0 is always read as 0	
!	Windowed registers:	8 in registers %i0..%i7
!				8 local registers %l0..%l7
!				8 out registers %o0..%o7
!	When move up a window, the outs become the ins  SAVE/RESTORE instr
!     + Call instruction writes to %o7
!     + Condition codes:	 xcc = 64 bit, icc= 32 bit nzvc
			
! FIXME:	 use register windows
!		 optimize the divide routine
!		 use branch delay slots
		
! offsets into the results returned by the uname syscall
.equ U_SYSNAME,0
.equ U_NODENAME,65
.equ U_RELEASE,65*2
.equ U_VERSION,(65*3)
.equ U_MACHINE,(65*4)
.equ U_DOMAINNAME,65*5

! offset into the results returned by the stat syscall
.equ S_SIZE,32

! syscall numbers

.equ SYSCALL_EXIT,1	
.equ SYSCALL_READ,3
.equ SYSCALL_WRITE,4
.equ SYSCALL_CLOSE,6
.equ SYSCALL_OPEN,5
.equ SYSCALL_STAT,38
.equ SYSCALL_UNAME,189

!
.equ STDIN,0
.equ STDOUT,1
.equ STDERR,2	

	
	.globl _start
_start:
		
        !=========================
	! PRINT LOGO
	!=========================
	
	set	new_logo,%i4	  	! point input to new_logo
	set	out_buffer,%i3		! point output to buffer
	mov	%i3,%i2			! save pointer to begin of output

main_logo_loop:
	ldub	[%i4],%g6		! load character
	inc	%i4			! update pointer
	cmp	%g6,0
	be	done_logo		! if zero, we are done
	nop				! branch delay slot!
	
	cmp	%g6,27			! if ^[, we are a color
        bne	blit_repeat		! if not go to the RLE blit
	nop
	
	mov	27,%g7			! output ^[[ to buffer
	stb	%g7,[%i3]
	inc	%i3
	mov	'[',%g7
	stb	%g7,[%i3]
	inc	%i3

	ldub	[%i4],%g6		! load number of ; separated elements 
	inc	%i4			! update pointer
		
element_loop:
        ldub	[%i4],%g4		! load color
	inc	%i4			! update pointer

	call	num_to_ascii		! convert byte to ascii decimal
	nop				! branch delay

	mov	';',%g4
	stb	%g4,[%i3]		! load ';'
	inc	%i3			! and output it
	
	subcc	%g6,1,%g6		! decrement counter
	bne	element_loop		! loop if elements left
	nop
	
	dec	%i3			! remove extra ';'
	
	ldub	[%i4],%g6		! load last char
	inc	%i4

	stb	%g6,[%i3]		! save last char
	inc	%i3
	
	ba 	main_logo_loop		! done with color
	nop				! branch delay slot
	
blit_repeat:
	ldub	[%i4],%g7		! get times to repeat
	inc	%i4			! increment pointer
blit_loop:	
	stb	%g6,[%i3]		! write character
	inc	%i3
	subcc	%g7,1,%g7 		! decrement counter
	bne	blit_loop		! if not zero, loop
	nop				! delay slot
	
	ba	main_logo_loop
	nop				! branch delay slot
	
done_logo:	
	mov	SYSCALL_WRITE,%g1	! number of the "write" syscall
	mov	STDOUT,%o0		! stdout
	mov	%i2,%o1			! output_buffer pointer
	call	strlen			! get length of string
	nop				! branch delay
	ta	0x10	           	! do syscall

	set	line_feed,%o1		! print line feed
	call	put_char
	nop
	
	!==========================
	! PRINT VERSION
	!==========================

	mov	SYSCALL_UNAME,%g1   	! uname syscall
	set	uname_info,%o0		! uname struct
	ta	0x10			! do syscall
	
	mov	%i2,%i3			! restore output to out_buffer

	set	uname_info,%i5
	
	add	%i5,U_SYSNAME,%i4	! os-name from uname "Linux"
	call	strcat
	nop
	
	set	ver_string,%i4		! source is " Version "
	call	strcat
	nop
	
	add	%i5,U_RELEASE,%i4    	! version from uname "2.4.1"
	call	strcat
	nop
	
	set	compiled_string,%i4	! source is ", Compiled "
	call	strcat
	nop
	
	add	%i5,U_VERSION,%i4	! compiled date
	call	strcat
	nop
	
	mov	%i2,%o1  		! restore saved location of out_buff
	
	call	strlen			! returns size in $18
	nop
	call	center			! print some spaces
	nop
	mov	SYSCALL_WRITE,%g1	! write out the buffer
	mov	STDOUT,%o0
	mov	%i2,%o1
	call	strlen
	nop
	ta	0x10

	set	line_feed,%o1		! print line feed
	call	put_char
	nop

	!===============================
	! Middle-Line
	!===============================

	mov	%i2,%i3			! restore output pointer
		
	!=========
	! Load /proc/cpuinfo into buffer
	!=========

	mov	SYSCALL_OPEN,%g1	! open()
	set	cpuinfo,%o0		! '/proc/cpuinfo'
	clr	%o1			! O_RDONLY <bits/fcntl.h>
	ta	0x10			! syscall.  fd in o0

	mov	%o0,%o5			! save fd in %o5
	
	mov	SYSCALL_READ,%g1	! read
	mov	%o5,%o0			! copy fd
	set	disk_buffer,%o1
	mov	4096,%o2	 	! 4096 is upper-limit guess of procfile
	ta	0x10

	mov	%o5,%o0			! restore fd
	mov	SYSCALL_CLOSE,%g1	! close
	ta	0x10

	!=============
	! Number of CPU's
	!=============
	
	set	disk_buffer,%g2		! look in cpuinfo buffer
	mov	'i',%o0			! find 'ive' and grab after ':'
	mov	'v',%o1
	mov	'e',%o2
	mov	'\n',%o3
		
	mov	%i3,%i6			! save output
	set	string_buffer,%i3	! load temp pointer
   	call	find_string
	nop
	mov	%i6,%i3			! restore output

	set	string_buffer,%o0	! convert ascii to decimal
	call	ascii_to_num	
	nop

	! Assume <=4 CPU's
	! have to learn how to do arrays on SPARC

	cmp	%o0,4
	bne	check_three
	nop
	
	set	four,%i4
	ba	print_num_cpu
	nop
	
check_three:		
	cmp	%o0,3
	bne	check_two
	nop
	
	set	three,%i4
	ba	print_num_cpu
	nop
	
check_two:
	cmp	%o0,2
	bne	check_one
	nop
	
	set	two,%i4
	ba	print_num_cpu
	nop
	
check_one:	
	set  	one,%i4
print_num_cpu:		
	call	strcat
	nop
	
	!=========
	! MHz  Note.. not available on my SparcStation5?
	!=========
	
!	ldi	$17,'c'			# find 'cycl' and grab after ':'
!	ldi	$18,'y'
!	ldi	$19,'c'
!	ldi	$20,':'
!	mov	$10,$14			# save output
!	lda	$10,string_buffer	# load temp pointer
!   	br	$26,find_string
!	mov	$14,$10			# restore output

!	lda	$16,string_buffer	# convert string to a long
!	br	$26,ascii_to_num

!	mov	$17,$16			# divide by 1 million
!	ldi	$17,1000000
!	br	$26,divide
	
!	mov	$18,$16			# convert back to ascii-decimal
!	br	$26,num_to_ascii
	
	set	megahertz,%i4		! print 'SPARC '
	call	strcat
	nop
   
   	!=========
	! Chip Name
	!==========
	set	disk_buffer,%g2		! look in cpuinfo buffer
	mov     'c',%o0			! find 'cpu' and grab  after :
	mov	'p',%o1
	mov	'u',%o2
	mov	'\n',%o3
	call	find_string
	nop
	
	set	comma,%i4		! print ', '
	call	strcat
	nop
	
	!========
	! RAM  --- stat of /proc/kcore doesn't work on SPARC
	!          use alternative methods
	!========

	mov	SYSCALL_OPEN,%g1	! open()
	set	meminfo,%o0		! '/proc/cpuinfo'
	clr	%o1			! O_RDONLY <bits/fcntl.h>
	ta	0x10			! syscall.  fd in o0

	mov	%o0,%o5			! save fd in %o5
	
	mov	SYSCALL_READ,%g1	! read
	mov	%o5,%o0			! copy fd
	set	mem_buffer,%o1
	mov	4096,%o2	 	! 4096 is upper-limit guess of procfile
	ta	0x10

	mov	%o5,%o0			! restore fd
	mov	SYSCALL_CLOSE,%g1	! close
	ta	0x10

	set	mem_buffer,%g2		! look in cpuinfo buffer	
	mov	'm',%o0			! find 'mTo' and grab after ':'
	mov	'T',%o1
	mov	'o',%o2
	mov	' ',%o3
		
	mov	%i3,%i6			! save output
	set	string_buffer,%i3	! load temp pointer
   	call	find_string	
	nop

	mov	%i6,%i3			! restore output

	set	string_buffer,%o0	! convert ascii to decimal
	call	ascii_to_num	
	nop
				
	sra	%o1,10,%o1		! divide to get M

	mov	%o1,%g4			! convert to ascii
	call	num_to_ascii
	nop
	
	set	ram_comma,%i4		! print 'M RAM, '
	call	strcat
	nop
	
	!========
	! Bogomips
	!========
	set	disk_buffer,%g2		! look in cpuinfo buffer	
	mov	'i',%o0      		! find 'IPS' and grab up to \n
	mov	'p',%o1
	mov	's',%o2
	mov	'\n',%o3
	call	find_string
	nop
	
	set	bogo_total,%i4
	call	strcat
	nop

	mov	%i2,%o1  		! restore saved location of out_buff
	
	call	strlen			! returns size in $18
	nop
	call	center			! print some spaces
	nop
	
	mov	SYSCALL_WRITE,%g1	! write the buffer out
	mov	STDOUT,%o0
	mov	%i2,%o1
	call	strlen
	nop
	ta	0x10
	
	set	line_feed,%o1		! print line feed
	call	put_char
	nop

	
	!=================================
	! Print Host Name
	!=================================

	add	%i5,U_NODENAME,%o1	! print node name

	call	strlen			! center
	nop
	call	center
	nop
	
	mov	SYSCALL_WRITE,%g1	! write it out
	mov	STDOUT,%o0
	set	uname_info,%o1
	add	%o1,U_NODENAME,%o1
	call	strlen
	nop
	ta	0x10

	mov	SYSCALL_WRITE,%g1	! restore default colors
	mov	STDOUT,%o0
	set	default_colors,%o1
	call	strlen
	nop
	ta	0x10

	set	line_feed,%o1		! print line feed
	call	put_char
	nop
	call	put_char
	nop
	
	!================================
	! Exit
	!================================
	
        mov	0,%o0			! exit value
        mov	SYSCALL_EXIT,%g1        ! put the exit syscall number in v0
        ta      0x10			! and exit


	!=================================
	! Divide
	! yes this is an awful algorithm, but simple
	! and uses few registers
	!=================================
	!  o1 =numerator o2=denominator
	!  o3 =quotient  o4=remainder
	
divide:
	clr	%o0			! zero out top of numerator
	udiv	%o1,%o2,%o3		! divide o0o1/o2
after_divide:	
	umul	%o2,%o3,%o0		! multiply quotient times denom
	sub	%o1,%o0,%o4		! subtrace result from numer for R
divide_done:		
	retl
	nop
	

	!=================================
	! FIND_STRING 
	!=================================
	!   %o0,%o1,%o2 are 3-char ascii string to look for
	!   %o3 is char to stop at
	!   %i3 points at output buffer
	!   %g2=buffer
find_string:
						
find_loop:
	ldub	[%g2],%g3		! watch for first char
	inc	%g2
	cmp	%g3,0
	be	done
	nop
	
	cmp	%g3,%o0
	bne	find_loop
	nop
	
	ldub	[%g2],%g3		! watch for second char
	inc	%g2
	cmp	%g3,%o1
	bne	find_loop
	nop
	
	ldub	[%g2],%g3		! watch for third char
	inc	%g2
	cmp	%g3,%o2
	bne	find_loop
	nop
	
					! if we get this far, we matched
find_colon:
	ldub	[%g2],%g3		! repeat till we find colon
	inc	%g2
	
	cmp	%g3,0
	be	done
	nop
	
	cmp	%g3,':'
	bne	find_colon
	nop
skip_spaces:	
	ldub	[%g2],%g3
	cmp	%g3,' '
	bne	store_loop
	nop
	inc	%g2
	ba	skip_spaces
	nop
	
store_loop:	 
	ldub	[%g2],%g3
	inc	%g2

	cmp	%g3,0
	be	done
	nop
	
    	cmp	%g3,%o3			! is it end string?
	be 	almost_done		! if so, finish
	nop
	
	stb	%g3,[%i3]		! if not store and continue
	inc	%i3
	ba	store_loop
	nop
	
almost_done:	 
	stb	%g0,[%i3]		! replace last value with null

done:
	retl
	nop

	!================================
	! put_char
	!================================
	! output value at %o1

put_char:
	mov	SYSCALL_WRITE,%g1	! number of the "write" syscall
	mov	STDOUT,%o0		! stdout
	mov	1,%o2			! 1 byte to output
	ta	0x10			! do syscall
	retl
	nop
	

	!================================
	! strcat
	!================================
	! %g2 = "temp"
	! %i4 = "source"
	! %i3 = "destination"
strcat:
	ldub	[%i4],%g2		! load a byte from %i4
	inc	%i4
	stb	%g2,[%i3]		! store a byte to %i3
	inc	%i3

	cmp	%g2,0
	bne	strcat			! if not zero, loop
	nop
	
	dec	%i3			! back up pointer to the zero
	retl
	nop
	
	!===============================
	! strlen
	!===============================
	! %o1 points to string
	! %o2 is returned with length
	! %g2,%g3 are trashed
	! %o7 has return address
	
strlen:
	mov	%o1,%g2			! copy pointer
	clr	%o2			! set count to 0
str_loop:
	inc	%g2			! increment pointer
	inc	%o2			! increment counter
	ldub	[%g2],%g3		! load byte
	cmp	%g3,0
	bne	str_loop		! is it zero? if not, loop
	nop				! branch delay
	retl				! return
	nop				! branch delay
		
	!==============================
	! center
	!==============================
	! %o2 has length of string
	! %g1,%o1,%o2,%o3 changed
	! %g2=temp
	! %g3 stores return address
		
center:
	mov	%o7,%g3			! save return address
	cmp	%o2,80			! see if we are >80
	bgt	done_center		! if so, bail
	nop
	
	mov	80,%g2			! 80 column screen
	sub	%g2,%o2,%g2		! subtract strlen
	sra	%g2,1,%g2		! divide by two
	set	space,%o1		! load pointer to space		
center_loop: 
	call 	put_char		! and print that many spaces
	nop
	subcc	%g2,1,%g2
	bne	center_loop
	nop
done_center:	
	mov	%g3,%o7			! restore return address
	retl
	nop	


	!===========================
	! ascii_to_num
	!===========================
	! %o0=string
	! %o1=result
	! %g2=temp
ascii_to_num:
	clr	%o1			! zero result
ascii_loop:		
	ldub	[%o0],%g2		! load value
	inc	%o0

	cmp	%g2,0
	be	ascii_done
	nop
	
	umul	%o1,10,%o1		! shift decimal left
	sub	%g2,0x30,%g2		! convert ascii->decimal
	add	%g2,%o1,%o1		! add it in
	ba	ascii_loop
	nop
ascii_done:			
	retl
	nop
	
	!===========================
	! num_to_ascii
	!===========================
	! %g4=num
	! %i3=output
	! %g2,%g3=temp
	! %g1=saved return value
		
num_to_ascii:
	mov	%o7,%g1			! save return value

	set	string_buffer,%g2	! load buffer		
	add	%g2,63,%g2		! start at end of string
	stb	%g0,[%g2]		! make sure trailing zero
	dec	%g2			! we work backwards

num_loop:
	mov	%g4,%o1
	mov	10,%o2			! we divide by 10 always
	call	divide
	nop

	cmp	%o3,0			! if remainder and quotient zero
	bne	keep_dividing		! then we are done shifting
	nop
	cmp	%o4,0
	bne	keep_dividing
	nop
	ba	num_done
	nop
	
keep_dividing:		

	add	%o4,0x30,%o4		! convert to ascii
	stb	%o4,[%g2]		! and store to buffer
	dec	%g2			! move to left
	mov	%o3,%g4
	ba	num_loop
	nop
num_done:		
	inc	%g2			! done, but re-adjust pointer
num_loop2:		
	ldub	[%g2],%g4		! write out the buffer
	inc	%g2
	cmp	%g4,0
	be	num_all_done
	nop
	stb	%g4,[%i3]
	inc	%i3
	ba	num_loop2
	nop
num_all_done:		
	mov	%g1,%o7			! restore return value
	retl
	nop
			
!===========================================================================
!.data
!===========================================================================

.include "logo.inc"

line_feed:	.ascii  "\n"
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
space:		.ascii	" \0"
megahertz:	.ascii	"SPARC \0"
comma:		.ascii	", \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"

default_colors:	.ascii	"\033[0m\0"

cpuinfo:	.ascii	"/proc/cpuinfo\0"
meminfo:	.ascii	"/proc/meminfo\0"
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
	! urgh get above from /usr/src/linux/include/asm/stat.h
	! not glibc

.lcomm uname_info,(65*6)

.lcomm	string_buffer,64
	
.lcomm	disk_buffer,4096	! we cheat!!!!
.lcomm	mem_buffer,4096		! we cheat!!!!
.lcomm	out_buffer,16384	! we cheat, 16k output buffer





