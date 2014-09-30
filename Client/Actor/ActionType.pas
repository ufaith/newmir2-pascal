unit ActionType;

interface

type

  // ��������
  PActionInfo = ^TActionInfo;
  TActionInfo = record
    start   : word;              // ��ʼ֡
    frame   : word;              // ֡��
    skip    : word;              // ������֡��
    ftime   : word;              // ÿ֡���ӳ�ʱ��(����)
    usetick : byte;              // (����δ֪)
  end;


const
  // Actor ������
  DIR_UP        = 0;
  DIR_UPRIGHT   = 1;
  DIR_RIGHT     = 2;
  DIR_DOWNRIGHT = 3;
  DIR_DOWN      = 4;
  DIR_DOWNLEFT  = 5;
  DIR_LEFT      = 6;
  DIR_UPLEFT    = 7;
implementation

end.
