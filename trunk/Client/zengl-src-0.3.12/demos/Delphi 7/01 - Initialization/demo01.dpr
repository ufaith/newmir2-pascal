program demo01;
// CN:这个文件包括一些蛇这(例如使用不使用静态链接) 与 定义使用链接的操作系统
// EN: This file contains some options(e.g. whether to use static compilation) and defines of OS for which is compilation going.
{$I zglCustomConfig.cfg}

{$R *.res}

uses
  {$IFDEF USE_ZENGL_STATIC}
  //CN:使用静态链接需要use ZenGL的功能的单元。
  // EN: Using static compilation needs to use ZenGL units with needed functionality.
  zgl_main,
  zgl_screen,
  zgl_window,
  zgl_timers,
  zgl_utils
  {$ELSE}
  // RU:使用动态链接库(so,dll,dylib) 仅仅需要一个头文件
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
  // CN: 可以在这里载入资源文件
  // EN: Here can be loading of main resources.
end;

procedure Draw;
begin
  // CN: 在这里绘制所有东西
  // EN: Here "draw" anything :)
end;

procedure Update( dt : Double );
begin
  // CN:在此函数实现平滑的移动是最理想的。因为定时器的精确度受限制于fps
  // 此函数将在每次渲染之前执行。其传递进来的dt参数是当前帧和上次帧的间隔。
  UpdateDt:=dt;

  // EN: This function is the best way to implement smooth moving of something, because accuracy of timers are restricted by FPS.
end;

procedure Timer;
begin
  // CN: Caption 将会显示每秒的帧率
  // EN: Caption will show the frames per second.
  //wnd_SetCaption( '01 - Initialization[ FPS: ' + u_IntToStr( zgl_Get( RENDER_FPS ) ) + ' ]' );
  wnd_SetCaption(AnsiToUtf8('01 - 初始化ZenGl [ FPS: ' + u_IntToStr(zgl_Get(RENDER_FPS)))+']'+u_floatToStr(UpdateDt));
end;

procedure Quit;
begin

end;

Begin
  // CN: 如果没有使用静态连接 下面的代码将会载入动态库
  // EN: Code below loads a library if static compilation is not used.
  {$IFNDEF USE_ZENGL_STATIC}
  if not zglLoad( libZenGL ) Then exit;
  {$ENDIF}

  // CN:为了载入或者/创建设置文件或者其他的，可以获取用户的根目录。或者可执行文件目录(不支持GNU/Linux)� 
  // EN: For loading/creating your own options/profiles/etc. you can get path to user home directory, or to executable file(not works for GNU/Linux).
  DirApp  := utf8_Copy( PAnsiChar( zgl_Get( DIRECTORY_APPLICATION ) ) );
  DirHome := utf8_Copy( PAnsiChar( zgl_Get( DIRECTORY_HOME ) ) );

  // CN:创建一个间隔为1000ms的定时器
  // EN: Create a timer with interval 1000ms.
  timer_Add( @Timer, 1000 );

  // CN:注册一个过程，这个过程将在ZenGL初始化后完成
  // EN: Register the procedure, that will be executed after ZenGL initialization.
  zgl_Reg( SYS_LOAD, @Init );

  // CN:注册渲染过程
  // EN: Register the render procedure.
  zgl_Reg( SYS_DRAW, @Draw );
  
  // CN：注册一个过程 ，这个过程将会获取两次帧的间隔
  // EN: Register the procedure, that will get delta time between the frames.
  zgl_Reg( SYS_UPDATE, @Update );

  // CN:注册一个过程，此过程将在ZenGl关闭后执行
  // EN: Register the procedure, that will be executed after ZenGL shutdown.
  zgl_Reg( SYS_EXIT, @Quit );

  // CN:设置窗口的标题属性
  // EN: Set the caption of the window.
  wnd_SetCaption( AnsiToUtf8('热血传奇') );

  // CN:允许显示鼠标光标
  // EN: Allow to show the mouse cursor.
  wnd_ShowCursor( TRUE );

  // CN: 设置屏幕
  // EN: Set screen options.
  scr_SetOptions( 800, 600, REFRESH_MAXIMUM, FALSE, FALSE );

  // CN: 初始化ZenGL.
  // EN: Initialize ZenGL.
  zgl_Init();
End.
