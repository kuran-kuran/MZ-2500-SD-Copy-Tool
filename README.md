# SHARP MZ-2500 SD Copy Tool

![MZ-2500 SD Copy Tool](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/TITLE.jpg)

　MZ-2500のジョイスティックポート1に挿したSD-dongleのSD-CARDとMZ-2500のFD、HDD間でOBT、BTX、BSDファイルを相互にコピーできるツールです。

　Windows等のツールで作成したMZ-2500用の機械語及びBASICプログラムをMZ-2500のFD、HDDにコピー、MZ-2500のFD、HDDのファイルを取り出してWindows等のツールで修正し、MZ-2500のFD、HDDに戻す等が簡単にできます。

## 回路図
　KiCadフォルダ内のSD_dongle.pdfを参照してください。

[回路図](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/Kicad/SD_dongle.pdf)

![SD_dongle](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/Kicad/SD_dongle_1.jpg)

|番号|品名|数量|備考|
| ------------ | ------------ | ------------ | ------------ |
|J1|D-SUBコネクター9Pメス|1|マルツ 3223DB9RS1S2等|
||J2、J3のいずれか|||
|J2|Micro_SD_Card_Kit|1|秋月電子通商 AE-microSD-LLCNV (注1)|
|J3|MicroSD Card Adapter|1|Arduino等に使われる5V電源に対応したもの(注2)|
|U1|Arduino_Pro_Mini_5V|1|Atmega328版を使用 168版は不可。(注3)|
||ピンソケット(任意)|12Pin×2|Arduino_Pro_Miniを取り外し可能としたい場合に調達します 秋月電子通商 FHU-1x42SGなど|

### 注1)秋月電子通商　AE-microSD-LLCNVのJ1ジャンパはショートしてください。

### 注2)MicroSD Card Adapterを使う場合

J3に取り付けます。

MicroSD Card Adapterについているピンヘッダを除去してハンダ付けするのが一番確実ですが、J2の穴にMicroSD Card Adapterをぴったりと押しつけ、裏から多めにハンダを流し込むことでハンダ付けをする方法もあります。なお、この方法の時にはしっかりハンダ付けが出来たかテスターで導通を確認しておいた方が安心です。

ハンダ付けに自信のない方はJ1の秋月電子通商　AE-microSD-LLCNVをお使いください。AE-microSD-LLCNVならパワーLED、アクセスLEDが付いています。

![MicroSD Card Adapter1](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/MicroSD%20Card%20Adapter.jpg)

### 注3)MZ-2500 SD Copy Tool用SD-DongleではArduino Pro MiniのA4、A5ピンは使用しません。

## Arduinoへの書込み
　Arduino IDEを使ってArduinoフォルダSD_dongleフォルダ内SD_dongle.inoを書き込みます。

　SdFatライブラリを使用しているのでArduino IDEメニューのライブラリの管理からライブラリマネージャを立ち上げて「SdFat」をインストールしてください。

　「SdFat」で検索すれば見つかります。「SdFat」と「SdFat - Adafruit Fork」が見つかりますが「SdFat」のほうを使っています。

## MZ-2500用Copy Toolプログラム
　MZ-2500のFD、HDD、FDDエミュレータ用FDイメージにOBTファイルを転送する手段がある方はSD_TRANSフォルダ内のSD_TRANS.binを転送してください。

　転送する手段の無い方はBASIC-S25又はBASIC-M25からモニタMコマンドでSD_LOADERフォルダ内のSD_LOADER.binの内容を入力します。

![SD_LOADER](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/SD_LOADER.jpg)

　入力間違いが無いことを確認し、SコマンドでSD_LOADER.bin等の名前を付けてセーブしてください。

　　*S A000 A16F A000:SD_LOADER.bin

　次にSD_TRANSフォルダ内のSD_TRANS.binをSD-CARDにコピーし、次のコマンドを実行します。


### (BASIC-M25)

　clear &HA000

　bload "SD_LOADER.bin"

　FD、HDDのカレントディレクトリをSD_TRANS.bin転送先ディレクトリに変更

　call &HA000

### (BASIC-S25)

　limit &HA000

　load "SD_LOADER.bin"

　FD、HDDのカレントディレクトリをSD_TRANS.bin転送先ディレクトリに変更

　call &HA000

　問題が無ければ「OK」と表示されて終了し、SD_TRANS.binがFD、HDDのカレントディレクトリに転送されているはずです。

## SD-CARD
　出来れば8GB以下のSDカードを用意してください。

　ArduinoのSdFatライブラリは、SD規格(最大2GB)、SDHC規格(2GB～32GB)に対応していますが、SDXC規格(32GB～2TB)には対応していません。

　また、SDHC規格のSDカードであっても32GB、16GBは相性により動作しないものがあるようです。

　FAT16又はFAT32が認識できます。NTFSは認識できません。

## 操作方法
　clear又はlimitで機械語領域を確保してからbload又はloadコマンドでSD_TRANS.binをロードします。

　必要があればFD又はHDDのカレントディレクトリを変更しておきます。

　SD-Dongleをジョイスティックポート1に挿します。

　call &HA000でCopy Toolを実行します。

　SD-CARDのファイル名は拡張子も含めて32文字まで、ただし漢字、半角カタカナ、及び一部の記号はArduinoが認識しないので使えません。パソコンでファイル名を付けるときはアルファベット、数字および空白でファイル名をつけてください。

　また、SD-CARDからFD、HDDにコピーされたファイルのファイル名は先頭16文字までとなります。

　Copy Toolが起動したらまず処理の選択をします。

![Copy_Tool_01](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/Copy_Tool_01.JPG)

### 1 SD -> FD
　SD-CARDのファイルをFD、HDDにコピーします。

　次にSD-CARDのファイル名を指定します。

　大文字、小文字は区別されるので大文字、小文字も正確に入力してください。

　FD、HDDにはSD-CARDのファイル名のままコピーされますが、16文字を超えた分は切り捨てられます。

![Copy_Tool_02](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/Copy_Tool_02.JPG)

　ファイルモードを指定します。SD-CARDのファイルにはファイルモード等の情報が含まれていないため指定する必要があります。

![Copy_Tool_03](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/Copy_Tool_03.JPG)

　実際のファイルモードと指定したファイルモードが間違っていてもコピーは正常終了しますが、MZ-2500のBASICからは期待した動作が出来なくなりますので削除してください。

#### 1 OBT
　SD-CARDのファイルには先頭アドレス、実行アドレスの情報が含まれていないため指定する必要があります。

![Copy_Tool_04](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/Copy_Tool_04.JPG)

#### 2 BXT
　ファイルモードを指定するだけでコピーが始まります。

![Copy_Tool_05](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/Copy_Tool_05.JPG)

#### 3 BSD
　ファイルモードを指定するだけでコピーが始まります。

![Copy_Tool_06](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/Copy_Tool_06.JPG)

　BSDファイルとはテキストファイルであり、Windows等のテキストエディタでBASICのプログラムとして入力することも可能です。

　ただし、改行コードは0Dhのみ(Windowsのテキストの改行コードは通常0Dh,0Ah)、漢字コードはSHIFTJISで作成してください。

## 注意!!
　SD-CARDからコピーされるファイル名のファイルがコピー先のFD、HDD上に既にある場合、エラー終了します。

![Copy_Tool_07](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/Copy_Tool_07.JPG)

　この「already exist error」で中止されたことをArduinoは認識できないため転送処理が中途半端なまま待機状態となっており、次にCopy Toolが起動されても正常に処理できません。

## 　SD-Dongleを挿し直すことで正常に処理できるよう復旧するので、もう一度Copy Toolを起動する前に必ずSD-Dongleを挿し直してください。

　FD、HDD上に既にあるファイルもCopy Tool起動前には削除してください。

![Copy_Tool_08](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/Copy_Tool_08.JPG)

![Copy_Tool_09](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/Copy_Tool_09.JPG)

### 2 FD -> SD
　FD、HDDのファイルをSD-CARDにコピーします。

　FD、HDDのファイル名を指定します。

![Copy_Tool_10](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/Copy_Tool_10.JPG)

　SD-CARDにコピーされるファイルのファイル名にはFD、HDD上のファイル情報に基づき、拡張子及び先頭アドレス、実行アドレスが付加されます。

　　[OBTファイル] test.OBJ -> test.OBJ_A000_A000.OBT

　　[BTXファイル] test.m25 -> test.m25.BTX

　　[BSDファイル] test     -> test.BSD

### 3 SD DIR
　SD-CARDのルートディレクトリにあるファイル一覧からファイルを選択することでSD-CARDのファイルをFD、HDDにコピーできます。

![Copy_Tool_11](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/Copy_Tool_11.JPG)

　「SD-CARD Search Name?」と聞いてくるので文字列を何も指定せずにENTERキーのみとするとSD-CARDルートディレクトリにあるファイルの一覧を表示します。

　文字列を指定するとSD-CARDルートディレクトリにあるその文字列から始まるファイルの一覧を表示します。

　10件表示したところで指示待ちになるので打ち切るならESCキー、Bキーで前の10件に戻ります。それ以外のキーで次の10件を表示します。

　行頭に0から9の数字を付加して表示してあるのでコピーしたいファイルの頭についている数字を入力するとコピー処理に移行します。

　検索する文字列は大文字、小文字の区別はありません。大文字、小文字のどちらで入力しても大丈夫です。

　表示される順番は、登録順となりファイル名アルファベッド順などのソートした順で表示することはできません。

## 追記
2024.11.30　Arduinoプログラムに安定性の向上を追加
