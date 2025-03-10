.Data
hInst	     dq	0
hout         dq 0
hmod         dq 0
hProcess     dq 0
bout         dd 0
mBytes       dd 0
pBytes       dd 0
strbuff      db 64 dup 0
outline      db 80 dup 020h
mHeading     db 'PiD...Name',0Dh,0Ah
crlf         db 0Dh,0Ah
mProcessList dd 1024 dup 0


.Code
start:
    Invoke GetModuleHandleA, 0
	Mov [hInst], Rax
    invoke GetStdHandle, -11    ; Console output handle returned in eax
    mov [hout],eax         		
	Invoke Main
	Invoke ExitProcess,0

PrintProcess FRAME pProcess
   ;==================================
   ; Get Process name and print line 
   ;==================================
    uses rax,rbx,rcx,rdx,edi
	;------------------------------------
	; space fill the output line
    mov d[outline],20202020h			; space fill first doubleword
    mov ecx,19							; set repeat count to 19
    mov esi,addr outline				; source starts at first double word
    mov edi,addr outline + 4			; destination starts at second doubleword
    rep movsd 							; clear the complete line
	;------------------------------------
    ; create the process id string    
    mov  eax,[pProcess]					; get value
    mov  rdi,addr strbuff+63	  		; set pointer to end of buffer
    xor  ecx,ecx						;
pploop1:
    mov  rbx,10							; set up divisor
    xor  rdx,rdx						; clear rdx to set up dx:ax dividend
    div  bx								; get next significant digit as remainder
    add  dx,030h						; make remainder digit displayable
    mov  [edi],dl						; store digit
    inc  ecx							; add one to length
    dec  edi							; move to next significant position
    test rax,rax 						; any more digits?
    jnz  pploop1        				; yes, go back and do next
	;-----------------------------------
    ; move process id into line
    mov  esi, addr strbuff+64			;
    sub  esi,ecx						; position to start of process number
    mov  edi,addr outline				; position to start of output line	
    rep  movsb							;
	;------------------------------------
    ;--get process name
    invoke OpenProcess,0410h,0,[pProcess]
    mov [hProcess],eax					; we may have a process handle
    test eax,eax						; do we really?
    jz >pputout							; nope, so just output pid
	;------------------------------------
	; zero fill the buffer
    mov d[strbuff],00h					; zero fill first doubleword of the buffer
    mov ecx,15							; set repeat count to 19
    mov esi,addr strbuff				; source starts at first double word
    mov edi,addr strbuff + 4			; destination starts at second doubleword
    rep movsd 							; clear the complete line
	;------------------------------------
	; get the base name for the process
    invoke EnumProcessModules,eax,addr hmod,8,addr pBytes
    invoke GetModuleBaseNameA,[hProcess],[hmod], addr strbuff, 64
    cld									; make sure we're going forward
    mov  esi,addr strbuff 				; get start of process name
    mov  edi,addr outline+7				; position at start of name in output line
pploop2:								;
    mov   eax,[esi]						; load next character
    test  eax,eax						; is this zero delimeter?
    jz    >pputout  					; 
    movsb 								; no, so move one character over and increment
    jmp pploop2							;
pputout:								;
    sub edi, addr outline				; adjust edi to be the number of characters to write
	;------------------------------------
	; output the line, follwed by crlf
    invoke WriteFile,[hout],addr outline,edi,addr bout,0   
    invoke WriteFile,[hout],addr crlf,2,addr bout,0     
   ret
EndF

Main Frame
	;===========================
	; List processes via WinAPI
  	;===========================
    invoke WriteFile,[hout],addr mHeading,12,addr bout,0
    invoke EnumProcesses, addr mProcessList, 4096, addr mBytes 
    mov  r14,[mBytes]					;
    shr  r14,2							; divide by 4 to get number of entries
    mov  ebx,0							;
procloop:								; loop for each entry
    mov  eax,ebx						; 
    shl  eax,2							; eax is the process id offset
    mov  edx,[mProcessList+eax]			; edx points to the next process id
    test edx,edx						; 
    jz   >								; if its zero we don't print it
    Invoke PrintProcess,edx				; if its not, we invoke the print routine
:   inc ebx								; move to next entry
    dec r14								; 
    jnz procloop						; and loop until end of list
    ret
EndF

