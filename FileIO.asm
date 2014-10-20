.586
.MODEL flat, stdcall

include Win32API.asm

.STACK 4096




		        .CODE


ReadTheFile        	        proc		;Parameter list: &filename, &InputBuffer, &BytesRead, &FileHandle, &FileSize
										;				 8[ebp]		12[ebp]		  16[ebp]	  20[ebp]	   24[ebp]
			;save old base pointer
			push ebp
			mov	 ebp, esp

			;save registers
			push eax
			push ebx
			push ecx

		    ;*********************************
		    ; Open existing file for Reading
		    ;*********************************
		    invoke  CreateFileA, 8[ebp], GENERIC_READ, FILE_SHARE_READ,\
		                         0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
		    cmp     eax,-1				;was open successful?
		    je		Finish              ;No....then Exit

			;Yes...then save file handle
			mov		ebx, 20[ebp]	;move address of FileHandle into ebx
		    mov		[ebx],eax       ;save file handle
			mov		20[ebp], eax	;now that the file handle has been returned, let 20[ebp] store the value instead of the address
		
		    ;*********************************
		    ; Determine the size (in bytes)
		    ; of the file
		    ;*********************************
	  	    invoke	GetFileSize, 20[ebp], 0		;20[ebp] is file handle
			
			;save filesize
			mov		ebx, 24[ebp]	;save address of FileSize to ebx
		    mov     [ebx], eax		;return filesize through parameter
			mov		24[ebp], eax	;now that filesize has been returned, store value instead of pointer
		
		    ;*********************************
		    ; Read the entire file into InputBuffer
		    ;*********************************
			mov ebx, 12[ebp]	;set ebx to the address of InputBuffer
			mov ecx, 16[ebp]	;set ecx to the address of BytesRead

		    invoke  ReadFile, 20[ebp], ebx, 24[ebp], ecx, 0
		    cmp		eax,0				;was it successful?
		    je		Finish				;No...then Exit

		    ;*********************************
		    ; Close the file
		    ;*********************************
		    invoke  CloseHandle, 20[ebp]

			;restore registers
			pop ecx
			pop ebx
			pop eax
			pop ebp

			ret

			Finish:
			invoke ExitProcess, 0
ReadTheFile	            endp

END   ReadFile


