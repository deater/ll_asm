;
;  linux_logo in z80 assembler 0.44
;
;       Vince Weaver <vince _at_ deater.net>
;
;  assemble with     "as -o ll.o ll.z80.s"
;  link with         "ld -o ll ll.o"
;
;  We use a cross-compiled z80-unknown-coff binutils for assembling
;   Do not use the "-N" option to ld or else you'll get a coff
;    executable.  We want a raw CP/M file.
;   You can enable -N to get a file objdump works on

; Architectural info
; + Registers, are 8-bit but can be joined as 16-bit
;  A/F  = accumulator / flags
;  B/C  = sometimes used as byte count
;  D/E
;  H/L
;  IX   = index (16 bits)
;  IY   = index (16 bits)
;  PC   = program counter (16 bits)
;  SP   = stack pointer (16 bits)
;  I/R = interrupt vector / refresh
;  AF' \
;  BC' |= alternate register set
;  DE' |
;  HL' /

; Flags
;  SF = significant bit (negative)
;  ZF = zero
;  YF = bit 5 of result
;  HF = half carry of an addition (from bit 3 to 4)
;  XF = bit 3 of result
;  PF = parity or overflow
;  NF = last insn was add or sub
;  CF = carry flag
;  XF, YF and NF can only be read using PUSH AF


; Addressing modes
; + immediate (1 byte)
; + immediate extended (2 bytes)
; + page zero (mainly used for interrupts)
; + relative (offset from PC)
; + extended (2 bytes)
; + indexed - a byte is added to one of the index registers
; + register
; + implied
; + register indirect - for example (HL)

; Instructions

; 8-bit Loads
; + 1 byte
; LD r,r  (move from reg to reg)
; LD r,(HL) (move value pointed to by HL)
; LD (HL),r (move to mem pointed to by HL)
; LD A,(BC)   LD A,(DE)
; LD (BC),A  LD (DE),A
; + 2 byte
; LD r,n  (move 8 bit immediate)
; LD (HL),n (move immediate to HL)
; LD A,I  LD I,A
; LD A,R  LD R,A
; + 3 byte
; LD r,(IX+d) , LD r,(IY+d) (move value pointed to by IX+d)
; LD (IX+d),r , LD (IY+d),r  (move to ID+x)
; LD A,(nn)  LD (nn),A
; + 4 byte
; LD (IX+d),n , LD (IY+d),n

; 16-bit loads
; + 1 byte
; LD SP,HL
; PUSH dd
; POP DD
; + 2 byte
; LD SP,IX  LD SP,IY
; PUSH IX  PUSH IY
; POP IX    POP IY
; + 3 byte
; LD DD,nn where DD is a 16-bit reg pair
; LD HL,(nn)  LD (nn),HL
; + 4 byte
; LD IX,nn LD IY,nn
; LD DD,(nn) LD (nn),DD
; LD IX,(nn) LD IY,(nn)
; LD (nn),IX LD (nn),IY

; Exchange instructions
; + 1 byte
; EX DE,HL
; EX AF,AF'
; EXX (exchange BC, DE and HL with ')
; EX (SP),HL
; + 2 byte
; EX (SP),IX  EX (SP),IY

; String Move instruction
; + 2 byte
; LDI  -- (HL) moved to (DE).  Both incremented, BC decremented
; LDIR -- like LDI, but repeats until BC is zero
; LDD -- like LDI but decrement instead of increment
; LDDR -- like LDD but repeat

; String Compare instructions
; + 2 byte
; CPI --- (HL) compared to A.  Condition bit set.  HL inc, BC dec
; CPIR -- like above, but repeats until BC zero or Z set
; CPD -- like above, but decrement
; CPDR -- like above, repeat

; 8-bit arithmetic
; + 1 byte
; ADD A,r    ADC A,r    SUB r    SBC r    AND r    OR r    XOR r
; ADD A,(HL) ADC A,(HL) SUB (HL) SBC (HL) AND (HL) OR (HL) XOR (HL)
; CP  r      CP (HL)
; INC r	     INC (HL)   DEC r    DEC (HL)

; + 2 byte
; ADD A,n    ADC A,n    SUB n    SBC n    AND n    OR n    XOR n
; CP  n

; + 3 byte
; ADD A, (IX+d)  ADD A, (IY+d)   ADC A, (IX+d)  ADC A, (IY+d)
; SUB (IX+d)     SUB (IY+d)      SBC (IX+d)     SBC (IY+d)
; AND (IX+d)     AND (IY+d)      OR  (IX+d)     OR  (IY+d)
; XOR (IX+d)     XOR (IY+d)      CP  (IX+d)     CP  (IY+d)
; INC (IX+d)	 INC (IY+d)      DEC (IX+d)     DEC (IY+d)

; BCD instructions
; + 1 byte
; DAA

; unary arithmetic
; + 1 byte
; CPL - ones complement of A
; + 2 byte
; NEG - negate A

; misc
; + 1 byte
; CCF,SCF - complement/set carry flag
; NOP, HALT
; DI,EI - disable/enable interrupts
; + 2 byte
; IM 0,1,2 - set interrupt mode

; 16-bit arithmetic
; + 1 byte
; ADD HL, dd  
; INC dd  DEC dd   -- note!  Does not modify flags
; + 2 byte
; INC IX, INC IY
; DEC IX, DEC IY
; ADC HL,dd  SBC HL,dd
; ADD IX,dd  ADD IY,dd (some restrictions on which register pairs)

; Rotate and Shift
; + 1 byte
; RLCA - rotate left (carry set from bit 7)
; RLA - rotate left through carry
; RRCA - rotate right, set carry
; RRA - rotate right through carry
; + 2 byte
; RLC r - rotate reg left (carry set)
; RLC (HL)  
; RL r - rotate left through carry
; RL (HL)
; RRC r, RRC (HL)
; RR r, RR (HL)
; SLA r, SLA (HL)
; SRA r, SRA (HL)
; SRL r, SRL (HL)
; RLD -- low 4 of (HL) to high (HL), high (HL) to bottom A, bot A to low (HL)
; RRD -- like above but right
; + 4 byte
; RLC (IX+d), RLC (IY+d)
; RL (IX+d), RL (IY+d)
; RRC (IX+d), RRC (IY+d)
; RR (IX+d), RR (IY+d)
; SLA (IX+d), SLA (IY+d)
; SRA (IX+d), SRA (IY+d)
; SRL (IX+d), SRL (IY+d)

; Bit testing and setting
; + 2 byte
; BIT b,r   BIT b,(HL)  -- test bit
; SET b,r   SET b,(HL)  -- set bit
; RES b,r   RES b,(HL)  -- reset bit
; + 4 byte
; BIT b,(IX+d)  BIT b,(IY+d)
; SET b,(IX+d)  SET b,(IY+d)
; RES b,(IX+d)  RES b,(IY+d)

; Jumps
; + 1 byte
; JP (HL)
; RET (return)
; RET cc
; RST P - software exception (sort of)
; + 2 byte
; JR e - jump relative
; JR C,e   JR NC,e   (carry/nocarry)
; JR Z,e   JR NZ,e   (zero/nozero)
; JP (IX)  JP (IY)
; DJNZ,e  --- decrement B, if not zero jump
; RETI (Return from interrupt)
; RETN (return from NMI)
; + 3 byte
; JP nn
; JP cc,nn where cc is NZ,Z,NC,C,PO,PE,P,M
; CALL e -- PC pushed on stack 
; CALL cc,e -- conditional call

; I/O
; IN, INI, INIR, IND, INDR
; OUT, OUTI, OTIR, OUTD, OUTR

; System calls
; + Call number is in C
; + Return is often in A
; + Register E is output
; CP/M
; + Programs start at 0x100 (TPA, Transient Program Area)
;   everything below that belongs to OS
; + Address 0x00 has a jump to the BIOS/warm-boot
; + Byte 0x04 is the current drive
; + Bytes 0x05-0x07 is a jump to BDOS which is the kernel entry point
; + Value at 0x06 can tell you size of memory?


; Optimization
; + 975 bytes - straight port of the pdp-11 code
; + 974 bytes - change a "jp P" to a "jr Z"
; + 973 bytes - use "DJNZ" instead of "DEC B/JR NZ"
; + 971 bytes - remove unneeded push/pops in middle line
; + 965 bytes - save HL so no-need to re-load for printing strings
; + 964 bytes - use "sbc HL,HL" instead of "ld HL,0"
; + 963 bytes - use "or A" to clear the carry flag
; + 944 bytes - rewrote find_string to use a loop
; + 942 bytes - remove extraneous push/pop
; + 940 bytes - jump instead of call at end of center_and_print
; + 934 bytes - re-organize num_to_ascii, have strcat be fall-through
; + 932 bytes - make write_stdout fallthrough for center_and_print
; + 925 bytes - re-write strcat to not use ldir
; + 920 bytes - move FCB to BSS.  Didn't save much as had to clear BSS to 0
; + 917 bytes - optimize strcat (thanks to Mikael Tillenius)
; + 916 bytes - turn a call/ret sequence into jump (Mikael Tillenius)
; + 915 bytes - use an immediate 0 to nul-terminate (Mikael Tillenius)
; + 903 bytes - re-write num_to_ascii
; + 896 bytes - misc cleanups.  Can't seem to optimize find_string at all

; + rethink use of IX/IY for pointers



.equ  BOOT, 0x0000
.equ  BDOS, 0x0005

; System Calls
.equ RESET,  0x00
.equ CONIN,  0x01	; A is char input
.equ CONOUT, 0x02	; E is char output
.equ READIN, 0x03
.equ PUNCH,  0x04
.equ LIST,   0x05
.equ DIRIO,  0x06
.equ GETIO,  0x07
.equ SETIO,  0x08
.equ PRINTST,0x09	; print string until $  DE is address of string
.equ VERSION,0x0c       ; version number returned in HL
.equ OPEN,   0x0f	; DE=FCB addy, ret A = directory code
.equ CLOSE,  0x10	; DE=FCB addy, ret A = directory code
.equ READSEQ,0x14	; DE=FCB addy, ret A = directory code

.include "logo.include"


     			  	        ; offset into TPA
;.org 0x100				; not needed?
      					; gas padds with .org :(

_start:
	ld     HL,stack+512    		; Setup stack?
	ld     SP,HL			; default stack only has room
					; for 8 entries...

	;=========================
	; PRINT LOGO
	;=========================

; LZSS decompression algorithm implementation
; by Stephan Walter 2002, based on LZSS.C by Haruhiko Okumura 1989
; optimized some more by Vince Weaver

setup:
	ld	IY,out_buffer		; out_buffer in IY
	push	IY			; save on stack for later use	
	exx
	ld	DE,N-F       		; R is in DE'
	exx
	ld	HL,logo			; HL points to logo data
		
decompression_loop:
	ld	C,(HL)   		; load a byte
	inc	HL			; increment pointer
	
	ld	B,0x08			; load top as a counter

test_flags:

	push	BC			; save BC
	ld	BC,logo_end		; load in end
	sbc	HL,BC			; subtract (no 16-bit compare)
	jr	Z,done_logo		; if zero, we are done
	add	HL,BC  	   		; restore HL back the way it was
	pop	BC			; restore BC

	srl 	C			; shift bottom bit into carry flag
	jr	C,discrete_char		; if C set, we jump to discrete char

offset_length:
				; load an unaligned little-endian word
				; and increment pointer by two
				
				; this has match_length and match_position
			       
				; match_position is top 10 bits 
				; match_length is 6 bits
				; these should be configurable, but tricky
				; on 8-bit machines to make generic
				
	push    BC			

	ld	C,(HL)		; load byte1
	inc	HL
	ld	B,(HL)		; load byte2
	inc	HL
	
	; get counter length in right place
	
	ld	A,B	        ; counter = (r4 >> P_BITS) + THRESHOLD + 1
	srl	A		;                       (=match_length)
	srl	A
	add	A,THRESHOLD+1
	ld	D,A	   	; D is counter length
	
	; get offset in right place

	ld      A,B
	and	POSITION_MASK
	ld	B,A
	
	push	BC
	pop	IX		        ; move BC into IX

	pop	BC			; restore original BC
	
output_loop:

	exx 				; change to alternate set

	push	IX			
	pop	BC			; move IX into BC'
	
	ld	A,B			; 
	and	POSITION_MASK		;
	ld	B,A			; mask BC' with 0x3ff
	
	ld	HL,text_buf		; point HL' to text_buf
	add	HL,BC			; add BC' to text_buf

	ld	A,(HL)			; load byte from text_buf[]
	
	inc	IX			; advance pointer in text_buf

	exx				; restore real register set

store_byte:
	cp 	0xa			; these instructions
	jr	NZ,not_linefeed		; handle the fact		
	ld	E,0xd			; that on CP/M
	ld	(IY+0),E		; we use \r\n
	inc	IY			; instead of just \n

not_linefeed:	

	ld	(IY+0),A		; store the byte in A

	inc	IY			; increment pointer

	exx	  			; switch to ALTERNATE registers
		
	ld	HL,text_buf		; load text buf into HL'
	add	HL,DE			; add HL' and DE'

	ld	(HL),A			; store a byte to text_buf[r]

	inc	DE			; increment DE'

	ld	A,D
	and	POSITION_MASK		; anding DE' with 0x3ff
	ld	D,A
					; masking r
					
	exx				; switch back to NORMAL registers
	
	dec	D			; decrement, repeat if !=0
	jr	NZ,output_loop		

	djnz	test_flags		; dec the by-8 counter (B)
					; if not zero, re-load flags

	jr	decompression_loop

discrete_char:
	ld	A,(HL)			; load a byte
	inc	HL			; increment pointer
	
	ld	D,1 			; set counter to output once
					; we know it has to be zero here

	jr	store_byte		; and store it

;
; end of LZSS code
;

done_logo:
	pop	BC			; restore from inside loop
	ld	(IY+0),'$'		; terminate string
	pop	DE			; get address of output
	push	DE			; store back again on stack
	call	write_stdout		; print the logo
		
	;==========================
	; PRINT VERSION
	;==========================
	
first_line:
	pop	DE
	push	DE			; set DE to output buffer
		
        ld    	C,VERSION		; get Version syscall
        call 	BDOS			; call OS	
					; H=00 is CP/M, H=01 is MP/M
					; L=20 for CP/M 2.0

print_os_version:
	ld	A,H			; move H (version) into A
	dec	A			; make A 0xff (cp/m) or 0x00 (mp/m) 
	and	'C'-'M'			; difference in the ascii codes
	add	A,'M'			; adjust to right string
	ld	(DE),A			; store byte
	inc	DE			; increment pointer

print_pm_string:
	push	HL			; save syscall result	
	ld	HL,ver_string		; source is "P/M Version "
	call	strcat
	pop	HL    			; restore result from version call
	
print_version_number:	
	ld	A,L			; move the version number
	rra
	rra
	rra
	rra				; shift to get high nibble
	and	0x0f			; mask
	add	A,0x30			; convert to ASCII
	ld	(DE),A			; write out
	inc	DE			; increment pointer
	
	ld	A,'.'			; write decimal point
	ld	(DE),A
	inc	DE
	
	ld	A,L			; minor version
	and	0x0f			; mask
	add	A,0x30			; convert to ASCII
	ld	(DE),A			; write out
	inc	DE			; increment pointer
	
	
	ld	HL,compiled_string	; source is ", Compiled "
	call	strcat			; we fake the date
	push	HL			; save for later	

	call	center_and_print	; center and print

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

	ld	DE,cpuinfo_fcb	     	; load the FCB addy
	push	DE			; save for later
	ld    	B,36			; want to clear 36 bytes
	xor	A			; clear to zero
clear_fcb:
	ld	(DE),A			; save zero
	inc	DE			; increment pointer
	djnz	clear_fcb		; loop
	
	
	ld    	BC,11			; we want to copy 11-byte string
	pop	DE			; restore FCB
	push	DE
	inc	DE			; point past drive indicator
	ld	HL,cpuinfo		; point to string value
	ldir				; run with it
	
	
	pop	DE			; point to FCB	
	push	DE	
	
        ld    	C,OPEN			; open FILE
        call 	BDOS			; call OS		
	
       					; result in A.  We ignore?
					
	pop    	DE				
	push	DE			; point to FCB
	ld	C,READSEQ		; read into 128 byte buffer at 0x80
	call	BDOS			; which is default DMA address
	
	pop	DE
	ld	C,CLOSE			; read info 128 byte buffer at 0x80
	call	BDOS			; which is default DMA address	

	pop	HL			; restore string pointer

	pop	DE			;
	push	DE			; set DE to output buffer
	
	;=============
	; Number of CPUs
	;=============
number_of_cpus:

					; Assume one processor
					; HL points to "One"
	call	strcat
	
	;=========
	; MHz
	;=========
print_mhz:
	
	push    HL
	ld	HL,mhz_search		; find the MHz
	call	find_string

	ld	A,' '	   		; store a space
	ld	(DE),A
	inc	DE

	;=========
	; Chip Name
	;=========
chip_name:
	
	ld	HL,type_search
	call	find_string

	pop     HL		       ; HL is points to the right place
				       ; for " Processor, "
	call	strcat

	;========
	; RAM
	;========
print_ram:	

	push	HL
	
	; determining RAM is a bit of a hack
	
	ld	HL,(0x06)      	      	; address 6 points to the end
					; of user-usable memory
					
	ld	A,H			; divide by 10 to get KB
	rra
	rra

	sbc	HL,HL			; small way to set HL to zero
	ld	L,A			; move result into lower byte
	
	or	A	  		; clear carry flag
	
	call	num_to_ascii

	pop	HL			; HL points to 'K RAM, '
	call	strcat			; call strcat

	push HL

	;========
	; Bogomips
	;========
print_bogomips:

	ld      HL,mips_search
	call    find_string   		; search for "MIPS"

	pop	HL
	call	strcat			; HL points to Bogomips Total

	call	center_and_print	; center and print


	;=================================
	; Print Host Name
	;=================================
last_line:
	pop	DE			; copy output buffer to DE
	
	ld	HL,host_string	       	; Print host string
	call	strcat
	push	HL

	call	center_and_print	; center and print

	pop	DE			; points to default_colors
	call	write_stdout	 	; write stdout
	
	
	;================================
	; Exit
	;================================
exit:
     	jp BOOT  			; Return to the OS.


	

	;==============================
	; center_and_print
	;==============================
	; DE = end of string
	; string to center at output_buffer

center_and_print:

	push	DE
	ld	DE,escape
	call	write_stdout		; we want to output ^[[
	
str_loop2:
        pop	HL			; get end of string into HL
	
	push	HL			; save end of string?
	
	ld	DE,out_buffer		; load beginning of buffer
	sbc	HL,DE			; subtract to get string length

	ld	A,L			; move length to A
	neg
	add	A,80			; result is 80-length
	
	jp	M,done_center		; if result negative, don't center

	sra	A			; divide by 2
;	adc	A,0			; round

	ld	L,A			; put in HL for printing
	scf				; print to stdout
	call	num_to_ascii		; print number of spaces

	ld	DE,Cstring		; writing out "C"
	call	write_stdout		; write_stdout

done_center:

	pop	DE			; restore end of string
	ld  	HL,linefeed		; CP/M line terminator
	call	strcat			; attach to  end

	ld	DE,out_buffer		; have to load, can't use
					; version on stack because
					; the return address is there first

					; write_stdout will return for us
		
	;================================
	; WRITE_STDOUT
	;================================
	; DE : has pointer to string

write_stdout:

        ld    	C,PRINTST		; print string syscall
        jp 	BDOS			; call OS, returns for us

	
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

	ld	IX,ascii_buffer		; point to output value
	push	IX			; save for later

	push 	AF			; save flags value for later	

	xor	A			; clear A' (non-leading zero)
	ex 	AF,AF'
	    
	ld	BC,-10000		; -10000 BC = 0xd8f0
	call	handle_digit
	ld	BC,-1000		;  -1000 BC = 0xfab8
	call	handle_digit
	ld	BC,-100			;   -100 BC = 0xff9c
	call	handle_digit
	ld	C,0xf6			;    -10 BC = 0xfff6
	call	handle_digit
	ld	C,0xff			;     -1 BC = 0xffff
	
					; fall through on -1 case

handle_digit:
	ld	A,'0'-1			; start 1 under '0'
digit_loop:
	inc	A			; move to next digit
	add	HL,BC			; subtract off power of 10
	jr	c,digit_loop		; if no overflow, then keep
					;  subtracting
	
	
	sbc	HL,BC			; we went too far, so adjust back
	
	ld	(IX+0),A		; write out the digit we found

	and	0xf			; if not a zero, write it out
	jr      NZ,write_digit

	; leading zero suppression

	xor	A			; clear A
	ex	AF,AF'			; get non-leading zero indicator
	or	C			; if low bit of C is 1, it means 
	and	1			;   we are on last digit so always
					;   print zero

	ret	Z			; otherwise suppress the zero


write_digit:	
	inc	IX			; move pointer (effectively writing)
	
	ld	A,1			; turn off zero suppression
	ex	AF,AF'

	bit    0,C			; are we done with the number?
	ret    Z			; if not, return for more

done_converting:

	; done converting

	pop	AF			; restore flags value from earlier
	jr	NC,num_to_strcat	; if C==0, strcat

num_to_stdout:
	pop	DE			; move buffer pointer to DE	
	ld	(IX+0),'$'		; CP/M terminating CHAR
	jr	write_stdout


num_to_strcat:
	pop	HL			; move buffer pointer to HL
	ld	(IX+0),0		; nul terminate string
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


	ld	A,(HL) 	    	        ; load in a byte
	ldi				; (HL) moved to (DE), both incremented
	or      A			; compare to zero
	jr      NZ,strcat		; if not zero, loop
	dec     DE			; point output to before NUL termination
	ret				; return
	
	;=================================
	; FIND_STRING 
	;=================================
	; HL is the string to find
	; DE is output pointer
	
find_string:
	
	push	DE			; save DE for our loop here  +1
	
	ld	DE,0x79			; look in cpuinfo buffer
					; one less so that we can inc first
					; thing inside loop

	push	DE			; save disk pointer for later  +2
	push	HL			; save find string for later  +3

no_match:
	pop	HL			; restore old find_pointer  +2	
	pop	DE			; restore old disk pointer  +1
	inc	DE			; increment disk pointer

	
	ld	A,D			; check to see if we've gone
	or	A			; past 128-byte buffer
	jr NZ,error

	push	DE	                ;                           +2
	push	HL     			; save for next loop        +3

	ld	B,4			; how many chars to compare
find_loop:
	
	ld	A,(DE)			; load in disk value
	cp	(HL)			; compare it with string
	inc	DE			; increment pointer
	inc	HL			; increment pointer
	jr	NZ,no_match		; if not match, move on
	djnz	find_loop		; check up to 4 characters

					; if we get here, we matched
	
	pop	HL			; throw away string pointer  +2
	pop	HL			; move disk pointer to HL    +1
;
error:
	pop	DE			; restore output pointer     +0

find_colon:
	ld 	A,':'			; looking for a colon
	ld	BC,0x80			; we want to search length of buffer
	cpir				; repeat until we find colon
	ret	NZ
	
	inc	HL			; skip the space

	ld 	A,13			; carriage return value
store_loop:	

	cp 	(HL)			; is value a carriage-return?

	ret	Z			; if so, we are done

	ldi				; otherwise load (HL) store (DE)
					; incrementing both, decrement BC
	jr  	store_loop		; loop
	




;===========================================================================
;	section .data
;===========================================================================
;.data
ver_string:	.asciz	"P/M Version "
compiled_string:.ascii	", Compiled "
compiled_date:	.asciz  "Fri Oct 17 10:00:00 EDT 1980"
one:		.asciz	"One "
processor:	.asciz	" Processor, "
ram_comma:	.asciz	"K RAM, "
bogo_total:	.asciz	" Bogomips Total"
host_string:	.asciz	"krg"
default_colors:	.byte  27
		.ascii "[0m"
linefeed:	.byte  13,10,'$'

escape:		.byte 27
		.ascii "[$"

Cstring:	.ascii "C$"

mhz_search:	.ascii " MHz"
mips_search:	.ascii "MIPS"
type_search:	.ascii "type"

cpuinfo:	.ascii "CPUINFO Z80"	; the filename "cpuinfo.z80"

.include	"logo.lzss_new"


;============================================================================
;	section .bss
;============================================================================
;.bss

.lcomm ascii_buffer,7
.lcomm text_buf, (N+F-1)
.lcomm	out_buffer,8192

;cpuinfo_fcb:	.byte 0	      ; drive code = "Any" (otherwise, which drive A-P)
;		.ascii  "CPUINFO " ; 8 bytes for the first part of the filename
;		.ascii  "Z80" ; the extension.  Highest bits indicate status
;		.byte 0       ; extent
;		.byte 0,0     ; reserved for system
;		.byte 0       ; record count
;		.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ; reserved for CP/M
;		.byte 0	      ; current record
;		.byte 0,0,0   ; random record numbers

.lcomm	cpuinfo_fcb,36

.lcomm	stack,512



