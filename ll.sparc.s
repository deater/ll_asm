!
!  linux_logo in sparc assembler    0.48
!
!  Should in theory work for both sparc32 and sparc64
!    but actually written as pure SPARCV8 I think
!    Possible optimizations if we make it v8plus?
!
!  by Vince Weaver <vince _at_ deater.net>
!
!  assemble with     "as -o ll.o ll.sparc.s"
!  link with         "ld -o ll ll.o"

! Things to remember about SPARC assembly:
!     + Instruction are OPCODE SOURCE1,SOURCE2,DESTINATION
!     + Only a 13-bit immediate field	
!     + Has a branch delay slot!  The annul bit can cancel that.
!       annul on conditional branches only annuls when not-taken
!     + Comments are the "!" character
!     + Syscalls have number in %g1, options in %o0,%o1,...
!	Result returned in %o0
!	Linux syscall is called by "ta 0x10"
!     + See "Sparc Application Binary Interface"	
!     + %g0 - %g7 regs always visible.  g5,g6,g7 reserved for kernel
!	%g0 is always read as 0	
!	Windowed registers:	8 in registers %i0..%i7
!				8 local registers %l0..%l7
!				8 out registers %o0..%o7
!	When move up a window, the outs become the ins  SAVE/RESTORE instr
!       The save and restore instructions can act also as ADD instructions
!       for the stack... you must save room for at least 16 words on stack.
!	(this is to hold space for reg window in case of overflow.
!	(stack also must be double-word aligned.  96 bytes is safe...)
!     + Call instruction writes to %o7
!     + %o6 is the stack pointer	
!     + Condition codes:	 xcc = 64 bit, icc= 32 bit nzvc
			
! FIXME:
!		 optimize the divide routine

!
! %asi alternate access spaces.  Above 0x80 is user-space.
!    Some useful ones: little-endian accesses, block-memory moves
! faligndata instruction is VIS (SIMD) instruction.
!
! Floating point regs are done a bit odd (and gdb confuses it more)
!   f0-f31 are single precision
!   d0-d30 (even only) are double precision.  d0-d15 are equiv
!         to f0/f1, f2/f3, f4/f5, etc
!
! On v9, branches can be against icc or xcc
!   also {,a} indicates annulled (if taken, always execute delay.
!        otherwise, annul it)
!   also {,pn,pt} predict not taken or taken

! Initial size 1397
! ============================================================================
! Further optimizations by Magnus Hjorth (mhjorth@gaisler.com), summary:
!   * In the LZSS decoder, instead of OR:ing in 0xff00 and then testing the top
!     8 bits, OR in 0x100 and test if less than 2, this can be done without
!     precomputed constant. (1388)
!   * You can get the constant +4096 by doing "sub %g0,-4096,%reg"
!   * Use sethi to get a pointer 4K into the address space, then add from
!     that to get any address within 0..8K. This scheme is not supported by the
!     assembler/linker interface so we have to manually manage a symbol for each
!     section which we know in advance ends up at address 0x1000. (1361)
!   * For ba instructions, you can use ba,a to get rid of delay slot
!   * For some branches, if the first instruction in the untaken path does not
!     affect the taken path (for example sets a register or cond code that
!     is overwritten before use) we can let it be in the delay slot (1361)
!   * Use the annul bit on conditional branches to skip the delay slot in the
!     untaken case, allows us to avoid post-decrementing counter after loop in
!     some cases (1349)
!   * Optimize center_and_print with delay slot tricks (1337 (!?))
!   * Tail recursion for center_and_print/write_stdout (1329)
!   * Tail recursion for num_to_ascii (1305)
!   * Re-optimize find_string to use sliding window, tail recursion (1261)
!
! Newer Linux toolchains generate an extra sections with PAX_FLAGS and put
! text and data/bss on a separate page (for no-execute protection),
! to avoid this overhead a custom linker script like below can be used:
!
! PHDRS { load PT_LOAD ; }
! SECTIONS
! {
!  PROVIDE (__executable_start = SEGMENT_START("text-segment", 0x10000));
!  . = SEGMENT_START("text-segment", 0x10000) + SIZEOF_HEADERS;
!  .text  : { *(.text) } :load =0
!  .data  : { *(.data) } :load =0
!  .bss   : { *(.bss) *(COMMON) } :load
! }
!
! ============================================================================


! offsets into the results returned by the uname syscall
.equ U_SYSNAME,0
.equ U_NODENAME,65
.equ U_RELEASE,65*2
.equ U_VERSION,(65*3)
.equ U_MACHINE,(65*4)
.equ U_DOMAINNAME,65*5

! struct sysinfo {
! long uptime,loads[3],totalram,...;
.equ S_TOTALRAM,4*4
	
! offset into the results returned by the stat syscall
.equ S_SIZE,32

! syscall numbers

.equ SYSCALL_EXIT,1	
.equ SYSCALL_READ,3
.equ SYSCALL_WRITE,4
.equ SYSCALL_CLOSE,6
.equ SYSCALL_OPEN,5
.equ SYSCALL_UNAME,189
.equ SYSCALL_SYSINFO,214

!
.equ STDIN,0
.equ STDOUT,1
.equ STDERR,2	

! Symbol that points to absolute address 0x11000 in each segment
.equ data_ref,     0x11000
.equ bss_ref,      0x11000
       
.include "logo.include"
	
	.globl _start
_start:
		
        !=========================
	! PRINT LOGO
	!=========================

# LZSS decompression algorithm implementation
# by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
# optimized some more by Vince Weaver

	sethi	%hi(data_ref),%g2		! point %g2 at data_ref/bss_ref
	add	%g2,(out_buffer-bss_ref),%g4	! point %g4 to out_buffer

	add	%g2,(text_buf-bss_ref),%g3	! point %g3 to text_buf

	set	(N-F),%l6		! R
 	       
	add	%g2,(logo-data_ref),%l7		! %l7 points to logo
	add	%g2,(logo_end-data_ref),%l5	! %l5 points to end of logo

	mov	%g4,%l4				! point %l4 to out_buffer

decompression_loop:	
	ldub	[%l7],%l3	! load in a byte
	inc	%l7		! increment source pointer

				! put 0x01 in top as a hackish 8-bit counter
	or	%l3,0x100,%l2	! move in the flags

check_ctr:
	cmp	%l2,2
	bl	decompression_loop
	! BRANCH DELAY SLOT
	! nop removed, following cmp harmless in taken case

test_flags:
	cmp	%l5,%l7		! have we reached the end?	
	be	done_logo	! if so, exit
	# BRANCH DELAY SLOT
	! nop delay slot removed, btst harmless in taken case
	
	btst	0x1,%l2		! test to see if discrete char
	
	bnz	discrete_char	! if set, we jump to discrete char
	
	! BRANCH DELAY SLOT
	srl     %l2,1,%l2	! shift

offset_length:
	ldub	[%l7],%l3	! load 16-bit length and match_position combo
	ldub    [%l7+1],%l1	! can't use lhu because might be unaligned
	add	%l7,2,%l7	! increment source pointer
	sll     %l1,8,%l1
        or      %l1,%l3,%l1

	srl	%l1,P_BITS,%l0	! get the top bits, which is length

	add	%l0,THRESHOLD+1,%l0
				! add in the threshold?

output_loop:	
	and	%l1,(POSITION_MASK<<8+0xff),%l1
				! get the position bits
	
	ldub	[%l1+%g3],%l3              
				! load byte from text_buf[]
	inc	%l1             ! advance pointer in text_buf
	
store_byte:	
	stb	%l3,[%l4]
	inc	%l4		! store byte to output buffer
	
	stb	%l3, [%l6+%g3]	! store also to text_buf[r]
	inc	%l6		! r++
	
	
	deccc   %l0		! decrement count
	bnz	output_loop	! repeat until k>j
	#BRANCH DELAY SLOT
	and	%l6,(N-1),%l6	! wrap r if we are too big

	ba,a	check_ctr
	# BRANCH DELAY SLOT
	! nop annulled

discrete_char:	
	ldub	[%l7],%l3
	inc	%l7			! load a byte
	ba	store_byte		! and store it
	# BRANCH DELAY SLOT
	set	1,%l0			! force a one-byte output

done_logo:
	call	write_stdout		! print the logo
	# BRANCH DELAY SLOT
        mov	%g4,%o0			! point %o0 to out_buffer
			
first_line:
	!==========================
	! PRINT VERSION
	!==========================

	mov	SYSCALL_UNAME,%g1	! uname syscall in %g1
	add	%g2,(uname_info-bss_ref),%o0		
					! destination of uname in %o0
	ta	0x10			! do syscall
	
	mov	%g4,%o5			! point %o5 to out_buffer

	call	strcat
	# BRANCH DELAY SLOT
	add	%g2,((uname_info-bss_ref)+U_SYSNAME),%o0

					! source is " Version "	
	call	strcat
	# BRANCH DELAY SLOT
	add	%g2,(ver_string-data_ref),%o0

					! version from uname, ie "2.4.1"
	call	strcat
	# BRANCH DELAY SLOT
	add	%g2,((uname_info-bss_ref)+U_RELEASE),%o0

					! source is ", Compiled "
	call	strcat
	# BRANCH DELAY SLOT
	add	%g2,(compiled_string-data_ref),%o0	

					! compiled date
	call	strcat
	# BRANCH DELAY SLOT
	add	%g2,((uname_info-bss_ref)+U_VERSION),%o0	

	call	center_and_print	! center and print
	sub     %o5,%g4,%o2		! branch delay slot
	

	!===============================
	! Middle-Line
	!===============================
middle_line:
	
	mov	%g4,%o5			! restore output pointer
		
	!=========
	! Load /proc/cpuinfo into buffer
	!=========

	mov	SYSCALL_OPEN,%g1	! open()
	add	%g2,(cpuinfo-data_ref),%o0		
					! '/proc/cpuinfo'
	clr	%o1			! O_RDONLY <bits/fcntl.h>
	ta	0x10			! syscall.  fd in o0

	mov	%o0,%l0			! save fd in %l0
	
	mov	SYSCALL_READ,%g1	! read()
	mov	%l0,%o0			! copy fd
	add	%g2,(disk_buffer-bss_ref),%o1
	sub	%g0,-4096,%o2		! assume less than 4kB cpuinfo file
					! (note trick to assign 4096)
	ta	0x10

	mov	%l0,%o0			! restore fd
	mov	SYSCALL_CLOSE,%g1	! close
	ta	0x10

	!=============
	! Number of CPU's
	!=============
	set	('t'<<24+'i'<<16+'v'<<8+'e'),%o0
	                                ! find 'tive\t:' and grab up to '\n'
	
	call	find_string
	# BRANCH DELAY SLOT
	set	'\n',%o1

	sub	%o5,%g4,%l0		! see how long #cpus is
	cmp	%l0,1
	bne	more_than_one
	# BRANCH DELAY SLOT
	! nop skipped (unneccessary but harmless ldub)
	
	ldub	[%g4],%l1		! see if we have one cpu
	cmp	%l1,'1'
	bne	more_than_one
	# BRANCH DELAY SLOT

	mov	%g4,%o5			! restore output pointer
	
					! print "One, "
	call	strcat
	# BRANCH DELAY SLOT
	add	%g2,(one-data_ref),%o0
	
	ba	print_mhz
	# BRANCH DELAY SLOT
	mov	1,%l6
	
	
more_than_one:
	mov	' ',%l6
	stb	%l6,[%o5]		! store a space
	inc	%o5			! increment pointer if not plural
	mov	0,%l6
		

        !=========
	! MHz
	!=========
print_mhz:	
	! Mips /proc/cpuinfo does not indicate MHz
		

   	!==========
	! Chip Name
	!==========
	
	set	('c'<<24+'p'<<16+'u'<<8+'\t'),%o0
	                                ! find 'cpu\t:' and grab up to '\n'

	call	find_string
	# BRANCH DELAY SLOT
	set	'\n',%o1

					! print "Processor"
	call	strcat
	# BRANCH DELAY SLOT
	add	%g2,(processor-data_ref),%o0


	add	%g2,(comma-data_ref),%o0
	call	strcat
	# BRANCH DELAY SLOT
	add	%o0,%l6,%o0
	
	

	!========
	! RAM
	!========
ram:
	set	SYSCALL_SYSINFO,%g1	! sysinfo() syscall
	add	%g2,(sysinfo_buff-bss_ref),%o0
					! point to sysinfo buffer
	ta	0x10

	add	%g2,(sysinfo_buff-bss_ref),%o0	
	ld	[%o0+S_TOTALRAM],%o0

	srl	%o0,20,%o0		! divide by 2**20 to get amount
	
	call	num_to_ascii
	# BRANCH DELAY SLOT
	set	1,%o1			! use strcat ,not stdout

					! print 'M RAM, '
	call	strcat                  ! call strcat
	add	%g2,(ram_comma-data_ref),%o0
	
	!========
	! Bogomips
	!========
	set	('B'<<24+'o'<<16+'g'<<8+'\o'),%o0
	                                ! find 'Bogo' and grab up to '\n'
	
	call	find_string
	# BRANCH DELAY SLOT
	mov	'\n',%o1
	
					! bogo total follows RAM
	call	strcat			! call strcat
	# BRANCH DELAY SLOT
	add	%g2,(bogo_total-data_ref),%o0
	
	call	center_and_print	! center and print
	# BRANCH DELAY SLOT
	sub     %o5,%g4,%o2		! branch delay slot

	
	!=================================
	! Print Host Name
	!=================================
last_line:
	mov	%g4,%o5			! restore pointer to out_buffer

					! host name from uname()
	call	strcat                  
	# BRANCH DELAY SLOT
	add	%g2,(uname_info-bss_ref)+U_NODENAME,%o0

	call	center_and_print        ! center and print
	# BRANCH DELAY SLOT
	sub     %o5,%g4,%o2		! branch delay slot

					! (.txt) pointer to default_colors
	call	write_stdout
	# BRANCH DELAY SLOT
	add	%g2,(default_colors-data_ref),%o0

	!================================
	! Exit
	!================================
exit:		
        mov	0,%o0			! exit value
        mov	SYSCALL_EXIT,%g1        ! put the exit syscall number in g1
        ta      0x10			! and exit



	!=================================
	! FIND_STRING 
	!=================================
	!   %o0 is the 4-char ascii string to look for
	!   %o1 is char to stop at

	! The code does a sliding window through the disk buffer
	!  Bringing in one byte at a time and then shifting it left for compare
	!  It does depend on 4 consecutive zeroes at end of disk buffer
	!  Maybe should only read in 4091 bytes from cpuinfo file?

find_string:
	add	%g2,(disk_buffer-bss_ref)-4,%l2
					! set up disk_buffer pointer
	set	-1, %l4
find_loop:
	ldub	[%l2+4],%l3		! Load in the next byte to compare
	sll	%l4,8,%l4		! Shift -1 by a byte
	or	%l4,%l3,%l4		! Set high three bytes to 0xff
					!  low byte is the value from disk

	cmp	%l4,%g0			! Are we zero?
	be	generic_retl		! If so, too far.  Stop

	# BRANCH DELAY SLOT

	cmp	%l4,%o0			! are we the search value?
	bne	find_loop		! If not, loop
	# BRANCH DELAY SLOT
	inc	%l2

find_colon:
	ldub	[%l2],%l3		! repeat till we find colon
	cmp	%l3,':'			! are we a colon?
	bne	find_colon
	# BRANCH DELAY SLOT
	inc	%l2			! Increment pointer

store_loop:
	! increment first in loop to skip one space char
	inc     %l2
	ldub	[%l2],%l3		! load byte

	cmp	%l3,0			! are we off the edge?
	be	generic_retl		! if so, done
	# BRANCH DELAY SLOT	

    	cmp	%l3,%o1			! is it end char?
	be 	generic_retl		! if so, finish
	# BRANCH DELAY SLOT
	
	stb	%l3,[%o5]		! if not store and continue

	ba	store_loop		! loop
	inc	%o5			! incrememnt pointer

	! fall through to strcat

	!================================
	! strcat
	!================================
	! %o0 = "source"
	! %o5 = "destination"
	! %l0 = destroyed
strcat:
	ldub	[%o0],%l0		! load a byte from string
	inc	%o0			! increment
	stb	%l0,[%o5]		! store byte to output_buffer
	cmp	%l0,0
	bne,a	strcat			! if not zero, loop
	# BRANCH DELAY SLOT (ignored when falls through do to annul)
	inc	%o5			! incrememnt
generic_retl:
	retl				! return from leaf
	# BRANCH DELAY SLOT
	# the cmp in the below center_and_print

	!==============================
	! center_and_print
	!==============================
	! string is in g4 (out_buffer global)
	! end of buffer is in o5 -> i5
	! length of buffer (i5-g4) is precomputed in o2->i2
	!     that is done in branch delay slot of caller

center_and_print:
	! Put cmp before save so it can be in delay slot of retl above
	cmp	%o2,80
	save	%sp,-128,%sp		! save reg window

	bgt     done_center		! don't center if > 80
	# BRANCH DELAY SLOT
	set	0,%o1			! print to stdout

	neg	%i2			! negate length
	add	%i2,80,%i2		! add to 80

	call	write_stdout		! print ESCAPE char
	# BRANCH DELAY SLOT
	add	%g2,(escape-data_ref),%o0
	
	call	num_to_ascii		! print number of spaces
	# BRANCH DELAY SLOT
	srl	%i2,1,%o0		! divide by 2, print

	call	write_stdout
	# BRANCH DELAY SLOT
	add	%g2,(c-data_ref),%o0		! print "C"


done_center:
					! point to the string to print
	call	write_stdout
	# BRANCH DELAY SLOT
	mov	%g4,%o0

	! tail recursion into write_stdout
	ba	write_stdout_saved
	# BRANCH DELAY SLOT
	add	%g2,(linefeed-data_ref),%i0

	#================================
	# WRITE_STDOUT
	#================================
	# %o0 -> %i0 (a1) has string

write_stdout:
	save	%sp,-128,%sp		! save reg window
write_stdout_saved:
	mov	%i0,%o1			! copy string to print
	set	SYSCALL_WRITE,%g1	! Write syscall in %g1
	set	STDOUT,%o0		! 1 in %o0 (stdout)
	set	0,%o2			! 0 (count) in %o2

str_loop1:
	ldub	[%o1+%o2],%l0		! load byte
	cmp	%l0,%g0			! compare against zero
	bnz,a	str_loop1		! if not nul, repeat
	# BRANCH DELAY SLOT
	inc	%o2			! increment count (only if taken)

	ta	0x10			! run the syscall

	ret				! return
	# BRANCH DELAY SLOT
	restore				! restore reg window	

	
	!===========================
	! num_to_ascii
	!===========================
	! o0 = num
	! o1 = (0==stdout, 1==strcat)
	! o5 =output
		
num_to_ascii:
	save	%sp,-128,%sp	
	add	%g2,(ascii_buffer-bss_ref)+10,%l0
					! point to end of ascii buffer

div_by_10:

	dec	%l0
	udivcc	%i0,10,%l7		! divide by 10, quotient in %l7
	umul	%l7,10,%l6		! remultiply out
	sub	%i0,%l6,%l6		! remainder in %l6

	add	%l6,0x30,%l6		! conver to ascii
	stb	%l6,[%l0]		! store to buffer
	bnz	div_by_10		! if not zero, loop
	# BRANCH DELAY SLOT
	mov	%l7,%i0			! copy for next divide
		
write_out:
	cmp	%i1,1			! check where output goes
	! Tail recursion directly into write_stdout
	bne     write_stdout_saved
	# BRANCH DELAY SLOT
	mov	%l0,%i0			! move result to o0		

	! Tail recursion into strcat
	ba      strcat
	# BRANCH DELAY SLOT
	restore

!===========================================================================
.data
!===========================================================================

data_begin:
ver_string:		.ascii  " Version \0"
compiled_string:	.ascii  ", Compiled \0"
ram_comma:		.ascii  "M RAM, \0"
bogo_total:		.ascii  " Bogomips Total\0"
linefeed:		.ascii  "\n\0"
default_colors:		.ascii "\033[0m\n\n\0"
escape:			.ascii "\033[\0"
c:			.ascii "C\0"

.ifdef FAKE_PROC
cpuinfo:		.ascii	"proc/cp.sparc\0"
.else
cpuinfo:	        .ascii  "/proc/cpuinfo\0"	
.endif

one:	.ascii	"One \0"
processor:	.ascii " Processor\0"
comma:		.ascii "s, \0"
		
.include "logo.lzss_new"

#============================================================================
#.bss
#============================================================================

.lcomm bss_begin,1
	
.lcomm  text_buf, (N+F-1)
.lcomm  ascii_buffer,10         ! 32 bit can't be > 9 chars
	
   ! see /usr/src/linux/include/linux/kernel.h
.lcomm sysinfo_buff,(64)
.lcomm uname_info,(65*6)
	
.lcomm  disk_buffer,4096        ! we cheat!!!!	
.lcomm  out_buffer,16384	
