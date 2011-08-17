#!/usr/bin/env python

from twisted.internet import reactor, protocol, defer
from twisted.protocols import basic

import conf

class ClientProtocol(basic.LineReceiver):
    def connectionMade(self):
        #print 'Connected.'
        self.sendLine("shutdown")
        #self.loseConnection()

    def connectionLost(self, reason):
        pass
        #print "connection lost"

    def sendMessage(self, msg):
        self.sendLine(msg)

    def dataReceived(self, line):
        print('*', line)

class ClientFactory(protocol.ClientFactory):
    protocol = ClientProtocol

    def __init__(self):
        pass
        #self.channel = channel
        #self.filename = filename

    def startedConnecting(self, connector):
        pass
        #print 'Started to connect.'

    def clientConnectionLost(self, connector, reason):
        #print 'Lost client connection.  Reason:', reason
        # connector.connect() #reconnect
        reactor.stop()

    def clientConnectionFailed(self, connector, reason):
        print 'Client connection failed. Reason:', reason
        reactor.stop()


class Client(object):
    def __init__(self, conf, args):
        self.conf = conf
        self.args = args

    def start(self):
        client = ClientFactory()
        reactor.connectTCP(
            self.conf['control_address'],
            self.conf['control_port'],
            client,
        )
        #client.protocol.sendMessage('shutdown')
        #reactor.callLater(.2, client.protocol.sendMessage, self.args[0])
        reactor.run()


def start(conf, args):
    return Client(conf, args).start()

