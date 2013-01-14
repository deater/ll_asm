;
;  ll.65c816.s  -- Linux Logo in 65c816 Assembly for the SNES v0.47
;
;               by Vince Weaver  <vince _at_ deater.net>
;
;     decompresses the same lzss data as the Linux versions
;     but displays it to the Mode 1 SNES Screen

; 65c816 -- 16 bit extension to the 6502
;  Comes up in 6502 compatibility mode
;  3 registers, A, X, Y
;    8 or 16-bits.  Top half of A is called B, C is combo of B|A
;  Stack pointer S (can be anywhere bank 0)
;  Status register P  -- NVMXDIZC
;    Negative, oVerflow, M (Accum 8/16), X (X,y 8/16), Decimal,
;    IRQ Disable, Zero, Carry
;  Direct (Zero) page register D (can be anywhere bank 0)
;     not being at multiple of 256 adds extra clock cycle
;  B -- data bank register (top 8 bits of 24-bit address)
;  K -- program bank register (top 8-bits of 24-bit address)
;

; When transition 8->16 16->8 on Accumulator, high 8-bits (B) retained
; When transition 8->16 16->8 on X,Y -> high 8 bits set to 0

; New instructions (vs 6502)
;   TXY, TYX -- transfer X/Y
;   TCD, TDC -- transfer A to DP
;   TCS, TSC -- transfter A to Stack Pointer
;   XBA      -- exchange low and high bits of A
;   XCE      -- exchange emulation bit with carry flag
;   PHX,PHY,PLX,PLY -- push/pull X and Y on stack
;   PHB,PLB  -- push/pull the data register
;   PHK      -- push program bank register (no pull)
;   PHD,PLD  -- push/pull direct page register
;   PEA      -- push effective absolute address
;   PEI      -- push effecitive indirect address
;   PER      -- push effective relative address
;   MVN,MVP  -- memory block move next/previous (direction is pos or neg)
;   STZ      -- store zero
;   BRA      -- branch always
;   BRL      -- branch to address in bank0
;   RTL      -- return long (pulls bank off stack too)
;   SEP,REP  -- Set or Clear bits in Status

; New Addressing Modes
; Program Counter Relative Long -- now +/- 32k
; Stack relative -- LDA 14, S    S always points to next value
; Stack Relative Indirect Index Y -- LDA (14,S),Y
; Block Move
; Absolute Long -- LDA $BEBEEF (24-bit)
; Absolute Long Indexed X -- LDA $BEBEEF,X
; Absolute Indexed Indirect -- JMP ($1111,X)
; Absolute Indirect Long -- JMP [$5678]
; Direct Page Indirect -- LDA ($56) -- indirect, 2 bytes
; Direct Page Indirect Long -- LDA [$56] -- indirect, 3 bytes (including bank)
; Direct Page Indirect Long Indexed Y -- LDA [$56],Y

; other instructions
; ADC -- add with carry
; AND -- and accumuator with memory
; ASL -- arithmetic shift left
; BCC (BLT), BCS (BGE), BEQ, BNE, BMI, BPL, BVC, BVS -- branch of status
; BIT -- test mem against accumulator
; BRK -- software interrupt
; CLC, CLD, CLI, CLV -- clear status
; SEC, SED, SEI, SEV -- set status
; CMP -- compare accumulator with memory
; CPX, CPY -- compare X or Y with memory
; COP -- co-processor
; DEC -- decrement memory (can DEC A now)
; DEA, DEX, DEY -- decrement A or X or Y
; EOR -- exclusive or A with memory
; INC -- incrememnt memory (can INC A now)
; INA, INX, INY -- increment A or X or Y
; JMP
; JSR, JSL -- Jump to subroutine (long)
; LDA -- load accumulator from memory
; LDX, LDY -- load X or Y from memory
; LSR -- logical shift right
; MVP, MVN move positive (dest>source), negative (dest<source)
;  source in X, dest in Y, 16-bit len is A-1
;  operands are source bank and destination bank
; NOP -- no op
; ORA -- OR A with mem
; PEA -- push immediate on stack
; PEI -- push effective indirect
; PER -- push PC relative indirect address
; PHA, PLA, PHP, PLP -- push/pull A or status
; ROL, ROR -- rotate mem or accumulator
; RTI -- return from Interrupt (pulls P too)
; RTS, RTL -- return from subroutine (long)
; SBC -- subtract with borrow
; STA -- Store A to mem
; STP -- stop processor (maybe low power?)
; STX, STY -- store X,Y to memory
; TAX, TXA, TAY, TYA, TSX, TXS -- transfer between registers
; TRB, TSB -- rest and set, test and reset memory bits
; WAI -- wait for interrupt
; WDM -- future expansion (initials of designer)
; 
 

; Page zero locations

.setcpu "65816"

.segment "STARTUP"

	; Called at Reset (Startup) Time
Reset:

	; Run the initialization code
	; as the hardware state is unknown at reset

.include "snes_init.s"

	;================================
	; Get Ready to Go
	;================================

	phk			;make sure Data Bank = Program Bank
	plb

	cli			;enable interrupts



;==============================================
;==============================================
; DONE INITIALIZATION
;==============================================
;==============================================

start_program:

	rep	#$10	; X/Y = 16 bit
.i16
	sep	#$20	; mem/A = 8 bit
.a8

	lda     #^screen_byte	; get bank for x_direction var (probably $7E)
	pha			;
	plb			; set the data bank to the one containing x_dir$


.define EQU =
LOGOB     EQU $FA
LOGOH     EQU $F9
LOGOL     EQU $F8
OUTPUTH   EQU $F7
OUTPUTL   EQU $F6
ROFFSETH  EQU $F5
ROFFSETL  EQU $F4
LOADRH    EQU $F3
LOADRL    EQU $F2
MSELECTH  EQU $F1
MSELECTL  EQU $F0

;; LZSS Parameters

N             EQU 1024
F             EQU 64
THRESHOLD     EQU 2
P_BITS        EQU 10
POSITION_MASK EQU 3

;	sep	#$20	; mem/A = 8 bit
;.a8

	stz	LOGOB

	rep	#$20	; mem/A = 16 bit
.a16


start_lzss:

	lda	#logo			; load logo pointer
	sta	LOGOL

	lda	#.LOWORD(output)	; load output pointer
	sta	OUTPUTL

	lda	#(N-F)			; load R value
	sta	ROFFSETL

decompression_loop:

	sep	#$20		; mem/A = 8 bit
.a8
	lda	#$ff		; set mask counter
	xba
	lda	[LOGOL]		; load byte from logo

	rep	#$20		; mem/A = 16 bit
.a16
	sta	MSELECTL
	inc	LOGOL		; increment pointer

test_flags:

	lda	#logo_end
	cmp	LOGOL		; compare to see if we've reached end
        beq	done_logo	; if so, we are done

not_match:
	lsr     MSELECTL	; shift byte mask into carry flag

	bcs	discrete_char	; if set we have discrete char

offset_length:

	lda	[LOGOL]		; load a little-endian word
	inc	LOGOL		; increment pointer
	inc	LOGOL		; increment pointer (urgh forgot this at first)

	tay			; copy value to Y

	xba
	and	#$ff
	lsr	A
	lsr	A		; shift right by 10 (top byte by 2)
	clc
	adc	#(THRESHOLD+1)	; add threshold+1 (3)

	tax			; store out count in X
output_loop:

	tya
	and	#(N-1)		; Mask so mod N
	tay

	sep	#$20		; mem/A = 8 bit
.a8
	lda	text_buf,Y

	rep	#$20		; mem/A = 16 bit
.a16

	iny

store_byte:
	phy
	sep	#$20		; mem/A = 8 bit
.a8
	sta	(OUTPUTL)	; store byte to output

	ldy	ROFFSETL
	sta	text_buf,Y	; store to text_buf[r]

	rep	#$20		; mem/A = 16 bit
.a16
	inc	OUTPUTL		; increment address
	iny
	tya
	and	#(N-1)
	sta	ROFFSETL

	ply

	dex				; count down the out counter
	bne	output_loop		; loop to output_loop if not 0

	lda	MSELECTL
	xba

	bne     test_flags		; loop to test_flags if not zero

	beq	decompression_loop	; restart whole process

discrete_char:
	sep	#$20		; mem/A = 8 bit
.a8
	lda	[LOGOL]		; load byte from logo

	rep	#$20		; mem/A = 16 bit
.a16
	inc	LOGOL		; increment pointer

	ldx	#1		; want to write a single byte
	bne	store_byte	; go and store it (1 byte less than jmp)

done_logo:

	lda	OUTPUTL
	dec	A			; points one too far
	sec
	sbc	#.LOWORD(output)
	sta	OUTPUTL

	lda	#$0

	rep	#$10	; X/Y = 16 bit
.i16
	sep	#$20	; mem/A = 8 bit
.a8



convert_ansi_to_tiles:

	stz	offset
	ldy	#.LOWORD(tile_data2)
	sty	tile_offset

	ldx	#$0
	stx	logo_pointer		; offset

load_ansi_loop:

	ldx	logo_pointer

	; load from 24-bit long offset (since B is set to 7e)

	lda	output,x

	cmp	#27		; is it escape character?
	bne	not_escape

	;=================
	;== escape char ==
	;=================

	inx			; point past escape
	inx			; assume we have a [

new_color:
	stz	color

color_loop:
	lda	output,x	; load first byte of color

	inx
	cmp	#'m'
	beq	done_color

	cmp	#';'
	beq	done_color

	pha			; save read-in value

;	lda	color		; multiply existing color by 10
;	asl	color
;	asl	color
;	clc
;	adc	color
;	asl	A
;	sta	color

	asl	color		; instead of mul x 10
	asl	color		; mul x 16
	asl	color		; easier to parse if hex digits
	asl	color


	pla			; restore read-in value

	sec
	sbc	#$30		; convert ascii color to decimal

	clc
	adc	color		; have updated color
	sta	color		; store it

	jmp	color_loop

done_color:
	pha

	lda	color
	cmp	#0
	bne	not_zero
	stz	bold_color
	bra	done_set_color

not_zero:
	cmp	#1
	bne	not_one
	lda	#$8
	sta	bold_color

	bra	done_set_color
not_one:

	cmp	#$38
	bcs	background_color	; bge

foreground_color:
	and	#$7
	ora	bold_color
	sta	fore_color
	bra	done_set_color

background_color:
	and	#$7
	sta	back_color
done_set_color:

	pla

	cmp	#';'			; see if multiple color commands
	beq	new_color		; if so, handle next color

	stx	logo_pointer		; otherwise update pointer

	jmp	check_end		; and move to next char

not_escape:


test_hash:
	cmp	#'#'
	bne	test_O
	ldy	#$8
	bra	y_is_set
test_O:
	cmp	#'O'
	bne	its_zero
	ldy	#$10
	bra	y_is_set

its_zero:
	ldy	#$0

y_is_set:

	lda	#$1	; fx has the values 1,4,8 rather than
	sta	fx	; traditional 0,1,2 in a for loop.
			; this makes things easier later
fx_loop:

	stz	fy	; set fy to 0
fy_loop:		; we loop from 0 to 7
			; as our chars are 8 lines high

	lda	fy	; load fy into A
	asl		; multiply by two, as we do two planes at a time
	tax		; move into X

check_color:

	phx			; save X (offset) on stack
	tyx			; move Y (font pointer) into X
	lda	f:font,X	; long load of font value, as font is in ROM
	plx			; restore X (offset)
	iny			; increment font pointer

	bit	fx		; is xth bit of font set?

	beq	use_back_color	; if not, use background color

use_fore_color:
	lda	fore_color	; using foreground color
	bra	store_color

use_back_color:
	lda	back_color	; using background color

store_color:
	sta	temp_color	; store color to use to temp_color

plane_loop:			; plane loop is unrolled

	; plane 0

	asl	screen_byte,X	; screen_byte[0+(fy*2)]<<=1
	ror	temp_color	; rotate temp_color into carry
	lda	screen_byte,X	; get current color
	adc	#$0		; add in carry bit
	sta	screen_byte,X	; store back out

	; plane 1
	inx			; point to plane1

	asl	screen_byte,X	; screen_byte[1+(fy*2)]<<=1
	ror	temp_color	; rotate temp_color into carry
	lda	screen_byte,X	; get current color
	adc	#$0		; add in carry bit
	sta	screen_byte,X	; store back out


	; plane 2
	txa			; plane 2 is 15 bytes ahead of plane1 value
	clc
	adc	#15
	tax

	asl	screen_byte,X	; screen_byte[16+(fy*2)]<<=1
	ror	temp_color	; rotate temp_color into carry
	lda	screen_byte,X	; get current color
	adc	#$0		; add in carry bit
	sta	screen_byte,X	; store back out

	; plane 3
	inx

	asl	screen_byte,X	; screen_byte[17+(fy*2)]<<=1
	ror	temp_color	; rotate temp_color into carry
	lda	screen_byte,X	; get current color
	adc	#$0		; add in carry bit
	sta	screen_byte,X	; store back out

end_plane_loop:

	inc	fy		; move to next line

	lda	fy		; see if we've reached line 8 yet
	cmp	#$8
	bne	fy_loop		; if not, loop


	dey			; point Y back to beginning of font
	dey			; is this faster than subtract 8
	dey			; or loading a constant?
	dey
	dey
	dey
	dey
	dey

check_if_offset_is_mult_8:
	inc	offset		; every 8 horizontal points
	lda	offset		; we create a new tile
	cmp	#$8
	bne	no_write	; it not, skip

;=================================
; copy  screen_byte to tile memory
;=================================

copy_screen_byte_to_tile2:

	phy

	ldx	#.LOWORD(screen_byte)	; copy from screen_byte
	ldy	tile_offset		; to tile_offset
	lda	#31			; move 32 bytes
	mvn	$7e,$7e			; both in bank $7E

	sty	tile_offset		; save the updated tile_offset

	; fix top of A
	; if we don't do this B ends up FF and that messes up
	; things like TAX down the road

	lda	#$0
	xba

	ply

	stz	offset			; reset offset to 0

no_write:
done_fx:
	asl	fx			; shift fx left

	lda	fx			; if we reach 8 (3 bits) we are done
	cmp	#$8
	beq	next_char		; move onto the next char

	jmp	fx_loop			; otherwise loop on fx


next_char:
	ldx	logo_pointer		; increment the logo pointer
	inx
	stx	logo_pointer
check_end:
;	cpx	#$800
	cpx	OUTPUTL			; have we reached the end?
	bcs	done_convert		; if so, finish
	jmp	load_ansi_loop		; otherwise, loop

done_convert:


	rep	#$10	; X/Y = 16 bit
.i16
	sep	#$20	; mem/A = 8 bit
.a8

	lda     #0		; set data bank back to 0
	pha			;
	plb			;


;===============================================
;===============================================
; Display to the screen
;===============================================
;===============================================



	;==========================
	; Setup Background
	;==========================

        lda     #$04            ; BG1 Tilemap starts at VRAM 0400
	; 0000 0100
	; aaaa aass   a=0000 01 << 11 = 0800
	; ss = size of screen in tiles 00 = 32x32
        sta     $2107           ; bg1 src

	; 0000 0100
	; aaaa bbbb  a= BG2 tiles, b= BG1 tiles
	; bbbb<<13

	lda	#$04
        sta	$210b           ; bg1 tile data starts at VRAM 8000

	;==============
	; Load Palettes
	;==============
.a8
.i16
        stz     $2121           ; CGRAM color-generator read/write address

        ldy     #$0020          ; we only have 16 colors / 32 bytes

        ldx     #$0000          ; pointer
copypal:
        lda     tile_palette, x	; load byte of palette
        sta     $2122           ; store to color generator
        inx
        dey
        bne     copypal


	;=====================
	; Load Tile Data
	;=====================

	; replace with DMA!


	rep     #$20            ; set accumulator/mem to 16bit
.a16
.i16
	lda     #$4000          ;
        sta     $2116           ; set adddress for VRAM read/write
				; multiply by 2, so 0x8000

        ldy     #$1690          ; Copy 361 tiles, which are 32 bytes each
                                ;  8x8 tile with 4bpp (four bits per pixel)
				; in 2-byte chunks, so
				; (361*32)/2 = 5776 = 0x1690

        ldx     #$0000
copy_tile_data:
        lda     f:tile_data, x
        sta     $2118           ; write the data
        inx                     ; increment by 2 (16-bits)
        inx
        dey                     ; decrement counter
        bne     copy_tile_data


	;=====================
	; Load TB_FONT Data
	;=====================

	; replace with DMA!


	rep     #$20            ; set accumulator/mem to 16bit
.a16
.i16
	lda     #$6000          ;
        sta     $2116           ; set adddress for VRAM read/write
				; multiply by 2, so 0xc000

        ldy     #$600		; Copy 96 tiles, which are 32 bytes each
                                ;  8x8 tile with 4bpp (four bits per pixel)
				; in 2-byte chunks, so
				; (96*32)/2 = 1536 = 0x600

        ldx     #$0000
copy_font_data:
        lda     f:tb_font, x
        sta     $2118           ; write the data
        inx                     ; increment by 2 (16-bits)
        inx
        dey                     ; decrement counter
        bne     copy_font_data


	;===================================
	; clear background to linear tilemap
	;===================================
.a16
.i16

clear_linear_tilemap:

	lda	#$0400		; we set tilemap to be at VRAM 0x0400 earlier
	sta	$2116

        ldy     #$0000          ; clear counters
	ldx	#$ffff

				; store to VRAM
                                ; the bottom 8 bits is the tile to use
                                ; the top 8 bits is vhopppcc
                                ; vert flip, horiz flip o=priority
                                ; p = palette, c=top bits of tile#
	;
	; 0001 1000
	; vhop ppcc
	; so 1800 = v=0 h=0 o=0 ppp = 2
	;           c=0x0

.a16
.i16

fill_screen_loop:

	tya

        sta     $2118

	iny
	inx

	cpx	#30
	bne	no_skip

	lda	#$0
	sta	$2118
	sta	$2118

	ldx	#0

no_skip:

	cpy	#$0169			; 30x12 = 360 = 0x168

	bne     fill_screen_loop




        ; Write String to Background
put_string:

        lda     #$05a9          ; set VRAM address
                                ; 0400 = upper left (0,0)
                                ; 0420 =            (0,1)
                                ; 05a0 =            (0,13)
                                ; 05a9 =            (9,13)

        sta     $2116           ; set VRAM r/w address
                                ; 2116 = 05
                                ; 2117 = a9

        ldy     #$000d          ; length of string


        ldx     #$0000          ; string index

        lda     #$0200          ; clear A

copy_string:

        sep     #$20            ; set accumulator to 8 bit
                                ; as we only want to do an 8-bit load
.a8
        lda     hello_string, x       ; load string character
                                ; while leaving top 8-bits alone
        beq     done_copy_string

	sec
	sbc	#$20

        rep     #$20            ; set accumulator back to 16 bit
.a16
        sta     $2118           ; store to VRAM
                                ; the bottom 8 bits is the tile to use
                                ; the top 8 bits is vhopppcc
                                ; vert flip, horiz flip o=priority
                                ; p = palette, c=top bits of tile#

        inx                     ; increment string pointer

        bra     copy_string
done_copy_string:





setup_video:

        sep     #$20            ; set accumulator to 8 bit
                                ; as we only want to do an 8-bit load
.a8
.i16


	; Enable sprite
	; sssnnbbb
	; ss = size (8x8 in our case)
	; nn = name
	; bb = base selection, VRAM >> 14
;	lda	#%00000010	; point at 0x4000 in VRAM
;	sta	$2101

	; 000abcde
	; a = object, b=BG4 c=BG3 d=BG2 e=BG1
;	lda	#%00010001	; Enable BG1
	lda	#%00000001	; Enable BG1

	sta	$212c

	; disable subscreen
	stz	$212d

	; abcd efff
	; abcd = 8 (0) or 16 width for BG1234
	; e = priority for BG3
	; fff = background mode
	lda	#$01
	sta	$2105		; set Mode 1

	; a000 bbbb
	; a = screen on/off (0=on), ffff = brightness

	lda	#$0f
	sta	$2100		; Turn on screen, full Brightness


;	lda	#$81		; Enable NMI (VBlank Interrupt) and joypads
;	sta	$4200		;


main_loop:

	; repeat forever
	; stp?

	bra	main_loop


;============================================================================

wram_fill_byte:
.byte $00


;============================================================================
; Character Data
;============================================================================

color:
	.byte 0
bold_color:
	.byte 0
fore_color:
	.byte 0
back_color:
	.byte 0
temp_color:
	.byte 0

font:
	; bits 2,1,0
font_space:
	.byte	0,0,0,0,0,0,0,0   ; space
font_hash:
	.byte   $2,$2,$7,$2,$2,$7,$2,$2   ; #
font_o:
	.byte   $2,$5,$5,$5,$5,$5,$5,$2   ; O

.include "logo.lzss"

hello_string:
        .asciiz "HELLO,_WORLD!"

tile_palette:
        .word $0        ; 0 black    r=0 g=0 b=0
        .word $0        ; 1 d. red
        .word $0        ; 2 d. green
        .word $0        ; 3 d. yellow
        .word $0        ; 4 d. blue
        .word $0        ; 5 d. purple
        .word $0        ; 6 d. cyan
        .word $56b5     ; 7 l. grey  r=aa g=aa b=aa
        .word $3def     ; 8 d. grey  r=7d g=7d b=7d
        .word $3dff     ; 9 b. red   r=ff g=7d b=7d
	.word $0        ; 10 green
        .word $3ff      ; 11 yellow   r=ff g=ff b=0
	.word $0        ; 12 blue
	.word $0        ; 13 pink
	.word $0        ; 14 cyan
        .word $7fff     ; 15 white    r=ff g=ff b=ff

tb_font:
.include "tbfont.inc"

.segment "BSS"

fx:
.res 1
fy:
.res 1
offset:
.res 1
tile_offset:
.res 2
logo_pointer:
.res 2

screen_byte:
.res 8*4	; 8 bytes, times four

tile_data:
.res	32
tile_data2:
.res (30*12)*32

text_buf:	.res (N+F-1)

output:
.res 4096

.segment "CARTINFO"
        .byte   "LINUX_LOGO            "        ; Game Title
        .byte   $01                             ; 0x01:HiRom, 0x30:FastRom(3.57MHz)
        .byte   $05                             ; ROM Size (2KByte * N)
        .byte   $00                             ; RAM Size (8KByte * N)
        .word   $0001                           ; Developper ID ?
        .byte   $00                             ; Version
        .byte   $7f, $73, $80, $8c              ; Security Key ?
        .byte   $ff, $ff, $ff, $ff              ; Security Key ?

	; Interrupt Vectors!

        .word   $0000	; Native:COP
        .word   $0000	; Native:BRK
        .word   $0000	; Native:ABORT
        .word   $0000	; Native:NMI
        .word   $0000	;
        .word   $0000	; Native:IRQ

        .word   $0000   ;
        .word   $0000   ;

        .word   $0000   ; Emulation:COP
        .word   $0000   ;
        .word   $0000   ; Emulation:ABORT
        .word   $0000   ; Emulation:NMI
        .word   Reset   ; Emulation:RESET
        .word   $0000   ; Emulation:IRQ/BRK

