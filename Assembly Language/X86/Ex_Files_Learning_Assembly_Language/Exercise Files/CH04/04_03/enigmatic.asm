.Const
GENERIC_READ          equ 080000000h
GENERIC_WRITE         equ 40000000h
CREATE_ALWAYS         equ 2
OPEN_EXISTING         equ 3
FILE_ATTRIBUTE_NORMAL equ 080h
INVALID_FILE_HANDLE   equ -1

.Data
hInst	    dq	0
hin			dq  0   ; handle for console input
hout        dq  0   ; handle for console output
hfin        dq  0	; handle for file input
hfout       dq  0   ; handle for file output
hConfig     dq  0   ; handle for config file
bin			dd  0   ; bytes read
bout		dd	0	; bytes written
;----------------------------------
; working storage
charin      db  32 dup 0
ciph        dd  0
welcome     db  0Dh,0Ah
            db  'Enigma-like file encryptor',0Dh,0Ah
            db  '  0..Exit',0Dh,0Ah
            db  '  1..Configure',0Dh,0Ah
            db  '  2..Cipher',0Dh,0Ah
            db  '> '
wlen        dd  $-welcome
message1    db  0Ah, 0Dh, "Enter rotor for slot x: "
message2    db  "Enter start character slot x: "
message3    db  0Ah, 0Dh, "Enter two characters for plug x: " 
message4    db  "Enter input  filename: "
message5    db  "Enter output filename: "
message6    db  "Configuration State  x-x x-x x-x xxxxxxxxxxxxxxxx ",0Dh,0Ah
confile     db  'enigmatic.cfg',0
badfile     db  "Problem with the file, sorry...",0Dh,0Ah
noconfig    db  "Cannot open the config file....",0Dh,0Ah
strbuff     db  64 dup 0
m24         db  24
align 8
;-------------------------------------------
; Menu jump table
jumper		dq	addr exit
			dq	addr config
            dq  addr cipher

;==================================
; start of configuration data
;==================================
configdata  db 'Enigmatic Configuration'  
   ;----------------------------------
   ; Rotors which provide key stream
rotor  struct
   hex			dq
   notch		db 
ends
rotor1		rotor	<01F46C8037B9AD25Eh,0Fh>
rotor2		rotor	<0EFA87B439D5216C0h,03h>
rotor3		rotor	<00F732D168C4BA59Eh,0Dh>
rotor4		rotor	<0F0E8143CA2695B9Dh,00h>
rotor5		rotor	<0AB8736E1F0C295D4h,03h>
   ;-----------------------------------------------
   ; Encryptor slots into which rotors are placed
slot  struct
   rotty    rotor
   rotno    db 
   rotstart db
ends
slots slot 3 dup <>
   ;--------------------------------------------------
   ;Plugs for cross connecting at start and at end
xplugs      db  00h,01h,02h,03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh
;===================================================
; end of configuration
;===================================================
configlen   dd  $-configdata

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

;=================================================================
; FINDCH: callable subroutine to find position of nibble in rotor
; Input: lower al nibble, output ecx
;=================================================================
findch:
    uses  rbx,rdx
    xor   rcx,rcx							; start at 0th position
    mov	  rdx,[edi]							; set rdx to slot.rotty.hex
:   rol   rdx,4								; get top nibble in low nibble bit
    mov   bl,dl
    and   bl,0Fh
    cmp   bl,al								; is this the nibble?
    je >
    inc   ecx								; move to next position
    jmp <
:   ret  
    EndU

;===================================================
; DISPLAYCONFIG: show the running config
;===================================================
displayconfig:
    uses eax,ecx,edi
    mov  edi,addr message6					; set to start of print line
    mov  al,[slots.rotno]					; move slot 1 rotor number
    mov  [edi+21],al
    mov  al,[slots.rotstart]				; move slot 1 start character
    mov  [edi+23],al
    mov  al,[slots.rotno+24]				; move slot 2 rotor number
    mov  [edi+25],al
    mov  al,[slots.rotstart+24]				; move slot 2 start character
    mov  [edi+27],al
    mov  al,[slots.rotno+48]				; move slot 3 rotor number
    mov  [edi+29],al
    mov  al,[slots.rotstart+48]				; move slot 3 start character
    mov  [edi+31],al
    ;----------------------------------------
    ; put in plug configuration
    add  edi,33  
    xor  ecx,ecx
dcloop:
    mov  al,[xplugs+ecx]   					; get plugs byte
    add  al,30h								; make it displayable
    cmp  al,39h
    jle  >
    add  eax,7								; adjust for A-F
:   mov  [edi+ecx],al
    inc  ecx
    cmp  ecx,16
    jne  dcloop
    invoke WriteFile,[hout],addr message6,52,addr bout,0
    ret
    EndU

;===================================================
; LOADPLUG: invokable subroutine for loading plugs
;===================================================
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

;===================================================
; LOADSLOT: invokable subroutine for loading slots
;===================================================
LoadSlot Frame pslotno
    ;-------------------------------------------
    ; get rotor and place in slot 
    uses rax, rbx, rcx, rdx, rdi
    lea  edx,addr message1
    mov  ecx,[pslotno]
    add  ecx,030h
    mov  b[edx+23],cl						; insert rotor number into rotor message
    invoke WriteFile,[hout],addr message1,26,addr bout,0
    invoke ReadFile,[hin],addr charin,3,addr bin,0 
    xor  edx,edx
	mov  eax,[pslotno]						; get slot number
	dec  eax								; adjust 1-3 to 0-2
	mul  b[m24]								; multiply by 24 to become offset
	mov  edi,addr slots
	add  edi,eax							; get slot address
    xor  eax,eax
    mov  al,b[charin]						; load rotor number
    sub  al,031h							; change char 1-5 to binary 0-4
    shl	 eax,4								; multiply by 16 (each rotor set is 16 bytes) to get offset of requested rotor
    mov  rbx,[rotor1+eax]					; load hex dword from rotor
    mov  [edi],rbx				 			; store hex dword into slot.rotty.hex
    mov  cl,[rotor1+eax+8]					; load notch byte from rotor
    mov  [edi+8],cl							; move notch byte into slot.rotty.notch
    mov  cl,[charin]						; load rotor number
    mov  [edi+10h],cl						; save in slot
    ;-------------------------------------------
    ; get slot start character 0-F
    lea  edx,addr message2					
    mov  b[edx+27],030h						; insert slot number into start position message
    mov  eax,[pslotno]						;
    add  b[edx+27],al						;
    invoke WriteFile,[hout],addr message2,30,addr bout,0
    invoke ReadFile,[hin],addr charin,3,addr bin,0 
    mov  al,[charin]
	mov  [edi+011h],al						; save the start character into slot.rotstart
    call hexer								; change start character into a hex nibble
:   mov  rbx,[edi]							; load current slot rotor 
    rol  rbx,4								; move nibble to lower 
    and  rbx,0Fh							;
    cmp  al,bl								; is the rotor correctly positioned?
    je   >									; if so, leave now
    rol  q[edi],4							; turn the rotor one nibble
    jmp  <									;  
:	ret
EndF

;===================================================
; ENIGMATE: main processing cycle
;===================================================
Enigmate FRAME pnibble
    uses eax,ebx,ecx    
    mov  ecx,[pnibble]			; use ecx to use in plugs
    and  ecx,0Fh				;  
    xor  eax,eax				; clear eax for processing the nibble
    ;------------------------------------------------
    ;  PLUGBOARD: run through plugs 
    mov   al,[xplugs+ecx]
    ;------------------------------------------------
    ;  ROTORS: run through slots
    invoke slotfwd,1,eax
    invoke slotfwd,2,eax
    invoke slotfwd,3,eax
    ;------------------------------------------------
    ; REFLECTOR: reflect back using a symmetric reflection
    not   al						; not will substitute F for 0, E for 1, etc
    and   al,0Fh					; remove upper nibble
    ;------------------------------------------------
    ;  ROTORS: run back through slots
    invoke slotbck,3,eax
    invoke slotbck,2,eax
    invoke slotbck,1,eax
    ;------------------------------------------------
    ;  PLUGBOARD: run through plugs 
    mov   ecx,eax
    mov   al,[xplugs+ecx]
    ;------------------------------------------------
    ;  store cipher nibble
    mov    bl,[ciph]
    shl    bl,4							; move nibble up
    or     bl,al    	           		; put lower nibble in
    mov    [ciph],bl					; store in ciph
    ;-------------------------------------------------
    ; turn rotor in slot 1...check for notch
    mov	   rax,[slots]					; get rotor
    rol    rax,4						; turn rotor one nibble
    mov    [slots],rax					; save rotor    
	rol	   rax,4						; rotate top nibble down to bottom	
    and    rax,0Fh						; clear top nibble    
    cmp    al,[slots.rotty.notch]		; check against rotor notch
    jne    >
    ;-------------------------------------------------
    ; turn rotor in slot 2...check for notch
    mov	   rax,[slots+24]				; get rotor
    rol    rax,4						; turn rotor one nibble
    mov    [slots+24],rax				; save rotor    
	rol	   rax,4						; rotate top nibble down to bottom	
    and    rax,0Fh						; clear top nibble    
    cmp    al,[slots.rotty.notch+24]	; check against rotor notch
    jne    >
    ;-------------------------------------------------
    ; turn rotor in slot 3...no check needed
    mov	   rax,[slots+48]				; get rotor
    rol    rax,4						; turn rotor one nibble
    mov    [slots+48],rax				; save rotor    
:   ret
EndF

;=====================================================
; SLOTFWD: use slot rotor to forward transpose nibble
;=====================================================
slotfwd FRAME pslotno, pnibble
    uses ebx,ecx,edx,edi
    ;----------------------------
    ; position at slot
    xor  edx,edx
    mov  eax,[pslotno]						; get slot number
    dec  eax								;
    mul  b[m24]								; calculate offset to start of slot
    mov  edi,addr slots						; 
    mov  rbx,[edi+eax]						; get slot rotor hex	
    ;------------------------------
    ; get rotor offset
    mov  ecx,[pnibble]						; find incoming character
    shl  ecx,2								; convert it to a nibble offset
    ;------------------------------
    ; extract nibble into al
    rol  rbx,cl								; rotate nibble to the front
	rol	 rbx,4								; then rotate around to bl
    mov  rax,rbx							; put rotor into rax
    and  rax,0Fh							; clear all but nibble
	ret
EndF

;=====================================================
; SLOTBCK: use slot rotor to backward transpose nibble
;=====================================================
slotbck FRAME pslotno, pnibble
    uses ecx,edi
    ;----------------------------
    ; position at slot
    xor  edx,edx
    mov  eax,[pslotno]						; get slot number
    dec  eax								;
    mul  b[m24]								; convert to offset 
    mov  edi,addr slots						; 
    add  edi,eax 							; point to start of slot
    ;-----------------------------
    ; locate nibble
    mov  eax,[pnibble]						; put nibble into al
    call findch								; get position in ecx
    mov  al,cl								; move into al as the substitution
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
    ;------------------------------------------------
    ;  Enigmatic encryptor now configured 
    invoke CreateFileA,ADDR confile,GENERIC_WRITE,0,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0           
    mov    [hConfig], eax
    cmp    eax,INVALID_FILE_HANDLE
    je     >badfilename
    invoke WriteFile,[hConfig],addr configdata,[configlen],addr bout,0
    invoke CloseHandle,[hConfig]	
    ret

;=============================================================
; Ciphering between ciphers and plaintext
;=============================================================   
cipher:
    ;-------------------------------------------------
    ; recover configuration data
    invoke  CreateFileA,ADDR confile,GENERIC_READ,0,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0           
    mov     [hConfig], eax
    cmp     eax,INVALID_FILE_HANDLE
    je      >badconfig
    invoke  ReadFile,[hConfig],addr configdata,[configlen],addr bin,0
    invoke  CloseHandle,[hConfig]    
    invoke  displayconfig
    ;-------------------------------------------------
    ; Get file names and open them
    invoke WriteFile,[hout],addr message4,23,addr bout,0
    invoke ReadFile,[hin],addr strbuff,60,addr bin,0
    mov    eax,[bin]
    sub    eax,2
    mov    b[strbuff+eax],00h
    invoke CreateFileA,ADDR strbuff,GENERIC_READ,0,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0           
    mov    [hfin], eax
    cmp    eax,INVALID_FILE_HANDLE
    je     >badfilename
    invoke WriteFile,[hout],addr message5,23,addr bout,0
    invoke ReadFile,[hin],addr strbuff,60,addr bin,0
    mov    eax,[bin]
    sub    eax,2
    mov    b[strbuff+eax],00h
    invoke CreateFileA,ADDR strbuff,GENERIC_WRITE,0,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0           
    mov    [hfout], eax
    cmp    eax,INVALID_FILE_HANDLE
    je     >badfilename
    ;-------------------------------------------------
    ; get file size, and cycle each byte through
    invoke  GetFileSize,[hfin],0
    mov     r15, eax						; r15 holds file size
cuploop:
    ;------------------------------------------------
    ; get next byte from plaintext
    invoke ReadFile,[hfin],addr charin,1,addr bin,0
    xor    eax,eax
    mov    [ciph],eax
    mov    al,[charin]
    shr    al,4
    invoke Enigmate,eax
    mov    al,[charin]
    and    al,0Fh
    invoke Enigmate,eax
    ;------------------------------------------------
    ; put next byte out to cipher
    invoke WriteFile,[hfout],addr ciph,1,addr bout,0
    dec    r15						
    jnz    cuploop
    invoke CloseHandle,[hfin]
    invoke CloseHandle,[hfout]
    ret

;=====================================
; Error message displays
;=====================================
badfilename:
    invoke WriteFile,[hout],addr badfile,32,addr bout,0 
    ret
badconfig:
    invoke WriteFile,[hout],addr noconfig,32,addr bout,0 
    ret
EndF

