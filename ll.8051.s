;
;  linux_logo in 8051 assembler 0.45
;
;       Vince Weaver <vince _at_ deater.net>
;
;  assemble with     "as -o ll.o ll.8051.s"
;  link with         "ld -o ll ll.o"
;
; /home/vince/vmw/ll_simulators/8051/sdcc/bin/sdas8051
;  We use a cross-compiled z80-unknown-coff binutils for assembling
;   Do not use the "-N" option to ld or else you'll get a coff
;    executable.  We want a raw CP/M file.
;   You can enable -N to get a file objdump works on

; Architectural info:
;
; Bit-addressible memory?
; Program status word
;   carry bit, aux (for BCD), overflow, parity, 2 user-define, 2 reg
;   bank-switch

; A and B registers. B primarily used for mul/div
; RAM locations R0..R7.  Bank selected by RS0 and RS1
; DPTR - 16 bit pointer (DPH/DPL)

; stack starts at 0x7, grows up?

; P = parity of the accumulator
; 2 bits uncommitted, can be used as status flags

; Addressing modes
;  Direct - can only address lowest 128 bytes and SFRs
;    ADD A,7FH
;  Indirect- a reg that points to an address
;    ADD A, @R0
;     8 bit addresses can be R0 or R1
;    16 bit addresses can only be DPTR
;  Indexed - only can access program memory.  DPTR has address, A has
;    offset
;  Register -
;    ADD A,R7
;  Immediate -  look like #100 or #100H if hex
;    ADD A,#127

; Instructions
;   ACALL - absolute call
;   ADD A,byte    A=A+?
;   ADDC A,byte   A=A+? with carry
;   AJMP          absolute jump, within 2k range
;   ANL           and logical
;                 A=A&R
;                 A=A&(direct)
;                 A=A&@R  (indirect)
;                 A=A&#   (immediate)
;                 (direct)=(direct)&A
;                 (direct)=(direct0&#
;   ANL C         And with carry
;                 ANL C,bit
;                 ANL C,ACC.7
;                 ANL C,OV
;    slash means invert, ANL C,/OV
;  CNJE           compare and jump if not equal
;                 can compare any type with A
;                 any indirect or reg compared with immediate
;  CLR A          set accumulator to 0
;  CLR C
;  CLR bit
;  CPL A          compliment accumulator
;  CPL bit
;  DA  A          decimal adjust accumulator for addition
;  DEC byte       decrement byte.  does not affect flags
;  DIV AD         A=A/B  B=A%B
;  DJNZ           decrement and jump if not zero
;  INC byte       increment.  Doesn't affect accumulator
;  INC DPTR       increment 16-bit pointer
;  JB             jump if bit set
;  JBC            jump if bit set and clear bit
;  JC             jump if carry set
;  jmp @A+DPTR    adds A to DPTR and jumps to it
;  JNC            jump if carry not set
;  JNZ            jump if A not zero
;  JZ             jump if A zero
;  LCALL          call
;  LJMP           long jump to 16-bit address
;  MOV A, Rx
;  MOV A, direct
;  MOV A, @Rx
;  MOV A, #
;  MOV Rx, A
;  MOV Rx, direct
;  MOV Rx, #
;  MOV direct, A
;  MOV direct, Rx
;  MOV direct, direct
;  MOV direct, @Rx
;  mov direct, #
;  MOV @Rx, A
;  MOV @Rx, direct
;  MOV @Rx, #
;  MOV C,bit
;  MOV bit,C
;  MOV DPTR, #d16
;  MOVC          move code byte
;     MOVC A,@A+DPTR
;     MOVC A,@A+PC
;  MOVX - move to external memory
;  MUL AB - A=low(A*B), B=high(A*B)
;  NOP
;  ORL  - logical or
;  ORL C, bit
;  ORL C, /bit
;  POP - pop from stach
;  PUSH - push on stack
;  RET - return from subroutine
;  RETI - return from interrupt
;  RL A - rotate accumlator left
;  RLC A - rotate a left through carry
;  RR A - rotate A right
;  RRC A - rotate right through carry
;  SETB - set bit
;  SJMP - short jump
;  SUBB  - subtract with borrow
;  SWAP A - swap nibbles
;  XCH   - exchange byte
;  XCHD - exchange nibble
;  XRL - exclusive or



; Optimization


;.include "logo.include"


     			  	        ; offset into TPA
;.org 0x100				; not needed?
      					; gas padds with .org :(

_start:
;	ld     HL,stack+512    		; Setup stack?
;	ld     SP,HL			; default stack only has room
					; for 8 entries...

	;=========================
	; PRINT LOGO
	;=========================

; LZSS decompression algorithm implementation
; by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
; optimized some more by Vince Weaver

setup:
;	ld	IY,out_buffer		; out_buffer in IY
;	push	IY			; save on stack for later use	
;	exx
;	ld	DE,N-F       		; R is in DE'
;	exx
;	ld	HL,logo			; HL points to logo data
		
decompression_loop:
;	ld	C,(HL)   		; load a byte
;	inc	HL			; increment pointer
	
;	ld	B,0x08			; load top as a counter

test_flags:

;	push	BC			; save BC
;	ld	BC,logo_end		; load in end
;	sbc	HL,BC			; subtract (no 16-bit compare)
;	jr	Z,done_logo		; if zero, we are done
;	add	HL,BC  	   		; restore HL back the way it was
;	pop	BC			; restore BC

;	srl 	C			; shift bottom bit into carry flag
;	jr	C,discrete_char		; if C set, we jump to discrete char

offset_length:
				; load an unaligned little-endian word
				; and increment pointer by two
				
				; this has match_length and match_position
			       
				; match_position is top 10 bits 
				; match_length is 6 bits
				; these should be configurable, but tricky
				; on 8-bit machines to make generic
				
;	push    BC			

;	ld	C,(HL)		; load byte1
;	inc	HL
;	ld	B,(HL)		; load byte2
;	inc	HL
	
	; get counter length in right place
	
;	ld	A,B	        ; counter = (r4 >> P_BITS) + THRESHOLD + 1
;	srl	A		;                       (=match_length)
;	srl	A
;	add	A,THRESHOLD+1
;	ld	D,A	   	; D is counter length
	
	; get offset in right place

;	ld      A,B
;	and	POSITION_MASK
;	ld	B,A
	
;	push	BC
;	pop	IX		        ; move BC into IX

;	pop	BC			; restore original BC
	
output_loop:

;	exx 				; change to alternate set

;	push	IX			
;	pop	BC			; move IX into BC'
	
;	ld	A,B			; 
;	and	POSITION_MASK		;
;	ld	B,A			; mask BC' with 0x3ff
	
;	ld	HL,text_buf		; point HL' to text_buf
;	add	HL,BC			; add BC' to text_buf

;	ld	A,(HL)			; load byte from text_buf[]
	
;	inc	IX			; advance pointer in text_buf

;	exx				; restore real register set

store_byte:
;	cp 	0xa			; these instructions
;	jr	NZ,not_linefeed		; handle the fact		
;	ld	E,0xd			; that on CP/M
;	ld	(IY+0),E		; we use \r\n
;	inc	IY			; instead of just \n

not_linefeed:	

;	ld	(IY+0),A		; store the byte in A

;	inc	IY			; increment pointer

;	exx	  			; switch to ALTERNATE registers
		
;	ld	HL,text_buf		; load text buf into HL'
;	add	HL,DE			; add HL' and DE'

;	ld	(HL),A			; store a byte to text_buf[r]

;	inc	DE			; increment DE'

;	ld	A,D
;	and	POSITION_MASK		; anding DE' with 0x3ff
;	ld	D,A
					; masking r
					
;	exx				; switch back to NORMAL registers
	
;	dec	D			; decrement, repeat if !=0
;	jr	NZ,output_loop		

;	djnz	test_flags		; dec the by-8 counter (B)
					; if not zero, re-load flags

;	jr	decompression_loop

discrete_char:
;	ld	A,(HL)			; load a byte
;	inc	HL			; increment pointer
	
;	ld	D,1 			; set counter to output once
					; we know it has to be zero here

;	jr	store_byte		; and store it

;
; end of LZSS code
;

done_logo:
;	pop	BC			; restore from inside loop
;	ld	(IY+0),'$'		; terminate string
;	pop	DE			; get address of output
;	push	DE			; store back again on stack
;	call	write_stdout		; print the logo
		
	;==========================
	; PRINT VERSION
	;==========================
	
first_line:
;	pop	DE
;	push	DE			; set DE to output buffer
		
;       ld    	C,VERSION		; get Version syscall
;        call 	BDOS			; call OS	
					; H=00 is CP/M, H=01 is MP/M
					; L=20 for CP/M 2.0

print_os_version:
;	ld	A,H			; move H (version) into A
;	dec	A			; make A 0xff (cp/m) or 0x00 (mp/m) 
;	and	'C'-'M'			; difference in the ascii codes
;	add	A,'M'			; adjust to right string
;	ld	(DE),A			; store byte
;	inc	DE			; increment pointer

print_pm_string:
;	push	HL			; save syscall result	
;	ld	HL,ver_string		; source is "P/M Version "
;	call	strcat
;	pop	HL    			; restore result from version call
	
print_version_number:	
;	ld	A,L			; move the version number
;	rra
;	rra
;	rra
;	rra				; shift to get high nibble
;	and	0x0f			; mask
;	add	A,0x30			; convert to ASCII
;	ld	(DE),A			; write out
;	inc	DE			; increment pointer
	
;	ld	A,'.'			; write decimal point
;	ld	(DE),A
;	inc	DE
	
;	ld	A,L			; minor version
;	and	0x0f			; mask
;	add	A,0x30			; convert to ASCII
;	ld	(DE),A			; write out
;	inc	DE			; increment pointer
	
	
;	ld	HL,compiled_string	; source is ", Compiled "
;	call	strcat			; we fake the date
;	push	HL			; save for later	

;	call	center_and_print	; center and print

	;===============================
	; Middle-Line
	;===============================

middle_line:		

	;=========
	; Load file "cpuinfo .z80" info buffer
	;=========
	
	
	; I could use one of the built-in FCB areas
	; but I use one on the BSS instead

	; bss isn't initialized to zero by default :(
	; I guess you need a real OS for that

;	ld	DE,cpuinfo_fcb	     	; load the FCB addy
;	push	DE			; save for later
;	ld    	B,36			; want to clear 36 bytes
;	xor	A			; clear to zero
clear_fcb:
;	ld	(DE),A			; save zero
;	inc	DE			; increment pointer
;	djnz	clear_fcb		; loop
	
	
;	ld    	BC,11			; we want to copy 11-byte string
;	pop	DE			; restore FCB
;	push	DE
;	inc	DE			; point past drive indicator
;	ld	HL,cpuinfo		; point to string value
;	ldir				; run with it
;	
	
;	pop	DE			; point to FCB	
;	push	DE	
	
 ;       ld    	C,OPEN			; open FILE
  ;      call 	BDOS			; call OS		
	
       					; result in A.  We ignore?
					
;	pop    	DE				
;	push	DE			; point to FCB
;	ld	C,READSEQ		; read into 128 byte buffer at 0x80
;	call	BDOS			; which is default DMA address
	
;	pop	DE
;	ld	C,CLOSE			; read info 128 byte buffer at 0x80
;	call	BDOS			; which is default DMA address	

;	pop	HL			; restore string pointer

;	pop	DE			;
;	push	DE			; set DE to output buffer
	
	;=============
	; Number of CPUs
	;=============
number_of_cpus:

					; Assume one processor
					; HL points to "One"
;	call	strcat
	
	;=========
	; MHz
	;=========
print_mhz:
	
;	push    HL
;	ld	HL,mhz_search		; find the MHz
;	call	find_string

;	ld	A,' '	   		; store a space
;	ld	(DE),A
;	inc	DE

	;=========
	; Chip Name
	;=========
chip_name:
	
;	ld	HL,type_search
;	call	find_string

;	pop     HL		       ; HL is points to the right place
				       ; for " Processor, "
;	call	strcat

	;========
	; RAM
	;========
print_ram:	

;	push	HL
	
	; determining RAM is a bit of a hack
	
;	ld	HL,(0x06)      	      	; address 6 points to the end
					; of user-usable memory
					
;	ld	A,H			; divide by 10 to get KB
;	rra
;	rra

;	sbc	HL,HL			; small way to set HL to zero
;	ld	L,A			; move result into lower byte
	
;	or	A	  		; clear carry flag
	
;	call	num_to_ascii

;	pop	HL			; HL points to 'K RAM, '
;	call	strcat			; call strcat

;	push HL

	;========
	; Bogomips
	;========
print_bogomips:

;	ld      HL,mips_search
;	call    find_string   		; search for "MIPS"

;	pop	HL
;	call	strcat			; HL points to Bogomips Total

;	call	center_and_print	; center and print


	;=================================
	; Print Host Name
	;=================================
last_line:
;	pop	DE			; copy output buffer to DE
	
;	ld	HL,host_string	       	; Print host string
;	call	strcat
;	push	HL

;	call	center_and_print	; center and print

;	pop	DE			; points to default_colors
;	call	write_stdout	 	; write stdout
	
	
	;================================
	; Exit
	;================================
exit:
;     	jmp exit  			; Return to the OS.


	

	;==============================
	; center_and_print
	;==============================
	; DE = end of string
	; string to center at output_buffer

center_and_print:

;	push	DE
;	ld	DE,escape
;	call	write_stdout		; we want to output ^[[
	
str_loop2:
 ;       pop	HL			; get end of string into HL
	
;	push	HL			; save end of string?
	
;	ld	DE,out_buffer		; load beginning of buffer
;	sbc	HL,DE			; subtract to get string length

;	ld	A,L			; move length to A
;	neg
;	add	A,80			; result is 80-length
	
;	jp	M,done_center		; if result negative, don't center

;	sra	A			; divide by 2
;	adc	A,0			; round

;	ld	L,A			; put in HL for printing
;	scf				; print to stdout
;	call	num_to_ascii		; print number of spaces

;	ld	DE,Cstring		; writing out "C"
;	call	write_stdout		; write_stdout

done_center:

;	pop	DE			; restore end of string
;	ld  	HL,linefeed		; CP/M line terminator
;	call	strcat			; attach to  end

;	ld	DE,out_buffer		; have to load, can't use
					; version on stack because
					; the return address is there first

					; write_stdout will return for us
		
	;================================
	; WRITE_STDOUT
	;================================
	; DE : has pointer to string

write_stdout:

;        ld    	C,PRINTST		; print string syscall
 ;       jp 	BDOS			; call OS, returns for us

	
	;=============================
	; num_to_ascii
	;=============================
	; HL = value to print
	; CF = 1, stdout
	; CF = 0, strcat
	; AF,BC,DE,IX   trashed
	
	; this code roughly based on code by Milos Bazelides
	;    http://baze.au.com/misc/z80bits.html
	
num_to_ascii:

;	ld	IX,ascii_buffer		; point to output value
;	push	IX			; save for later

;	push 	AF			; save flags value for later	

;	xor	A			; clear A' (non-leading zero)
;	ex 	AF,AF'
	    
;	ld	BC,-10000		; -10000 BC = 0xd8f0
;	call	handle_digit
;	ld	BC,-1000		;  -1000 BC = 0xfab8
;	call	handle_digit
;	ld	BC,-100			;   -100 BC = 0xff9c
;	call	handle_digit
;	ld	C,0xf6			;    -10 BC = 0xfff6
;	call	handle_digit
;	ld	C,0xff			;     -1 BC = 0xffff
	
					; fall through on -1 case

handle_digit:
;	ld	A,'0'-1			; start 1 under '0'
digit_loop:
;	inc	A			; move to next digit
;	add	HL,BC			; subtract off power of 10
;	jr	c,digit_loop		; if no overflow, then keep
					;  subtracting
	
	
;	sbc	HL,BC			; we went too far, so adjust back
	
;	ld	(IX+0),A		; write out the digit we found

;	and	0xf			; if not a zero, write it out
;	jr      NZ,write_digit

	; leading zero suppression

;	xor	A			; clear A
;	ex	AF,AF'			; get non-leading zero indicator
;	or	C			; if low bit of C is 1, it means 
;	and	1			;   we are on last digit so always
					;   print zero

;	ret	Z			; otherwise suppress the zero


write_digit:	
;	inc	IX			; move pointer (effectively writing)
	
;	ld	A,1			; turn off zero suppression
;	ex	AF,AF'

;	bit    0,C			; are we done with the number?
;	ret    Z			; if not, return for more

done_converting:

	; done converting

;	pop	AF			; restore flags value from earlier
;	jr	NC,num_to_strcat	; if C==0, strcat

num_to_stdout:
;	pop	DE			; move buffer pointer to DE	
;	ld	(IX+0),'$'		; CP/M terminating CHAR
;	jr	write_stdout


num_to_strcat:
;	pop	HL			; move buffer pointer to HL
;	ld	(IX+0),0		; nul terminate string
		     			; fall through to strcat


	;================================
	; strcat
	;================================
	; value to cat in HL
	; output buffer in DE
strcat:

        ; orig calculated strlen so we can use ldir
	; but ldir only useful for pascal strings

	; Mikael Tillenius provided a version using "ldi" 
	; that was 3-bytes smaller than the one I came up with
	; that used discrete instructions


;	ld	A,(HL) 	    	        ; load in a byte
;	ldi				; (HL) moved to (DE), both incremented
;	or      A			; compare to zero
;	jr      NZ,strcat		; if not zero, loop
;	dec     DE			; point output to before NUL termination
;	ret				; return
	
	;=================================
	; FIND_STRING 
	;=================================
	; HL is the string to find
	; DE is output pointer
	
find_string:
	
;	push	DE			; save DE for our loop here  +1
	
;	ld	DE,0x79			; look in cpuinfo buffer
					; one less so that we can inc first
					; thing inside loop

;	push	DE			; save disk pointer for later  +2
;	push	HL			; save find string for later  +3

no_match:
;	pop	HL			; restore old find_pointer  +2	
;	pop	DE			; restore old disk pointer  +1
;	inc	DE			; increment disk pointer

	
;	ld	A,D			; check to see if we've gone
;	or	A			; past 128-byte buffer
;	jr NZ,error

;	push	DE	                ;                           +2
;	push	HL     			; save for next loop        +3

;	ld	B,4			; how many chars to compare
find_loop:
	
;	ld	A,(DE)			; load in disk value
;	cp	(HL)			; compare it with string
;	inc	DE			; increment pointer
;	inc	HL			; increment pointer
;	jr	NZ,no_match		; if not match, move on
;	djnz	find_loop		; check up to 4 characters

					; if we get here, we matched
	
;	pop	HL			; throw away string pointer  +2
;	pop	HL			; move disk pointer to HL    +1
;
error:
;	pop	DE			; restore output pointer     +0

find_colon:
;	ld 	A,':'			; looking for a colon
;	ld	BC,0x80			; we want to search length of buffer
;	cpir				; repeat until we find colon
;	ret	NZ
	
;	inc	HL			; skip the space

;	ld 	A,13			; carriage return value
store_loop:	

;	cp 	(HL)			; is value a carriage-return?

;	ret	Z			; if so, we are done

;	ldi				; otherwise load (HL) store (DE)
					; incrementing both, decrement BC
;	jr  	store_loop		; loop
	




;===========================================================================
;	section .data
;===========================================================================
;.data
;ver_string:	.asciz	"P/M Version "
;compiled_string:.ascii	", Compiled "
;compiled_date:	.asciz  "Fri Oct 17 10:00:00 EDT 1980"
;one:		.asciz	"One "
;processor:	.asciz	" Processor, "
;ram_comma:	.asciz	"K RAM, "
;bogo_total:	.asciz	" Bogomips Total"
;host_string:	.asciz	"krg"
;default_colors:	.byte  27
;		.ascii "[0m"
;linefeed:	.byte  13,10,'$'

;escape:		.byte 27
;		.ascii "[$"

;Cstring:	.ascii "C$"

;mhz_search:	.ascii " MHz"
;mips_search:	.ascii "MIPS"
;type_search:	.ascii "type"

;cpuinfo:	.ascii "CPUINFO Z80"	; the filename "cpuinfo.z80"

;.include	"logo.lzss_new"


;============================================================================
;	section .bss
;============================================================================
;.bss

;.lcomm ascii_buffer,7
;.lcomm text_buf, (N+F-1)
;.lcomm	out_buffer,8192

;cpuinfo_fcb:	.byte 0	      ; drive code = "Any" (otherwise, which drive A-P)
;		.ascii  "CPUINFO " ; 8 bytes for the first part of the filename
;		.ascii  "Z80" ; the extension.  Highest bits indicate status
;		.byte 0       ; extent
;		.byte 0,0     ; reserved for system
;		.byte 0       ; record count
;		.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ; reserved for CP/M
;		.byte 0	      ; current record
;		.byte 0,0,0   ; random record numbers

;.lcomm	cpuinfo_fcb,36

;.lcomm	stack,512



