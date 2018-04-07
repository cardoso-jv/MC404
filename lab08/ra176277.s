@ Global symbol
.global ajudaORobinson


.align 4

ajudaORobinson:
  stmfd sp!, {r4-r11, lr}	@ Save the callee-save registers and the return address.

  bl 		inicializaVisitados

  bl		posicaoXLocal
  mov 	r2, r0
  bl 		posicaoYLocal
	mov 	r3, r0


	bl 		posicaoYRobinson
	mov 	r1, r0
	bl 		posicaoXRobinson


  bl 		ajudaRecursiva





  ldmfd sp!, {r4-r11, pc} @ Restore the registers and return

ajudaRecursiva:
  stmfd sp!, {r4-r11, lr}	@ Save the callee-save registers and the return address.


  mov r6, r2 @ posicaoXLocal r6
  mov r7, r3 @ posicaoYLocal r7

  mov r4, r0 @ posicaoXRobinson r4
  mov r5, r1 @ posicaoYRobinson r5

  cmp r6, r4



  @Verifica Superior Esquerda
  mov r0, r4, #-1
  mov r0, r4, #-1
  bl daParaPassar

  ldmfd sp!, {r4-r11, pc} @ Restore the registers and return


proxPosicao:
	stmfd sp!, {r4-r11, lr} @ Restore the	registers and return





