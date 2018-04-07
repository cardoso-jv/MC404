	.file	"mapa.c"
	.globl	mapa
	.data
	.align 32
	.type	mapa, @object
	.size	mapa, 100
mapa:
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	95
	.byte	95
	.byte	95
	.byte	88
	.byte	88
	.byte	95
	.byte	88
	.byte	95
	.byte	88
	.byte	88
	.byte	95
	.byte	88
	.byte	95
	.byte	88
	.byte	88
	.byte	95
	.byte	95
	.byte	95
	.byte	88
	.byte	88
	.byte	95
	.byte	88
	.byte	88
	.byte	95
	.byte	95
	.byte	95
	.byte	88
	.byte	95
	.byte	88
	.byte	88
	.byte	95
	.byte	88
	.byte	95
	.byte	95
	.byte	88
	.byte	95
	.byte	95
	.byte	95
	.byte	88
	.byte	88
	.byte	95
	.byte	95
	.byte	95
	.byte	88
	.byte	88
	.byte	95
	.byte	88
	.byte	95
	.byte	88
	.byte	88
	.byte	95
	.byte	88
	.byte	95
	.byte	95
	.byte	88
	.byte	95
	.byte	88
	.byte	95
	.byte	88
	.byte	88
	.byte	95
	.byte	95
	.byte	88
	.byte	95
	.byte	95
	.byte	95
	.byte	88
	.byte	95
	.byte	88
	.byte	88
	.byte	95
	.byte	95
	.byte	95
	.byte	95
	.byte	88
	.byte	95
	.byte	95
	.byte	95
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.byte	88
	.comm	visitados,400,32
	.comm	xRob,4,4
	.comm	yRob,4,4
	.comm	xLoc,4,4
	.comm	yLoc,4,4
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movl	%edi, -4(%rbp)
	movq	%rsi, -16(%rbp)
	movl	$3, xRob(%rip)
	movl	$1, yRob(%rip)
	movl	$8, xLoc(%rip)
	movl	$3, yLoc(%rip)
	movl	$0, %eax
	call	ajudaORobinson
	movl	$0, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.globl	daParaPassar
	.type	daParaPassar, @function
daParaPassar:
.LFB1:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	%edi, -4(%rbp)
	movl	%esi, -8(%rbp)
	cmpl	$0, -4(%rbp)
	js	.L4
	cmpl	$9, -4(%rbp)
	jg	.L4
	cmpl	$0, -8(%rbp)
	js	.L4
	cmpl	$9, -8(%rbp)
	jle	.L5
.L4:
	movl	$0, %eax
	jmp	.L6
.L5:
	movl	-8(%rbp), %eax
	movslq	%eax, %rcx
	movl	-4(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$2, %rax
	addq	%rdx, %rax
	addq	%rax, %rax
	addq	%rcx, %rax
	addq	$mapa, %rax
	movzbl	(%rax), %eax
	cmpb	$88, %al
	setne	%al
	movzbl	%al, %eax
.L6:
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1:
	.size	daParaPassar, .-daParaPassar
	.globl	posicaoXRobinson
	.type	posicaoXRobinson, @function
posicaoXRobinson:
.LFB2:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	xRob(%rip), %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2:
	.size	posicaoXRobinson, .-posicaoXRobinson
	.globl	posicaoYRobinson
	.type	posicaoYRobinson, @function
posicaoYRobinson:
.LFB3:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	yRob(%rip), %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE3:
	.size	posicaoYRobinson, .-posicaoYRobinson
	.globl	posicaoXLocal
	.type	posicaoXLocal, @function
posicaoXLocal:
.LFB4:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	xLoc(%rip), %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE4:
	.size	posicaoXLocal, .-posicaoXLocal
	.globl	posicaoYLocal
	.type	posicaoYLocal, @function
posicaoYLocal:
.LFB5:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	yLoc(%rip), %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE5:
	.size	posicaoYLocal, .-posicaoYLocal
	.globl	inicializaVisitados
	.type	inicializaVisitados, @function
inicializaVisitados:
.LFB6:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	$0, -4(%rbp)
	jmp	.L16
.L19:
	movl	$0, -8(%rbp)
	jmp	.L17
.L18:
	movl	-8(%rbp), %eax
	movslq	%eax, %rcx
	movl	-4(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$2, %rax
	addq	%rdx, %rax
	addq	%rax, %rax
	addq	%rcx, %rax
	movl	$0, visitados(,%rax,4)
	addl	$1, -8(%rbp)
.L17:
	cmpl	$9, -8(%rbp)
	jle	.L18
	addl	$1, -4(%rbp)
.L16:
	cmpl	$9, -4(%rbp)
	jle	.L19
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE6:
	.size	inicializaVisitados, .-inicializaVisitados
	.globl	foiVisitado
	.type	foiVisitado, @function
foiVisitado:
.LFB7:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	%edi, -4(%rbp)
	movl	%esi, -8(%rbp)
	movl	-8(%rbp), %eax
	movslq	%eax, %rcx
	movl	-4(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$2, %rax
	addq	%rdx, %rax
	addq	%rax, %rax
	addq	%rcx, %rax
	movl	visitados(,%rax,4), %eax
	cmpl	$1, %eax
	sete	%al
	movzbl	%al, %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE7:
	.size	foiVisitado, .-foiVisitado
	.globl	visitaCelula
	.type	visitaCelula, @function
visitaCelula:
.LFB8:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	%edi, -4(%rbp)
	movl	%esi, -8(%rbp)
	movl	-8(%rbp), %eax
	movslq	%eax, %rcx
	movl	-4(%rbp), %eax
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$2, %rax
	addq	%rdx, %rax
	addq	%rax, %rax
	addq	%rcx, %rax
	movl	$1, visitados(,%rax,4)
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE8:
	.size	visitaCelula, .-visitaCelula
	.globl	ajudaORobinson
	.type	ajudaORobinson, @function
ajudaORobinson:
.LFB9:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE9:
	.size	ajudaORobinson, .-ajudaORobinson
	.ident	"GCC: (GNU) 6.3.1 20161221 (Red Hat 6.3.1-1)"
	.section	.note.GNU-stack,"",@progbits
