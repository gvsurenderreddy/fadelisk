#!/usr/bin/env python


import os
import sys

#from twisted.application import internet, service
#from twisted.web import script, resource
from twisted.internet import reactor, protocol, defer
from twisted.web import server, vhost, static
from twisted.protocols import basic

import conf

class ClientProtocol(basic.LineReceiver):
    def connectionMade(self):
        print 'Connected.'
        self.sendLine("shutdown")
        #self.loseConnection()

    def connectionLost(self, reason):
        print "connection lost"

    def sendMessage(self, msg):
        self.sendLine(msg)

    def dataReceived(self, line):
        print('*', line)

class ClientFactory(protocol.ClientFactory):
    protocol = ClientProtocol

    def __init__(self):
        print 'Factory init'
        print self.__dict__
        #self.channel = channel
        #self.filename = filename

    def startedConnecting(self, connector):
        print 'Started to connect.'

    def clientConnectionLost(self, connector, reason):
        #print 'Lost client connection.  Reason:', reason
        # connector.connect() #reconnect
        reactor.stop()
            
    def clientConnectionFailed(self, connector, reason):
        print 'Client connection failed. Reason:', reason
        reactor.stop()


class Client(object):
    def __init__(self, options, args, conf=None):
        self.options = options
        self.args = args
        self.conf = conf

    def start(self):
        client = ClientFactory()
        reactor.connectTCP(
            self.conf['control_address'] or 'localhost',
            self.conf['control_port'] or 1067,
            client,
        )
        #client.protocol.sendMessage('shutdown')
        #reactor.callLater(.2, client.protocol.sendMessage, self.args[0])
        reactor.run()


def start(options, args, conf):
    return Client(options, args, conf).start()

