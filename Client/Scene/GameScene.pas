unit GameScene;

interface

uses
  MondoZenGl, MZGui,SoundEngine;

type
  TGameScene = Class(TMZScene)
  Protected
    Class Var ClickDown: Boolean;
    Class Function GetKeyStates: TKeyStates;
    procedure MouseDown(const Button: TMZMouseButton); override;
    procedure MouseMove(const X: Integer; const Y: Integer); override;
    procedure MouseUp(const Button: TMZMouseButton); override;
    procedure KeyDown(const KeyCode: TMZKeyCode); override;
    procedure KeyUp(const KeyCode: TMZKeyCode); override;
    procedure Update(const DeltaTimeMs: Double); override;
    procedure Shutdown;override;
  End;

implementation

{ TGameScene }

class function TGameScene.GetKeyStates: TKeyStates;
begin
  Result := [];
  if TMZKeyboard.IsKeyPressed(kcAlt) then
    Result := Result + [kAlt];
  if TMZKeyboard.IsKeyPressed(kcCtrl) then
    Result := Result + [kCtrl];
  if TMZKeyboard.IsKeyPressed(kcShift) then
    Result := Result + [kShift];
  if TMZMouse.IsButtonDown(mbLeft) then
    Result := Result + [mLeft];
  if TMZMouse.IsButtonDown(mbMiddle) then
    Result := Result + [mMiddle];
  if TMZMouse.IsButtonDown(mbRight) then
    Result := Result + [mRight];
end;

procedure TGameScene.KeyDown(const KeyCode: TMZKeyCode);
begin
  inherited;
  TGuiManager.GetInstance.KeyDown(GetKeyStates, KeyCode);
end;

procedure TGameScene.KeyUp(const KeyCode: TMZKeyCode);
begin
  inherited;
  TGuiManager.GetInstance.KeyUp(GetKeyStates, KeyCode);
end;

procedure TGameScene.MouseDown(const Button: TMZMouseButton);
var
  X, Y: Integer;
begin
  inherited;
  TMZMouse.GetPos(X, Y);
  TGuiManager.GetInstance.MouseDown(GetKeyStates, TMZMouseButton(Button), X, Y);
  if TMZMouseButton(Button) = mbLeft then
    ClickDown := True;
end;

procedure TGameScene.MouseMove(const X, Y: Integer);
begin
  inherited;
  TGuiManager.GetInstance.MouseMove(GetKeyStates, X, Y);
end;

procedure TGameScene.MouseUp(const Button: TMZMouseButton);
var
  X, Y: Integer;
begin
  inherited;
  TMZMouse.GetPos(X, Y);
  TGuiManager.GetInstance.MouseUp(GetKeyStates, TMZMouseButton(Button), X, Y);
  if ClickDown then
  begin
    if TMZMouseButton(Button) = mbLeft then
    begin
      TGuiManager.GetInstance.Click(GetKeyStates, X, Y);
      ClickDown := False;
    end;
  end;
end;

procedure TGameScene.Shutdown;
begin
  inherited;
  TSoundEngine.GetInstance.Free;
  {������Դ������Ҫ�ڳ���������ʱ������ͷš������ڶ���Դ�����ͷŵ�ʱ�� ZenGl�����Ѿ��ͷŵ��� ȴ����Դ�ٽ���
  �ͷŻ�����ڴ���ʴ���}
end;

procedure TGameScene.Update(const DeltaTimeMs: Double);
begin
  inherited;
  TGuiManager.GetInstance.Update(DeltaTimeMs);
end;

end.
