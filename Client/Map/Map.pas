unit Map;

interface
uses
MondoZengl;
type
  MapType=(Mir2,Mir2New,Mir3);
  TMapHeader =packed record
     wWidth  : word;
     wHeight : word;
     btVersion:Byte;  //=15ʱ���ʾ֧�ֶ��tiles ��smtiles
     Title: string[13];
     UpdateDate: TDateTime;
     Reserved  : array[0..24] of char;
  end;
  TMapInfo = packed record
    wBkImg: Word;  //tiles ��ֵ ���λΪ1��ʾ��������
    wMidImg: Word; //smtiles��ֵ ���λΪһ��ʾ��������
    wFrImg: Word;
    btDoorIndex: byte;
    btDoorOffset: byte;
    btAniFrame: byte;
    btAniTick: byte;
    btArea: byte;
    btLight: byte;  //12
  end;
  pTMapInfo = ^TMapInfo;

  TNewMapInfo = record
    wBkImg: Word;
    wMidImg: Word;
    wFrImg: Word;
    btDoorIndex: byte;
    btDoorOffset: byte;
    btAniFrame: byte;
    btAniTick: byte;
    btArea: byte;
    btLight: byte; //0..1..4
    btBkIndex: Byte;
    btSmIndex: Byte;   //14
  end;

    TGameMap=class
    Protected
      TargetTexture:TMZRenderTarget;
    Public
     // Constructor Create();
     // destructor Destroy; override;
      Procedure DrawTile(x,y:integer);virtual;abstract;
      Procedure DrawObject(x,y:Integer);virtual;abstract;
    end;


Function EstimateMapType(sFileName:String):MapType;
implementation

Function EstimateMapType(sFileName:String):MapType;
begin

end;
end.
