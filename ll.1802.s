;
;  linux_logo in RCA COSMAC 1802 assembler 0.48
;
;  By:
;       Vince Weaver <vince _at_ deater.net>
;
;  assemble with     "asmx -C1802 -w -e -o ll.hex ll.1802.s"
;  run in the simulator with "elf -baud 1200 -vt100 -r ./serial_test.hex"

;.include "logo.include"

; Optimization progress:

;
; Architectural info
;

;	.globl _start
;_start:


	;=========================
	; PRINT LOGO
	;=========================

; LZSS decompression algorithm implementation
; by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
; optimized some more by Vince Weaver

	; r0 = instruction pointer
	; r1 = out_buffer
	; r2 = R
	; r3 = temp
	; r4 = logo data inputting from
	; r5 = decompress_byte
	; r6 = position
	; r7 = match length
	; r8 = logo end
	; r9 = bit_count
	; ra = out_byte
	; rb = current_byte
	; rc = temp 16bit
	; rd = text_buf
	; re = temp_16bit
	; rf =

        ldi	LOW logo
	plo	r4
	ldi	HIGH logo
	phi	r4

        ldi	LOW out_buffer
	plo	r1
	ldi	HIGH out_buffer
	phi	r1

        ldi	LOW text_buf
	plo	rd
	ldi	HIGH text_buf
	phi	rd

	ldi	HIGH 960		; N - F = 1024-64 = 960
	phi	r2
	ldi	LOW 960
	plo	r2

	sex	r4			; set index to r4

decompression_loop:
	ldxa				; load a byte, increment pointer
	plo	rb

	ldi	8			; bits left
	plo	r9

test_flags:
	ghi	r4
	smi	HIGH logo_end
	bnz	not_done

	glo	r4
	smi	LOW logo_end	; have we reached the end?
	bz	done_logo	; if so, exit

not_done:

	glo	rb
	shr 			; shift bottom bit into DF flag
	plo	rb
	bdf	discrete_char	; if set, we jump to discrete char

offset_length:
	ldxa			; load a byte, increment
	plo	rc
	ldxa			; load a byte, increment
	phi	rc

	ghi	rc
	shr
	shr			; (rc>>P_BITS)
	adi	3		; + THRESHOLD + 1

				; P_BITS = 10
				; THRESHOLD = 2
				; r6 = (r6 >> P_BITS) + THRESHOLD + 1
				;                       (=match_length)

	plo	r6		; put in r6


output_loop:
				; Assume ((POSITION_MASK<<8)+0xff) is 0x3ff
	ghi	rc		; mask with 0x3ff
	ani	3
	phi	rc

	glo	rc
	adi	LOW text_buf
	plo	re
	ghi	rc
	adci	HIGH text_buf
	phi	re

	ldn	re		; load byte from text_buf[rc]
	inc	rc		; advance rc pointer

store_byte:
;	glo	ra			; get output_byte
	str	r1			; store a byte
	inc	r1			; increment pointer

	plo	ra

	glo	r2
	adi	LOW text_buf
	plo	re
	ghi	r2
	adci	HIGH text_buf
	phi	re

	glo	ra
	str	re			; store a byte to text_buf[r]
	inc 	r2			; r++


				; Assume ((POSITION_MASK<<8)+0xff) is 0x3ff
	ghi	r2		; mask with 0x3ff
	ani	3		; (wrap to N-1 bits)
	phi	r2

	dec	r6			; decement count

	ghi	r6			; if count not zero, then loop
	bnz	output_loop
	glo	r6
	bnz	output_loop

	dec	r9
	glo	r9			; get bit count; is it zero?
	bnz	test_flags		; if not, re-load flags

	br	decompression_loop

discrete_char:

	ldi	1
	plo	r6			; we set r6 to one so byte
					; will be output once

	ldxa				; load a byte, increment pointer
;	plo	ra			; put in output_byte

	br	store_byte		; and store it

; end of LZSS code

done_logo:
;	ldr	r1,out_addr		; buffer we are printing to


;	ldr	r0,strcat_addr
;	mov	r11,r0			; point r11 to "strcat_r4"
;	sub	r0,#8
;	mov	r10,r0			; point r10 to "strcat_r3"
;	sub	r0,#(strcat_r5-write_stdout)
;	mov	r9,r0			; point r9 to "write_stdout"

;	sub	r0,#(write_stdout-center_and_print)
;	mov	r8,r0

;	blx	r9			; print the logo


	ldi	HIGH delay	; POINT RC TO "DELAY"
        phi	rc
        ldi	LOW delay
        plo	rc

	ldi	HIGH out_char	; POINT RB TO "OUT_CHAR"
        phi	rb
        ldi	LOW out_char
        plo	rb

	ldi	HIGH write_stdout	; POINT R9 TO "WRITE_STDOUT"
        phi	r9
        ldi	LOW write_stdout
        plo	r9

;	ldi	HIGH hello_world
;	phi	r4
;        ldi	LOW hello_world
;	plo	r4

        ldi	LOW out_buffer
	plo	r4
	ldi	HIGH out_buffer
	phi	r4


	sep	r9




	;==========================
	; PRINT VERSION
	;==========================

;first_line:
;	ldr	r0,uname_addr
;	mov	r5,r0
;	mov	r7,#SYSCALL_UNAME
;	swi	#0			; do uname syscall

					; os-name from uname "Linux"

;	ldr	r6,out_addr		; point r6 to out_buffer

;	blx	r10			; call strcat_r5

;	ldr	r4,ver_addr		; source is " Version "

;	blx 	r11			; call strcat_r4

;	add	r5,#U_RELEASE
					; version from uname, ie "2.6.20"
;	blx	r10			; call strcat_r5

					; source is ", Compiled "
;	blx	r11			; call strcat_r4

;	add	r5,#(U_VERSION-U_RELEASE)
					; compiled date
;	blx	r10			; call strcat_r5

					; source is "\n"
;	blx	r11			; call strcat_r4

;	blx	r8			; center and print

	;===============================
	; Middle-Line
	;===============================
;middle_line:
	;=========
	; Load /proc/cpuinfo into buffer
	;=========

;	ldr	r6,out_addr		; point r6 to out_buffer

;	mov	r0,r4
					; '/proc/cpuinfo'
;	mov	r1,#0			; 0 = O_RDONLY <bits/fcntl.h>
;	mov	r7,#SYSCALL_OPEN
;	swi	#0			; syscall.  return in r0?

;	mov	r3,r0			; save our fd
;	ldr	r1,disk_addr
;	mov	r2,#128
;	lsl	r2,#5		 	; 4096 is maximum size of proc file ;)
;	mov	r7,#SYSCALL_READ
;	swi	#0

;	mov	r0,r3
;	mov	r7,#SYSCALL_CLOSE
;	swi	#0			; close (to be correct)


	;=============
	; Number of CPUs
	;=============
;number_of_cpus:

					; cheat.  Who has an SMP arm?
					; Print "One"
;	add	r4,#14			; length of /proc/cpuinfo
;	blx	r11			; call strcat_r4

	;=========
	; MHz
	;=========
;print_mhz:

	; the arm system I have does not report MHz

	;=========
	; Chip Name
	;=========
;chip_name:

;	mov	r0,#'a'
;	mov	r1,#'r'
;	mov	r2,#'e'
;	mov	r3,#'\n'
;	bl	find_string
					; find 'sor\t: ' and grab up to ' '

;	blx	r11			; print " Processor, "

	;========
	; RAM
	;========
;	ldr	r0,sysinfo_addr
;	mov	r2,r0

;	mov	r7,#SYSCALL_SYSINFO
;	swi	#0			; sysinfo() syscall

;	add	r2,#S_TOTALRAM
;	ldr	r3,[r2]
					; size in bytes of RAM
;	lsr	r3,#20			; divide by 1024*1024 to get M

;	mov	r0,#1
;	bl num_to_ascii

					; print 'M RAM, '
;	blx	r11			; call strcat

	;========
	; Bogomips
	;========

;	mov	r0,#'I'
;	mov	r1,#'P'
;	mov	r2,#'S'
;	mov	r3,#'\n'
;	bl	find_string

;	blx	r11			; print bogomips total

;	blx	r8			; center and print

	;=================================
	; Print Host Name
	;=================================
;last_line:
;	ldr	r6,out_addr		; point r6 to out_buffer

;	sub	r5,#(U_VERSION-U_NODENAME)
					; host name from uname()
;	blx	r10			; call strcat_r5

;	blx	r8			; center and print

;	ldr	r1,colors_addr

					; restore colors, print a few linefeeds
;	blx	r9			; write_stdout

	;================================
	; Exit
	;================================
exit:
	idl			; wait forever



	;=================================
	; FIND_STRING
	;=================================
	; r0,r1,r2 = string to find
	; r3 = char to end at
	; writes to r6

;find_string:
;	push	{r5,r7,lr}
;	ldr	r7,disk_addr		; look in cpuinfo buffer
;find_loop:
;	ldrb	r5,[r7]			; load a byte
;	cmp	r5,#0			; off the end?
;	beq	done			; then finished

;	add	r7,#1			; increment pointer
;	cmp	r5,r0			; compare against first byte
;	bne	find_loop

;	ldrb	r5,[r7]			; load next byte
;	cmp	r5,r1
;	bne	find_loop		; if not equal, loop

;	ldrb	r5,[r7,#1]		; load next byte
;	cmp	r5,r2
;	bne	find_loop		; if not equal, loop

					; if all 3 matched, we are found

;find_colon:
;	ldrb	r5,[r7]			; load a byte
;	add	r7,#1			; increment pointer
;	cmp	r5,#':'
;	bne	find_colon		; repeat till we find colon

;	add	r7,r7,#1		; skip the space

;store_loop:
;	ldrb	r5,[r7]			; load a byte, increment pointer
;	strb	r5,[r6]			; store a byte, increment pointer
;	add	r7,#1			; increment pointers
;	add	r6,#1
;	cmp	r5,r3
;	bne	store_loop

;almost_done:
;	mov	r0,#0
;	strb	r0,[r6]			; replace last value with NUL
;	sub	r6,#1			; adjust pointer

;done:
;	pop	{r5,r7,pc}		; return



	;==============================
	; center_and_print
	;==============================
	; string to center in at output_buffer

;center_and_print:

;	push	{r3,r4,LR}		; store return address on stack

;	ldr	r1,colors_addr		; we want to output ^[[
;	mov	r2,#2

;	bl	write_stdout_we_know_size

;str_loop2:
;	ldr	r2,out_addr		; point r2 to out_buffer
;	sub	r2,r2,r6		; get length by subtracting
					; actually, negative value here
					; an optimization...

					; subtract r2 from 81
;	add	r2,#81			; we use 81 to not count ending \n

;	blt	done_center		; if result negative, don't center

;	lsr	r3,r2,#1		; divide by 2

;	mov	r0,#0			; print to stdout
;	bl	num_to_ascii		; print number of spaces

;	add	r1,#7			; we want to output C
;	blx	r9			; write_stdout

;done_center:
;	ldr	r1,out_addr		; point r1 to out_buffer
;	blx	r9			; write_stdout
;	pop	{r3,r4,PC}		; restore return address from stack

	;#############################
	; num_to_ascii
	;#############################
	; r3 = value to print
	; r0 = 0=stdout, 1=strcat

;num_to_ascii:

;	push	{r1,r2,r3,r4,r5,LR}	; store return address on stack
;	ldr	r2,ascii_addr
;	add	r2,#9			; point to end of our buffer

	;===================================================
	; div_by_10: because ARM has no divide instruction
	;==================================================
	; r3=numerator
	; r5=quotient    r4=remainder

;	mov	r7,#10		; Divide by 10
;div_by_10:
;	mov     r5,#0           ; zero out quotient
;divide_loop:
;	mov     r1,r5           ; move Q temporarily to r1
;	mul     r1,r7           ; multiply Q by denominator
;	add     r5,#1           ; increment quotient
;	cmp     r1,r3           ; is it greater than numerator?
;	ble     divide_loop     ; if not, loop
;	sub     r5,#2           ; otherwise went too far, decrement
				; and done
;	mov     r1,r5           ; move Q temporarily to r2
;	mul     r1,r7           ; calculate remainder
;	sub     r4,r3,r1        ; R=N-(Q*D)

	; Done Divide, Q=r5 R=r4

;	add     r4,#0x30        ; convert to ascii
;	strb    r4,[r2]         ; store a byte
;	sub     r2,#1           ; decrement pointer
;	mov     r3,r5           ; move Q in for next divide, update flags
;	bne	div_by_10	; if Q not zero, loop

;write_out:
;	add	r1,r2,#1	; adjust pointer

;	cmp	r0,#0
;	beq	num_stdout

;	mov	r5,r1
;	blx	r10			; if 1, strcat_r5
;	pop	{r1,r2,r3,r4,r5,pc}	; pop and return

;num_stdout:
;	blx	r9			; else, fallthrough to stdout
;	pop	{r1,r2,r3,r4,r5,pc}	; pop and return


	;================================
	; strcat
	;================================
	; value to cat in r4
	; output buffer in r6
	; r3 trashed
;strcat_r5:
;	push	{r4,lr}
;	mov	r4,r5
;	blx	r11
;	pop	{r4,pc}

;strcat_r4:
;	push	{r3,lr}
;strcat_loop:
;	ldrb	r3,[r4]			; load a byte
;	add	r4,#1			; increment pointer
;	strb	r3,[r6]			; store a byte
;	add	r6,#1			; increment pointer
;	cmp	r3,#0			; is it zero?
;	bne	strcat_loop		; if not loop
;	sub	r6,r6,#1		; point to one less than null
;	pop	{r3,pc}			; return

	;================================
	; WRITE_STDOUT
	;================================
	; runs as r9
	; expects to return to r0
	; r4 = string to print


write_stdout_return:

	sep	r0			; return to r0

write_stdout:
	sex	r4			; use r4 as index

write_loop:
	ldxa				; load from r4 and increment
	bz	write_stdout_return	; if zero we are done
	plo	rf			; put char into rf
	sep	rb			; call out_char
	br	write_loop		; loop


	;================================
	; OUT_CHAR
	;================================
	; expects to be run as rb
	; expects to return to r9
	; rf = byte to output

out_char_return:
	sep	r9		; return to write_stdout

out_char:
	ldi	7		; load bit counter
	plo	ra		; and put in ra

        seq			; begin start bit
 	sep	rc		; call delay

out_loop:

	glo	rf		; load in char to output
	shr			; shift into carry
	plo	rf		; store back to rf

	bdf	out_one		; if carry set, output a 1

	seq			; otherwise, output a 0
				; (note, we are assuming the serial
				; hardware inverts Q)

	br	not_one		; skip ahead

out_one:
	req			; output a 1 (inverted)

not_one:
 	sep	rc		; call delay

	dec	ra		; decrement bit count
	glo	ra		; load bit count
	bnz	out_loop	; if not zero than loop

	seq			; mark parity
 	sep	rc		; delay

	req			; stop bit
 	sep	rc		; delay

	br	out_char_return	; done and return


	;================================
	; DELAY
	;================================
	; expects to be run as rc
	; expects to return to rb

delay_begin:
	sep	rb		; return

delay:
	ldi	49		; loop 49 times
				; this isn't calculated but was found
				; by trial and error

delay_loop:
	smi	1		; decrement counter
	bnz	delay_loop	; repeat until empty
	br	delay_begin	; goto return


;.align 2

; data address
;ver_addr:	.word ver_string
;colors_addr:	.word default_colors

;bss addresses
;uname_addr:	.word uname_info
;sysinfo_addr:	.word sysinfo_buff
;ascii_addr:	.word ascii_buffer
;disk_addr:	.word disk_buffer

; constant values
;pos_mask:	.word ((POSITION_MASK<<8)+0xff)

; function pointers
;strcat_addr:	.word (strcat_r4+1)	; +1 to make it a thumb addr


;addresses:
; These are loaded by LDM at init
;text_addr:	.word text_buf
;out_addr:	.word out_buffer
;R:		.word (N-F)
;logo_addr:	.word logo
;logo_end_addr:	.word logo_end

;.align 1
;===========================================================================
;	section .data
;===========================================================================
;.data


.include	"logo.lzss_new"

hello_world:
	db "Hello World!\r\n",0


;ver_string:	.asciz	" Version "
;compiled_string:.asciz	", Compiled "
;linefeed:	.asciz	"\n"
;.ifdef FAKE_PROC
;cpuinfo:	.asciz  "proc/cpui.arm"
;.else
;cpuinfo:	.asciz	"/proc/cpuinfo"
;.endif
;one:		.asciz	"One "
;processor:	.asciz	" Processor, "
;ram_comma:	.asciz	"M RAM, "
;bogo_total:	.asciz	" Bogomips Total\n"

;default_colors:	.asciz "\033[0m\n\n"
;C:		.asciz "C"






;============================================================================
;	section .bss
;============================================================================
;.bss
;bss_begin:
;.lcomm uname_info,(65*6)
;.lcomm sysinfo_buff,(64)
;.lcomm ascii_buffer,10
;.lcomm text_buf, (N+F-1)
;.lcomm	disk_buffer,4096	; we cheat!!!!



text_buf:	DS	1087 	; 1024 + 64 - 1 =  1087 (N+F-1)
out_buffer:	DS	4096	; 4kb?

;	# see /usr/src/linux/include/linux/kernel.h




