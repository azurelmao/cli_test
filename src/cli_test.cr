require "socket"
require "./format"
require "./network"
require "./command"

module Test
  extend self

  Log.setup do |log|
    dispatcher = Log::DispatchMode::Direct
    backend = Log::IOBackend.new(dispatcher: dispatcher, formatter: Format)

    log.bind "*", :trace, backend
  end

  record Stop
  record Command, data : String
  record PartialCommand, data : String

  def set_terminal_mode
    before = Crystal::System::FileDescriptor.tcgetattr STDIN.fd
    mode = before
    mode.c_lflag &= ~LibC::ICANON
    mode.c_lflag &= ~LibC::ECHO
    mode.c_lflag &= ~LibC::ISIG

    at_exit do
      Crystal::System::FileDescriptor.tcsetattr(STDIN.fd, LibC::TCSANOW, pointerof(before))
    end

    if Crystal::System::FileDescriptor.tcsetattr(STDIN.fd, LibC::TCSANOW, pointerof(mode)) != 0
      raise IO::Error.from_errno "tcsetattr"
    end
  end

  def main
    set_terminal_mode

    network_channel = Channel({String, Socket::IPAddress}).new
    command_channel = Channel(Command | PartialCommand).new

    spawn start_network_fiber(network_channel)
    spawn start_command_fiber(command_channel)

    print "> "
    loop do
      current_input = ""

      select
      when request = network_channel.receive
        print "\e[2K\r"

        handle_request(request)

        print "> #{current_input}"
      when command = command_channel.receive
        print "\e[2K\r"

        case command
        when Command
          handle_command(command.data)

          current_input = ""
        when PartialCommand
          current_input = command.data
        end

        print "> #{current_input}"
      end
    end
  end
end

Test.main
