module Test
  def start_key_fiber(channel : Channel(Char | Enter | Delete | ArrowKey))
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
      when '\e'
        case STDIN.read_char
        when '['
          case STDIN.read_char
          when 'A'
            channel.send ArrowKey::Up
          when 'B'
            channel.send ArrowKey::Down
          when 'C'
            channel.send ArrowKey::Right
          when 'D'
            channel.send ArrowKey::Left
          else
            STDIN.pos -= 1
          end
        else
          STDIN.pos -= 1
        end
      when '\n' # Enter
        channel.send Enter.new
      when '\u{7f}' # Backspace
        channel.send Delete.new
      else
        channel.send char
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
