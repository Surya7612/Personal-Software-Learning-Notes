.Data
hInst	    dq	0
slot1   	db	5
slot2		db	2
slot3		db	3
settings	db	3 DUP 1

plug1		db	2Fh
plug2		db	16h
rotten      db  ?
welcome     db  'Enigma-like file encryptor',0Dh,0Ah
rotor1		dq	01F46C8037B9AD25Eh
rotor2		dq	0EFA87B439D5216C0h
rotor3		dq	00F732D168C4BA59Eh
rotor4		dq	0F0E8143CA2695B9Dh
rotor5		dq	0AB8736E1F0C295D4h

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
	ret
EndF
