# -*- coding: utf-8 -*-

import os

from twisted.web import server, resource
from twisted.internet import reactor

PORT = int(os.environ.get('PORT', 8080))

class HelloResource(resource.Resource):
    isLeaf = True
    numberRequests = 0

    def render_GET(self, request):
        self.numberRequests += 1
        request.setHeader("content-type", "text/plain")
        return "I am request #" + str(self.numberRequests) + "\n"

reactor.listenTCP(PORT, server.Site(HelloResource()))
reactor.run()