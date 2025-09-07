# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


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