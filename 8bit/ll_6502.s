;
;  ll_6502.s  -- Linux Logo in 6502 Assembly for the Apple II v0.31
;
;		by Vince Weaver  <vince _at_ deater.net>
;
;     decompresses the same lzss data as the Linux versions
;     but displays it to the high-res Apple II screen
;
;     Also prints some rough system info for Apple II class
;     computers, though not for the IIgs


.define EQU =

;; Standard zero page allocations that we use

CH      EQU $24
CV      EQU $25
BASL    EQU $28
BASH    EQU $29


;; Our Zero Page Allocations

;; for the LZSS part of the code

LOGOH     EQU $FF
LOGOL     EQU $FE
OUTPUTH   EQU $FD
OUTPUTL   EQU $FC
STORERH   EQU $FB
STORERL   EQU $FA
LOADRH    EQU $F9
LOADRL    EQU $F8
EFFECTRH  EQU $F7
EFFECTRL  EQU $F6
MSELECT   EQU $F5
COUNT     EQU $F4
OUT_COUNT EQU $F3

;; for the graphics code

QUOTIENT  EQU $FF
REMAINDER EQU $FE
;; FD is OUTPUTH
;; FC is OUTPUTL
DIVISORH  EQU $FB
DIVISORL  EQU $FA
DIVIDENDH EQU $F9
DIVIDENDL EQU $F8
YADDRH    EQU $F7
YADDRL    EQU $F6
APPLEY    EQU $F5
;; F4 is COUNT
COLOR     EQU $F3
APPLEXH   EQU $F2
APPLEXL   EQU $F1
MASK      EQU $F0
BLOCK     EQU $EF
OUTH      EQU $EE
OUTL      EQU $ED
HGRPNTH   EQU $EC
HGRPNTL   EQU $EB

;; for the sysinfo code
STRCATH   EQU $F9
STRCATL   EQU $F8
RAMSIZE   EQU $F7
NUM2      EQU $F3
NUM1      EQU $F2
NUM0      EQU $F1
TYPE      EQU $F0
CPU       EQU $EF


;; 
OUTPUT	  EQU $4000	     	       ;; hgr page2, should be unused

;; VECTORS
BASIC 	 EQU $3D0		       ;; VECTOR for return to Applesoft
KEYPRESS EQU $C000
KEYRESET EQU $C010


;; SOFT SWITCHES
GR      EQU $C050
TEXT    EQU $C051
FULLGR  EQU $C052
TEXTGR  EQU $C053
PAGE0   EQU $C054
PAGE1   EQU $C055
LORES   EQU $C056
HIRES   EQU $C057

;; MONITOR ROUTINES
PRBL2	EQU $F94A		       ;; Print Blanks monitor routine
BASCALC	EQU $FBC1
HOME    EQU $FC58		       ;; Clear the text screen
SETNORM EQU $FE84		       ;; NORMAL
COUT1   EQU $FDF0		       ;; output A to screen
CROUT    EQU $FD8E		       ;; char out monitor routine

;; LZSS Parameters

N  	      EQU 1024
F     	      EQU 64
THRESHOLD     EQU 2
P_BITS	      EQU 10
POSITION_MASK EQU 3


;==========================================================
; MAIN()
;==========================================================

        ; save zero page
	; otherwise we can't return to BASIC
	
	ldx	#$e8   	     	       	 ; we save $E8-$F8
	ldy	#0
	lda	#>zp_save
	sta	OUTPUTH
	lda	#<zp_save
	sta	OUTPUTL
save_zp_loop:
	lda	0,X
	sta	(OUTPUTL),Y
	inx
	iny
	cpy	#$10			; save 16 bytes
	bne	save_zp_loop

  ;==========================
  ; set graphics mode, page 0
  ;==========================
	cld				; make sure doing binary adds
					; not decimal	
	jsr     HOME
	sta	GR
	sta	HIRES			; hires mode
	sta	TEXTGR			; mixed text/graphics
	sta	PAGE0			; first graphics page

	jsr	clear_screen		; clear the screen
	
	lda	#>LOGO			; load logo pointer
	sta	LOGOH
	lda     #<LOGO
	sta	LOGOL

	jsr	reset_output		; load output pointer
					    
	lda	#>(N-F)			; load R value
	sta	STORERH
	lda	#<(N-F)
	sta	STORERL 
							         
	ldy	#0			; setup Y for indirect zero page
					; addressing, we always want +0

decompression_loop:   
   
   	lda	#8                  	; set mask counter
	sta	COUNT
           
	lda	(LOGOL),Y		; load byte
	      
	sta	MSELECT			; store it
		    
	ldx	#LOGOL
	jsr	inc16 			; increment pointer
		     
test_flags:

	lda	LOGOH			; compare to see if we've reached end
	cmp	#>LOGO_END
	bcc	not_match

	lda	LOGOL
	cmp	#<LOGO_END
        bcc	not_match
		        
	jmp	done_logo 		; if so, we are done
			   
not_match:			   
        lsr	MSELECT		   	; shift byte mask into carry flag
     
        bcs	discrete_char		; if set we have discrete char
	
offset_length:   
	lda	(LOGOL),Y               ; load byte
      
        ldx	#LOGOL                  ; 16-bit increrment
	jsr	inc16
	       
	sta	LOADRL			; bottom of R offset
		     
	lda	(LOGOL),Y               ; load another byte
			
	ldx	#LOGOL                  ; 16 bit increment
	jsr	inc16
			         
	sta	LOADRH			; top of R offset
				       
	lsr	A
	lsr	A			; shift right by 10 (top byte by 2)
	
   	clc
	adc	#3			; add threshold+1 (3)
        sta	OUT_COUNT		; store to OUT_COUNT
	 
output_loop:

	clc 				; calculate R+LOADR
	lda	LOADRL
	adc	#<R
	sta	EFFECTRL
		        
	lda	LOADRH
	and	#((N-1)>>8)		; Mask so mod N
        sta	LOADRH
	
	adc	#>R
	sta	EFFECTRH
				          
        lda	(EFFECTRL),Y		; Load byte R[LOADR]
  
        ldx	#LOADRL			; 16 bit increment
	jsr	inc16

store_byte:   

	sta     (OUTPUTL),Y		 ; store byte to output

        jsr	inc_pointer

	pha	     			 ; calculate R+STORER
	clc
        lda	STORERL
	adc	#<R
	sta	EFFECTRL
			         
	lda	STORERH
	and	#((N-1)>>8)		 ; mask so mod N
				          
	sta	STORERH
	adc	#>R
	sta	EFFECTRH
						
	pla				 ; restore from stack
	
	sta	(EFFECTRL),Y		 ; store A there too
	   
      	ldx	#STORERL		 ; 16 bit increment
        jsr	inc16
	    
	dec	OUT_COUNT		 ; count down the out counter
	bne	output_loop		 ; loop to output_loop if not 0
		     
	dec	COUNT			 ; count down the mask counter
	bne	test_flags		 ; loop to test_flags if not zero
			      
	jmp	decompression_loop	 ; restart whole process
				 
discrete_char:	
	lda	(LOGOL),Y		 ; load byte
		   		      
        ldx	#LOGOL			 ; 16-bit increment
	jsr	inc16

	ldx	#1   			 ; want to write a single byte
	stx	OUT_COUNT
      
        jmp	store_byte		 ; go and store it
	    
	    
done_logo:

	;==========================
	; print ANSI to HGR display
	;==========================
	
	tya			       	 ; get zero from Y 
	sta	(OUTPUTL),Y	         ; make sure we are null terminated

	jsr	reset_output		 ; restore OUTPUT pointer
					 ; now as input
		      
	sty	COUNT  		    	 ; set count to zero
	sty	COLOR			 ; set color to zero
			       
	lda	#64			 ; start Y at 64 (partway down screen)
	sta	APPLEY
				     
	sty	APPLEXH			 ; set X to 20 (centered)
	lda	#20			 ; X can be up to 280, so 16-bit val
        sta	APPLEXL
					         
        jsr	y_to_addr		 ; convert Y value to an address
						       
rle_loop:
	lda	(OUTPUTL),Y		 ; load a byte
      	beq	rle_done		 ; if zero, we are done
             
	cmp	#27			 ; are we escape?
	bne	not_escape
		      
escape:
	ldx	COUNT			 ; don't display if COUNT==0
	beq	dont_output
	
	jsr	flush_line 		 ; we finished a color, display it
					 ; flush_line should set COUNT to 0
dont_output:   
	jsr     inc_pointer		 ; point after escape
      
        lda	(OUTPUTL),Y		 ; load next byte (should be [ )
	          
find_m:   
	cmp	#$6D			 ; looking for 'm'
      	beq	found_m
      
        cmp	#$33   			 ; now looking for '3'
	bne	not_three
	    
	jsr	inc_pointer
	
	; if we have 3, the next number after is our color
	; (these are ANSI escape codes)
	; convert to apple HGR colors
	
	lda	(OUTPUTL),Y		 ; load ascii number
	and	#7                	 ; mask	        
        asl	A
	cmp	#8
	bmi	ok			 ; make sure red, yellow map to orange
   	lsr	A
ok:		 			 ; I'm out of meaningful label names!
        and	#3
        sta	COLOR			 ; save our computed color
	          
not_three:   
	jsr  	inc_pointer
      	lda	(OUTPUTL),Y
        jmp	find_m	   		 ; loop until we find a 'm'
	
found_m:   
	jsr	inc_pointer		 ; done with escape
	jmp	rle_loop		 ; rejoin main loop
	          
not_escape:   
	cmp   	#10			 ; check for linefeed
        bne	not_linefeed
			   
linefeed:   
	jsr 	flush_line		 ; if linefeed, flush line
					 ; flush_line should set count to 0

        jsr	inc_pointer

	sty	APPLEXH	   		 ; reset APPLEX to 20
	lda	#20
	sta	APPLEXL
					     
	clc	       			 ; increment Y by 8 (we are doing
	lda	APPLEY			 ;  8-pixel high blocks)
	adc	#8
	sta	APPLEY
	jsr	y_to_addr
		          
	jmp rle_loop	 		 ; loop
			        
not_linefeed:   
	inc	COUNT			 ; normal case.  we increment run by 3
	inc	COUNT			 ; because 80*3 fits on 280 wide screen
	inc	COUNT
					      
	jsr	inc_pointer
						       
	jmp	rle_loop   		 ; loop
							  
rle_done:   

	;=================================
	; print the system info
	;=================================

	ldy 	#0			; be sure Y is zero

	sty	CH			; set HTAB to 0
	lda	#20			; set VTAB to 20 (visible under
	sta	CV			;                 the graphics)
	jsr	BASCALC			; update output pointers

	jsr 	get_sysinfo		; get some system info
   
        ; print version info
         
	jsr 	reset_output
	lda	#>VERSION
	sta	STRCATH
	lda	#<VERSION
	sta	STRCATL
	jsr	strcat 			; concatenate version info
	
	jsr	center_and_print	; print it to screen
			
	; print middle line
	
	jsr	reset_output		; reset output pointer
	
	lda	#>ONE			; point to the "One 1.02MHz" line
	sta	STRCATH
	lda	#<ONE
	sta	STRCATL
	jsr	strcat 			; concatenate it
					       
	lda	CPU			; what kind of CPU do we have?
	bne	cmos
nmos:
	lda	#>NMOS			; we have 6502 CPU, so print that
	sta	STRCATH
	lda	#<NMOS
	sta	STRCATL
	jmp	done_cpu

cmos:
    	lda	#>CMOS			; we have 65C02 CPU, so print that
	sta	STRCATH
	lda	#<CMOS
	sta    	STRCATL

done_cpu:
	jsr	strcat
	
	lda	#>PROCESSOR		; add Processor string
	sta	STRCATH
	lda	#<PROCESSOR
	sta    	STRCATL
	jsr	strcat
			      
	jsr	num_to_ascii		; add the amount of RAM

	lda	#>RAM			; add the RAM related string
	sta	STRCATH
	lda	#<RAM
	sta	STRCATL
	jsr	strcat
    
	jsr	center_and_print	; center and print

        ; print last line
	     
	jsr    	reset_output		; reset output pointer
	
	lda	#>APPLE			; print Apple II
	sta	STRCATH
	lda	#<APPLE
	sta    	STRCATL
	jsr	strcat
			    
	lda	TYPE  			; add type to the end
	sta	(OUTPUTL),Y
        jsr	inc_pointer
	tya
	sta	(OUTPUTL),Y
	       
	jsr	center_and_print	; center and print

	jsr	wait_until_keypressed	; wait until a key is pressed


;==========================================================
; EXIT back to BASIC
;==========================================================

exit:
        ; restore zero page
	
	ldx	#$e8   	   		; restore $e8-$f8
	ldy	#$0
	lda	#>zp_save
	sta	OUTPUTH
	lda	#<zp_save
	sta	OUTPUTL	
restore_zp_loop:
	lda	(OUTPUTL),Y
	sta	0,X
	inx
	iny
	cpy	#$10
	bne	restore_zp_loop

     	jmp 	BASIC		       ; return to BASIC


;==========================================================
; Wait until keypressed
;==========================================================
;
	        
wait_until_keypressed:
        lda     KEYPRESS                 ; check if keypressed
	bpl     wait_until_keypressed    ; if not, loop
	rts
		
;==================================================
; inc16 - increments a 16-bit pointer in zero page 
;==================================================

inc16:
        inc     0,X                	 ; increment address
	bne     no_carry
	inx
	inc     0,X			 ; handle overflow
no_carry: 
	rts
	       
;==================================================
; y_to_addr - convert y value to address in mem
;==================================================
; this is needlessly complicated.  Blame Steve Wozniak
; apparently it was a clever hack to avoid the need
; for dedicated memory refresh circuitry

y_to_addr:
	lda	APPLEY
	and	#$7  			 ; y%8
        asl	A			 ; *1024 (by saving to high bit free
	asl	A			 ;        multiply by 256)
	
	clc
	adc	#$20			 ; add 0x2000 which is where HGR starts
	sta	YADDRH
	sty	YADDRL
			
less_than_64:
	lda  	APPLEY
	cmp	#64
	bcs	less_than_128
        ldx	#0
	jmp	ready_to_add
					  
less_than_128:
	cmp     #128
	bcs	more_than_128
	ldx	#$28
	sec	     			 ; on 6502 carry must be 1 to subtract
	sbc     #64			 ; subtract down
	jmp	ready_to_add
	
more_than_128:
	ldx     #$50
	sec
        sbc	#128
		    
ready_to_add:   
	lsr	A			 ; divide by 8
	lsr	A			 ; this also maskes off low bits
	lsr	A			 ; so we can't combine with below
				   
	lsr	A			 ; this shift puts us to lower half
					 ; of 16-bit value, so have to check
					 ; and handle the underflow
					 ; low bit is put into the C bit
	bcc	no_bottom_add
					      
	pha		     		 ; save accumulator
	clc				 ; shifted out C to bottom byte
        lda     YADDRL
	adc	#$80
	sta	YADDRL
       	pla	      			 ; restore A from stack
		         
no_bottom_add:
	adc     YADDRH			 ; update top half of address
	sta	YADDRH
			       
	clc
	txa				 ; add in X which we picked earlier
	adc	YADDRL			 ; we shifted by 0x80, 
					 ; and max X can be is 0x50
					 ; so shouldn't ever carry
	sta	YADDRL
		
	rts

;============================================
; inc_pointer - increments the output pointer
;============================================

inc_pointer:
	inc     OUTPUTL			 ; increment address
        bne	no_carry2
        inc	OUTPUTH	 		 ; handle overflow
no_carry2:
	rts
	   
;===================================================
; flush_line - flush out an RLE pair to graphics mem
;===================================================

flush_line:
        lda	COUNT			 ; repeat until COUNT=0
      	beq	end_flush
         
	jsr	hplot	 		 ; plot a point
	       
	ldx	#APPLEXL
	jsr	inc16			 ; increment 16-bit count
				    
	dec	COUNT
	jmp	flush_line
					  
end_flush:
	rts

;===========================================
; hplot - plot a pixel to the screen
;===========================================

hplot:
        lda	APPLEXH			 ; prepare to divide by 7
      	sta	DIVIDENDH		 ; again, thanks Woz
        lda	APPLEXL
	sta	DIVIDENDL
	       
	jsr	div7
		        
	lda	#1  			 ; load a 1
        ldx	REMAINDER		 ; and shift it by X%7

make_mask:
	beq	done_mask
	asl	A
	dex
	jmp make_mask
					  
done_mask:
	sta	MASK			; mask saved
	
	lda	YADDRH			; copy yaddr into our hgr pointer
	sta	HGRPNTH
	lda	YADDRL
	sta	HGRPNTL
		       
	clc
        adc	QUOTIENT		; add x/7 to out mem pointer
	sta	HGRPNTL
	lda	HGRPNTH
        adc	#0
	sta	HGRPNTH
					 
	lda	(HGRPNTL),Y		; get our 7 bits of interest
	sta	BLOCK			; store for later
					          
	lda	#1			; see if out X value is even or odd
	bit	APPLEXL
	beq	even
							   
odd:
    	lda	#2			; load odd mask
	bit	COLOR			; see if our color has this bit set
        bne	set_bit			; if so, set it
	jmp	clear_bit		; otherwise, clear it
	    
even:
	lda	#1			; load even mask
	bit	COLOR			; see if our color has this bit set
        beq	clear_bit		; if not, clear it
					; if so, fall through
set_bit:   
	lda	MASK			; set the bit
	ora	BLOCK
	jmp	done_pset

clear_bit:
	lda	MASK			; clear the bit
	eor	#$FF			; invert the bits
	and	BLOCK			; and with inverse to clear
						      
done_pset:   
	ora	#$80			; force blue/orange palette
      	sta	BLOCK			; write out block
      
        ldx	#8   			; we want to make it 8 pixels high
make_blocky:
	sta 	(HGRPNTL),Y		; store to video mem
	
	pha				; save on stack
	clc
	lda	HGRPNTH			; add 4 to high byte, equiv to
	adc	#$04			; adding 1k to address. 
	sta	HGRPNTH			; the lines are 1k apart in mem
      	pla				; restore block
         
	dex				; decrement counter
	bne make_blocky			; repeat until done
	rts

;=========================================
; div7 - divide by 7
;=========================================
; this is all the fault of 7400 series logic
; and the NTSC standard

div7:
        sty	QUOTIENT		 ; clear quotient
	
        lda	#1
	sta	DIVISORH
	lda	#$C0
	sta	DIVISORL		 ; set DIVISOR to 7<<6
			      
div7_loop:
	asl	QUOTIENT
	
	lda	DIVIDENDH
	cmp	DIVISORH
        bcc	less_than
        bne	subtract
		        
	lda	DIVIDENDL
	cmp	DIVISORL
	bcc	less_than
				    
subtract:
        sec
        lda	DIVIDENDL
	sbc	DIVISORL
	sta	DIVIDENDL
				          
	lda	DIVIDENDH
	sbc	DIVISORH
	sta	DIVIDENDH
							    
	lda	QUOTIENT
        ora	#1
	sta	QUOTIENT
		  
less_than:
	clc
	ror	DIVISORH
	ror	DIVISORL		 ; carry should make this 16 bit
	lda	DIVISORL
        cmp	#3    
	bne	div7_loop
		     
	lda	DIVIDENDL		 ; set remainder
	sta	REMAINDER

	rts

;=======================================
; clear_screen - clear the hi-res screen
;=======================================
clear_screen:
	lda     #$20
	sta	OUTPUTH
	lda	#$0
	sta	OUTPUTL
	ldy	#0
clear_screen_loop:
	lda	#$00
	sta	(OUTPUTL),Y
	clc

	jsr	inc_pointer

	lda	OUTPUTH
	cmp	#$40
	bne	clear_screen_loop

	rts

;==============================================
; num_to_ascii - convert byte to 3 ascii bytes
;==============================================

num_to_ascii:
        ldx  	#NUM2			; output to 3 bytes in zero page
	lda	RAMSIZE			; hardcoded to only print ramsize
        sta	DIVIDENDL
	 
div_loop:
	jsr	div10			; divide/mod by 10
	    
	clc
	lda	#$B0
	adc	REMAINDER		; convert remainder to ASCII
       	sta	0,X			; store to zero page
	dex
	lda	QUOTIENT		; move quotient to be next dividend
	sta	DIVIDENDL
	bne	div_loop

store_loop:				; now copy from zero page to output
	inx				; because generated in reverse
	lda	0,X
        sta	(OUTPUTL),Y
	cpx	#(NUM2+1)
	beq	done_ntoa
	jsr	inc_pointer
	jmp	store_loop
done_ntoa:
	rts

;==================================
; div10 - divide a byte by 10
;==================================

div10:
        sty	QUOTIENT
        lda	#$a0
        sta	DIVISORL		 ; set DIVISOR to 10<<4
div10_loop:
		  
       	asl	QUOTIENT
			
	lda	DIVIDENDL
	cmp	DIVISORL
        bcc	less_than_10
subtract_10:
	sec
        lda	DIVIDENDL
	sbc	DIVISORL
	sta	DIVIDENDL
			
	lda	QUOTIENT
	ora	#1
	sta	QUOTIENT
less_than_10:
					  
	clc
	     
	ror	DIVISORL
	lda	DIVISORL
	cmp	#$5
	bne	div10_loop
				     
	lda	DIVIDENDL
	sta    	REMAINDER
			
	rts		

;====================================
; strcat - concatenate string
;====================================

strcat:
        lda	(STRCATL),Y
	sta	(OUTPUTL),Y
        beq	strcat_done
	ldx	#STRCATL
	jsr	inc16
	jsr	inc_pointer
	jmp	strcat
strcat_done:
	rts

;=============================================
; center_and_print - centers and prints string
;=============================================

center_and_print:
	jsr	strlen			; get length of string
  
	sec
        lda	#40			; width of screen
	sbc	COUNT

	bmi	no_center
	lsr	A	 		; divide by 2
	adc	#0			; round up if carry
	
	tax

	jsr	PRBL2			; print X blanks

	jsr	reset_output		; reset output pointer
	
no_center:
	ldx	COUNT
print_loop:
      	lda	(OUTPUTL),Y
        jsr	COUT1

	jsr	inc_pointer
	dex
	bne	print_loop
		  
	jsr	CROUT	  		; output to screen
		     
	rts

;================================
; strlen - count length of string
;================================

strlen:
        jsr	reset_output		; reset the output pointer

	sty	COUNT			; set count to zero
strlen_loop:
        lda 	(OUTPUTL),Y
       	beq	strlen_done
	inc	COUNT	   		; if not zero, increment count
	jsr	inc_pointer
        jmp	strlen_loop
strlen_done:
	rts		     
		     
;=========================================
; reset_output - reset OUTPUT H&L pointers
;=========================================

reset_output:
	lda  	#<OUTPUT
      	sta	OUTPUTL
        lda	#>OUTPUT
	sta	OUTPUTH
	rts	    

;=================================
; get_sysinfo
;=================================

; uses lookup table from 
;    http://web.pdx.edu/~heiss/technotes/misc/tn.misc.07.html
; to get model type.
; Then make some intelligent guesses about chip/memory
; This is just a simple hack, and doesn't support IIgs

get_sysinfo:
	lda 	#64			; first set some defaults
      	sta	RAMSIZE
        lda	#('e'+$80)
	sta	TYPE
	lda	#0
	sta	CPU
		        
	lda	$FBB3
	cmp	#$38
	bne	apple_iiplus
apple_ii:
	lda	#(' '+$80)		; we're an original Apple II
	sta	TYPE
	jmp	done_detecting
					  
apple_iiplus:
	cmp  	#$EA
      	bne	apple_iie
      
        lda	$FB1E
	cmp	#$8A
	beq	apple_iii
	       
	lda	#48	 		; we're an Apple II+
	
	sta	RAMSIZE			; not always true
		     			; 64k if language card
					; too lazy to detect that
					
	lda	#('+'+$80)
	sta	TYPE
	jmp	done_detecting
	
apple_iii:
   	lda	#('I'+$80)		; we're an Apple III in emulation
      	sta	TYPE
        lda	#48
	sta	RAMSIZE
	jmp	done_detecting
	       
apple_iie:
	lda	$FBC0
	beq	apple_iic
		     
        cmp	#$E0	 		; we're an Apple IIe (original)
	bne	done_detecting
			   
apple_iie_enhanced:
	lda	#1 			; we're an Apple IIe (enhanced)
	sta	CPU
	lda	#128
	sta	RAMSIZE
				       
	jmp	done_detecting
					  
apple_iic:
   	lda	#('c'+$80)		; we're an Apple IIc
      	sta	TYPE
        lda	#128
	sta	RAMSIZE
	    
done_detecting:
	rts

	
;; *********************
;; BSS
;; *********************
.bss

R:  		  .res (N-F)
zp_save:	  .res 32


;; *********************
;; DATA
;; *********************
.data

VERSION:
; "Linux Version 2.6.22.6, Compiled 2007"
.byte	$CC,$E9,$EE,$F5,$F8,$A0,$D6,$E5,$F2,$F3,$E9,$EF,$EE,$A0,$B2,$AE
.byte	$B6,$AE,$B2,$B2,$AE,$B6,$AC,$A0,$C3,$EF,$ED,$F0,$E9,$EC,$E5,$E4
.byte	$A0,$B2,$B0,$B0,$B7,$00

ONE:
; "One 1.02MHz "
.byte	$CF,$EE,$E5,$A0,$B1,$AE,$B0,$B2,$CD,$C8,$FA,$A0,$00

NMOS:
; "6502"
.byte   $B6,$B5,$B0,$B2,$00

CMOS:
; "65C02"
.byte	$B6,$B5,$C3,$B0,$B2,$00

PROCESSOR:
; " Processor, "
.byte	$A0,$D0,$F2,$EF,$E3,$E5,$F3,$F3,$EF,$F2,$AC,$A0,$00

RAM:	
; "kB RAM"
.byte	$EB,$C2,$A0,$D2,$C1,$CD,$00

APPLE:
; "Apple II";
.byte 	$C1,$F0,$F0,$EC,$E5,$A0,$C9,$C9,$00


LOGO:
.byte	255,27,91,48,59,49,59,51,55
.byte	159,59,52,55,109,35,204,247,192,7,51
.byte	141,48,200,27,27,91,196,7,203,31,28,12,59
.byte	15,52,48,109,10,192,247,1,96,26,56,44,156
.byte	31,27,91,51,49,109,204,4,65,172,13,36
.byte	2,28,16,79,13,32,16,65,147,152,131,52,28,52,204,16
.byte	16,12,36,111,57,236,167,28,8,51,22,20,137,85,44,96
.byte	0,43,97,214,113,226,200,203,8,212,9,211,16,43,89,245,209
.byte	0,128,17,210,24,13,40,28,20,13,44,28,28,240,74,26,91
.byte	0,13,80,95,101,135,101,43,85,245,205,205,40,205,20,137,65
.byte	0,29,135,66,75,114,83,28,120,15,98,135,109,85,88,247,193
.byte	0,232,43,244,151,73,120,61,176,27,95,151,176,18,43,171,202
.byte	16,223,22,26,245,90,245,217,63,51,27,86,146,91,176,2
.byte	0,12,29,211,200,172,57,23,102,50,246,110,109,236,68,96,94
.byte	8,175,10,166,105,20,1,48,51,11,222,31,49,15,211,188
.byte	0,175,79,25,86,170,69,82,219,40,82,70,127,8,83,219,35
.byte	0,169,85,170,53,24,33,18,104,145,42,200,34,178,104,112,45
.byte	0,198,80,178,121,145,74,112,49,248,81,243,40,221,23,255,23
.byte	8,2,54,3,36,229,66,10
LOGO_END:
