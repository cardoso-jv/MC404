.set CODIGO 0x000
.set Var 0x020
.set DADOS 0X3FD

.org CODIGO
	LOAD M(t)
	SUB M(count)
	STOR M(t)
laco:
	LOAD M(v1)
	STA M(f1)
	ADD M(count)
	STOR M(v1)
f1:	LOAD MQ, M(000)
	LOAD M(v2)
	STA M(f2	)
	ADD M(count)
	STOR M(v2)
f2:	MUL M(000)
	LOAD MQ
	ADD M(soma)
	STOR M(soma)
	LOAD M(t)
	SUB M(count)
	STOR M(t)
	JUMP+ M(laco, 20:39)
fim_de_laco:
	LOAD M(soma)
	JUMP M(0x400)

.org Var
soma:
	.word 0x00 
count:
	.word 0x01

.org DADOS
v1: .skip 0x01
v2: .skip 0x01
t:  .skip 0x01