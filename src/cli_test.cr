require "socket"
require "./format"

module Test
  Log.setup do |log|
    dispatcher = Log::DispatchMode::Direct
    backend = Log::IOBackend.new(dispatcher: dispatcher, formatter: Format)

    log.bind "*", :trace, backend
  end

  record Stop

  network_channel = Channel({String, Socket::IPAddress}).new
  network_stop_channel = Channel(Stop).new
  spawn do
    addr = "localhost"
    port = 1234

    socket = UDPSocket.new
    socket.bind addr, port

    loop do
      select
      when network_stop_channel.receive
        break
      else
        request = socket.receive
        network_channel.send request
      end
    end
  end

  record Command, data : String
  record PartialCommand, data : String

  command_channel = Channel(Command | PartialCommand).new
  spawn do
    command = Array(Char).new

    loop do
      char = STDIN.raw {STDIN.read_char}

      case char
      when nil
        break
      when '\u{3}'
        print "^C\r\n"
        break
      when '\u{4}'
        print "\r\n"
        break
      # TODO: Arrow keys
      when '\r'
        command_channel.send Command.new(command.join)
        command.clear
      when '\u{7f}'
          command_channel.send PartialCommand.new(command.join) if command.pop?
      else
        command << char
        command_channel.send PartialCommand.new(command.join)
      end
    end

    Log.trace {"stopped command fiber"}
  end

  at_exit { STDIN.cooked! }

  print "> "
  loop do
    current_input = ""

    select
    when request = network_channel.receive
      print "\e[2K\r"

      message, client_addr = request
      Log.info { "Received message: \"#{message}\" from #{client_addr}" }

      print "> #{current_input}"
    when command = command_channel.receive
      print "\e[2K\r"

      case command
      when Command
        case command.data
        when "stop"
          Log.info { "Stopping server!" }
          network_stop_channel.send Stop.new
          STDIN.close
          exit
        when "hello"
          Log.info { "world!" }
        else
          Log.error &.emit "Unknown command!"
        end

        current_input = ""
      when PartialCommand
        current_input = command.data
      end

      print "> #{current_input}"
    end
  end
end
