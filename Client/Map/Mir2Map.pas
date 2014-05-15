unit Mir2Map;

interface
uses
Map;
type
   TMapInfo = record
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

  TNewMapInfo =Packed record  //��Ҫ�رսṹ�����
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
      m_nAniCount    :Cardinal;
      m_dwAniTime     :Cardinal;
    Protected

    public
      Constructor Create;override;
      destructor Destroy; override;
      procedure LoadMap(sFileName:string);override;
      procedure DrawTile(x: Integer; y: Integer); override;//xyΪ��ͼ����������
      procedure DrawObject(x: Integer; y: Integer); override;
    end;

implementation
uses
windows,{GetTickCount��Ҫ}
System.Classes,
System.SysUtils,{�ļ�����Ҫ}
Texture,
ResManager, {��ȡ������Ҫ}
DrawEx, {������Ҫ}
MondoZenGL,{��Ⱦ��������Ҫ}
Math; {ȡ����Ҫ}
{ TMir2Map }

constructor TMir2Map.Create;
begin
  inherited;
  m_nAniCount:=0;
  m_dwAniTime:=GetTickCount;
end;

destructor TMir2Map.Destroy;
begin

  inherited;
end;

procedure TMir2Map.DrawObject(x, y: Integer);{�˹���δʵ��}
var
  {i,j:Integer;
  Xt,Yt:Integer;
  aX,aY:Integer;
  NowRect:TMZRect;
  overLapeTex:TMZTexture;
  OverlapeRect:TMZRect;//����ȡ���������
  xx,yy:Single;}

  LoopX,LoopY,cX,cY:Integer;
  MapInfo:pTNewMapInfo;
  AniFrame:Byte;
  AniTick:Byte;
  NeedBlend:Boolean;
  tex:TTexture;
  ObjImageIndex:Integer;
  ObjFileIndex:Byte;
begin
  inherited;
 (* Xt:=(g_nClientWidth div UNITX) + 1;
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
  end; *)

  {��������أ�50���벥��һ֡����}
  if GetTickCount - m_dwAniTime >= 50 then
  begin
    m_dwAniTime := GetTickCount;
    Inc(m_nAniCount);
    if m_nAniCount > 100000 then m_nAniCount := 0;
  end;
  m_Scene.Canvas.RenderTarget:=m_ObjsTarget;
  cX := Floor(x / UNITX);
  cY := Floor(y / UNITY);
  for LoopX := cX to (m_ObjsTarget.Texture.Width div UNITX)+cX do
  begin
    for LoopY := cY to (m_ObjsTarget.Texture.Height div UNITY)+ cY + 15  do
    begin
      tex := nil;
      if (loopX < 0) or (loopX >= m_nWidth) or (loopY < 0) or (loopY >= m_nHeight)then Continue;
      MapInfo := @m_Arr_TilesInfo[LoopX,LoopY];
      ObjImageIndex := MapInfo.wFrImg and $7FFF;
      if ObjImageIndex > 0 then
      begin
        NeedBlend := False;
        ObjFileIndex := MapInfo.btArea + 1;//��Ϊ��Դ���������±�Ϊ 1��
        if (MapInfo.btAniFrame and $80) > 0 then //���λΪ1��ʾ��֡��ҪBlend����ʵ����Ч֡�������128֡
        begin
          NeedBlend := TRUE;
          AniFrame := MapInfo.btAniFrame and $7F;
          if AniFrame > 0 then
          begin
            AniTick := MapInfo.btAniTick;
            ObjImageIndex := ObjImageIndex + (m_nAniCount mod (AniFrame + (AniFrame * AniTick))) div (1 + AniTick);
          end;
        end;


        if (MapInfo.btDoorOffset and $80) > 0 then // �ŵ����λ1��ʾ�˴�����
        begin
           if (MapInfo.btDoorIndex and $7F) > 0 then
              ObjImageIndex :=  ObjImageIndex + (MapInfo.btDoorOffset and $7F);
        end;

        Dec(ObjImageIndex);
        {�������ϴ���ʽ�������ͼ���ȴ��� �ţ����Ǵ���������������ͨ��obj}
        tex:=TResManager.GetInstance.GetTexture(MAPOBJ,ObjFileIndex,ObjImageIndex);
        if tex = nil then Continue;

        if (tex.Texture.Width=UNITX) and (tex.Texture.Height=UNITY) then
        begin
          DrawTexture2Canvas(m_Scene.Canvas,tex.Texture,(LoopX-cX)*UNITX,(LoopY-cY)*UNITY);
        end else
        begin
          if NeedBlend then
          begin
            DrawTexture2Canvas(m_Scene.Canvas,tex.Texture,(LoopX-cX)*UNITX+tex.X-2 , (LoopY-cY)*UNITY - tex.Texture.Height+UNITY+tex.Y);
          end else
          begin
            DrawTexture2Canvas(m_Scene.Canvas,tex.Texture,(LoopX-cX)*UNITX+tex.X , (LoopY-cY)*UNITY-tex.Texture.Height+UNITY);
          end;

        end;

      end;
    end;

  end;
  m_Scene.Canvas.RenderTarget:=Nil;
  DrawTexture2Canvas(m_Scene.Canvas,m_ObjsTarget.Texture,0,0);

end;


procedure TMir2Map.DrawTile(x, y: Integer);
var
  cX,cY:Integer; //�����x,y
  loopX,loopY:Integer;//ѭ������
  tex:TTexture;
  MapInfo:pTNewMapInfo;

  TilesImageIndex:Integer;
  TilesFileIndex :Byte;
begin
  inherited;
  {floor��ȡ��С�ڵ���X������������
   �磺floor(-123.55)=-124��floor(123.55)=123}
  //���ȸ���X,Y�жϳ���ͼ���ڵ�cX,cYֵ
  cX := Floor(x / UNITX);
  cY := Floor(y / UNITY);
  m_Scene.Canvas.RenderTarget:=m_TilesTarget;
  {��Tiles}
  for loopX := cX to (m_TilesTarget.Texture.Width div UNITX)+cX do
    begin
      for loopY := cY to (m_TilesTarget.Texture.Height div UNITY)+cY do
      begin
        {��ֹ����Խ��}
        if (loopX < 0) or (loopX >= m_nWidth) or (loopY < 0) or (loopY >= m_nHeight)then Continue;
        MapInfo := @m_Arr_TilesInfo[loopX,LoopY];
        {96*48�ĵ�שֻ��������xy��Ϊ 2�ı�����ʱ���������,�������ﻭ���שTiles}
        if (loopX mod 2 = 0) and (loopY mod 2 = 0) then
        begin
          TilesImageIndex := MapInfo.wBkImg and $7FFF;
          if TilesImageIndex > 0 then
          begin
            tex := nil;
            Dec(TilesImageIndex);
            TilesFileIndex := (Mapinfo.btBkIndex and $7F) + 1; //��ΪTiles�����±��Ǵ� 1��ʼ
            tex := TResManager.GetInstance.GetTexture(TILES,TilesFileIndex,TilesImageIndex);
            if tex <> nil then DrawTexture2Canvas(m_Scene.Canvas,tex.Texture,(loopX-cX)*UNITX,(loopY-cY)*UNITY);
          end;
        end;
        {��С��שSmtiles}
        TilesImageIndex := MapInfo.wMidImg and $7FFF;
        if TilesImageIndex > 0 then
        begin
          tex := nil;
          Dec(TilesImageIndex);
          TilesFileIndex := (MapInfo.btSmIndex and $7F) + 1;
          tex := TResManager.GetInstance.GetTexture(SMTILES,TilesFileIndex,TilesImageIndex);
          if tex <> nil then  DrawTexture2Canvas(m_Scene.Canvas,tex.Texture,(loopX-cX)*UNITX-2,(loopY-cY)*UNITY);
        end;
      end;
    end;
  m_Scene.Canvas.RenderTarget:=nil;
  DrawTexture2Canvas(m_Scene.Canvas,m_TilesTarget.Texture,0,0);
end;

procedure TMir2Map.LoadMap(sFileName: string);
  var
  Header         :TMapHeader;
  FileStream     :TFileStream;
  x,y            :Integer;
  pinfo          :pTNewMapinfo;
  isNewMap       :Boolean;
  RecordLength   :Integer;
begin
  inherited;
  //�ж��Ѿ��򿪵ĵ�ͼ�ļ��ǲ��Ǻ͵�ǰ��ͼ�ļ�һ����ȷ����Ҫ�ظ�����
  if sFileName=m_sMapPath then Exit;
   //��ȡ��ͼ��С���������鳤�ȡ�
    m_sMapPath := sFileName;
  try
    FileStream := TFileStream.Create(m_sMapPath,fmOpenRead);
    FileStream.Read(Header,SizeOf(TMapHeader));
    if Header.btVersion = 15 then
    begin
      IsNewMap := True;
      RecordLength := SizeOf(TNewMapInfo);
    end else
    begin
      IsNewMap:=False;
      RecordLength := SizeOf(TMapInfo);
    end;
    SetLength(m_Arr_TilesInfo,Header.wWidth,Header.wHeight);
    SetLength(m_bArr_WalkFlag,Header.wWidth,Header.wHeight);
    m_nWidth  := Header.wWidth;
    m_nHeight := Header.wHeight;
    for x := 0 to Header.wWidth-1 do
      begin
        for y := 0 to Header.wHeight-1 do
          begin
            FileStream.Read(m_Arr_TilesInfo[x,y],RecordLength);
            if not isNewMap then
            begin
              m_Arr_TilesInfo[x,y].btBkIndex:=0;
              m_Arr_TilesInfo[x,y].btSmIndex:=0;
            end;

            pinfo := @m_Arr_TilesInfo[x,y];
            with pinfo^ do
            begin   {�����ֶ���ֻҪ��һ���ֶε����λ��1��˵����������}
              if (wbkImg or wMidImg or wFrImg) > $7FFF then
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
