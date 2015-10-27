# 16-bit code that will run on x86_64 Linux
# Tested with binutils 2.25.1

# as -o 16.o 16.s
# ld -Ttext-segment=0x4000 -o 16 16.o

# Need to run as root (sudo ./16) because Linux doesn't like
# letting you map executables into really low memory

.globl _start

.arch i286
.code16

_start:
	push	$1		# write syscall
	pop	%ax

	push	$6		# write 6 bytes
	pop	%dx

	xor	%di,%di		# stdout = 1
	add	$1,%di		# can't use inc as 1-byte inc not
				# valid in x86_64

	movb	$0x40,%ch	# point to hello
	movb	$0x92,%cl	# for some reason movw of a 16-bit number
				# seriously confuses gas
	mov	%cx,%si

	.byte 0x0f,0x05		# syscall
#	int $0x80		# int 0x80 won't work for some reason
				# strace shows it works but the syscall
				# never returns
exit:
	push	$60		# exit
	pop	%ax
	xor	%di,%di		# exit(0)

	.byte 0x0f,0x05 # syscall

hello_world:	.ascii "Hello\n"
