# frozen_string_literal: true

require 'tty-spinner'

module Pangea
  module CLI
    module UI
      # Spinner UI component for showing progress
      class Spinner
        def initialize(message = nil, options = {})
          format = options.fetch(:format, :classic)
          @spinner = TTY::Spinner.new(
            "[:spinner] #{message}",
            format: format,
            hide_cursor: true,
            success_mark: '✓',
            error_mark: '✗'
          )
        end
        
        def start
          @spinner.start
        end
        
        def stop
          @spinner.stop
        end
        
        def success(message = nil)
          @spinner.success(message)
        end
        
        def error(message = nil)
          @spinner.error(message)
        end
        
        def update(message)
          @spinner.update(title: "[:spinner] #{message}")
        end
        
        def spin
          start
          yield
          success
        rescue => e
          error
          raise e
        ensure
          stop
        end
      end
    end
  end
end