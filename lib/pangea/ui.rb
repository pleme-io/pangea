# frozen_string_literal: true

module Pangea
  # Simple UI for outputting messages
  class UI
    def initialize(output = $stdout)
      @output = output
    end
    
    def say(message)
      @output.puts message
    end
    
    def info(message)
      @output.puts "[INFO] #{message}"
    end
    
    def success(message)
      @output.puts "[✓] #{message}"
    end
    
    def warn(message)
      @output.puts "[WARNING] #{message}"
    end
    
    def error(message)
      @output.puts "[ERROR] #{message}"
    end
  end
end