;
;  linux_logo in RCA COSMAC 1802 assembler 0.48
;
;  By:
;       Vince Weaver <vince _at_ deater.net>
;
;  assemble with     "asmx -C1802 -w -e -o ll.hex ll.1802.s"
;  run in the simulator with "elf -baud 1200 -vt100 -r ./ll.hex"

;.include "logo.include"

; Optimization progress:

;
; Architectural info
;
;	The 1802 is a very non-typical architecture.
;	+ D = 8-bit accumulator
;	+ DF = 1-bit data flag (carry flag)
;	+ R0-Rf = 16 16-bit index registers
;	+ X = 4-bit index register select
;	+ P = 4-bit program counter select (any of the Rx can be the PC)
;	+ IE = 1-bit interrupt enable
;	+ T = 8-bit X,P saved after interrupt
;	+ Q = 1-bit output flip-flop
;	No stack, but any Rx can act as one, there are auto inc/dec insns
;
;	Instructions are variable width, 1 or 2 bytes
;
;	Register Operations
;	+ INC Rn / DEC Rn
;	+ INC Rx (x is selected by the X register)
;	+ GLO Rn / GHI Rn (D=low or high byte of Rn)
;	+ PLO Rn / PHI Rn (Rn low or high = D)
;
;	Memory Operations
;	+ LDN Rn	(D= Mem[Rn] for Rn!=0)
;	+ LDA Rn	like above, but increment Rn
;	+ LDX		(D= Mem[Rx])
;	+ LDXA		like above, but increment Rx
;	+ LDI nn	load immediate byte
;	+ STR Rn	store D to Mem[Rn]
;	+ STXD		like above, but decrement Rn
;
;	Branch Instructions
;	Short: only within current 256-byte page
;	+ BR nn		branch always
;	+ NBR nn	branch never (continue with next insn)
;	+ BQ nn / BNQ nn	branch based on Q
;	+ BZ nn / BNZ nn	branch if D is zero (or not)
;	+ BDF nn / BNF nn	branch if DF is set/notset
;	+	(BPZ,BGE or BM,BL branch pos/greatere/minus/less) are aliases
;	+ B1/B2/B3/B4/BN1/BN2/BN3/BN4	branch based on EF external flags
;	Long Branch
;	+ LBR hhll / NLBR hhll
;	+ LBQ hhll / LBNQ hhll
;	+ LBZ hhll / LBNZ hhll
;	+ LBDF hhll / LBNF hhll
;
;	Conditional execution / Skips
;	+ LSNQ / LSQ	-- skip 2 if/if not Q
;	+ LSNZ / LSZ
;	+ LSNF / LSDF
;	+ LSIE
;
;	Arithmetic
;	+ OR / AND / XOR	-- logic, D = D OP Mem[Rx]
;	+ ADD / ADC		-- add, D = D + Mem[Rx] (+ DF if carry)
;	+ SD / SDB		-- sub, D = Mem[Rx]-D (- Not DF if borrow)
;	+ SM / SMB		-- subfrom, D = D - Mem[Rx]
;	+ ORI nn / ANI nn / XRI nn 	-- immediate, D = D OP nn
;	+ ADI nn / ADCI nn		-- immediate adds
;	+ SDI / SDBI			-- immediate subs
;	+ SMI / SMBI			-- immediate subfroms
;
;	Shifts
;	+ SHR / SHL		-- shift right/left, into carry
;	+ SHRC / SHLC		-- shift right/left carry in carry out
;
;	Special register instructions
;	+ SEQ / REQ	Set/reset Q
;	+ SEX		Set X register (make it the index)
;	+ SEP		Set P register (make it the program counter)
;
;	Other
;	+ NOP
;	+ IDL	wait for interrupt or DMA
;	+ RET/DIS/MARK/SAVE	interrupt handling instructions
;	+ OUT1 .. OUT7		output on bus
;	+ INP1 .. INP7		input from bus




;	.globl _start
;_start:

;	br	done_logo		; while debugging (for speed)

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

	ldi	HIGH num_to_ascii	; point r7 to num_to_ascii
        phi	r7
        ldi	LOW num_to_ascii
        plo	r7

	ldi	HIGH find_string	; point r8 to find_string
        phi	r8
        ldi	LOW find_string
        plo	r8

	ldi	HIGH write_stdout	; point r9 to write_stdout
        phi	r9
        ldi	LOW write_stdout
        plo	r9

	ldi	HIGH out_char		; point rb to out_char
        phi	rb
        ldi	LOW out_char
        plo	rb

	ldi	HIGH delay		; point rc to delay
        phi	rc
        ldi	LOW delay
        plo	rc

	ldi	HIGH strcat		; point rd to strcat
        phi	rd
        ldi	LOW strcat
        plo	rd

	ldi	HIGH center_and_print	; point re to center_and_print
        phi	re
        ldi	LOW center_and_print
        plo	re


        ldi	LOW out_buffer
	plo	r4
	ldi	HIGH out_buffer
	phi	r4

	sep	r9

	;==========================
	; PRINT VERSION
	;==========================

first_line:

	ldi	LOW out_buffer
	plo	r4
	ldi	HIGH out_buffer
	phi	r4

					; no uname syscall, faking

	ldi	LOW uname_sysname
	plo	r5
	ldi	HIGH uname_sysname
	phi	r5

					; os-name from uname "Linux"

	sep	rd			; call strcat


	ldi	LOW ver_string
	plo	r5
	ldi	HIGH ver_string
	phi	r5
					; source is " Version "

	sep 	rd			; call strcat

	ldi	LOW uname_release
	plo	r5
	ldi	HIGH uname_release
	phi	r5

					; version from uname, ie "2.6.20"
	sep	rd			; call strcat_r5

	ldi	LOW compiled_string
	plo	r5
	ldi	HIGH compiled_string
	phi	r5

					; source is ", Compiled "
	sep	rd			; call strcat

	ldi	LOW uname_version
	plo	r5
	ldi	HIGH uname_version
	phi	r5

					; compiled date
	sep	rd			; call strcat_r5

	ldi	LOW linefeed
	plo	r5
	ldi	HIGH linefeed
	phi	r5

					; source is "\n"
	sep	rd			; call strcat_r4

	sep	re			; center and print
	sep	re
	sep	re
	sep	re

	;===============================
	; Middle-Line
	;===============================
middle_line:

	ldi	LOW out_buffer
	plo	r4
	ldi	HIGH out_buffer
	phi	r4

	;=========
	; Load /proc/cpuinfo into buffer
	;=========
	; We have to fake this, no FILE I/O

	; open
	; read
	; close
	; now in disk_buffer

	;=============
	; Number of CPUs
	;=============
number_of_cpus:

					; cheat.  Who has an SMP arm?
					; Print "One"


	ldi	LOW one
	plo	r5
	ldi	HIGH one
	phi	r5

	sep	rd			; call strcat

	;=========
	; MHz
	;=========
print_mhz:

	ldi	'M'
	plo	r2
	ldi	'H'
	phi	r2
	ldi	'z'
	plo	r3
	ldi	'\n'
	phi	r3
	sep	r8

	ldi	LOW mhz
	plo	r5
	ldi	HIGH mhz
	phi	r5

	sep	rd			; call strcat

	;=========
	; Chip Name
	;=========
chip_name:
	ldi	'c'
	plo	r2
	ldi	'p'
	phi	r2
	ldi	'u'
	plo	r3
	ldi	'\n'
	phi	r3
	sep	r8			; call find_string
					; find 'cpu\t: ' and grab up to ' '

	ldi	LOW processor
	plo	r5
	ldi	HIGH processor
	phi	r5

	sep	rd			; print " Processor, "

	;========
	; RAM
	;========
ram:
	; no RAM detection, assume 32k
	; assume something put ram value at address total_ram

	ldi	LOW total_ram
	plo	r3
	ldi	HIGH total_ram
	phi	r3
	lda	r3
	phi	r2
	ldn	r3
	plo	r2


	; divide by 1024
	ghi	r2		; divide by 256
	shr			; divide by 2
	shr			; divide by 2
	plo	r2		; put back in r2

        ldi	LOW ascii_buffer
	plo	r5
	ldi	HIGH ascii_buffer
	phi	r5			; point r5 to ascii_buffer

	sep 	r7		; call num_to_ascii

	sep	rd		; call strcat

	ldi	LOW ram_comma
	plo	r5
	ldi	HIGH ram_comma
	phi	r5

					; print 'K RAM, '
	sep	rd			; call strcat

	;==========
	; Bogomips
	;==========

	ldi	'I'
	plo	r2
	ldi	'P'
	phi	r2
	ldi	'S'
	plo	r3
	ldi	'\n'
	phi	r3
	sep	r8

	ldi	LOW bogo_total
	plo	r5
	ldi	HIGH bogo_total
	phi	r5

	sep	rd			; print bogomips total

	sep	re			; center and print
	sep	re
	sep	re
	sep	re

	;=================================
	; Print Host Name
	;=================================
last_line:

        ldi	LOW out_buffer
	plo	r4
	ldi	HIGH out_buffer
	phi	r4			; point r4 to out_buffer

	ldi	LOW uname_nodename
	plo	r5
	ldi	HIGH uname_nodename
	phi	r5			; point r5 to out_buffer

					; host name from uname()

	sep	rd			; call strcat

	sep	re			; center and print
	sep	re
	sep	re
	sep	re

	ldi	LOW default_colors
	plo	r4
	ldi	HIGH default_colors
	phi	r4			; point r5 to out_buffer


					; restore colors, print a few linefeeds
	sep	r9			; write_stdout

	;================================
	; Exit
	;================================
exit:
	idl			; wait forever


	nop
	nop
	nop
	nop
	nop














	




	;=================================
	; FIND_STRING
	;=================================
	; r2/r3 = string to find
	; rf = char to end at
	; returns to r0
	; called as r8
	; trashes r6
	; writes to r4

find_string_return:
	sep	r0

find_string:

        ldi	LOW disk_buffer
	plo	r6
	ldi	HIGH disk_buffer
	phi	r6			; point r4 to out_buffer

	sex	r6

find_loop:
	ldn	r6			; load a byte
	bz	done			; if zero then done

	glo	r2			; get first byte
	sm				; subtract with byte at r6
	inc	r6
	bnz	no_match		; loop if not zero

	ghi	r2			; load next byte
	sm
	inc	r6
	bnz	no_match1		; if not equal, loop

	glo	r3
	sm
	bz	find_colon

no_match1:
	dec	r6
no_match:
	br	find_loop

find_colon:
	ldi	':'
	sm
	inc	r6
	bnz	find_colon		; repeat till we find a colon

	inc	r6			; skip the space

store_loop:
	ldxa				; load byte from r6, inc
	str	r4			; store to r4
	inc	r4			; increment r4

	ghi	r3
	sm
	bnz	store_loop

almost_done:
	ldi	0
	str	r4			; replace last value with NUL

done:
	br	find_string_return	; return



	;==============================
	; center_and_print
	;==============================
	; string to center in out_buffer
	; end of string in r4
	; called as re
	; returns to r0

center_and_print_return:
	sep	r9			; call write_stdout

center_and_print:

	glo	r4
	smi	LOW out_buffer

					; subtract length from 81
	sdi	81			; we use 81 to not count ending \n

	bpz	no_zero		; if result negative, don't center

	ldi	0

no_zero:

	shr				; divide by 2

	plo	r2			; put into r2

        ldi	LOW after_escape
	plo	r5
	ldi	HIGH after_escape
	phi	r5			; point r5 to ascii_buffer

	sep	r7			; call num_to_ascii

        ldi	LOW escape
	plo	r4
	ldi	HIGH escape
	phi	r4			; we want to output ^[[

	sep	r9



        ldi	LOW C
	plo	r4
	ldi	HIGH C
	phi	r4			; we want to output C

	sep	r9

done_center:

        ldi	LOW out_buffer
	plo	r4
	ldi	HIGH out_buffer
	phi	r4			; point r4 to out_buffer


	br	center_and_print_return

	;#############################
	; num_to_ascii
	;#############################
	; r2 = value to print
	; called in r7
	; returns to r0
	; r5 points to buffer with result
	; trashes r2 and r3
nta_return:
	sep	r0

num_to_ascii:


	;===================================================
	; div_by_10: because 1802 has no mul/divide instruction
	;==================================================
	; cheat and only convert a byte

	ldi	0
	plo	r3		; digit counter
	phi	r3		; leading zero?
	glo	r2		; get value to convert
c_100s_loop:
	smi	100
	bm	count_10s
	inc	r3
	br	c_100s_loop

count_10s:
	adi	100		; restore positive
	plo	r2

	glo	r3
	bz	zero_100s

	adi	0x30
	str	r5
	inc	r5
	phi	r3		; make leading zero not true

zero_100s:

	ldi	0
	plo	r3
	glo	r2
c_10s_loop:
	smi	10
	bm	count_1s
	inc	r3
	br	c_10s_loop

count_1s:
	adi	10
	plo	r2

	ghi	r3
	bnz	noleadzero

	glo	r3
	bz	notenszero

noleadzero:

	glo	r3

	adi	0x30
	str	r5
	inc	r5

notenszero:
	ldi	0
	plo	r3
	glo	r2
c_1s_loop:
	smi	1
	bm	nta_done
	inc	r3
	br	c_1s_loop

nta_done:
	adi	1
	glo	r3
	adi	0x30
	str	r5
	inc	r5
	ldi	0
	str	r5

        ldi	LOW ascii_buffer
	plo	r5
	ldi	HIGH ascii_buffer
	phi	r5			; point r5 to ascii_buffer


	br	nta_return


	;================================
	; strcat
	;================================
	; called in rd
	; returns to r0
	; value to cat in r5
	; output buffer in r4

strcat_return:
	sep	r0

strcat:

strcat_loop:
	lda	r5			; load a byte, increment
	str	r4			; store a byte
	lbz	strcat_return		; if zero, return
	inc	r4			; if not, inc output pointer
	lbr	strcat_loop		; and loop


	;================================
	; WRITE_STDOUT
	;================================
	; runs as r9
	; expects to return to r0
	; r4 = string to print
	; ra,rf trashed

write_stdout_return:

	sep	r0			; return to r0

write_stdout:
	sex	r4			; use r4 as index

write_loop:
	ldxa				; load from r4 and increment
	lbz	write_stdout_return	; if zero we are done
	plo	rf			; put char into rf
	sep	rb			; call out_char
	lbr	write_loop		; loop







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
	lbnz	out_loop	; if not zero than loop

	seq			; mark parity
 	sep	rc		; delay

	req			; stop bit
 	sep	rc		; delay

	lbr	out_char_return	; done and return


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

;===========================================================================
;	section .data
;===========================================================================
;.data

.include	"logo.lzss_new"

ver_string:		db	" Version ",0
compiled_string:	db	", Compiled ",0
linefeed:		db	"\r\n",0
cpuinfo:		db	"proc/cpu.1802",0
one:			db	"One ",0
mhz:			db	"MHz ",0
processor:		db	" Processor, ",0
ram_comma:		db	"K RAM, ",0
bogo_total:		db	" Bogomips Total\r\n",0
default_colors:		db	27,"[0m\r\n\r\n",0
escape:			db	27,"["
after_escape:		db	0,0,0,0
C:			db	"C",0

; fake uname
uname_sysname:		db	"VMWos",0
uname_release:		db	"0.1",0
uname_version:		db	"#1 2015-03-12",0
uname_nodename:		db	"cosmac",0

; fake RAM
total_ram:		dw	32768

; fake cpuinfo
disk_buffer:		db	"cpu\t: 1802\n"
			db	"cpu MHz\t: 0.33\n"
			db	"BogoMIPS\t: 0.30\n",0


;============================================================================
;	section .bss
;============================================================================
;.bss
;bss_begin:
;.lcomm uname_info,(65*6)
;.lcomm sysinfo_buff,(64)
;.lcomm	disk_buffer,4096	; we cheat!!!!

ascii_buffer:	DS	10
text_buf:	DS	1087 	; 1024 + 64 - 1 =  1087 (N+F-1)
out_buffer:	DS	4096	; 4kb?





