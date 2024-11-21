CR2			EQU		02H					;行の先頭で無ければ改行
CRT1C		EQU		03H					;1文字表示 A:文字コード
CRTMSG		EQU		05H					;文字列表示 DE:文字列先頭アドレス 00Hで終了すること
INKEY		EQU		0DH					;キーボードから1字入力 
										;入力 Aレジスタ BIT0 0:キーが押されていなければZF=1でリターン
										;					 1:キーが押されるまで待つ。
										;				BIT1 0:ファンクションキーを展開しない。
										;					 1:ファンクションキーを展開する。
										;				BIT2 0:カナ漢字変換をしない。
										;					 1:カナ漢字変換をする。
										;				BIT3 0:アルゴキー、HARDCOPYキーを有効にする。
										;					 1:アルゴキー、HARDCOPYキーはフラグのみセット。
DEHEX		EQU		14H					;ASCII文字列の16進数をバイナリに変換 入力 HL:文字列のポインタ 出力 DE:16進数
COUNT		EQU		17H					;Bレジスタ <- (DE)の文字列長
PRT1C		EQU		26H					;ファイルへ1文字出力 A:DATA
INP1C		EQU		27H					;ファイルから1文字入力 A:DATA CF=1:EOF
DEVFN		EQU		2DH					;(DE)の文字列をデバイス名ディレクトリ名、ファイル名として解釈する
										;DE:文字列先頭アドレス B:文字列長
LUCHK		EQU		2EH					;使用するLOGICAL UNITを指定する 入力 A:LU 出力 A 1:READ OPEN 2:WRITE OPEN 4:RANDOM OPEN CF=1 OPENされていない
LOPEN		EQU		2FH					;ファイルのREADオープン .DEVFNをコールした後にコールする。
SAVEF		EQU		31H					;ファイルをSAVEオープン .DEVFNをコールした後にコールする。
RWOPN		EQU		33H					;ファイルオープン D 1:READ OPEN 2:WRITE OPEN 3:RANDOM OPEN 10H:APPEND OPEN A:LOGICAL UNIT NUMBER
BINKEY		EQU		34H					;現在のカーソル位置から入力 出力 DE:文字列バッファ
CLKL		EQU		38H					;ファイルクローズ A 0:すべてをCLOSE/KILL 0以外:AのLUをCLOSE/KILL B=0 KILL B<>0 CLOSE
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

;7
;6 OUT
;5 OUT
;4 OUT CTRL
;3 OUT
;2 OUT
;1 OUT DATA1
;0 OUT DATA0

			ORG		0A000H

			LD		DE,TITLE			;TITLE表示
			SVC		CRTMSG
			SVC		CR2					;改行

GS1:		LD		DE,GSEL				;選択
			SVC		CRTMSG
			SVC		BINKEY
			LD		A,(DE)
			CP		39H					;9ならキャンセル
			JP		Z,ERR9
			CP		31H					;SLOAD
			JR		Z,SLOAD
			CP		32H					;SSAVE
			JP		Z,SSAVE
			CP		33H					;SDIR
			JP		Z,SDIR
			JR		GS1

;*********** BTX、OBT転送処理 SD -> FD **********************************
SLOAD:		LD		A,80H				;コマンド「80」送信(SDからLOAD)
			CALL	STCD
			AND		A					;0以外ならERROR
			JP		NZ,ERR1
			
			LD		DE,QNAME			;SD-CARDコピー元ファイル名入力
			SVC		CRTMSG
			SVC		BINKEY
			
			LD		B,21H
			LD		HL,DNAME
FN1:		LD		A,(DE)
			LD		(HL),A
			CALL	SBYTE				;ファイル名を送信
			INC		DE
			INC		HL
			DJNZ	FN1
			CALL	RBYTE				;ファイル名のファイルがSDに存在すればA=0 0以外ならERROR
			AND		A
			JP		NZ,ERR2

MD1:		LD		DE,QMODE			;ファイルモード指定
			SVC		CRTMSG
			SVC		BINKEY
			LD		A,(DE)
			CP		31H					;0以下ならやり直し
			JR		C,MD1
			CP		34H					;4以上ならやり直し
			JR		NC,MD1

			SUB		30H
			LD		(FMODE),A			;ファイルモード退避
			
			CALL	RBYTE
			LD		L,A
			CALL	RBYTE
			LD		H,A
			LD		(FILESIZE),HL		;ファイルサイズ受信退避

			LD		A,(FMODE)
			CP		01H
			JR		NZ,CP1
			
			LD		DE,QLOAD			;OBTファイルならLOAD START ADDRESS指定
			SVC		CRTMSG
			SVC		BINKEY
			LD		H,D
			LD		L,E
			SVC		DEHEX				;入力文字を16進数4桁に変換
			CALL	DSP4HEX				;DEレジスタの16進数を表示
			LD		(LOADADR),DE		;LOAD開始アドレス退避
			SVC		CR2					;改行

			LD		DE,QEXE				;OBTファイルならEXECUTE ADDRESS指定
			SVC		CRTMSG
			SVC		BINKEY
			LD		H,D
			LD		L,E
			SVC		DEHEX				;入力文字を16進数4桁に変換
			CALL	DSP4HEX				;DEレジスタの16進数を表示
			LD		(EXECADR),DE		;実行開始アドレス退避
			SVC		CR2					;改行
			JR		CP2
			
CP1:		LD		HL,0000H
			LD		(LOADADR),HL		;OBTファイル以外なら0000Hに設定
			LD		(EXECADR),HL		;OBTファイル以外なら0000Hに設定

CP2:		LD		DE,DNAME			;コピー先ファイル名設定
			SVC		COUNT				;Bレジスタ <- (DE)の文字列長
			SVC		DEVFN				;ソースファイル名解釈
			LD		A,(FMODE)
			CP		03H					;BSDファイルなら別処理
			JP		Z,BSD

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
			JR		Z,RCV2				;ブロック数が0ならRCV2へ

RCV0:		PUSH	BC
			LD		B,00H				;1ブロック分256Byteを受信してBUUFERに格納
			LD		HL,BUFFER
RCV1:		CALL	RBYTE
			LD		(HL),A
			INC		HL
			DJNZ	RCV1

			LD		DE,DNAME			;コピー先ファイル名設定
			SVC		COUNT				;Bレジスタ <- (DE)の文字列長
			SVC		DEVFN				;コピー元ファイル名解釈
			LD		HL,BUFFER
			LD		DE,0100H
			LD		BC,(DBLOCK)			;コピー先ブロック位置設定
			LD		A,02H
			SVC		DFUNC				;1レコード書き込み
			INC		BC
			LD		(DBLOCK),BC			;コピー先ブロック位置+1

			LD		A,2EH
			SVC		CRT1C				;進捗を「.」として表示
			POP		BC
			DJNZ	RCV0				;ブロック分ループ

RCV2:		LD		A,C
			AND		A
			JR		Z,RCV4				;1ブロックに満たない端数Byteが0ならRCV4へ
			
			LD		B,C					;端数分を受信
			LD		HL,BUFFER
RCV3:		CALL	RBYTE
			LD		(HL),A
			INC		HL
			DJNZ	RCV3

			LD		DE,DNAME			;コピー先ファイル名設定
			SVC		COUNT				;Bレジスタ <- (DE)の文字列長
			SVC		DEVFN				;コピー元ファイル名解釈
			LD		HL,BUFFER
			LD		DE,0100H
			LD		BC,(DBLOCK)			;コピー先ブロック位置設定
			LD		A,2
			SVC		DFUNC				;1レコード書き込み
			LD		A,2EH
			SVC		CRT1C				;進捗を「.」として表示

RCV4:		LD		DE,OK_MSG			;「COPY OK」表示
			JR		RCV5
;
ERR1:		LD		DE,ERR_MSG1			;SD-CARD INITIALIZE ERROR
			JR		RCV5
ERR2:		LD		DE,ERR_MSG2			;NOT FIND FILE
			JR		RCV5
ERR3:		LD		DE,ERR_MSG3			;BSD NOT OPEN
			JR		ERR31
ERR4:		LD		A,1
			LD		B,1
			SVC		CLKL				;ファイルクローズ
			LD		DE,ERR_MSG4			;BSD NOT WRITE MODE
ERR31:		LD		A,0FFH				;処理打ち切り指示
			CALL	SBYTE
			JR		RCV5
ERR5:		LD		A,1
			LD		B,1
			SVC		CLKL				;ファイルクローズ
			LD		DE,ERR_MSG5			;BSD NOT READ MODE
			JR		ERR31
ERR9:		LD		DE,ERR_MSG9			;COPY CANCEL
RCV5:		SVC		CRTMSG
			RET

;********** BSDファイル転送処理 SD -> FD ****************************
BSD:
			LD		(ELMD),A			;ファイルモード設定
			LD		D,2					;WRITE OPEN
			LD		A,1					;LOGICAL NO=1
			SVC		RWOPN
			LD		A,1
			SVC		LUCHK				;OPEN出来たかチェック
			JR		C,ERR3				;OPEN出来なかったらERR
			CP		2
			JR		NZ,ERR4				;WRITEモードでオープンされていなければERR
			
			XOR		A					;処理継続指示
			CALL	SBYTE
			LD		BC,(FILESIZE)
			LD		A,B
			OR		C
			JR		Z,BSD4				;ファイルサイズが0ならクローズ

BSD1:		CALL	RBYTE
			SVC		PRT1C
			DEC		BC
			LD		A,C
			AND		A
			JR		NZ,BSD2
			LD		A,2EH				;256Byteごとに進捗を「.」として表示
			SVC		CRT1C
BSD2:		LD		A,B
			OR		C
			JR		NZ,BSD1				;ファイルサイズ分ループ

BSD4:		LD		A,1
			LD		B,1
			SVC		CLKL				;ファイルクローズ
			
			JR		RCV4				;「COPY OK」表示

;*********** BTX、OBT転送処理 FD -> SD **********************************
SSAVE:
			LD		A,81H				;コマンド「81」送信(SDへSAVE)
			CALL	STCD
			AND		A					;0以外ならERROR
			JP		NZ,ERR1

			LD		DE,Q2NAME			;FDコピー元ファイル名入力
			SVC		CRTMSG
			SVC		BINKEY
			
			LD		B,21H
			LD		HL,DNAME
SS1:		LD		A,(DE)
			LD		(HL),A
			CALL	SBYTE				;ファイル名を送信
			INC		DE
			INC		HL
			DJNZ	SS1

			LD		DE,DNAME			;コピー先ファイル名設定
			SVC		COUNT				;Bレジスタ <- (DE)の文字列長
			SVC		DEVFN				;コピー元ファイル名解釈
			SVC		LOPEN				;コピー元ファイルREADオープン
			LD		A,(ELMD)			;ファイルモード読出し
			LD		(FMODE),A			;退避
			CALL	SBYTE				;ファイルモード送信

			LD		HL,(ELMD30)			;開始ブロックNOを読み出し
			LD		(DBLOCK),HL			;退避
			
			LD		HL,(ELMD20)			;ファイルサイズ読出し
			LD		(FILESIZE),HL		;退避
			LD		A,H
			CALL	SBYTE				;送信
			LD		A,L
			CALL	SBYTE				;送信

			LD		HL,(ELMD22)			;LOAD開始アドレス取得
			LD		(LOADADR),HL		;退避
			LD		A,H
			CALL	SBYTE				;送信
			LD		A,L
			CALL	SBYTE				;送信

			LD		HL,(ELMD24)			;実行開始アドレス取得
			LD		(EXECADR),HL		;退避
			LD		A,H
			CALL	SBYTE				;送信
			LD		A,L
			CALL	SBYTE				;送信

			CALL	RBYTE				;WRITEオープン出来ればA=0 0以外ならERROR
			AND		A
			JP		NZ,ERR2

			LD		A,(FMODE)
			CP		03H
			JP		Z,SBSD				;BSDファイルなら別処理

			XOR		A					;処理継続指示
			CALL	SBYTE
			LD		BC,(FILESIZE)
SS4:		PUSH	BC
			LD		DE,DNAME			;コピー元ファイル名
			SVC		COUNT				;Bレジスタ <- (DE)の文字列長
			SVC		DEVFN				;コピー元ファイル名解釈
			LD		HL,BUFFER
			LD		DE,0100H
			LD		BC,(DBLOCK)			;コピー元ブロック位置設定
			LD		A,1
			SVC		DFUNC				;1レコード読込
			INC		BC
			LD		(DBLOCK),BC			;コピー元ブロック位置+1

			LD		B,00H
			LD		HL,BUFFER
SS5:		LD		A,(HL)
			CALL	SBYTE
			INC		HL
			DJNZ	SS5
			
			LD		A,2EH
			SVC		CRT1C				;進捗を「.」として表示
			POP		BC
			DJNZ	SS4					;ブロック数分繰り返し

			LD		A,C
			AND		A
			JR		Z,SS7
			PUSH	BC
			LD		DE,DNAME			;コピー元ファイル名
			SVC		COUNT				;Bレジスタ <- (DE)の文字列長
			SVC		DEVFN				;コピー元ファイル名解釈
			LD		HL,BUFFER
			LD		DE,0100H
			LD		BC,(DBLOCK)			;コピー元ブロック位置設定
			LD		A,1
			SVC		DFUNC				;1レコード読込

			POP		BC
			LD		B,C
			LD		HL,BUFFER
SS6:		LD		A,(HL)
			CALL	SBYTE
			INC		HL
			DJNZ	SS6
			LD		A,2EH
			SVC		CRT1C				;進捗を「.」として表示
SS7:		JP		RCV4				;「COPY OK」表示
			
;********** BSDファイル転送処理 FD -> SD ********************
SBSD:
			LD		D,1					;READ OPEN
			LD		A,1					;LOGICAL NO=1
			SVC		RWOPN
			
			LD		A,1
			SVC		LUCHK				;OPEN出来たかチェック
			JP		C,ERR3				;OPEN出来なかったらERR
			CP		1
			JP		NZ,ERR5				;READEモードでオープンされていなければERR
			
			XOR		A					;処理継続指示
			CALL	SBYTE
			LD		BC,(FILESIZE)

SBSD1:		SVC		INP1C
			JR		C,SBSD2
			CALL	SBYTE
			DEC		BC
			LD		A,C
			AND		A
			JR		NZ,SBSD1
			LD		A,2EH				;256Byteごとに進捗を「.」として表示
			SVC		CRT1C
			JR		SBSD1
			
SBSD2:		LD		A,1
			LD		B,1
			SVC		CLKL				;ファイルクローズ
			
			JP		RCV4				;「COPY OK」表示

;************************* SD FILE DIRECTORY **********************************
SDIR:
			LD		DE,QFIND			;SD-CARDファイル名検索文字列入力
			SVC		CRTMSG
			SVC		BINKEY

			CALL	DIRLIST				;DIRLIST本体をコール
			CP		00H					;00以外ならERROR
			JR		Z,SLOAD2			;00ならDEにセットされているファイル名でSLOADを実行
			CP		01H					;01なら通常リターン
			RET		Z
SDIR5:		PUSH	AF
			CP		0F0H
			JP		NZ,SDIR3
			LD		DE,ERR_MSG1			;SD-CARD INITIALIZE ERROR
			JP		SDIR4
SDIR3:		CP		0F1H
			JP		NZ,SDIR99
			LD		DE,ERR_MSG2			;NOT FIND FILE
			JP		SDIR4
SDIR99:
			LD		DE,MSG99			;その他ERROR
SDIR4:		SVC		CRTMSG
			POP		AF
			RET

SLOAD2:		LD		A,80H				;コマンド「80」送信(SDからLOAD)
			CALL	STCD
			AND		A					;0以外ならERROR 0以外のはずはないが一応
			JP		NZ,ERR1
			
			LD		B,21H
			LD		DE,DNAME
FN2:		LD		A,(DE)
			CALL	SBYTE				;ファイル名を送信
			INC		DE
			DJNZ	FN2
			CALL	RBYTE				;ファイル名のファイルがSDに存在すればA=0 0以外ならERROR 0以外のはずはないが一応
			AND		A
			JP		NZ,ERR2
			JP		MD1

;**** DIRLIST本体 ****
;****              戻り値 A=エラーコード ****
DIRLIST:
			LD		A,82H				;DIRLISTコマンド82Hを送信
			CALL	STCD				;コマンドコード送信
			AND		A					;00以外ならERROR
			JP		NZ,DLRET
		
			PUSH	BC
			LD		B,21H				;ファイルネーム検索文字列33文字分を送信
STLT1:		LD		A,(DE)
STLT3:		PUSH	AF
			CALL	SNDBYTE				;ファイルネーム検索文字列を送信
			POP		AF
			AND		A					;00H以外ならDEをインクリメント
			JR		Z,STLT4
			INC		DE
STLT4:		DJNZ	STLT1				;33文字分ループ

			POP		BC
			CALL	RCVBYTE				;状態取得(00H=OK)
			AND		A					;00以外ならERROR
			JP		NZ,DLRET

DL1:		LD		DE,DNAME
DL2:		CALL	RCVBYTE				;'00H'を受信するまでを一行とする
			AND		A
			JR		Z,DL3
			CP		0FFH				;'0FFH'を受信したら終了
			JR		Z,DL4
			CP		0FDH				;'0FDH'受信で文字列を取得してSETLしたことを表示
			JR		Z,DL9
			CP		0FEH				;'0FEH'を受信したら一時停止して一文字入力待ち
			JR		Z,DL5
			LD		(DE),A
			INC		DE
			JR		DL2
DL3:		LD		(DE),A
			LD		DE,DNAME			;'00H'を受信したら一行分を表示して改行
			SVC		CRTMSG
DL33:
			SVC		CR2					;改行
			JP		DL1
DL4:		CALL	RCVBYTE				;状態取得(00H=OK)
			LD		A,01H
			JP		DLRET

DL9:		SVC		CR2					;改行
		
			LD		DE,DNAME			;選択したファイルネームを再度取得
DL91:		CALL	RCVBYTE
			LD		(DE),A
			CP		0DH
			JR		NZ,DL92
			XOR		A
DL92:		AND		A
			INC		DE
			JP		NZ,DL91

			LD		DE,SETMSG			;取得したファイルネームを表示
			SVC		CRTMSG
			SVC		CR2					;改行
			CALL	RCVBYTE				;状態取得(00H=OK)読み飛ばし
			JP		DLRET

DL5:
			LD		DE,MSG_KEY1			;HIT ANT KEY表示
			SVC		CRTMSG
DL6:
			XOR		A
			SVC		INKEY				;KEY SCAN
		
			JP		Z,DL6
			CP		1BH					;ESCで打ち切り
			JP		Z,DL7
			CP		30H					;数字0～9ならそのままArduinoへ送信してSETL処理へ
			JP		C,DL61
			CP		3AH
			JP		C,DL8
DL61:
			CP		42H					;「B」で前ページ
			JP		Z,DL8
			CP		62H					;「b」で前ページ
			JP		Z,DL8
			XOR		A					;それ以外で継続
			JP		DL8
DL7:		LD		A,0FFH				;0FFH中断コードを送信
DL8:		CALL	SNDBYTE
			JP		DL1
		
DLRET:		RET

;**** コマンド送信 (IN:A コマンドコード)****
STCD:		CALL	SNDBYTE          ;Aレジスタのコマンドコードを送信
			CALL	RCVBYTE          ;状態取得(00H=OK)
			RET

;******** DEレジスタの16進数を16進数文字列4桁に変換して表示 **************
DSP4HEX:
			PUSH	DE
			LD		DE,ADRS				;入力ADDRESS確認
			SVC		CRTMSG
			POP		DE
			LD		A,D
			CALL	DSPHEX				;Dレジスタ表示
			LD		A,E
			CALL	DSPHEX				;Eレジスタ表示
			RET

;******** Aレジスタの16進数を16進数文字列2桁に変換して表示 ****************
DSPHEX:
			PUSH	DE
			PUSH	AF
			SRL		A					;上位4Bit
			SRL		A
			SRL		A
			SRL		A
			CALL	HEX2ASC				;ASCII文字に変換
			SVC		CRT1C				;AレジスタのASCIIコードを表示
			POP		AF
			AND		0FH					;下位4Bit
			CALL	HEX2ASC				;ASCII文字に変換
			SVC		CRT1C				;AレジスタのASCIIコードを表示
			POP		DE
			RET

;********* Aレジスタの下位4Bitを16進数1桁としてASCIIコードに変換 ************
HEX2ASC:
			CP		0AH
			JR		NC,HA1
			ADD		A,30H				;0-9なら+30H
			JR		HA2
HA1:		ADD		A,37H				;A-Fなら+37H
HA2:		RET

RBYTE:		JP		RCVBYTE
SBYTE:		JP		SNDBYTE

;**** 2BIT受信 ****
;AレジスタBIT2、BIT3を受信する
RCV2BIT:
			CALL	F1CHK		;BIT1が0になるまでLOOP
			IN		A,(0EFH)	;JOYPORT0 -> A
			PUSH 	AF
			RES		4,A
			OUT		(0EFH),A	;BIT6 <- 0
			CALL	F2CHK		;BIT1が1になるまでLOOP
			SET		4,A
			OUT		(0EFH),A	;BIT6 <- 1
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
			AND		04H        ;BIT2 = 0?
			JR		NZ,F1CHK
			RET

;**** BUSYをCHECK(0) ****
; EFH BIT1が1になるまでLOOP
F2CHK:		IN		A,(0EFH)
			AND		04H        ;BIT2 = 1?
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
			OUT		(0EFH),A	;BIT6 <- 0
			CALL	F1CHK		;BIT1が0になるまでLOOP
			SET		4,A
			OUT		(0EFH),A	;BIT6 <- 1
			CALL	F2CHK
			RET
		
TITLE:		DEFB	'SD <-> FD Copy Tool',00H
OK_MSG:		DEFB	'Copy Ok',0DH,00H
ERR_MSG1:	DEFB	'SD-CARD Initialize Error',0DH,00H
ERR_MSG2:	DEFB	'Not Find File',0DH,00H
ERR_MSG3:	DEFB	'BSD Not Open',0DH,00H
ERR_MSG4:	DEFB	'BSD Not Write Mode',0DH,00H
ERR_MSG5:	DEFB	'BSD Not Read Mode',0DH,00H
ERR_MSG9:	DEFB	'Copy Cancel',0DH,00H
MSG99:		DEFB	'Error',0DH,0AH,00H
GSEL:		DEFB	'Select?(1:SD->FD 2:FD->SD 3:SD Dir 9:Cancel)',00H
QNAME:		DEFB	'SD-CARD '
Q2NAME:		DEFB	'File Name?',00H
QFIND:		DEFB	'SD-CARD Search Name?',00H
QMODE:		DEFB	'Mode(1:OBT 2:BTX 3:BSD)?',00H
QLOAD:		DEFB	'Load Address?',00H
QEXE:		DEFB	'Execute Address?',00H
ADRS:		DEFB	'Ser Address:',00H
MSG_KEY1	DEFB	'Sel:0-9 Next:Any Key Back:B Break:ESC',0DH,0AH,00H
SETMSG		DEFB	'SD -> FD Set File Name:'


DNAME:		DS		40
DBLOCK:		DS		2
FMODE:		DS		1
FILESIZE:	DS		2
LOADADR:	DS		2
EXECADR:	DS		2
			
BUFFER:		DS		256

			END
