.Data
hInst	DQ	0
;---Demo1
;key	dq 0D045601FA563771Eh
;---Demo2
;nosh	dd	0ABADFEEDh	
;---Demo3
string1 db 'Peter, Paul, and Mary',0
string2 db 'Simon and Garfunkle',0

.Code

start:
	Invoke GetModuleHandleA, 0
	Mov [hInst], Rax
	Invoke Main
	Invoke ExitProcess, 0

Main Frame
	;=====================
	; Demo 1
	;=====================
; 	mov		rax,[key]
; 	movbe	rbx,[key]
;	bswap	rbx
	;=====================
	; Demo 2
	;=====================
;	mov	eax,0BAADF00Dh
;	mov ebx,0ADBA0DF0h
;	xchg ebx,eax
;	xchg eax,[nosh]
	;=====================
	; Demo 3
	;=====================
    cld 
    mov esi,addr string1
	mov edi,addr string2
    mov ecx,22
    rep movsb	

	ret
EndF
