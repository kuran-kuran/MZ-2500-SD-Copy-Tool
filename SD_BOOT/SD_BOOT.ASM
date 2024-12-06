CR2		EQU	02H	; 行の先頭で無ければ改行
CRT1C		EQU	03H	; 1文字表示 A:文字コード
CRTMSG		EQU	05H	; 文字列表示 DE:文字列先頭アドレス 00Hで終了すること

	ORG	02000h

MAIN	PROC
MAIN:
	NOP
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

	; Recv: status byte
	CALL	RCVBYTE ; status
	AND	A
	JP	NZ, ERR

	; Send Filename 33bytes
	LD	B, 33
	LD	HL, READFILE
filename_loop:
	LD	A, (HL)
	CALL	SNDBYTE ; filename 33bytes

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

	; Recv: status byte
	CALL	RCVBYTE ; status
	AND	A
	JP	NZ, ERR

	; Recv: filesize
	CALL	RCVBYTE ; filesize low
	LD	C, A
	CALL	RCVBYTE ; filesize high
	LD	B, A ; HL = filesize

	; Transfar start
	XOR	A
	CALL	SNDBYTE ; start

	; Recv filedata
@@:
	CALL	RCVBYTE ; data
	LD	(HL), A
	INC	HL
	DEC	DE
	LD	A, B
	OR	C
	JR	NZ, @b

	; Boot
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

BOOT_END:

	DS	32226 - (MAIN_END - MAIN) + (BOOT_END - BOOT)

	END 02000h
