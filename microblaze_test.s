# mb-as -o microblaze_test.o microblaze_test.s 
# mb-ld -o microblaze_test microblaze_test.o 

# Sycscalls
.equ SYSCALL_EXIT,	1
.equ SYSCALL_WRITE,	4

.equ STDOUT,1

	.globl _start	
_start:	

test:
	addi r12, r0, SYSCALL_WRITE
	addi r5, r0, STDOUT
	addi r6, r0, hello
	addi r7,r0, 13
	brki r14, 0x08			# syscall
	nop

exit:
        addi r12, r0, SYSCALL_EXIT	# put exit syscall in r12
	addi r5, r0,5			# return value 
        brki r14, 0x08			# syscall
	nop   	   			# branch delay slot

.data
hello:	.ascii "Hello World!\n\0"
