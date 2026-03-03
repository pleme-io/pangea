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
      module Diff
        # Parses terraform plan output into structured sections
        module PlanParser
          module_function

          def parse_plan_output(output)
            sections = []
            current_section = nil

            output.lines.each do |line|
              current_section = process_line(line, current_section, sections)
            end

            sections
          end

          def process_line(line, current_section, sections)
            case line
            when /^Terraform will perform the following actions:/
              { type: :header, content: [] }
            when /^  # (.+) will be (.+)$/
              resource = ::Regexp.last_match(1)
              action = ::Regexp.last_match(2)
              section = {
                type: :resource,
                resource: resource,
                action: parse_action(action),
                content: []
              }
              sections << section
              section
            when /^      [+-~]/, /^        /
              current_section[:content] << line if current_section
              current_section
            when /^Plan:/, /^Changes to Outputs:/
              section = { type: :summary, content: [line] }
              sections << section
              section
            else
              current_section[:content] << line if current_section && !line.strip.empty?
              current_section
            end
          end

          def parse_action(action_text)
            case action_text
            when /created/
              :create
            when /updated in-place/
              :update
            when /replaced/
              :replace
            when /destroyed/
              :destroy
            when /read/
              :read
            else
              :unknown
            end
          end
        end
      end
    end
  end
end
