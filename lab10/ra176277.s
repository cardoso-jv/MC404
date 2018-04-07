@ Constantes para os enderecos do GPT
.set GPT_CR,								0x53FA0000
.set GPT_PR,								0x53FA0004
.set GPT_SR,								0x53FA0008
.set GPT_IR, 								0x53FA000C
.set GPT_OCR1,							0x53FA0010

@ Constantes para os enderecos do TZIC
.set TZIC_BASE,             0x0FFFC000
.set TZIC_INTCTRL,          0x00000000
.set TZIC_PRIOMASK,         0x0000000C
.set TZIC_INTSEC1,          0x00000084
.set TZIC_ENSET1,           0x00000104
.set TZIC_PRIORITY9,        0x00000424

@ Máscaras para troca do Modo
.set SYSTEM_M, 							0x0000001F
.set USER_M,								0x00000010
.set IRQ_M,									0x00000012
.set SUPERVISOR_M,					0x00000013

@ Constantes
.set TIME_SZ, 							100 @ Tempo do sistema



.org 0x0
.section .iv,"a"

_start:

interrupt_vector:
  b RESET_HANDLER 			@ 0x000
.org 0x18
  b IRQ_HANDLER					@ 0x018


.org 0x100
.text

RESET_HANDLER:

  @ Zera o contador
  ldr r2, =count_system  @ Carrega endereço do count_system em r2
  mov r0, #0
  str r0, [r2]

  @ Faz o registrador que aponta para a tabela de interrupções apontar para a tabela interrupt_vector
  ldr r0, =interrupt_vector
  mcr p15, 0, r0, c12, c0, 0

  @ Troca para modo IRQ
  msr  CPSR_c, #IRQ_M

  @ Ajusta a pilha do modo IRQ.
  ldr r13, =irq_stack_pointer

  @ Volta para modo anterior
  msr  CPSR_c, #SUPERVISOR_M

  @ Habilita o GPT e configura o clock_src para periférico
  ldr r1, =GPT_CR
  mov r0, #0x41
  str r0, [r1]

  @ Zera o prescaler (GPT_PR) e seta GPT_OCR1 para contar até 100 clocks
  ldr r1, =GPT_PR
  mov r0, #0
  str r0, [r1]

  ldr r1, =GPT_OCR1
  mov r0, #TIME_SZ
  str r0, [r1]

  @ Habilita Output Compare Channel 1
  ldr r1, =GPT_IR
  mov r0, #1
  str r0, [r1]

SET_TZIC:

  @ Liga o controlador de interrupcoes
  @ R1 <= TZIC_BASE
  ldr	r1, =TZIC_BASE

  @ Configura interrupcao 39 do GPT como nao segura
  mov	r0, #(1 << 7)
  str	r0, [r1, #TZIC_INTSEC1]

  @ Habilita interrupcao 39 (GPT)
  @ reg1 bit 7 (gpt)
  mov	r0, #(1 << 7)
  str	r0, [r1, #TZIC_ENSET1]

  @ Configure interrupt39 priority as 1
  @ reg9, byte 3
  ldr r0, [r1, #TZIC_PRIORITY9]
  bic r0, r0, #0xFF000000
  mov r2, #1
  orr r0, r0, r2, lsl #24
  str r0, [r1, #TZIC_PRIORITY9]

  @ Configure PRIOMASK as 0
  eor r0, r0, r0
  str r0, [r1, #TZIC_PRIOMASK]

  @ Habilita o controlador de interrupcoes
  mov	r0, #1
  str	r0, [r1, #TZIC_INTCTRL]

  @instrucao msr - habilita interrupcoes
  msr  CPSR_c, #SUPERVISOR_M    @ SUPERVISOR mode, IRQ/FIQ enabled

laco:
	b laco


IRQ_HANDLER:
	@ Sinaliza ao GPT que estamos tratando a interrupcao
	ldr r1, =GPT_SR
	mov r0, #0x1
	str r0, [r1]

	@ Incrementa Contador
	ldr r2, =count_system
  ldr r0, [r2] 							@ Carrega o valor de count_system em r0
  add r0, r0, #1 						@ Incrementa 1 count_system
  str r0, [r2]							@ Guarda novo valor em count_system

  @ Corrige LR
  sub lr, #4

  @ Volta fluxo de execução
  movs pc, lr


.data

count_system:
	.skip 4

irq_stack:
	.skip 1024
irq_stack_pointer:

