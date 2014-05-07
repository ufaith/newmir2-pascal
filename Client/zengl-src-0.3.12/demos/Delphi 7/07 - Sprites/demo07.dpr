program demo07;

{$I zglCustomConfig.cfg}

{$R *.res}

uses
  {$IFDEF USE_ZENGL_STATIC}
  zgl_main,
  zgl_screen,
  zgl_window,
  zgl_timers,
  zgl_keyboard,
  zgl_camera_2d,
  zgl_render_2d,
  zgl_fx,
  zgl_textures,
  zgl_textures_png,
  zgl_textures_jpg,
  zgl_sprite_2d,
  zgl_primitives_2d,
  zgl_font,
  zgl_text,
  zgl_math_2d,
  zgl_utils
  {$ELSE}
  zglHeader
  {$ENDIF}
  ;

type
  TTux = record
    Texture : zglPTexture;
    Frame   : Integer;
    Pos     : zglTPoint2D;
end;

var
  dirRes      : UTF8String {$IFNDEF MACOSX} = '../data/' {$ENDIF};
  fntMain     : zglPFont;
  texLogo     : zglPTexture;
  texBack     : zglPTexture;
  texGround   : zglPTexture;
  texTuxWalk  : zglPTexture;
  texTuxStand : zglPTexture;
  tux         : array[ 0..20 ] of TTux;
  time        : Integer;
  camMain     : zglTCamera2D;
  Title       : UTF8String='������';
procedure Init;
  var
    i : Integer;
begin
  // CN:Camera �����ʼ������Ϊcamera�ṹ���ڲ�ֵĬ����0
  // EN: Camera must be initialized, because camera structure is zero-filled by default.
  cam2d_Init( camMain );

  //CN: ��������
  // $FF000000 -��ζ��͸��ͨ�����������ļ��ġ�����û��͸��ɫ��
  // TEX_DEFAULT_2D  -һ���Ƚϸ��ӵı�־����,2D ������Ҫʹ������ ��ϸ��Ϣ�����ڰ����ĵ����ҵ�
  // EN: Load the texture.
  //     $FF000000 - means that alpha channel must be used from file, without colorkey.
  //     TEX_DEFAULT_2D - complex of flags that needed for 2D sprites. Description can be found in help.
  texLogo := tex_LoadFromFile( dirRes + 'zengl.png', $FF000000, TEX_DEFAULT_2D );

  texBack := tex_LoadFromFile( dirRes + 'back01.jpg' );

  texGround := tex_LoadFromFile( dirRes + 'ground.png' );
  // CN:���õ���֡�Ĵ�С
  // EN: Set the size of single frame for texture.
  tex_SetFrameSize( texGround, 32, 32 );

  texTuxWalk := tex_LoadFromFile( dirRes + 'tux_walking.png' );
  tex_SetFrameSize( texTuxWalk, 64, 64 );
  texTuxStand := tex_LoadFromFile( dirRes + 'tux_stand.png' );
  tex_SetFrameSize( texTuxStand, 64, 64 );

  for i := 0 to 9 do
    begin
      tux[ i ].Texture := texTuxWalk;
      tux[ i ].Frame   := random( 19 ) + 2;
      tux[ i ].Pos.X   := i * 96;
      tux[ i ].Pos.Y   := 32;
    end;
  for i := 10 to 19 do
    begin
      tux[ i ].Texture := texTuxWalk;
      tux[ i ].Frame   := random( 19 ) + 2;
      tux[ i ].Pos.X   := ( i - 9 ) * 96;
      tux[ i ].Pos.Y   := 600 - 96;
    end;
  tux[ 20 ].Texture := texTuxStand;
  tux[ 20 ].Frame   := random( 19 ) + 2;
  tux[ 20 ].Pos.X   := 400 - 32;
  tux[ 20 ].Pos.Y   := 300 - 64 - 4;

  // ��������
  // EN: Load the font.
  fntMain := font_LoadFromFile( dirRes + 'font.zfi' );
end;

procedure Draw;
  var
    i : Integer;
    t : Single;
begin
  batch2d_Begin();
  if time > 255 Then
    begin
      // CN:�ر���ɫ������һ��������Ⱦ���ܵĺð취����Ϊ��Ļ��ͨ���ǳ����˸��ֶ����
      // EN: Rendering perfomance can be increased by disabling clearing the color buffer. This is a good idea because screen is full of objects.
      zgl_Disable( COLOR_BUFFER_CLEAR );

      // CN:����������Ļ�ϲ������ŵ�800*600
      // EN: Render the background with size 800x600 and using texture "back".
      ssprite2d_Draw( texBack, 0, 0, 800, 600, 0 );

      // CN:���õ�ǰcamera
      // EN: Set the current camera.
      cam2d_Set( @camMain );

      // CN: ���ƹ㳡
      // EN: Render the ground.
      for i := -2 to 800 div 32 + 1 do
        asprite2d_Draw( texGround, i * 32, 96 - 12, 32, 32, 0, 2 );
      for i := -2 to 800 div 32 + 1 do
        asprite2d_Draw( texGround, i * 32, 600 - 32 - 12, 32, 32, 0, 2 );

      // CN:�������
      // EN: Render penguins
      for i := 0 to 9 do
        if i = 2 Then
          begin
            // CN: ������ϻ��ƿ��
            // EN: Render the text in frame over penguins.
            t := text_GetWidth( fntMain, 'I''m so red...' ) * 0.75 + 4;
            pr2d_Rect( tux[ i ].Pos.X - 2, tux[ i ].Pos.Y - fntMain.MaxHeight + 4, t, fntMain.MaxHeight, $000000, 200, PR2D_FILL );
            pr2d_Rect( tux[ i ].Pos.X - 2, tux[ i ].Pos.Y - fntMain.MaxHeight + 4, t, fntMain.MaxHeight, $FFFFFF );
            text_DrawEx( fntMain, tux[ i ].Pos.X, tux[ i ].Pos.Y - fntMain.MaxHeight + 8, 0.75, 0, 'I''m so red...' );
            // CN:ʹ��fx2d������FX_Color��־ ���ƺ�ɫ���
            // EN: Render red penguin using fx2d-function and flag FX_COLOR.
            fx2d_SetColor( $FF0000 );
            asprite2d_Draw( tux[ i ].Texture, tux[ i ].Pos.X, tux[ i ].Pos.Y, 64, 64, 0, tux[ i ].Frame div 2, 255, FX_BLEND or FX_COLOR );
          end else
            if i = 7 Then
              begin
                t := text_GetWidth( fntMain, '???' ) * 0.75 + 4;
                pr2d_Rect( tux[ i ].Pos.X + 32 - t / 2, tux[ i ].Pos.Y - fntMain.MaxHeight + 4, t, fntMain.MaxHeight, $000000, 200, PR2D_FILL );
                pr2d_Rect( tux[ i ].Pos.X + 32 - t / 2, tux[ i ].Pos.Y - fntMain.MaxHeight + 4, t, fntMain.MaxHeight, $FFFFFF );
                text_DrawEx( fntMain, tux[ i ].Pos.X + 32, tux[ i ].Pos.Y - fntMain.MaxHeight + 8, 0.75, 0, '???', 255, $FFFFFF, TEXT_HALIGN_CENTER );
                // CN: ����������� ʹ��FX_COLOR_SET �� FX_COLOR;
                // EN: Render penguin ghost using flag FX_COLOR and mode FX_COLOR_SET :)
                fx_SetColorMode( FX_COLOR_SET );
                fx2d_SetColor( $FFFFFF );
                asprite2d_Draw( tux[ i ].Texture, tux[ i ].Pos.X, tux[ i ].Pos.Y, 64, 64, 0, tux[ i ].Frame div 2, 155, FX_BLEND or FX_COLOR );
                // CN: �ص�Ĭ�ϵĻ���ģʽ
                // EN: Return default mode.
                fx_SetColorMode( FX_COLOR_MIX );
              end else
                asprite2d_Draw( tux[ i ].Texture, tux[ i ].Pos.X, tux[ i ].Pos.Y, 64, 64, 0, tux[ i ].Frame div 2 );

      // CN: ʹ����һ�ַ����������ʹ��FX2D_FLIPX
      // EN: Render penguins, that go another way using special flag for flipping texture - FX2D_FLIPX.
      for i := 10 to 19 do
        if i = 13 Then
          begin
            t := text_GetWidth( fntMain, 'I''m so big...' ) * 0.75 + 4;
            pr2d_Rect( tux[ i ].Pos.X - 2, tux[ i ].Pos.Y - fntMain.MaxHeight - 10, t, fntMain.MaxHeight, $000000, 200, PR2D_FILL );
            pr2d_Rect( tux[ i ].Pos.X - 2, tux[ i ].Pos.Y - fntMain.MaxHeight - 10, t, fntMain.MaxHeight, $FFFFFF );
            text_DrawEx( fntMain, tux[ i ].Pos.X, tux[ i ].Pos.Y - fntMain.MaxHeight - 4, 0.75, 0, 'I''m so big...' );
            // CN: ���ƴ���졣.�������ƶ�λ�á���ΪFX2D_SCALE ���ž��������������ġ�
            // EN: Render "big" penguin. It must be shifted up, because FX2D_SCALE scale sprite relative to the center.
            fx2d_SetScale( 1.25, 1.25 );
            asprite2d_Draw( tux[ i ].Texture, tux[ i ].Pos.X, tux[ i ].Pos.Y - 8, 64, 64, 0, tux[ i ].Frame div 2, 255, FX_BLEND or FX2D_FLIPX or FX2D_SCALE );
          end else
            if i = 17 Then
              begin
                // CN: ��Ⱦ"�߸������" ʹ�� FX2D_VCHAGE ����FX2D_SCALE,  ����fx2d_SetVertexes �������ƶ����鶥�㣡
                // EN: Render "tall" penguin using flag FX2D_VCHANGE instead of FX2D_SCALE, and function fx2d_SetVertexes for shifting upper vertexes of sprite.
                fx2d_SetVertexes( 0, -16, 0, -16, 0, 0, 0, 0 );
                asprite2d_Draw( tux[ i ].Texture, tux[ i ].Pos.X, tux[ i ].Pos.Y, 64, 64, 0, tux[ i ].Frame div 2, 255, FX_BLEND or FX2D_FLIPX or FX2D_VCHANGE );
              end else
                asprite2d_Draw( tux[ i ].Texture, tux[ i ].Pos.X, tux[ i ].Pos.Y, 64, 64, 0, tux[ i ].Frame div 2, 255, FX_BLEND or FX2D_FLIPX );

      // CN: ����camera
      // EN: Reset the camera.
      cam2d_Set( nil );

      // CN: ����Ļ�м���ƹ㳡
      // EN: Render piece of ground in the center of screen.
      asprite2d_Draw( texGround, 11 * 32, 300 - 16, 32, 32, 0, 1 );
      asprite2d_Draw( texGround, 12 * 32, 300 - 16, 32, 32, 0, 2 );
      asprite2d_Draw( texGround, 13 * 32, 300 - 16, 32, 32, 0, 3 );

      t := text_GetWidth( fntMain, 'o_O' ) * 0.75 + 4;
      pr2d_Rect( tux[ 20 ].Pos.X + 32 - t / 2, tux[ 20 ].Pos.Y - fntMain.MaxHeight + 4, t, fntMain.MaxHeight, $000000, 200, PR2D_FILL );
      pr2d_Rect( tux[ 20 ].Pos.X + 32 - t / 2, tux[ 20 ].Pos.Y - fntMain.MaxHeight + 4, t, fntMain.MaxHeight, $FFFFFF );
      text_DrawEx( fntMain, tux[ 20 ].Pos.X + 32, tux[ 20 ].Pos.Y - fntMain.MaxHeight + 8, 0.75, 0, 'o_O', 255, $FFFFFF, TEXT_HALIGN_CENTER );
      asprite2d_Draw( tux[ 20 ].Texture, tux[ 20 ].Pos.X, tux[ 20 ].Pos.Y, 64, 64, 0, tux[ 20 ].Frame div 2 );
    end;

  if time <= 255 Then
    ssprite2d_Draw( texLogo, 400 - 256, 300 - 128, 512, 256, 0, time )
  else
    if time < 510 Then
      begin
        pr2d_Rect( 0, 0, 800, 600, $000000, 510 - time, PR2D_FILL );
        ssprite2d_Draw( texLogo, 400 - 256, 300 - 128, 512, 256, 0, 510 - time );
      end;

  if time > 255 Then
    text_Draw( fntMain, 0, 0, 'FPS: ' + u_IntToStr( zgl_Get( RENDER_FPS ) ) );
  batch2d_End();
end;

procedure Timer;
  var
    i : Integer;
begin
  INC( time, 2 );

  camMain.Angle := camMain.Angle + cos( time / 1000 ) / 10;

  for i := 0 to 20 do
    begin
      INC( tux[ i ].Frame );
      if tux[ i ].Frame > 20 Then
        tux[ i ].Frame := 2;
    end;
  for i := 0 to 9 do
    begin
      tux[ i ].Pos.X := tux[ i ].Pos.X + 1.5;
      if tux[ i ].Pos.X > 864 Then
        tux[ i ].Pos.X := -96;
    end;
  for i := 10 to 19 do
    begin
      tux[ i ].Pos.X := tux[ i ].Pos.X - 1.5;
      if tux[ i ].Pos.X < -96 Then
        tux[ i ].Pos.X := 864;
    end;

  if key_Press( K_ESCAPE ) Then zgl_Exit();
  key_ClearState();
end;

Begin

  {$IFNDEF USE_ZENGL_STATIC}
  if not zglLoad( libZenGL ) Then exit;
  {$ENDIF}

  randomize();

  timer_Add( @Timer, 16 );

  zgl_Reg( SYS_LOAD, @Init );
  zgl_Reg( SYS_DRAW, @Draw );

  wnd_SetCaption( '07 - Sprites' );
  //wnd_SetCaption( Title );

  wnd_ShowCursor( TRUE );

  scr_SetOptions( 800, 600, REFRESH_MAXIMUM, FALSE, FALSE );

  zgl_Init();
End.
