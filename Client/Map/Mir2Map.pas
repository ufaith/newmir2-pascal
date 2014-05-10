unit Mir2Map;

interface
uses
Map;
type
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
   pTNewMapInfo = ^TNewMapInfo;
    TMir2Map=class(TGameMap)
    Private
      m_Arr_TilesInfo : array of array of TNewMapInfo;  //��ά����
    Protected

    public
      Constructor Create(FileName:string;TextureWidth,TextureHeight:Integer);override;
      destructor Destroy; override;
      procedure LoadMap(sFileName:string);override;
    end;

implementation
uses
System.Classes,System.SysUtils;
{ TMir2Map }

constructor TMir2Map.Create(FileName: string; TextureWidth,
  TextureHeight: Integer);
begin
  inherited;
  loadMap(FileName);
end;

destructor TMir2Map.Destroy;
begin

  inherited;
end;

procedure TMir2Map.LoadMap(sFileName: string);
  var
  Header         :TMapHeader;
  FileStream     :TFileStream;
  x,y            :Integer;
  pinfo          :pTNewMapinfo;
  isNewMap       :Boolean;
begin
  inherited;
  //�ж��Ѿ��򿪵ĵ�ͼ�ļ��ǲ��Ǻ͵�ǰ��ͼ�ļ�һ����ȷ����Ҫ�ظ�����

  if sFileName=m_sMapPath then Exit;
   //��ȡ��ͼ��С���������鳤�ȡ�
    m_sMapPath := sFileName;
  try
    FileStream := TFileStream.Create(m_sMapPath,fmOpenRead);
    FileStream.Read(Header,SizeOf(TMapHeader));
    if Header.btVersion = 15 then IsNewMap := True else IsNewMap:=False;
    SetLength(m_Arr_TilesInfo,Header.wWidth,Header.wHeight);
    SetLength(m_bArr_WalkFlag,Header.wWidth,Header.wHeight);
    m_nWidth  := Header.wWidth;
    m_nHeight := Header.wHeight;
    for x := 0 to Header.wWidth-1 do
      begin
        for y := 0 to Header.wHeight-1 do
          begin
            if isNewMap then
              FileStream.Read(m_Arr_TilesInfo[x,y],SizeOf(TNewMapInfo))
            else
            begin
              FileStream.Read(m_Arr_TilesInfo[x,y],SizeOf(TMapInfo));
              m_Arr_TilesInfo[x,y].btBkIndex:=0;
              m_Arr_TilesInfo[x,y].btSmIndex:=0;
            end;
            pinfo := @m_Arr_TilesInfo[x,y];
            with pinfo^ do
            begin   {�����ֶ���ֻҪ��һ���ֶε����λ��1��˵����������}
              if (wbkImg or wMidImg or wFrImg) >$7FFF then
                m_bArr_WalkFlag[x,y] := True
                else
                m_bArr_WalkFlag[x,y] := False;
            end;
          end;
      end;
  finally
    FileStream.Free;
  end;
end;

end.
