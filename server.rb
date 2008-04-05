require 'socket'

class Mud
  class Server

    def initialize(port=3333, host="0.0.0.0")
      @tcp_server = ::TCPServer.new(host,port)
    end

    def start
      while (session = @tcp_server.accept)
        Client.connect(session)
      end
    end
  end
end

