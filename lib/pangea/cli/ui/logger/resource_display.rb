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
        # Resource display methods for the Logger
        module ResourceDisplay
          # Resource actions
          def resource_action(action, resource_type, resource_name, status = nil)
            symbols = { create: "+", update: "~", delete: "-", replace: "±" }
            colors = { create: :bright_green, update: :bright_yellow, delete: :bright_red, replace: :bright_magenta }

            action_symbol = symbols[action] || "?"
            action_color = colors[action] || :white

            message = "#{action_symbol} #{resource_type}.#{resource_name}"

            if status
              status_color = status == :success ? :green : :red
              status_text = status == :success ? "✓" : "✗"
              message += " #{@pastel.decorate(status_text, status_color)}"
            end

            say message, color: action_color
          end

          # Resource status with enhanced formatting
          def resource_status(resource_type, resource_name, action, status = nil, details = nil)
            style = ACTION_STYLES[action] || ACTION_STYLES[:default]
            action_symbol = @pastel.decorate(style[:symbol], style[:color])

            resource_display = "#{@pastel.bright_white(resource_type)}.#{@pastel.cyan(resource_name)}"

            status_indicator = if status && (indicator = STATUS_INDICATORS[status])
                                color = status == :success ? :bright_green :
                                       status == :error ? :bright_red :
                                       status == :warning ? :bright_yellow : :bright_blue
                                @pastel.decorate(indicator, color)
                              else
                                ""
                              end

            message = "#{action_symbol} #{resource_display}#{status_indicator}"
            message += " #{@pastel.bright_black("(#{details})")}" if details

            say message
          end
        end
      end
    end
  end
end
