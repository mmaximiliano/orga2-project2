;section .rodata
;mascaras que no usamos:

setalphato0: 	db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00
setalphato255: 	db 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF 
divisor4: db 0x04, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00
join_mask: 		db 0x00, 0x01, 0xFF, 0xFF, 0x02, 0x03, 0xFF, 0xFF, 0x08, 0x09, 0xFF, 0xFF, 0x0A, 0x0B, 0xFF, 0xFF
test_mask:	db 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0xFF		

;mascaras que se pueden hacer in-place facil
invert_mask:	db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
divisor3: 		db 0x03, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00

;de este podemos hacer 1 y shiftear
red_mask: 	db 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0x01, 0xFF, 0xFF, 0xFF, 0x02, 0xFF, 0xFF, 0xFF, 0x03, 0xFF 
green_mask: db 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0x01, 0xFF, 0xFF, 0xFF, 0x02, 0xFF, 0xFF, 0xFF, 0x03, 0xFF, 0xFF
blue_mask:  db 0x00, 0xFF, 0xFF, 0xFF, 0x01, 0xFF, 0xFF, 0xFF, 0x02, 0xFF, 0xFF, 0xFF, 0x03, 0xFF, 0xFF, 0xFF

color_mask85: 	db 0x55, 0x00, 0x00, 0x00, 0x55, 0x00, 0x00, 0x00, 0x55, 0x00, 0x00, 0x00, 0x55, 0x00, 0x00, 0x00
color_mask170: 	db 0xAA, 0x00, 0x00, 0x00, 0xAA, 0x00, 0x00, 0x00, 0xAA, 0x00, 0x00, 0x00, 0xAA, 0x00, 0x00, 0x00

;mascaras que usamos

rojoR: db 0xDC, 0x02, 0x00, 0x00, 0xDC, 0x02, 0x00, 0x00, 0xDC, 0x02, 0x00, 0x00, 0xDC, 0x02, 0x00, 0x00
rojoG: db 0x08, 0x01, 0x00, 0x00, 0x08, 0x01, 0x00, 0x00, 0x08, 0x01, 0x00, 0x00, 0x08, 0x01, 0x00, 0x00
rojoB: db 0xC3, 0x00, 0x00, 0x00, 0xC3, 0x00, 0x00, 0x00, 0xC3, 0x00, 0x00, 0x00, 0xC3, 0x00, 0x00, 0x00

verdeR: dw 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
verdeG: db 0x50, 0x01, 0x00, 0x00, 0x50, 0x01, 0x00, 0x00, 0x50, 0x01, 0x00, 0x00, 0x50, 0x01, 0x00, 0x00
verdeB: db 0x4A, 0x01, 0x00, 0x00, 0x4A, 0x01, 0x00, 0x00, 0x4A, 0x01, 0x00, 0x00, 0x4A, 0x01, 0x00, 0x00

cremaR: db 0xC4, 0x02, 0x00, 0x00, 0xC4, 0x02, 0x00, 0x00, 0xC4, 0x02, 0x00, 0x00, 0xC4, 0x02, 0x00, 0x00
cremaG: db 0xBB, 0x02, 0x00, 0x00, 0xBB, 0x02, 0x00, 0x00, 0xBB, 0x02, 0x00, 0x00, 0xBB, 0x02, 0x00, 0x00
cremaB: db 0x82, 0x02, 0x00, 0x00, 0x82, 0x02, 0x00, 0x00, 0x82, 0x02, 0x00, 0x00, 0x82, 0x02, 0x00, 0x00

; total de mascaras: 10 --> nos quedan 6 para usar
;xmm0 a xmm5: uso libre // xmm6 a xmm15: mascaras
;cada pı́xel en memoria se guarda en el siguiente orden: B, G, R, A.

global tresColores_asm

;*src: rdi, *dst:rsi, int width edx, int height ecx
tresColores_asm:
	push rbp					;alineada
	mov rbp, rsp
	push r12					;desalineada
	push r13					;alineada

;limpiamos parte alta de los parametros
	mov edx, edx 								;rdx = #columnas
	mov r8, rdx 								;r8 = #columnas
	mov ecx, ecx								;rcx = #filas

	xor r12, r12 ;Fila actual
	xor r13, r13 ;Columna actual

;cargo mascaras
	movdqu xmm6, [cremaR] ; xmm6 = mask
	movdqu xmm7, [cremaG] ; xmm7 = mask
	movdqu xmm8, [cremaB] ; xmm8 = mask
	movdqu xmm9, [verdeR] ; xmm9 = mask
	movdqu xmm10, [verdeG] ; xmm10 = mask
	movdqu xmm11, [verdeB] ; xmm11 = mask
	movdqu xmm12, [rojoR] ; xmm12 = mask
	movdqu xmm13, [rojoG] ; xmm13 = mask
	movdqu xmm14, [rojoB] ; xmm14 = mask
	movdqu xmm15, [red_mask] ; xmm15 = mask

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
	add rax, r13								;rax = col act + (fila *#col)
	shl rax, 2									;rax = ubicador

	mov r9, rax									;r9 = ubicador
;-----------------------Operaciones con datos-------------------------------

	movdqu xmm5, [rdi+r9] 						;original en xmm5
	movdqu xmm0, xmm5							;xmm0 = p3 | p2 | p1 | p0
	movdqu xmm1, xmm5							;xmm1 = xmm0
	pxor xmm2, xmm2								;xmm2 = 0
	
	punpcklbw xmm0, xmm2						;desempaqueto parte baja xmm0 = [0|a|0|r|0|g|0|b|0|a|0|r|0|g|0|b] (b->w) = [p1|p0]
	punpckhbw xmm1, xmm2						;desempaqueto parte alta xmm1 = [0|a|0|r|0|g|0|b|0|a|0|r|0|g|0|b] (b->w) = [p3|p2]

	;seteo alpha en 0 para poder sumar horizontal
	psllq xmm0, 16
	psrlq xmm0, 16
	psllq xmm1, 16
	psrlq xmm1, 16

	phaddw xmm0, xmm0 					;sumo 2 veces para hacer r+g+b = s
	phaddw xmm0, xmm0					;xmm0 = x|x|x|x|x|x|s1|s0

	phaddw xmm1, xmm1
	phaddw xmm1, xmm1					;xmm1 = x|x|x|x|x|x|s3|s2

	;hasta aca tengo en 2 registros 2 pixeles con sus respectivos s
	
	pslldq xmm1, 4		 				;xmm1 = x|x|x|x|s3|s2|0|0
	pblendw xmm0, xmm1, 11111100b		;xmm0 = x|x|x|x|s3|s2|s1|s0 
 	punpcklwd xmm0, xmm2				;xmm0 = 0|s3|0|s2|0|s1|0|s0

	cvtdq2ps xmm0, xmm0 				;convierto los 4 s a single FP

	;genero divisor3
	mov r10d, 3
	pinsrd xmm2, r10d, 0					;xmm2 = [0,0,0,3]
	pinsrd xmm2, r10d, 1					
	pinsrd xmm2, r10d, 2					
	pinsrd xmm2, r10d, 3					;xmm2 = [3,3,3,3]

	cvtdq2ps xmm2, xmm2					;convierto la mask a float ps

	divps xmm0, xmm2					;xmm0 = w = (r+g+b)/3 = |w3|w2|w1|w0 
	cvttps2dq xmm0, xmm0					;convierto a entero (w)

	movdqu xmm5, xmm0					;conservo xmm5 como el original con los ws

	;tengo calculado el promedio

.crema:

	movdqu xmm1, xmm0					
	movdqu xmm2, xmm0
	movdqu xmm3, xmm0					; xmm3 =xmm2=xmm1 = xmm0=|w3|w2|w1|w0

	mov r10d, 0xAA							;genero mask170 en x4
	pxor xmm4, xmm4							; x4 = 0
	pinsrd xmm4, r10d, 0
	pinsrd xmm4, r10d, 1
	pinsrd xmm4, r10d, 2
	pinsrd xmm4, r10d, 3

	pcmpgtd xmm4, xmm0					;comparo 170 > w

	pcmpeqq xmm0, xmm0
	pandn xmm4, xmm0					; not xmm4

	movdqu xmm0, xmm4					; mask en xmm0

	paddd xmm1, xmm6					;w + cremaR
	psrld xmm1, 2						;xmm1 = |w + cremaR|/4

	paddd xmm2, xmm7					;w + rojoG
	psrld xmm2, 2						;xmm2 = |w + cremaG|/4
	
	paddd xmm3, xmm8					;w + rojoB
	psrld xmm3, 2						;xmm3 = |w + cremaB|/4
	
	;pasamos la mascara para todos
	pand xmm1, xmm0
	pand xmm2, xmm0					
	pand xmm3, xmm0

	;aca satura

	pxor xmm0, xmm0						;xmm0 = 0
	
	packusdw xmm1, xmm0					;0|0|0|0|r3|r2|r1|r0
	packuswb xmm1, xmm0					;0|0|0|0|0|0|0|0|0|0|0|0|r3|r2|r1|r0
	
	packusdw xmm2, xmm0					;0|0|0|0|g3|g2|g1|g0
	packuswb xmm2, xmm0					;0|0|0|0|0|0|0|0|0|0|0|0|g3|g2|g1|g0
	
	packusdw xmm3, xmm0					;0|0|0|0|b3|b2|b1|b0
	packuswb xmm3, xmm0					;0|0|0|0|0|0|0|0|0|0|0|0|b3|b2|b1|b0
	
	movdqu xmm0, xmm15					; xmm0 = red_mask
	pshufb xmm1, xmm0					;0|0|r3|0|0|0|r2|0|0|0|r2|0|0|0|r0|0 -> mem
	
	psrldq xmm0, 1						; shifteo 1 byte el red mask
	mov r10b, 0xFF
	pinsrb xmm0, r10b, 15					;xmm0 = green_mask // le agrego FF en la ultima posicion
	pshufb xmm2, xmm0					;0|g3|0|0|0|g2|0|0|0|g1|0|0|0|g0|0|0 -> mem
	
	psrldq xmm0, 1						; shifteo 1 byte el green_mask
	pinsrb xmm0, r10b, 15					;xmm0 = blue_mask // le agrego FF en la ultima posicion
	pshufb xmm3, xmm0					;b3|0|0|0|b2|0|0|0|b1|0|0|0|b0|0|0|0 -> mem

	pxor xmm0, xmm0						;armo todo en xmm0 que es lo que le paso despues a *dst
	paddusb xmm0, xmm1
	paddusb xmm0, xmm2
	paddusb xmm0, xmm3


.verde: 	;no puedo tocar xmm0 (res) o xmm5 (original)
	movdqu xmm1, xmm5					;recupero |w3|w2|w1|w0
	movdqu xmm2, xmm5					;xmm2 = |w3|w2|w1|w0

	mov r10d, 0x55						;genero mask85 en x4
	pxor xmm4, xmm4						; x4 = 0
	pinsrd xmm4, r10d, 0
	pinsrd xmm4, r10d, 1
	pinsrd xmm4, r10d, 2
	pinsrd xmm4, r10d, 3

	pcmpgtd xmm4, xmm1					;xmm4 =  mask85 > w

	pcmpeqq xmm3, xmm3
	pandn xmm4, xmm3					; not xmm4

	movdqu xmm1, xmm4					;mask en 1
	
	mov r10d, 0xAA						;genero mask170 en x4
	pxor xmm4, xmm4						; x4 = 0
	pinsrd xmm4, r10d, 0
	pinsrd xmm4, r10d, 1
	pinsrd xmm4, r10d, 2
	pinsrd xmm4, r10d, 3

	pcmpgtd xmm4, xmm2	 				;xmm4 = (170) > w

	movdqu xmm2, xmm4					; mask en 2
	
	pand xmm1, xmm2					;xmm1 = todo el mask = 85 < w <= 170
	
	movdqu xmm2, xmm5					;x2=x3=x4= original
	movdqu xmm3, xmm5
	movdqu xmm4, xmm5

	paddd xmm2, xmm9 					;w + verdeR
	psrld xmm2, 2					;xmm2 = |w + verdeR|/4
			
	paddd xmm3, xmm10					;w + verdeG
	psrld xmm3, 2					;xmm3 = |w + verdeG|/4

	paddd xmm4, xmm11					;w + verdeB
	psrld xmm4, 2					;xmm4 = |w + verdeB|/4

	;pasamos la mascara para todos
	pand xmm2, xmm1
	pand xmm3, xmm1
	pand xmm4, xmm1

	;empaquetamos
	pxor xmm1, xmm1						;xmm1 = 0
	
	packusdw xmm2, xmm1					;0|0|0|0|r3|r2|r1|r0
	packuswb xmm2, xmm1					;0|0|0|0|0|0|0|0|0|0|0|0|r3|r2|r1|r0
	
	packusdw xmm3, xmm1					;0|0|0|0|g3|g2|g1|g0
	packuswb xmm3, xmm1					;0|0|0|0|0|0|0|0|0|0|0|0|g3|g2|g1|g0
	
	packusdw xmm4, xmm1					;0|0|0|0|b3|b2|b1|b0
	packuswb xmm4, xmm1					;0|0|0|0|0|0|0|0|0|0|0|0|b3|b2|b1|b0

	movdqu xmm1, xmm15					; xmm0 = red_mask
	pshufb xmm2, xmm1					;0|0|r3|0|0|0|r2|0|0|0|r2|0|0|0|r0|0 -> mem
	
	psrldq xmm1, 1						; shifteo 1 byte el red mask
	mov r10b, 0xFF
	pinsrb xmm1, r10b, 15				;xmm0 = green_mask // le agrego FF en la ultima posicion
	
	pshufb xmm3, xmm1					;0|g3|0|0|0|g2|0|0|0|g1|0|0|0|g0|0|0 -> mem
	
	psrldq xmm1, 1						; shifteo 1 byte el green_mask
	pinsrb xmm1, r10b, 15					;xmm0 = blue_mask // le agrego FF en la ultima posicion
	
	pshufb xmm4, xmm1					;b3|0|0|0|b2|0|0|0|b1|0|0|0|b0|0|0|0 -> mem

	paddusb xmm0, xmm2					;los agrego al total
	paddusb xmm0, xmm3
	paddusb xmm0, xmm4

.rojo:
	movdqu xmm1, xmm5					;recupero |w3|w2|w1|w0

	mov r10d, 0x55						;genero mask85 en x4
	pxor xmm4, xmm4						; x4 = 0
	pinsrd xmm4, r10d, 0
	pinsrd xmm4, r10d, 1
	pinsrd xmm4, r10d, 2
	pinsrd xmm4, r10d, 3

	pcmpgtd xmm4, xmm1 					; xmm4 = (85) > w

	movdqu xmm1, xmm4					; mask en 1
 	
 	movdqu xmm2, xmm5
 	movdqu xmm3, xmm5
 	movdqu xmm4, xmm5

	paddd xmm2, xmm12 					;w + rojoR
	psrld xmm2, 2					;xmm2 = |w + rojoR|/4
		
	paddd xmm3, xmm13					;w + rojoG
	psrld xmm3, 2					;xmm3 = |w + rojoG|/4

	paddd xmm4, xmm14					;w + rojoB
	psrld xmm4, 2				 	;xmm4 = |w + rojoB|/4

	;pasamos la mascara para todos
	pand xmm2, xmm1
	pand xmm3, xmm1
	pand xmm4, xmm1

	;empaquetamos
	pxor xmm1, xmm1						;xmm1 = 0
	
	packusdw xmm2, xmm1					;0|0|0|0|r3|r2|r1|r0
	packuswb xmm2, xmm1					;0|0|0|0|0|0|0|0|0|0|0|0|r3|r2|r1|r0
	
	packusdw xmm3, xmm1					;0|0|0|0|g3|g2|g1|g0
	packuswb xmm3, xmm1					;0|0|0|0|0|0|0|0|0|0|0|0|g3|g2|g1|g0
	
	packusdw xmm4, xmm1					;0|0|0|0|b3|b2|b1|b0
	packuswb xmm4, xmm1					;0|0|0|0|0|0|0|0|0|0|0|0|b3|b2|b1|b0

	movdqu xmm1, xmm15					; xmm1 = red_mask
	pshufb xmm2, xmm1					;0|0|r3|0|0|0|r2|0|0|0|r2|0|0|0|r0|0 -> mem
	
	psrldq xmm1, 1						; shifteo 1 byte el red mask
	mov r10b, 0xFF
	pinsrb xmm1, r10b, 15				;xmm0 = green_mask // le agrego FF en la ultima posicion
	
	pshufb xmm3, xmm1					;0|g3|0|0|0|g2|0|0|0|g1|0|0|0|g0|0|0  -> mem
	
	psrldq xmm1, 1						; shifteo 1 byte el green_mask
	pinsrb xmm1, r10b, 15					;xmm0 = blue_mask // le agrego FF en la ultima posicion
	
	pshufb xmm4, xmm1					;b3|0|0|0|b2|0|0|0|b1|0|0|0|b0|0|0|0 -> mem

	paddusb xmm0, xmm2					;los agrego al total
	paddusb xmm0, xmm3
	paddusb xmm0, xmm4

.brillo:								;hasta aca tengo el rgb de cada pixel. Ahora agrego los brillos

	mov r10b, 0xFF						;genero mask con brillos en ff
	pxor xmm4, xmm4						; x4 = 0
	pinsrb xmm4, r10d, 3
	pinsrb xmm4, r10d, 7				; xmm4 = [FF|00|00|00|FF|00|00|00|FF|00|00|00|FF|00|00|00|]
	pinsrb xmm4, r10d, 11
	pinsrb xmm4, r10d, 15

	paddusb xmm0, xmm4

;--------------------Fin de operaciones -------------------------------------
	
	movdqu [rsi+r9], xmm0

.finCicloCol:
	add r13d, 4
	jmp .cicloCol

.siguienteFila:
	inc r12d
	xor r13, r13
	jmp .cicloFila
.fin:	
	pop r13
	pop r12
	pop rbp
	ret


