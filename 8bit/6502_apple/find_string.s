
	;=================================
	; FIND_STRING 
	;=================================
	;   disk buffer pointer is in DISKH/DISKL
	;   disk buffer is 256 bytes max
	;   X holds value to stop at

find_string:
	ldy	#0
find_loop:
        lda	(DISKL),Y
	iny
	
	beq	done			# if so, done

	cmp	(%esi), %ebx		# do the strings match?
	jne	find_loop		# if not, loop
	
					# if we get this far, we matched

find_colon:	   			
	lodsb				# repeat till we find colon
	cmp	$0,%al			# this is actually smaller code
	je	done			#   than an or ecx/repnz scasb
	cmp	$':',%al
	jne	find_colon


skip_spaces:
        lodsb                           # skip spaces
	cmp     $0x20,%al               # Loser new intel chips have lots??
        je      skip_spaces

store_loop:	 
	cmp	$0,%al
	je	done
	cmp	%ah,%al			# is it end string?
	je 	almost_done		# if so, finish
	cmp	$'\n',%al		# also end if linefeed
	je	almost_done
	stosb				# if not store and continue
	lodsb				# load value	
	jmp	store_loop
	 
almost_done:	 

	movb	 $0, (%edi)	        # replace last value with NUL 
done:
	ret

