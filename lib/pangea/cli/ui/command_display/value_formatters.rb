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

module Pangea
  module CLI
    module UI
      module CommandDisplay
        # Value formatting utilities for command display
        module ValueFormatters
          # Display execution time
          def display_execution_time(start_time, operation: 'Operation')
            elapsed = Time.now - start_time
            formatted_time = format_duration(elapsed)

            formatter.kv_pair(
              "#{operation} duration",
              Boreal.paint(formatted_time, :muted)
            )
          end

          private

          def format_output_value(value)
            case value
            when String
              Boreal.paint(value, :muted)
            when Array
              Boreal.paint("[#{value.join(', ')}]", :muted)
            when Hash
              Boreal.paint(value.to_json, :muted)
            when Numeric
              Boreal.paint(value.to_s, :primary)
            when TrueClass, FalseClass
              Boreal.paint(value.to_s, :update)
            else
              Boreal.paint(value.to_s, :muted)
            end
          end

          def format_duration(seconds)
            if seconds < 1
              "#{(seconds * 1000).round}ms"
            elsif seconds < 60
              "#{seconds.round(2)}s"
            else
              minutes = (seconds / 60).floor
              secs = (seconds % 60).round
              "#{minutes}m #{secs}s"
            end
          end
        end
      end
    end
  end
end
