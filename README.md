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

J2に取り付けます。

MicroSD Card Adapterについているピンヘッダを除去してハンダ付けするのが一番確実ですが、J2の穴にMicroSD Card Adapterをぴったりと押しつけ、裏から多めにハンダを流し込むことでハンダ付けをする方法もあります。なお、この方法の時にはしっかりハンダ付けが出来たかテスターで導通を確認しておいた方が安心です。

ハンダ付けに自信のない方はJ1の秋月電子通商　AE-microSD-LLCNVをお使いください。AE-microSD-LLCNVならパワーLED、アクセスLEDが付いています。

![MicroSD Card Adapter1](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/MicroSD%20Card%20Adapter.jpg)

### 注3)MZ-2500 SD Copy Tool用SD-DongleではArduino Pro MiniのA4、A5ピンは使用しません。

## Arduinoへの書込み
　Arduino IDEを使ってArduinoフォルダSD_dongleフォルダ内SD_dongle.inoを書き込みます。

　SdFatライブラリを使用しているのでArduino IDEメニューのライブラリの管理からライブラリマネージャを立ち上げて「SdFat」をインストールしてください。

　「SdFat」で検索すれば見つかります。「SdFat」と「SdFat - Adafruit Fork」が見つかりますが「SdFat」のほうを使っています。

## 転送プログラム
　MZ-2500のFD、HDD、FDDエミュレータ用FDイメージにOBTファイルを転送する手段がある方はSD_TRANSフォルダ内のSD_TRANS.binを転送してください。

　転送する手段の無い方はBASIC-S25又はBASIC-M25からモニタMコマンドでSD_LOADERフォルダ内のSD_LOADER.binの内容を入力します。

![SD_LOADER](https://github.com/yanataka60/MZ-2500-SD-Copy-Tool/blob/main/JPEG/SD_LOADER.jpg)

　入力間違いが無いことを確認し、SコマンドでSD_LOADER.bin等の名前を付けてセーブしてください。

　　*S A000 A16F A000 SD_LOADER.bin

　次にSD_TRANSフォルダ内のSD_TRANS.binをSD-CARDにコピーしてから次のコマンドを実行します。


　(BASIC-M25)

　clear &HA000

　bload "SD_LOADER.bin"

　SD_TRANS.binを転送したいFD、HDDのフォルダをカレントフォルダにしておきます。

　call &HA000

　(BASIC-S25)

　limit &HA000

　load "SD_LOADER.bin"

　SD_TRANS.binを転送したいFD、HDDのフォルダをカレントフォルダにしておきます。

　call &HA000

　「COPY OK」と表示されて終了し、SD_TRANS.binがFD、HDDのカレントフォルダに転送されているはずです。

## SD-CARD
　出来れば8GB以下のSDカードを用意してください。

　ArduinoのSdFatライブラリは、SD規格(最大2GB)、SDHC規格(2GB～32GB)に対応していますが、SDXC規格(32GB～2TB)には対応していません。

　また、SDHC規格のSDカードであっても32GB、16GBは相性により動作しないものがあるようです。

　FAT16又はFAT32が認識できます。NTFSは認識できません。

## 操作方法
### TK-80
#### 扱えるファイル
　拡張子btkとなっているバイナリファイルです。

　ファイル名は0000～FFFFまでの16進数4桁を付けてください。(例:1000.btk)

　この16進数4桁がTK-80からSD-Card内のファイルを識別するファイルNoとなります。

　BTKファイルのフォーマットは、バイナリファイル本体データの先頭に開始アドレス、終了アドレスの4Byteのを付加した形になっています。

　パソコンのクロスアセンブラ等でTK-80用の実行binファイルを作成したらバイナリエディタ等で先頭に開始アドレス、終了アドレスの4Byteを付加し、ファイル名を変更したものをSD-Cardのルートディレクトリに保存すればTK-80から呼び出せるようになります。

#### Save
　4桁のファイルNo(xxxx)をデータ表示部のLEDに入力してSTORE DATAを押します。

　正常にSaveが完了するとアドレス部にスタートアドレス、データ部にエンドアドレスが表示されます。

　　　8000H～8390Hまでをxxxx.BTKとしてセーブします。セーブ範囲は固定となっていて指定はできません。

　「F0F0F0F0」と表示された場合はSD-Card未挿入です。確認してください。

#### Load
　4桁のファイルNo(xxxx)をデータ表示部のLEDに入力してLOAD DATAキーを押します。

　　　xxxx.BTKをBTKヘッダ情報で示されたアドレスにロードします。ただし、8391H～83FFHまでの範囲はライトプロテクトされます。

　正常にLoadが完了するとアドレス部にスタートアドレス、データ部にエンドアドレスが表示されます。スタートアドレスが実行開始アドレスであればそのままRUNキーを押すことでプログラムが実行できます。

　「F0F0F0F0F0」と表示された場合はSD-Card未挿入、「F1F1F1F1F1」と表示された場合はファイルNoのファイルが存在しない場合です。確認してください。

　異常が無いと思われるのにエラーとなってしまう場合にはTK-80をリセットしてからやり直してみてください。


### TK-80BSで扱えるファイル
　BS MONITOR、BS LEVEL2 BASIC共にルートに置かれた拡張子が「.CAS」ファイルのみ認識できます。(以外のファイル、フォルダも表示されますがLOAD実行の対象になりません)

　ファイル名は拡張子を除いて32文字まで、ただし半角カタカナ、及び一部の記号はArduinoが認識しないので使えません。パソコンでファイル名を付けるときはアルファベット、数字および空白でファイル名をつけてください。

　TK-80BSでのCASファイルとは、インテルHEX形式のファイルです。BIN2HEX等の変換プログラムでHEXファイルを作成した場合には拡張子をHEXからCASに変更して使ってください。

### TK-80BS MONITOR
#### SD[復改]又はSD,文字列[復改]
　文字列を入力せずにSD[復改]のみ入力するとSD-CARDルートディレクトリにあるファイルの一覧を表示します。

　文字列を付けて入力すればSD-CARDルートディレクトリにあるその文字列から始まるファイルの一覧を表示します。

　10件表示したところで指示待ちになるので打ち切るなら!を入力、Bキーで前の10件に戻ります。それ以外のキーで次の10件を表示します。

　行頭に0から9の数字を付加して表示してあるのでロードしたいファイルの頭についている数字を入力するとロードが実行されます。

　BASICプログラム、機械語プログラムのどちらもロード対象となり、8802hから始まるCASファイルがBASICプログラムとして認識され、それ以外のアドレスから始まるCASファイルは機械語プログラムとして認識します。

　BASICプログラムと認識した場合にはBASICテキスト終了ポインタもセットされます。

　表示される順番は、登録順となりファイル名アルファベッド順などのソートした順で表示することはできません。

##### 例)
　　SD[復改]

　　SD,SPACE[復改]

#### LT,DOSファイル名[復改]
　指定したDOSファイル名のファイルをSD-CARDからLOADします。

　拡張子「CAS」は入力してもしなくても構いません。

　BASICプログラム、機械語プログラムのどちらもロード対象となり、8802hから始まるCASファイルがBASICプログラムとして認識され、それ以外のアドレスから始まるCASファイルは機械語プログラムとして認識します。

　BASICプログラムと認識した場合にはBASICテキスト終了ポインタもセットされます。

##### 例)
　　LT,SPACE[復改]

#### LT[復改]
　複数のCASファイルを連結してまとめて一つのCASファイルとなっている場合、SDコマンド又はLT,DOSファイル名[復改]で一つ目のプログラムをロードしていた場合に限り二つ目以降のプログラムはLT[復改]のみでロード出来ます。

　複数のCASファイルの連結については後述します。

　BASICプログラム、機械語プログラムのどちらもロード対象となり、8802hから始まるCASファイルがBASICプログラムとして認識され、それ以外のアドレスから始まるCASファイルは機械語プログラムとして認識します。

　BASICプログラムと認識した場合にはBASICテキスト終了ポインタもセットされます。

#### ST,開始アドレス,終了アドレス,DOSファイル名[復改]
　開始アドレスから終了アドレスまでの機械語プログラムをDOSファイル名でSAVEします。

　拡張子「CAS」は自動的に付加されます。

##### 例)
　　ST,9000,93FF,SPACE[復改]

### TK-80BS LEVEL2 BASIC
#### FILES[復改]又はFILES 文字列[復改]
　文字列を入力せずにFILES[復改]のみ入力するとSD-CARDルートディレクトリにあるファイルの一覧を表示します。

　文字列を付けて入力すればSD-CARDルートディレクトリにあるその文字列から始まるファイルの一覧を表示します。

　文字列はダブルコーテーションで括っても括らなくてもどちらでも構いません。

　10件表示したところで指示待ちになるので打ち切るなら!を入力、Bキーで前の10件に戻ります。それ以外のキーで次の10件を表示します。

　行頭に0から9の数字を付加して表示してあるのでロードしたいファイルの頭についている数字を入力するとロードが実行されます。

　BASICプログラム、機械語プログラムのどちらもロード対象となり、8802hから始まるCASファイルがBASICプログラムとして認識され、それ以外のアドレスから始まるCASファイルは機械語プログラムとして認識します。

　BASICプログラムと認識した場合にはBASICテキスト終了ポインタもセットされます。

　表示される順番は、登録順となりファイル名アルファベッド順などのソートした順で表示することはできません。

##### 例)
　　FILES[復改]

　　FILES SPACE[復改]

　　FILES "SPACE"[復改]

#### LOAD DOSファイル名[復改]
#### LOADH DOSファイル名[復改]
　指定したDOSファイル名のファイルをSD-CARDからLOADします。

　LOADとLOADHは同じ動作をします。

　拡張子「CAS」は入力してもしなくても構いません。

　DOSファイル名はダブルコーテーションで括っても括らなくてもどちらでも構いません。

　BASICプログラム、機械語プログラムのどちらもロード対象となり、8802hから始まるCASファイルがBASICプログラムとして認識され、それ以外のアドレスから始まるCASファイルは機械語プログラムとして認識します。

　BASICプログラムと認識した場合にはBASICテキスト終了ポインタもセットされます。

##### 例)
　　LOAD SPACE[復改]

　　LOAD "SPACE"[復改]

#### LOAD[復改]
#### LOADH[復改]
　複数のCASファイルを連結してまとめて一つのCASファイルとなっている場合、FILESコマンド又はLOAD DOSファイル名[復改]で一つ目のプログラムをロードしていた場合に限り二つ目以降のプログラムはLOAD[復改]のみでロード出来ます。

　LOADとLOADHは同じ動作をします。

　複数のCASファイルの連結については後述します。

　BASICプログラム、機械語プログラムのどちらもロード対象となり、8802hから始まるCASファイルがBASICプログラムとして認識され、それ以外のアドレスから始まるCASファイルは機械語プログラムとして認識します。

　BASICプログラムと認識した場合にはBASICテキスト終了ポインタもセットされます。

#### SAVE DOSファイル名[復改]
　BASICプログラムをDOSファイル名でSAVEします。SAVEHは使えません。

　拡張子「CAS」は自動的に付加されます。

　DOSファイル名はダブルコーテーションで括っても括らなくてもどちらでも構いません。

##### 例)
　　SAVE SPACE[復改]

　　SAVE "SPACE"[復改]

## CASファイルの連結
　BASICプログラムから機械語プログラムを呼び出して動くアプリケーションの場合、それぞれ別のDOSファイル名で保存して別々にLOADしても良いのですが、１本のCASファイルにまとめて扱うことも可能です。

　例えば「TESTBAS.CAS」と「TESTBIN.CAS」をまとめる場合にはテキストエディタで「TESTBAS.CAS」の後ろに「TESTBIN.CAS」をコピーし別名で保存します。例として「TESTBASBIN.CAS」とします。

「TESTBAS.CAS」

![TESTBAS](https://github.com/yanataka60/TK-80BS_SD/blob/main/JPEG/TESTBAS.jpg)

「TESTBIN.CAS」

![TESTBIN](https://github.com/yanataka60/TK-80BS_SD/blob/main/JPEG/TESTBIN.jpg)

「TESTBASBIN.CAS」

![TESTBASBIN](https://github.com/yanataka60/TK-80BS_SD/blob/main/JPEG/TESTBASBIN.jpg)

　このファイルは「LOAD TESTBASBIN[復改]」としてBASICプログラムをLOADし、次に「LOAD[復改]」とすることで機械語プログラムが読み込まれるCASファイルとなります。

　また、「TESTBAS.CAS」の最終行を削除してから「TESTBIN.CAS」をコピーし別名で保存すれば、「LOAD TESTBASBIN[復改]」でBASICプログラムと機械語プログラムをまとめてLOADすることも可能です。

![TESTBASBIN2](https://github.com/yanataka60/TK-80BS_SD/blob/main/JPEG/TESTBASBIN2.jpg)

　BASICプログラムと機械語プログラムの連結を例にあげましたが、BASICプログラムとBASICプログラム、機械語プログラムと機械語プログラムでも同じです。

　また、３つ以上のプログラムをまとめてしまうことも可能です。
