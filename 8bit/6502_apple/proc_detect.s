;
;  proc_detect.s
;     detects some system info and creates appropriate
;     /proc/cpuinfo analog

;  Much of the file I/O code is based on samples
;    from "Beneath Apple DOS" by Don Worth and Pieter Lechner

.define EQU =

;; Our Zero Page Allocations

OUTPUTH   EQU $FD
OUTPUTL   EQU $FC
STRCATH   EQU $EF
STRCATL   EQU $EE
RAMSIZE   EQU $ED
TYPE      EQU $EC
CPU       EQU $EB

RWTSH	  EQU $FB
RWTSL	  EQU $FA

DOSBUFH	  EQU $EF
DOSBUFL   EQU $EE

FILEMH    EQU $ED
FILEML	  EQU $EC



;; VECTORS
BASIC 	 EQU $3D0		       ;; VECTOR for return to Applesoft

;; MONITOR ROUTINES
COUT	EQU $FDED		       ;; output A to screen (indirect)
CROUT   EQU $FD8E		       ;; char out monitor routine

;; DOS VALUES

OPEN    EQU $01
CLOSE   EQU $02
READ    EQU $03
WRITE   EQU $04
DELETE  EQU $05
CATALOG EQU $06
LOCK    EQU $07
UNLOCK  EQU $08
RENAME  EQU $09
POSITION EQU $0A
INIT    EQU $0B
VERIFY  EQU $0C

LOCATE_FILEM_PARAM EQU $3DC
LOCATE_RWTS_PARAM  EQU $3E3
FILEMANAGER        EQU $3D6

;==========================================================
; MAIN()
;==========================================================


	;=================================
	; print the system info
	;=================================

	jsr	reset_output

	ldy 	#0			; be sure Y is zero

	; write first part of model

	lda	#>model
        sta	STRCATH
	lda	#<model
	sta	STRCATL
		  
	jsr	strcat	  		; concat to output

; get system info
;
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

	lda     TYPE			; load type into A
	sta	(OUTPUTL),Y		; store A to 16-bit OUTPUTLH pointer
	jsr	inc_pointer		; increment output pointer

	lda	#$8D			; load in carriage-return
	sta	(OUTPUTL),Y		; store A to 16-bit OUTPUTLH pointer
	jsr	inc_pointer		; increment output pointer
			

	
	lda	#>cpu			; point to the cpu type line
	sta	STRCATH
	lda	#<cpu
	sta	STRCATL
	jsr	strcat 			; concatenate it
					       
	lda	CPU			; what kind of CPU do we have?
	bne	is_cmos
is_nmos:
	lda	#>nmos			; we have 6502 CPU, so print that
	sta	STRCATH
	lda	#<nmos
	sta	STRCATL
	jmp	done_cpu

is_cmos:
    	lda	#>cmos			; we have 65C02 CPU, so print that
	sta	STRCATH
	lda	#<cmos
	sta    	STRCATL

done_cpu:
	jsr	strcat

	lda	#$8D			; load in carriage-return
	sta	(OUTPUTL),Y		; store A to 16-bit OUTPUTLH pointer
	jsr	inc_pointer		; increment output pointer



	lda	#>mhz			; add MHz string
	sta	STRCATH
	lda	#<mhz
	sta    	STRCATL
	jsr	strcat

	lda	#>bogomips		; add the bogomips related string
	sta	STRCATH
	lda	#<bogomips
	sta	STRCATL
	jsr	strcat
    
	
	jsr	CROUT

        ; print writing message

	lda	#>write_message		; print writing message
	sta	OUTPUTH
	lda	#<write_message
	sta    	OUTPUTL
	jsr	write_stdout
	
	; print output buffer
	
	jsr     reset_output		; reset the output pointer to begin
	jsr	write_stdout

	jsr	CROUT
	
	;================================
	; save to disk
	;================================
	
	jsr     LOCATE_FILEM_PARAM  	; load file manager param list
					; Y=low A=high
		
	sta	FILEMH
	sty	FILEML
	
	ldy    #8    			; set filename
	lda    #<filename
	sta    (FILEML),y
	iny
	lda    #>filename
	sta    (FILEML),y
	ldy    #7	 		; file type
	lda    #0			; 0 = text
	sta    (FILEML),y
	ldx    #0	 		; create new file
	
	jsr    open			; open file

	jsr    write			; write buffer out

	jsr    close			; close file
	

	;=====================================
	; read from disk
	;=====================================	

	ldy    #8    			; set filename
	lda    #<filename
	sta    (FILEML),y
	iny
	lda    #>filename
	sta    (FILEML),y
	ldy    #7	 		; file type
	lda    #0			; 0 = text
	sta    (FILEML),y
	ldx    #1	 		; open existing file
	
	jsr    open			; open file

	jsr    read			; write buffer out

	jsr    close			; close file


	;============================
	; print reading message
	;============================

	ldy 	#0			; be sure Y is zero
	lda	#>read_message		; print writing message
	sta	OUTPUTH
	lda	#<read_message
	sta    	OUTPUTL
	jsr	write_stdout	
	
	;==========================
	; print disk buffer
	;==========================
	
	lda	#>disk_buff		; print disk buffer
	sta	OUTPUTH
	lda	#<disk_buff
	sta    	OUTPUTL
	jsr	write_stdout

	jsr	CROUT

;==========================================================
; EXIT back to BASIC
;==========================================================

exit:

     	jmp 	BASIC		       ; return to BASIC


;=================================
; get_dos_buffer
;=================================
;
; Dos buffer format
; 0x000-0x0ff = data buffer
; 0x100-0x1ff = t/s list buffer
; 0x200-0x22c = file manager workarea (45 bytes)
; 0x22d-0x24a = file name buffer

; 0x24b-0x24c = address of file manager workarea
; 0x24d-0x24e = address of t/s list buffer
; 0x24f-0x250 = adress of data sector buffer
; 0x251-0x252 = address of file name field for the next buffer

; In DOS, $3D2 points to 0x22d of first buffer
;    add 0x24 to get chain pointer


open:
	; allocate one of the DOS buffers so we don't have to set them up
	
allocate_dos_buffer:
	lda     $3D2			; DOS load point
	sta	DOSBUFH
	ldy	#0
	sty	DOSBUFL
	
buf_loop:
	lda	(DOSBUFL),Y		; locate next buffer
	pha				; push on stack
					; we need this later
					; to test validity
					
	iny				; increment y
	lda	(DOSBUFL),Y		; load next byte
	sta	DOSBUFH			; store to buffer pointerl

	pla				; restore value from stack
	
	sta	DOSBUFL			; store to buffer pointerh
	
	bne	found_buffer		; if not zero, found a buffer
	
	lda	DOSBUFH			; also if not zero, found a buffer
	beq     exit			; no buffer found, exit

found_buffer:
	ldy  	#0			; get filename
	lda	(DOSBUFL),Y		; get first byte
	beq	good_buffer		; if zero, good buffer
	
					; in use
	ldy	#$24	   		; point to next 
	bne	buf_loop		; and loop
	
good_buffer:
	lda 	#$78
	sta	(DOSBUFL),Y		; mark as in use (can be any !0)

keep_opening:
	ldy	#0	
	lda	#OPEN			; set operation code to OPEN
	sta	(FILEML),y
	
	ldy	#2	  		; point to record length
	lda	#0			; set it to zero (16-bits)
	sta	(FILEML),y
	iny
	sta	(FILEML),y
	
	iny		  		; point to volume num (0=any)
	sta	(FILEML),y
	
	jsr	LOCATE_RWTS_PARAM	; get current RWTS parameters
					; so we can get disk/slot info
					
	sty	RWTSL
	sta	RWTSH
	
	ldy	#1
	lda	(RWTSL),y		; get slot*16
	lsr	a
	lsr	a
	lsr	a
	lsr	a			; divide by 16
	
	ldy	#6			; address of slot
	sta	(FILEML),y		; store it
	
	ldy	#2
	lda	(RWTSL),y		; get drive
	ldy	#5			; address of drive
	sta	(FILEML),y
	
filemanager_interface:

	ldy 	#$1E
dbuf_loop:	
	lda	(DOSBUFL),y		; get three buffer pointers
	pha				; push onto stack
	iny				; increment pointer
	cpy	#$24			; have we incremented 6 times?
	bcc	dbuf_loop		; if not, loop
	
	ldy	#$11			; point to the end of the same struct
					; in file manager
fmgr_loop:					
	pla				; pop value
	sta	(FILEML),Y		; store it
	dey				; work backwards
	cpy	#$c			; see if we are done
	bcs	fmgr_loop		; loop
	
	jmp	FILEMANAGER		; run filemanager
	

;====================
; close DOS file
;====================

close:
        ldy    #0    			; command offset
	lda    #CLOSE			; load close
	sta    (FILEML),y		
		     
	jsr    filemanager_interface
	
	ldy    #0		    	; mark dos buffer as free again
	tya
	sta    (DOSBUFL),y
	

	rts

;=========================
; write to dos file
;=========================

write:
        ldy   #0			; command offset
	lda   #WRITE
	sta   (FILEML),y
	
	iny   				; point to sub-opcode
	lda   #2			; "range of bytes"
	sta   (FILEML),y
	
	ldy   #6			; point to number of bytes to write
	      				; must be number - 1
	lda   #$ff
	sta   (FILEML),y		; we want to write 256 bytes
	iny
	lda   #$00
	sta   (FILEML),y

	ldy   #8			; buffer address
	lda   #<out_buff
	sta   (FILEML),y
	iny
	lda   #>out_buff
	sta   (FILEML),y
	
	jmp   filemanager_interface
	
	
;=========================
; read from dos file
;=========================

read:
        ldy   #0			; command offset
	lda   #READ
	sta   (FILEML),y
	
	iny   				; point to sub-opcode
	lda   #2			; "range of bytes"
	sta   (FILEML),y
	
	ldy   #6			; point to number of bytes to read
	lda   #$ff
	sta   (FILEML),y		; we want to read 255 bytes
	iny
	lda   #$00
	sta   (FILEML),y

	ldy   #8			; buffer address
	lda   #<disk_buff
	sta   (FILEML),y
	iny
	lda   #>disk_buff
	sta   (FILEML),y
	
	jmp   filemanager_interface

;================================================
; write_stdout - write out string at OUTPUTL
;================================================

write_stdout:
        lda	(OUTPUTL),Y		; load A from 16-bit ZP output address
	beq	print_done		; if zero, done printing
	jsr	COUT			; print char to screen
	ldx	#OUTPUTL		; point X to 16-bit OUTPUT address
	jsr	inc16			; increment 16-bit address pointer
	jmp	write_stdout		; loop
print_done:
	rts
	
;==================================================
; inc16 - increments a 16-bit pointer in zero page 
;==================================================

inc16:
        inc     0,X                	 ; increment address
	bne     no_carry
	inx				 ; increment x (to high byte)
	inc     0,X			 ; handle overflow
no_carry: 
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
	   
;====================================
; strcat - concatenate string
;====================================

strcat:
        lda	(STRCATL),Y		; load A from 16-bit STRCATLH pointer
	sta	(OUTPUTL),Y		; store A to 16-bit OUTPUTLH pointer
        beq	strcat_done		; if value was zero, done
	ldx	#STRCATL		; increment strcat pointer
	jsr	inc16			;
	jsr	inc_pointer		; increment output pointer
	jmp	strcat			; loop
strcat_done:
	rts 				; return


;=========================================
; reset_output - reset OUTPUT H&L pointers
;=========================================

reset_output:
	lda  	#<out_buff
      	sta	OUTPUTL
        lda	#>out_buff
	sta	OUTPUTH
	rts
	
;; *********************
;; BSS
;; *********************
.bss

disk_buff:	  .res 256
out_buff:	  .res 256

;; *********************
;; DATA
;; *********************
.data

filename:
; CPUINFO__6502 (padded to be 30 chars long)
.byte $C3,$D0,$D5,$C9,$CE,$C6,$CF,$DF
.byte $DF,$B6,$B5,$B0,$B2,$A0,$A0,$A0
.byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
.byte $A0,$A0,$A0,$A0,$A0,$A0


write_message:
; "WRITING TO DISK:"
.byte   $D7,$D2,$C9,$D4,$C9,$CE,$C7,$A0
.byte   $D4,$CF,$A0,$C4,$C9,$D3,$CB,$BA
.byte   $8D,$00

read_message:
; "READ FROM DISK:"
.byte   $D2,$C5,$C1,$C4,$A0,$C6,$D2,$CF
.byte   $CD,$A0,$C4,$C9,$D3,$CB,$BA,$8D
.byte	$00

model:
; "MODEL      : APPLE II"
.byte   $CD,$CF,$C4,$C5,$CC,$A0,$A0,$A0
.byte   $A0,$A0,$A0,$BA,$A0,$C1,$D0,$D0
.byte   $CC,$C5,$A0,$C9,$C9,$00

cpu:
; "CPU        : "
.byte   $C3,$D0,$D5,$A0,$A0,$A0,$A0,$A0
.byte   $A0,$A0,$A0,$BA,$A0,$00

mhz:
; "CPU MHZ    : 1.02MHz"
.byte   $C3,$D0,$D5,$A0,$CD,$C8,$DA,$A0
.byte   $A0,$A0,$A0,$BA,$A0,$B1,$AE,$B0
.byte	$B2,$CD,$C8,$FA,$8D,$00

bogomips:
; "BOGOMIPS   : 0.013"
.byte   $C2,$CF,$C7,$CF,$CD,$C9,$D0,$D3
.byte   $A0,$A0,$A0,$BA,$A0,$B0,$AE,$B0
.byte   $B1,$B3,$8D,$00

nmos:
; "6502"
.byte   $B6,$B5,$B0,$B2,$00

cmos:
; "65C02"
.byte	$B6,$B5,$C3,$B0,$B2,$00
