.Data
hInst	 dq  0
hout     dq  0
bout     dd  0

.Code
start:
	invoke GetModuleHandleA, 0
	mov [hInst], rax
    invoke GetStdHandle, -11    ; Console output handle returned in eax
    mov [hout], eax        
	invoke Main
	invoke ExitProcess, 0

Main Frame

	ret
EndF