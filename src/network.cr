module Test
  def start_network_fiber(channel : Channel({String, Socket::IPAddress}))
    addr = "localhost"
    port = 1234

    socket = UDPSocket.new
    socket.bind addr, port

    loop do
      request = socket.receive
      channel.send request
    end
  end
end
