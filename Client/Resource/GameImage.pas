unit GameImage;

interface
uses
Classes,Texture;
Type
    TGameImage=Class
    Protected
      FIndex:array of Integer;   //�����б�
      FFileStream:TFileStream; //���ļ����ļ���
      FImageCount:Integer;  //ͼƬ����;
      FTextureList:TThreadList; //�����б�
      FFileName:string;//��Դ�ļ�����
      Function ReadyLoadTexture(idx:integer):TTexture;
      Function GetCacheTexture(idx:integer):TTexture;virtual;
      Function GetTex(idx:integer):TTexture;
    Public
      constructor Create;virtual;
      destructor Destroy; override;
      Procedure Init;virtual;
      Procedure CreateFile;virtual;
      Function GetTexture(idx:integer;AutoFree:Boolean=True):TTexture;virtual;
      Procedure Insert(idx:Integer;pData:Pointer;Len:integer);virtual;
      property ImageCount:Integer Read FImageCount;
      property Texture[idx:integer]:TTexture Read GetTex;
    End;

function RGB565ToABGR(Pixel:Word):Integer;inline;
Function ARGBToABGR(Pixel:Cardinal):Cardinal;inline;
implementation
uses
windows;
{ TGameImage }



{ TGameImage }

constructor TGameImage.Create;
begin
FFileStream:=nil;
FImageCount:=0;
FFileName:='';
FTextureList:=TThreadList.Create;
end;

procedure TGameImage.CreateFile;
begin

end;

destructor TGameImage.Destroy;
begin
  SetLength(FIndex,0);
  FTextureList.Free;
  FFileName:='';
  inherited;
end;

function TGameImage.GetCacheTexture(idx: integer): TTexture;
begin

end;

function TGameImage.GetTex(idx: integer): TTexture;
begin
Result:=GetTexture(idx);
end;

function TGameImage.GetTexture(idx: integer; AutoFree: Boolean): TTexture;
begin

end;

procedure TGameImage.Init;
begin

end;

procedure TGameImage.Insert(idx: Integer; pData: Pointer; Len: integer);
begin

end;

function TGameImage.ReadyLoadTexture(idx: integer): TTexture;
var
List:TList;
Count:Integer;
begin
Result:=nil;
if (idx >=0) and (idx < FImageCount) then
begin
List:=FTextureList.LockList;
Count:=List.Count;
Result:=List[idx];
if Assigned(Result) then
Result.LastCheckTime:=GetTickCount;
FTextureList.UnlockList;
end;

end;
function RGB565ToABGR(Pixel:Word):Integer;inline;
var
R,G,B,A:Byte;
begin
R:=(Pixel and $F800) shr 8;//��߷�����248��
G:=(Pixel and $07E0) shr 3; //��߷�����252;
B:=(Pixel and $001F) shl 3;
A:=$FF;
if Pixel=0 then A:=0; //����ɫ͸��
Result:=(A shl 24)or (B shl 16) or (G shl 8) or R;
end;

Function ARGBToABGR(Pixel:Cardinal):Cardinal;inline;
var
R,G,B,A:Byte;
begin
//AGRB ABGR
//A:=(Pixel and $FF000000) shr 24;
R:=(Pixel and $00FF0000) shr 16;
G:=(Pixel and $0000FF00) shr 8;
B:=(Pixel and $000000FF);
A:=$FF;
if Pixel=0 then A:=0; //�����ɫ͸��ɫ
Result:=(A shl 24)or (B shl 16) or (G shl 8) or R;
end;
end.
