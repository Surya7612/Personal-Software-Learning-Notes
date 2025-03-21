.Data
hInst	 DQ	 0
hout     dq  0
strbuff  db  16 dup 020h
     	 db  0Dh
         db  0Ah
bout     dd  0
message  db  "Value is: "
cent     dq  100.0
rval1	 dq	 12.65
rval2	 dq	 16.44
rval3	 dq	 0
rval4    dq  0

.Code
start:
	Invoke GetModuleHandleA, 0
	Mov [hInst], Rax
    arg -11                ;STD_OUTPUT_HANDLE
    invoke GetStdHandle    ;handle returned in eax
    mov [hout],eax         ;store
	Invoke Main
	Invoke ExitProcess, 0

intout FRAME pistringlen, pistring, pint
    ;==============================================
    ; output integer value
    ; max string 16 characters
    ;==============================================
    uses     rax,rbx,rcx,rdx,rdi

    ;===============================================
    ; output message
    ;===============================================
    arg 0, addr bout
    arg [pistringlen]
    arg [pistring]
    arg [hout]
    invoke WriteFile
    ;==============================================
    ; get string into strbuff 
    ;==============================================
    mov      eax,[pint]					; get value
    mov      rdi,addr strbuff+15		; set pointer to end of buffer
    xor      ebx,ebx					; ebx will be length
    xor      r15,r15					;
iloop1:
    mov rbx,10							; set up divisor
    xor rdx,rdx							; clear rdx to set up dx:ax dividend
    div bx								; get next significant digit as remainder
    add dx,030h							; make remainder digit displayable
    mov [edi],dl						; store digit
    inc r15								; add one to length
    dec edi								; move to next significant position
    test rax,rax 						; any more digits?
    jnz iloop1        					; yes, go back and do next
    ;==============================================
    ; output integer value string
    ;==============================================
    add  r15,2							; add cr/lf
    mov edx, addr strbuff+18			;
    sub edx,r15							; position to start of string
    arg 0, addr bout
    arg r15, edx
    arg [hout]
    invoke WriteFile
    ret
EndF

realout FRAME prstringlen,prstring,preal
    ;==============================================
    ; output double precision floating point value
    ; max string 16 characters
    ;==============================================
    uses     rax,rbx,rcx,rdx,rdi
    ;===============================================
    ; output message
    ;===============================================
    arg 0, addr bout
    arg [prstringlen]
    arg [prstring]
    arg [hout]
    invoke WriteFile
    ;==============================================
    ; get string into strbuff 
    ;==============================================
    mov      rax,[preal]				; get value
    movq     xmm0,rax					; save rax in xmm0
    mulsd    xmm0,[cent]	 			; make into integer
    cvtsd2si rax,xmm0			   	    ; make eax integer rounded
    mov      rdi,addr strbuff+15		; set pointer to end of buffer
    xor      ebx,ebx					; ebx will be length
    xor      r15,r15					;
    mov      cx,3						; dp counter
rloop1:
    dec cx								; check if at dp
    jnz  >rnotdot						; jump if not
    mov b[edi],02Eh						; insert period
    inc r15								; add one to length
    dec edi								; dec to least significant
rnotdot: 
    mov rbx,10							; set up divisor
    xor rdx,rdx							; clear rdx to set up dx:ax dividend
    div bx								; get next significant digit as remainder
    add dx,030h							; make remainder digit displayable
    mov [edi],dl						; store digit
    inc r15								; add one to length
    dec edi								; move to next significant position
    test rax,rax 						; any more digits?
    jnz rloop1        					; yes, go back and do next
    ;==============================================
    ; output integer value string
    ;==============================================
    add  r15,2							; add cr/lf
    mov edx, addr strbuff+18			;
    sub edx,r15							; position to start of string
    arg 0, addr bout
    arg r15, edx
    arg [hout]
    invoke WriteFile
    ret
EndF

Main Frame
	;=====================
	; Demo1
  	;=====================
    fld  q[rval1]					; push floating point stack with rval1 
    fld  q[rval2]					; push floating point stack with rval2
    fadd							; add top two stack values
    fstp q[rval3]					; store top of stack to rval3 and pop 
    invoke realout,10,addr message,[rval3]
    ;======================
	; Demo2
	;======================
    movq  xmm0,[rval1]				; load real value to xmm
    movq  xmm1,[rval2]				; load real value to xmm
    addsd xmm1,xmm0					; add xmm registers
    movq  [rval4],xmm1				; save into memory
    mov   rax,[rval4]   			; eax is double precision floating point
    invoke realout,10,addr message,[rval4]
    ;======================
	; Demo3
	;======================
    cvtsd2si  eax,[rval1]			; round rval1 to eax
    invoke intout,10,addr message,eax
    cvttsd2si ebx,[rval1]			; truncate rval1 to ebx
    invoke intout,10,addr message,ebx

    ret

EndF
