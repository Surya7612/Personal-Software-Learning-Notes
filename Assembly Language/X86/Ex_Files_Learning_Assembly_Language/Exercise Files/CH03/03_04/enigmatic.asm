.Data
hInst	DQ		0
;==================================
; working storage
;==================================
bin			dd  0   ; bytes read
bout		dd	0	; bytes written
hin			dq  0   ; handle for console input
hout        dq  0   ; handle for console output
charin      db  32 dup 0
welcome     db  'Enigma-like file encryptor',0Dh,0Ah
message1    db  0Ah, 0Dh, "Enter rotor for slot x: "
message2    db  "Enter start character slot x: "
message3    db  0Ah, 0Dh, "Enter two characters for plug x: " 
m24			db  24

;===================================
; Rotors which provide key stream
;=================================== 
rotor  struct
   hex			dq
   notch		db
ends
rotor1		rotor	<01F46C8037B9AD25Eh,0Fh>
rotor2		rotor	<0EFA87B439D5216C0h,03h>
rotor3		rotor	<00F732D168C4BA59Eh,0Dh>
rotor4		rotor	<0F0E8143CA2695B9Dh,00h>
rotor5		rotor	<0AB8736E1F0C295D4h,03h>

;===============================================
; Encryptor slots into which rotors are placed
;===============================================
slot  struct
   rotty    rotor
   rotstart db
   rotpos   db
ends
slots slot 3 dup <>

;==================================================
;Plugs for cross connecting at start and at end
;==================================================
xplugs      db  00h,01h,02h,03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh

.Code
start:
	Invoke GetModuleHandleA, 0
	Mov [hInst], Rax
	Invoke Main
	Invoke ExitProcess, 0

    ;===========================================
    ; common procedures for char to hex nibble
    ;===========================================
hexer:
    sub al,030h								; convert character to binary
    cmp al,09h								; check if it was a number
	jle >hexout								; if so, skip to done
    sub al,7								; adjust for character
	cmp al,0Fh								; check if upper case
    jle >hexout								; if so, done
	sub al,020h								; final adjustment and done
hexout:
    ret    

;================================================
; LOADPLUG: load the two plug connections
;================================================
LoadPlug Frame pplug
    ;===========================================
    ; get start and end plug characters 
    ;===========================================
    uses rax,rbx
    mov  eax,[pplug]						; get plug number
    add  eax,030h							; make it displayable
    lea  ebx,message3						;
    mov  [ebx+32],al						; insert into plug message
    invoke WriteFile,[hout],addr message3,35,addr bout,0
    invoke ReadFile,[hin],addr charin,4,addr bin,0
    mov al,[charin]							; get first byte	
    and	rax,0FFh							; clear the rest of rax
    call hexer								; convert to hex nibble
    mov ebx,eax								; save in ebx
    mov al,[charin+1]						; get second byte	
    call hexer								; convert to hex nibble
    mov [xplugs+eax],bl						; connect al to bl
    mov [xplugs+ebx],al						; connect bl to al
    ret
EndF

;================================================
; LOADSLOT: load a rotor into a slot
;================================================
LoadSlot Frame pslotno
    ;===========================================
    ; get rotor and place in slot 
    ;===========================================
    uses rax, rbx, rcx, rdx, rdi
    lea edx,addr message1
    mov ecx,[pslotno]
    add ecx,030h
    mov b[edx+23],cl						; insert rotor number into rotor message
    invoke WriteFile,[hout],addr message1,26,addr bout,0
    invoke ReadFile,[hin],addr charin,3,addr bin,0
    xor edx,edx
	mov eax,[pslotno]
	dec eax
	mul b[m24]
	mov edi,addr slots
	add edi,eax
    xor eax,eax
    mov al,b[charin]
    sub al,031h								; change char 1-5 to binary 0-4
    shl	eax,4								; multiply by 16 (each rotor set is 16 bytes) to get offset of requetsed rotor
    mov rbx,[rotor1+eax]					; load hex dword from rotor
    mov [edi],rbx				 			; store hex dword into slot
    mov cl,[rotor1+eax+8]					; load notch byte from rotor
    mov [edi+8],cl							; move notch byte into slot.rotty.notch
    mov cl,[charin]							;
	mov [edi+10h],cl						; save rotor number in slot
    ;===========================================
    ; get slot start character 0-F
    ;===========================================
    lea edx,addr message2					
    mov b[edx+27],030h						; insert slot number into start position message
    mov eax,[pslotno]						;
    add b[edx+27],al						;
    invoke WriteFile,[hout],addr message2,30,addr bout,0
    invoke ReadFile,[hin],addr charin,3,addr bin,0
    mov al,[charin]
	mov [edi+010h],al						; save the start character into slot.rotstart
    call hexer
:   mov  rbx,[edi]							; load current slot rotor 
    rol  rbx,4								; move nibble to lower 
    and  rbx,0Fh							;
    cmp  al,bl								; is the rotor correctly positioned?
    je   >									; if so, leave now
    rol  q[edi],4							; turn the rotor one nibble
    jmp  <									;  
:   ret
EndF

Main Frame
	;=====================
	; Get console handles
	;=====================
    arg -10                ;STD_INPUT_HANDLE
    invoke GetStdHandle    ;handle returned in eax
    mov [hin],eax          ;store 
    arg -11                ;STD_OUTPUT_HANDLE
    invoke GetStdHandle    ;handle returned in eax
    mov [hout],eax         ;store
    ;===========================================
    ; output welcome message
    ;===========================================
    invoke WriteFile,[hout],addr welcome,28,addr bout,0
	
    ;================================================
    ; set up slots with rotor and starting point
    ;===============================================
    invoke LoadSlot,1
    invoke LoadSlot,2
    invoke LoadSlot,3
    ;===========================================================================
    ;  Read plugboard settings
    ;===========================================================================
    invoke LoadPlug,1
    invoke LoadPlug,2
    ;===========================================================================
    ;  Enigmatic encryptor now configured and ready to use
    ;===========================================================================
	ret
EndF

