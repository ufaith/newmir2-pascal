unit Main;


interface

procedure Init;

implementation

uses
  SysUtils,ResManager,
  MondoZenGL,
  LoadingScene,
  GuiDesign,
  Share,
  GfxFont,
  SoundEngine,
  MZGui;


procedure Init;
var
  Application  :TMZApplication;
  GuiForm      :TfrmGuiDesgin;
begin
  {��б�� \ }
  g_sClientPath                   :=ExtractFilePath(ExtractFilePath(ParamStr(0)));
  g_nClientWidth                  :=800;
  g_nClientHeight                 :=600;
  GuiForm                         :=TfrmGuiDesgin.Create(nil);
  GuiForm.Show;
  Application                     := TMZApplication.Create;
  Application.Options             := Application.Options + [aoShowCursor]+[aoUseSound,aoVSync,aoUseInputEvents];
  Application.Caption             := '��Ѫ����';
  Application.ScreenWidth         := g_nClientWidth;
  Application.ScreenHeight        :=g_nClientHeight;
  Application.ScreenRefreshRate   :=60;
  g_MainFont                      :=TGfxFont.Create('����',12,false,false,False);
  Application.SetScene(TLoadingScene.create);

    //
  TResManager.GetInstance.Free;
    //��������ͷ�GUI������
  TGuiManager.GetInstance.Free;

  //��Ϊ��������һ��ѭ�� ��ѭ��������Ҳ�ͱ�ʾ��������ˡ�������Ҫ����������ͷ���Դ
  GuiForm.Free;
  g_MainFont.Free;
end;

end.
