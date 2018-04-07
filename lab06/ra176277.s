.globl _start

.data

input_buffer:   .skip 32
output_buffer:  .skip 32
    
.text
.align 4

@ Funcao inicial
_start:
    @ Chama a funcao "read" para ler 4 caracteres da entrada padrao
    ldr r0, =input_buffer
    mov r1, #5             @ 4 caracteres + '\n'
    bl  read
    mov r4, r0             @ copia o retorno para r4.

    @ Chama a funcao "atoi" para converter a string para um numero
    ldr r0, =input_buffer
    mov r1, r4
    bl  atoi

    @ Chama a funcao "encode" para codificar o valor de r0 usando
    @ o codigo de hamming.
    bl  encode
    mov r4, r0             @ copia o retorno para r4.
	
    @ Chama a funcao "itoa" para converter o valor codificado
    @ para uma sequencia de caracteres '0's e '1's
    ldr r0, =output_buffer
    mov r1, #7
    mov r2, r4
    bl  itoa

    @ Adiciona o caractere '\n' ao final da sequencia (byte 7)
    ldr r0, =output_buffer
    mov r1, #'\n'
    strb r1, [r0, #7]

    @ Chama a funcao write para escrever os 7 caracteres e
    @ o '\n' na saida padrao.
    ldr r0, =output_buffer
    mov r1, #8         @ 7 caracteres + '\n'
    bl  write
    
    @--------------------------------------------------------------------

    @ Chama a funcao "read" para ler 7 caracteres da entrada padrao
    ldr r0, =input_buffer
    mov r1, #8             @ 7 caracteres + '\n'
    bl  read
    mov r4, r0             @ copia o retorno para r4.

    @ Chama a funcao "atoi" para converter a string para um numero
    ldr r0, =input_buffer
    mov r1, r4
    bl  atoi

    @ Chama a funcao "encode" para codificar o valor de r0 usando
    @ o codigo de hamming.
    bl  decode
    mov r4, r0             @ copia o retorno de r0 para r4.
    mov r6, r1             @ copia o retorno de r1 para r6
  
    @ Chama a funcao "itoa" para converter o valor codificado
    @ para uma sequencia de caracteres '0's e '1's
    ldr r0, =output_buffer
    mov r1, #4
    mov r2, r4
    bl  itoa

    @ Adiciona o caractere '\n' ao final da sequencia (byte 4)
    ldr r0, =output_buffer
    mov r1, #'\n'
    strb r1, [r0, #4]

    @ Chama a funcao write para escrever os 4 caracteres e
    @ o '\n' na saida padrao.
    ldr r0, =output_buffer
    mov r1, #5         @ 4 caracteres + '\n'
    bl  write

    @--------------------------------------------------------------------

    @ Chama a funcao "itoa" para converter o valor codificado
    @ para uma sequencia de caracteres '0's e '1's
    ldr r0, =output_buffer
    mov r1, #1
    mov r2, r6
    bl  itoa

    @ Adiciona o caractere '\n' ao final da sequencia (byte 4)
    ldr r0, =output_buffer
    mov r1, #'\n'
    strb r1, [r0, #1]

    @ Chama a funcao write para escrever os 4 caracteres e
    @ o '\n' na saida padrao.
    ldr r0, =output_buffer
    mov r1, #2         @ 4 caracteres + '\n'
    bl  write
    
    @ Chama a funcao exit para finalizar processo.
    mov r0, #0
    bl  exit

@ Codifica o valor de entrada usando o codigo de hamming.
@ parametros:
@  r0: valor de entrada (4 bits menos significativos)
@ retorno:
@  r0: valor codificado (7 bits como especificado no enunciado).
encode:    

   push {r4-r11, lr}
       
   @r0 = d1 d2 d3 d4
   @r0 = 3   2  1  0  --- indices de rotação

   mov r3, #0 @ Zera r3

   @p1 = d1 XOR d2 XOR d4

   mov r4, r0 @ Copia Valor de r0 para r4
   eor r4, r4, r0, ror #3 @ d4 XOR d1
   eor r4, r4, r0, ror #2 @ d2 XOR d4 XOR d1
   and r4, r4, #1 @ r4 AND 1 == ultimo digito de r4 (p1)
   orr r3, r4, lsl #6 @Coloca p1 no 6º digito de r3

   @p2 = d1 XOR d3 XOR d4

   mov r4, r0 @ Copia Valor de r0 para r4
   eor r4, r4, r0, ror #1 @ d4 XOR d3
   eor r4, r4, r0, ror #3 @ d1 XOR d4 XOR d3
   and r4, r4, #1 @ r4 AND 1 == ultimo digito de r4 (p2)
   orr r3, r4, lsl #5 @ Coloca p2 no 5º digito de r3

   @p3 = d2 XOR d3 XOR d4	

   mov r4, r0 @ Copia Valor de r0 para r4
   eor r4, r4, r0, ror #2 @ d4 XOR d2
   eor r4, r4, r0, ror #1 @ d3 XOR d4 XOR d2
   and r4, r4, #1
   orr r3, r4, lsl #3 @ Coloca p3 no 3º digito de r3

   @saida = p1 p2 d1 p3 d2 d3 d4

   @r3 = p1 p2 - p3 - - -

   mov r4, r0
   and r4, #8 @seleciona somente d1 
   orr r3, r4, lsl #1 @ Coloca d1 no 4º digito de r3
   mov r4, r0
   and r4, #7 @ Seleciona d2, d3, d4
   orr r3, r4 @ Coloca d2, d3, d4 nos ultimos digitos de r3

   mov r0, r3 @ Coloca saida em r0

   pop  {r4-r11, lr}
   mov  pc, lr

@ Decodifica o valor de entrada usando o codigo de hamming.
@ parametros:
@  r0: valor de entrada (7 bits menos significativos)
@ retorno:
@  r0: valor decodificado (4 bits como especificado no enunciado).
@  r1: 1 se houve erro e 0 se nao houve.
decode:    
   push {r4-r11, lr}

   mov r3, r0
   mov r1, r0

   @decodifica

   and r3, r3, #7  @ r3 = 0 0 0  0 d2 d3 d4
   and r1, r1, #16 @ r1 = 0 0 d1 0 0  0  0
   orr r3, r3, r1, lsr #1 @r3 = 0 0 0 d1 d2 d3 d4

   @Acha erro
   
   @r0 = p1 p2 d1 p3 d2 d3 d4
   @r0 =  6  5  4  3  2  1  0   ---- indices de rotação 

   mov r4, r0 @ Copia r0 em r4
   eor r4, r4, r0, ror #2 
   eor r4, r4, r0, ror #4
   eor r4, r4, r0, ror #6
   and r1, r4, #1
   
   mov r4, r0
   eor r4, r4, r0, ror #1
   eor r4, r4, r0, ror #4
   eor r4, r4, r0, ror #5
   and r4, r4, #1
   orr r1, r1, r4

   mov r4, r0
   eor r4, r4, r0, ror #1
   eor r4, r4, r0, ror #2
   eor r4, r4, r0, ror #3
   and r4, r4, #1
   orr r1, r1, r4

   mov r0, r3

   pop  {r4-r11, lr}
   mov  pc, lr

@ Le uma sequencia de bytes da entrada padrao.
@ parametros:
@  r0: endereco do buffer de memoria que recebera a sequencia de bytes.
@  r1: numero maximo de bytes que pode ser lido (tamanho do buffer).
@ retorno:
@  r0: numero de bytes lidos.
read:
    push {r4,r5, lr}
    mov r4, r0
    mov r5, r1
    mov r0, #0         @ stdin file descriptor = 0
    mov r1, r4         @ endereco do buffer
    mov r2, r5         @ tamanho maximo.
    mov r7, #3         @ read
    svc 0x0
    pop {r4, r5, lr}
    mov pc, lr

@ Escreve uma sequencia de bytes na saida padrao.
@ parametros:
@  r0: endereco do buffer de memoria que contem a sequencia de bytes.
@  r1: numero de bytes a serem escritos
write:
    push {r4,r5, lr}
    mov r4, r0
    mov r5, r1
    mov r0, #1         @ stdout file descriptor = 1
    mov r1, r4         @ endereco do buffer
    mov r2, r5         @ tamanho do buffer.
    mov r7, #4         @ write
    svc 0x0
    pop {r4, r5, lr}
    mov pc, lr

@ Finaliza a execucao de um processo.
@  r0: codigo de finalizacao (Zero para finalizacao correta)
exit:    
    mov r7, #1         @ syscall number for exit
    svc 0x0

@ Converte uma sequencia de caracteres '0' e '1' em um numero binario
@ parametros:
@  r0: endereco do buffer de memoria que armazena a sequencia de caracteres.
@  r1: numero de caracteres a ser considerado na conversao
@ retorno:
@  r0: numero binario
atoi:
    push {r4, r5, lr}
    mov r4, r0         @ r4 == endereco do buffer de caracteres
    mov r5, r1         @ r5 == numero de caracteres a ser considerado 
    mov r0, #0         @ number = 0
    mov r1, #0         @ loop indice
atoi_loop:
    cmp r1, r5         @ se indice == tamanho maximo
    beq atoi_end       @ finaliza conversao
    mov r0, r0, lsl #1 
    ldrb r2, [r4, r1]  
    cmp r2, #'0'       @ identifica bit
    orrne r0, r0, #1   
    add r1, r1, #1     @ indice++
    b atoi_loop
atoi_end:
    pop {r4, r5, lr}
    mov pc, lr

@ Converte um numero binario em uma sequencia de caracteres '0' e '1'
@ parametros:
@  r0: endereco do buffer de memoria que recebera a sequencia de caracteres.
@  r1: numero de caracteres a ser considerado na conversao
@  r2: numero binario
itoa:
    push {r4, r5, lr}
    mov r4, r0
itoa_loop:
    sub r1, r1, #1         @ decremento do indice
    cmp r1, #0          @ verifica se ainda ha bits a serem lidos
    blt itoa_end
    and r3, r2, #1
    cmp r3, #0
    moveq r3, #'0'      @ identifica o bit
    movne r3, #'1'
    mov r2, r2, lsr #1  @ prepara o proximo bit
    strb r3, [r4, r1]   @ escreve caractere na memoria
    b itoa_loop
itoa_end:
    pop {r4, r5, lr}
    mov pc, lr    

