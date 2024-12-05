CR2		EQU	02H	; 行の先頭で無ければ改行
CRT1C		EQU	03H	; 1文字表示 A:文字コード
CRTMSG		EQU	05H	; 文字列表示 DE:文字列先頭アドレス 00Hで終了すること

	ORG	0A000h

MAIN	PROC
MAIN:
	CALL	READ
	RET
ENDP

READ	PROC
READ:
	; Send: command 80h
	LD	DE, MES1
	RST	18h
	DB	CRTMSG
	RST	18h
	DB	CR2

	LD	A, 80h
	CALL	SNDBYTE ; command

	; Recv: status byte
	LD	DE, MES2
	RST	18h
	DB	CRTMSG
	RST	18h
	DB	CR2

	CALL	RCVBYTE ; status
	AND	A
	JP	NZ, ERR

	; Send Filename 33bytes
	LD	DE, MES3
	RST	18h
	DB	CRTMSG
	RST	18h
	DB	CR2

	LD	B, 33
	LD	HL, READFILE
filename_loop:
	LD	A, (HL)

	JR	NZ, @f
	LD	A, '#'
@@:
	RST	18h
	DB	CRT1C

	CALL	SNDBYTE ; filename 33bytes
	INC	HL
	DJNZ	filename_loop

	RST	18h
	DB	CR2

	; filename 33bytes
;	LD	DE, READFILE
;	RST	18h
;	DB	CRTMSG
;	RST	18h
;	DB	CR2

	; Recv: status byte
	LD	DE, MES4
	RST	18h
	DB	CRTMSG
	RST	18h
	DB	CR2

	CALL	RCVBYTE ; status
	AND	A
	JP	NZ, ERR

	; Recv: filesize
	LD	DE, MES5
	RST	18h
	DB	CRTMSG
	RST	18h
	DB	CR2

	CALL	RCVBYTE ; filesize low
	LD	L, A
	CALL	RCVBYTE ; filesize high
	LD	H, A ; HL = filesize

	; Transfar start
	LD	DE, MES6
	RST	18h
	DB	CRTMSG
	RST	18h
	DB	CR2

	XOR	A
	CALL	SNDBYTE ; start

	; Recv filedata
	LD	DE, MES7
	RST	18h
	DB	CRTMSG
	RST	18h
	DB	CR2

@@:
	CALL	RCVBYTE ; data
	DEC	HL
	LD	A, H
	OR	L
	JR	NZ, @b

	RET
ERR:
	SCF
	LD	DE, ERROR_MES
	RST	18h
	DB	CRTMSG
	RST	18h
	DB	CR2
	RET
ENDP

INCLUDE "SDTOOL.ASM"

; 33バイト
READFILE:
	DB	"BASIC-M25(6Z002)_2000H_2000H.OBT",0

MES1:
	DB	"Send: command 80h",0

MES2:
	DB	"Recv: status byte", 0

MES3:
	DB	"Send Filename 33bytes",0

MES4:
	DB	"Recv: status byte", 0

MES5:
	DB	"Recv: filesize", 0

MES6:
	DB	"Transfar start", 0

MES7:
	DB	"Recv filedata", 0

ERROR_MES:
	DB	"Error", 0

	END 0A000h
