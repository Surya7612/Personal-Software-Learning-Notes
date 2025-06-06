.Const
MB_OK           equ  40h
MB_YESNO        equ  04h
MB_YESNOCANCEL  equ  03h  
ID_OK           equ  1
ID_CANCEL       equ  2
ID_YES          equ  6
ID_NO           equ  7

.Data
hInst	 DQ	 0
hout     dq  0
bout     dd  0
crlf     db  0Dh,0Ah

.Code
start:
	invoke GetModuleHandleA, 0
	mov [hInst], rax
    invoke GetStdHandle, -11    ; Console output handle returned in eax
    mov [hout], eax        
	invoke Main
	invoke ExitProcess, 0

Main Frame
	;=====================
	; Windows Message Boxes
  	;=====================
;    invoke MessageBoxA,0,"Hello World!", "Messages", 040h		; MB_OK
;    invoke MessageBoxA,0,"Shall we?", "Invitation", MB_YESNO
;    invoke MessageBoxA,0,"Well..?","Question", MB_YESNOCANCEL

    ;========================
    ; Get command line
    ;=========================
    invoke GetCommandLineA					; eax points to command line
    xor    rcx,rcx
:   mov    bl,[eax+ecx]						; read it looking for zero terminator
    inc    ecx
    test   bl,bl
    jnz    < 
    dec    ecx
    Invoke WriteFile,[hout],eax,ecx,addr bout,0 
    Invoke WriteFile,[hout],addr crlf,2,addr bout,0 
    ret
EndF
