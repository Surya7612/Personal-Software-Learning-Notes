;EasyCodeName=starter,1
.Data
hInst	 dq	?
hout     dq ?
hin        dq ?
bin		   dd ?
bout	 dd ?

inbuff   db 64 dup 0
strbuff  db 16 dup 0
               db 0Dh,0Ah
numin  db 'Enter two numbers:',0Dh,0Ah
input    db '>'
num1   dd ?
num2   dd ?
num3   dd ?
menu    db 0Dh,0Ah
         db 'Choose a function:',0Dh,0Ah
         db '0...Exit',0Dh,0Ah 
         db '1...Add',0Dh,0Ah
         db '2...Subtract',0Dh,0Ah
         db '3...Multiply',0Dh,0Ah
         db '4...Divide',0Dh,0Ah
menlen  dd $-menu
result      db 'result: '
ten           dd 10 
;=====================
; Jump Table
;=====================
align 4
jumptab  dq addr Adder
                  dq addr Suber
                  dq addr Muler
                  dq addr Diver
 
.Code
start:
	invoke GetModuleHandleA, 0
	mov [hInst], rax
    invoke GetStdHandle, -11    	; Console output handle returned in eax
    mov [hout], eax         
    invoke GetStdHandle, -10    	; Console input handle returned in eax
    mov [hin],eax         
	invoke Main
	invoke ExitProcess,0

    ;========================================
    ;  Addition function
	;======================================== 
Adder:
uses   ebx
    mov   ebx,[num1]
    add    ebx,[num2]
    mov  [num3],ebx
	ret
endu

    ;========================================
    ;  Subtraction function
	;======================================== 
Suber:
uses ebx
    mov  ebx,[num1]
    sub   ebx,[num2]
    mov [num3],ebx
    ret
endu

    ;========================================
    ;  Multiplication function
	;======================================== 
Muler:
uses ebx,edx
    mov eax,[num1]
    mov ebx,[num2]
    mul  ebx
    mov [num3],eax
	ret
endu

    ;========================================
    ;  Division function
	;======================================== 
Diver:
uses ebx,edx
    xor    edx,edx
    mov eax,[num1]
    mov ebx,[num2]
    div    ebx
    mov [num3],eax
	ret
endu

    ;======================================================
    ; Extract number from input buffer and put into [stack]
    ;======================================================
numove Frame pnumber
uses eax,ebx,edx,edi
    xor    eax,eax
    mov  edi,addr inbuff     
:   xor    ebx,ebx
    mov  bl,[edi]
    cmp  bl,0Dh
    je       >
    mul  d[ten]
    sub  bl,030h
    add  eax,ebx
    inc    edi
    jmp  <
:   mov  edx,[pnumber]
    mov  [edx],eax
    ret
EndF

intout FRAME pistringlen, pistring, pint
    ;==============================================
    ; output integer value
    ; max string 16 characters
    ;==============================================
    uses     rax,rbx,rcx,rdx,rdi
    invoke WriteFile, [hout], [pistring], [pistringlen],addr bout, 0
    ;==============================================
    ; get string into strbuff 
    ;==============================================
    mov   eax,[pint]						  ; get value
    mov   rdi,addr strbuff+15		 ; set pointer to end of buffer
    xor     ebx,ebx								; ebx will be length
    xor     r15,r15					
:   mov   rbx,10							   ; set up divisor
    xor     rdx,rdx								 ; clear rdx to set up dx:ax dividend
    div     bx										 ; get next significant digit as remainder
    add   dx,030h							  ; make remainder digit displayable
    mov  [edi],dl								; store digit
    inc     r15										; add one to length
    dec    edi									   ; move to next significant position
    test   rax,rax 								 ; any more digits?
    jnz     <         								  ; yes, go back and do next
    ;==============================================
    ; output integer value string
    ;==============================================
    add  r15,2									; add cr/lf
    mov edx, addr strbuff+18			
    sub  edx,r15							; position to start of string
    invoke WriteFile, [hout], edx, r15, addr bout, 0
    ret
EndF

Main Frame
	;=====================
	; Read numbers
  	;=====================
    Invoke WriteFile,[hout],addr numin,20,addr bout,0 
    Invoke WriteFile,[hout],addr input,1,addr bout,0 
    Invoke ReadFile,[hin],addr inbuff,6,addr bin,0
    invoke numove, addr num1
    Invoke WriteFile,[hout],addr input,1,addr bout,0 
    Invoke ReadFile,[hin],addr inbuff,6,addr bin,0  
    invoke numove, addr num2
	;======================================
	; Display menu and allow repeat selection
  	;======================================
    invoke WriteFile,[hout],addr menu,[menlen],addr bout,0 
looper:
    invoke WriteFile,[hout],addr input,1,addr bout,0 
    invoke ReadFile,[hin],addr inbuff,3,addr bin,0  
    xor     ecx,ecx												; clear offset
    mov  cl,[inbuff]							 			  ; read menu option
    sub   cl,030h								   			   ; make binary
    jz       >											   	  		   ; if zero, jump to end
    dec   ecx										  			  ; adjust option 1-4 to 0-3	
    shl   ecx,3													  ;  ...and turn into a jump table offset
    lea   edx, jumptab+ecx				 			 ;  load the function address
    call [edx]												  	  ; and call it
    invoke intout,8,addr result,[num3] 	  ; display the result
    jmp  looper
:    ret
EndF

