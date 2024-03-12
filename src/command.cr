module Test
  def start_command_fiber(channel : Channel(Command | PartialCommand))
    command = Array(Char).new

    loop do
      char = STDIN.read_char

      case char
      when nil # STDIN was closed
        break
      when '\u{3}' # Ctrl+C
        print "^C\r\n"
        break
      when '\u{4}' # Ctrl+D
        print "\r\n"
        break
      # TODO: Arrow keys
      when '\r' # Enter
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
end
