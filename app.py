# -*- coding: utf-8 -*-

import os
from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor

PORT = int(os.environ.get('PORT', 8080))

class Echo(DatagramProtocol):

    def datagramReceived(self, data, (host, port)):
        print ("received %r from %s:%d" % (data, host, port))
        self.transport.write(data, (host, port))


reactor.listenUDP(9999, Echo())
reactor.run()
print("tyson is listening")