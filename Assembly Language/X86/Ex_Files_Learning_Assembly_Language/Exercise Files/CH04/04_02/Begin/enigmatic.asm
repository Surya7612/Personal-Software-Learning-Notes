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
welcome     db  0Dh,0Ah
            db  'Enigma-like file encryptor',0Dh,0Ah
            db  '  0..Exit',0Dh,0Ah
            db  '  1..Configure',0Dh,0Ah
            db  '  2..Encrypt',0Dh,0Ah
            db  '  3..Decrypt',0Dh,0Ah
            db  '> '
wlen        dd  $-welcome
message1    db  0Ah, 0Dh, "Enter rotor for slot x: "
message2    db  "Enter start character slot x: "
message3    db  0Ah, 0Dh, "Enter two characters for plug x: " 
m24         db  24
;-------------------------------------------
; Menu jump table
jumper		dq	addr exit
			dq	addr config
            dq  addr cipher

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
   rotno    db
   rotstart db
ends
slots slot 3 dup <>

;==================================================
;Plugs for cross connecting at start and at end
;==================================================
xplugs      db  00h,01h,02h,03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh

.Code
start:
	Invoke GetModuleHandleA, 0
	Mov [hInst], rax
    Invoke Main
exit:
    invoke CloseHandle,[hin]
    invoke CloseHandle,[hout]
	invoke CloseHandle,[hInst]
	Invoke ExitProcess, 0

;======================================================
; HEXER: callable subroutine for hex char to hex nibble
; Input al, output al
;======================================================
hexer:
    sub al,030h								; convert character to binary
    cmp al,09h								; check if it was a number
	jle >									; if so, skip to done
    sub al,7								; adjust for character
	cmp al,0Fh								; check if upper case
    jle >									; if so, done
	sub al,020h								; final adjustment and done
:   ret    

;================================================
; LOADPLUG: load the two plug connections
;================================================
LoadPlug Frame pplug
    uses rax,rbx
    mov eax,[pplug]							; get plug number
    add eax,030h							; make it displayable
    lea ebx, addr message3					;
    mov b[ebx+32],al						; insert into plug message
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
    ;-------------------------------------------
    ; get rotor and place in slot 
    uses rax, rbx, rcx, rdx, rdi
    lea edx,addr message1
    mov ecx,[pslotno]
    add ecx,030h
    mov b[edx+23],cl						; insert rotor number into rotor message
    invoke WriteFile,[hout],addr message1,26,addr bout,0
    invoke ReadFile,[hin],addr charin,3,addr bin,0
    xor edx,edx
	mov eax,[pslotno]						; get slot number
	dec eax									; adjust 1-3 to 0-2
	mul b[m24]								; multiply by 24 to become offset
	mov edi,addr slots
	add edi,eax								; get slot address
    xor eax,eax
    mov al,b[charin]						; load rotor number
    sub al,031h								; change char 1-5 to binary 0-4
    shl	eax,4								; multiply by 16 (each rotor set is 16 bytes) to get offset of requested rotor
    mov rbx,[rotor1+eax]					; load hex dword from rotor
    mov [edi],rbx				 			; store hex dword into slot.rotty.hex
    mov bl,[rotor1+eax+8]					; load notch byte from rotor
    mov [edi+8],bl							; move notch byte into slot.rotty.notch
    ;-------------------------------------------
    ; get slot start character 0-F
    lea edx,addr message2					
    mov b[edx+27],030h						; insert slot number into start position message
    mov eax,[pslotno]						;
    add b[edx+27],al						;
    invoke WriteFile,[hout],addr message2,30,addr bout,0
    invoke ReadFile,[hin],addr charin,3,addr bin,0
    mov al,[charin]
	mov [edi+010h],al						; save the start character into slot.rotstart
    call hexer
    mov	edx,edi								; set edx to point to first two nibbles of rotor slot.rotty.hex
    mov b[edi+011h],0						; set current position to start of rotor slot.rotpos	
looper:    
    mov bl,[edx]							; get current byte
	shr	bl,4								; get top nibble
    cmp bl,al								; is this the start point?
    je	>ready								; yes - we're done
    inc b[edi+011h]							; turn the rotor one position slot.rotpos
    mov bl,[edx]							; reload hex byte
    and bl,0Fh								; isolate bottom nibble
    cmp bl,al								; is this the start point?
    je >ready
    inc b[edi+011h]							; turn the rotor one position slot.rotpos
    inc edx        
    jmp looper
ready:
	ret
EndF

Main Frame
	;=====================
	; Get console handles
	;=====================
    invoke GetStdHandle, -10    ; Console input handle returned in eax
    mov [hin],eax    
    invoke GetStdHandle, -11    ; Console output handle returned in eax
    mov [hout],eax   
    ;===========================================
    ; output welcome message
    ;===========================================
menu:
    invoke WriteFile,[hout],addr welcome,[wlen],addr bout,0
    invoke ReadFile,[hin],addr charin,3,addr bin,0 ; read character plus lf/cr
    xor  eax,eax
    mov  al,[charin]
    sub  eax,030h							; get binary value
    shl  eax,3								; prepare for jump table 8 byte offset
    call [jumper+eax]						;
    jmp  < menu

;=============================================================
; CONFIGURATION
;=============================================================
config:
    ;-----------------------------------------------
    ; set up slots with rotor and starting point
    invoke LoadSlot,1
    invoke LoadSlot,2
    invoke LoadSlot,3
    ;------------------------------------------------
    ;  Read plugboard settings
    invoke LoadPlug,1
    invoke LoadPlug,2
    ;===========================================================================
    ;  Enigmatic encryptor now configured and ready to use
    ;===========================================================================
	ret

;=============================================================
; CIPHERING between ciphers and plaintext
;=============================================================   
cipher:
    ret

EndF

