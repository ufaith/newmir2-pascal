program demo02;

{$I zglCustomConfig.cfg}

{$R *.res}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes,

  {$IFDEF USE_ZENGL_STATIC}
  zgl_types,
  zgl_main,
  zgl_screen,
  zgl_window,
  zgl_timers,
  // CN:�ļ����õ�Ԫ��zipѹ���ļ����ڴ��ļ�
  // EN: Units for using files, files in memory and zip archives.
  zgl_file,
  zgl_memory,
  // CN:���߳���Դ���뵥Ԫ��
  // EN: Unit for multithreaded resource loading.
  zgl_resources,
  // CN:���嵥Ԫ
  // EN: Unit for using fonts.
  zgl_font,
  // CN:����Ԫ��zgl_textures ��һ����Ҫ�ĵ�Ԫ,����ĵ�Ԫ���ṩ�Բ�ͬ��ʽ���ļ�֧�֡�
  // EN: Units for using textures. zgl_textures is a main unit, next units provide support of different formats.
  zgl_textures,
  zgl_textures_tga, // TGA
  zgl_textures_jpg, // JPG
  zgl_textures_png, // PNG
  // CN������ʵ����ϵͳ�ڴ˵�Ԫ���档˼���Ǻ�����һ���ģ�����һ����Ҫ�ĵ�Ԫ����������Ҫ֧�ֵĲ�ͬ��ʽ�ĵ�Ԫ��
  // EN: Sound subsystem implemented in units below. Idea the same as for textures - there is a main unit and units for support different formats.
  zgl_sound,
  zgl_sound_wav, // WAV
  zgl_sound_ogg, // OGG

  zgl_primitives_2d,
  zgl_text,
  zgl_sprite_2d,
  zgl_utils
  {$ELSE}
  zglHeader
  {$ENDIF}
  ;

var
  dirRes : UTF8String {$IFNDEF MACOSX} = '../data/' {$ENDIF};

  memory : zglTMemory;

  // CN:ÿ����Դ����һ����������ͣ���������һ��ָ��ṹ���ָ��
  // EN: Every resource has its own typem which is just a pointer to structure.
  fntMain  : zglPFont;
  //
  texLogo  : zglPTexture;
  texTest  : zglPTexture;
  //
  sndClick : zglPSound;
  sndMusic : zglPSound;

procedure TextureCalcEffect( pData : PByteArray; Width, Height : Word );
begin
  u_Sleep( 1000 );
end;

procedure Init;
  var
    i         : Integer;
    memStream : TMemoryStream;
begin
  // CN: ���������Щ�����Ĳ������÷�����������DEMO���ҵ�������ֻʹ����һ����÷���
  // EN: Description with more details about parameters of functions can be found in other demos, here is only main idea shown.

  snd_Init();

  // CN:������Դ�ĺ���ʹ��  "����_LoadFromλ��" ��ʽ�������� "����"������tex snd font �ȵ� "λ��"���������ļ� �����ڴ���
  // EN: Functions for loading resources named in format "$(prefix)_LoadFrom$(where)", where "$(prefix)" can be tex, snd, font and so on, and $(where) - File and Memory.
  fntMain  := font_LoadFromFile( dirRes + 'font.zfi' );
  texLogo  := tex_LoadFromFile( dirRes + 'zengl.png' );
  sndClick := snd_LoadFromFile( dirRes + 'click.wav' );

  // CN:���߳���Դ��ȡ�����ڶ�ȡ��ʱ�򴴽�һ�������Լ������������飬������ȾһЩ����
  // ���߳���Դ��ȡ��һ���ȡû�в�֮ͬ��������ʹ�ú���������ʼ�ͽ������С�
  // EN: Multithreaded resource loading allows to make queue and do something while loading, e.g. rendering some animation.
  //     Loading resources in multithreaded mode has almost no difference with standard mode, except using functions for beginning and ending queues.
  res_BeginQueue( 0 );
  // CN:Ϊ�˱�����Ļ��������棬���������е���Դ��ȡ��������Ҫ��res_BeginQueue ��res_EndQueque�е��á����������������ӳٺ��ύ����
  //
  // EN: All standard functions for loading resources can be used between res_BeginQueue and res_EndQueue.
  //     Just for holding loading screen resources will be loaded multiple times, and texture will be post-processed with delay.
  zgl_Reg( TEX_CURRENT_EFFECT, @TextureCalcEffect );//����������ʱ��������д���
  for i := 0 to 3 do
    begin
      texTest  := tex_LoadFromFile( dirRes + 'back01.jpg', TEX_NO_COLORKEY, TEX_DEFAULT_2D or TEX_CUSTOM_EFFECT );
      sndMusic := snd_LoadFromFile( dirRes + 'music.ogg' );
    end;
  res_EndQueue();

  // CN:���ڴ��м�����Դ�ļ���Ҫ����ָ�����׺��
  // ������һ��ʹ��TMemoryStream��� mem_LoadFromFile/mem_Free ������ʾ������Ҫ��Ϊ��չʾһ��ZglTmemory����ι�����
  // EN: Loading resources from files in memory need additional set their extension.
  //     As an example TMemoryStream will be used instead of mem_LoadFromFile/mem_Free, just for showing how zglTMemory works.
  memStream := TMemoryStream.Create();
  {$IFNDEF MACOSX}
  memStream.LoadFromFile( dirRes + 'back01.jpg' );
  {$ELSE}
  memStream.LoadFromFile( PAnsiChar( zgl_Get( DIRECTORY_APPLICATION ) ) + 'Contents/Resources/back01.jpg' );
  {$ENDIF}
  memory.Position := memStream.Position;
  memory.Memory   := memStream.Memory;
  memory.Size     := memStream.Size;
  texTest := tex_LoadFromMemory( memory, 'JPG' );
  memStream.Free();

  // CN: ���ļ�����ѹ���ļ���������Դ��������Ҫopened Ȼ����closed��ʹ��file_OpenArchive ��File_CloseArchive��������
  // EN: For loading resources from zip-archive this archive should be "opened" first and then "closed" :) There are functions file_OpenArchive and file_CloseArchive for this.
  file_OpenArchive( dirRes + 'zengl.zip' );
  texLogo := tex_LoadFromFile( 'zengl.png' );
  file_CloseArchive();
end;

procedure Draw;
begin
  // CN�����߳���Դֻ�б��ڶ�ȡ���̱���ɺ�ſ��Զ�ȡ������Ĵ����������Դû�������������ʾ���뻭��
  // EN: Resources which are loading in multithreaded mode can be used only after finishing the loading process. Code below renders loading screen if resources are not loaded yet.
  if res_GetCompleted() < 100 Then
    begin
      ssprite2d_Draw( texLogo, ( 800 - texLogo.Width ) / 2, ( 600 - texLogo.Height ) / 2, texLogo.Width, texLogo.Height, 0 );
      text_Draw( fntMain, 400, 300 + texLogo.Height / 4, 'Loading... ' + u_IntToStr( res_GetCompleted() ) + '%', TEXT_HALIGN_CENTER );
      exit;
    end;

  ssprite2d_Draw( texTest, 0, 0, 800, 600, 0 );
  text_Draw( fntMain, 0, 0, 'FPS: ' + u_IntToStr( zgl_Get( RENDER_FPS ) ) );
  text_Draw( fntMain, 0, 16, 'VRAM Used: ' + u_FloatToStr( zgl_Get( RENDER_VRAM_USED ) / 1024 / 1024 ) + 'Mb' );
end;

Begin
  {$IFNDEF USE_ZENGL_STATIC}
  if not zglLoad( libZenGL ) Then exit;
  {$ENDIF}

  zgl_Reg( SYS_LOAD, @Init );
  zgl_Reg( SYS_DRAW, @Draw );

  wnd_SetCaption( '02 - Resources' );

  wnd_ShowCursor( TRUE );

  scr_SetOptions( 800, 600, REFRESH_MAXIMUM, FALSE, FALSE );
  scr_SetVSync(True);

  zgl_Init();
End.
