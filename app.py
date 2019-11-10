# -*- coding: utf-8 -*-

import os
from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor

port = int(os.environ.get('PORT', 5000))
print("tyson found port:")
print(port)
class EchoProtocol(DatagramProtocol):

    def datagramReceived(self, datagram, address):
        print ("received %r from %s" % (datagram, address))
        self.transport.write(datagram, address)


reactor.listenUDP(port, EchoProtocol())
reactor.run()
print("tyson is listening")