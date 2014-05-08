unit ResManager;

interface
uses  Classes, sysutils, Texture,Gameimage,Kpp,Forms,Wil,Wzl;
const
  PrguseCount = 3; //�����ļ�����

  KppFileCount = 4; //��Դ������ά���ļ�������
  OtherFileCount = 1; //�޹���ĵ����ļ�����

  {�����±�}
  CHRSEL = 1;
type
  TResManager = class(TThread)
  private
    Finited: Boolean;
    FRoot: string;
    FLoadPercent: integer;
    class var FInstance: TResManager;
    PrguseFile: array[1..PrguseCount] of TGameImage;
    OtherFile: array[1..OtherFileCount] of TGameImage; //�����ļ�����
    AllFileList: TList;
    function FileNameFormat(sfile: string; index: integer): string;
    procedure LoadFile;
    procedure CalcPercent(loaded: integer);
    constructor Create(sRoot: string); //���ݽ����ĸ�Ŀ¼Ҫȷ�������б��/
    Function LoadResFile(sFile:String):TGameImage;//���ݽ������ļ����ǲ�������׺���ġ�
  protected
    procedure Execute; override;
  public
    class function GetInstance: TResManager;
    destructor Destroy; override;
    procedure WriteLog(s: string);
    function GetPrguseTexture(PrguseIndex: integer; Index: integer; AutoFree:
      Boolean = True): TTexture;
    function GetOtherTexture(OtherFileIndex: integer; index: integer; AutoFree:
      Boolean = True): TTexture;
    Function GetTexture(ImageFile:TGameImage;index:Integer;AutoFree:Boolean=True):TTexture;
    property LoadPercent: integer read FLoadPercent;
  end;
implementation
uses
  MondoZenGL,Share;
{ TKppManager }

destructor TResManager.Destroy;
var
  i: integer;
  t: TGameImage;
begin
  for I := 0 to AllFileList.Count - 1 do
  begin
    t := AllFileList[i];
    FreeAndNil(T);

  end;
  AllFileList.Free;
  inherited;
end;

procedure TResManager.Execute;
var
  i: integer;
begin
  inherited;
  if not Finited then
    LoadFile;
  while not Terminated do
  begin
    //for i := 1 to PrguseCount do
      //PrguseFile[i].CheckFreeTexture;
    Sleep(100);
  end;
end;

function TResManager.FileNameFormat(sfile: string; index: integer): string;
begin
  result := Froot + sfile;
  if index <= 1 then
    exit;
  if index >= 256 then
    exit;
  result := format(sfile + '%d', [index]);
  result := Froot + result;
end;

class function TResManager.GetInstance: TResManager;
begin
  if not assigned(FInstance) then
    FInstance := TResManager.Create(g_sClientPath+'Data\');
  result := FInstance;
end;

function TResManager.GetOtherTexture(OtherFileIndex, index: integer; AutoFree:
  Boolean): TTexture;
begin
  Result := nil;
  if not OtherFileIndex in [1..OtherFileCount] then
    Exit;
    Result:=OtherFile[OtherFileIndex].GetTexture(index,AutoFree);
end;

function TResManager.GetPrguseTexture(PrguseIndex, Index: integer; AutoFree:
  Boolean): TTexture;
begin
  Result := nil;
  if not PrguseIndex in [1..PrguseCount] then
    exit;
  Result:=PrguseFile[PrguseIndex].GetTexture(index,AutoFree);
end;

function TResManager.GetTexture(ImageFile: TGameImage; index: Integer;
  AutoFree: Boolean): TTexture;
begin
Result:=nil;
if Assigned(ImageFile) then
begin
 Result:=ImageFile.GetTexture(index,AutoFree);
end;

end;

procedure TResManager.LoadFile;
var
  I: integer;
  LoadedFileCount: integer;
begin
  FLoadPercent := 0;
  LoadedFileCount := 0;
  for I := 1 to PrguseCount do
  begin

      PrguseFile[i] := LoadResFile(FileNameformat('Prguse', i));
      AllFileList.Add(PrguseFile[I]);
      inc(LoadedFileCount);
      CalcPercent(LoadedFileCount);
      //Sleep(500);
  end;

  for I := 1 to OtherFileCount do
  begin
    OtherFile[i] := LoadResFile(FileNameformat('ChrSel', i));
    inc(LoadedFileCount);
    AllFileList.Add(OtherFile[I]);
    CalcPercent(LoadedFileCount);
  end;

  Finited := True;
end;

function TResManager.LoadResFile(sFile: String): TGameImage;
begin
//���ȼ��kpp �ļ��Ƿ���ڡ�
//�ټ��Wzl�ļ��Ƿ���ڡ�
//�ټ��wil�ļ��Ƿ����.
  Result:=nil;
  if FileExists(sFile+'.KPP') then
  begin
  Result:=TKPPFile.Create(sFile+'.KPP');
  Result.Init;
  Exit;
  end else
  if FileExists(sFile+'.Wzl') Then
  begin
  Result:=TWzlImage.Create(sFile+'.Wzl');
  Result.Init;
  end else
  if FileExists(sFile+'.Wil') then
  begin
  Result:=TWilImage.Create(sFile+'.Wil');
  Result.Init;
  Exit
  end;



end;

procedure TResManager.WriteLog(s: string);
begin
  TMZLog.Log(S, True);
end;

procedure TResManager.CalcPercent(loaded: integer);
begin
  FLoadPercent := trunc((Loaded / KppFileCount) * 100);
end;

constructor TResManager.Create(sRoot: string);

begin
  inherited Create(False);
  FreeOnTerminate := False;
  Finited := False;
  FRoot := sRoot;
  AllFileList := TList.Create;
end;

end.

