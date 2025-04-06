; API
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

;I/O EFh
;7
;6 IN
;5 IN
;4 IN 
;3 IN 
;2 IN CTRL
;1 IN DATA1
;0 IN DATA0

;7
;6 OUT
;5 OUT
;4 OUT CTRL
;3 OUT
;2 OUT
;1 OUT DATA1
;0 OUT DATA0

;**** 2BIT受信 ****
;AレジスタBIT2、BIT3を受信する
RCV2BIT	PROC
RCV2BIT:
	CALL	F1CHK		;BIT1が0になるまでLOOP
	IN	A,(0EFH)	;JOYPORT0 -> A
	PUSH 	AF
	RES	4,A
	OUT	(0EFH),A	;BIT6 <- 0
	CALL	F2CHK		;BIT1が1になるまでLOOP
	SET	4,A
	OUT	(0EFH),A	;BIT6 <- 1
	POP 	AF
	AND	03H
	RET
ENDP

;**** 1BYTE受信 ****
;受信DATAを2BITずつ受信しAレジスタにセットしてリターン
RCVBYTE	PROC
RCVBYTE:
	PUSH	BC
	CALL	RCV2BIT
	LD	B,A
	CALL	RCV2BIT
	RLA
	RLA
	ADD	A,B
	LD	B,A
	CALL	RCV2BIT
	RLA
	RLA
	RLA
	RLA
	ADD	A,B
	LD	B,A
	CALL	RCV2BIT
	RLA
	RLA
	RLA
	RLA
	RLA
	RLA
	ADD	A,B
	CPL
	POP	BC
	RET
ENDP

;**** BUSYをCHECK(1) ****
; EFH BIT1が0になるまでLOP
F1CHK	PROC
F1CHK:	IN	A,(0EFH)
	AND	04H        	;BIT2 = 0?
	JR	NZ,F1CHK
	RET
ENDP

;**** BUSYをCHECK(0) ****
; EFH BIT1が1になるまでLOOP
F2CHK	PROC
F2CHK:	IN	A,(0EFH)
	AND	04H        	;BIT2 = 1?
	JR	Z,F2CHK
	RET
ENDP

;**** 1BYTE送信 ****
;Aレジスタの内容を下位2BITずつ送信
SNDBYTE	PROC
SNDBYTE:
	PUSH	BC
	CPL
	LD	B,A
	AND	03H
	CALL	SND2BIT
	LD	A,B
	AND	0CH
	RRA
	RRA
	CALL	SND2BIT
	LD	A,B
	AND	30H
	RRA
	RRA
	RRA
	RRA
	CALL	SND2BIT
	LD	A,B
	AND	0C0H
	RRA
	RRA
	RRA
	RRA
	RRA
	RRA
	CALL	SND2BIT
	POP	BC
	RET
ENDP

;**** 2BIT送信 ****
;AレジスタBIT0、BIT1を送信する
SND2BIT	PROC
SND2BIT:
	SET	4,A
	OUT	(0EFH),A
	RES	4,A
	OUT	(0EFH),A	;BIT6 <- 0
	CALL	F1CHK		;BIT1が0になるまでLOOP
	SET	4,A
	OUT	(0EFH),A	;BIT6 <- 1
	CALL	F2CHK
	RET
ENDP
