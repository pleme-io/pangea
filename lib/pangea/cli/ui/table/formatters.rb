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

require 'pastel'

module Pangea
  module CLI
    module UI
      class Table
        # Formatters for table row styling and display
        module Formatters
          # Color mappings
          ACTION_COLORS = {
            create: :bright_green,
            update: :bright_yellow,
            delete: :bright_red,
            replace: :bright_magenta
          }.freeze

          STATUS_DISPLAYS = {
            success: ['✓ Success', :bright_green],
            error: ['✗ Error', :bright_red],
            warning: ['⚠ Warning', :bright_yellow],
            pending: ['⧖ Pending', :bright_blue]
          }.freeze

          ACTION_SYMBOLS = {
            create: ['+ ', :bright_green],
            update: ['~ ', :bright_yellow],
            delete: ['- ', :bright_red],
            replace: ['± ', :bright_magenta]
          }.freeze

          TEMPLATE_STATUS = {
            compiled: ['✓ Compiled', :bright_green],
            failed: ['✗ Failed', :bright_red],
            validating: ['🔍 Validating', :bright_blue],
            compiling: ['⚙️ Compiling', :bright_yellow]
          }.freeze

          BACKEND_ICONS = {
            's3' => '☁️',
            'local' => '📁',
            'remote' => '🌐'
          }.freeze

          module_function

          def format_resource_row(resource)
            pastel = Pastel.new
            action_color = ACTION_COLORS[resource[:action]] || :white
            status_text, status_color = STATUS_DISPLAYS[resource[:status]] || ['Unknown', :bright_black]

            [
              "#{pastel.cyan(resource[:type])}.#{pastel.white(resource[:name])}",
              pastel.decorate(resource[:action].to_s.capitalize, action_color),
              pastel.decorate(status_text, status_color),
              pastel.bright_black(resource[:details] || '')
            ]
          end

          def format_plan_row(item)
            pastel = Pastel.new
            symbol, color = ACTION_SYMBOLS[item[:action]] || ['  ', :white]

            [
              "#{pastel.decorate(symbol, color)}#{pastel.cyan(item[:type])}.#{pastel.white(item[:name])}",
              item[:action].to_s.capitalize,
              pastel.bright_black(item[:reason] || '')
            ]
          end

          def format_template_row(template)
            pastel = Pastel.new
            status_text, status_color = TEMPLATE_STATUS[template[:status]] || ['Unknown', :bright_black]
            duration = format_duration(template[:duration])

            [
              pastel.bright_white(template[:name]),
              pastel.cyan(template[:resource_count].to_s),
              pastel.decorate(status_text, status_color),
              pastel.bright_black(duration)
            ]
          end

          def format_duration(duration)
            return '' unless duration
            duration < 1 ? "#{(duration * 1000).round}ms" : "#{duration.round(1)}s"
          end

          def format_namespace_row(ns)
            pastel = Pastel.new
            backend_icon = BACKEND_ICONS[ns[:backend_type]] || '❓'

            [
              pastel.bright_white(ns[:name]),
              "#{backend_icon} #{ns[:backend_type]}",
              pastel.cyan(ns[:location] || ''),
              pastel.bright_black(ns[:description] || '')
            ]
          end

          def format_cost_row(item)
            pastel = Pastel.new
            change = item[:estimated] - item[:current]
            change_display = format_cost_change(change, pastel)

            [
              pastel.white(item[:service]),
              "$#{item[:current]}/mo",
              "$#{item[:estimated]}/mo",
              change_display
            ]
          end

          def format_cost_change(change, pastel)
            if change > 0
              pastel.bright_red("+$#{change.abs}/mo")
            elsif change < 0
              pastel.bright_green("-$#{change.abs}/mo")
            else
              pastel.bright_black("No change")
            end
          end
        end
      end
    end
  end
end
