; Hello World for SNES

; use the cc65 assembler
;   cl65 -t none -o hello_world.o -l hello_world.lst -c hello_world.s
;   ld65 -o hello_world.sfc --config hello_world.cfg --obj hello_world.o


; Page zero locations
ball_x = $0000

.setcpu "65816"

.segment "STARTUP"

Reset:
	; Setup All the Registers

        sei     ; disable interrupts
        clc     ; clear carry
        xce     ; and exchange with X to enable native mode

        phk     ; make data bank match program bank
        plb     ;


        rep     #$38    ; clear status bits, binary mode, A and IX/IY = 16
.i16                    ; tell assembler IX/IY=16bits
.a16
        ldx     #$1fff  ; set the stack pointer to be  0x1fff
        txs             ; move X to stack


	sep	#$20	; mem/A = 8 bit
.a8
        lda     #$8f    ; put 0x8f in accumulator
                        ; (screen off, full brightness)
        sta     $2100   ; store to brightness/screen reg

	stz     $2101   ; sprite register (size+address, VRAM)
	stz     $2102   ; sprite register (address in mem, OAM)
	stz     $2103   ; "
	stz     $2105   ; graphic mode register (mode 0)
	stz     $2106   ; mosaic register (noplanes, nomosaic)
	stz     $2107   ; plane 0 map VRAM location
	stz     $2108   ; plane 1 map VRAM location
	stz     $2109   ; plane 2 map VRAM location
	stz     $210a   ; plane 3 map VRAM location
	stz     $210b   ; plane 0+1 tile location
	stz     $210c   ; plane 2+3 tile location

	stz     $210d   ; Plane 0 scroll x (first 8 bits)
	stz     $210d   ; Plane 0 scroll x (last 3 bits) #$0 - #$07ff
	stz     $210e   ; Plane 0 scroll y (first 8 bits)
	stz     $210e   ; Plane 0 scroll y (last 3 bits) #$0 - #$07ff
	stz     $210f   ; Plane 1 scroll x (first 8 bits)
	stz     $210f   ; Plane 1 scroll x (last 3 bits) #$0 - #$07ff
	stz     $2110   ; Plane 1 scroll y (first 8 bits)
	stz     $2110   ; Plane 1 scroll y (last 3 bits) #$0 - #$07ff
	stz     $2111   ; Plane 2 scroll x (first 8 bits)
	stz     $2111   ; Plane 2 scroll x (last 3 bits) #$0 - #$07ff
	stz     $2112   ; Plane 2 scroll y (first 8 bits)
	stz     $2112   ; Plane 2 scroll y (last 3 bits) #$0 - #$07ff
	stz     $2113   ; Plane 3 scroll x (first 8 bits)
	stz     $2113   ; Plane 3 scroll x (last 3 bits) #$0 - #$07ff
	stz     $2114   ; Plane 3 scroll y (first 8 bits)
	stz     $2114   ; Plane 3 scroll y (last 3 bits) #$0 - #$07ff

        lda     #$80    ; increase VRAM address after writing to $2119
        sta     $2115   ; VRAM address increment register
        stz     $2116   ; VRAM address low
        stz     $2117   ; VRAM address high
        stz     $211a   ; Initial Mode 7 setting register
        stz     $211b   ; Mode 7 matrix parameter A register (low)

        lda     #$01
        sta     $211b   ; Mode 7 matrix parameter A register (high)
        stz     $211c   ; Mode 7 matrix parameter B register (low)
        stz     $211c   ; Mode 7 matrix parameter B register (high)
        stz     $211d   ; Mode 7 matrix parameter C register (low)
        stz     $211d   ; Mode 7 matrix parameter C register (high)
        stz     $211e   ; Mode 7 matrix parameter D register (low)
        stz     $211e   ; Mode 7 matrix parameter D register (high)
        stz     $211f   ; Mode 7 center position X register (low)
        stz     $211f   ; Mode 7 center position X register (high)
        stz     $2120   ; Mode 7 center position Y register (low)
        stz     $2120   ; Mode 7 center position Y register (high)

        stz     $2121   ; color # register
        stz     $2123   ; bg1 & bg2 window mask reg
        stz     $2124   ; bg3 & bg4 window mask reg
        stz     $2125   ; obj & color mask reg
        stz     $2126   ; window 1 left pos
        stz     $2127   ; window 2 left pos
        stz     $2128   ; window 3 left pos
        stz     $2129   ; window 4 left pos
        stz     $212a   ; bg1,2,3,4 window logic reg
        stz     $212b   ; obj color win logic reg (or, and, xor, nor)

        lda     #$01    ;
        sta     $212c   ; main screen desig (plane, sprite enable)
        stz     $212d   ; sub screen desig
        stz     $212e   ; window mask main screen
        stz     $212f   ; window mask sub screen
        lda     #$30    ;
        sta     $2130   ; color addition and screen addition
        stz     $2131   ; add/sub desig for screen/sprite/color
        lda     #$e0    ;
        sta     $2132   ; color data for add/sub
        stz     $2133   ; screen setting (interlace, x,y enable,  SFX data)


			; $2134-$2136  - multiplication result, no initialization needed
			; $2137 - software H/V latch, no initialization needed
			; $2138 - Sprite data read, no initialization needed
			; $2139-$213A  - VRAM data read, no initialization needed
			; $213B - Color RAM data read, no initialization needed
			; $213C-$213D  - H/V latched data read, no initialization needed

	stz	$213E	; $213E - might not be necesary, but selects PPU master/slave mode
			; $213F - PPU status flag, no initialization needed
			; $2140-$2143 - APU communication regs, no initialization required

			; $2180  -  read/write WRAM register, no initialization required
			; $2181-$2183  -  WRAM address, no initialization required

			; $4016-$4017  - serial JoyPad read registers, no need to initialize

        stz     $4200   ; disable timers, v-blank interrupt, joypad register

        lda     #$ff    ;
        sta     $4201   ; programmable i/o port
;       stz     $4202   ; multiplicand A
;       stz     $4203   ; multiplier B
;       stz     $4204   ; multiplier C
;       stz     $4205   ; multiplicand C
;       stz     $4206   ; Divisor B
        stz     $4207   ; Horizontal Count Timer
        stz     $4208   ; Horizontal Count MSB
        stz     $4209   ; Vertical Count Timer
        stz     $420a   ; Vertical Count MSB
        stz     $420b   ; General DMA enable
        stz     $420c   ; Horizontal DMA enable
        stz     $420d   ; Access cycle designation (slow/fast ROM)
	lda	$4210	; $4210  - NMI status, reading resets

			; $4211  - IRQ status, no need to initialize
			; $4212  - H/V blank and JoyRead status, no need to initialize
			; $4213  - programmable I/O inport, no need to initialize

			; $4214-$4215  - divide results, no need to initialize
			; $4216-$4217  - multiplication or remainder results, no need to initialize

			; $4218-$421f  - JoyPad read registers, no need to initialize

			; $4300-$437F
			; no need to intialize because DMA was disabled above
			; also, we're not sure what all of the registers do, so it is better to leave them at
			; their reset state value

ClearVRAM:
	pha
	phx
	php

	rep	#$30	; mem/A = 8 bit, X/Y = 16 bit
	sep	#$20
.a8
	lda	#$80
	sta	$2115	; Set VRAM port to word access
	ldx	#$1809
	stx	$4300	; Set DMA mode to fixed source, WORD to $2118/9
	ldx	#$0000
	stx	$2116	; Set VRAM port address to $0000
	stx	$0000   ; Set $00:0000 to $0000 (assumes scratchpad ram)
	stx	$4302   ; Set source address to $xx:0000
	lda	#$00
	sta	$4304	; Set source bank to $00
	ldx	#$FFFF
	stx	$4305	; Set transfer size to 64k-1 bytes
	lda	#$01
	sta	$420B	; Initiate transfer

	stz	$2119	; clear the last byte of the VRAM

	plp
	plx
	pla

ClearPalette:
	phx
	php
	rep	#$30		; mem/A = 8 bit, X/Y = 16 bit
	sep	#$20
.a8
	stz	$2121
	ldx	#$0100
ClearPaletteLoop:
	stz	$2122
	stz	$2122
	dex
	bne	ClearPaletteLoop

	plp
 	plx

	;=================================
	;**** clear Sprite tables ********
	;=================================

	stz	$2102	;sprites initialized to be off the screen, palette 0, character 0
	stz	$2103
	ldx	#$0080
	lda	#$F0
_Loop08:
	sta	$2104	;set X = 240
	sta	$2104	;set Y = 240
	stz	$2104	;set character = $00
	stz	$2104	;set priority=0, no flips
	dex
	bne	_Loop08

	ldx	#$0020
_Loop09:
	stz	$2104		;set size bit=0, x MSB = 0
	dex
	bne	_Loop09

	;=====================
	;**** clear WRAM *****
	;=====================
	stz	$2181		;set WRAM address to $000000
	stz	$2182
	stz	$2183

	ldx	#$8008
	stx	$4300         ;Set DMA mode to fixed source, BYTE to $2180
	ldx	#wram_fill_byte
	stx	$4302         ;Set source offset
	lda	#^wram_fill_byte
	sta	$4304         ;Set source bank
	ldx	#$0000
	stx	$4305         ;Set transfer size to 64k bytes
	lda	#$01
	sta	$420B         ;Initiate transfer

	lda	#$01          ;now set the next 64k bytes
	sta	$420B         ;Initiate transfer


	;================================
	; Get Ready to Go
	;================================

	phk			;make sure Data Bank = Program Bank
	plb

	cli			;enable interrupts again


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
        ldy     #$0200          ; counter, 512 bytes
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

	rep     #$20            ; set accumulator/mem to 16bit
.a16
.i16
	lda     #$4000          ;
        sta     $2116           ; set adddress for VRAM read/write
				; multiply by 2, so 0x8000

        ldy     #$2000          ; Copy 512 tiles, which are 32bytes each
                                ;  8x8 tile with 4bpp (four bits per pixel)
				; in 2-byte chunks, so
				; (512*32)/2 = 8192 = 0x2000

        ldx     #$0000
copy_tile_data:
        lda     tile_data, x
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
	ldx	#$0000

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
	sta	$2118
	sta	$2118
	ldx	#0

no_skip:

	cpy	#$0400			; 32x32 = 1024

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






	;==========================
	; Setup Sprite
	;==========================

        sep     #$20            ; set accumulator to 8 bit
                                ; as we only want to do an 8-bit load
.a8
.i16


	; Load Palette for our sprite

	; Sprite Palettes start at color 128

;	lda	#128
;	sta	$2121       		; Start at START color
;	lda	#^sprite_palette        ; Using ^ before the parameter gets its bank.
;	ldx	#sprite_palette         ;
;	ldy	#(16 * 2)   		; 2 bytes for every color

	; In: A:X  -- points to the data
	;      Y   -- Size of data

;	pha
;	phx
;	phb
;	php         ; Preserve Registers

;	sep	#$20

;	stx	$4302   ; Store data offset into DMA source offset
;	sta	$4304   ; Store data bank into DMA source bank
;	sty	$4305   ; Store size of data block

;	stz	$4300   ; Set DMA Mode (byte, normal increment)
;	lda	#$22    ; Set destination register ($2122 - CGRAM Write)
;	sta	$4301
;	lda	#$01    ; Initiate DMA transfer
;	sta	$420B

;	plp         ; Restore registers
;	plb
;	plx
;	pla

	; Load sprite data to VRAM
;	lda	#$80
;	sta	$2115
;	ldx	#$4000		; DEST (VRAM 4000)
;	stx	$2116		; $2116: Word address for accessing VRAM.
;	lda	#^sprite_data	; SRCBANK
;	ldx	#sprite_data	; SRCOFFSET
;	ldy	#$0100		; SIZE

	; In: A:X  -- points to the data
	;     Y     -- Number of bytes to copy (0 to 65535)  (assumes 16-bit index)

;	phb
;	php         ; Preserve Registers

;	sep	#$20

;	stx	$4302   ; Store Data offset into DMA source offset
;	sta	$4304   ; Store data Bank into DMA source bank
;	sty	$4305   ; Store size of data block

;	lda	#$01
;	sta	$4300   ; Set DMA mode (word, normal increment)
;	lda	#$18    ; Set the destination register (VRAM write register)
;	sta	$4301
;	lda	#$01    ; Initiate DMA transfer (channel 1)
;	sta	$420B

;	plp         ; restore registers
;	plb

; Init all sprites to be offscreen
;SpriteInit:
;	php

;	rep	#$30	;16bit mem/A, 16 bit X/Y
;.a16
;	ldx #$0000
;	lda #$0001
;_setoffscr:
;	sta $0000,X
;	inx
;	inx
;	inx
;	inx
;	cpx #$0200
;	bne _setoffscr
;
;	ldx #$0000
;	lda #$5555
;_clr:
;	sta $0200, X		;initialize all sprites to be off the screen
;	inx
;	inx
;	cpx #$0020
;	bne _clr

;	plp

;	sep	#$20

;.a8
;	lda #($0)
;	sta $0000

;	lda #(224/2 - 16)
;	sta $0001

;	stz $0002
;	lda #%01110000
;	sta $0003

;    lda #%11000000
;    sta $0100

;	lda #%01010100
;	sta $0200

transfer_sprites:
;	rep #$10
;	sep #$20

	;=============================
	;*********transfer sprite data
	;=============================

;	stz	$2102		; set OAM address to 0
;	stz	$2103

;	ldy	#$0400
;	sty	$4300		; CPU -> PPU, auto increment, write 1 reg, $2104 (OAM Write)
;	stz	$4302
;	stz	$4303		; source offset
;	ldy	#$0220
;	sty	$4305		; number of bytes to transfer
;	lda	#$7E
;	sta	$4304		; bank address = $7E  (work RAM)
;	lda	#$01
;	sta	$420B		; start DMA transfer

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

	bra	main_loop


;=============================
; VBLank Routine
;  All the action happens here
;=============================

VBlank:
	rti

	php		; save status register
	rep	#$30	; Set A/mem=16 bits, X/Y=16 bits (to push all 16 bits)
.a16			; tell assembler the A is 16-bits
	phb		; save b
	pha		; save A
	phx		; save X
	phy		; save Y
	phd		; save zero page

	sep #$20        ; A/mem=8 bit
.a8

joypad_read:
	lda	$4212		; get joypad status
	and #%00000001		; if joy is not ready
	bne joypad_read		; wait

	lda	$4219		; read joypad (BYSTudlr)

	and	#%11110000  	; see if a button pressed

	bne	done_vblank	; if so, skip and don't move ball

done_joypad:

	lda	#^x_direction	; get bank for x_direction var (probably $7E)
	pha			;
	plb			; set the data bank to the one containing x_direction

	lda	ball_x		; get current ball X value
				; in the zero page, which is mirrored on SNES

	ldx	x_direction	; get x_direction  0=right, 1=left
	bne	ball_left	; if 1 skip ahead to handle going left

	ina			; ball_x += 2
	ina

	cmp	#248		; have we reached right side?

	bne	done_moving	; if not, keep moving right

	ldx	#1		; if so, switch to moving left
	bra	done_moving

ball_left:
	dea			; ball_x -= 2
	dea
	bne	done_moving	; if not at zero, keep moving left

	ldx	#0		; hit wall, switchto moving right

done_moving:
	sta	ball_x		; save ball_x co-ord
	stx	x_direction	; save x_direction


	;=======================================
	; Update the sprite info structure (OAM)
	;=======================================
.a8

	lda	#$0		; set data bank back to 0
	pha
	plb

	; Setup DMA transfer to copy our OAM structure in the zero page
	; into the actual OAM

	stz	$2102		; set OAM address to 0
	stz	$2103

	ldy	#$0400
	sty	$4300		; CPU -> PPU, auto increment, write 1 reg, $2104 (OAM Write)
	stz	$4302
	stz	$4303		; source offset
	ldy	#$0220
	sty	$4305		; number of bytes to transfer
	lda	#$7E
	sta	$4304		; bank address = $7E  (work RAM)
	lda	#$01
	sta	$420B		;start DMA transfer


done_vblank:

	lda	$4210	; Clear NMI flag

	rep	#$30	; A/Mem=16 bits, X/Y=16 bits
.a16
	pld		; restore saved vaules from stack
	ply
	plx
	pla
	plb

	sep #$20
	plp
	rti		; return from interrupt


;============================================================================

wram_fill_byte:
.byte $00


;============================================================================
; Character Data
;============================================================================


; tile data
.include "ll.tiles"

hello_string:
        .asciiz "HELLO,_WORLD!"



.segment "BSS"
x_direction:	.word 0

.segment "CARTINFO"
        .byte   "SAMPLE1               "        ; Game Title
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

