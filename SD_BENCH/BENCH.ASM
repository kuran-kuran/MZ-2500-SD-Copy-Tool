
; 080h load
; 1バイト 送信 コマンド 080h
; 1バイト 受信 状態 (0:正常, 0F0h:SDカード初期化エラー, 0F4h:コマンドエラー)
; 33バイト 送信 ファイル名(0で終わる文字列、33バイトよりも短い場合は0埋め)
; 1バイト 受信 状態 (0:正常, 0F1h:ファイルが無い, 0FFh: ファイルがオープンできない)
; 2バイト 受信 ファイルサイズ
; 1バイト 送信 転送するか? (0:転送開始, その他:転送キャンセル)
; ファイルサイズ分のバイト数 受信 ファイルデータ
;
; 081h save
; 1バイト 送信 コマンド 080h
; 1バイト 受信 状態 (0:正常, 0F0h:SDカード初期化エラー, 0F4h:コマンドエラー)
; 33バイト 送信 ファイル名(0で終わる文字列、33バイトよりも短い場合は0埋め)
; 1バイト 送信 ファイルタイプ (1: OBT, 2:BTX, 3: BSD)
; 2バイト 送信 ファイルサイズ
; 2バイト 送信 スタートアドレス
; 2バイト 送信 実行アドレス
; 1バイト 受信 状態 (0:正常, 0FFh: ファイルがオープンできない)
;
	ORG	0A000h

MAIN	PROC
MAIN:
	RET
ENDP

READ	PROC
READ:
	; Send: command 80h
	LD	A, 80h
	CALL	SNDBYTE
	; Recv: status byte
	CALL	RCVBYTE
	AND	A
	JP	NZ, ERR
	; Send Filename 33bytes
	LD	B, 33
	LD	HL, READFILE
@@:
	LD	A, (HL)
	CALL	SNDBYTE
	INC	HL
	DEC	B
	DJNZ	@b
	; Recv: status byte
	CALL	RCVBYTE
	AND	A
	JP	NZ, ERR
	; Recv: filesize
	CALL	RCVBYTE
	LD	L, A
	CALL	RCVBYTE
	LD	H, A ; HL = filesize
	; Transfar start
	XOR	A
	CALL	SNDBYTE
	; Recv filedata
@@:
	CALL	RCVBYTE
	DEC	HL
	LD	A, H
	OR	L
	JR	NZ, @b

	RET
ERR:
	SCF
	RET
ENDP

INCLUDE "SDTOOL.ASM"

; 33バイト
READFILE:
	DB	"test_2000H_2000H",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


	END 0A000h
