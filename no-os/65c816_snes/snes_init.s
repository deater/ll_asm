init_snes:
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


