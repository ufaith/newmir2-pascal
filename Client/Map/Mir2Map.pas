unit Mir2Map;

interface
uses
Map;
Const
UNITX = 48;
UNITY = 32;
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
      procedure DrawTile(x: Integer; y: Integer); override;//xyΪ��ͼ����������
      procedure DrawObject(x: Integer; y: Integer); override;
    end;

implementation
uses
System.Classes,System.SysUtils,Share,Texture,ResManager,DrawEx,MondoZenGL;
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

procedure TMir2Map.DrawObject(x, y: Integer);
var
  i,j:Integer;
  Xt,Yt:Integer;
  aX,aY:Integer;
  tex:TTexture;
  ImageIndex:Integer;
  FileIndex:Integer;
  NowRect:TMZRect;
  overLapeTex:TMZTexture;
  OverlapeRect:TMZRect;//����ȡ���������
  xx,yy:Single;
begin
  inherited;
  Xt:=(g_nClientWidth div UNITX) + 1;
  Yt:=(g_nClientHeight div UNITY ) + 1;
  if not Assigned(m_Scene) then Exit;
  // ���㱾�λ��Ƶ�����
  NowRect.X:=x;
  NowRect.Y:=0;
  NowRect.W:=TMZApplication.Instance.ScreenWidth;
  NowRect.H:=TMZApplication.Instance.ScreenHeight;
  //�жϱ��λ��Ƶ�������ϴλ��Ƶ������Ƿ�����ص�����
  if NowRect.Equals(m_LastDrawRect) then Exit;{�������������ϴ�������ͬ�Ļ����˳�}
  xx := abs(m_LastDrawRect.X-NowRect.X);
  yy := Abs(m_LastDrawRect.Y-NowRect.y);
  OverlapeRect.W := NowRect.W-xx;
  OverlapeRect.H := NowRect.H-yy;
  OverlapeRect.X := X-m_LastDrawRect.X;
  OverlapeRect.Y := Y-m_LastDrawRect.Y;
  if OverlapeRect.X < 0 then OverlapeRect.X:=0;
  if OverlapeRect.Y < 0 then OverlapeRect.Y:=0;
  //��������ص�������ô���ص���������ȡ����
  overLapeTex:=m_ObjsTarget.Texture;

  //���ص����������Ŀ�������ϡ�
 // m_Scene.Canvas.RenderTarget:=m_ObjsTarget;
  //���Ʒ��ص����������

  for I := 0 to xt do
  begin
    for j := 0 to Yt do
    begin
      //���I,J���ںϷ���Χ֮�� ������
      aX := x+i;
      aY := y+j;
      if (aX < 0) or (aX >= m_nWidth)  then Continue;
      if (aY < 0) or (aY >= m_nHeight) then Continue;
      ImageIndex := m_Arr_TilesInfo[aX,aY].wFrImg and $7FFF;
      FileIndex := m_Arr_TilesInfo[aX,aY].btArea+1;
      tex := TResManager.GetInstance.GetTexture(MAPOBJ,FileIndex,ImageIndex);
      DrawTexture2Canvas(m_Scene.Canvas,Tex.m_Texture,i*UNITX,j*UNITY);
    end;
  end;

end;

procedure TMir2Map.DrawTile(x, y: Integer);
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
