require "socket"
require "./format"
require "./network"
require "./key"

module Test
  extend self

  Log.setup do |log|
    dispatcher = Log::DispatchMode::Direct
    backend = Log::IOBackend.new(dispatcher: dispatcher, formatter: Format)

    log.bind "*", :trace, backend
  end

  record Stop
  record Enter
  record Delete

  enum ArrowKey
    Up
    Down
    Right
    Left
  end

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
    key_channel = Channel(Char | Enter | Delete | ArrowKey).new

    spawn start_network_fiber(network_channel)
    spawn start_key_fiber(key_channel)

    command_history = Array(Array(Char)).new
    command_history << [] of Char
    command_index = 0
    cursor_pos = 0

    print "> "
    loop do
      select
      when request = network_channel.receive
        print "\e[2K\r"

        handle_request(request)

        print "> #{command_history[command_index].join}\r\e[#{2 + cursor_pos}C"
      when key = key_channel.receive
        print "\e[2K\r"

        case key
        when Char
          if command_history[command_index][cursor_pos]?
            command_history[command_index].insert(cursor_pos, key)
          else
            command_history[command_index] << key
          end

          cursor_pos += 1
        when Delete
          if cursor_pos - 1 >= 0
            if command_history[command_index][cursor_pos - 1]?
              command_history[command_index].delete_at(cursor_pos - 1)
            else
              command_history[command_index].pop?
            end

            cursor_pos -= 1
          end
        when Enter
          handle_command(command_history[command_index].join)

          if !command_history[command_index].empty?
            command_history << [] of Char
            command_index += 1
          end

          cursor_pos = 0
        when ArrowKey::Up
          command_index -= 1 if command_index > 0
        when ArrowKey::Down
          command_index += 1 if command_index < command_history.size - 1
        when ArrowKey::Right
          cursor_pos += 1 if cursor_pos < command_history[command_index].size
        when ArrowKey::Left
          cursor_pos -= 1 if cursor_pos > 0
        end

        print "> #{command_history[command_index].join}\r\e[#{2 + cursor_pos}C"
      end
    end
  end
end

Test.main
