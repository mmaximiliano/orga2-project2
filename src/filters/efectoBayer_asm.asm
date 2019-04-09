; void efectoBayer_asm (unsigned char *src, unsigned char *dst , int cols, int filas,
;                       int src_row_size, int dst_row_size);

azul_mask: 	db 0xff, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0xff
verde_mask: db 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff
rojo_mask: 	db 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff
;unsigned char *src: rdi, unsigned char *dst:rsi, int width edx, int height ecx, int src_row_size r8d, int dst_row_size r9d


global efectoBayer_asm
efectoBayer_asm:
	push rbp					;alineada
	mov rbp, rsp

	push r12
	push r13
	push r14
	push r15

;limpiamos parte alta de los parametros
	mov edx, edx 								;rdx = #columnas
	mov r8, rdx 								;r8 = #columnas
	mov ecx, ecx								;rcx = filas

	;cargamos las mascaras
	movdqu xmm0, [azul_mask]
	movdqu xmm1, [verde_mask]
	movdqu xmm8, [rojo_mask]

	xor r12, r12 ;Fila actual
	xor r13, r13 ;Columna actual (j)


	mov r11, rcx ;iterador inverso filas (i)
	dec r11
	; mov r10, r8 ; iterador inverso columnas (j)
	; dec r10
	mov r14, 8 ; para hacer mod

.cicloFila:
	cmp r12d, ecx
	je .fin
.cicloCol:
	cmp r13d, r8d
	je .siguienteFila


	;calculo en que posicion de la matriz estoy trabajando
	mov eax, r12d								;eax = fila actual
	mul r8d										;edx:eax = fila actual * #columnas
	mov edx, edx
	mov eax, eax
	shl rdx, 32
	add rax, rdx
	add rax, r13								;eax = col act + (fila *#col)
	shl rax, 2									;eax = ubicador

	mov r9, rax									;r9 = ubicador

	xor edx, edx
	mov eax, r13d
	div r14										;divido j por 8 para ver el modulo
	cmp edx, 0
	jne .azul 									;fila que tiene pixeles verdes y azules

.rojo: 											; fila con pixeles verdes y rojos
	xor edx, edx
	mov eax, r11d
	div r14										;divido i por 8 para ver el modulo
	cmp edx, 3
	jg .verde
	movdqu xmm4, [rdi+r9]
	pand xmm4, xmm8
	movdqu [rsi + r9], xmm4
	jmp .finCicloCol

.azul:
	xor edx, edx
	mov eax, r11d
	div r14										;divido i por 8 para ver el modulo
	cmp edx, 3
	jle .verde
	movdqu xmm4, [rdi+r9]
	pand xmm4, xmm0
	movdqu [rsi + r9], xmm4
	jmp .finCicloCol

.verde:
	movdqu xmm4, [rdi+r9]
	pand xmm4, xmm1
	movdqu [rsi + r9], xmm4

.finCicloCol:
	add r13d, 4
	; sub r10d, 4
	jmp .cicloCol
.siguienteFila:
	inc r12d			;actualizo iteradores de fila
	dec r11d
	xor r13, r13			;;reseteo iteradores de columna
	; mov r10, r8 ; iterador inverso columnas
	jmp .cicloFila

 .fin:
 	pop r15
 	pop r14
 	pop r13
 	pop r12
 	pop rbp
	ret
