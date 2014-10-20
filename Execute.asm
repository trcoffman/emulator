.586
.MODEL flat, stdcall

include Win32API.asm

;my constants
opAdd	EQU		11h
opSub	EQU		22h
opXor	EQU		44h
opLoad	EQU		05h
opLoadR	EQU		55h
opStore	EQU		06h
opStoreR EQU	66h
opOut	EQU		0CCh
opJnz	EQU		0AAh
opHalt	EQU		0FFh	

.STACK 4096

.DATA

.CODE

ExecuteBinary	proc	;param: RegArray 8[ebp], Memory 12[ebp], MemorySize 16[ebp], hStdOut 20[ebp]
	
	;**************
	; Create stack frame
	;**************
	push ebp
	mov	 ebp, esp

	;*************
	; Allocate Local Variables
	;*************
	push eax		;Allocate dword
	push eax		;Allocate dword

	;***************
	; Registers used
	;***************
	push eax ; ax is The instruction pointer
	push edi ; edi is the register array pointer
	push esi ; esi is the input buffer pointer
	push ebx ; used to store instruction parameter
	push ecx ; used to store instruction parameter\
	push edx ; used for LoadR

	xor eax, eax			; point to the offset 0 in InputBuffer
	mov edi, 8[ebp]		; edi now points to RegArray
	mov esi, 12[ebp]	; esi now points to InputBuffer

	;***********
	; Initialize local variables
	;***********
	mov [ebp-4], eax ;Output Buffer
	mov [ebp-8], eax ;Bytes Written


	;***************
	; execute an instruction
	;***************
	Exec:
	;clear out our input registers
	xor ebx, ebx
	xor ecx, ecx

	;Read a byte and execute it.
	mov	bl, [esi][eax]

	;Figure out what type of instruction it is
	;is it Halt?
	cmp bl, opHalt
	je Finish

	cmp bl, opAdd	;Add
	je _Add
	cmp bl, opSub	;Sub
	je _Sub
	cmp bl, opXor	;Xor
	je _Xor
	cmp bl, opLoad	;Load
	je _Load
	cmp bl, opLoadR	;LoadR
	je _LoadR
	cmp bl, opStore ;Store
	je _Store
	cmp bl, opStoreR ;StoreR
	je _StoreR
	cmp bl, opOut	;Out
	je _Out
	cmp bl, opJnz	;Jnz
	je _Jnz

	;If none of the jumps has been triggered yet, invalid instruction, jump to Error label
	jmp Error


	;****************
	; Add
	; [3 byte instruction]
	;****************
	_Add:
	;read operands into bl and cl
	mov bl, [esi][eax+1]
	mov cl, [esi][eax+2]
	;set cl to the value of the register it refers to
	mov cl, [edi][ecx]
	;add cl to the Register that bl represents
	add [edi][ebx], cl
	
	;shift the instruction pointer to the next instruction
	add	ax, 3;

	;execute next instruction
	jmp Exec

	;***************
	; Sub
	; [3 byte instruction]
	;***************
	_Sub:
	;read operands into bl and cl
	mov bl, [esi][eax+1]
	mov cl, [esi][eax+2]
	;set cl to the value of the register it refers to
	mov cl, [edi][ecx]
	;subtract cl from the Register that bl represents
	sub [edi][ebx], cl
	
	;shift the instruction pointer to the next instruction
	add	ax, 3;

	jmp Exec	;End Sub

	;***************
	; Xor
	; [3 byte instruction]
	;***************
	_Xor:
	;read operands into bl and cl
	mov bl, [esi][eax+1]
	mov cl, [esi][eax+2]
	;set cl to the value of the register it refers to
	mov cl, [edi][ecx]
	;xor cl with the Register that bl represents
	xor [edi][ebx], cl

	;shift the instruction pointer to the next instruction
	add	ax, 3;

	jmp Exec	;End XOR

	;***************
	; Load 
	; [4 byte instruction]
	;***************
	_Load:
	
	mov	bl, [esi][eax+1]		;read first argument [register]
	mov	cx, [esi][eax+2]		;read second argument [address]
	xchg cl, ch					;convert address to Little Endian
	mov cl, [esi][ecx]			;cl now contains the value at address cx
	mov [edi][ebx], cl			;Load Register #ebx with value stored at cx
	
	add ax, 4				;shift instruction pointer
	jmp Exec				;End Load

	;***************
	; LoadR
	; [4 byte instruction]
	;***************
	_LoadR:
	xor edx, edx				;only instruction that uses edx, so the only one that needs to zero it every time
	mov	bl, [esi][eax+1]		;read first argument [register]
	mov	cx, [esi][eax+2]		;read second argument [address]
	xchg cl, ch					;convert address to Little Endian
	mov dl, [edi][ebx]			;read the value of register #bl into dl
	add cx, dx					;cx now is the address of the data we want
	mov cl, [esi][ecx]			;cl now contains the value at address cx + dx
	mov [edi][ebx], cl			;Load Register #ebx with value stored at offset cx
	
	add ax, 4				;shift instruction pointer
	jmp Exec	;End LoadR

	;***************
	; Store
	; [3 byte instruction]
	;***************
	_Store:
	mov	bx, [esi][eax+1]		;read first argument [address]
	xchg bl, bh					;convert address to Little Endian
	mov cl, [edi]				;move R0 into cl
	mov [esi][ebx], cl			;move CL into Address
	
	add ax, 3					;shift instruction pointer 3 bytes-
	jmp Exec	;End Store

	;***************
	; StoreR
	; [4 byte instruction]
	;***************
	_StoreR:
	mov	bl, [esi][eax+1]		;read first argument [register]
	mov	cx, [esi][eax+2]		;read second argument [address]
	xchg cl, ch					;convert address to Little Endian
	mov bl, [edi][ebx]			;fetch the value of R# [the offset]
	add cx, bx					;add the offset to the address
	mov bl, [edi]				;fetch the value of R0 [the value to be stored]
	mov [esi][ecx], bl			;move value at bl into Address
	
	add ax, 4					;shift instruction pointer 4 bytes
	jmp Exec	;End StoreR

	;***************
	; Out
	; [2 byte instruction]
	;***************
	_Out:
	mov	bl, [esi][eax+1]		;read first argument [register]
	mov bl, [edi][ebx]			;bl = value of register #ebx
	mov [ebp-4], bl				;OutputBuffer = bl
	;output byte
	mov ecx, ebp				;ecx will be used to store addresses of the arguments
								;which will be pushed onto the call stack
	push 0
	sub ecx, 8					;ecx = &BytesWritten
	push ecx					;BytesWritten argument
	push 1						;Number of bytes to write
	add ecx, 4					;ecx = &OutputBuffer
	push ecx					;OutputBuffer
	add ecx, 24					;ecx now points to the address of outputHandle
	mov ecx, [ecx]				;dereference ecx to point to location of hStdOut
	mov ecx, [ecx]				;dereference it further to get value of hStdOut
	push ecx					;pass the standard output handle
	mov ebx, eax				;WriteConsoleA trashes eax, so we must save it
	call WriteConsoleA			;Write to the console 
	mov eax, ebx				;restore eax

	add ax, 2					;shift instruction pointer 2 bytes			
	jmp Exec


	;***************
	; Jnz
	; [4 byte instruction]
	;***************
	_Jnz:
	mov	bl, [esi][eax+1]		;read first argument [register]
	mov	cx, [esi][eax+2]		;read second argument [address]
	xchg cl, ch					;convert address to Little Endian
	mov dl, [edi][ebx]			;read the value of R# into bl
	cmp dl, 0					;compare R# to 0
	je	_Jz					;If it's equal, then simply jump to end of instruction code
	mov ax, cx					;If it's not equal, then jump to address cx
	jmp	endJnz 

	_Jz:
	add ax, 4
	endJnz:
	jmp Exec	;End Jnz

	
	Error:
	;TODO write error message code

	Finish:
	;**************
	; Restore registers
	;**************
	pop edx
	pop ecx
	pop ebx
	pop esi
	pop edi
	pop eax

	;*************
	; Deallocate local variables
	;*************
	add esp, 8

	pop ebp
	ret
	
ExecuteBinary	endp

END
