CR2		EQU	02H	; 行の先頭で無ければ改行
CRT1C		EQU	03H	; 1文字表示 A:文字コード
CRTMSG		EQU	05H	; 文字列表示 DE:文字列先頭アドレス 00Hで終了すること

MSG	EQU	00889H	; メッセージ表示(0Dh終了)
LETNL	EQU	00A2EH	; [CR]の実行、改行
PRT3	EQU	008B5H	; Aレジスタの1文字出力 制御無し
PRNT	EQU	008C6H	; Aレジスタの1文字出力 制御有

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
	CALL	MSG
	CALL	LETNL

	LD	A, 80h
	CALL	SNDBYTE ; command

	; Recv: status byte
	LD	DE, MES2
	CALL	MSG
	CALL	LETNL

	CALL	RCVBYTE ; status
	AND	A
	JP	NZ, ERR

	; Send Filename 33bytes
	LD	DE, MES3
	CALL	MSG
	CALL	LETNL

	LD	B, 33
	LD	HL, READFILE
filename_loop:
	LD	A, (HL)

@@:
	PUSH	AF
	CALL	PRNT
	POP	AF

	CALL	SNDBYTE ; filename 33bytes
	INC	HL
	DJNZ	filename_loop

	CALL	LETNL

	; filename 33bytes
;	LD	DE, READFILE
;	CALL	MSG
;	CALL	LETNL

	; Recv: status byte
	LD	DE, MES4
	CALL	MSG
	CALL	LETNL

	CALL	RCVBYTE ; status
	AND	A
	JP	NZ, ERR

	; Recv: filesize
	LD	DE, MES5
	CALL	MSG
	CALL	LETNL

	CALL	RCVBYTE ; filesize low
	LD	L, A
	CALL	RCVBYTE ; filesize high
	LD	H, A ; HL = filesize

	; Transfar start
	LD	DE, MES6
	CALL	MSG
	CALL	LETNL

	XOR	A
	CALL	SNDBYTE ; start

	; Recv filedata
	LD	DE, MES7
	CALL	MSG
	CALL	LETNL

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
	CALL	MSG
	CALL	LETNL

	HALT

	RET
ENDP

INCLUDE "SDTOOL.ASM"

; 33バイト
READFILE:
	DB	"BASIC-M25(6Z002)_2000H_2000H.OBT",0h

MES1:
	DB	"Send: command 80h",0Dh

MES2:
	DB	"Recv: status byte", 0Dh

MES3:
	DB	"Send Filename 33bytes",0Dh

MES4:
	DB	"Recv: status byte", 0Dh

MES5:
	DB	"Recv: filesize", 0Dh

MES6:
	DB	"Transfar start", 0Dh

MES7:
	DB	"Recv filedata", 0Dh

ERROR_MES:
	DB	"Error", 0Dh

	END 0A000h
