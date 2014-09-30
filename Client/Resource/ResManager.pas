unit ResManager;

interface
uses  Classes, sysutils, Texture,Gameimage,Kpp,vcl.forms,Wil,Wzl,System.Generics.Collections;
const
  PRGUSECOUNT = 3; //�����ļ�����
  TILESCOUNT = 10;  //��ש����
  SMTILESCOUNT = 10;//С��ש����
  MAPOBJCOUNT = 40; //Objects.wil�ļ�����
  OTHERCOUNT = 1; //�޹���ĵ����ļ�����
  FILECOUNT = PRGUSECOUNT + TILESCOUNT + SMTILESCOUNT + MAPOBJCOUNT + OTHERCOUNT; //��Դ������ά���ļ�������
type
  TResManager = class(TThread)
  private
    class var FInstance : TResManager;
    m_bInited           : Boolean;
    m_sRoot             : string;
    m_nLoadedFileCount  : integer;
    m_FileList          :TList<TGameImage>;
    function FileNameFormat(sfile: string; index: integer): string;
    procedure LoadFile;
    Function CalcPercent():integer;
    constructor Create(sRoot: string); //���ݽ����ĸ�Ŀ¼Ҫȷ�������б��/
    Function LoadResFile(sFile:String):TGameImage;//���ݽ������ļ����ǲ�������׺���ġ�
  protected
    procedure Execute; override;
  public
    class function GetInstance: TResManager;
    destructor Destroy; override;
    Function GetTexture(FileType:Integer;FileIndex:integer;ImageIndex:Integer):TTexture;
    property LoadPercent: integer read CalcPercent;
  end;
var
{�����±�}
  CHRSEL   :Integer=1;
  PRGUSE   :Integer;
  MAPOBJ   :Integer;
  MONSTER  :Integer;
  TILES    :Integer;
  SMTILES  :Integer;
  HUMAN    :Integer;
  WEAPON   :Integer;
  HUMEFF   :Integer;
  WEAPONEFF:Integer;
  OTHER    :Integer;
implementation
uses
  MondoZenGL,Share;
{ TKppManager }

destructor TResManager.Destroy;
var
  i: integer;
  t: TGameImage;
begin
  for I := 0 to m_FileList.Count - 1 do
  begin
    t := m_FileList[i];
    FreeAndNil(T);

  end;
  m_FileList.Free;
  inherited;
end;

procedure TResManager.Execute;
begin
  inherited;
  if not m_bInited then
    LoadFile;
  while not Terminated do
  begin
    Sleep(100);
  end;
end;

function TResManager.FileNameFormat(sfile: string; index: integer): string;
begin
  result := m_sRoot + sfile;
  if index <= 1 then
    exit;
  if index >= 256 then
    exit;
  result := format(sfile + '%d', [index]);
  result := m_sRoot + result;
end;

class function TResManager.GetInstance: TResManager;
begin
  if not assigned(FInstance) then
    FInstance := TResManager.Create(g_sClientPath+'Data\');
  result := FInstance;
end;


function TResManager.GetTexture(FileType, FileIndex, ImageIndex: Integer): TTexture;
begin
  Result:=m_FileList[FileType+FileIndex-1].GetTexture(ImageIndex);
end;

procedure TResManager.LoadFile;
var
  I: integer;
  GameImage:TGameImage;
begin
  m_nLoadedFileCount := 0;
  //��������ļ�
  PRGUSE:=0;//��FileList���±���=0��
  for I := 1 to PRGUSECOUNT do
  begin
    GameImage:=LoadResFile(FileNameformat('Prguse', i));
    m_FileList.Add(GameImage);
    inc(m_nLoadedFileCount);
  end;
  OTHER:=m_FileList.Count;
  //���������ļ�
  for I := 1 to OTHERCOUNT do
  begin
    GameImage:= LoadResFile(FileNameformat('ChrSel', i));
    m_FileList.Add(GameImage);
    inc(m_nLoadedFileCount);
  end;
  //�����ͼObject�ļ�
  MAPOBJ:=m_FileList.Count;
  for I := 1 to MAPOBJCOUNT do
  begin
    GameImage:=LoadResFile(FileNameFormat('Objects',i));
    m_FileList.Add(GameImage);
    inc(m_nLoadedFileCount);
  end;
  TILES:=m_FileList.Count;
  for I := 1 to TILESCOUNT do
  begin
    GameImage:=LoadResFile(FileNameFormat('Tiles',i));
    m_FileList.Add(GameImage);
    inc(m_nLoadedFileCount);
  end;
  SMTILES := m_FileList.Count;
  for I := 1 to SMTILESCOUNT do
  begin
    GameImage:=LoadResFile(FileNameFormat('SmTiles',i));
    m_FileList.Add(GameImage);
    inc(m_nLoadedFileCount);
  end;

  m_bInited := True;
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
    Exit;
  end else
  if FileExists(sFile+'.Wil') then
  begin
    Result:=TWilImage.Create(sFile+'.Wil');
    Result.Init;
    Exit
  end;
end;


Function TResManager.CalcPercent:Integer;
begin
  Result := trunc((m_nLoadedFileCount div FILECOUNT) * 100);
end;

constructor TResManager.Create(sRoot: string);

begin
  inherited Create(False);
  FreeOnTerminate := False;
  m_bInited := False;
  m_sRoot := sRoot;
  m_FileList:= TList<TGameImage>.Create;
end;

initialization
finalization
begin

end;
end.

