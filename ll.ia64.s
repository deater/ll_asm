//
//  linux_logo in ia64 assembler    0.7
//
//  by Vince Weaver <vince@deater.net>
//
//  assemble with     "as -o ll.o ll.ia64.s"
//  link with         "ld -o ll ll.o"

//  BUGS:  No Pretty Printing (rounding, cpu-model cleanup)
//      :  Doesn't print vendor name


// FIXME!  I apologize for the overall crudeness of this port
//	   I never figured out how syscall return values work
//	   And bizzarrely it won't work when being gdb'd
//
//	   I also didn't paralellize or use specilative reads
//	     or branches.
//	   Maybe someday in the future I'll have time to work
//	     on the above.
	

// offsets into the results returned by the uname syscall
.equ U_SYSNAME,0
.equ U_NODENAME,65
.equ U_RELEASE,65*2
.equ U_VERSION,(65*3)
.equ U_MACHINE,(65*4)
.equ U_DOMAINNAME,65*5

// offset into the results returned by the stat syscall
.equ S_SIZE,48

// syscall numbers

.equ SYSCALL_EXIT,1025	
.equ SYSCALL_READ,1026
.equ SYSCALL_WRITE,1027
.equ SYSCALL_CLOSE,1029
.equ SYSCALL_OPEN,1028
.equ SYSCALL_STAT,1210
.equ SYSCALL_UNAME,1130

	.globl _start
_start:	

	alloc   loc0 = ar.pfs,0,8,5,8	// 0 inputs, 8 local, 5 outputs
	                                //    8 rotating
					// the whole register-stack is
					//    impossible complex, see
					//    the intel documentation
   ;;	

		
        //=========================
	// PRINT LOGO
	//=========================

	movl	loc1=new_logo		// point input to new_logo
	movl	out4=out_buffer		// point output to buffer
	;; 
	mov	r13=out4		// save pointer to begin of output


main_logo_loop:
	;; 
	ld1	loc2=[loc1]		// load character
	;; 
	add	loc1=1,loc1		// update pointer
	
	cmp.eq	p6,p7=0,loc2
	;; 
(p6)	br.cond.dptk	done_logo	// if zero, we are done
	;; 
	cmp.ne	p6,p7=27,loc2		// if ^[, we are a color
	;; 
(p6)    br.cond.dptk	blit_repeat     // if not go to the RLE blit
	
	mov	loc7=27			// output ^[[ to buffer
	;; 
	st1	[out4]=loc7
	;; 
	add	out4=1,out4
	mov	loc7='['
	;; 
	st1	[out4]=loc7
	;; 
	add	out4=1,out4

	ld1	loc3=[loc1]		// load number of ; separated elements 
	;; 
	add	loc1=1,loc1		// update pointer
	;; 
element_loop:
        ld1	loc2=[loc1]		// load color
	;; 
	add	loc1=1,loc1		// update pointer

	mov	out1=loc2		// convert byte to ascii decimal
	br.call.sptk.many	b1=num_to_ascii

	mov	loc7=';'
	;; 
	st1	[out4]=loc7		// load ';'
	;;
		
	add	out4=1,out4		// and output it
	
	add	loc3=-1,loc3		// decrement counter
	;;
	cmp.ne	p6,p7=0,loc3		// if zero, we are done
	;; 
(p6)	br.cond.dptk	element_loop	// loop if elements left

	add	out4=-1,out4		// remove extra ';'
	
	ld1	loc2=[loc1]		// load last char
	;; 
	add	loc1=1,loc1

	st1	[out4]=loc2		// save last char
	;; 
	add	out4=1,out4
	;; 
	br 	main_logo_loop		// done with color

blit_repeat:
	ld1	loc3=[loc1]		// get times to repeat
	;; 
	add	loc1=1,loc1		// increment pointer
blit_loop:	
	st1	[out4]=loc2		// write character
	;; 
	add	out4=1,out4
	add	loc3=-1,loc3 		// decrement counter
	;; 
	cmp.ne	p6,p7=0,loc3		// if zero, we are done
	;; 
(p6)	br.cond.dptk	blit_loop	// loop if elements left
	;; 
	br	main_logo_loop

done_logo:
	mov     out0=1			// stdout
	mov	out1=r13		// output_buffer
	br.call.sptk.many	b0=strlen
	mov     r15=SYSCALL_WRITE
	mov	out2=r8			// move length to right place
	;;
	br.call.sptk.many       b0=syscall

	movl	out0=line_feed	// print line feed
	br.call.sptk.many	b4=put_char

	
	//==========================
	// PRINT VERSION
	//==========================

	mov	r15=SYSCALL_UNAME		// uname syscall
	movl	out0=uname_info			// uname struct
	;; 
	br.call.sptk.many	b0=syscall	// do syscall
	;;
	
	mov	out4=r13			// restore output to out_buffer

	mov	loc4=out0
	;; 
	add	out0=U_SYSNAME,loc4		// os-name from uname "Linux"
	br.call.sptk.many	b5=strcat
	;; 
	movl	out0=ver_string			// source is " Version "
	br.call.sptk.many	b5=strcat
	;; 
	add	out0=U_RELEASE,loc4		// version from uname "2.4.1"
	br.call.sptk.many	b5=strcat
	;; 
	movl	out0=compiled_string		// source is ", Compiled "
	br.call.sptk.many	b5=strcat
	;; 
	add	out0=U_VERSION,loc4		// compiled date
	br.call.sptk.many	b5=strcat
	;; 
	mov	out1=r13  		// restore saved location of out_buff
	
	br.call.sptk.many	b0=strlen		// returns size in $18
	;; 
	br.call.sptk.many	b3=center		// print some spaces
	;; 
	mov	r15=SYSCALL_WRITE	// write out the buffer
	mov	out0=1
	mov	out1=r13
	br.call.sptk.many	b0=strlen
	;;
	mov	out2=r8
	br.call.sptk.many	b0=syscall
	
	movl	out0=line_feed			// print line feed
	br.call.sptk.many	b4=put_char

	//===============================
	// Middle-Line
	//===============================

	mov	out4=r13			// restore output pointer
		
	//=========
	// Load /proc/cpuinfo into buffer
	//=========


// WHY DOES THIS HANG UNDER GDB?
	
	mov	r15=SYSCALL_OPEN		// open()
	movl	out0=cpuinfo			// '/proc/cpuinfo'
	mov	out1=0				// O_RDONLY <bits/fcntl.h>
	;; 
	br.call.sptk.many       b0=syscall	// syscall.  fd returned in r15  
						// we should check that r15>=0
	;;

	mov	loc0=3	// FIXME.  Can't figure out return value from
			//         syscall so we cheat since it will just be 3
	;; 
	mov	r15=SYSCALL_READ		// read
	mov	out0=3				// copy fd
	movl	out1=disk_buffer
	;; 
	mov	out2=4096		 	// 4096 is upper-limit guess of procfile
	;; 

	br.call.sptk	b0=syscall
	
	;; 
	mov	r15=SYSCALL_CLOSE
	mov	out0=loc0			// restore fd
	br.call.sptk.many	b0=syscall	// close
	;;



	//=============
	// Number of CPU's
	//=============

	mov	out0='I'			// find 'cycl' and grab after ':'
	mov	out1='P'
	mov	out2='S'
	;; 
	br.call.sptk	b1=count_string
	;; 

	// Assume <=4 CPU's
	// have to learn how to do arrays on ia64

	cmp.ne	p6,p7=4,r8
	;; 
(p6)	br.cond.dptk	check_three	
	;; 
	movl	out0=four
	br	print_num_cpu
check_three:
	cmp.ne	p6,p7=3,r8
	;; 
(p6)	br.cond.dptk	check_two	
	movl	out0=three
	br	print_num_cpu
check_two:
	cmp.ne	p6,p7=2,r8
	;; 
(p6)	br.cond.dptk	check_one	
	movl	out0=two
	br	print_num_cpu
check_one:	
	movl	out0=one
print_num_cpu:		
	br.call.sptk	b5=strcat
	

	//=========
	// MHz
	//=========
	
	mov	out0='M'		// find 'cycl' and grab after ':'
	mov	out1='H'
	mov	out2='z'
	mov	out3='.'
	;;
	br.call.sptk.many	b1=find_string
	;; 
	movl	out0=megahertz		// print 'MHz '
	br.call.sptk.many	b5=strcat
	;; 
   
   	//=========
	// Chip Name
	//=========
	
   	mov     out0='i'     	// find 'ily' and grab  after :
	mov	out1='l'
	mov	out2='y'
	mov	out3='\n'
	;; 
	br.call.sptk.many	b1=find_string
	;; 

	movl	out0=comma			// print ', '
	br.call.sptk.many	b5=strcat
	;; 
	//========
	// RAM
	//========
	
	mov	r15=SYSCALL_STAT		// stat() syscall
	movl	out0=kcore			// /proc/kcore
	movl	out1=stat_buff
	;; 
	br.call.sptk.many	b0=syscall
	;;

	movl	loc3=stat_buff
	;; 
	add	loc3=S_SIZE,loc3
	;; 
	ld8	loc4=[loc3]	
	;; 
	shr	loc4=loc4,10   		// divide to get K
	;; 
	shr	loc4=loc4,10	       	// divide to get M
	;; 
	mov	out1=loc4		// convert to ascii
	br.call.sptk.many	b1=num_to_ascii

	;;
	movl	out0=ram_comma    	// print 'M RAM, '
	br.call.sptk.many	b5=strcat

	//========
	// Bogomips
	//========
	;; 
	mov	out0='I'      		// find 'IPS' and grab up to \n
	mov	out1='P'
	mov	out2='S'
	mov	out3='\n'
	;; 
	br.call.sptk.many	b1=find_string
	;;
	movl	out0=bogo_total
	;; 
	br.call.sptk.many	b5=strcat


	mov	out1=r13  		 	// restore saved location of out_buff
	
	br.call.sptk.many	b0=strlen	// returns size in $18
	;; 
	br.call.sptk.many	b3=center	// print some spaces
	
	mov	r15=SYSCALL_WRITE	// write the buffer out
	mov	out0=1
	mov	out1=r13
	br.call.sptk.many	b0=strlen
	mov	out2=r8
	br.call.sptk.many	b0=syscall

	movl	out0=line_feed	// print line feed
	br.call.sptk.many	b4=put_char

	//=================================
	// Print Host Name
	//=================================

	movl	loc0=uname_info			// uname struct
	;;	
	add	out1=U_NODENAME,loc0		// print node name

	br.call.sptk.many	b0=strlen	// center
	;; 
	br.call.sptk.many	b3=center
	;; 
	mov	r15=SYSCALL_WRITE	 	// write it out
	mov	out0=1
	add	out1=U_NODENAME,loc0 
	br.call.sptk.many	b0=strlen
	mov	out2=r8
	br.call.sptk.many	b0=syscall
	;; 
	mov	r15=SYSCALL_WRITE	// restore default colors
	mov	out0=1
	movl	out1=default_colors
	br.call.sptk.many	b0=strlen
	mov	out2=r8
	br.call.sptk.many	b0=syscall
	;; 
	movl	out0=line_feed	// print line feed
	br.call.sptk.many	b4=put_char
	br.call.sptk.many	b4=put_char

	//================================
	// Exit
	//================================

	mov     out0=0			// 0 exit value
	mov     r15=SYSCALL_EXIT	// load syscall number
;;
	br.call.sptk.many       b0=syscall	// call to syscall
	

	//======================
	// syscall
	//======================
	// this is the only way I could figure out how to
	// get the register stack set up right, by having
	// the syscall in its own procedure
syscall:	
	break.i			0x100000	//  do the syscall
	;; 
	br.ret.sptk.many        b0		//  return

	
	//======================
	// syscall with return
	//======================
	// is the value returned on the stack?
	// some seem to, others segfault?
syscall_with_return:	
	break.i			0x100000	//  do the syscall
	;;

	ld4	r8=[r2]
	;; 

	br.ret.sptk.many        b0		//  return
	
		
	//=================================
	// Divide
	// yes this is an awful algorithm, but simple
	// and uses few registers
	//=================================
	//  in1 =numerator in2=denominator
	//  r8=quotient  r9=remainder
	
divide:
	alloc	r29=ar.pfs,5,8,5,8
	mov	r8=r0			// zero out result
	;;

	setf.sig	f3=in1
	setf.sig	f4=in2
	;; 
divide_loop:

	setf.sig	f8=r8

	;; 
	xma.l	f7=f8,f4,f0		// multiply temp by denominator
	add	r8=1,r8
	;;
	getf.sig	loc0=f7
	;;
		
	cmp.le	p8,p9=loc0,in1		// is it greater than numerator?
	;;
(p8)	br.cond.dptk	divide_loop	// if not, increment temp
		
	;; 
	add	r8=-2,r8		// otherwise went too far, decrement
					// and done
	;;
	setf.sig  f8=r8
	;; 
	xma.l	f7=f8,f4,f0		// calculate remainder
	;;
	getf.sig	loc0=f7
	;;
	sub	r9=in1,loc0		// R=N-(Q*D)
	mov	ar.pfs=r29		// restore register file
	br.ret.sptk.many        b3	//  return

	//=================================
	// FIND_STRING 
	//=================================
	//   in3 is char to end at
	//   in0,in1,in2 are 3-char ascii string to look for
	//   in4 points at output buffer
	
find_string:
	alloc	r28=ar.pfs,5,8,5,0
	movl	loc0=disk_buffer	// look in cpuinfo buffer
	;;

find_loop:
	ld1	loc1=[loc0]		// watch for first char
	;;
	add	loc0=1,loc0

	cmp.eq	p8,p9=0,loc1		// is it zero
	;;
(p8)	br.cond.dptk	done		// if so we are done
	;; 
	cmp.ne	p10,p11=loc1,in0	// watch for first char
	;; 
(p10)	br.cond.dptk	find_loop
	ld1	loc1=[loc0]		// watch for second char
	;;
	add	loc0=1,loc0
	cmp.ne	p10,p11=loc1,in1
	;; 
(p10)	br.cond.dptk	find_loop	
	
	ld1	loc1=[loc0]		// watch for third char
	;; 
	add	loc0=1,loc0
	cmp.ne	p10,p11=loc1,in2
	;; 
(p10)	br.cond.dptk	find_loop
	
					// if we get this far, we matched
find_colon:
	ld1	loc1=[loc0]		// repeat till we find colon
	;;
	add	loc0=1,loc0

	cmp.eq	p8,p9=0,loc1		// escape if hit a null
	;;
(p8)	br.cond.dptk	done

	cmp.ne	p10,p11=':',loc1
	;; 
(p10)	br.cond.dptk	find_colon

	add	loc0=1,loc0		// skip a char [should be space]
	;; 
store_loop:	 
	ld1	loc1=[loc0]
	;; 
	add	loc0=1,loc0


	cmp.eq	p6,p7=0,loc1		// is it a null?
	;;
(p6)	br.cond.dptk	done

	cmp.eq	p6,p7=in3,loc1		// is it end string?
	;; 
(p6)	br.cond.dptk 	almost_done	// if so, finish

//	cmpeq	$6,' ',$7		// cpuinfo has trailing spaces?
//	bne	$7,almost_done		// watch for them too
	st1	[in4]=loc1		// if not store and continue
	;; 
	add	in4=1,in4
	br	store_loop
	;; 
almost_done:	 
	st1	[in4]=r0		// replace last value with null

done:
	mov	ar.pfs=r28
	br.ret.sptk.many	b1


	//=================================
	// COUNT_STRING 
	//=================================
	//   in0,in1,in2 are 3-char ascii string to look for
	//   r8 points at result
	
count_string:
	alloc	r28=ar.pfs,5,8,5,0
	mov	r8=r0
	movl	loc0=disk_buffer	// look in cpuinfo buffer
	;;

count_loop:
	ld1	loc1=[loc0]		// watch for first char
	;;
	add	loc0=1,loc0

	cmp.eq	p8,p9=0,loc1		// is it zero
	;;		
(p8)	br.cond.dptk	done_counting	// if so we are done
	;; 	
	cmp.ne	p10,p11=loc1,in0	// watch for first char
	;; 
(p10)	br.cond.dptk	count_loop
	ld1	loc1=[loc0]		// watch for second char
	;;
	add	loc0=1,loc0
	cmp.ne	p10,p11=loc1,in1
	;; 
(p10)	br.cond.dptk	count_loop	
	
	ld1	loc1=[loc0]		// watch for third char
	;; 
	add	loc0=1,loc0
	cmp.ne	p10,p11=loc1,in2
	;; 
(p10)	br.cond.dptk	count_loop
	
					// if we get this far, we matched

	add	r8=1,r8
	br	count_loop

done_counting:
	mov	ar.pfs=r28
	br.ret.sptk.many	b1

	//================================
	// put_char
	//================================
	// output value at in0

put_char:
	alloc	r29=ar.pfs,5,8,5,0
	mov	r15=SYSCALL_WRITE	// number of the "write" syscall
	mov	out0=1			// stdout
	mov	out2=1			// 1 byte to output
	mov	out1=in0
	;; 
	br.call.sptk.many	b0=syscall	// do syscall
	mov	ar.pfs=r29
	br.ret.sptk.many        b4	//  return

	//================================
	// strcat
	//================================
	// in0 = "source"
	// in4 = "destination"
strcat:
	alloc	r29=ar.pfs,5,8,5,0
strcat_loop:
	ld1	loc0=[in0]
	;; 
	add	in0=1,in0
	st1	[in4]=loc0
	;; 
	add	in4=1,in4
	
	cmp.ne	p6,p7=0,loc0 
(p6)	br.cond.dptk	strcat_loop	// is it zero? if not, loop
	;; 
	
	add	in4=-1,in4		// back up pointer to the zero

	mov	ar.pfs=r29
	br.ret.sptk.many	b5	// return
	
	//===============================
	// strlen
	//===============================
	// in1 points to string
	// r8 is returned with length

strlen:
	alloc	r30=ar.pfs,5,8,5,0
	mov	loc0=in1		// copy pointer
	mov	loc1=r0			// set count to 0
	;; 
str_loop:
	add	loc0=1,loc0		// increment pointer
	add	loc1=1,loc1		// increment counter
	;; 
	ld1	loc2=[loc0]		// load byte
	;;		
	cmp.ne	p6,p7=0,loc2 
(p6)	br.cond.dptk	str_loop	// is it zero? if not, loop
	;;
	mov	r8=loc1			// return value in r8
	mov	ar.pfs=r30
	br.ret.sptk.many        b0	//  return

	//==============================
	// center
	//==============================
	// r8 has length of string
	
	
center:
	alloc	r30=ar.pfs,5,8,5,0
	;;
	cmp.le	p6,p7=80,loc1		// see if we are >80
(p6)	br.cond.dptk	     done_center   // if so, bail

	mov	loc1=80	       		// 80 column screen
	;;
	sub	loc1=loc1,r8		// subtract strlen
	;;
	shr	loc1=loc1,1		// divide by two
	movl	out0=space	// load pointer to space		
center_loop: 
	br.call.sptk.many 	b4=put_char   // and print that many spaces
	add	loc1=-1,loc1
	;;
	cmp.ne	p6,p7=0,loc1 
(p6)	br.cond.dptk	center_loop	// is it zero? if not, loop	

done_center:
	;;
	mov	ar.pfs=r30
	br.ret.sptk.many	b3


	//===========================
	// ascii_to_num
	//===========================
	// in1=string
	// r8=result

ascii_to_num:
	alloc	r30=ar.pfs,5,8,5,0
	;;
	mov	r8=0			// zero result
	mov	loc1=10
ascii_loop:		
	ld1	loc0=[in1]		// load value
	;;
	add	in1=1,in1
	cmp.ne	p6,p7=0,loc0
	br.cond.dptk	ascii_done
	
	setf.sig	f4=loc1
	setf.sig	f8=r8
	;;
	xma.l	f7=f8,f4,f0		// shift decimal left
	;;
	getf.sig	loc3=f7
	
	add		loc3=-0x30,loc3	// convert ascii->decimal
	add		r8=r8,loc3	// add it in

	br	ascii_loop
ascii_done:			
	mov	ar.pfs=30
	br.ret.sptk.many 	b7
	
	//===========================
	// num_to_ascii
	//===========================
	// in1=number
	// in4=output

num_to_ascii:
	alloc	r30=ar.pfs,5,8,5,0

	movl	loc0=string_buffer	//load buffer
	mov	loc1=r0
	;; 
	add	loc0=63,loc0		// start at end of string
	;; 
	st1	[loc0]=r0		// make sure trailing zero
	;; 
	add	loc0=-1,loc0		// we work backwards
	;;
	mov	out1=in1
	;; 
num_loop:
	mov	out2=10

	br.call.sptk.many	b3=divide
	;;
		
	add	loc7=r8,r9		// if remainder and quotient zero
	;;
	cmp.eq	p6,p7=0,loc7
	;; 
(p6)	br.cond.dptk	num_done	// then we are done shifting
	;;	
	add	r9=0x30,r9		// convert to ascii

	;; 
	st1	[loc0]=r9		// and store to buffer
	;;
	 
	add	loc0=-1,loc0		// move to left
	mov	out1=r8
	br	num_loop
	;; 
num_done:		
	add	loc0=1,loc0		// done, but re-adjust pointer
	;; 
num_loop2:		
	ld1	loc6=[loc0]		// write out the buffer
	;; 
	add	loc0=1,loc0
	cmp.eq	p6,p7=0,loc6
	;; 
(p6)	br.cond.dptk	num_all_done	// then we are done shifting
	;; 
	st1	[in4]=loc6
	;; 
	add	in4=1,in4
	br	num_loop2
	
num_all_done:		
	;; 
	mov	ar.pfs=r30
	br.ret.sptk	b1
	
			
//===========================================================================
//.data
//===========================================================================
		
.include "logo.inc"

line_feed:	.ascii  "\n"
ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
space:		.ascii	" \0"
megahertz:	.ascii	"MHz Intel \0"
comma:		.ascii	", \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"

default_colors:	.ascii	"\033[0m\0"

cpuinfo:	.ascii	"/proc/cpuinfo\0"
kcore:		.ascii	"/proc/kcore\0"


one:	.ascii	"One \0"
two:	.ascii	"Two \0"
three:	.ascii  "Three \0"
four:	.ascii	"Four \0"


//============================================================================
//.bss
//============================================================================


.lcomm stat_buff,1024,4
	// urgh get above from /usr/src/linux/include/asm/stat.h
	// not glibc

.lcomm uname_info,1024,4
	
.lcomm	string_buffer,64,4
.lcomm	disk_buffer,4096,4	// we cheat!!!!	
	
.lcomm	out_buffer,16384,4	// we cheat, 16k output buffer



