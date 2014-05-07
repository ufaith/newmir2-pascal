#_*_coding=GBK_*_
from twisted.internet import reactor
from twisted.internet.protocol import Protocol, Factory,ReconnectingClientFactory
import time
from Client2LoginGate_pb2 import *
class Session:
    pass
class LServer(Protocol):#��Ҫ�߼�ʵ����
    def connectionMade(self):
        s=Session()
        s.id=len(self.factory.sessionList)
        s.socket=self.transport
        s.lastReadTick=time.clock()  #��λΪ��ĸ�����
        self.factory.addSession(s)
        print 'new client connection',self.transport.client
    def connectionLost(self,reason):
        print 'a client lost:',reason
    def dataReceived(self,data):
        print 'data to :',data
        #�����в���
        protobuf=self.factory.protobuf
        protobuf.ParseFromString(data)
        #�ж�����Ӧ��Ͷ�����ĸ�������
        if (protobuf.Type>S_LOGINSRV) and(protobuf.Type<E_LOGINSRV):#��Ϣ������S_LOGINSRV��E_LOGINSRV֮�䣬˵������ϢӦ��Ͷ�ݸ�LoginSrv
            print '����ϢӦ���͸�LoginSrv'
            self.factory.LoginSrv.transport(data)
        elif (protobuf.Type>S_ROLESRV) and(protobuf.Type<E_ROLESRV):#RoleSrv
            print '����ϢӦ�÷��͸�RoleSrv'
        elif (protobuf.Type>S_MANAGESRV) and(protobuf.Type<E_MANAGESRV):#ManageSrv
            print '����ϢӦ�÷��͸�ManageSrv'
        else:
            print '����Ϣ�����쳣'
class LServerFactory(Factory):
    def __init__(self):
        self.protocol=LServer
        self.sessionList=[]
        self.protobuf=ClientMsg()
    def addSession(self,session):
        self.sessionList.append(session)


 
class ConnectToLoginSrv(Protocol):#������LoginSrv������
    def connectionMade(self):
        print 'LoginSrv�����Ѿ�����'
        self.factory.iswork=True      
    def dataReceived(self,data):
        print 'Revecived From LoginSrv',data
    def connectionLost(self,reason):
        pass
    
    
class ConnectLoginSrvFactory(ReconnectingClientFactory):
    def __init__(self,LFactory):
        self.protocol=ConnectToLoginSrv
        self.maxRetries=50
        self.maxDelay=3
        self.lserver=LFactory
    def clientConnectionFailed(self, connector, reason):
        print 'LoginSrv����ʧ��,����׼������'
        self.iswork=False
        self.retry(connector)
    def clientConnectionLost(self, connector, unused_reason):
        print 'LoginSrv�Ͽ�����,������׼������'  
        self.iswork=False
        self.retry(connector)
    def buildProtocol(self, addr): 
        self.lserver.LoginSrv=ReconnectingClientFactory.buildProtocol(self, addr)
        
        
class ConnectToRoleSrv(Protocol):#������RoleSrv������
    def dateReceived(self,date):
        pass
    def connectionLost(self,reason):
        pass
class ConnectRoleSrvFactory(ReconnectingClientFactory):
    def __init__(self):
        protocol=ConnectToRoleSrv

class ConnectToManageSrv(Protocol):#������ManagerSrv������
    def dataReceived(self,data):
        pass
    def connectionLost(self,reason):
        pass


class ConnectManagerSrvFactory(ReconnectingClientFactory):
    def __init__(self):
        protocol=ConnectToManageSrv
       
factory=LServerFactory()
reactor.connectTCP('127.0.0.1',7000,ConnectLoginSrvFactory(factory))
reactor.listenTCP(7200,factory)
reactor.run()
