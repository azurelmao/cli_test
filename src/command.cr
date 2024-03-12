module Test
  def start_command_fiber(channel : Channel(Command | PartialCommand))
    command = Array(Char).new

    loop do
      char = STDIN.read_char

      case char
      when nil # STDIN was closed
        exit
      when '\u{3}' # Ctrl+C
        puts "^C"
        exit
      when '\u{4}' # Ctrl+D
        puts
        exit
      # TODO: Arrow keys
      when '\n' # Enter
        channel.send Command.new(command.join)
        command.clear
      when '\u{7f}' # Backspace
        channel.send PartialCommand.new(command.join) if command.pop?
      else
        command << char
        channel.send PartialCommand.new(command.join)
      end
    end
  end

  def handle_command(command : String)
    case command
    when "stop"
      Log.info { "Stopping server!" }
      exit
    when "hello"
      Log.info { "world!" }
    else
      Log.error &.emit "Unknown command!"
    end
  end
end
