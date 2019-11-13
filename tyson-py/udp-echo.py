"""UDP hole punching server."""
from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor

import sys
DEFAULT_PORT = 4000

class ServerProtocol(DatagramProtocol):

    def datagramReceived(self, datagram, address):
        """Handle incoming datagram messages."""
        print(datagram)
        # data_string = datagram.decode("utf-8")
        # msg_type = data_string[:2]
        ip, port = address
        for i in range(0, 3):
            self.transport.write(bytes(str(port)), address, int(port) +i)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: ./server.py PORT")
        port = DEFAULT_PORT
        # sys.exit(1)
    else:
        port = int(sys.argv[1])
    reactor.listenUDP(port, ServerProtocol())
    print('Listening on *:%d' % (port))
    reactor.run()