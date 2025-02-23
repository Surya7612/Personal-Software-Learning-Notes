.Data
hInst	    dq	0
hout        dq  0
bout        dd  0
;---------------
mNoAES      db 'This cpu does not support AES',0Dh,0Ah
mDoAES      db 'AES Enabled Processor',0Dh,0Ah
mOK         db 'Ciphering worked',0Dh,0Ah
mNoOK       db 'Ciphering failed',0Dh,0Ah
;---------------
align 16
check_plain      db 06Bh, 0C1h, 0BEh, 0E2h, 02Eh, 040h, 09Fh, 096h, 0E9h, 03Dh, 07Eh, 011h, 073h, 093h, 017h, 02Ah
check_cipher     db 03Ah, 0D7h, 07Bh, 0B4h, 00Dh, 07Ah, 036h, 060h, 0A8h, 09Eh, 0CAh, 0F3h, 024h, 066h, 0EFh, 097h
enc_key          db 02Bh, 07Eh, 015h, 016h, 028h, 0AEh, 0D2h, 0A6h, 0ABh, 0F7h, 015h, 088h, 009h, 0CFh, 04Fh, 03Ch
enc_expansion    db 160 dup 0 
computed_cipher  db 16  dup 0
computed_plain   db 16  dup 0
;----------------
pand1            db 00h,00h,00h,00h,0FFh,0FFh,0FFh,0FFh,00h,00h,00h,00h,00h,00h,00h,00h
pand2            db 00h,00h,00h,00h,00h,00h,00h,00h,0FFh,0FFh,0FFh,0FFh,00h,00h,00h,00h
pand3            db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,0FFh,0FFh,0FFh,0FFh

.Code ;
start:
	invoke GetModuleHandleA,0
	mov [hInst], rax
    invoke GetStdHandle, -11    ; Console output handle returned in eax
    mov [hout],eax 
	Invoke Main
	Invoke ExitProcess,0

;-----------------------------------------------
; we have the sub/xor/recon value f() in xmm0[3]
; apply to word0 and ripple... 
;-----------------------------------------------
xgen16a:
    psrldq  xmm0,12				    ; move f() to xmm0[0]
    pxor    xmm1,xmm0				; create first new dword
    movaps  xmm0,xmm1				; move for next xor
    pslldq  xmm0,4					; put into position
    pand    xmm0,[pand1]			; remove the rest
    pxor    xmm1,xmm0				; create next new dword
    movaps  xmm0,xmm1			
    pslldq  xmm0,4				
    pand    xmm0,[pand2]		
    pxor    xmm1,xmm0				; create third new dword
    movaps  xmm0,xmm1			
    pslldq  xmm0,4			
    pand    xmm0,[pand3]		
    pxor    xmm1,xmm0				; create last new dword
    add     edi,16				 
    movaps  [edi],xmm1				; store as next 128 bits
    ret
;-----------------------------------------
; generate 16 bytes of expanded key
;-----------------------------------------
xgen16 FRAME
    uses eax
    movaps xmm1,[enc_key]
    aeskeygenassist xmm0,xmm1,01h
    call xgen16a
    aeskeygenassist xmm0,xmm1,02h
    call xgen16a
    aeskeygenassist xmm0,xmm1,04h
    call xgen16a
    aeskeygenassist xmm0,xmm1,08h
    call xgen16a
    aeskeygenassist xmm0,xmm1,10h
    call xgen16a
    aeskeygenassist xmm0,xmm1,20h
    call xgen16a
    aeskeygenassist xmm0,xmm1,40h
    call xgen16a
    aeskeygenassist xmm0,xmm1,80h
    call xgen16a
    aeskeygenassist xmm0,xmm1,1Bh
    call xgen16a
    aeskeygenassist xmm0,xmm1,36h
    call xgen16a
    ret
EndF

Main Frame
    ;-----------------------------------
    ; Check we can support hardware AES
	mov   eax,1			; call for cpu information
	cpuid		
	and   ecx,02000000	; check ecx bit 25 for AES
    jz    >noAES 
    invoke WriteFile,[hout],addr mDoAES,23,addr bout,0
    ;-----------------------------------------------------
    ; generate the expanded key
    mov    edi,addr enc_key	 ; set up to expand key
    invoke xgen16			 ; generate 10x16 additional bytes of expanded key
    ;------------------------------------------------------
    ; encrypt the plaintext
    movaps     xmm0,[check_plain]
    pxor       xmm0,[enc_key]
    mov        edi,addr enc_key
    mov        ecx,9 
:   add        edi,16
    aesenc     xmm0,[edi]
    loop       <
    aesenclast xmm0,[edi+16] 
    ;---------------------------------------------------------
    ; check the result
    ;---------------------------------------------------------
    movdqa     xmm1,[check_cipher]		 ; load the expected cipher value
    comisd     xmm0,xmm1						; check if we're the same (half check)
    jne        >badAES  
    ;---------------------------------------------------------
    ; successful exit
    ;---------------------------------------------------------
    invoke WriteFile,[hout],addr mOK,16,addr bout,0
    ret
;---------------------------------------------------------------------
; Error messages
noAES:
    invoke WriteFile,[hout],addr mNoAES,31,addr bout,0
	Invoke ExitProcess,1
badAES:
    invoke WriteFile,[hout],addr mNoOK,16,addr bout,0
	Invoke ExitProcess,2
EndF