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
    module Commands
      # JSON formatting and display methods
      module JsonFormatting
          private

          def display_compiled_json(template_name, terraform_json)
            ui.info "Compiled Terraform JSON for template '#{template_name}':"
            ui.info '-' * 60

            parsed = JSON.parse(terraform_json)
            formatted_json = JSON.pretty_generate(parsed)

            formatted_json.lines.each_with_index do |line, index|
              line_number = (index + 1).to_s.rjust(4)
              ui.say "#{ui.pastel.bright_black(line_number)} #{highlight_json_line(line.chomp)}"
            end
          rescue JSON::ParserError
            ui.error 'Invalid JSON in compiled output'
            ui.say terraform_json
          end

          def highlight_json_line(line)
            line
              .gsub(/"([^"]+)":/, ui.pastel.blue("\"\\1\":"))
              .gsub(/:\s*"([^"]+)"/, ": #{ui.pastel.green("\"\\1\"")}")
              .gsub(/:\s*(\d+)/, ": #{ui.pastel.cyan('\\1')}")
              .gsub(/:\s*(true|false)/, ": #{ui.pastel.yellow('\\1')}")
              .gsub(/([{}\[\],])/, ui.pastel.bright_black('\\1'))
          end
        end
      end
    end
  end
