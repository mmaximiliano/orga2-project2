;unsigned char *src: rdi, unsigned char *dst:rsi, int width edx, int height ecx, int src_row_size r8d, int dst_row_size r9d


; *src = rdi
; *dst = rsi
; cols = edx
; filas = ecx
; src row size = r8d
; dst row size = r9d

global edgeSobel_asm
edgeSobel_asm:
	push rbp									;alineada
	mov rbp, rsp
	push r12									;desalineada
	push r13									;alineada
	push r14									;desalineada
	sub rsp, 8									;alineada

	;limpio parte alta de los parametros 
	mov edx, edx 								; rdx = columnas
	mov ecx, ecx 								; rcx = filas
	mov r8d, r8d 								; r8 = src_row_size
	mov r9d, r9d								; r9 = dst_row_size

	mov r12, rdi								; r12 = *src
	mov r13, rsi								; r13 = *dst

	;empiezo desde la posicion (2,2) de la imagen
	lea rdi, [rdi + r8 + 1]
	lea rsi, [rsi + r8 + 1]

	;calculo el final de la matriz
	lea rax, [rcx - 2] 							; rax = filas -2
	imul r8										; rax = (filas-2)*src_row_size
	lea r9, [rdi + rax -17]
	;r9 = apunta a la posicion (N-2, M) de la matriz
	;sub r9, r8

	;calculo los punteros a las filas
	mov r10, rdi
	mov r11, rdi
	sub r10, r8
	add r11, r8
	;r10 = puntero a la fila anterior
	;rdi = puntero a la fila actual
	;r11 = puntero a la fila siguiente

	pxor xmm0, xmm0		;xmm0 = todos ceros


	;recorro la imagen
.ciclo:
	;traigo todos los pixeles necesarios:
	;↖ ↑ ↗ xmm1=xmm5	xmm2 xmm3
	;←   → xmm4 		     xmm6
	;↙ ↓ ↘ xmm7=xmm15 	xmm8 xmm9

	movdqu xmm1, [r10 - 1]	; xmm1 = ↖
	movdqu xmm5, xmm1		; xmm5 = ↖
	movdqu xmm2, [r10]		; xmm2 = ↑
	movdqu xmm3, [r10 + 1]	; xmm3 = ↗
	
	movdqu xmm4, [rdi - 1]	; xmm4 = ←
	movdqu xmm6, [rdi + 1] 	; xmm6 = →

	movdqu xmm7, [r11-1]	; xmm7  = ↙
	movdqu xmm15, xmm7		; xmm15 = ↙
	movdqu xmm8, [r11]		; xmm8  = ↓
	movdqu xmm9, [r11+1]	; xmm9  = ↘

	pxor xmm0, xmm0			;xmm0 = 0
	call operadorX
	; xmm1 = ↖0 + ←0 + ↙0 + ↗0 + →0 + ↘0
	; xmm4 = ↖1 + ←1 + ↙1 + ↗1 + →1 + ↘1

	pxor xmm0, xmm0			;xmm0 = 0
	call operadorY 
	; xmm5  = ↖0 + ↑0 + ↗0 + ↙0 + ↓0 + ↘0
	; xmm10 = ↖1 + ↑1 + ↗1 + ↙1 + ↓1 + ↘1

	;|OPERADOR x|
	pxor xmm6, xmm6			; xmm6 = 0
	pxor xmm7, xmm7			; xmm7 = 0
	;aplico modulo
	psubw xmm6, xmm1		; xmm6 = -xmm1
	pmaxsw xmm6, xmm1		; xmm6 = abs(xmm1)

	psubw xmm7, xmm4		; xmm7 = -xmm4
	pmaxsw xmm7, xmm4		; xmm7 = abs(xmm4)

	packuswb xmm6, xmm7		; xmm6 = abs(OPx)	

	;|OPERADOR Y|
	pxor xmm3, xmm3			; xmm3 = 0
	pxor xmm4, xmm4			; xmm4 = 0
	;aplico modulo
	psubw xmm3, xmm5		; xmm3 = -xmm5
	pmaxsw xmm3, xmm5		; xmm3 = abs(xmm5)

	psubw xmm4, xmm10		; xmm4 = -xmm10
	pmaxsw xmm4, xmm10		; xmm4 = abs(xmm10)
	
	packuswb xmm3, xmm4		; xmm3 = abs(OPy)

	;sumo resX con resY		
	paddusb xmm3, xmm6 		; res en xmm3

;guardo el resultado en rsi
	movdqu [rsi], xmm3

	; avanzo los punteros
	add rsi, 16
	add rdi, 16
	add r10, 16
	add r11, 16

	; si estoy antes del puntero al final, sigo iterando
	cmp rdi, r9
	jle .ciclo

	mov rax, r8
	imul rcx
	sub rax, r8
	add rax, r12
	sub rax, 1
	cmp rdi, rax
	je .seguir
	sub rax, 16
	mov rdi, rax
	mov rsi, r13
	add rsi, rdi
	sub rsi, r12
	mov r10, rdi
	mov r11, rdi
	sub r10, r8
	add r11, r8

	jmp .ciclo
	.seguir:
;-------------------------casos borde-------------------------------
	call bordeColumnas
	call bordeFilas

.fin:
	add rsp, 8
	pop r14
	pop r13
	pop r12
	pop rbp
	ret


;-------------------- Funciones auxiliares -----------------------

bordeColumnas:
	xor r10, r10
	xor r14, r14
	xor r12, r12




	mov r14d, r8d						; r14d= src_row_size
	dec r14								; r14 = src_row_size -1
	add r14, r13						; r14 = ultima columna
	mov r12, r13						; r12 = ultima fila

.ciclo:
	mov byte [r14], 0					; ultima columna = 0
	mov byte [r12], 0					; primer columna = 0
	
	add r12d, r8d
	add r14d, r8d
	inc r10
	cmp r10d, ecx
	jne .ciclo

.fin:
	ret


bordeFilas:
	xor rax, rax
	xor r9, r9
	xor r10, r10
	xor r12, r12
	xor r14, r14
	


	mov eax, r8d						; eax = src_row_size
	mov r9d, ecx						; r9d = filas
	dec r9d								; r9d = filas -1
	mul r9d								; rax = src_row_size * (filas -1)
	mov r12, r13						; r12 = primer fila
	mov r14d, eax						; r14d= |matriz|
	add r14, r13 						; r14 = ultima fila
	pxor xmm1, xmm1					

.ciclo:
	movdqu [r14], xmm1					; primer fila = 0
	movdqu [r12], xmm1					; ultima fila = 0
	add r14, 16
	add r12, 16
	add r10, 16
	cmp r10d, r8d
	jne .ciclo
.fin:
	ret

operadorX:
	; Usa:
	; ↖ ↑ ↗ xmm1 - xmm3			
	; ← . → xmm4 - xmm6		
	; ↙ ↓ ↘ xmm7 - xmm9			
	; xmm0 = 0

	; Preserva: 
	; xmm5  = ↖ xmm2 = ↑ xmm3 = ↗
	; xmm15 = ↙ xmm8 = ↓ xmm9 = ↘
	; xmm0 = 0


; extiendo precisión en los registros de la primer columna
	movdqu xmm10, xmm1			; xmm10 = ↖
	movdqu xmm11, xmm4			; xmm11 = ←
	movdqu xmm12, xmm7			; xmm12 = ↙

	punpcklbw xmm1, xmm0		; xmm1 = ↖0
	punpcklbw xmm4, xmm0		; xmm4 = ←0
	punpcklbw xmm7, xmm0		; xmm7 = ↙0

	punpckhbw xmm10, xmm0		; xmm10 = ↖1
	punpckhbw xmm11, xmm0		; xmm11 = ←1
	punpckhbw xmm12, xmm0		; xmm12 = ↙1

; Realizo las multiplicaciones de la parte baja

	; multiplico xmm1 por -1
	psubw xmm0, xmm1
	movdqu xmm1, xmm0			; multiplico xmm1 por -1
	pxor xmm0, xmm0				; xmm0 = 0

	; multiplico por 2 xmm4
	psllw xmm4, 1				; multiplico por 2
	;Mul xmm7, -1

	;los sumo todos
	Psubw xmm1, xmm4			; xmm1  = - ↖0 - ←0
	Psubw xmm1, xmm7			; xmm1  = - ↖0 - ←0 - ↙0

; Realizo las multiplicaciones de la parte alta
	; multiplico xmm10 por -1
	psubw xmm0, xmm10
	movdqu xmm10, xmm0			; multiplico xmm10 por -1
	pxor xmm0, xmm0				; xmm0 = 0
	;multiplico por 2 xmm1
	psllw xmm11, 1				; multiplico por 2
	;Mul xmm12, -1
	
	;los sumo todos
	Psubw xmm10, xmm11			; xmm10 = - ↖1 - ←1
	Psubw xmm10, xmm12			; xmm10 = - ↖1 - ←1 - ↙1

; extiendo precisión en la última columna
	Movdqu xmm12, xmm3			; xmm12 = ↗
	Movdqu xmm13, xmm6			; xmm13 = →
	Movdqu xmm14, xmm9			; xmm14 = ↘
	;me guardo xmm9 y xmm3 para poder recuperarlos despues
	movdqu xmm11, xmm9			; xmm11 = ↘
	movdqu xmm7, xmm3			; xmm7  = ↗

	Punpcklbw xmm3, xmm0		; xmm3 = ↗0
	Punpcklbw xmm6, xmm0		; xmm6 = →0
	Punpcklbw xmm9, xmm0		; xmm9 = ↘0

	Punpckhbw xmm12, xmm0		; xmm12 = ↗1
	Punpckhbw xmm13, xmm0		; xmm13 = →1
	Punpckhbw xmm14, xmm0		; xmm14 = ↘1

; Realizo las multiplicaciones de la parte baja

	;Mul xmm3, 1
	psllw xmm6, 1				;multiplico por 2
	;Mul xmm9, 1

	;los sumo todos
	Paddw xmm6, xmm3			; xmm6 = →0 + ↗0
	Paddw xmm6, xmm9			; xmm6 = ↗0 + →0 + ↘0

;Realizo las multiplicaciones de la parte alta

	;Mul xmm12, 1
	psllw xmm13, 1				;multiplico por 2
	;Mul xmm14, 1

	;los sumo todos	  
	Paddw xmm13, xmm12			; xmm13 = →1 +↗1 
	Paddw xmm13, xmm14			; xmm13 =↗1 + →1 + ↘1

	;recupero xmm9 y xmm3
	movdqu xmm9, xmm11			; xmm9 = ↘
	movdqu xmm3, xmm7			; xmm3 = ↗

; sumo todo (primer columna con la ultima)
	Paddw xmm1, xmm6			; xmm1  = ↖0 + ←0 + ↙0 + ↗0 + →0 + ↘0
	Paddw xmm10, xmm13			; xmm10 = ↖1 + ←1 + ↙1 + ↗1 + →1 + ↘1
	movdqu xmm4, xmm10			; xmm4  = ↖1 + ←1 + ↙1 + ↗1 + →1 + ↘1

	ret


operadorY:
	; Usa:
	; xmm5  = ↖ xmm2 = ↑ xmm3 = ↗
	; xmm15 = ↙ xmm8 = ↓ xmm9 = ↘
	; xmm0 = 0

	; Preserva:
	; xmm1 = ↖0 + ←0 + ↙0 + ↗0 + →0 + ↘0
	; xmm4 = ↖1 + ←1 + ↙1 + ↗1 + →1 + ↘1

; extiendo precisión en los registros de la primer fila
	Movdqu xmm10, xmm5			; xmm10 = ↖
	Movdqu xmm11, xmm2			; xmm11 = ↑
	Movdqu xmm12, xmm3			; xmm12 = ↗

	Punpcklbw xmm5, xmm0		; xmm5 = ↖0
	Punpcklbw xmm2, xmm0		; xmm2 = ↑0
	Punpcklbw xmm3, xmm0		; xmm3 = ↗0

	Punpckhbw xmm10, xmm0		; xmm10 = ↖1
	Punpckhbw xmm11, xmm0		; xmm11 = ↑1
	Punpckhbw xmm12, xmm0		; xmm12 = ↗1

; Realizo las multiplicaciones de la parte baja
	pxor xmm0, xmm0				; xmm0 = 0
	psubw xmm0, xmm5			
	movdqu xmm5, xmm0			; mulplico xmm5 por -1
	pxor xmm0, xmm0				; xmm0 = 0
	;Mul xmm5, -1
	psllw xmm2, 1				; multiplico por 2
	;Mul xmm3, -1

	; los sumo todos
	psubw xmm5, xmm2			; xmm5  = - ↖0 - ↑0
	psubw xmm5, xmm3			; xmm5  = - ↖0 - ↑0 - ↗0

; Realizo las multiplicaciones de la parte alta
	psubw xmm0, xmm10			
	movdqu xmm10, xmm0			; mulplico xmm10 por -1
	pxor xmm0, xmm0				; xmm0 = 0
	;Mul xmm10, -1
	psllw xmm11, 1				; multiplico por 2
	;Mul xmm12, -1


	; los sumo todos
	psubw xmm10, xmm11			; xmm10 = - ↖1 - ↑1
	psubw xmm10, xmm12			; xmm10 = - ↖1 - ↑1 - ↗1

; extiendo precisión en la última fila:
	movdqu xmm12, xmm15			; xmm12 = ↙
	movdqu xmm13, xmm8			; xmm13 = ↓
	movdqu xmm14, xmm9			; xmm14 = ↘

	punpcklbw xmm15, xmm0		; xmm15 = ↙0
	punpcklbw xmm8, xmm0		; xmm8  = ↓0
	punpcklbw xmm9, xmm0		; xmm9  = ↘0

	punpckhbw xmm12, xmm0		; xmm12 = ↙1
	punpckhbw xmm13, xmm0		; xmm13 = ↓1
	punpckhbw xmm14, xmm0		; xmm14 = ↘1

; Realizo las multiplicaciones de la parte baja
	;Mul xmm15, 1
	psllw xmm8, 1				;multiplico por 2
	;Mul xmm9, 1

	;los sumo todos
	paddw xmm15, xmm8			; xmm15  = ↙0 + ↓0
	paddw xmm15, xmm9			; xmm15  = ↙0 + ↓0 + ↘0

; Realizo las multiplicaciones de la parte alta
	;Mul xmm12, 1
	psllw xmm13, 1				;multiplico por 2
	;Mul xmm14, 1

	;los sumo todos
	paddw xmm12, xmm13			; xmm12 = ↙1 + ↓1
	paddw xmm12, xmm14			; xmm12 = ↙1 + ↓1 + ↘1

; sumo todo (primer fila con la ultima fila)
	paddw xmm5, xmm15			; xmm5  = ↖0 + ↑0 + ↗0 + ↙0 + ↓0 + ↘0
	paddw xmm10, xmm12			; xmm10 = ↖1 + ↑1 + ↗1 + ↙1 + ↓1 + ↘1

	ret