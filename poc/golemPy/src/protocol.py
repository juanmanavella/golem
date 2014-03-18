from twisted.internet.protocol import Protocol 
from message import MessageHello, MessagePing, MessagePong
from databuffer import DataBuffer
from message import Message

class GolemProtocol(Protocol):

    def __init__(self, client):
        self.client = client
        self.db = DataBuffer()

    def sendMessage(self, msg):
        sMessage = msg.serializeWithHeader()
        #print "Sending message {} to {}".format(msg, self.transport.getPeer())
        self.transport.write(sMessage)

    def connectionMade(self):
        self.client.newConnection(self)

    def dataReceived(self, data):
        self.db.appendString(data)
        mess = Message.deserialize(self.db)
        if mess is None:
            print "Deserialization message failed"
            return

        peer = self.transport.getPeer()
        for m in mess:
            #print "Received message {} from {}".format(m, peer)
            msg = self.client.interpret(self, m)
            if msg:
                self.sendMessage(msg)