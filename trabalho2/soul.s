@
@   Sistema Operacional do UóLi - SOUL
@
@   Criado por João Victor Cardoso De Oliveira - 176277
@            e Matheus Pompeo Garcia - 156743
@
@   MC404 - Segundo semestre de 2017
@

@ Constantes para os enderecos do GPT
.set GPT_BASE,              0x53FA0000
.set GPT_CR,                0x00000000
.set GPT_PR,                0x00000004
.set GPT_SR,                0x00000008
.set GPT_IR,                0x0000000C
.set GPT_OCR1,              0x00000010

@ Constantes para os enderecos do TZIC
.set TZIC_BASE,             0x0FFFC000
.set TZIC_INTCTRL,          0x00000000
.set TZIC_PRIOMASK,         0x0000000C
.set TZIC_INTSEC1,          0x00000084
.set TZIC_ENSET1,           0x00000104
.set TZIC_PRIORITY9,        0x00000424

@ Constantes para os enderecos do GPIO
.set GPIO_BASE,             0x53F84000
.set GPIO_DR,               0x00000000
.set GPIO_GDIR,             0x00000004
.set GPIO_PSR,              0x00000008

@ Máscaras para troca do Modo
.set SYSTEM_M,              0x0000001F
.set USER_M,                0x00000010
.set IRQ_M,                 0x00000012
.set SUPERVISOR_M,          0x00000013

@ Códigos das SYSCALLS
.set SYS_READ_SONAR,          16 @ read_sonar
.set SYS_PROX_CALLB,          17 @ register_proximity_callback
.set SYS_SET_MSPEED1,         18 @ set_motor_speed
.set SYS_SET_MSPEED2,         19 @ set_motors_speed
.set SYS_GET_TIME,            20 @ get_time
.set SYS_SET_TIME,            21 @ set_time
.set SYS_SET_ALARM,           22 @ set_alarm
.set SOUL_IRQ,                23

@ Constantes
.set TIME_SZ,               100 @ Tempo do sistema
.set MAX_ALARMS,              8 @ Número Máximo de Alarmes
.set MAX_CALLBACKS,           8 @ Número Máximo de Register_proximity_Callbacks


.org 0x0
.section .iv,"a"

_start:

interrupt_vector:
  b RESET_HANDLER       @ 0x000
.org 0x08
  b SYSCALL_HANDLER     @ 0x008
.org 0x18
  b IRQ_HANDLER         @ 0x018


.org 0x100
.text

RESET_HANDLER:

  ldr sp, =supervisor_stack_pointer

  @ Zera o contador
  ldr r2, =count_system  @ Carrega endereço do count_system em r2
  mov r0, #0
  str r0, [r2]

  @ Faz o registrador que aponta para a tabela de interrupções apontar para a tabela interrupt_vector
  ldr r0, =interrupt_vector
  mcr p15, 0, r0, c12, c0, 0

START_IRQ_STACK:
  @ Troca para modo IRQ
  msr  CPSR_c, #IRQ_M

  @ Ajusta a pilha do modo IRQ.
  ldr sp, =irq_stack_pointer

  @ Volta para modo SUPERVISOR
  msr  CPSR_c, #SUPERVISOR_M

SET_GPT:
  @ R1 <= GPT_BASE
  ldr r1, =GPT_BASE

  @ Habilita o GPT e configura o clock_src para periférico
  mov r0, #0x41
  str r0, [r1, #GPT_CR]

  @ Zera o prescaler (GPT_PR) e seta GPT_OCR1 para contar até TIME_SZ clocks
  mov r0, #0
  str r0, [r1, #GPT_PR]

  mov r0, #TIME_SZ
  str r0, [r1, #GPT_OCR1]

  @ Habilita Output Compare Channel 1
  mov r0, #1
  str r0, [r1, #GPT_IR]

SET_TZIC:
  @ R1 <= TZIC_BASE
  ldr r1, =TZIC_BASE

  @ Configura interrupcao 39 do GPT como nao segura
  mov r0, #(1 << 7)
  str r0, [r1, #TZIC_INTSEC1]

  @ Habilita interrupcao 39 (GPT)
  @ reg1 bit 7 (gpt)
  mov r0, #(1 << 7)
  str r0, [r1, #TZIC_ENSET1]

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
  mov r0, #1
  str r0, [r1, #TZIC_INTCTRL]

  @instrucao msr - habilita interrupcoes
  msr  CPSR_c, #SUPERVISOR_M    @ SUPERVISOR mode, IRQ/FIQ enabled

SET_GPIO:
  ldr r1, =GPIO_BASE

  @ Configura bits do GDIR em entrada/saida de acordo com os periféricos do robô
  ldr r0, =0xFFFC003E      @ bin: 11111111111111000000000000111110 (Mais significativo -> Menos Significativo)
  str r0, [r1, #GPIO_GDIR]

START_USER_STACK:
  @ Troca para modo USER
  msr  CPSR_c, #USER_M

  @ Configura a pilha do modo USER.
  ldr sp, =user_stack_pointer

  @ Desvia o fluxo para o usuário
  ldr r0, =0x77812000
  mov pc, r0

SYSCALL_HANDLER:
  cmp r7, #SYS_READ_SONAR
  beq read_sonar
  cmp r7, #SYS_PROX_CALLB
  beq register_proximity_callback
  cmp r7, #SYS_SET_MSPEED1
  beq set_motor_speed
  cmp r7, #SYS_SET_MSPEED2
  beq set_motors_speed
  cmp r7, #SYS_GET_TIME
  beq get_time
  cmp r7, #SYS_SET_TIME
  beq set_time
  cmp r7, #SYS_SET_ALARM
  beq set_alarm
  cmp r7, #SOUL_IRQ
  beq change_irq_mode


IRQ_HANDLER:
  stmfd sp!, {r0-r11, lr}

@ Sinaliza ao GPT que estamos tratando a interrupcao
  ldr r5, =GPT_BASE
  mov r4, #0x1
  str r4, [r5, #GPT_SR]

@ Incrementa Contador
  ldr r9, =count_system
  ldr r6, [r9]              @ Carrega o valor de count_system em r0
  add r6, r6, #1            @ Incrementa 1 count_system
  str r6, [r9]              @ Guarda novo valor em count_system


rotina_do_alarme:
  ldr r4, =alarmsInUse      @ Carrega endereço do alarmsInUse
  ldr r4, [r4]              @ Carrega o número de Alarms
  cmp r4, #0                @ Compara número de Alarms com zero
  beq rotina_do_callback      @ Se igual, pula para final do irq_mode

  ldr r5, =alarmsTime       @ Load no endereço de Alarmtime[0]
  ldr r10, =alarmsAdress    @ Load no endereço de alarmsAdress[0]

alarme_irq_loop:
  cmp r4, #0                @ Compara r4 (número de alarmes ativos) com 0
  ble rotina_do_callback    @ Se r4 for menor ou igual a zero, o fluxo é desviado para o fim do laço

  ldr r8, [r5]              @ Carrega em r8 o tempo ativo do alarme a ser monitorado
  cmp r8, r6                @ Compara com o tempo do sistema
  beq iguais                @ Se iguais, o fluxo é desviado para o tratamento
retorna_dos_iguais:
  add r5, r5, #4            @ É adicionado 4 ao endereço dos times
  add r10, r10, #32         @ Adicionado 32 ao endereço dos alarmsAdress
  sub r4, r4, #1            @ E subtraido 1 do numero de alarmes ativos ainda nao verificados
  b alarme_irq_loop         @ Repete o laço

iguais:
  ldr  r7, [r10]            @ Carrega endereço da função de usuário

@  msr  CPSR_c, #USER_M      @ USER mode
  blx  r7
@  mov r7, #SOUL_IRQ
@  svc 0x0

  stmfd sp!, {r4-r10}        @ Empilha os registradores que serão sujos no tratamento

Reordenacao_dos_alarmes:

  cmp r4, #1                @ Compara o numero de alarmes que ainda restam com zero
  beq fim_tratamento        @ Se for igual a zero, pula para o fim do tratamento

  ldr r8, [r5, #4]          @ Carrega em r8 o tempo do endereço r5 + 4
  str r8, [r5]              @ Salva esse valor no endereço de r5
  add r5, r5, #4            @ Adiciona 4 a r5

  ldr r8, [r10, #32]        @ Carrega em r8 o endereço r10 + 32
  str r8, [r10]             @ Salva esse valor no endereço de r10
  add r10, r10, #32         @ Adiciona 32 a r10

  sub r4, r4, #1            @ Subtrai 1 do numero de alarmes que ainda restam para interagir
  b Reordenacao_dos_alarmes

fim_tratamento:
  ldmfd sp!, {r4-r10}       @ Desempilha os registradores que foram sujos durante a ordenação

  sub r5, r5, #4            @ Subtrai 4 de r5
  sub r10, r10, #32           @ Subtrai 32 de r10
  sub r4, r4, #1            @ Subtrai 4 de r5

  ldr r8, =alarmsInUse      @ Carrega endereço de alarmsInUse
  ldr r9, [r8]              @ Carrega o número de Alarms
  sub r9, r9, #1            @ Subtrai 1
  str r9, [r8]              @ E salva novamente no endereço de alarmsInUse

  b retorna_dos_iguais      @ Retorna o fluxo do programa


rotina_do_callback:
  ldr r3, =callbacksInUse
  ldr r3, [r3]
  cmp r3, #0
  beq termina_irq_mode

  ldr r4, =callbacksDistance
  ldr r5, =callbacksSonarID
  ldr r6, =callbacksAdress

callbacks_irq_loop:
  cmp r3, #0
  ble termina_irq_mode

  ldr r0, [r5]
  mov r7, #SYS_READ_SONAR
  svc 0x0

  ldr r1, [r4]
  cmp r0, r1
  ble trata_callback

retorna_da_func:
  sub r3, r3, #1
  add r4, r4, #12
  add r5, r5, #4
  add r6, r6, #32
  b callbacks_irq_loop

trata_callback:
@  stmfd sp!, {r4-r7}
  ldr r8, [r6]
@  msr CPSR_c, #USER_M
  blx r8
@  mov r7, #SOUL_IRQ
@  svc 0x0
@  ldmfd sp!, {r4-r7}
  stmfd sp!, {r3-r6}

Reordenação_das_callbacks:
  cmp r3, #1
  beq fim_callback

  ldr r8, [r4, #12]
  str r8, [r4]
  add r4, r4, #12

  ldr r8, [r5, #4]
  str r8, [r5]
  add r5, r5, #4

  ldr r8, [r6, #32]
  str r8, [r6]
  add r6, r6, #32

  sub r3, r3, #1
  b Reordenação_das_callbacks

fim_callback:
  ldmfd sp!, {r3 - r6}

  sub r3, r3, #1
  sub r4, r4, #12
  sub r5, r5, #4
  sub r6, r6, #32

  ldr r8, =callbacksInUse
  ldr r9, [r8]
  sub r9, r9, #1
  str r9, [r8]

  b retorna_da_func



termina_irq_mode:
  @ Corrige LR
  ldmfd sp!, {r0-r11, lr}
  sub lr, lr, #4

  @ Volta fluxo de execução
  movs pc, lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Identifica o valor sendo lido em um determinado sonar.
@
@   Parametro:
@     r0: Identificador do sonar.
@
@   Saida:
@     r0: o valor obtido na leitura do sonar
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
read_sonar:
  stmfd sp!, {lr}              @ Salva na pilha os registradores que serão sujos

  cmp r0, #15                  @ Compara r0 com 15 (maior número válido para identificador dos sonares).
  bhi invalidSonarIdentifier   @ Se maior -> salta para invalidSonarIdentifier

  ldr r3, =GPIO_BASE
  ldr r2, [r3, #GPIO_DR]       @ Carrega valor de GPIO_DR em r2
  bic r2, #0x3F                @ Limpa bits[5-0] do GPIO_DR
  mov r0, r0, lsl #2           @ Left shift 2 vezes para coincidir com os bits do GPIO (2-5)
  orr r2, r2, r0               @ OR do identificador do sonar em r0 com vetor GPIO_DR

  str r2, [r3, #GPIO_DR]       @ Escreve o valor no GPIO_DR e set o TRIGGER para 0

  bl delay                     @ Realiza um delay equivalente aos 15ms que demora o hardware

  orr r2, r2, #2               @ OR do vetor GPIO_DR com TRIGGER = 1
  str r2, [r3, #GPIO_DR]       @ Escreve o valor no GPIO_DR e set o TRIGGER para 1

  bl delay                     @ Realiza um delay equivalente aos 15ms que demora o hardware

  bic r2, r2, #2               @ BIC do vetor GPIO_DR com TRIGGER = 0
  str r2, [r3, #GPIO_DR]       @ Escreve o valor no GPIO_DR e set o TRIGGER para 0
  b last_phase                 @ Pula o fluxo de execução para o final

do_delay:
  bl delay
last_phase:
  ldr r2, [r3, #GPIO_DR]       @ Carrega valor de GPIO_DR em r2
  mov r0, #1                   @ Move para r0 o valor 1
  and r0, r0, r2               @ AND de r0 com r2
  cmp r0, #1                   @ Compara r0 com 1 (em bits) para verificar se FLAG = 1
  bne do_delay                 @ Se FLAG = 0, a ultima parte é refeita após um delay


  ldr r2, [r3, #GPIO_DR]       @ Carrega valor de GPIO_DR em r2
  ldr r0, =0x3FFC0             @ Seta em r0 os bits equivalente aos bits de SONAR_DATA no GPIO_DR
  and r0, r0, r2               @ AND de r0 com r2, o que faz com que r0 fique com o valor lido em SONAR_DATA
  mov r0, r0, lsr #6           @ Right shift dos bits de r0 14 vezes para coincidir com a ordem dos bits mais e menos significativos

  ldmfd sp!, {lr}              @ Desempilha lr.
  movs pc, lr                  @ Retorna fluxo

invalidSonarIdentifier:
  mov r0, #-1                  @ Carrega o valor -1 no registrados r0 (valor que representa valor invalido)
  ldmfd sp!, {lr}              @ Desempilha lr.
  movs pc, lr                  @ Retorna fluxo

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Chama uma função em determinado tempo de sistema.
@
@   Parametro:
@     r0: ponteiro para função a ser chamada quando o alarme for ativado.
@     r1: tempo de sistema em que o alarme deve ser adicionado
@
@   Saida:
@     r0: -1 Caso seja excedito o número de alarmes maximo
@     r0: -2 Caso tempo seja menor do que tempo atual do sistema
@     r0:  0 default
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
set_alarm:

  ldr r2, =alarmsInUse          @ Carrega o endereço de alarmsInUse em r2
  ldr r2, [r2]                  @ Carrega o número de alarmes em ativos em r2

  cmp r2, #MAX_ALARMS           @ Compara o número de alarmes ativos com o número maximo de alarmes
  bge MoreThanMax               @ Se maior ou igual o fluxo vai para MoreThanMax

  ldr r3, =count_system         @ Carrega o endereço de count_system em r3
  ldr r3, [r3]                  @ Carrega o tempo do sistema em r3

  cmp r1, r3                    @ Compara o tempo do sistema desejado para o alarme com o tempo do sistema atual
  ble LessThanTime              @ Se menor ou igual o fluxo vai para LessThanTime

  ldr r3, =alarmsAdress        @ Carrega em r3 o endereço do local onde será armazeada a função a ser chamada

Adress_insert_loop:
  cmp r2, #0                    @ Compara r2 (número de alarmes ativos) com 0
  beq Adress_insert_loop_end    @ Se r2 for igual a zero, o fluxo é desviado para a inserção
  add r3, r3, #32               @ Caso contrario é somado 32 a r3
  sub r2, r2, #1                @ Subtraido 1 de r2
  b Adress_insert_loop          @ E todo o processo se repete

Adress_insert_loop_end:
  str r0, [r3]                  @ Salva r0 (endereço da função) no endereço de r3

  ldr r2, =alarmsInUse          @ Carrega o endereço de alarmes ativos em r2
  ldr r2, [r2]                  @ Carrega o número de alarmes em ativos em r2

  ldr r3, =alarmsTime           @ Carrega em r3 o endereço do local onde será armazeado o tempo do alarme

Time_insert_loop:
  cmp r2, #0                    @ Compara r2 (número de alarmes ativos) com 0
  beq Time_insert_loop_end      @ Se r2 for igual a zero, o fluxo é desviado para a inserção
  add r3, r3, #4                @ Caso contrario é somado 32 a r3
  sub r2, r2, #1                @ Subtraido 1 de r2
  b Time_insert_loop            @ E todo o processo se repete

Time_insert_loop_end:
  str r1, [r3]                  @ Salva r1 (tempo da função) no endereço de r3

  ldr r3, =alarmsInUse          @ Carrega em r3 o endereço do número de alarmes ativos
  ldr r2, [r3]                  @ Carrega em r2 o número de alarmes ativos
  add r2,r2, #1                 @ Soma 1
  str r2, [r3]                  @ Salva no endereço do número de alarmes ativos

  mov r0, #0
  movs pc, lr                   @ Retorna o fluxo do usuário

MoreThanMax:
  mov   r0, #-1                 @ Carrega em r0 -1, identificador de um erro
  movs  pc, lr                  @ Retorna o fluxo do usuário

LessThanTime:
  mov   r0, #-2                 @ Carrega em r0 -2, identificador de um erro
  movs  pc, lr                  @ Retorna o fluxo do usuário

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Identifica a proximidade entre o robo e um objeto, para quando esta distância esta no limiar chamar uma função.
@
@   Parametro:
@     r0: Identificador do sonar (valores válidos: 0 a 15).
@     r1: Limiar de distância.
@     r2: ponteiro para função a ser chamada na ocorrência do alarme.
@
@   Saida:
@     r0: 0 caso tudo ocorra bem
@         -1 caso o número de callbacks máximo ativo no sistema seja maior do que MAX_CALLBACKS.
@         -2 caso o identificador do sonar seja inválido.
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

register_proximity_callback:
  stmfd sp!, {r4-r7}              @ Salva na pilha os registradores que serão sujos

  cmp r0, #15                  @ Compara r0 com 15 (maior número válido para identificador dos sonares).
  bhi invalidSonar_Callback    @ Se maior -> salta para invalidSonarIdentifier

  cmp r0, #0                   @ Compara r0 com 0 (menor número válido para identificador dos sonares).
  blt invalidSonar_Callback    @ Se menor -> salta para invalidSonarIdentifier

  ldr r7, =callbacksInUse
  ldr r3, [r7]
  cmp r3, #MAX_CALLBACKS
  bhi MoreThanMax_Callback

  ldr r4, =callbacksDistance
  ldr r5, =callbacksSonarID
  ldr r6, =callbacksAdress

  Callback_insert_loop:
  cmp r3, #0                    @ Compara r2 (número de alarmes ativos) com 0
  beq Callback_insert_loop_end  @ Se r2 for igual a zero, o fluxo é desviado para a inserção
  add r4, r4, #12               @ Caso contrario é somado 32 a r3
  add r5, r5, #4                @ Caso contrario é somado 32 a r3
  add r6, r6, #32               @ Caso contrario é somado 32 a r3
  sub r3, r3, #1                @ Subtraido 1 de r2
  b Callback_insert_loop        @ E todo o processo se repete

  Callback_insert_loop_end:
  ldr r3, [r7]
  add r3, r3, #1
  str r3, [r7]
  str r0, [r5]                  @ Salva r0 (endereço da função) no endereço de r3
  str r1, [r4]                  @ Salva r0 (endereço da função) no endereço de r3
  str r2, [r6]                  @ Salva r0 (endereço da função) no endereço de r3

  ldmfd sp!, {r4-r6}            @ Desempilha lr.

  mov r0, #0
  movs pc, lr

invalidSonar_Callback:
  mov r0, #-2
  movs pc, lr

MoreThanMax_Callback:
  mov r0, #-1
  movs pc, lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@  Ajusta tempo do sistema.
@
@  Parametro:
@   r0: novo tempo do sistema.
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
set_time:
  ldr r1, =count_system
  str r0, [r1] @ Coloca em count_system novo tempo de sistema(r0)
  movs pc, lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Recupera tempo do sistema.
@
@   Parametro:
@     -
@
@   Saida:
@     r0: tempo do sistema
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
get_time:
  ldr  r1, =count_system
  ldr  r0, [r1]  @ Carrega o valor de count_system em r0
  movs pc,lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Muda velocidade do motor.
@
@   Parametro:
@     r0: Idenficador do motor
@     r1: Nova velocidade
@
@   Saida:
@     r0: -1 (id motor inválido)
@         -2 (velocidade inválida)
@          0 (default)
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
set_motor_speed:
  ldr r3, =GPIO_BASE
  ldr r2, [r3, #GPIO_DR]  @ Carrega valor de GPIO_DR em r2
  cmp r1, #0x3F           @ Compara com 111111 (6 bits)
  bhi invalid_speed       @ Se maior -> Salta para invalid_speed
  cmp r1, #0              @ Compara com 000000 (menor velocidade possível)
  blt invalid_speed       @ Se menor -> Salta para invalid_speed
  cmp r0, #1              @ Compara com 1
  beq set_motor1          @ Se igual -> Salta para set_motor1
  cmp r0, #0              @ Compara com 0
  beq set_motor0          @ Se igual -> Salta para set_motor0
  b   invalid_motor       @ Se não é motor 1 e não é motor 0 -> salta para invalid_motor

invalid_speed:
  mov  r0, #-2            @ Retorna -2 caso velocidade inválida
  movs pc, lr

invalid_motor:
  mov  r0, #-1            @ Retorna -1 caso motor inválido
  movs pc, lr

set_motor1:
  bic  r2, r2, #0xFE000000  @ Limpa bits 31-25 (bits da velocidade + write_motor1) do GPIO_DR
  orr  r2, r2, #0x2000000   @ Bit(25) = 1, setando mortor1_write
  mov  r1, r1, ror #6       @ Rotaciona o valor da velocidade 6 vezes para coincidir com os bits do GPIO (31-26)
  orr  r1, r2, r1           @ OR da velocidade rotacionada com vetor GPIO_DR (após BIC)
  str  r1, [r3, #GPIO_DR]   @ Escreve valor no GPIO_GDIR
  bic  r1, r1, #0x2000000   @ Bit(25) = 0, mortor1_write = 0
  str  r1, [r3, #GPIO_DR]   @ Escreve em GPIO_GDIR

  mov  r0, #0               @ Valor de retorno 0
  movs pc, lr               @ Retorna fluxo

set_motor0:
  bic  r2, r2, #0x1FC0000   @ Limpa bits 24-18 (bits da velocidade + write_motor0) do GPIO_DR
  orr  r2, r2, #0x0040000   @ Bit(18) = 1, setando mortor0_write
  mov  r1, r1, lsl #19      @ Logical left 19 casas para coincidir com bits de velocidade do GPIO_DR (24-19)
  orr  r1, r2, r1           @ OR da velocidade rotacionada com vetor GPIO_DR (após BIC)
  str  r1, [r3, #GPIO_DR]   @ Escreve valor no GPIO_GDIR
  bic  r1, r1, #0x0040000   @ Bit(18) = 0, mortor0_write = 0
  str  r1, [r3, #GPIO_DR]   @ Escreve em GPIO_GDIR

  mov  r0, #0               @ Valor de retorno 0
  movs pc, lr               @ Retorna fluxo


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Muda velocidade dos motores.
@
@   Parametro:
@     r0: Velocidade motor 0 (v0)
@     r1: Velocidade motor 1 (v1)
@
@   Saida:
@     r0: -1 (velocidade_motor0 inválida)
@         -2 (velocidade_motor1 inválida)
@          0 (default)
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
set_motors_speed:
  cmp r1, #0x3F             @ Compara v1 com 111111 (6 bits)
  bhi invalid_m1speed       @ Se maior -> Salta para invalid_m1speed
  cmp r1, #0
  blt invalid_m1speed
  cmp r0, #0x3F             @ Compara v0 com 111111 (6 bits)
  bhi invalid_m0speed       @ Se maior -> Salta para invalid_m0speed
  cmp r0, #0
  blt invalid_m0speed

  ldr  r3, =GPIO_BASE
  ldr  r2, [r3, #GPIO_DR]   @ Carrega valor de GPIO_DR em r2
  ldr  r3, =0xFFFC0000      @ Mascara para BIC
  bic  r2, r2, r3           @ Limpa bits 31-18 (bits da velocidade + write_motors de ambos motores) do GPIO_DR
  ldr  r3, =GPIO_BASE
  orr  r2, r2, #0x2040000   @ Bit(25) = Bit(18) = 1, setando mortor1_write e motor0_write
  mov  r1, r1, ror #6       @ Rotaciona o valor da velocidade1 6 vezes para coincidir com os bits do GPIO (31-26)
  mov  r0, r0, lsl #19      @ Logical left 19 casas para coincidir com bits de velocidade0 do GPIO_DR (24-19)
  orr  r2, r2, r1           @ OR da velocidade1 rotacionada com vetor GPIO_DR (após BIC)
  orr  r2, r2, r0           @ OR da velocidade0 após logical shift com vetor GPIO_DR (após BIC e já com velocidade 1)

  str  r2, [r3, #GPIO_DR]   @ Escreve em GPIO_DR
  bic  r2, r2, #0x2040000   @ Bit(25) = Bit(18) = 0, mortor1_write = motor0_write = 0
  str  r2, [r3, #GPIO_DR]   @ Escreve em GPIO_GDIR

  mov  r0, #0               @ Valor de retorno 0
  movs pc, lr               @ Retorna fluxo

invalid_m0speed:
  mov r0, #-1               @ Retorna -1 caso v0 inválida
  movs pc, lr

invalid_m1speed:
  mov r0, #-2               @ Retorna -2 caso v0 inválida
  movs pc, lr

change_irq_mode:
  msr  CPSR_c, #IRQ_M
  mov  pc, lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
@ Realiza o delay necessário em algumas partes
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
delay:
  stmfd sp!, {r0-r2, lr}    @ Salva na pilha os registradores que serão sujos

  mov r0, #100              @ Carrega o valor 200 em r0
  mov r1, #1                @ Carrega o valor 1 em r1
  mov r2, #0                @ Carrega o valor 0 em r2

loop:
  sub r0, r0, r1            @ Subtrai 1 de r0

  cmp r0, r2                @ Compara o valor de r0 com r2
  bgt loop                  @ Se maio -> Refaz loop, se igual -> segue o fluxo


  ldmfd sp!, {r0-r2, pc}    @ Retorna o fluxo de execução anterior a função.


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@                                                                                 .data                                                                                                               @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

.data

supervisor_stack:
  .skip 1024
supervisor_stack_pointer:

count_system:
  .word 0

irq_stack:
  .skip 1024
irq_stack_pointer:

user_stack:
  .skip 1024
user_stack_pointer:

alarmsInUse:                  @ Pilha para os alarmes ativados.
  .word 0

alarmsTime:                   @ Tempo dos alarmes ativados, que possuem a mesma indexação da pilha alarmsInUse
  .skip MAX_ALARMS * 4

alarmsAdress:
  .skip MAX_ALARMS * 32

callbacksInUse:               @ Pilha para as callbacks ativadas.
  .word 0

callbacksSonarID:             @ ID do sonar respectivo da callback ativada. Mesma indexação da pilha callbacksInUse
  .skip MAX_CALLBACKS * 4

callbacksDistance:            @ Limiar de distância da respectiva callback ativada. Mesma indexação da pilha callbacksInUse e callbacksSonarID
  .skip MAX_CALLBACKS * 12

callbacksAdress:
  .skip MAX_CALLBACKS * 32

