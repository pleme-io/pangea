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

require 'json'

module Pangea
  module CLI
    module UI
      module Diff
        # Value formatting and action styling for diff display
        module Formatting
          # Action icons and colors for terraform operations
          ACTION_STYLES = {
            create: ['[+]', :green],
            update: ['[~]', :yellow],
            replace: ['[+/-]', :magenta],
            destroy: ['[-]', :red],
            read: ['[<-]', :blue],
            unknown: ['[?]', :white]
          }.freeze

          module_function

          def action_style(action)
            ACTION_STYLES.fetch(action, ACTION_STYLES[:unknown])
          end

          def format_value_change(old_val, new_val, pastel)
            if old_val.length > 30 || new_val.length > 30
              # Multi-line diff for long values
              "\n    #{pastel.red("- #{old_val}")}\n    #{pastel.green("+ #{new_val}")}"
            else
              # Inline diff for short values
              "#{pastel.red(old_val)} -> #{pastel.green(new_val)}"
            end
          end

          def format_value(value)
            case value
            when String
              value =~ /\n/ ? "\n#{value.lines.map { |l| "    #{l}" }.join}" : value
            when Hash, Array
              JSON.pretty_generate(value)
            else
              value.to_s
            end
          end
        end
      end
    end
  end
end
