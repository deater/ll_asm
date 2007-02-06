;
;  linux_logo in hppa pa-risc assembler 0.18
;
;  By 
;       Vince Weaver <vince _at_ deater.net>
;
;  assemble with     "as -o ll.o ll.parisc.s"
;  link with         "ld -o ll ll.o"


; hppa specific things:
;    * labels must begin in column zero
;    * EQU statements have the label first, ie STDERR: .equ 2
;    * branch delay slots
;    * can only shift left by a max of 3!
;      use depw to do it instead!  Also there is a shift amount reg..
;    * no and immediate instruction!
;    * stack grows *up*, not down
;    * no full hardware mul/div.  Have to pipeline by hand
;    * weird halfword arithmatic modes

; architecture hints
;   32 gp registers, %r0-%r31
;      %r0 is a zero register, %r1 target of ADDIL, %r31 target of BLE
;      %cr11 (%sar) shift amount register?
;
; Calling convention:
;   %r2 = return link?
;   %r19-%r22 = t4-t1 (not a typo) temp registers
;   %r23-%r26 = arg3-arg0 argument registers
;   %r27 = data pointer
;   %r28 = ret0 = return value
;   %r29 = ret1 = return value, static link
;   %r30 = stack pointer
;   %r31 = milicode return link
;
; To load a 32 bit word, L'SYMBOL refers to left 21 bits
;                        R'SYMBOL refers to right 11 bits
;  ie: LDIL L'START,%r1
;      LDO  R'START(%r1),%r1
;
; Instructions are source, source, destination, ie add %r1,%r2,%r3 =  r3=r2+r1
;
; Weird concept of "spaces"
;
;	ble 0x100(%sr2,%r0)            
;  is a syscall instruction.  Linux Syscalls are in area 0x100
;  WARNING!  BE CAREFUL!  I managed to lock hard a pa-risc system
;    by using an ill-formed syscall instruction.


.include "logo.include.parisc"

# offsets into the results returned by the uname syscall
U_SYSNAME:   	   	.equ	  0
U_NODENAME:		.equ	  65
U_RELEASE:		.equ	  65*2
U_VERSION:		.equ	  65*3
U_MACHINE:		.equ	  65*4
U_DOMAINNAME:		.equ	  65*5

# offset into the results returned by the sysinfo syscall
S_TOTALRAM:   	  	.equ	  16

# Sycscalls
SYSCALL_EXIT:		.equ      1
SYSCALL_READ:		.equ	  3
SYSCALL_WRITE:     	.equ	  4
SYSCALL_OPEN:      	.equ	  5
SYSCALL_CLOSE:     	.equ	  6
SYSCALL_SYSINFO:   	.equ	  116
SYSCALL_UNAME:     	.equ	  59

#
STDIN:  .equ 0
STDOUT: .equ 1
STDERR: .equ 2



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


	ldil  	L'ver_string,%r21  	; store beginning of .data seg
	ldo	R'ver_string(%r21),%r21	; in r21 to avoid 2 load instructions
					; each time
					
	ldil  	L'ascii_buff,%r22  	; store beginning of .bss seg
	ldo	R'ascii_buff(%r22),%r22	; in r22 to avoid 2 load instructions

					
	ldi     (N-F),%r8   	     	; R

	addi	(logo-ver_string),%r21,%r9

					; %r9 points to logo
	
        addi 	(logo_end-ver_string),%r21,%r12
        				; %r12 points to logo_end

        addi 	(text_buf-ascii_buff),%r22,%r27		
					; %r27 points to text_buf

	ldil  	L'out_buffer,%r16  	
	ldo	R'out_buffer(%r16),%r16	; point %r16 to out_buffer
					; too far to add immediate

        copy	%r16,%r17               ; copy to %r17 for output

	ldi	0xff,%r28		
	
	ldi	0x1fe0,%r29		; annoying way to get 0xff00 into r29
	shladd	%r29,3,%r0,%r29 

decompression_loop:

	ldb	0(%r9),%r10     	; load in a byte
	addi	1,%r9,%r9		; increment source pointer
	
	copy 	%r10, %r11		; move in the flags
	or 	%r11,%r29,%r11  	; re-load top as a hacky 8-bit counter
 
test_flags:
	cmpb,=	%r12,%r9, done_logo  	; have we reached the end?
				     	; if so, exit

	ldi	1,%r13			; check load bit (no andi instr!)
        and	%r13,%r11,%r13

	cmpib,<> 0,%r13,discrete_char 	; if set, we jump to discrete char

        ; BRANCH_DELAY
	shrpw	%r0,%r11,1,%r11      	; shift bottom bit into carry flag
	
offset_length:
	      				; PA-RISC doesn't like unaligned ldh
	ldb     1(%r9),%r24
	ldb	0(%r9),%r10
	depw	%r24,23,8,%r10		; combine into a 16-bit value

	copy	%r10,%r24		; copy r10 to r24
	
	addi	2,%r9,%r9		; get match_length and match_position
	    				
	
	shrpw %r0,%r10,P_BITS,%r15	
	addi THRESHOLD+1,%r15,%r15 
	      			; r15 = (r10 >> P_BITS) + THRESHOLD + 1
                                ;                       (=match_length)
		
output_loop:
	depwi,z	POSITION_MASK,23,8,%r13	; %r13=POSITION_MASK<<8
	addi	0xff,%r13,%r13		; %r13+=0xff
	
        and 	%r24,%r13,%r24          ;  mask it
	ldb 	%r27(%r24),%r10		; load byte from text_buf[]
	addi 	1,%r24,%r24	    	; advance pointer in text_buf
store_byte:	
        stb     %r10,0(%r17)
	addi	1,%r17,%r17      	; store it
	
	add	%r27,%r8,%r26
	stb     %r10,0(%r26)		; store also to text_buf[r]
	addi 	1,%r8,%r8        	; r++
	
	ldi	(N-1),%r13


	addi	-1,%r15,%r15		; decrement count
	cmpib,<>	0,%r15,output_loop	; repeat until k>j
	
	;BRANCH DELAY SLOT
	and 	%r13,%r8,%r8		; mask r	
	

	and	%r11,%r29,%r13		; if 0 we shifted through 8 and must	
	cmpib,<> 0,%r13,test_flags	; re-load flags
	
	nop	 			; BRANCH DELAY SLOT
	
	b 	decompression_loop
	; no nop needed as following	; BRANCH DELAY SLOT
	; instruction is harmless
	
discrete_char:
	ldb     0(%r9),%r10
	addi	1,%r9,%r9		; load a byte

					
        b     store_byte              	; and store it

	; BRANCH DELAY SLOT
	ldi   	1,%r15			; want one char

# end of LZSS code

done_logo:

        bl	write_stdout,%r2		; print the logo
	
	; BRANCH DELAY SLOT
	copy	%r16,%r25


	#==========================
	# PRINT VERSION
	#==========================

	addi	(uname_info-ascii_buff),%r22,%r26
					; destination of uname
      
        copy 	%r26,%r15	       	; save uname_info struct addr
      
        ble 	0x100(%sr2,%r0)         ; syscall
	
	; BRANCH DELAY SLOT
        ldi	SYSCALL_UNAME,%r20     	; uname syscall

        copy 	%r16, %r17	       	; restore buffer offset pointer

        bl	strcat,%r2
	
	; BRANCH DELAY SLOT
	addi	U_SYSNAME,%r15,%r25    	; os-name from uname "Linux"

        bl   	strcat,%r2		; call strcat
      	
	; BRANCH DELAY SLOT
	addi	(ver_string-ver_string),%r21,%r25
      				        ; source is " Version "
      
        bl	strcat,%r2		; call strcat
	
	; BRANCH DELAY SLOT
        addi	U_RELEASE,%r15,%r25	; version from uname ie "2.4.1"

        bl   	strcat,%r2		  	; call strcat
	
	; BRANCH DELAY SLOT
        addi	(compiled_string-ver_string),%r21,%r25	
					; source is ", Compiled "

        bl	strcat,%r2			; call strcat
	
	; BRANCH DELAY SLOT
        addi	U_VERSION,%r15,%r25		; compiled date

	bl	center_and_print,%r2		; center and print
	nop					; branch delay
  	
	#===============================
	# Middle-Line
	#===============================

	copy	%r16,%r17	        ; restore output_buffer

	#=========
	# Load /proc/cpuinfo into buffer
	#=========

	addi	(cpuinfo-ver_string),%r21,%r26
				    	; '/proc/cpuinfo'
	ldi	0,%r25			; 0 = O_RDONLY <bits/fcntl.h>
	ldi	0,%r24			;
	ble 	0x100(%sr2,%r0)         ; syscall.
	ldi	SYSCALL_OPEN, %r20   	; syscall set in branch delay slot
					; fd in %r20?  
					; we should check that 
					; return %r20>=0

	copy	%r28,%r14		; save the resulting fd
	
	copy    %r14,%r26		; set fd to arg0
	
        ldil 	L'disk_buffer,%r25	; point to disk buffer
        ldo  	R'disk_buffer(%r25),%r25

	ldi	4096,%r24		; 4096 is maximum size of proc file ;)

	ble 	0x100(%sr2,%r0)         ; syscall.
	ldi	SYSCALL_READ, %r20      ; syscall set in branch delay slot

	copy    %r14,%r26		; set fd to arg0
	
	ble 	0x100(%sr2,%r0)         ; syscall.
	ldi	SYSCALL_CLOSE, %r20     ; syscall set in branch delay slot

	#=============
	# Number of CPUs
	#=============
number_of_cpus:

	# we cheat here and just assume 1.  
	# besides, I don't have a SMP PA-RISC machine to test on

	bl	 strcat,%r2
	
	; BRANCH DELAY SLOT
	addi	 (one-ver_string),%r21,%r25
        	 			; print "One"
	
	#=========
	# MHz
	#=========
print_mhz:

	
	ldil	L'((0x20<<24)+(0x4d<<16)+(0x48<<8)+0x7a) ,%r26   
	ldo	R'((0x20<<24)+(0x4d<<16)+(0x48<<8)+0x7a)(%r26) ,%r26   
	
					; find  " MHz" and grab up to .
	bl	find_string,%r2
	
	; BRANCH DELAY SLOT
	ldi	0x2e,%r24		; 0x2e is ascii for .

	bl   	strcat,%r2	    	; strcat
	
	; BRANCH DELAY SLOT
	addi	(MHz-ver_string),%r21,%r25
	     		     		; bogo total follows RAM 

   	#=========
	# Chip Name
	#=========
chip_name:

	ldil	L'((0x63<<24)+(0x70<<16)+(0x75<<8)+0x9) ,%r26   
	ldo	R'((0x63<<24)+(0x70<<16)+(0x75<<8)+0x9)(%r26) ,%r26   
	
					; find  "cpu\t" and grab up to ' '

	bl	find_string,%r2
	
	; BRANCH DELAY SLOT
	ldi	0x20,%r24		; 0x20 is ascii for ' '

	bl   	strcat,%r2	    	; strcat
	
	; BRANCH DELAY SLOT
	addi	(processor-ver_string),%r21,%r25
	     			   	; "Processor, "
		
	#========
	# RAM
	#========

	addi	(sysinfo_buff-ascii_buff),%r22,%r26
	
	ble 	0x100(%sr2,%r0)         ; syscall.
	ldi	SYSCALL_SYSINFO, %r20   ; syscall set in branch delay slot
	
	ldw	S_TOTALRAM(%r26),%r26   ; size in bytes of RAM
		
	shrpw	%r0,%r26,20,%r6		; divide by 1024*1024 to get M

	bl     num_to_ascii,%r2
	
	; BRANCH DELAY SLOT
	ldi    1,%r9			; print to buffer

	bl	strcat,%r2		; call strcat
	
	; BRANCH DELAY SLOT
	addi   (ram_comma-ver_string),%r21,%r25
	     				; print 'M RAM, '

	#========
	# Bogomips
	#========
	
	ldil	L'((0x6d<<24)+(0x69<<16)+(0x70<<8)+0x73) ,%r26   
	ldo	R'((0x6d<<24)+(0x69<<16)+(0x70<<8)+0x73)(%r26) ,%r26   
	
					; find 'mips\t: ' and grab up to \n

	bl	find_string,%r2
	; BRANCH DELAY SLOT
	ldi	0xa,%r24		; 0xa is \n in ascii

	bl   	strcat,%r2	    	; strcat
	; BRANCH DELAY SLOT
	addi	(bogo_total-ver_string),%r21,%r25
					; bogo total follows RAM 

	bl	center_and_print,%r2	; center and print
	nop
	
	#=================================
	# Print Host Name
	#=================================
	
	copy	%r17,%r16	       ; copy s0 to s1 (output_buf_offset)

	bl	strcat,%r2	       ; call strcat
	; BRANCH DELAY SLOT
	addi	U_NODENAME,%r15,%r25   ; host name from uname()
	
	bl	center_and_print,%r2   ; center and print
	nop

	bl	write_stdout,%r2
	; BRANCH DELAY SLOT
	addi	(default_colors-ver_string),%r21,%r25
				       ; pointer to default_colors

	#================================
	# Exit
	#================================
exit:
	ldi	0, %r26			; put exit code in arg0
	ble 	0x100(%sr2,%r0)         ; syscall.  100 is linux gateway
	ldi	SYSCALL_EXIT, %r20      ; syscall in branch delay slot


	#=================================
	# FIND_STRING 
	#=================================
	#   %r24 is char to end at
	#   %r26 is 4-char ascii string to look for
	#   %r17 is the output buffer	
	#   %r9,%r10,%r11,%r12 are destroyed


find_string:

        ldil L'(disk_buffer-1),%r10     ; look in cpuinfo buffer
        ldo  R'(disk_buffer-1)(%r10),%r10

	ldi  0x3a,%r12			; 0x3a is ':'
	ldi  0x0,%r11

find_loop:

	
					; complicated load/shift
					; PA-RISC doesn't like unaligned
					; 32-bit loads
	depw	%r11,23,24,%r11					
	ldb	1(%r10),%r9		
	depw	%r9,31,8,%r11                                
	
	cmpib,= 0,%r11,done		; are we at EOF?
	; LOAD_DELAY_SLOT
	addi    1,%r10,%r10	        ; increment pointer	

	cmpb,<> %r26,%r11,find_loop	; do the strings match?
	nop				; if not, loop
	
					; if we get this far, we matched

find_colon:

	ldb	1(%r10),%r11		; repeat till we find colon

	cmpib,= 0,%r11,done		; not found? then done

	; LOAD DELAY SLOT
	addi	1,%r10,%r10


	cmpb,<> %r12,%r11,find_colon	; is it a colon?
	nop				; if not, loop

	addi   2,%r10,%r10              ;  skip a char [should be space]
	
store_loop:	 
	ldb	0(%r10),%r11		; load value

	cmpib,= 0,%r11,done		; off end, then stop
	; LOAD_DELAY SLOT
	addi	1,%r10,%r10		; increment
	
	cmpb,=  %r11,%r24,done		; is it end char?
	nop				; if so, finish
       
	stb	%r11,0(%r17)		; if not store and continue

	bl	store_loop,%r0		; loop
	; LOAD DELAY SLOT
	addi	1,%r17,%r17		; increment output pointer
	
done:
       bv,n 	%r0(%r2)		; return
       					; branch delay is nullified

	#================================
	# strcat
	#================================
	# output_buffer_offset = %r17 
	# string to cat = %r25     
	# destroys %r18

strcat:
       ldb 	0(%r25),%r18		; load byte from string

       cmpib,= 0,%r18,done_strcat	; if zero, we are done
       ; BRANCH DELAY SLOT
       stb  	%r18,0(%r17)		; store byte to output_buffer       

       addi	1,%r25,%r25		; increment string

       
       bl	strcat,%r0	 	; loop
       ; BRANCH DELAY SLOT
       addi 	1,%r17,%r17		; increment output_buffer

done_strcat:
       bv,n 	%r0(%r2)		; return
       					; branch delay is nullified

	#==============================
	# center_and_print
	#==============================
	# string is in %r16 output_buffer
        # %r4,%r5 clobbered
	# %r9= stdout or strcat

center_and_print:
	copy %r2,%r3			; save return address


        sub	%r17,%r16,%r4		; subtract end pointer from start
       		    			; (cheaty way to get size of string)

	ldi     80,%r5
        cmpb,>  %r4,%r5,done_center	; don't center if > 80
	; BRANCH DELAY SLOT
  	ldi    	0,%r9 			; print to stdout	
	
	sub	%r5,%r4,%r4		; 80 - length

	shrpw	%r0,%r4,1,%r4		; divide by two

        bl	write_stdout,%r2
	; BRANCH DELAY SLOT
	addi	(escape-ver_string),%r21,%r25
        				; print escape char
       
        bl	num_to_ascii,%r2        ; print number of spaces
	; BRANCH DELAY SLOT
        copy	%r4,%r6

        bl	write_stdout,%r2
	; BRANCH DELAY SLOT
	addi	(c-ver_string),%r21,%r25
        				; print "C"

done_center:
      	bl 	write_stdout,%r2
	; BRANCH DELAY SLOT
        copy 	%r16, %r25		; point to the string to print

	addi	(linefeed-ver_string),%r21,%r25
        				; print linefeed at end of line	
	
        copy	%r3,%r2 		; restore saved pointer
	     				; so we'll return to
					; where we were called from 
					; at the end of the write_stdout
	
	#================================
	# WRITE_STDOUT
	#================================
	# r25 (arg1) has string
	# r18, r19 destroyed
	
write_stdout:
	ldi	STDOUT, %r26		; 1 in arg0 (stdout)	
	ldi	0,%r24			; 0 (count) in arg2
	
	copy	%r25,%r18		; copy string pointer
	
str_loop1:

	addi	1,%r18,%r18		; increment pointer	
	ldb	0(%r18),%r19		; load byte at r18

	cmpib,<>  0,%r19,str_loop1	; if r19 not zero, loop
	addi	1,%r24,%r24		; BRDELAY: increment arg2

	ble 	0x100(%sr2,%r0)         ; syscall.  100 is linux gateway
	ldi	SYSCALL_WRITE, %r20     ; syscall in branch delay slot

	bv,n	%r0(%r2)       		; return
					; branch delay is nullified	

	##############################
	# num_to_ascii
	##############################
	
	# %r6  = value to print
	# %r5  = output buffer	
	# %r9 = 0=stdout, 1=strcat
	# destroys t2 ($10)
	# destroys t3 ($11)
	# destroys a0 ($4)
	
num_to_ascii:

	addi     ((ascii_buff-ascii_buff)+10),%r22,%r5
	     			 	; point to end of ascii_buffer
				 
	copy %r2,%r7		   	; save return value

 div_by_10:
 	 addi	 -1,%r5,%r5	 	; point back one

	 copy	 %r6,%r26
	 bl	 div_uint,%r2	 	; div by 10, result in %r28
	 ; BRANCH DELAY SLOT
	 ldi	 0xa,%r25   	        ; dividing by 10	 
	 	 
	 copy	 %r6,%r26

	 bl	 mod_uint,%r2		; mod by 10, result in %r29
	 ; BRANCH DELAY SLOT
	 ldi	 0xa,%r25		; modding by 10	 

	 
	 addi	 0x30,%r29,%r29	 ; convert to ascii

	 copy	 %r28,%r6	 ; move old result into next divide
	 
	 cmpib,<> 0,%r28,div_by_10
	 ; BRANCH DELAY SLOT
	 stb	 %r29,0(%r5)	 ; store to buffer
	 
write_out:
	 copy	%r5,%r25	 
	 cmpib,= 0,%r9,write_stdout ; print to stdout if r9==0
	 ; BRANCH DELAY SLOT
	 copy	%r7,%r2		 ; restore return address	 
	 
     	 b	 strcat		 ; strcat will return for us
	 ; BRANCH DELAY SLOT
	 nop



         #
	 # Divide and mod code based on code from the gcc compiler 
	 #

         #####################
	 # unsigned int divide
	 #####################
	 # %r26 = dividend
	 # %r25 = divisor
	 # %r28 = quotient
	 # %r1,%r23  = trashed
	 
div_uint:
	 ldil	 0x80000 ,%r23	        ; load 1<<31 into %r23
	 
	 ldo	 -1(%r25),%r1
	 subi	 0,%r25,%r1      	;  clear carry, negate the divisor 
	 ds	 %r0,%r1,%r0	 	;  set V-bit to 1 

         add	 %r26,%r26,%r28	 	;  shift msb bit into carry 
 	 ds	 %r0,%r25,%r1  	 	;  1st divide step, if no carry

	 ; typically you unroll this, but we are
	 ; going for size, not speed

div_uint_loop:
	 addc	 %r28,%r28,%r28	 	;  shift %r28 with/into carry

	 shrpw	 %r0,%r23,1,%r23	; shift does not mess with carry,
	 cmpib,<> 0,%r23,div_uint_loop	; add, sub, etc do
	 ; BRANCH DELAY
	 ds	 %r1,%r25,%r1	 	;  divide step 
	 
	 bv	%r0(%r2)         ; return	 
	 addc	%r28,%r28,%r28	 ; shift last retreg bit


         #####################
	 # unsigned int divide
	 #####################
	 # %r26 = dividend
	 # %r25 = divisor
	 # %r29 = remainder
	 # %r1,%r23  = trashed
mod_uint:
	 ldil	 0x80000 ,%r23	        ; load 1<<31 into %r23
	 ldo	 -1(%r25),%r1

	 subi	 0,%r25,%r29     	;  clear carry, negate the divisor */
	 ds	 %r0,%r29,%r0	 	;  set V-bit to 1 

         add	 %r26,%r26,%r1	 	;  shift msb bit into carry 
 	 ds	 %r0,%r25,%r29   	;  1st divide step, if no carry 
	 
mod_uint_loop:	 
	 addc	 %r1,%r1,%r1	 	;  shift %r29 with/into carry 
	 shrpw	 %r0,%r23,1,%r23	; shift does not mess with carry,
	 cmpib,<> 0,%r23,mod_uint_loop	; add, sub, etc do
	 ; BRANCH DELAY SLOT
	 ds	 %r29,%r25,%r29	 	;  divide step 
	 

	 comiclr,<= 0,%r29,%r0
	 add     %r29,%r25,%r29		;  correction 
	 bv	 %r0(%r2)         	; return	 
	 nop



;===========================================================================
;	section .data
;===========================================================================
.data

ver_string:	.ascii	" Version \0"
compiled_string:	.ascii	", Compiled \0"
ram_comma:	.ascii	"M RAM, \0"
bogo_total:	.ascii	" Bogomips Total\0"
linefeed:	.ascii  "\n\0"
default_colors:	.ascii "\033[0m\n\n\0"
escape:		.ascii "\033[\0"
c:		.ascii "C\0"

cpuinfo:	.ascii	"/proc/cpuinfo\0"

one:	.ascii	"One \0"
MHz:	.ascii	"MHz PA-RISC \0"
processor:	.ascii " Processor, \0"

.include	"logo.lzss_new.parisc"

;============================================================================
;	section .bss
;============================================================================


;.bss

.lcomm  ascii_buff,10		; 32 bit can't be > 9 chars

   ; see /usr/src/linux/include/linux/kernel.h
.lcomm sysinfo_buff,(64)
.lcomm uname_info,(65*6)

.lcomm text_buf,   (N+F-1)


.lcomm	disk_buffer,4096	; we cheat!!!!

.lcomm out_buffer, 16384






