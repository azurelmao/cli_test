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

  def handle_request(request : {String, Socket::IPAddress})
    message, client_addr = request
    Log.info { "Received message: \"#{message}\" from #{client_addr}" }
  end
end
