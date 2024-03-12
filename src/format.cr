require "colorize"
require "log"

struct Test::Format
  extend Log::Formatter

  def self.format(entry : Log::Entry, io : IO)
    label = entry.severity.label

    severity = case entry.severity
    when .trace?  then " #{label}".ljust(7).colorize(:white).back(:magenta).italic.to_s
    when .debug?  then " #{label}".ljust(7).colorize(:light_cyan).to_s
    when .info?   then " #{label}".ljust(7)
    when .notice? then " NOTE".ljust(7).colorize(:light_yellow).to_s
    when .warn?   then " #{label}".ljust(7).colorize(255, 135, 0).to_s
    when .error?  then " #{label}".ljust(7).colorize(:light_red).to_s
    when .fatal?  then " #{label}".ljust(7).colorize(:black).back(:red).bold.to_s
    end

    io << '['
    io << entry.timestamp.time_of_day
    io << ']'
    io << ' '

    io << severity if severity
    io << ' '
    io << '-'
    io << ' '

    unless entry.source.empty?
      io << entry.source
      io << ':'
      io << ' '
    end

    if exception = entry.exception
      io << exception.message
    else
      io << entry.message
    end

    unless entry.data.empty?
      max_size = 0
      entry.data.each do |(name, _)|
        max_size = Math.max(max_size, name.to_s.size)
      end

      entry.data.each do |(name, value)|
        io << '\n'
        io << '-'
        io << ' '
        io << "#{name}:".to_s.ljust(max_size + 1)
        io << ' '
        io << value
      end
    end

    if exception = entry.exception
      if backtrace = exception.backtrace?
        backtrace.each do |frame|
          io << '\n'
          io << frame
        end
      end
    end
  end
end
