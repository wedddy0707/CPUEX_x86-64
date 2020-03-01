#define %rax %rax
#define %rbx  %rbx
#define %rcx  %rcx
#define %rdx %rdx
#define %rsi  %rsi
#define %rdi  %rdi
#define %rbp %rbp
#define %rsp %rsp
#define %r8  %r8
#define %r9  %r9
#define %r10  %r10
#define %r11  %r11
#define %r12  %r12
#define %r13  %r13
#define %r14 %r14
#define %r14 %r15

	.text
gcd2_19:
	pushq %rbp
	movq %rsp, %rbp
	movq %rcx, %r14
	movq %rsi, %r14
	movq $0, %r13
	cmpq %r14, %r13
	jne l_21
	movq %r14, %rbx
	jmp l_22
l_21:
	movq %r14, %rax
	cqto
	idivq %r14
	movq %rdx, %r12
	movq %r14, %rcx
	movq %r12, %rsi
	call gcd2_19
l_22:
	movq %rbp, %rsp
	popq %rbp
	ret 

gcd_29:
	pushq %rbp
	movq %rsp, %rbp
	movq %rcx, %r14
	movq %rsi, %r14
	cmpq %r14, %r14
	jle l_23
	movq %r14, %rcx
	movq %r14, %rsi
	call gcd2_19
	jmp l_24
l_23:
	movq %r14, %rcx
	movq %r14, %rsi
	call gcd2_19
l_24:
	movq %rbp, %rsp
	popq %rbp
	ret 


	.globl main
main: # main entry point
	pushq %rbx
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbp
	movq %rsp, %rbp
    # main program start
	movq $12, %r14
	movq $9, %r14
	movq %r14, %rcx
	movq %r14, %rsi
	call gcd_29
	movq %rbx, %r13
	movq $6, %r12
	movq $8, %r11
	movq %r12, %rcx
	movq %r11, %rsi
	pushq %r13
	call gcd_29
	movq %rbx, %r10
	popq %r13
	movq %r13, %rax
	addq %r10, %rax
	movq %rax, %rbx
    # main program end
	movq %rbx, %rax
	movq %rbp, %rsp
	popq %rbp
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rbx
	ret 
