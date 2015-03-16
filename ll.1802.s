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

;	Optimization:
;	+ 1030 -- initial working code
;	+ 1029 -- remove redundant instruction
;	+ 1025 -- remove extraneous NOPs
;	+ 1015 -- merge loading of high function addresses when the same
;	+ 1011 -- re-arrange functions so all start in page 1
;	+ 1009 -- remove superflous set of D to zero
;	+ 1008 -- remove extraneous sex
;	+ 1004 -- inline out_char
;	+ 1003 -- use skp instruction in out_char
;	+ 1002 -- use lsdf instruction in out_char
;	+ 1000 -- remove out_char initialization
;	+  991 -- optimize center_and_print to need only 3 calls
;	+  987 -- remove some now-unneeded long branches


;	.globl _start
;_start:

	br	done_logo		; while debugging (for speed)

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

	ldi	LOW 960
	plo	r2
	ldi	HIGH 960		; N - F = 1024-64 = 960
	phi	r2


	sex	r4		; set index to r4

decompression_loop:
	ldxa			; load a byte, increment pointer
	plo	rb		; store byte in rb

	ldi	8		; bits left
	plo	r9		; use r9 as a counter

test_flags:
	ghi	r4		; full 16-bit compare
	smi	HIGH logo_end	; is this necessary?
	bnz	not_done	; TODO: convert to skip?
				; but then skip into mid-instruction?

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
	ani	3		; by anding high byte with 3
	phi	rc

	glo	rc		; index to text_buf[rc]
	adi	LOW text_buf
	plo	re
	ghi	rc
	adci	HIGH text_buf
	phi	re

	ldn	re		; load byte from text_buf[rc]
	inc	rc		; advance rc pointer

store_byte:
					; byte currently in D

	str	r1			; store a byte
	inc	r1			; increment pointer

	plo	ra			; save temporarily to ra

	glo	r2			; get address for text_buf[r2]
	adi	LOW text_buf
	plo	re
	ghi	r2
	adci	HIGH text_buf
	phi	re

	glo	ra			; restore byte to output
	str	re			; store a byte to text_buf[r2]
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

	br	store_byte		; and store it

; end of LZSS code

done_logo:

	; Group routines with high byte 1 together

	ldi	HIGH num_to_ascii	; point r7 to num_to_ascii
	phi	r7
;	ldi	HIGH find_string	; point r8 to find_string
	phi	r8
;	ldi	HIGH write_stdout	; point r9 to write_stdout
	phi	r9
;	ldi	HIGH delay		; point rc to delay
	phi	rc
;	ldi	HIGH strcat		; point rd to strcat
	phi	rd
;	ldi	HIGH center_and_print	; point re to center_and_print
	phi	re



	ldi	LOW num_to_ascii	; point r7 to num_to_ascii
	plo	r7
	ldi	LOW find_string		; point r8 to find_string
	plo	r8
	ldi	LOW write_stdout
	plo	r9
	ldi	LOW delay
	plo	rc
	ldi	LOW strcat		; point rd to strcat
	plo	rd
	ldi	LOW center_and_print
	plo	re


	; Load out_buffer

        ldi	LOW out_buffer
	plo	r4
	ldi	HIGH out_buffer
	phi	r4

	; Print the logo
;	sep	r9		; call write_stdout

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
;	sep	re

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

	ldi	LOW ascii_buffer
	plo	r5
	ldi	HIGH ascii_buffer
	phi	r5			; point r5 to ascii_buffer

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
;	sep	re

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
;	sep	re

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



	;=================================
	; FIND_STRING
	;=================================
	; r2/r3 = string to find
	; rf = char to end at
	; returns to r0
	; called as r8
	; trashes/looks in r6
	; writes to r4

find_string_return:
	sep	r0

find_string:

        ldi	LOW disk_buffer
	plo	r6
	ldi	HIGH disk_buffer
	phi	r6			; point r6 to disk_buffer

	sex	r6			; so we can use "sm" instruction

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

	glo	r3			; get third byte
	sm				; compare
	bz	find_colon		; if same, we matched!

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
	lda	r6			; load byte from r6, inc
	str	r4			; store to r4
	inc	r4			; increment r4

	ghi	r3			; compare to end char
	sm
	bnz	store_loop

almost_done:
	; D is zero in order to fall through here

	str	r4			; replace last value with NUL

done:
	br	find_string_return	; return



	;================================
	; strcat
	;================================
	; called in rd
	; returns to r0
	; value to cat in r5
	; output buffer in r4

	; really want to make this 7 bytes but can't figure
	; out how to make it smaller, even using skips

strcat_return:
	sep	r0

strcat:

strcat_loop:
	lda	r5			; load a byte, increment
	str	r4			; store a byte
	bz	strcat_return		; if zero, return
	inc	r4			; if not, inc output pointer
	br	strcat_loop		; and loop


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

write_loop:
	lda	r4			; load from r4 and increment
	bz	write_stdout_return	; if zero we are done
	plo	rf			; put char into rf

	;=======================
	; begin out_char inline
	;=======================

out_char:
	ldi	7		; load bit counter
	plo	ra		; and put in ra

        seq			; begin start bit
 	sep	rc		; call delay

out_loop:

	glo	rf		; load in char to output
	shr			; shift into carry
	plo	rf		; store back to rf

	lsdf			; if carry set, skip to out_one, output a 1

	seq			; otherwise, output a 0
				; (note, we are assuming the serial
				; hardware inverts Q)

	skp			; skip ahead to not_one

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

	;=====================
	; end out_char inline
	;=====================

	br	write_loop		; loop



	;================================
	; DELAY
	;================================
	; expects to be run as rc
	; expects to return to r9

delay_begin:
	sep	r9		; return

delay:
	ldi	49		; loop 49 times
				; this isn't calculated but was found
				; by trial and error

delay_loop:
	smi	1		; decrement counter
	bnz	delay_loop	; repeat until empty
	br	delay_begin	; goto return


	;==============================
	; center_and_print
	;==============================
	; string to center in out_buffer
	; end of string in r4
	; called as re
	; returns to r0
	; you need to call this three times in succession

center_and_print_return:
	sep	r9			; tail call write_stdout

center_and_print:

					; assume never more than 128 bytes
	glo	r4			; get low value of end pointer
	smi	LOW out_buffer		; subtract start pointer

					; subtract length from 81
	sdi	81			; we use 81 to not count ending \n

	lsdf				; if result negative, don't center

	ldi	0			; skipped if positive

no_zero:

	shr				; divide by 2

	plo	r2			; put into r2

        ldi	LOW after_escape
	plo	r5
	ldi	HIGH after_escape
	phi	r5			; point r5 to where we want our value

	sep	r7			; call num_to_ascii

	ldi	'C'			; tack a 'C' onto the end
	str	r5

        ldi	LOW escape
	plo	r4
	ldi	HIGH escape
	phi	r4			; we want to output ^[[NNNC

	sep	r9			; call write_stdout

done_center:

        ldi	LOW out_buffer		; point to output_buffer
	plo	r4
	ldi	HIGH out_buffer
	phi	r4			; point r4 to out_buffer

	br	center_and_print_return


	;=============================
	; num_to_ascii
	;=============================
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
	bnf	nta_done	; bm branch minus
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

	lbr	nta_return




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
after_escape:		db	0,0,0,0,0

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





