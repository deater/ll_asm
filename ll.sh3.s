!
!  linux_logo in SH3 assembler 0.30
!
!  By 
!       Vince Weaver <vince _at_ deater.net>
!
!  assemble with     "as -o ll.o ll.sh3.s"
!  link with         "ld -o ll ll.o"

!  I have to cross-compile, so what I do is was more like
!      make CROSS=sh3-linux- ARCH=sh3

! RISC
! 32-bit, 16-bit instructions.  16 gp registers, banked
!  delayed branches.  Also has DSP built-in.

! SH-3E has floating point built in.
! Bottom 8 registers are banked based on processor mode,
!  but bank0 is always used in user space
! R0 has special meaning in some addressing modes
! GBR register = for I/O accesses?
! MACH/MACL multiply registers
! PR (Procedure Register)
! PC - Program counter
! can be either big or little endian
! T bit in condition codes set on compare instruction
! S bit used in 64-bit multiply

! addressing modes
!   direct register           rn
!   indirect register        @rn
!   post-increment indirect  @rn+
!   pre-decrement indirect  -@rn
!   indirect w dispalcement  @(disp:4,rn)  [4 bit displacemnt]
!   indirect indexed         @(r0,rn)      [has to be r0]
!   ind GBR displacement     @(disp:8,GBR) [8 bit displacement]
!   ind indexed GBR          @(R0,GBR)     [has to be r0]
!   ind PC w displacement    @(disp:8,PC)
!   PC relative		     disp          [either 8 or 12 bits, or R0]
!   immediate                #val          [tst,and,or,xor=zero extended,
!                                           mov,add,comp=sign extended,
!                                           quadupled for trapa]

! Instructions
! ADD Rm,Rn  = Rm+Rn->Rn
! ADDC = add carry (T is carry reg)  ADDV = add with overflow
! AND (full or 8-bit zero extend)  AND.B (8-bit and w mem at GBR)
! BF (branch if false, no delay slot) BF/S (branch if false)
! BRA (branch always)  BRAF (branch far [pc+reg])
! BSR (branch to subroutine, PC->PR)
! BSRF (branch to subroutine far [pc+reg])
! BT (branch if true, no delay slot) BT/S (branch if true)
! CLRMAC (clear multiply/accum reg) CLRS (clear S bit)
! CLRT (clear T bit)
! CMP/EQ CMP/GE CMP/GT CMP/HI CMP/HS CMP/PL CMP/PZ CMP/STR
!   equal, greater than or equal, greater than
!   higher than (ie unsigned gt), higher or same, 
!   positive, positive or zero, byte in rn=byte in rm
!   only immediate compate is with CMP/EQ
!   sets T flag
! DIV0S (divide step 0 signed) DIV0U (div step 0 unsigned)
! DIV1 (divide step 1)
! DMULS.L (do 32x32 multiply and store in MACL and MACH)
! DMULU.L (do unsigned 32x32 mult and store in MACL/MACH)
! DT (decrement and test.  subtrace one, compare 0, set T)
! EXTS (extend as signed) EXTU (extend as unsigned)
! JMP (jump)  JSR (jump subroutine)
! LDS, LDS.L (load to system reg).  On plain sh3 only MACH and MACL targets
! MAC.L (multiply and accumulate.  two 32-bit vals read from mem and 
!        multipled, then added to current MAC registers)
! MAC,MAC.W (two 16-bit vals read from mem and multiplied and added to MAC)
! MOV, MOV.B, MOV.W, MOV.L (move) 
! MOVA (move effective address) PC+disp -> R0
! MOVT (T bit stored in REG, zero extended)
! MUL.L (two 32-bit values multiplied, bottom 32bits only stored in MAC)
! MULS.W (two 16-bit signed values multiplied, stored in MAC)
! MULU.W (16-bit unsigned mul)
! NEG (negate), NEGC (negate w carry, used for negating > 32bit num)
! NOP (nop)     NOT (1's complement)
! OR, OR.B (logical OR)
! PREF (prefetch data to cache)
! ROTCL (rotate with carry, left) ROTCR (rotate with carry, right)
! ROTL (rotate [shift] left)      ROTR (rotate [shift] right)
! RTS (return from subroutine) [PR->PC]
! SETS (set S flag) SETT (set T flag) 
! SHAD (Shift arithmatically dynamically) [left and right arith shift]
! SHAL (shift left by one bit, moving T in)
! SHAR (shift right arith by one bit, shifting into T)
! SHLD (shift left dynamically) [meaning amount in reg]
! SHLL (shift left locgically, by one bit)
! SHLL2, SHLL8, SHLL16 (shift left by 2, 8, or 16 bits)
! SHLR (shift right logically, by one bit)
! SHLR2, SHLR8, SHLR16 (shift right by 2,8 ,or 16 bits)
! SUB (subtract)  SUBC (subtract with carry)
! SUBV (subtract with overflow)
! SWAP.B SWAP.W (swap bytes)
! TAS (test and set) [for SMP]
! TRAPA (trap always) [system call]
! TST (test)
! XOR, XOR.B (exclusive or)
! XTRCT (extract middle 32 bits fro two registers paired)



! Syscalls
!   number in r3, args in r4,r5,r6,r7,r0,r1
!   use the "trapa" instruction.  possibly 0x10+num_arguments
!   result returned in r0

! r15 is stack pointer, r14 is frame pointer

! Optimizing
! + 1169 - Original working version
! + 1061 - Remove debugging hooks
! + 1049 - optimize/remove branch delay slots in lzss code
! + 1025 - optimize/remove branch delay slots in sysinfo code
! + 1021 - convert find_string into a loop
! + 1001 - optimize all but num_to_ascii 
! +  994 - optimize num_to ascii.  Wish I could put the 16 divide
!          instructions in a loop somehow, that's 32 bytes there.

.include "logo.include"

! offsets into the results returned by the uname syscall
.equ U_SYSNAME,0
.equ U_NODENAME,65
.equ U_RELEASE,65*2
.equ U_VERSION,(65*3)
.equ U_MACHINE,(65*4)
.equ U_DOMAINNAME,65*5

! offset into the results returned by the sysinfo syscall
.equ S_TOTALRAM,16

! Sycscalls
.equ SYSCALL_EXIT,	1
.equ SYSCALL_READ,	3
.equ SYSCALL_WRITE,	4
.equ SYSCALL_OPEN,	5
.equ SYSCALL_CLOSE,	6
.equ SYSCALL_SYSINFO,	116
.equ SYSCALL_UNAME,	122

!
.equ STDIN,0
.equ STDOUT,1
.equ STDERR,2

	.globl _start	
_start:

	!=========================
	! PRINT LOGO
	!=========================

! LZSS decompression algorithm implementation
! by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
! optimized some more by Vince Weaver

	mov.l	@(out_addr-.,pc),r8	! point r8 to out_buffer
	mov	r8,r10			! copy for later
	mov.l	@(R-.,pc),r0		! r is in r0
	mov.l	@(logo_addr-.,pc),r3	! r3 points to logo data
	mov.l	@(logo_end_addr-.,pc),r7! r7 points to logo end
	mov.l	@(text_addr-.,pc),r9	! r9 points to text buf

decompression_loop:
       	mov	#8,r5			! shift count
	mov.b	@r3+,r1			! load a byte, increment pointer

test_flags:
	cmp/ge	r7,r3		! have we reached the end?
	bt	done_logo  	! if so, exit
				! bt has no delay slot

	shlr 	r1		! shift bottom bit into carry flag
	bt	discrete_char	! if set, we jump to discrete char
				! bt has no delay slot
				
offset_length:
	mov.b	@r3+,r12	! load a byte, increment pointer
	extu.b	r12,r12
	
	mov.b	@r3+,r4		! load a byte, increment pointer	
				! we can't load halfword as no unaligned loads
        extu.b	r4,r4

	shll8	r4
	or	r4,r12  	! merge back into 16 bits
				! this has match_length and match_position

				! no need to mask r12, as we do it
				! by default in output_loop

	mov	r12,r6		! r6 will hold the count
	shlr8	r6   		! assuming P_BITS is 10
	shlr2	r6		! have to shift in 2 parts
	add	#(THRESHOLD+1),r6
				! r6 = (r4 >> P_BITS) + THRESHOLD + 1
				!                       (=match_length)

output_loop:
	
	mov.l	@(pos_mask-.,pc),r13	! urgh, can't handle simple constants
	and	r13,r12			! mask it

	mov	r9,r13
	add	r12,r13
	mov.b 	@r13,r4		! load byte from text_buf[r12]
	add	#1,r12		! increment pointer

store_byte:
	mov.b	r4,@r10			! store a byte
	add	#1,r10			! increment pointer

	mov.b	r4,@(r0,r9)		! store a byte to text_buf[r]
	add	#1,r0			! r++

	mov.w	@(n_val-.,pc),r2
	add	#-1,r2		 	! grrr no way to get this easier
	and	r2,r0			! mask r

	dt	r6			! decement count
	bf 	output_loop		! repeat until k>j
					! bf has no branch delay slot

	dt	r5			! dt--.  If dt=0, T=1
	bf	test_flags		! if not, re-load flags
					! bf has no branch delay slot

	bra	decompression_loop	! loop
	nop				! wasted branch delay

discrete_char:
	mov.b	@r3+,r4			! load a byte, increment pointer
	bra	store_byte		! and store it (and delay slot)	
	mov	#1,r6			! we set r6 to one so byte
					! will be output once


! end of LZSS code

done_logo:

	bsr	write_stdout		! print the logo
	mov	r8,r5			! buffer we are printing to (br delay)

	!==========================
	! PRINT VERSION
	!==========================

first_line:

	mov	r8,r10			! copy in output pointer

	mov	#SYSCALL_UNAME,r3	! uname number
	mov.l	@(uname_addr-.,pc),r4	! uname struct
	trapa	#0x11		        ! do syscall


	bsr	strcat_r4		! os-name from uname "Linux"
	mov	r4,r11		        ! save pnter for later (br delay)

	bsr 	strcat_r9	        ! call strcat
	mov.l	@(data_addr-.,pc),r9	! source is " Version " (br delay)

	add	#(U_RELEASE/2),r11	! too big to fit in 8bit offset
	mov	r11,r3			! save pointer for later
	add	#(U_RELEASE/2),r3

	bsr	strcat_r4	        ! call strcat
	mov	r3,r4		        ! version from uname, "2.6.20" (brdly)

	bsr	strcat_r9		! source is ", Compiled "
	nop				! delay slot (wasted)

	add	#(U_VERSION/3),r3	! point to compiled date
	
	bsr	strcat_r4		! call strcat
	mov	r3,r4			! point to compiled data (br delay)
	
	bsr	strcat_r9		! source is "\n"
	nop				! delay slot (wasted)
	
	bsr	center_and_print	! center and print
	nop				! branch delay slot (wasted)

	!===============================
	! Middle-Line
	!===============================
middle_line:		
	!=========
	! Load /proc/cpuinfo into buffer
	!=========

	mov	r8,r10			! restore output pointer
	
	mov	#SYSCALL_OPEN,r3
	mov.l	@(cpu_addr-.,pc),r4	! uname struct	
					! '/proc/cpuinfo'
	mov	#0,r5			! 0 = O_RDONLY <bits/fcntl.h>
	trapa	#0x12			! open()  fd returned in r0

	mov	r0,r1			! save our fd
	
	mov	#SYSCALL_READ,r3
	mov	r1,r4			! move in fd
	mov.l	@(disk_addr-.,pc),r5	! load pointer to disk address
	
	mov	#16,r6			
	shll8	r6			! load 4096 (16<<8)
				 	! 4096 is maximum size of proc file ;)
	trapa	#0x13			! read()

	mov	#SYSCALL_CLOSE,r3
	mov	r1,r4		 	! restore fd
	trapa	#0x11			! close (to be correct)

	!=============
	! Number of CPUs
	!=============
number_of_cpus:

	bsr	strcat_r9		! assume no SMP, print "One"
	nop				! branch delay slot (wasted)

	!=========
	! MHz
	!=========
print_mhz:
	bsr	find_string		! call find_string
	mov.l	@(mhz_search-.,pc),r4	! look for "MHz" (br delay)

	bsr	strcat_r9		! print MHz
	nop				! branch delay slot (wasted)

	!=========
	! Chip Name
	!=========
chip_name:	
	bsr	find_string			! call find_string
	mov.l	@(family_search-.,pc),r4	! find "mily"

	bsr	strcat_r9		! print " Processor, "
	nop			  	! branch delay (wasted)
	
	!========
	! RAM
	!========

	mov	#SYSCALL_SYSINFO,r3	! sysinfo() syscall
	mov.l	@(sys_addr-.,pc),r4	! sysinfo addr
	trapa	#0x11
	
	mov.l	@(S_TOTALRAM,r4),r4		
					! size in bytes of RAM
	shlr16	r4			! divide by 1024*1024 to get M
	shlr2	r4			! we shift by 16,2,2
	shlr2	r4			! because sh can't do >>20 direct

	bsr num_to_ascii		! convert to ASCII
	mov	#1,r3			! use strcat

	bsr	strcat_r9		! print 'M RAM, '
	nop				! branch delay (wasted)

	!=========
	! Bogomips
	!=========


	bsr	find_string		! call find_string
	mov.l	@(bogo_search-.,pc),r4	! look for 'mips' (br delay)

	bsr	strcat_r9		! print bogomips total
	nop				! branch delay (wasted)
	
	bsr	center_and_print	! center and print
	nop				! branch delay (wasted)
	
	!=================================
	! Print Host Name
	!=================================
last_line:
	mov	r8,r10			! restore out_buffer
	
	bsr	strcat_r4		! call strcat
	mov	r11,r4			! restore uname ptr (branch delay)
	
	bsr	center_and_print	! center and print
	nop				! branch delay (wasted)
	
	bsr     write_stdout	        ! restore colors, print a few linefeeds
        mov	r9,r5			! point to linefeeds (branch delay)
	
	!================================
	! Exit
	!================================	
exit:
     	mov	#SYSCALL_EXIT,r3
	mov	#0,r4				! result is zero
	trapa	#0x11				! and exit

	!=======================================
	! Constants used by the logo code
	!   (have to be within 256 bytes of use)
	!=======================================
.align 2
out_addr:	.long out_buffer
logo_addr:	.long logo
logo_end_addr:	.long logo_end
text_addr:	.long text_buf
pos_mask:	.long ((POSITION_MASK<<8)+0xff)
R:     		.long N-F
.align 1
n_val:		.word N

	!=================================
	! FIND_STRING 
	!=================================
	! r3=char to stop at
	! r4=string to find
	! r5 trashed
find_string:
	mov.l	@(disk_addr-.,pc),r5	! load pointer to disk buffer
find_loop:
        ! this would be easier with unaligned loads
	! but SH doesn't support them
	! (this is trickier because qemu-sh4 on x86 does)

	! wish we could use
	! mov.l	@r5,r0

	! turn into a loop?

	xor    r1,r1  	   		! clear r1
	mov    #0,r0			! clear r0
looper:
        mov.b	@(r0,r5),r14		! load byte
	shll8	r1			! shift old part
	or	r14,r1			! or new part in
	add	#1,r0			! increment pointer
	cmp/eq	#4,r0			! have we done 4?
	bf	looper			! if not loop

	xor	r0,r0			! was our result 0?
	cmp/eq	r1,r0
	bt	done 			! if so, off end, done

	cmp/eq	r4,r1			! compare to our string

	bf/s	find_loop		! if no match, loop
	add	#1,r5	 		! incrememnt pointer (br delay)
	
find_colon:
	mov.b	@r5+,r0			! load a byte, increment pointer
	cmp/eq	#':',r0
	bf/s	find_colon		! repeat till we find colon
	nop				! branch delay slot (wasted)

	add	#1,r5			! skip the space
		
store_loop:
	mov.b	@r5+,r0			! load a byte, increment pointer 
	mov.b	r0,@r10			! store a byte
	add	#1,r10			! increment pointer
	cmp/eq	#'\n',r0		! is it linefeed?
	bf/s	store_loop		! if not loop
	nop				! branch delay slot

	xor     r0,r0			! clear r0

done:
	rts				! return
	mov.b	r0,@-r10		! replace last value with NUL (brdly)

	!================================
	! strcat_r9
	!================================
	! value to cat in r9
	! output pointer in r10
	! r0 trashed
strcat_r9:        
	mov.b	@r9+,r0			! load a byte, increment pointer 
	mov.b	r0,@r10			! store a byte
	add	#1,r10			! increment pointer
	cmp/eq	#0,r0			! is it zero?
	bf	strcat_r9		! if not loop
					! bf has no delay slot

	rts				! return
	add	#-1,r10			! point to one less than null (brdlay)
	
	!================================
	! strcat_r4
	!================================
	! value to cat in r4
	! output pointer in r10
	! r0 trashed
strcat_r4:
	mov.b	@r4+,r0			! load a byte, increment pointer 
	mov.b	r0,@r10			! store a byte
	add	#1,r10			! increment pointer
	cmp/eq	#0,r0			! is it zero?
	bf	strcat_r4		! if not loop
					! bf has no branch delay
					
	rts				! return
	add	#-1,r10			! point to one less than null (brdly)


	!==============================
	! center_and_print
	!==============================
	! string to center in at output_buffer

center_and_print:
	sts.l   pr,@-r15		! store return address on stack

	bsr	write_stdout
	mov.l	@(escape_addr-.,pc),r5	! we want to output ^[[
	
str_loop2:
	mov	r10,r0			! point r0 to out pointer
	sub	r8,r0			! get length by subtracting

	mov	#81,r4			! we use 81 to not count ending \n
	subv	r0,r4			! subtract.  T=1 on underflow

	bt	done_center		! if result negative, don't center
					! bt has no branch delay
		
	shlr	r4			! divide by 2
	xor	r0,r0
	addc	r0,r4			! round


	bsr	num_to_ascii		! print number of spaces
	mov	#0,r3			! print to stdout (branch delay)
	
	bsr	write_stdout
	mov.l	@(c_addr-.,pc),r5	! we want to output C (brnch delay)

done_center:

	lds.l   @r15+,pr		! restore return address from stack
	mov	r8,r5			! point to output
					! fall through to write_stdout

	!================================
	! WRITE_STDOUT
	!================================
	! string to write in r5
	! r0,r1,r2,r3,r4,r6 trashed

write_stdout:
	mov	#-1,r0			! init count
	mov	#0,r2 			! 
strlen:	
	add	#1,r0			! increment count
	mov.b	@(r0,r5),r1		! load byte from memory
	cmp/eq	r2,r1	   		! compare against zero
	bf/s	strlen			! loop
	mov	r0,r6 			! branch delay slot
	
	mov	#SYSCALL_WRITE,r3	! syscall #
	mov	#STDOUT,r4		! write to stdout
	
	trapa	#0x13			! do the syscall
	
	rts				! return
	nop				! branch delay slot (wasted)

	
	!=============================
	! num_to_ascii
	!=============================
	! r4 = value to print
	! r3 = 0=stdout, 1=strcat
	! r2,r5,r6 trashed?
	
num_to_ascii:
	mov.l	@(ascii_addr-.,pc),r5	! point to end of ascii buffer

div_by_10:
	mov	#10,r6		! we'll be dividing by 10
	shll16	r6
	div0u			! set up for unsigned division
	mov	r4,r2
divloop:	
	div1	r6,r2		! can't do this in a loop
	div1	r6,r2		! because it depends on value of T
	div1	r6,r2		! and can't compare for loop end
	div1	r6,r2		! without setting T
	div1	r6,r2
	div1	r6,r2		! could we be clever with rotates
	div1	r6,r2		! to save/restore the T book somehow?
	div1	r6,r2
	div1	r6,r2
	div1	r6,r2
	div1	r6,r2
	div1	r6,r2
	div1	r6,r2
	div1	r6,r2
	div1	r6,r2
	div1	r6,r2
	rotcl	r2
	extu.w	r2,r2	
	
	mov	#10,r6
	
		     		! Q is in r2
	mul.l	r6,r2		! multiply Q by 10, store in MACL
	sts	macl,r0		! move macl to r0
	mov	r4,r6
	sub	r0,r6		! subtract, R is now in r6

	add	#0x30,r6	! convert to ascii
	mov.b	r6,@-r5		! store a byte, decrement pointer	
	mov	r2,r4		! move Q in for next divide
	
	xor	r0,r0
	cmp/eq	r0,r4
	bf	div_by_10	! if Q not zero, loop
				! bf has no branch delay

write_out:
	cmp/eq	r3,r0		! r0 should still be zero

	bt	write_stdout	! if r3==0, goto stdout
				! bt has no branch delay


	bra	strcat_r4	! if 1, strcat
	mov	r5,r4		! but string in right place (brdelay)

	
.align 2
cpu_addr:	.long cpuinfo
data_addr:	.long data_begin
uname_addr:	.long uname_info
disk_addr:	.long disk_buffer
sys_addr:	.long sysinfo_buff
escape_addr:	.long escape
ascii_addr:	.long (ascii_buffer+10)
c_addr:		.long C

family_search:	.long 'm'<<24+'i'<<16+'l'<<8+'y'
mhz_search:	.long 'u'<<24+' '<<16+'c'<<8+'l'
bogo_search:	.long 'm'<<24+'i'<<16+'p'<<8+'s'

.align 1


!===========================================================================
!	section .data
!===========================================================================
.data	
data_begin:
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
linefeed:		.ascii	"\n\0"
one:	.ascii	"One \0"
mhz:	.ascii	" \0"
processor:	.ascii	" Processor, \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\n\0"

default_colors:	.ascii "\033[0m\n\n\0"
escape:		.ascii "\033[\0"
C:		.ascii "C\0"

.ifdef FAKE_PROC
cpuinfo:	.ascii  "proc/cpui.sh3\0"
.else
cpuinfo:	.ascii	"/proc/cpuinfo\0"
.endif

.include	"logo.lzss_new"

.align 2
!============================================================================
!	section .bss
!============================================================================
!.bss
bss_begin:
.comm uname_info,(65*6)
.comm sysinfo_buff,(64)
.comm ascii_buffer,10
.comm  text_buf, (N+F-1)

.comm	disk_buffer,4096	! we cheat!!!!
.comm	out_buffer,16384
	! see /usr/src/linux/include/linux/kernel.h

