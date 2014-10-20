;Tyler Coffman
;CS M30 9/31/10

.586
.MODEL flat, stdcall

include Win32API.asm
include prototypes.inc

.STACK 4096

.DATA

prompt	byte "Enter executable filename: ", 0
promptBytesWritten dword 0

;file information
FileName                byte    128 dup (0)
InputBuffer             byte    1024 dup (0)
BytesRead               dword   0
FileHandle              dword   0
FileSize                dword   0
BytesWritten			dword	0

;I/O handles
hStdOut			dword		0
hStdIn			dword		0

;Code info
RegisterArray	byte	6 dup (0)

.CODE

start:		
	;Get output handle
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov  hStdOut, eax

	;Get input handle		
	invoke  GetStdHandle, STD_INPUT_HANDLE          ;win32 function
	mov     hStdIn,eax                              ;stores the input handle which was placed in EAX by GetStdHandle

	;*********************
	; Get filename of executable
	;*********************
	invoke	WriteConsoleA, hStdOut, OFFSET prompt, SIZEOF prompt, OFFSET promptBytesWritten, 0	
	invoke  ReadConsoleA, hStdIn, OFFSET FileName, SIZEOF FileName, \
						OFFSET BytesRead, 0

	;Fix the FileName string by removing the \n at the end of the string, so that CreateFileA can use it
	move eax, BytesRead
	mov	FileName[eax], 0
	;**********************
	; Read the file into memory
	;**********************
	push OFFSET FileSize
	push OFFSET FileHandle
	push OFFSET BytesRead
	push OFFSET InputBuffer
	push OFFSET FileName
	call ReadTheFile

	;**********************
	; Execute the binary file
	;**********************
	push OFFSET hStdOut
	push OFFSET BytesRead
	push OFFSET InputBuffer
	push OFFSET RegisterArray
	call ExecuteBinary 
			
	;terminate process
	invoke ExitProcess, 0
END start
