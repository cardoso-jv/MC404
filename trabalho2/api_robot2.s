.global set_time, set_motor_speed, set_motors_speed
.global read_sonar, read_sonars, register_proximity_callback
.global add_alarm, get_time

.text
.align 4

/**************************************************************/
/* 												Motors - Correto                    */
/**************************************************************/
set_motor_speed:
	stmfd 	sp!, {r7, lr}	@ Save the callee-save registers and the return address.

	ldrb 		r1, [r0, #1]  @ Load motor_cfg_t.speed in r1
	ldrb 		r0, [r0]			@ Move motor_cfg_t.id in r0

	mov  		r7, #18				@ ID for set_motor_speed svc
	svc 		0x0						@ Call svc

	ldmfd 	sp!, {r7, pc} @ Restore the registers and return


set_motors_speed:
	stmfd 	sp!, {r7, lr}		@ Save the callee-save registers and the return address.

	mov 		r3, r1					@ Move Pointer_Struct(m2) to r3

	ldrb 		r2, [r0] 				@ Load motor_cfg_t.id(m1)
	cmp   	r2, #0					@ Compare with 0
	ldreqb	r0, [r0, #1]		@ Is equal to 0, load motor_cfg_t.speed(m1) in r1
	ldrhib  r1, [r0, #1]		@ If higher than 0, load motor_cfg_t.speed(m1) in r0

	ldrb 		r2, [r3]				@ Follow steps above motor_cfg_t (m2)
	cmp 		r2, #0
	ldreqb	r0, [r3, #1]
	ldrhib  r1, [r3, #1]

	mov 		r7, #19					@ ID for set_motors_speed svc
	svc 		0x0							@ Call svc

	ldmfd 	sp!, {r7, pc} 	@ Restore the registers and return


/**************************************************************/
/* 										  	Sonars                              */
/**************************************************************/
read_sonar:
	stmfd 	sp!, {r7, lr}		@ Save the callee-save registers and the return address.

	mov 		r7, #16 				@ ID for read_sonar svc
	svc			0x0

	ldmfd sp!, {r7, pc} 		@ Restore the registers and return


read_sonars:
	stmfd 	sp!, {r4-r6, lr}		@ Save the callee-save registers and the return address.

	mov r4, r0									@ Move Start ID_Sonar(r0) to r4
	mov r5, r1									@ Move Last ID_Sonar(r1) to r5
	ldr r6, [r2]								@ Load Pointer_Array
	sub r6, r6, #4							@ Adjust Pointer_Array
	laco:
		bl read_sonar							@ Call read_sonar
		str r0, [r6], #4					@ Store r0 (return of read_sonar) in [r6]+4 and att [r6]
		add r4, r4, #1						@ Add 1 to get ID_nextSonar
		mov r0, r4 								@ Move next ID_Sonar to r0
		cmp r0, r5								@ Compare r0 to r5 (Last sonar)
		bhi laco									@ Jump to laco if r0>r5

	ldmfd sp!, {r4-r6, pc} 			@ Restore the registers and return


register_proximity_callback:
	stmfd 	sp!, {r7, lr}		@ Save the callee-save registers and the return address.

	mov r7, #17 						@ ID for register_proximity_callback svc
	svc 0x0

	ldmfd sp!, {r7, pc} 		@ Restore the registers and return


/**************************************************************/
/*                         Timer                              */
/**************************************************************/
add_alarm:
	stmfd 	sp!, {r7, lr}		@ Save the callee-save registers and the return address.

	mov r7, #22
	svc 0x0

	ldmfd sp!, {r7, pc} 		@ Restore the registers and return


get_time:
	stmfd 	sp!, {r6, r7, lr}		@ Save the callee-save registers and the return address.

	mov r6, r0 								@ Load address will receive time system in r6

	mov r7, #20									@ ID for get_time svc
	svc 0x0

	str r0, [r6]								@ Store time_system

	ldmfd 	sp!, {r6, r7, pc} 	@ Restore the registers and return


set_time:
	stmfd 	sp!, {r7, lr}		@ Save the callee-save registers and the return address.

	mov r7, #21							@ ID for set_time svc
	svc 0x0

	ldmfd sp!, {r7, pc} 		@ Restore the registers and return

