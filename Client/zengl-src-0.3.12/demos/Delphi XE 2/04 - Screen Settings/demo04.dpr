program demo04;

{$I zglCustomConfig.cfg}

{$R *.res}

uses
  {$IFDEF USE_ZENGL_STATIC}
  zgl_main,
  zgl_screen,
  zgl_window,
  zgl_timers,
  zgl_keyboard,
  zgl_font,
  zgl_text,
  zgl_sprite_2d,
  zgl_textures,
  zgl_textures_png,
  zgl_textures_jpg,
  zgl_utils
  {$ELSE}
  zglHeader
  {$ENDIF}
  ;

var
  dirRes  : UTF8String {$IFNDEF MACOSX} = '../data/' {$ENDIF};

  fntMain : zglPFont;
  texBack : zglPTexture;

procedure Init;
begin
  fntMain := font_LoadFromFile( dirRes + 'font.zfi' );
  texBack := tex_LoadFromFile( dirRes + 'back03.jpg' );
end;

procedure Draw;
begin
  ssprite2d_Draw( texBack, 0, 0, 800, 600, 0 );

  text_Draw( fntMain, 0, 0, 'Escape - Exit' );
  text_Draw( fntMain, 0, fntMain.MaxHeight * 1, 'F1 - Fullscreen with desktop resolution and correction of aspect' );
  text_Draw( fntMain, 0, fntMain.MaxHeight * 2, 'F2 - Fullscreen with desktop resolution and simple scaling' );
  text_Draw( fntMain, 0, fntMain.MaxHeight * 3, 'F3 - Fullscreen with resolution 800x600' );
  text_Draw( fntMain, 0, fntMain.MaxHeight * 4, 'F4 - Windowed mode' );
end;

procedure Timer;
begin
  // RU: ������������� � ������������� ������������� �����. �������� ���� - ������������� � ������������� ����� ��������� ������� ���������� �������� ����� ������������, �� ��� ����
  //     ��������� ��������� �����������. ��� �������� �������� ��������� ������� � LCD.
  // EN: Recommended fullscreen mode for using. Main idea is switching to fullscreen mode using current desktop resolution of user and saving the aspect. This will avoid some problems
  //     with LCD's.
  if key_Press( K_F1 ) Then
    begin
      // RU: �������� ��������� ���������.
      // EN: Enable aspect correction.
      zgl_Enable( CORRECT_RESOLUTION );
      // RU: ���������� ���������� ��� ������� ���������� �������� ����������.
      // EN: Set resolution for what application was wrote.
      scr_CorrectResolution( 800, 600 );
      scr_SetOptions( zgl_Get( DESKTOP_WIDTH ), zgl_Get( DESKTOP_HEIGHT ), REFRESH_MAXIMUM, TRUE, FALSE );
    end;

  // RU: ������ ����� � ���������� �� ����� ����������� - ��������� ��������� �� ������ � ������. ��������, ���������� ��������� �� ������ ����� ����������� ��� ����������
  //     ������ 5:4(���������� ������ 1280x1024), �.�. ����� ��������� ��� ������� ������ ��� ������������ ���������.
  // EN: Similar mode to previous one with one exception - disabled correction for width and height. E.g. this can be useful for aspect 5:4(resolution 1280x1024),
  //     because screen can be filled without significant distortion.
  if key_Press( K_F2 ) Then
    begin
      zgl_Enable( CORRECT_RESOLUTION );
      zgl_Disable( CORRECT_WIDTH );
      zgl_Disable( CORRECT_HEIGHT );
      scr_CorrectResolution( 800, 600 );
      scr_SetOptions( zgl_Get( DESKTOP_WIDTH ), zgl_Get( DESKTOP_HEIGHT ), REFRESH_MAXIMUM, TRUE, FALSE );
    end;

  // RU: ������������ � ������������� ����� ��������� ��������� �������. � ���� ����� ����� ������ ����� ��� ������� ���������� �� LCD:
  //     - ���� ����������� ���������� �� �������� ������ ��� LCD, �� ��� ����������� ���������� � ��������� ������������ ����� ��������� ������������
  //     - �� �������������� ��������� �������� � ������������ 4:3 ����� ��������� ����������
  // EN: Switching to fullscreen mode using set values. Nowadays this method two main problems with LCD:
  //     - if used resolution is not main for LCD, then without special options in drivers user will see pixelization
  //     - picture with aspect 4:3 will be stretched on widescreen monitors
  if key_Press( K_F3 ) Then
    begin
      zgl_Disable( CORRECT_RESOLUTION );
      scr_SetOptions( 800, 600, REFRESH_MAXIMUM, TRUE, FALSE );
    end;

  // RU: ������� �����.
  // EN: Windowed mode.
  if key_Press( K_F4 ) Then
    begin
      zgl_Disable( CORRECT_RESOLUTION );
      scr_SetOptions( 800, 600, REFRESH_MAXIMUM, FALSE, FALSE );
    end;

  if key_Press( K_ESCAPE ) Then zgl_Exit();

  key_ClearState();
end;

Begin
  {$IFNDEF USE_ZENGL_STATIC}
  if not zglLoad( libZenGL ) Then exit;
  {$ENDIF}

  timer_Add( @Timer, 16 );

  zgl_Reg( SYS_LOAD, @Init );
  zgl_Reg( SYS_DRAW, @Draw );

  wnd_SetCaption( '04 - Screen Settings' );

  wnd_ShowCursor( TRUE );

  scr_SetOptions( 800, 600, REFRESH_MAXIMUM, FALSE, FALSE );

  zgl_Init();
End.
