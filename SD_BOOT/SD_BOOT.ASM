CR2		EQU	02h	; 行の先頭で無ければ改行
CRT1C		EQU	03h	; 1文字表示 A:文字コード
CRTMSG		EQU	05h	; 文字列表示 DE:文字列先頭アドレス 00Hで終了すること
TINIT		EQU	64h	; テキスト画面を初期化

	ORG	02000h

MAIN	PROC
MAIN:
	NOP

	LD	A, 000001000b
	RST	18h
	DB	TINIT
	LD	A, 12 ; cls
	RST	18h
	DB	CRT1C

	LD	DE, MES_HELLO
	RST	18h
	DB	CRTMSG
	RST	18h
	DB	CR2
	; BOOTをFD00hへ転送する
	LD	HL, BOOT_PROC
	LD	DE, 0FD00h
	LD	BC, BOOT_END - BOOT
	LDIR
	JP	BOOT
ENDP

MES_HELLO:
	DB	"Hello MZ-2500", 0
MAIN_END:

BOOT_PROC:
	ORG	0FD00h
BOOT	PROC
BOOT:
	; Loading message
	LD	DE, MES_LOADING
	RST	18h
	DB	CRTMSG
	RST	18h
	DB	CR2

	; Send: command 80h
	LD	A, 80h
	CALL	SNDBYTE ; command

LD	A, 'A'
RST	18h
DB	CRT1C

	; Recv: status byte
	CALL	RCVBYTE ; status
	AND	A
	JP	NZ, ERR

LD	A, 'B'
RST	18h
DB	CRT1C

	; Send Filename 33bytes
	LD	B, 33
	LD	HL, READFILE
filename_loop:
	LD	A, (HL)
	PUSH	AF
	CALL	SNDBYTE ; filename 33bytes
	POP	AF

	OR	A
	JR	NZ, @f
	LD	A, '#'
@@:
	RST	18h
	DB	CRT1C

	INC	HL
	DJNZ	filename_loop

	RST	18h
	DB	CR2

LD	A, 'C'
RST	18h
DB	CRT1C

	; Recv: status byte
	CALL	RCVBYTE ; status
	AND	A
	JP	NZ, ERR

LD	A, 'D'
RST	18h
DB	CRT1C

	; Recv: filesize
	CALL	RCVBYTE ; filesize low
	LD	C, A
	CALL	RCVBYTE ; filesize high
	LD	B, A ; HL = filesize

LD	A, 'E'
RST	18h
DB	CRT1C

	; Transfar start
	XOR	A
	CALL	SNDBYTE ; start

LD	A, 'F'
RST	18h
DB	CRT1C

	; Recv filedata
@@:
	CALL	RCVBYTE ; data
	LD	(HL), A
	INC	HL
	DEC	DE

RST	18h
DB	CRT1C

	LD	A, B
	OR	C
	JR	NZ, @b

	; Boot
	XOR	A
	OUT	(0B4H),A
	OUT	(0B5H),A ; 0
	LD	A, 2
	OUT	(0B5H),A ; 2
	INC	A
	OUT	(0B5H),A ; 3
	INC	A
	OUT	(0B5H),A ; 4
	INC	A
	OUT	(0B5H),A ; 5
	INC	A
	OUT	(0B5H),A ; 6
	INC	A
	OUT	(0B5H),A ; 7
	INC	A
	OUT	(0B5H),A ; 8

	JP	2000h

ERR:
	SCF
	LD	DE, MES_ERROR
	RST	18h
	DB	CRTMSG
	RST	18h
	DB	CR2
	RET
ENDP

INCLUDE "SD_TOOL.ASM"

; 33バイト
READFILE:
	DB	"@BOOT-A MZ-2500.bin", 0
	DB	00h, 00h ,00h ,00h ,00h ,00h ,00h ,00h, 00h ,00h ,00h ,00h ,00h

MES_LOADING:
	DB	"Loading ", 0

MES_NOTFOUND:
	DB	"Not found", 0

MES_ERROR:
	DB	"Error", 0

	DW	MAIN_END - MAIN
	DW	BOOT_END - BOOT
	DW	32768 - (MAIN_END - MAIN) - (BOOT_END - BOOT)

BOOT_END:

	DS	32768 - (MAIN_END - MAIN) - (BOOT_END - BOOT)

	END 02000h
