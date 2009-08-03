//
//  linux_logo in ia64 assembler    0.24
//
//  by Vince Weaver <vince _at_ deater.net>
//
//  assemble with     "as -o ll.o ll.ia64.s"
//  link with         "ld -o ll ll.o"

.include "logo.include"

// ASSEMBLY INFO
//   Comment is the C++ comment character
//   by default, automatic mode which bundles instructions for you
//   you can enable explicit mode with ".explicit"
//   you specify end of instruction group with ;;
//     an instruction group is a set of instructions with no dependencies
//   a bundle has 3 instructions, each 41 bits long, plus a 5-bit field
//     you can indicate a bundle by hand using { } brackets to include
//     with a .specifier to indicate what insn type (For example .mii)	
//   not all instructions can be bundled together.  
//	Long immediate and jump instructions can take 2 instructions
	
// in an instruction group, all instructions in a group run at same time.
//    reg RAW and WAW dependencies are not allowed.  WAR are allowed (usually)
//    mem RAW and WAW dependencies are allowed.  accesses happen in prog order
// exceptions:	 RAW - subsequent branches can see changes made to pr regs
//    a few other exceptions, not really relevant to ll
		
			
	
		 
// instructions like {p1}mov r1 =r4
// compare instructions can set predicates
// Instructions in bundles.  Up to 3 instructions per bundle
// can jump to x86 code with "jmpe"
// can do "virtual register allocation" to assign var names to strings
// can annotate branches with guessed targets and probabilities

// 128 int / 128fp registers, 64 predicate registers, 8 branch regs
// register stack
// register rotation

// 128 int registers, GR0-GR127.  in x86 mode you get GR8-GR31
//     registers are 64-bit plus extra "NaT" (not a Thing) bit
// GR0-GR31 always visible.  
//   GR0 is a zero register.   Always reads 0, writes cause a fault
//   r1 = gp (global pointer)
//   r2-r3 = scratch (usable with 22-bit add)
//   r4-r7 are saved registers
//   r8 = struct/union pointer
//   r8-r11 = return values
//   r12=stack pointer (must be 128-bit alligned)
//   r13=thread pointer
								
// GR32-127 are stacked registers.		
// 128 fp registers, FR0-FR127
// FR0-FR31 always visible.
//  FR0 always reads as 0.0, FR1 always reads as 1.0.  can't read them	
// 64 predicate registers, PR0-PR63 (1 bit each)
//   PR0-PR15 always available.  PR0 is always 1
//   PR16-PR63 are rotating (for loop unrolling)	
// 8 branch registers, BR0-BR7  (br0 also known as rp)
// 8 Kernel registers KR0-7 (AR0-7).  Can be read in userspace but not written
// LC (AR65) is a loop counting register
// Many other registers that don't matter to us in ll

// normal looking add instruction.  Extra add/sub instructions that
//   can additionall add/sub a "1" as well
//   There is a special add with 22-bit immediate that can only add gr0,1,2
//   shladd cann also shift by 1,2,4 before add
// integer multiply uses FP unit?
// special 32-bit addition instruction addp
// various shift and extract instructions.  Funnel shift?
// movl can load a 64-bit immediate, taking two instruction slots
// cmp, cmp4 (32-bit), tbit, tnat, etc do compares and set two predicate bits
//    normall the two bits are set, one is == the other is !=
//    also "unc" unconditional like normal but init to zero if not being set
//    also and, or, demorgan which allow multiple compares in one instruct?
//    cmp.ne p1,p2=a,r0  means p1= a!=0, p2= a==r0 (?)	
// loads/stores.  
//    Can be either little/big-endian, but set at program start time
//    can do lots of weird things, like speculative loads, and spill inst
//    special spill instruction to handle NaT in registers
//    loads should be aligned
//    "advanced" loads let you move loads in front of stores even
//      if you don't know if they overlap yet.	
//    use the "chk" instruction to be sure speculative load worked
//  post-increment loads ld8 r2=[r1],1
	
// Branches.  Branches don't have to be the last insn in a bundle
//    all manner of branch prediction hints, plus special loop unrolling stuff
//    branch registers can hold the destination of a call
//    you specify branch predictor info with branches.
//       .spnt. (statically predict not taken)  .sptk (taken)
//       .dpnt  (dynamically predict not taken) .dptk (taken)
//       .few - prefetch only a few instrs at destination
//	 .many - prefetch many instrs at destination		
		
// String instructions:	
//    czx finds first zero byte in a reg

// loop instruction:	 special LC loop count reg and br.cloop
	
// register stack	
//    use "alloc" instruction to allocate register stack
//    use like "alloc loc0=ar.pfs,w,x,y,z
//        the old instruction windows stored to loc0 (restore on exit)
//        w = input regs (which are same as old out regs)
//        x = local regs
//        y = output regs (up to 8 for passing params)
//        z = rotating registers			
//    allocated registers are placed as r32-r??
				

// syscall is "break.i 0x10000" instruction, with syscall # in r15
//    and inputs in out0...out?	

.equ STDIN,0
.equ STDOUT,1		
.equ STDERR,2
				
// offsets into the results returned by the uname syscall
.equ U_SYSNAME,0
.equ U_NODENAME,65
.equ U_RELEASE,65*2
.equ U_VERSION,(65*3)
.equ U_MACHINE,(65*4)
.equ U_DOMAINNAME,65*5

.equ S_TOTALRAM,32
	
// syscall numbers
.equ SYSCALL_EXIT,1025	
.equ SYSCALL_READ,1026
.equ SYSCALL_WRITE,1027
.equ SYSCALL_CLOSE,1029
.equ SYSCALL_OPEN,1028
.equ SYSCALL_SYSINFO,1127
.equ SYSCALL_UNAME,1130

	.globl _start
_start:	

	alloc   loc0 = ar.pfs,4,32,6,0	// 4 inputs, 32 locals, 6 outputs
   	
	movl	r13=out_buffer		// point output to buffer

        //=========================
	// PRINT LOGO
	//=========================
	
// LZSS decompression algorithm implementation
// by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
// optimized some more by Vince Weaver
	
	mov	loc1=r13		// buffer we are printing to
	mov	loc2=(N-F)		// R
	movl	loc3=logo		// beginning of logo data
	movl	loc8=logo_end		// end of logo data
	movl	loc9=text_buf		// point to text_buf

decompression_loop:
	ld1	loc4=[loc3],1		// load logo byte, auto-increment
	mov	loc5=0xff00
	or	loc5=loc5,loc4		// set top 8 bits as a pseudo-count

test_flags:
	cmp.ge	p2,p3=loc3,loc8		// have we reached the end?
(p2)	br.cond.dpnt	done_logo	// if so, branch to end

	tbit.nz	p4,p5=loc5,0
	shr.u	loc5=loc5,1		// shift right
(p4)	br.cond.dptk	discrete_char	// if shifted out a 1, discrete char
	
offset_length:

	ld1	loc12=[loc3],1		// load a byte, inc
	ld1	loc4=[loc3],1		// load a byte, inc

					// we have ot merge into one 16-bit
					// value, as we have no unaligned loads
	shl	loc13=loc4,8		// shift left
	or	loc4=loc13,loc12	// and put on top

	mov	loc7=loc4		// move into r7.  we mask this later

	mov	loc12=(THRESHOLD+1)
	shr	loc13=loc4,P_BITS
	add	loc6=loc12,loc13	// loc6= (loc4>>P_BITS)+THRESHOLD+1
					//     = match_length
	
	

output_loop:	
	mov	loc12=((POSITION_MASK<<8)+0xff)
	and	loc7=loc7,loc12		// mask

	add	loc12=loc7,loc9
	
	ld1	loc4=[loc12]		// load byte from text_buf[loc2]
	add	loc7=1,loc7		// incrememnt pointer
		
store_byte:			
	st1	[loc1]=loc4,1		// store byte and auto-inc
	add	loc12=loc9,loc2
	st1	[loc12]=loc4		// store byte to text[loc2]
	add	loc2=1,loc2		// increment loc2
	
	mov	loc12=(N-1)
	and	loc2=loc2,loc12		// mask loc2 to not be too big

	add	loc6=-1,loc6		// decrement count
	cmp.ne	p2,p3=0,loc6
(p2)	br.cond.dptk	output_loop	// if not zero, loop

	mov	r12=0x100
	cmp.lt	p4,p5=r12,loc5		// see if top bits set
(p4)	br.cond.dptk	test_flags	// if not, reload flags

	
	br	decompression_loop
		
discrete_char:		
	ld1	loc4=[loc3],1		// load byte and auto-inc
	mov	loc6=1			// set to store single byte
	br	store_byte		// store it
	
done_logo:
	mov	out0=r13
	br.call.sptk.few	b4=write_stdout	
	
	
	//==========================
	// PRINT VERSION
	//==========================
first_line:
	mov	r4=r13				// out_buffer
	
	mov	r15=SYSCALL_UNAME		// uname syscall
	movl	out0=uname_info			// uname struct
	mov	loc4=out0			// copy pointer
	break.i	0x100000			// call syscall

	add	out0=U_SYSNAME,loc4		// os-name from uname "Linux"
	br.call.sptk.few	b5=strcat

	movl	out0=ver_string			// source is " Version "
	br.call.sptk.few	b5=strcat
	 
	add	out0=U_RELEASE,loc4		// version from uname "2.4.1"
	br.call.sptk.few	b5=strcat

	movl	out0=compiled_string		// source is ", Compiled "
	br.call.sptk.few	b5=strcat

	add	out0=U_VERSION,loc4		// compiled date
	br.call.sptk.few	b5=strcat

	movl	out0=linefeed
	br.call.sptk.few	b5=strcat	// "\n"
	
{
	// force not to be in a bundle with another call
	br.call.sptk.few	b0=center_and_print	
}
	//===============================
	// Middle-Line
	//===============================
middle_line:

	mov	r4=r13			// restore output pointer

	//=========
	// Load /proc/cpuinfo into buffer
	//=========
	
	mov	r15=SYSCALL_OPEN	// open()
	movl	out0=cpuinfo		// '/proc/cpuinfo'
	mov	out1=0			// O_RDONLY <bits/fcntl.h>
	break.i	0x100000		// syscall. fd returned in r8?
	
	mov	r15=SYSCALL_READ	// read
	mov	out0=r8			// copy fd
	movl	out1=disk_buffer
	mov	out2=4096		// 4096 is upper-limit of a procfile
	break.i	0x100000		// syscall

	mov	r15=SYSCALL_CLOSE	// fd still in out0
	break.i	0x100000		// syscall
		


	//=============
	// Number of CPUs
	//=============

	mov	out0='I'		// count how many times IPS appears
	mov	out1='P'
	mov	out2='S'
	br.call.sptk	b1=count_string

	cmp.lt	p2,p3=5,r8		// cap cpus at "5" = many
(p2)	mov	r8=5	
	
	movl	loc2=array		// get string pointers
	movl	loc3=one
	
	add	loc4=loc2,r8		// add offset in array
	add	loc4=-1,loc4		// to beginning of list
	ld1	loc4=[loc4]
	add	out0=loc4,loc3
	
	br.call.sptk.few	b5=strcat

	//=========
	// MHz
	//=========
	
	mov	out0='M'		// find 'cycl' and grab after ':'
	mov	out1='H'
	mov	out2='z'
	mov	out3='.'
	br.call.sptk.many	b1=find_string

	movl	out0=megahertz		// print 'MHz '
	br.call.sptk.many	b5=strcat

   
   	//=========
	// Chip Name
	//=========
	
   	mov     out0='i'     	// find 'ily' and grab  after :
	mov	out1='l'
	mov	out2='y'
	mov	out3='\n'
	br.call.sptk.many	b1=find_string

	movl	out0=ram_comma			// print ', '
	add	out0=5,out0
	br.call.sptk.many	b5=strcat

	//========
	// RAM
	//========

	mov	r15=SYSCALL_SYSINFO	// sysinfo() syscall
	movl	out0=sysinfo_buff
	break.i	0x100000

	add	loc2=S_TOTALRAM,out0
	ld8	loc3=[loc2]

	shr	out1=loc3,20
	mov	out0=1
	
	br.call.sptk.many	b1=num_to_ascii

	
	movl	out0=ram_comma    	// print 'M RAM, '
	br.call.sptk.many	b5=strcat

	//========
	// Bogomips
	//========

	mov	out0='I'      		// find 'IPS' and grab up to \n
	mov	out1='P'
	mov	out2='S'
	mov	out3='\n'

	br.call.sptk.many	b1=find_string

	movl	out0=bogo_total

	br.call.sptk.many	b5=strcat

{	
	br.call.sptk.few	b0=center_and_print
}

	//=================================
	// Print Host Name
	//=================================
last_line:
	mov	r4=r13				// out_buffer
	movl	loc1=uname_info			// uname struct		
	add	out0=U_NODENAME,loc1		// print node name

{
	br.call.sptk.few	b5=strcat
	        // gas incorrectly puts two calls in same bundle
		// so we are forcing this one to be by itself
}
	
	br.call.sptk.few	b0=center_and_print

	movl	out0=default_colors		// restore default colors
	br.call.sptk.few	b4=write_stdout


	//================================
	// Exit
	//================================
exit:	
	mov     out0=0			// 0 exit value
	mov     r15=SYSCALL_EXIT	// load syscall number
	break.i	0x100000

		
	//=================================
	// Divide
	// yes this is an awful algorithm, but simple
	// and uses few registers
	//=================================
	// in0 =numerator	in1=denominator
	// r8=quotient		r9=remainder
	// b3=return
	
divide:
	alloc	loc0=ar.pfs,2,8,6,0	// setup register frame
	mov	r8=r0			// zero out result

	setf.sig	f3=in0		// itanium uses fp multiply
	setf.sig	f4=in1

divide_loop:

	setf.sig	f8=r8

	xma.l	f7=f8,f4,f0		// multiply temp by denominator
	add	r8=1,r8			// incrememnt quotient

	getf.sig	loc1=f7		// get result
		
	cmp.le	p8,p9=loc1,in0		// is it greater than numerator?
(p8)	br.cond.dptk	divide_loop	// if not, increment temp
		
	add	r8=-2,r8		// otherwise went too far, decrement
					// and done

	setf.sig  f8=r8
	xma.l	f7=f8,f4,f0		// calculate remainder
	getf.sig	loc1=f7
	sub	r9=in0,loc1		// R=N-(Q*D)

	mov	ar.pfs=loc0		// restore register file
	br.ret.sptk.many        b3	//  return
	

	//=================================
	// FIND_STRING 
	//=================================
	//   in3 is char to end at
	//   in0,in1,in2 are 3-char ascii string to look for
	//   b1=return
	
find_string:
	alloc	loc0=ar.pfs,4,8,4,0
	movl	loc1=disk_buffer	// look in cpuinfo buffer
	
find_loop:
	ld1	loc2=[loc1],1		// watch for first char
	cmp.ne	p6,p7=loc2,in0
(p6)	br.cond.dptk	find_loop
	
	ld1	loc2=[loc1]		// watch for second char
	cmp.ne	p6,p7=loc2,in1
(p6)	br.cond.dptk	find_loop

	add	loc3=1,loc1
	ld1	loc2=[loc3]		// watch for third char
	cmp.ne	p6,p7=loc2,in2
(p6)	br.cond.dptk	find_loop	
		
	cmp.eq	p8,p9=0,loc2		// see if off the end
(p8)	br.cond.spnt	done		// if so, exit

		
					// if we get this far, we matched
find_colon:
	ld1	loc2=[loc1],1		// repeat till we find colon
	cmp.eq	p8,p9=0,loc2		// escape if hit a null
(p8)	br.cond.dptk	done
	cmp.ne	p10,p11=':',loc2
(p10)	br.cond.dptk	find_colon

	add	loc1=1,loc1		// skip a char [should be space]

store_loop:
	ld1	loc2=[loc1],1
	cmp.eq	p6,p7=0,loc2		// is it a null?
(p6)	br.cond.dptk	done

	cmp.eq	p8,p9=in3,loc2		// is it end string?
(p8)	br.cond.dptk 	almost_done	// if so, finish

	st1	[r4]=loc2,1		// if not store and continue
	br	store_loop

almost_done:	 
	st1	[r4]=r0			// replace last value with null

done:
	mov	ar.pfs=loc0
	br.ret.sptk.many	b1


	//=================================
	// COUNT_STRING 
	//=================================
	//   in0,in1,in2 are 3-char ascii string to look for
	//   r8 points at result
	//   b1=return
	
count_string:
	alloc	loc0=ar.pfs,4,8,4,0
	mov	r8=0

	movl	loc1=disk_buffer	// look in cpuinfo buffer

count_loop:
	ld1	loc2=[loc1],1		// watch for first char

	cmp.eq	p8,p9=0,loc2		// see if off the end
(p8)	br.cond.spnt	done_counting	// if so, exit	
	
	cmp.ne	p6,p7=loc2,in0
(p6)	br.cond.dptk	count_loop
	
	ld1	loc2=[loc1]		// watch for second char
	cmp.ne	p6,p7=loc2,in1
(p6)	br.cond.dptk	count_loop

	add	loc3=1,loc1
	ld1	loc2=[loc3]		// watch for third char
	cmp.ne	p6,p7=loc2,in2
(p6)	br.cond.dptk	count_loop	
		

		
					// if we get this far, we matched
	add	r8=1,r8
	br	count_loop

done_counting:
	mov	ar.pfs=loc0
	br.ret.sptk.many	b1

	//================================
	// write_stdout
	//================================
	// string to output in in0
	// return in b4

write_stdout:
	alloc	loc0=ar.pfs,1,2,6,0	// setup reg stack

	mov	out1=in0		// copy string to print
	mov	out2=0			// set length to 0

string_loop:
	ld1	loc1=[in0],1		// load byte, auto inc
	cmp.ne	p1,p2=loc1,r0		// is it zero?
	add	out2=1,out2		// increment count
(p1)	br.cond.dptk	string_loop	// if not zero, loop
	
	add	out2=-1,out2		// fix count to not include 0
		
	mov	out0=STDOUT		// stdout
	mov	r15=SYSCALL_WRITE	// write_syscall	
	break.i	0x100000		// syscall	
	
	mov	ar.pfs=loc0		// restore register stack
	br.ret.sptk.many        b4	//  return

	
	//================================
	// strcat
	//================================
	// in0 = "source"
	// r4 = "destination"
	// b5 = return pointer
strcat:
	alloc	loc0=ar.pfs,1,8,6,0	// setup register frame
strcat_loop:
	ld1	loc1=[in0],1		// load and incrememnt pointer
	st1	[r4]=loc1,1		// store and increment pointer
	
	cmp.ne	p6,p7=0,loc1 
(p6)	br.cond.dptk	strcat_loop	// is it zero? if not, loop
	
	add	r4=-1,r4		// back up pointer to the zero

	mov	ar.pfs=loc0		// restore register frame
	
	br.ret.sptk.many	b5	// return

		
	//==============================
	// center_and_print
	//==============================
	// out_buffer has string to print
	// return address in b0
	
center_and_print:
	alloc	loc0=ar.pfs,4,8,6,0

	movl	out0=escape			// print escape
	br.call.sptk.few	b4=write_stdout

str_loop2:	
	mov	loc1=r13		// out_buffer
	sub	loc2=r4,loc1		// find size of string by subtracting
	
	mov	loc3=80			// size of screen+1
	sub	loc2=loc3,loc2		// get size

	cmp.lt	p6,p7=loc2,r0
(p6)	br.cond.dpnt	done_center	// if negative, don't center	

	shr	out1=loc2,1		// divide by two

	mov	out0=0
	br.call.sptk.few	b1=num_to_ascii
	


	movl	out0=C				// print trailing C
	br.call.sptk.few	b4=write_stdout
	
	mov	out0=r13			// out_buffer
	br.call.sptk.few	b4=write_stdout
	
done_center:
	mov	ar.pfs=loc0
	br.ret.sptk.many	b0

		
	//===========================
	// num_to_ascii
	//===========================
	// in0=0=stdout 1=stcat
	// in1=number
	// b1
	
num_to_ascii:
	alloc	loc0=ar.pfs,2,8,6,0

	movl	loc1=ascii_buffer	// point to buffer
	add	loc2=9,loc1		// point to end of buffer

	mov	out1=10			// divide by 10
	mov	out0=in1		// move in number to divide	

num_loop:
	br.call.sptk.few	b3=divide

after_div:		
	add	r9=0x30,r9		// convert to ascii
	st1	[loc1]=r9,-1		// store to output

	mov	out0=r8			// move quotient back in
	cmp.ne	p6,p7=0,r8		// see if done
(p6)	br.cond.dptk	num_loop	

	add	loc1=1,loc1		// fix pointer

	cmp.eq	p6,p7=0,in0
	mov	out0=loc1
(p6)	br.call.sptk	b4=write_stdout
(p7)	br.call.sptk	b5=strcat	
	
num_all_done:		
	mov	ar.pfs=loc0		// restore reg stack
	br.ret.sptk	b1		// return

			
//===========================================================================
//.data
//===========================================================================
		
ver_string:		.asciz  " Version "
compiled_string:	.asciz  ", Compiled "
linefeed:		.asciz  "\n"
.ifdef FAKE_PROC
cpuinfo:		.asciz  "proc/cpu.ia64"
.else
cpuinfo:		.asciz  "/proc/cpuinfo"
.endif
megahertz:		.asciz	"MHz "	
processor:		.asciz  " Processor, "
ram_comma:		.asciz  "M RAM, "
bogo_total:		.asciz  " Bogomips Total\n"

default_colors:		.asciz "\033[0m\n\n"
escape:			.asciz "\033["
C:			.asciz "C"

array:	.byte	0,5,10,17,23
		
one:			.asciz	"One "
two:			.asciz	"Two "
three:			.asciz  "Three "
four:			.asciz	"Four "
many:			.asciz	"Many "
	
.include        "logo.lzss_new"	

//============================================================================
//.bss
//============================================================================

// includes alignment after size
	
bss_begin:
.lcomm uname_info,	(65*6),4
.lcomm sysinfo_buff,	(64),4
.lcomm ascii_buffer,	10,4
.lcomm text_buf,	(N+F-1),4
.lcomm disk_buffer,	4096,4        // we cheat!!!!
.lcomm out_buffer,	16384,4

 // see /usr/src/linux/include/linux/kernel.h
	
