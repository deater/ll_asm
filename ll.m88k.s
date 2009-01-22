;;
;; linux_logo in m88k assembler    0.33
;;
;;  by Vince Weaver <vince _at_ deater.net>
;;
;;  assemble with     "as -o ll.o ll.m88k.s"
;;  link with         "ld -o ll ll.o"

;; m88k - a short-lived RISC chip made by Motorola after
;;        the m68k but before the PPC

;; No Linux port is ever likely to happen, so we use NetBSD
;;   under gxemul

;; m88k features (88110 specifically)
;;  - 32 integer registers, r0-r31, r0 = zero, r1 = branch target
;;  - 32 80-bit FP registers, x0-x31, x0 = zero
;;  - GPU (!) instructions, mainly for packing pixels
;;  - Target Instruction Cache (TIC) caches insns at branch target
;;    thus if predicted can run those w/o stalling!
;;  - Both normal TLB and a "block-sized" software managed TLB
;;  - issues in order, can complete out-of-order
;;  - 8kB L1 I and D caches, 2-way

;;  - aligned load/stores only
;;  - can be big or little endian (big endian is default)
;;  - immediates can be signed or unsigned, set by software?
;;  - 3 operand instructions
;;  - branch delay slot is optional (!)
;;  - static branch prediction based on eq0, gt0, etc

;; flags - C = carry 

;; instructions
;;   - integer : add, addu (add.ci add.co add.cio  various carry)
;;     	         cmp (returns a 16-bit value with various flags set)
;;		 divs
;;		 divu (.d makes it a 64-bit division using 2 reg pair)
;;		 muls, mulu (mulu.d is a 64-bit result)
;;		 sub, subu (similar carry/borrow to add)
;;   - bit : clr, ext (extract bit field), extu
;;           ff0 (find first 0) 0 is LSB, 31 MSB 32= not found
;;	     ff1 (find first 1)
;;	     mak (make bit field)  select bits from a register
;;	     rot (rotate) rotates right
;;	     set (set bit field)
;;   - logical : and  (and.c complements, and.u does upper 16 bits)
;;     	         mask, 
;;		 or (or.c complements, or.u does upper 16 bits)
;;		 xor (xor.c complements, xor.u does upper 16 bits)
;;   - GPU : padd, padds, pcmp, pmul, ppack, prot, psub, psubs, punpk
;;   - branches : bb0 (branch if selected bit is 0. bb0.n has delay slot)
;;     		  bb1 (branch if selected set is 1. bb1.n has delay slot)
;;                bcnd (eq0, ne0, gt0, lt0, ge0, le0) also .n option
;;		  br (branch always) also a .n option
;;		  bsr (branch subroutine). saved in r1.  .n option
;;		  illop (illegal op), jmp, jsr
;;		  rte, tb0, tb1, tbnd, tcnd (trap instructions)
;;   - load/store : ld .b .bu .h .hu .d 
;;     		      either a reg or a 16-bit constant added to source
;;		      in scaled mode (surrounded in brackets) it is
;;		      shifted by the size of the opreation
;;     		    lda, ldcr (control reg)
;;     		    st (similar to ld)
;;		    stcr, xcr, xmem (exchange reg and mem)
;;   - FPU : fadd, fcmp, fcmpu, fcvt, fdiv, fldcr
;;           flt (convert int to fp), fmul, fsqrt (software implemented), fstcr
;;           fsub, fxcr, int (round floating point to int)
;;           mov, nint (round fp to nearest int), trnc (truncate fp to int)
;;
;;   - NO SHIFT INSTRUCTIONS.  
;;     for "asr rx,y" use "ext rx,rx,32<y>"
;;     for "lsr rx,y" use "extu rx,rx,32<y>"
;;     for "lsl rx,y" use "mak rx,rx,32<y>"

;; p 353 begins instruction reference

;; r0 = constant 0
;; r1 = return address
;; r2-r9 = called proc parameters
;; r10-r13 = scratch
;; r14-r25 = callee preserved
;; r26-r29 = reserved by linker
;; r30 = frame pointer
;; r31 = stack pointer

;; openBSD

;; use ktrace/kdump instead of strace

;; system calls are done with "tb0 0,0,0x80"
;;   syscall number in r13
;;   arguments in r2-r9
;;  return value in r2 (which is why r2 has result of execve at start?)
;;  URGH!  OpenBSD expects a sycall to look like this
;;      tb0 0,0,0x80
;;	br  error
;;	jmp r1
;;  It modifies the trap return to skip an instruction if no error
;;  So you have to waste an instruction if you are not handling errors


/* OPTIMIZATION */
/* + 8192 = Initial code, straight port from PPC code                    */
/* + 6008 = Merge data and text segments                                 */
/* + 4096 = strip.  aout format wants page size multiple                 */
/* + 1376 = don't count trailing zeros toward filesize                   */
/* + 1352 = we are smaller than 64k so pointers are only 16-bit          */
/*          this saves us 4 bytes for each pointer load                  */
/* + 1344 = some minor tweaks to the LZSS decompression code             */
/* + 1320 = make pointers 16 bit with the first line code                */
/* + 1284 = make pointers 16 bit with the middle and last line           */
/* + 1264 = complete 16-bit pointer conversion                           */
/* + 1260 = have num_to_ascii fall through to strcat                     */
/* + 1248 = make CTL_KERN the common case for sysctl                     */
/* + 1240 = remove "hello world" test string that I had forgotten        */

;; Sycscalls
;; /usr/include/sys/syscall.h
.equ SYSCALL_EXIT,     1
.equ SYSCALL_READ,     3
.equ SYSCALL_WRITE,    4
.equ SYSCALL_OPEN,     5
.equ SYSCALL_CLOSE,    6
.equ SYSCALL_SYSCTL,   202

;; sysctls
;; /usr/include/sys/sysctl.h
.equ CTL_KERN,1
.equ CTL_HW,6

.equ KERN_OSTYPE,1
.equ KERN_OSRELEASE,2
.equ KERN_HOSTNAME,10
.equ KERN_OSVERSION,27

.equ HW_PHYSMEM,5

.equ STDIN, 0
.equ STDOUT,1
.equ STDERR,2

.include "logo.include"

	.globl start	
	
.text
.align 4

start:	

	or	r0,r0,r0	/* first 2 instructions ignored? */
	or	r0,r0,r0	/* I must be doing something wrong */

        /* ========================= */
	/* PRINT LOGO
	/* ========================= */

;; LZSS decompression algorithm implementation
;; by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
;; optimized some more by Vince Weaver

	/* or.u	r18,r0,hi16(out_buffer) */     /* put out_buffer in r18  */
	/* or	r18,r18,lo16(out_buffer) */
	
	or	r18,r0,lo16(out_buffer)        /* fits in just 16-bits   */

	or	r16,r18,r0	       /* copy out_buffer to r16         */
	or	r21,r0,lo16(text_buf)  /* put text_buf in r21            */
	or	r9,r0,lo16(logo)       /* r9 points to logo              */
	or	r12,r0,lo16(logo_end)  /* r12 points to end of the logo  */
	or	r8,r0,(N-F)	       /* r8 is R (N-F)                  */
	
decompression_loop:
	ld.bu 	r10,r9,r0		/* load in a byte                */
	addu	r9,r9,1			/* increment pointer             */
	
	or	r11,r10,0xff00		/* copy to r11 and load top as   */
					/* a hackish 8-bit counter       */

test_flags:
	cmp	r10,r12,r9	        /* have we reached the end?      */
	bb1	2,r10,done_logo		/* if eq (bit 2 set) then exit   */

	mask	r13,r11,0x1		/* get the bottom bit            */
	extu	r11,r11,32<1>		/* logical shift right           */
	
	bcnd	ne0,r13,discrete_char	/* if low bit set, discrete_char */

offset_length:
	ld.bu  	r10,r9,r0		/* load in 16-bit little endian  */
	ld.bu	r24,r9,1		/* in two byte chunks            */
	addu	r9,r9,2
	
	mak	r24,r24,32<8>		/* re-arrange to be big-endian   */
	or	r24,r24,r10
	
	extu    r15,r24,32<10>		/* P_BITS is 10 */
	addu    r15,r15,THRESHOLD+1 	/* r15 = (r10>>P_BITS)+THRESHOLD+1 */
	                                /*    == match_length              */
					 
output_loop:
	mask    r24,r24,(POSITION_MASK<<8+0xff)	/* mask it               */
	ld.bu   r10,r21,r24		/* load byte from txt_buf[]      */
	addu    r24,r24,1		/* increment pointer             */
	
store_byte:
	st.b	r10,r16,r0	       /* store byte to output           */
	addu	r16,r16,1	       /* increment pointer              */

	st.b    r10,r21,r8	       /* store into text_buf[r]         */
	addu	r8,r8,1		       /* increment r		         */
	mask	r8,r8,(N-1)	       /* mask to handle oflo	         */

	subu	r15,r15,1	       /* decrement out count	         */
	bcnd	ne0,r15,output_loop    /* loop until r15 is zero         */
	
	mask	r13,r11,0xff00	       /* test to see if we are done byte */
	bcnd	ne0,r13,test_flags
	
	br	decompression_loop

discrete_char:

	ld.bu   r10,r9,r0	       /* load a byte                    */
	addu	r9,r9,1	 	       /* increment pointer              */
	or	r15,r0,1	       /* set length to 1                */

	br	store_byte

done_logo:

	or	r3,r18,r0	       /* restore out_buffer             */
	bsr	write_stdout	       /* and print the logo             */
	
	or	r14,r18,r0	       /* restore out_buffer to r14      */
	
	/*==========================*/
	/* PRINT VERSION            */
	/*==========================*/
first_line:

        /* OpenBSD does not have a UNAME syscall  */
	/* We have to use sysctl instead          */

	or	r11,r0,KERN_OSTYPE
	bsr	run_sysctl_kern
	
	or	r16,r0,lo16(sysctl_info)			       
	bsr	strcat		       /* os-name from sysctl "OpenBSD"  */

	or	r16,r0,lo16(ver_string)				
	bsr 	strcat		       /* source is " Version "          */
	
	or	r11,r0,KERN_OSRELEASE
	bsr	run_sysctl_kern
	
	or	r16,r0,lo16(sysctl_info)	
	bsr 	strcat		       /* version from sysctl "4.4"      */
	
	or	r16,r0,lo16(compiled_string)
	bsr 	strcat		       /* source is ", Compiled "        */


	or	r11,r0,KERN_OSVERSION
	bsr	run_sysctl_kern
	
	or	r16,r0,lo16(sysctl_info)	
	bsr 	strcat		       /* compiled info                  */

	or	r16,r0,lo16(linefeed)
	bsr 	strcat		       /* source is "\n"                 */

	bsr	center_and_print       /* write it to screen             */
	

	/*===============================*/
	/* Middle-Line                   */
	/*===============================*/
middle_line:
	or	r14,r18,r0			/* restore out buffer */

	/*================================*/
	/* Load /proc/cpuinfo into buffer */
	/*================================*/

        /* There is no /proc/cpuinfo on OpenBSD  */
	/* So we fake it.  We could do this all  */
	/* with sysctls, but I want the exe size */
	/* to be comparable with Linux.  So      */
	/* instead we parse the output of sysctl */

	or	r13,r0,SYSCALL_OPEN    /* open()                         */
	or	r2,r0,lo16(cpuinfo)    /* '/proc/cpuinfo'                */
	or	r3,r0,r0	       /* O_RDONLY <fcntl.h>             */
	tb0	0,r0,0x80	       /* syscall.  fd in r2.            */
	br	exit		       /* exit if error                  */

	or	r8,r2,r0	       /* save our fd for later		 */

	or	r13,r0,SYSCALL_READ    /* read()                         */
	or	r3,r0,lo16(disk_buffer)
	or	r4,r0,32768	       /* assume less than 32k           */
	tb0	0,r0,0x80
	br	exit	 	       /* exit if error                  */

	or	r2,r0,r8	       /* restore fd                     */
	or	r13,r0,SYSCALL_CLOSE   /* close()                        */
	tb0	0,r0,0x80
	br	exit	 	       /* exit if error                  */
	
	/*================*/
	/* Number of CPUs */
	/*================*/
number_of_cpus:

	/* Assume 1 CPU for now, even though people have run SMP m88k*/
	
	or	r16,r0,lo16(one)	
	bsr 	strcat		       /* One                            */
	
	/*=========*/
	/* MHz     */
	/*=========*/
print_mhz:

	or.u	r2,r0,('o'<<8)+'d'
	or	r2,r2,('e'<<8)+'l'     /* find model                     */
	or	r3,r0,','
	or	r4,r0,'M'	
 	bsr	find_string
   
	or	r16,r0,lo16(megahertz)	
	bsr 	strcat		       /* MHz                            */
	
	/*=============*/
	/* Chip Name   */
	/*=============*/
chip_name:

	or.u	r2,r0,('o'<<8)+'d'
	or	r2,r2,('e'<<8)+'l'     /* find model                     */
	or	r3,r0,'='	       /* start at =			 */
	or	r4,r0,','	       /* grab until ,			 */

	bsr	find_string
	
	or	r16,r0,lo16(comma)	
	bsr 	strcat		       /* ", "                           */
   
	/*========*/
	/* RAM    */
	/*========*/
ram:

	or	r10,r0,CTL_HW
	or	r11,r0,HW_PHYSMEM
	bsr	run_sysctl

	or	r3,r0,lo16(sysctl_info)
	
	ld	r2,r3,r0               /* load bytes of RAM into r2      */

	extu	r2,r2,32<20>	       /* divide by 2^20 to get MB       */

	or	r5,r0,r0	       /* set to write using strcat      */
	bsr	num_to_ascii	       /* convert to ascii               */

	or	r16,r0,lo16(ram_comma)	
	bsr 	strcat		       /* "M RAM, "                      */

	/*============*/
	/* Bogomips   */
	/*============*/
bogomips:

	/* OpenBSD has no concept of Bogomips... */
      
	bsr	center_and_print       /* center and print it            */


	/*=================================*/
	/* Print Host Name                 */
	/*=================================*/
last_line:

	or	r14,r18,r0	       /* restore out buffer             */

	or	r11,r0,KERN_HOSTNAME
	bsr	run_sysctl_kern
	
	or	r16,r0,lo16(sysctl_info)	
					
	bsr	strcat		       /* hostname		         */

	bsr	center_and_print

	or	r3,r0,lo16(default_colors)	
	
	bsr	write_stdout	       /* restore the default colors     */

	
	/*================================*/
	/* Exit                           */
	/*================================*/
exit:	
	or	r2,r0,r0	       /* exit value of zero             */
	or      r13,r0,SYSCALL_EXIT    /* put the exit syscall in r13    */
	tb0	0,r0,0x80	       /* and exit                       */
	
	/*=================================*/
	/* FIND_STRING                     */
	/*=================================*/
	/*   r3 is char to start at        */
	/*   r4 is char to end at          */
	/*   r2 is the 4-char to look for  */
	/*   r5,r6,r7 trashed              */
find_string:
	or	r5,r0,lo16(disk_buffer)        /* Look in disk buffer    */
find_loop:
	ld.bu	r6,r5,0		       /* load first byte */
	mak	r7,r6,32<8>
	ld.bu	r6,r5,1		       /* load second byte */
	or	r7,r7,r6
	mak	r7,r7,32<8>
	ld.bu	r6,r5,2		       /* load third byte */
	or	r7,r7,r6
	mak	r7,r7,32<8>	
	ld.bu	r6,r5,3		       /* load fourth byte */
	or	r7,r7,r6	

	addu	r5,r5,1		       /* increment pointer */

	bcnd	eq0,r6,done	       /* if null, we are done           */
	
	cmp	r7,r2,r7	       /* compare with out 4 char string */
	bb1	3,r7,find_loop	       /* if (ne==3), keep looping       */
	
				       /* if we get this far, we matched */

find_start_char:

	ld.bu	r6,r5,0		       /* repeat till we find r3 char    */
	addu	r5,r5,1		       
	
	bcnd	eq0,r6,done	       /* if null, we are done           */
	
	cmp	r7,r6,r3
	bb1	3,r7,find_start_char   /* if no match, repeat		 */
	
store_loop:
	 ld.bu	r6,r5,r0	       /* load character                 */
	 addu	r5,r5,1
	 
	 bcnd	eq0,r6,done	       /* if null, bail			 */

    	 cmp	r7,r6,r4	       /* is it end char?                */
	 bb1 	2,r7,almost_done       /* if so, finish                  */
	 st.b	r6,r14,r0	       /* if not store and continue      */
	 addu	r14,r14,1
	 br	store_loop
	 
almost_done:	 
	st.b	r0,r14,r0	       /* replace last value with null */

done:
	jmp	r1		       /* return                         */


	/*==============================*/
	/* center_and_print             */
	/*==============================*/
	/* r14 is end of buffer         */
	/* r18 is start of buffer       */
	/* r19 is saved link register   */
	/* r10,r11 trashed */
	
center_and_print:

	or 	r19,r1,r0	       /* back up return address         */

	subu	r10,r14,r18	       /* calc length of buffer          */
					
	cmp	r11,r10,80	       /* see if we are >80              */
	bb1	7,r11,done_center      /* see if ge (bit 7)              */

	or	r3,r0,lo16(escape)
	bsr	write_stdout	       /* print escape character         */

	or	r11,r0,80	       /* 80 column screen               */
	subu	r11,r11,r10	       /* subtract strlen                */
	extu	r2,r11,32<1>	       /* divide by two                  */

	or	r5,r0,1		       /* print to stdout                */
	bsr	num_to_ascii	       /* print number                   */
	
	or	r3,r0,lo16(C)	
	bsr	write_stdout	       /* print C character              */
				       /* ansi for shift right is ^[numC */

done_center:	

	or	r3,r18,r0	       /* point to string to print       */

	or	r1,r19,r0	       /* restore link register          */
				       /* write_stdout returns for us    */

	/*================================*/
	/* WRITE_STDOUT                   */
	/*================================*/
	/* r3 has string                  */
	/* r2,r4,r13 trashed         	  */
		
write_stdout:
	or	r4,r0,r0	       /* string length counter       */
strlen_loop:
	ld.bu 	r2,r3,r4	       /* get byte from (r3+r4)       */
     	addu	r4,r4,1		       /* increment counter           */
	bcnd	ne0,r2,strlen_loop     /* if not zero keep counting   */
	
	subu	r4,r4,1		       /* adjust to not count final 0 */
	or	r13,r0,SYSCALL_WRITE   /* write syscall               */
	or	r2,r0,STDOUT	       /* write to stdout	      */
	tb0	0,r0,0x80	       /* syscall                     */
	br	exit		       /* exit if error               */
	jmp	r1		       /* return                      */


	/*==============================*/
	/* run_sysctl                   */
	/*==============================*/
	/* r10,r11 = sysctl number      */
	/* size is hard-coded 256       */
	/* result goes to sysctl_info   */
run_sysctl_kern:
	or	r10,r0,CTL_KERN	       /* setup more common CTL_KERN    */
run_sysctl:
	or	r2,r0,lo16(sysctl_num1)/* arg1: point r2 to sysctl_num1 */
	st	r10,r2,r0	       /*       save r10 to sysctl_num1 */
	st	r11,r2,4	       /*       save r11 to sysctl_num2 */
	or	r3,r0,0x2	       /* arg2: set size to 2           */
	addu	r4,r2,8		       /* arg3: point r4 to sysctl_info */
	addu	r5,r2,256	       /* arg4: point r5 to sysctl_size */
	or	r10,r0,256	       /*       sysctl_size is 256      */
	st	r10,r5,r0	       /*       save to memory          */
	or	r6,r0,r0	       /* arg5: NULL                    */
	or	r7,r0,r0	       /* arg6: 0                       */

	or      r13,r0,SYSCALL_SYSCTL  /* set sysctl syscall            */
	tb0	0,r0,0x80
	br	exit	 	       /* exit if error                 */

	jmp	r1		       /* return */

	/*===============================*/
        /* Num to Ascii                  */
	/*===============================*/
	/* num is in r2                  */
	/* r5=0 strcat, otherwise stdout */
	/* r5,r6,r7,r8          trashed  */

num_to_ascii:
	or	r7,r0,lo16(num_to_ascii_buff+9)
					/* the end of a backwards growing  */
					/* 10 byte long buffer.            */

div_by_10:
	or	r4,r2,r0		/* copy to r4			   */
	divu	r2,r2,10		/* divide r3 by 10, store in r3    */
	
	mulu	r8,r2,10		/* find remainder.  1st q*dividend */
	subu	r6,r4,r8		/* then subtract from original = R */
	addu	r6,r6,0x30		/* convert remainder to ascii      */
    	
	st.b	r6,r7,r0		/* Store to backwards buffer       */
	subu	r7,r7,1			/* decrement backwards buffer      */

	bcnd	ne0,r2,div_by_10	/* was quotient zero?              */
					/* if not keep dividing            */
	
write_out:
	addu	r7,r7,1			/* fix to point at buffer          */
	
	bcnd	eq0,r5,strcat_num	/* if r5 is 0 then skip ahead      */
	
stdout_num:
        or	r3,r7,r0		/* point to our buffer             */
	br	write_stdout		/* stdout will return for us       */

	jmp	r1			/* return */

strcat_num:
	or	r16,r7,r0		/* point to the beginning          */

	/*================================*/
	/* strcat                         */
	/*================================*/
	/* r10 =  scratch                 */
	/* r16 =  source                  */
       	/* r14 =  destination             */
strcat:

strcat_loop:
	ld.bu	r10,r16,r0	       /* load a byte from [r16]         */
	st.b	r10,r14,r0	       /* store a byte to [r14]          */
	addu	r14,r14,1
	addu	r16,r16,1
	bcnd	ne0,r10,strcat_loop    /* loop if not zero               */
	subu	r14,r14,1	       /* point to one less than null    */
	jmp	r1		       /* return                         */



/*==========================================================================*/
/* .data */
/*==========================================================================*/


data_begin:

ver_string:		.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
linefeed:		.ascii	"\n\0"
one:			.ascii	"One\0"
megahertz:		.ascii	"MHz \0"
comma:			.ascii  ", \0"
ram_comma:		.ascii	"M RAM, "
bogo_total:		.ascii	"Unknown Bogomips Total\n\0"

default_colors:		.ascii	"\033[0m\n\n\0"
escape:         	.ascii "\033[\0"
C:              	.ascii "C\0"

;;cpuinfo:		.ascii	"/proc/cpuinfo\0"
cpuinfo:		.ascii	"cpuinfo_m88k\0\0"

.include "logo.lzss_new"

/*==========================================================================*/
;;.bss
/*==========================================================================*/

.lcomm bss_begin,0
.lcomm	num_to_ascii_buff,10
.lcomm  text_buf, (N+F-1)	/* These buffers must follow each other */
.lcomm	out_buffer,16384

.lcomm  sysctl_num1,4
.lcomm  sysctl_num2,4
.lcomm  sysctl_info,256
.lcomm	sysctl_info_size,4

.lcomm	disk_buffer,32768
