// 2024.11.30 INPUT_PULLUPに修正
//
#include "SdFat.h"
#include <SPI.h>
SdFat SD;
char f_name[40];
char c_name[40];
char buf1[10],buf2[10];
char sdir[10][40];
File file;
unsigned long f_length,f_length2,f_length1;
#define CABLESELECTPIN  (10)
#define CHKPIN          (15)
#define PB2PIN          (4)
#define PB3PIN          (5)
#define FLGPIN          (14)
#define PA0PIN          (16)
#define PA1PIN          (17)
// ファイル名は、ロングファイルネーム形式対応
boolean eflg;

void sdinit(void){
  // SD初期化
  if( !SD.begin(CABLESELECTPIN,8) )
  {
////    Serial.println("Failed : SD.begin");
    eflg = true;
  } else {
////    Serial.println("OK : SD.begin");
    eflg = false;
  }
////    Serial.println("START");
}

void setup(){
////  Serial.begin(9600);
// CS=pin10
// pin10 output

  pinMode(CABLESELECTPIN,OUTPUT);
  pinMode( CHKPIN,INPUT);  //CHK
  pinMode( PB2PIN,OUTPUT); //送信データ
  pinMode( PB3PIN,OUTPUT); //送信データ
  pinMode( FLGPIN,OUTPUT); //FLG

  pinMode( PA0PIN,INPUT_PULLUP); //受信データ
  pinMode( PA1PIN,INPUT_PULLUP); //受信データ

  digitalWrite(PB2PIN,LOW);
  digitalWrite(PB3PIN,LOW);
  digitalWrite(FLGPIN,LOW);

  sdinit();
}

//2BIT受信
byte rcv2bit(void){
//LOWになるまでループ
  while(digitalRead(CHKPIN) != LOW){
  }
//受信
  byte j_data = digitalRead(PA0PIN)+digitalRead(PA1PIN)*2;
//FLGをセット
  digitalWrite(FLGPIN,LOW);
//HIGHになるまでループ
  while(digitalRead(CHKPIN) == LOW){
  }
//FLGをリセット
  digitalWrite(FLGPIN,HIGH);
  return(j_data);
}

//1BYTE受信
byte rcv1byte(void){
  byte i_data = 0;
  i_data=rcv2bit();
  i_data=i_data+rcv2bit()*4;
  i_data=i_data+rcv2bit()*16;
  i_data=i_data+rcv2bit()*64;
  return(~i_data);
}

//2BIT送信
void snd2bit(byte j_data)
{
  digitalWrite(PB2PIN,(j_data)&0x01);
  digitalWrite(PB3PIN,(j_data>>1)&0x01);
//FLGをセット
  digitalWrite(FLGPIN,LOW);
//LOWになるまでループ
  while(digitalRead(CHKPIN) != LOW){
  }
  digitalWrite(FLGPIN,HIGH);
//HIGHになるまでループ
  while(digitalRead(CHKPIN) == LOW){
  }
//FLGをリセット
  digitalWrite(FLGPIN,HIGH);
}

//1BYTE送信
void snd1byte(byte i_data){
  snd2bit((~i_data)&0x03);
  snd2bit((~i_data>>2)&0x03);
  snd2bit((~i_data>>4)&0x03);
  snd2bit((~i_data>>6)&0x03);
}

//SDカードから読込
void f_load(void){
  int wk1 = 0;
  unsigned int lp1;
//ファイルネーム取得
  receive_name(f_name);
//ファイルが存在しなければERROR
  if (SD.exists(f_name) == true){
//ファイルオープン
    file = SD.open( f_name, FILE_READ );
    if( true == file ){
//状態コード送信(OK)
        snd1byte(0x00);

//ファイルサイズ取得
        f_length = file.size();
        f_length2 = f_length % 256;
        f_length1 = f_length / 256;
        snd1byte(f_length2);
        snd1byte(f_length1);

        if(rcv1byte()==0x00){
//データ送信
          if(f_length>0){
            for (lp1 = 1;lp1 <= f_length;lp1++){
              wk1 = file.read();
              snd1byte(wk1);
            }
          }
        }
        file.close();
        sdinit();
     } else {
//状態コード送信(ERROR)
      snd1byte(0xFF);
      sdinit();
     }
   } else {
//状態コード送信(FILE NOT FIND ERROR)
    snd1byte(0xF1);
    sdinit();
  }
}

//SDカードに書き込み
void f_save(void){
  int wk1 = 0;
  unsigned long lp1,fmode,s_adrs,s_adrs1,s_adrs2,g_adrs,g_adrs1,g_adrs2;
  String buf11,buf22;
//ファイルネーム取得
  receive_name(f_name);

//ファイルタイプ取得
  fmode = rcv1byte();
//ファイルサイズ取得
  f_length1 = rcv1byte();
  f_length2 = rcv1byte();
//ファイルサイズ算出
  f_length = f_length1*256+f_length2;
//スタートアドレス取得
  s_adrs1 = rcv1byte();
  s_adrs2 = rcv1byte();
//スタートアドレス算出
  s_adrs = s_adrs1*256+s_adrs2;
//実行アドレス取得
  g_adrs1 = rcv1byte();
  g_adrs2 = rcv1byte();
//実行アドレス算出
  g_adrs = g_adrs1*256+g_adrs2;
  String fname = f_name;

//fmodeによりファイル名修正
  switch(fmode){
    case 1:
      sprintf(buf1,"%04x",s_adrs);
      buf11 = buf1;
      buf11.toUpperCase();
      sprintf(buf2,"%04x",g_adrs);
      buf22 = buf2;
      buf22.toUpperCase();
      fname = fname + "_"+buf11+"H_"+buf22+"H.OBT";
      break;
    case 2:
      fname = fname + ".BTX";
      break;
    case 3:
      fname = fname + ".BSD";
      break;
  }

//ファイルが存在すればdelete
  if (SD.exists(fname) == true){
    SD.remove(fname);
  }
//ファイルオープン
  file = SD.open( fname, FILE_WRITE );
  if( true == file ){
//状態コード送信(OK)
    snd1byte(0x00);
    if(rcv1byte()==0x00){
      if(f_length>0){
        for (lp1 = 1;lp1 <= f_length;lp1++){
          wk1 = rcv1byte();
          file.write(wk1);
        }
      }
    }
    file.close();
  } else {
//状態コード送信(ERROR)
    snd1byte(0xFF);
    sdinit();
  }
}

//比較文字列取得 32+1文字まで取得、ただしダブルコーテーションは無視する
void receive_name(char *f_name){
char r_data;
  unsigned int lp2 = 0;
  for (unsigned int lp1 = 0;lp1 <= 32;lp1++){
    r_data = rcv1byte();
    if (r_data != 0x22){
      f_name[lp2] = r_data;
      lp2++;
    }
  }
}

//f_nameとc_nameをc_nameに0x00が出るまで比較
//FILENAME COMPARE
boolean f_match(char *f_name,char *c_name){
  boolean flg1 = true;
  unsigned int lp1 = 0;
  while (lp1 <=32 && c_name[0] != 0x00 && flg1 == true){
    if (upper(f_name[lp1]) != upper(c_name[lp1])){
      flg1 = false;
    }
    lp1++;
    if (c_name[lp1]==0x00){
      break;
    }
  }
  return flg1;
}

//小文字->大文字
char upper(char c){
  if('a' <= c && c <= 'z'){
    c = c - ('a' - 'A');
  }
  return c;
}


// SD-CARDのFILELIST
void dirlist(void){
//比較文字列取得 32+1文字まで
  receive_name(c_name);
  File file2 = SD.open( "/" );
  if( file2 == true ){
//状態コード送信(OK)
    snd1byte(0x00);

    File entry =  file2.openNextFile();
    int cntl2 = 0;
    unsigned int br_chk =0;
    int page = 1;
//全件出力の場合には10件出力したところで一時停止、キー入力により継続、打ち切りを選択
    while (br_chk == 0) {
      if(entry){
        entry.getName(f_name,36);
        unsigned int lp1=0;
//一件送信
//比較文字列でファイルネームを先頭から比較して一致するものだけを出力
        if (f_match(f_name,c_name)){
//sdir[]にf_nameを保存
          strcpy(sdir[cntl2],f_name);
          snd1byte(0x30+cntl2);
          snd1byte(0x20);
          while (lp1<=36 && f_name[lp1]!=0x00){
            snd1byte(f_name[lp1]);
            lp1++;
          }
          snd1byte(0x00);
          cntl2++;
        }
      }
// CNTL2 > 表示件数-1
      if (!entry || cntl2 > 9){
//継続・打ち切り選択指示要求
        snd1byte(0xfe);

//選択指示受信(0:継続 B:前ページ 以外:打ち切り)
        br_chk = rcv1byte();
//前ページ処理
        if (br_chk==0x42 || br_chk==0x62){
//先頭ファイルへ
          file2.rewindDirectory();
//entry値更新
          entry =  file2.openNextFile();
//もう一度先頭ファイルへ
          file2.rewindDirectory();
          if(page <= 2){
//現在ページが1ページ又は2ページなら1ページ目に戻る処理
            page = 0;
          } else {
//現在ページが3ページ以降なら前々ページまでのファイルを読み飛ばす
            page = page -2;
            cntl2=0;
//page*表示件数
            while(cntl2 < page*10){
                entry =  file2.openNextFile();
                if (f_match(f_name,c_name)){
                  cntl2++;
                }
            }
         }
          br_chk=0;
        }
//1～0までの数字キーが押されたらsdir[]から該当するファイル名を送信
        if(br_chk>=0x30 && br_chk<=0x39){
          file = SD.open( sdir[br_chk-0x30], FILE_READ );
          if( file == true ){
            unsigned int lp2=0;
            snd1byte(0xFD);
            while (lp2<=36 && sdir[br_chk-0x30][lp2]!=0x00){
              snd1byte(sdir[br_chk-0x30][lp2]);
              lp2++;
            }
            snd1byte(0x00);
            file.close();
          }
        }
        page++;
        cntl2 = 0;
      }
//ファイルがまだあるなら次読み込み、なければ打ち切り指示
      if (entry){
        entry =  file2.openNextFile();
      }else{
        br_chk=1;
      }
    }
//処理終了指示
    snd1byte(0x00);
  }else{
    snd1byte(0xf1);
  }
}

void loop()
{
  digitalWrite(PB2PIN,LOW);
  digitalWrite(PB3PIN,LOW);
  digitalWrite(FLGPIN,LOW);
//コマンド取得待ち
////  Serial.print("cmd:");
  byte cmd = rcv1byte();
////  Serial.println(cmd,HEX);
  if (eflg == false){
    switch(cmd) {
//80hでSDカードからLoad
      case 0x80:
//状態コード送信(OK)
////  Serial.println("LOAD START");
//状態コード送信(OK)
        snd1byte(0x00);
        f_load();
        break;
//81hでSDカードにsave
      case 0x81:
//状態コード送信(OK)
////  Serial.println("SAVE START");
//状態コード送信(OK)
        snd1byte(0x00);
        f_save();
        break;
//82hでSDカードファイル一覧
      case 0x82:
//状態コード送信(OK)
////  Serial.println("SD DIR START");
//状態コード送信(OK)
        snd1byte(0x00);
        sdinit();
        dirlist();
        break;
      default:
//状態コード送信(CMD ERROR)
        snd1byte(0xF4);
    }
  } else {
//状態コード送信(ERROR)
    snd1byte(0xF0);
    sdinit();
  }
}
