.set CODIGO 0x000
.set Var 0x101

.org CODIGO
	LOAD MQ, M(dado)
	MUL M(g)
	LOAD MQ
	STOR M(dado)
	RSH
	STOR M(k)
laco:
	LOAD M(dado)
	DIV M(k)
	LOAD MQ
	ADD M(k)
	RSH
	STOR M(k)
	LOAD M(i)
	SUB M(count)
	STOR M(i)
	JUMP+ M(laco)

	LOAD M(k)
	JUMP M(0x400)



.org Var
g:
	.word 0x0A
i:
	.word 0x09
count:
	.word 0x01
k:
	.skip 0x01
dado:
	.skip 0x01