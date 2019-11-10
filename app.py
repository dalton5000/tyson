# -*- coding: utf-8 -*-

import os
from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor

PORT = int(os.environ.get('PORT', 8080))

class Echo(DatagramProtocol):

    def datagramReceived(self, datagram, address):
        print ("received %r from %s:%d" % (datagram, address))
        self.transport.write(datagram, address)


reactor.listenUDP(PORT, Echo())
reactor.run()
print("tyson is listening")