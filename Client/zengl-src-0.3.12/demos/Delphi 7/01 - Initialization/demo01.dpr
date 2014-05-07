program demo01;
// CN:����ļ�����һЩ����(����ʹ�ò�ʹ�þ�̬����) �� ����ʹ�����ӵĲ���ϵͳ
// EN: This file contains some options(e.g. whether to use static compilation) and defines of OS for which is compilation going.
{$I zglCustomConfig.cfg}

{$R *.res}

uses
  {$IFDEF USE_ZENGL_STATIC}
  //CN:ʹ�þ�̬������Ҫuse ZenGL�Ĺ��ܵĵ�Ԫ��
  // EN: Using static compilation needs to use ZenGL units with needed functionality.
  zgl_main,
  zgl_screen,
  zgl_window,
  zgl_timers,
  zgl_utils
  {$ELSE}
  // RU:ʹ�ö�̬���ӿ�(so,dll,dylib) ������Ҫһ��ͷ�ļ�
  // EN: Using ZenGL as a shared library(so, dll or dylib) needs only one header.
  zglHeader
  {$ENDIF}
  ;

var
  DirApp  : UTF8String;
  DirHome : UTF8String;
  UpdateDt: Double;

procedure Init;
begin
  // CN: ����������������Դ�ļ�
  // EN: Here can be loading of main resources.
end;

procedure Draw;
begin
  // CN: ������������ж���
  // EN: Here "draw" anything :)
end;

procedure Update( dt : Double );
begin
  // CN:�ڴ˺���ʵ��ƽ�����ƶ���������ġ���Ϊ��ʱ���ľ�ȷ����������fps
  // �˺�������ÿ����Ⱦ֮ǰִ�С��䴫�ݽ�����dt�����ǵ�ǰ֡���ϴ�֡�ļ����
  UpdateDt:=dt;

  // EN: This function is the best way to implement smooth moving of something, because accuracy of timers are restricted by FPS.
end;

procedure Timer;
begin
  // CN: Caption ������ʾÿ���֡��
  // EN: Caption will show the frames per second.
  //wnd_SetCaption( '01 - Initialization[ FPS: ' + u_IntToStr( zgl_Get( RENDER_FPS ) ) + ' ]' );
  wnd_SetCaption(AnsiToUtf8('01 - ��ʼ��ZenGl [ FPS: ' + u_IntToStr(zgl_Get(RENDER_FPS)))+']'+u_floatToStr(UpdateDt));
end;

procedure Quit;
begin

end;

Begin
  // CN: ���û��ʹ�þ�̬���� ����Ĵ��뽫�����붯̬��
  // EN: Code below loads a library if static compilation is not used.
  {$IFNDEF USE_ZENGL_STATIC}
  if not zglLoad( libZenGL ) Then exit;
  {$ENDIF}

  // CN:Ϊ���������/���������ļ����������ģ����Ի�ȡ�û��ĸ�Ŀ¼�����߿�ִ���ļ�Ŀ¼(��֧��GNU/Linux)� ��
  // EN: For loading/creating your own options/profiles/etc. you can get path to user home directory, or to executable file(not works for GNU/Linux).
  DirApp  := utf8_Copy( PAnsiChar( zgl_Get( DIRECTORY_APPLICATION ) ) );
  DirHome := utf8_Copy( PAnsiChar( zgl_Get( DIRECTORY_HOME ) ) );

  // CN:����һ�����Ϊ1000ms�Ķ�ʱ��
  // EN: Create a timer with interval 1000ms.
  timer_Add( @Timer, 1000 );

  // CN:ע��һ�����̣�������̽���ZenGL��ʼ�������
  // EN: Register the procedure, that will be executed after ZenGL initialization.
  zgl_Reg( SYS_LOAD, @Init );

  // CN:ע����Ⱦ����
  // EN: Register the render procedure.
  zgl_Reg( SYS_DRAW, @Draw );
  
  // CN��ע��һ������ ��������̽����ȡ����֡�ļ��
  // EN: Register the procedure, that will get delta time between the frames.
  zgl_Reg( SYS_UPDATE, @Update );

  // CN:ע��һ�����̣��˹��̽���ZenGl�رպ�ִ��
  // EN: Register the procedure, that will be executed after ZenGL shutdown.
  zgl_Reg( SYS_EXIT, @Quit );

  // CN:���ô��ڵı�������
  // EN: Set the caption of the window.
  wnd_SetCaption( AnsiToUtf8('��Ѫ����') );

  // CN:������ʾ�����
  // EN: Allow to show the mouse cursor.
  wnd_ShowCursor( TRUE );

  // CN: ������Ļ
  // EN: Set screen options.
  scr_SetOptions( 800, 600, REFRESH_MAXIMUM, FALSE, FALSE );

  // CN: ��ʼ��ZenGL.
  // EN: Initialize ZenGL.
  zgl_Init();
End.
