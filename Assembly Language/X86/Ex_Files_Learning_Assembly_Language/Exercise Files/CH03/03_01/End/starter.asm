.Data
hInst	DQ	0
value1	dq	18
value2	dq	24
value3  dq  0

.Code
start:
	Invoke GetModuleHandleA, 0
	Mov [hInst], Rax
	Invoke Main
	Invoke ExitProcess, 0

adder1 Frame pvalue1,pvalue2,pvalue3
    ;===============================
    ; Invokable sub program Adder1      
    ;===============================
    uses rax,rdx
    mov 	edx,[pvalue1]	; get address of first value	
    mov		rax,[edx]		; load it
    mov 	edx,[pvalue2]	; get address of second value
    add		rax,[edx]		; add it
    mov 	edx,[pvalue3]	; get address of third value
    mov		[edx],rax		; save into it
    ret
    EndF

    ;===============================
    ; Callable sub program Adder2      
    ;===============================
adder2:
    push ebp				; save ebp
    mov  ebp,esp			; set ebp up for accessing parameters
    push rax				; save eax as we will use it
    push edx				; save edx as we will use it
    mov  rax,[ebp+010h]		; first parameter is at 16 bytes offset
    add  rax,[ebp+018h]		; add second parameter at 24 bytes offset
    mov  edx,[ebp+020h]		; get address of return value at 32 bytes offset
    mov  [edx],rax			; write answer
    pop  edx				; restore edx
    pop  rax				; restore eax
    mov  esp,ebp			; restore stack pointer
    pop  ebp				; restore ebp
    ret 24 

Main Frame
	;=====================
	; Invoke the adder
  	;=====================
    arg addr value3			; pass by reference, i.e. address
    arg addr value2			;
    arg addr value1			;
    invoke adder1
	;=====================
	; Call the adder
  	;=====================
    xor rax,rax				; clear rax
    mov [value3],rax		; ...and clear the result	
    push addr value3		; ..we can pass addresses
    push [value2]			;  ..and values
    push [value1]			;   
    call adder2

    ret

EndF
