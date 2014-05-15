unit Map;

interface
uses
MondoZengl;
Const
UNITX = 48;
UNITY = 32;
type
  MapType=(Mir2,Mir2New,Mir3,Unknow);

  TMapHeader = packed record
     wWidth  : word;
     wHeight : word;
     btVersion:Byte;  //=15ʱ���ʾ֧�ֶ��tiles ��smtiles
     Title: string[13]; //14���ֽ�
     UpdateDate: TDateTime;
     Reserved  : string[24];//25���ֽ�
  end;


  TGameMap=class
    Protected
      //��ͼ���
      m_nWidth         :Integer;
      m_nHeight        :Integer;
      //�ӽǿ�ߣ�����Ļ��ȸ߶ȡ�
      m_nViewWidth     :Integer;
      m_nViewHeight    :Integer;
      //�ر��obj��ȾĿ��
      m_TilesTarget    :TMZRenderTarget;
      m_ObjsTarget     :TMZRenderTarget;
      //��ͼ�ļ�·���Լ���ͼ����
      m_sMapPath       :string; //��ͼ�ļ�·����
      m_sMapCode       :string; //��ͼ���� M001.MAP ��ô�����ͼ�������M001;
      //��ͼ
      m_bArr_WalkFlag  :array of array of Boolean;
      //�ϴλ��Ƶ�����
      m_LastDrawRect   :TMZRect;
      //����ָ��
      m_Scene          :TMZScene;
      Function GetWalkFlag(x,y :integer):Boolean;
    Public
       Constructor Create;virtual;
       destructor Destroy; override;
      Procedure LoadMap(sfilename:string);virtual;abstract;
      Procedure DrawTile(x,y :integer);virtual;abstract;
      Procedure DrawObject(x,y :Integer);virtual;abstract;
      procedure SetViewSize(Width,Height:integer);
      property WalkFlag[x,y : integer] : Boolean Read GetWalkFlag;
      property Width  : Integer Read m_nWidth;
      Property Height : Integer Read m_nHeight;
      property Scene : TMZScene Read m_Scene write m_Scene;
    end;


Function EstimateMapType(sFileName:String):MapType;
implementation
uses
sysutils,System.Classes,math;

Function EstimateMapType(sFileName:String):MapType;
var
  FileStream:TFileStream;
  Header:TMapHeader;
begin
   Result:=Unknow;
   if FileExists(sFileName) then
   begin
     try
      FileStream := TFileStream.Create(sFileName,fmOpenRead);
      FileStream.Read(Header,SizeOf(TMapHeader));
      if Header.btVersion=15  then Result:= Mir2New
      else Result:=Mir2;
     finally
      FileStream.Free;
     end;

   end;

end;
{ TGameMap }

constructor TGameMap.Create;
begin
   // m_sMapPath      := FileName;
  //m_TargetTexture := TMZRenderTarget.Create(TMZTexture.Create(TextureWidth,TextureHeight,0,[]));
  m_sMapPath      := '';
  m_sMapCode      := '';
  m_LastDrawRect  := TMZRect.Create(0,0,0,0);
  m_nViewWidth    :=800;
  m_nViewHeight   :=600;
  m_TilesTarget   :=nil;
  m_ObjsTarget    :=nil;
end;

destructor TGameMap.Destroy;
begin
  SetLength(m_bArr_WalkFlag,0);
  if Assigned(m_TilesTarget) then FreeAndNil(m_TilesTarget);
  if Assigned(m_ObjsTarget) then FreeAndNil(m_ObjsTarget);
  inherited;
end;

function TGameMap.GetWalkFlag(x, y:integer): Boolean;
begin
  Result:=False;
     {����Ҫ�жϲ�ѯ������ֵ�ǲ����ںϷ���Χ,����Խ�籨��}
  if not ((x >= 0) and (x < m_nWidth)) then Exit;
  if not ((y >= 0) and (y < m_nHeight)) then Exit;
  Result := m_bArr_WalkFlag[x,y];
end;


procedure TGameMap.SetViewSize(Width, Height: integer);
var
  W,H:Integer;
begin
  //���Ƚ�������ȾĿ���ͷŵ�,�����´���������ȾĿ��
  if Assigned(m_TilesTarget) then m_TilesTarget.Free;
  if Assigned(m_ObjsTarget) then m_ObjsTarget.Free;

  {��֤��Ⱥ͸߶ȱ���Ļ����������}
  (*ceil��ȡ�ô��ڵ���X����С��������
   �磺ceil(-123.55)=-123�� ceil(123.15)=124 *)
  W := ceil(Width  / UNITX) + 2;
  H := ceil(Height / UNITY) + 2;
  W := W * UNITX;
  H := H * UNITY;
  {��ֹ������չΪ2��n�η�}
  m_TilesTarget := TMZRenderTarget.Create(TMZTexture.Create(W,H,0,[tfPrecalculateAlpha]));
  m_ObjsTarget  := TMZRenderTarget.Create(TMZTexture.Create(W,H,0,[tfPrecalculateAlpha]));
end;

end.
