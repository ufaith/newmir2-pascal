#_*_coding=GBK_*_
from twisted.internet import reactor
from twisted.internet.protocol import Protocol,ClientFactory
from Client2LoginGate_pb2 import *
class Client(Protocol):
    def connectionMade(self):
            print '�Ѿ����ӵ�LoginSrv'
            print '׼����������'
            self.protobuf=ClientMsg()
            self.protobuf.Type=GETROLE
            self.protobuf.ID='qq531662161'
            self.protobuf.Password='13576665585'
            self.transport.write(self.protobuf.SerializeToString())
    def connectionLost(self,reason):
            print '�Ͽ�����'
    def dataReceived(self,data):
            print '�յ�����'
f=ClientFactory()
f.protocol=Client
reactor.connectTCP('127.0.0.1',7200,f)
reactor.run()
