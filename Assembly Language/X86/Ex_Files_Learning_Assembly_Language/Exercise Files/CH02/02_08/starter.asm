.Data
hInst	DQ	0

.Code
start:
	Invoke GetModuleHandleA, 0
	Mov [hInst], Rax
	Invoke Main
	Invoke ExitProcess, 0

Main Frame
	;=====================
	; Negate
  	;=====================
    mov  rax,42
    neg  rax
    ;=========================
	; Increment and decrement
	;=========================
    mov  rax,42
    inc  rax
    mov  rax,42
    dec  rax
    ;======================
	; Add and subtract
	;======================
	mov	 rax,42
    add	 rax,13
	mov	 rax,42
    sub	 rax,73
    ;======================
	; Multiply
	;======================
    mov	 eax,42
	mov	 ebx,8
	mul	 ebx
    mov	 eax,42
	mov	 ebx,-2
	imul ebx
    ;=======================
	; Divide
	;========================
    mov	 rax,0280h
    mov  bl,3
    div	 bl
    xor  rdx,rdx
    mov  edx,02h
    mov  eax,065E011D4h
    mov  ebx,13
    div  ebx
    mov  eax,-285
    cdq
    mov  ebx,13
    idiv ebx

    ret
EndF
