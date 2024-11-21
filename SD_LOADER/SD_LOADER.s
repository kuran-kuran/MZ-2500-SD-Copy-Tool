CR2			EQU		02H					;行の先頭で無ければ改行
CRTMSG		EQU		05H					;文字列表示 DE:文字列先頭アドレス 00Hで終了すること
COUNT		EQU		17H					;Bレジスタ <- (DE)の文字列長
DEVFN		EQU		2DH					;(DE)の文字列をデバイス名ディレクトリ名、ファイル名として解釈する
										;DE:文字列先頭アドレス B:文字列長
LOPEN		EQU		2FH					;ファイルのREADオープン .DEVFNをコールした後にコールする。
SAVEF		EQU		31H					;ファイルをSAVEオープン .DEVFNをコールした後にコールする。
DFUNC		EQU		42H					;A:1 レコード単位のREAD A:2 レコード単位のSAVE
										;HL:データのアドレス DE:バイトサイズ BC:ブロックNO

ELMD		EQU		0800H				;ファイルモード 1:OBJ 2:BTX 3:BSD
ELMD1		EQU		0801H				;ファイル名
ELMD20		EQU		0814H				;ファイルサイズ
ELMD22		EQU		0816H				;LOAD開始アドレス
ELMD24		EQU		0818H				;実行開始アドレス
ELMD26		EQU		081AH
ELMD30		EQU		081EH				;開始ブロックNO
ELMD32		EQU		0820H

SVC			MACRO	a1
			RST		18H
			DB		a1
			ENDM

;EFH
;7
;6 IN
;5 IN
;4 IN 
;3 IN 
;2 IN CTRL
;1 IN DATA1
;0 IN DATA0

;EFH
;7
;6 OUT
;5 OUT
;4 OUT CTRL
;3 OUT
;2 OUT
;1 OUT DATA1
;0 OUT DATA0

			ORG		0A000H

			LD		DE,TITLE			;「COPYING SD_TRANS.bin」表示
			SVC		CRTMSG
			SVC		CR2					;改行
			
			LD		A,80H				;コマンド「80」送信(SDからLOAD)
			CALL	SBYTE
			CALL	RBYTE				;0以外ならERROR
			AND		A
			JP		NZ,ERR
			
			LD		DE,FNAME			;DOSファイルネーム送信
			LD		B,21H
FN1:		LD		A,(DE)
			CALL	SBYTE
			INC		DE
			DJNZ	FN1
			CALL	RBYTE				;0以外ならERROR
			AND		A
			JP		NZ,ERR

			LD		A,01H				;ファイルモード:BINARY
			LD		(FMODE),A			;ファイルモード退避
			
			CALL	RBYTE
			LD		L,A
			CALL	RBYTE
			LD		H,A
			LD		(FILESIZE),HL		;ファイルサイズ受信退避

			LD		HL,0A000H
			LD		(LOADADR),HL		;LOAD開始アドレス受信退避

			LD		(EXECADR),HL		;実行開始アドレス受信退避
			
			LD		DE,FNAME			;コピー先ファイル名設定
			SVC		COUNT				;Bレジスタ <- (DE)の文字列長
			SVC		DEVFN				;ソースファイル名解釈
			LD		A,(FMODE)
			LD		(ELMD),A			;ファイルモード設定
			LD		HL,(FILESIZE)
			LD		(ELMD20),HL			;ファイルサイズ設定
			LD		HL,(LOADADR)
			LD		(ELMD22),HL			;LOAD開始アドレス設定
			LD		HL,(EXECADR)
			LD		(ELMD24),HL			;実行開始アドレス設定
			XOR		A
			SVC		SAVEF				;コピー先ファイルをSAVEオープン
			LD		HL,(ELMD30)			;開始ブロックNOを取得
			LD		(DBLOCK),HL			;退避
;
			XOR		A					;処理継続指示
			CALL	SBYTE
			LD		BC,(FILESIZE)
			LD		A,B
			AND		A
			JR		Z,RCV2

RCV0:		PUSH	BC
			LD		B,00H
			LD		HL,BUFFER
RCV1:		CALL	RBYTE
			LD		(HL),A
			INC		HL
			DJNZ	RCV1

			LD		DE,FNAME			;コピー先ファイル名設定
			SVC		COUNT				;Bレジスタ <- (DE)の文字列長
			SVC		DEVFN				;コピー元ファイル名解釈
			LD		HL,BUFFER
			LD		DE,0100H
			LD		BC,(DBLOCK)			;コピー先ブロック位置設定
			LD		A,02H
			SVC		DFUNC				;1レコード書き込み
			INC		BC
			LD		(DBLOCK),BC			;コピー先ブロック位置+1

			POP		BC
			DJNZ	RCV0

RCV2:		LD		A,C
			AND		A
			JR		Z,RCV4
			
			LD		B,C
			LD		HL,BUFFER
RCV3:		CALL	RBYTE
			LD		(HL),A
			INC		HL
			DJNZ	RCV3

			LD		DE,FNAME			;コピー先ファイル名設定
			SVC		COUNT				;Bレジスタ <- (DE)の文字列長
			SVC		DEVFN				;コピー元ファイル名解釈
			LD		HL,BUFFER
			LD		DE,0100H
			LD		BC,(DBLOCK)			;コピー先ブロック位置設定
			LD		A,2
			SVC		DFUNC				;1レコード書き込み

RCV4:		LD		DE,OK_MSG			;「COPY OK」表示
			JR		RCV5
;
ERR:		LD		DE,ERR_MSG			;「COPY ERROR」表示
RCV5:		SVC		CRTMSG
			RET

RBYTE:		JR		RCVBYTE
SBYTE:		JR		SNDBYTE

;**** 2BIT受信 ****
;AレジスタBIT2、BIT3を受信する
RCV2BIT:
			CALL	F1CHK				;BIT1が0になるまでLOOP
			IN		A,(0EFH)			;JOYPORT0 -> A
			PUSH 	AF
			RES		4,A
			OUT		(0EFH),A			;BIT6 <- 0
			CALL	F2CHK				;BIT1が1になるまでLOOP
			SET		4,A
			OUT		(0EFH),A			;BIT6 <- 1
			POP 	AF
			AND		03H
			RET

;**** 1BYTE受信 ****
;受信DATAを2BITずつ受信しAレジスタにセットしてリターン
RCVBYTE:
			PUSH	BC
			CALL	RCV2BIT
			LD		B,A
			CALL	RCV2BIT
			RLA
			RLA
			ADD		A,B
			LD		B,A
			CALL	RCV2BIT
			RLA
			RLA
			RLA
			RLA
			ADD		A,B
			LD		B,A
			CALL	RCV2BIT
			RLA
			RLA
			RLA
			RLA
			RLA
			RLA
			ADD		A,B
			CPL
			POP		BC
			RET

;**** BUSYをCHECK(1) ****
; EFH BIT1が0になるまでLOP
F1CHK:		IN		A,(0EFH)
			AND		04H					;BIT2 = 0?
			JR		NZ,F1CHK
			RET

;**** BUSYをCHECK(0) ****
; EFH BIT1が1になるまでLOOP
F2CHK:		IN		A,(0EFH)
			AND		04H					;BIT2 = 1?
			JR		Z,F2CHK
			RET

;**** 1BYTE送信 ****
;Aレジスタの内容を下位2BITずつ送信
SNDBYTE:
			PUSH	BC
			CPL
			LD		B,A
			AND		03H
			CALL	SND2BIT
			LD		A,B
			AND		0CH
			RRA
			RRA
			CALL	SND2BIT
			LD		A,B
			AND		30H
			RRA
			RRA
			RRA
			RRA
			CALL	SND2BIT
			LD		A,B
			AND		0C0H
			RRA
			RRA
			RRA
			RRA
			RRA
			RRA
			CALL	SND2BIT
			POP		BC
			RET

;**** 2BIT送信 ****
;AレジスタBIT0、BIT1を送信する
SND2BIT:
			SET		4,A
			OUT		(0EFH),A
			RES		4,A
			OUT		(0EFH),A				;BIT6 <- 0
			CALL	F1CHK					;BIT1が0になるまでLOOP
			SET		4,A
			OUT		(0EFH),A				;BIT6 <- 1
			CALL	F2CHK
			RET
		
TITLE:		DEFB	'COPYING '
FNAME:		DEFB	'SD_TRANS.bin',00H
OK_MSG:		DEFB	'OK',0DH,00H
ERR_MSG:	DEFB	'ERROR',0DH,00H

DBLOCK:		DS		2
FMODE:		DS		1
FILESIZE:	DS		2
LOADADR:	DS		2
EXECADR:	DS		2
			
BUFFER:		DS		256

			END
