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
      class Logger
        # Display helper methods for the Logger
        module DisplayHelpers
          # Progress messages
          def step(number, total, message)
            say "[#{number}/#{total}] #{message}", color: :bright_black
          end

          # File operations
          def file_action(action, path)
            action_texts = { create: "Creating", update: "Updating", delete: "Deleting", read: "Reading" }
            action_text = action_texts[action] || action.to_s.capitalize
            info "#{action_text} #{path}"
          end

          # Code display
          def code(content, language: :ruby)
            say "```#{language}", color: :bright_black
            say content
            say "```", color: :bright_black
          end

          # Error context
          def error_context(error, file: nil, line: nil)
            error "#{error.class}: #{error.message}"

            if file && line
              say "  Location: #{file}:#{line}", color: :bright_black
            end

            if ENV['DEBUG'] && error.backtrace
              say "\nBacktrace:", color: :bright_black
              error.backtrace.first(10).each do |frame|
                say "  #{frame}", color: :bright_black
              end
            end
          end

          # Beautiful diff display
          def diff_line(type, content)
            diff_styles = {
              add:     { prefix: "+ ", color: :bright_green },
              remove:  { prefix: "- ", color: :bright_red },
              context: { prefix: "  ", color: :bright_black },
              header:  { prefix: "@@ ", suffix: " @@", color: :bright_cyan }
            }

            style = diff_styles[type]
            return unless style

            formatted_content = style[:suffix] ? "#{content}#{style[:suffix]}" : content
            say @pastel.decorate("#{style[:prefix]}#{formatted_content}", style[:color])
          end

          # Template processing status
          def template_status(name, action, duration = nil)
            icon = TEMPLATE_ICONS[action] || TEMPLATE_ICONS[:default]

            action_texts = {
              compiling:  { text: 'compiling...', color: :yellow },
              compiled:   { text: 'compiled', color: :green },
              failed:     { text: 'failed', color: :red },
              validating: { text: 'validating...', color: :blue },
              validated:  { text: 'validated', color: :green }
            }

            message = "#{icon} Template #{@pastel.bright_white(name)}"

            if (action_info = action_texts[action])
              message += " #{@pastel.decorate(action_info[:text], action_info[:color])}"
              message += " #{@pastel.bright_black("(#{duration}s)")}" if duration && action == :compiled
            end

            say message
          end
        end
      end
    end
  end
end
