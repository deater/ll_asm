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
;   MVN,MVP  -- memory block move in negative/positive direction
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
ball_x = $0000

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
	;==============================================
	; DONE INITIALIZATION
	;==============================================
	;==============================================
	;==============================================

start_program:

	rep	#$10	; X/Y = 16 bit
	sep	#$20	; mem/A = 8 bit
.a8
.i16


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

        ldy     #$000c          ; we only have 6 colors / 12 bytes

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
        lda     tile_data2, x
        sta     $2118           ; write the data
        inx                     ; increment by 2 (16-bits)
        inx
        dey                     ; decrement counter
        bne     copy_tile_data


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
;put_string:

;        lda     #$05a9          ; set VRAM address
                                ; 0400 = upper left (0,0)
                                ; 0420 =            (0,1)
                                ; 05a0 =            (0,13)
                                ; 05a9 =            (9,13)

;        sta     $2116           ; set VRAM r/w address
                                ; 2116 = 05
                                ; 2117 = a9

;        ldy     #$000d          ; length of string


;        ldx     #$0000          ; string index

;        lda     #$0000          ; clear A

;copy_string:
;        txa                     ; put color in A and shift left by 10
;        asl
;        asl
;        asl
;        asl
;        asl
;        asl
;        asl
;        asl
;        asl
;        asl

;        sep     #$20            ; set accumulator to 8 bit
                                ; as we only want to do an 8-bit load
;.a8
;        lda     hello_string, x       ; load string character
                                ; while leaving top 8-bits alone
;        beq     done_copy_string

;        rep     #$20            ; set accumulator back to 16 bit
;.a16
;        sta     $2118           ; store to VRAM
                                ; the bottom 8 bits is the tile to use
                                ; the top 8 bits is vhopppcc
                                ; vert flip, horiz flip o=priority
                                ; p = palette, c=top bits of tile#

;        inx                     ; increment string pointer

;        bra     copy_string
;done_copy_string:





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


	lda	#$81		; Enable NMI (VBlank Interrupt) and joypads
	sta	$4200		;


main_loop:

	; all work done in interrupt handler

	; stp?

	bra	main_loop


;=============================
; VBLank Routine
;=============================

VBlank:
	rti		; return from interrupt


;============================================================================

wram_fill_byte:
.byte $00


;============================================================================
; Character Data
;============================================================================


; tile data

tile_data2:
        ; Planes 1 and 0
        .word $0000
        .word $0000
        .word $0000
        .word $0000
        .word $0000
        .word $0000
        .word $0000
        .word $0000
        ; Planes 3 and 2
        .word $0000
        .word $0000
        .word $0000
        .word $0000
        .word $0000
        .word $0000
        .word $0000
        .word $0000

.include "ll.tiles"

.include "ll.ans.inc"

hello_string:
        .asciiz "HELLO,_WORLD!"



.segment "BSS"
x_direction:	.word 0

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
        .word   VBlank	; Native:NMI
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

