#_*_coding=GBK_*_
#Client��LoginGate֮��ĻỰ�ṹ
class Session:
    'LoginGate_Session'
    def __init__(self):
        self.id=''  #���ｫID��Ĭ��Ϊ�ַ��� ��Ϊ��ID�����ܽ���Ϊ�ַ������ݳ�ȥ�����ڴ��ݵ�ʱ��ת��������
        self.socket=0
        self.lastReadTick=0 #���һ�οͻ��˴��ݹ�����Ϣ��ʱ�����ڼ�ⳬʱ
