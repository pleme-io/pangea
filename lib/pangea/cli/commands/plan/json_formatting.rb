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
              ui.say "#{Boreal.paint(line_number, :muted)} #{highlight_json_line(line.chomp)}"
            end
          rescue JSON::ParserError
            ui.error 'Invalid JSON in compiled output'
            ui.say terraform_json
          end

          def highlight_json_line(line)
            line
              .gsub(/"([^"]+)":/, Boreal.paint("\"\\1\":", :info))
              .gsub(/:\s*"([^"]+)"/, ": #{Boreal.paint("\"\\1\"", :success)}")
              .gsub(/:\s*(\d+)/, ": #{Boreal.paint('\\1', :primary)}")
              .gsub(/:\s*(true|false)/, ": #{Boreal.paint('\\1', :update)}")
              .gsub(/([{}\[\],])/, Boreal.paint('\\1', :muted))
          end
        end
      end
    end
  end
