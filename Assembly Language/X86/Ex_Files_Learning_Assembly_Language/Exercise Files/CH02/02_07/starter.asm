;EasyCodeName=starter,1
.Data
hInst	DQ	0
val		dw  028FDh
valand  dw  028FDh
valnot  dw  028FDh
valxor  dw  028FDh
valor   dw  028FDh
.Code

start:
	Invoke GetModuleHandleA, 0
	Mov [hInst], Rax
	Invoke Main
	Invoke ExitProcess, 0

Main Frame
	;=====================
	; Write your code here
  	;=====================
    xor rax,rax
    mov ax,03333h
    and [valand],ax
    not w[valnot]
    xor [valxor],ax
    or  [valor],ax
    mov ax,[val]
    shl ax,4
    xor rbx,rbx
    mov bx,[val]
    shr bx,2
    xor rcx,rcx
    mov cx,0A8FDh
    sar cx,2
    mov ax,[val]
    rol ax,4
    mov bx,[val]
    ror bx,3
    ret
EndF
