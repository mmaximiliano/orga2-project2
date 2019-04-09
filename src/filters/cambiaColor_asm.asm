; void cambiaColor_asm (unsigned char *src RDI, unsigned char *dst RSI, int cols RDX, int filas RCX,
;                       int src_row_size R8, int dst_row_size R9,
;                       pila:
;												unsigned char Nr , unsigned char Ng, unsigned char Nb,
;                       unsigned char Or, unsigned char Og, unsigned char Ob, int lim);

extern imprimir_basura
;section .rodata
multx3: 		times 4 dd 3.0
restar1:		times 4 dd 1.0
dividirx512:	times 4 dd 512.0
setAlpha: 		times 4	db 0x00, 0x00, 0x00, 0xFF


global cambiaColor_asm
cambiaColor_asm:
	push rbp								;alineada
	mov rbp, rsp
	push r12
	push r13								;alineada



	;mascaras:
	movdqu xmm14, [multx3]	;xmm14 <- 3 | 3 | 3 | 3 (PS)
	movdqu xmm11, [dividirx512] ; esta en PS

	movdqu xmm10, [restar1]	; esta en PS
	movdqu xmm9, [setAlpha]					;xmm9 <- ffffffff | 0 | 0 | 0

	;Parametros:
	mov ecx, ecx							;Limpio la parte alta
	mov edx, edx							;Limpio la parte alta

	;Parametros por pila:
	mov r13d, [rsp+80]									;r13d <-lim
	pinsrd xmm12, r13d, 0								;xmm12 <- x | x | x | lim
	cvtdq2ps xmm12, xmm12								;xmm12 <- x | x | x | lim (PS)
	insertps xmm12, xmm12, 00010000b 		;xmm12 <- x | x | lim | lim  d: 01 s:00 Zmask:0000
	insertps xmm12, xmm12, 00100000b 		;xmm12 <- x | lim | lim | lim d: 10 s:00 Zmask:0000
	insertps xmm12, xmm12, 00110000b 		;xmm12 <- lim | lim | lim | lim d: 11 s:00 Zmask:0000
	mulps xmm12, xmm12 									;xmm12 <- lim² | lim² | lim² | lim²

	pxor xmm0, xmm0								;limpio xmm0
	mov r13b, [rsp+72]						;r13d <- Ob
	pinsrb xmm0, r13b, 0					;xmm0 <- x | x | x | Ob
	mov r13b, [rsp+64]						;r13d <- Og
	pinsrb xmm0, r13b, 1					;xmm0 <- x | x | Og | Ob
	mov r13b, [rsp+56]						;r13d <- Or
	pinsrb xmm0, r13b, 2					;xmm0 <- x | Or | Og | Ob
	pshufd xmm0, xmm0, 0					;xmm0 <- xOrOgOb | xOrOgOb | xOrOgOb | xOrOgOb (Int)

	pxor xmm1, xmm1								;limpio xmm1
	mov r13b, [rsp+48]						;r13d <- Nb
	pinsrb xmm1, r13b, 0					;xmm1 <- x | x | x | Nb
	mov r13b, [rsp+40]						;r13d <- Ng
	pinsrb xmm1, r13b, 1					;xmm1 <- x | x | Ng | Nb
	mov r13b, [rsp+32]						;r13d <- Nr
	pinsrb xmm1, r13b, 2					;xmm1 <- x | Nr | Ng | Nb
	pshufd xmm1, xmm1, 0					;xmm1 <- xNrNgNb | xNrNgNb | xNrNgNb | xNrNgNb (Int)

	;xmm12 <- lim² | lim² | lim² | lim² (float)

	;ciclo:
	shr edx, 2
	mov r10d, 0
.cicloFilas:
	cmp r10d, ecx ;cheque si termine
	je .fin

	mov r11d, 0
.cicloActual:
	cmp r11d, edx
	je .finCicloActual

	;levanto pixeles
	movdqu xmm2, [rdi]      ;xmm2 <- ARGB(P4) | ARGB(P3) | ARGB(P2) | ARGB(P1)

	movdqu xmm3, xmm2
	movdqu xmm4, xmm2
	movdqu xmm5, xmm2

	pslld xmm3, 8				;xmm3 <- r4 g4 b4 0 | r3 g3 b3 0 | r2 g2 b2 0 | r1 g1 b1 0
	psrld xmm3, 24			;xmm3 <- r4 | r3 | r2 | r1 (DW)

	pslld xmm4, 16			;xmm4 <- g4 b4 0 0 | g3 b3 0 0 | g2 b2 0 0 | g1 b1 0 0
	psrld xmm4, 24			;xmm4 <- g4 | g3 | g2 | g1 (DW)

	pslld xmm5, 24			;xmm5 <- b4 0 0 0 | b3 0 0 0 | b2 0 0 0 | b1 0 0 0
	psrld xmm5, 24			;xmm5 <- b4 | b3 | b2 | b1 (DW)

	movdqu xmm6, xmm0		;xmm6 <- xOrOgOb | xOrOgOb | xOrOgOb | xOrOgOb
	movdqu xmm7, xmm0		;xmm7 <- xOrOgOb | xOrOgOb | xOrOgOb | xOrOgOb
	movdqu xmm8, xmm0		;xmm8 <- xOrOgOb | xOrOgOb | xOrOgOb | xOrOgOb

	pslld xmm6, 8				;xmm6 <- OrOgOb0 | OrOgOb0 | OrOgOb0 | OrOgOb0
	psrld xmm6, 24			;xmm6 <- 000 Or  | 000 Or  | 000 Or  | 000 Or

	pslld xmm7, 16			;xmm7 <- OgOb00 | OgOb00 | OgOb00 | OgOb00
	psrld xmm7, 24			;xmm7 <- 000 Ob | 000 Ob | 000 Ob | 000 Ob

	pslld xmm8, 24			;xmm8 <- Ob 000 | Ob 000 | Ob 000 | Ob 000
	psrld xmm8, 24			;xmm8 <- 000 Ob | 000 Ob | 000 Ob | 000 Ob


	movdqu xmm2, xmm6			;xmm2 <- 0r | 0r | 0r | 0r
	paddd xmm2, xmm3   		;xmm7 <- 2r4 | 2r3 | 2r2 | 2r1

	psubd xmm6, xmm3 			;xmm6 <- ∆R | ∆R | ∆R | ∆R
	pmulld xmm6, xmm6			;xmm6 <- ∆R² | ∆R² | ∆R² | ∆R²

	psubd xmm7, xmm4 			;xmm7 <- ∆G | ∆G | ∆G | ∆G
	pmulld xmm7, xmm7			;xmm7 <- ∆G² | ∆G² | ∆G² | ∆G²

	psubd xmm8, xmm5  		;xmm8 <- ∆B | ∆B | ∆B | ∆B
	pmulld xmm8, xmm8			;xmm8 <- ∆B² | ∆B² | ∆B² | ∆B²

	movdqu xmm15, xmm6
	psubd xmm15, xmm8		;xmm15 <- ∆R² - ∆B² | ∆R² - ∆B² | ∆R² - ∆B² | ∆R² - ∆B²

	pslld xmm6, 1			;xmm6 <- 2*(∆R² | ∆R² | ∆R² | ∆R²)
	pslld xmm7, 2			;xmm7 <- 4*(∆G² | ∆G² | ∆G² | ∆G²)

	cvtdq2ps xmm8, xmm8
	mulps xmm8, xmm14		;xmm8 <- 3*(∆B² | ∆B² | ∆B² | ∆B²)

	cvtdq2ps xmm15, xmm15
	cvtdq2ps xmm2, xmm2
	mulps xmm2, xmm15		;xmm2 <- 2r*(∆R² - ∆B²) | 2r*(∆R² - ∆B²) | 2r*(∆R² - ∆B²) | 2r*(∆R² - ∆B²)

	divps xmm2, xmm11		;xmm2 <- r*(∆R² - ∆B²)/256 | r*(∆R² - ∆B²)/256 | r*(∆R² - ∆B²)/256 | r*(∆R² - ∆B²)/256

	cvtdq2ps xmm6, xmm6
	cvtdq2ps xmm7, xmm7

	addps xmm2, xmm6
	addps xmm2, xmm7
	addps xmm2, xmm8 		;xmm2 <- d² | d² | d² | d²

	divps xmm2, xmm12       ;xmm2 <- c | c | c | c


	movdqu xmm15, xmm10 	;xmm15 <- 1 | 1 | 1 | 1
	subps xmm15, xmm2   	;xmm15 <- 1-c | 1-c | 1-c | 1-c

	movdqu xmm6, xmm1			;xmm6 <- xNrNgNb | xNrNgNb | xNrNgNb | xNrNgNb
	pslld xmm6, 8					;xmm6 <- NrNgNb0 | NrNgNb0 | NrNgNb0 | NrNgNb0
	psrld xmm6, 24				;xmm6 <- 000 Nr  | 000 Nr  | 000 Nr  | 000 Nr
	cvtdq2ps xmm6, xmm6 	;xmm6 <- PS

	mulps xmm6, xmm15		;xmm6 <- Nr*(1-c) | Nr*(1-c) | Nr*(1-c) | Nr*(1-c)

	cvtdq2ps xmm3, xmm3		;xmm3 <- r src to PS
	movdqu xmm15, xmm2 		;xmm15 <- c | c | c | c
	mulps xmm15, xmm3 		;xmm15 <- c*r | c*r | c*r | c*r

	addps xmm6, xmm15		;xmm6 <- Nr*(1-c) + c*r


	movdqu xmm15, xmm10 		;xmm15 <- 1 | 1 | 1 | 1
	subps xmm15, xmm2   	;xmm15 <- 1-c | 1-c | 1-c | 1-c

	movdqu xmm7, xmm1			;xmm7 <- xNrNgNb | xNrNgNb | xNrNgNb | xNrNgNb
	pslld xmm7, 16				;xmm7 <- NgNb 00 | NgNb 00 | NgNb 00 | NgNb 00
	psrld xmm7, 24				;xmm7 <- 000 Nb  | 000 Nb  | 000 Nb  | 000 Nb
	cvtdq2ps xmm7, xmm7 	;xmm7 <- PS

	mulps xmm7, xmm15		;xmm7 <- Ng*(1-c) | Ng*(1-c) | Ng*(1-c) | Ng*(1-c)

	cvtdq2ps xmm4, xmm4		;xmm4 <- g src to PS
	movdqu xmm15, xmm2 		;xmm15 <- c | c | c | c
	mulps xmm15, xmm4 		;xmm15 <- c*g | c*g | c*g | c*g

	addps xmm7, xmm15		;xmm7 <- Ng*(1-c) + c*g


	movdqu xmm15, xmm10 	;xmm15 <- 1 | 1 | 1 | 1
	subps xmm15, xmm2   	;xmm15 <- 1-c | 1-c | 1-c | 1-c

	movdqu xmm8, xmm1			;xmm8 <- xNrNgNb | xNrNgNb | xNrNgNb | xNrNgNb
	pslld xmm8, 24				;xmm8 <- Nb 000 | Nb 000 | Nb 000 | Nb 000
	psrld xmm8, 24				;xmm8 <- 000 Nb | 000 Nb | 000 Nb | 000 Nb
	cvtdq2ps xmm8, xmm8		;xmm8 <- PS

	mulps xmm8, xmm15		;xmm8 <- Nb*(1-c) | Nb*(1-c) | Nb*(1-c) | Nb*(1-c)

	cvtdq2ps xmm5, xmm5		;xmm5 <- b src to Ps
	movdqu xmm15, xmm2 		;xmm15 <- c | c | c | c
	mulps xmm15, xmm5 		;xmm15 <- c*b | c*b | c*b | c*b

	addps xmm8, xmm15		;xmm8 <- Nb*(1-c) + c*b


	cvttps2dq xmm6, xmm6			;to int
	pslld xmm6, 16						;xmm6 <- 0 Nr*(1-c) + r*c 0, 0 | 0 Nr*(1-c) + r*c 0, 0 | 0 Nr*(1-c) + r*c 0, 0 | 0 Nr*(1-c) + r*c 0, 0
	cvttps2dq xmm7, xmm7			;to int
	pslld xmm7, 8							;xmm7 <- 0 0 Ng*(1-c) + g*c 0 | 0 0 Ng*(1-c) + g*c 0 | 0 0 Ng*(1-c) + g*c 0 | 0 0 Ng*(1-c) + g*c 0
	paddb xmm6, xmm7					;xmm6 <- 0 Nr*(1-c) + r*c Ng*(1-c) + g*c 0 | 0 Nr*(1-c) + r*c Ng*(1-c) + g*c 0 | 0 Nr*(1-c) + r*c Ng*(1-c) + g*c 0 | 0 Nr*(1-c) + r*c Ng*(1-c) + g*c 0
	cvttps2dq xmm8, xmm8			;to int
	paddb xmm6, xmm8					;xmm6 = 0 Nr*(1-c) + r*c, Ng*(1-c) + g*c, Nb*(1-c) + b*c | 0 Nr*(1-c) + r*c, Ng*(1-c) + g*c, Nb*(1-c) + b*c | 0 Nr*(1-c) + r*c, Ng*(1-c) + g*c, Nb*(1-c) + b*c | 0 Nr*(1-c) + r*c, Ng*(1-c) + g*c, Nb*(1-c) + b*c

	cvttps2dq xmm3, xmm3			;to int
	pslld xmm3, 16						;xmm3 <- 0r00 | 0r00 | 0r00 | 0r00
	cvttps2dq xmm4, xmm4			;to int
	pslld xmm4, 8							;xmm4 <- 00g0 | 00g0 | 00g0 | 00g0
	paddb xmm3, xmm4					;xmm3 <- 0rg0 | 0rg0 | 0rg0 | 0rg0
	cvttps2dq xmm5, xmm5			;to int
	paddb xmm3, xmm5					;xmm3 <- 0rgb | 0rgb | 0rgb | 0rgb

	mulps xmm2, xmm12					;xmm2 <- d² | d² | d² | d²
	sqrtps xmm2, xmm2 				;xmm2 <- d | d | d | d

	movdqu xmm4, xmm12			;xmm4 <- lim² | lim² | lim² | lim² (PS)
	sqrtps xmm4, xmm4				;xmm4 <-  lim | lim | lim | lim
	cvttps2dq xmm4, xmm4		;xmm4 <-  lim | lim | lim | lim (int)
	movdqu xmm5, xmm2				;xmm5 <- d | d | d | d (PS)
	cvttps2dq xmm5, xmm5		;xmm5 <- d | d | d | d (int)
	pcmpgtd xmm4, xmm5			;xmm4 lim>d | lim>d | lim>d | lim>d]

	pand xmm6, xmm4				;xmm6 <- resultado Ni*(1-c)+i*c si lim>d, 0 si no

	pxor xmm5, xmm5				;limpio xmm5
	pcmpeqd xmm5, xmm5		;xmm5 <- FFFF | FFFF | FFFF | FFFF (Int)
	pxor xmm4, xmm5				;xmm4 <- d>=lim | d>=lim | d>=lim | d>=lim

	pand xmm3, xmm4				;xmm3 src si d>=lim 0 si no
	pxor xmm3, xmm6				;xmm3 <- resultado final

	pslld xmm3, 8
	psrld xmm3, 8 				;limpio el byte mas signifactivo de cada DW para ponerle alfa en 255
	pxor xmm3, xmm9
	movdqu [rsi], xmm3		;cargo el resultado

	add rsi, 16
	add rdi, 16
	inc r11d
	jmp .cicloActual
.finCicloActual:
	inc r10d
	cmp r10d, ecx
	je .fin
	jmp .cicloFilas
	
.fin:
	pop r13
	pop r12
	pop rbp
	ret
